# Manual Test Plan — Community Health Integration (Step 3: Create a Post)

Scope: [roadmap.md](../base_content/roadmap.md) Step 3 pairs with
[CH-Step 3 (Generic Resource & Action Ingestion)](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md).
Every test below interacts only with Underlined's UI (`http://localhost:3000`) — the
post composer at `/posts/new`. Community Health sync is invisible bookkeeping: a
published post emits a `CREATE` action event behind the scenes, but the composer must
look and behave **identically** whether the integration is on, off, or broken — same
principle as [Step 1's doc](step_1_plus_integration_tests.md), just for posts instead
of signup/profile.

Unlike Step 1 (which synced identity via `ensure_member`), this step exercises CH's
newer, more general machinery: `record_action`, which registers an opaque **resource**
(`resource_type: "post"`, a caller-supplied id CH never interprets) the first time it's
referenced, then records an append-only **action** against it, idempotent on a
caller-supplied `event_key`. Posts use `event_key: "post:create:<post_id>"`.

For raw setup commands (starting stacks, registering the platform), see
[integration.md](integration.md) — this file assumes those work.

## Before you start

- **Start from empty databases.** This file assumes both Underlined's and
  HealthyCommunity's databases are empty before Test 1 (then builds up a book/user to
  post with, per the next two bullets). If you're re-running this file, empty both
  first with the two snippets from
  [Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
  — the same snippets this file's [Cleanup](#cleanup) section ends with.
- Both repos checked out: `Underlined` and `HealthyCommunity`.
- You have one **enabled** user to log in with (see
  [Step 1's doc](step_1_plus_integration_tests.md#finding-a-users-id-and-why-signing-up-isnt-enough-to-log-in)
  for how to flip `enabled` via `iex -S mix` — never `psql`).
- You have at least one book in the catalog (see
  [Step 2's doc](step_2_tests.md), Test 1) to attach posts to.
- Unlike Step 1's user id, a post's id needs no lookup trick: after publishing, the
  composer's "View post" link goes to `/posts/<id>` — the id is right there in the
  address bar.
- All DB verification below uses `docker compose exec api iex -S mix` (Underlined) and
  `docker compose exec app iex -S mix` (HealthyCommunity) — never `psql` — with:
  ```elixir
  # Underlined
  alias Api.Repo
  alias Api.Infrastructure.Repository.Post.Postgres.Post
  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker
  import Ecto.Query
  ```
  ```elixir
  # HealthyCommunity
  alias CommunityHealth.Repo
  alias CommunityHealth.Actions.CommunityAction
  alias CommunityHealth.Resources.Resource
  import Ecto.Query
  ```

---

## Test 1 — Publishing a post records a CREATE action (happy path)

**Setup**
1. Start HealthyCommunity: `cd HealthyCommunity && docker compose up -d postgres app`
2. Register the platform once and copy the printed API key (skip if already
   registered from Step 1's testing):
   `docker compose exec app mix community_health.register_platform "Underlined"`
3. Start Underlined with the integration **on**:
   `cd Underlined && COMMUNITY_HEALTH_ENABLED=true COMMUNITY_HEALTH_API_KEY="<key>" docker compose up -d`

**Steps (Underlined UI)**
1. Log in, go to `http://localhost:3000/posts/new`.
2. Pick any book from the search grid.
3. Fill in a passage, a "what I think" takeaway, and 1–2 keywords.
4. Click Publish.

**Expected UI result**
- The composer shows the normal "Published!" success card with a "View post" link —
  exactly as it does with the integration fully removed. No loading delay, no error.
5. Click "View post" and copy the post's id from the URL (`/posts/<id>`).

**Backend verification**
1. Confirm the post exists in Underlined:
   ```elixir
   post_id = "<the post id from the URL>"
   post = Repo.get(Post, post_id)
   post.user_id
   ```
2. In a **separate** iex shell inside HealthyCommunity's `app` container, confirm the
   resource and action both landed (re-bind `post_id` there too — it's a different
   BEAM session, nothing is shared between the two shells):
   ```elixir
   post_id = "<the same post id>"

   event_key = "post:create:#{post_id}"
   action = Repo.one(from a in CommunityAction, where: a.event_key == ^event_key)
   action.action_type        # => "CREATE"
   action.actor_external_id  # => the post's user_id from step 1

   resource = Repo.get(Resource, action.resource_id)
   resource.resource_type    # => "post"
   resource.external_ref     # => post_id
   ```

**Pass criteria:** the composer UI is unaffected AND, within a few seconds (processed
by an Oban job after the HTTP response, same as every CH sync), exactly one
`community_actions` row and one `resources` row exist for this post.

---

## Test 2 — Publishing a second post creates a second resource, not a merge

**Setup:** continue from Test 1, same logged-in user.

**Steps (Underlined UI)**
1. Publish a second, different post (any book, different passage/thinking).

**Backend verification**
```elixir
Repo.aggregate(from(r in Resource, where: r.resource_type == "post"), :count)
```
**Pass criteria:** the count is now **2** — each post gets its own resource row, keyed
by its own id; nothing about CH's ingestion merges unrelated posts together.

---

## Test 3 — Kill switch: integration disabled (the production default)

This is the configuration Underlined will actually run in production
(`COMMUNITY_HEALTH_ENABLED=false`), so it's the most important case to verify — same
principle as [Step 1's Test 3](step_1_plus_integration_tests.md#test-3--kill-switch-integration-disabled-the-production-default).

**Setup**
1. Stop HealthyCommunity entirely (or leave it down).
2. Start/restart Underlined with the flag off:
   `COMMUNITY_HEALTH_ENABLED=false docker compose up -d` (or omit the var — `false` is
   the default).

**Steps (Underlined UI)**
1. Publish a post as usual.

**Expected UI result**
- Identical to Test 1 — success card, "View post" link, no error, no slow spinner.

**Backend verification (Underlined side only — HealthyCommunity is down)**
- `docker compose logs api` shows no HTTP calls attempted to port 4100.
- Optionally confirm the no-op adapter is active:
  ```elixir
  Application.get_env(:api, :community_health, Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop)
  # => Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop
  ```

**Pass criteria:** publishing works normally with HealthyCommunity completely absent —
the integration fails *closed*, exactly as it does for Step 1.

---

## Test 4 — Kill switch: Community Health unreachable (network failure)

Same scenario as [Step 1's Test 4](step_1_plus_integration_tests.md#test-4--kill-switch-community-health-unreachable-network-failure),
exercised through post creation instead of signup.

**Setup**
1. Start Underlined with the integration **on** but pointed at a URL nothing is
   listening on:
   ```
   COMMUNITY_HEALTH_ENABLED=true \
   COMMUNITY_HEALTH_API_URL=http://host.docker.internal:4999 \
   COMMUNITY_HEALTH_API_KEY=anything \
   docker compose up -d
   ```

**Steps (Underlined UI)**
1. Publish a post.

**Expected UI result**
- Same success card as Test 1. Publishing must not hang or error even though every
  sync attempt behind the scenes will fail.

**Backend verification**
- `docker compose logs -f api` shows the job retrying (`CommunityHealthClient`
  returning a connection error) at Oban's default backoff cadence — the same ~80-minute
  road to discard documented in Step 1's Test 4. To see the discard line quickly instead
  of waiting, force one with `max_attempts: 1` from the `api` container's iex shell:
  ```elixir
  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker

  job =
    CommunityHealthWorker.new(
      %{
        action: "record_action",
        actor_id: "test-actor-id",
        action_type: "CREATE",
        resource_type: "post",
        resource_id: "test-post-id",
        community_id: "default",
        event_key: "post:create:test-post-id"
      },
      max_attempts: 1
    )

  Oban.insert(job)
  ```
  Watch `docker compose logs -f api` for the discard line to appear almost immediately.

**Pass criteria:** publishing is unaffected by CH being unreachable; the forced job
confirms the discard/log path fires rather than retrying forever.

---

## Test 5 — Kill switch: Community Health rejects the request (bad API key)

Same scenario as [Step 1's Test 5](step_1_plus_integration_tests.md#test-5--kill-switch-community-health-rejects-the-request-bad-api-key).

**Setup**
1. Make sure HealthyCommunity is running: `cd HealthyCommunity && docker compose up -d postgres app`
2. Start Underlined with an intentionally wrong key:
   ```
   COMMUNITY_HEALTH_ENABLED=true \
   COMMUNITY_HEALTH_API_KEY=this-is-not-a-real-key \
   docker compose up -d
   ```

**Steps (Underlined UI)**
1. Publish a post.

**Expected UI result**
- Same success card as every other test.

**Backend verification**
- HealthyCommunity's `app` logs show `401`s on `/v1/communities`/`/v1/events` calls.
- Confirm no resource/action was created for this post's id (same lookup as Test 1,
  step 2) — it should come back `nil`.

**Pass criteria:** an invalid key degrades exactly like an unreachable service —
publishing still succeeds, HealthyCommunity's data is untouched for that post.

---

## Test 6 — Backfill existing posts

Covers posts published before the integration existed/was enabled.

**Setup**
1. With CH disabled, publish 1–2 posts via the UI so they exist without any CH action.
2. Bring the integration up correctly (valid key, HealthyCommunity running).
3. Run the one-time backfill:
   `docker compose exec api mix community_health.backfill_posts`

**Backend verification**
1. List the post ids you're checking for:
   ```elixir
   Repo.all(from p in Post, select: {p.id, p.user_id})
   ```
2. For each id, confirm an action now exists in HealthyCommunity:
   ```elixir
   event_key = "post:create:<id>"
   Repo.exists?(from a in CommunityAction, where: a.event_key == ^event_key)
   ```

**Pass criteria:** every pre-existing post now has a `CREATE` action after the backfill
runs, without touching the Underlined UI at all.

### Test 6b — Re-running the backfill doesn't duplicate anything

**Steps**
1. Run `mix community_health.backfill_posts` a second time, immediately.

**Backend verification**
```elixir
# Pick any post id from Test 6 and confirm there's still exactly one row for it
event_key = "post:create:<id>"
Repo.aggregate(from(a in CommunityAction, where: a.event_key == ^event_key), :count)
# => 1
```
**Pass criteria:** the count stays **1** — `event_key` is the idempotency contract, so
replaying the same backfill (or retrying a flaky job) can never double-record a post.
This is the same guarantee Step 1's `ensure_member` gives on `[community_id,
actor_external_id]`, just keyed differently here.

---

## Test 7 (optional) — Circuit breaker trips after repeated failures

Same resilience check as [Step 1's Test 7](step_1_plus_integration_tests.md#test-7-optional--circuit-breaker-trips-after-repeated-failures),
exercised through post creation.

**Setup:** same as Test 4 (CH enabled, unreachable URL).

**Steps (Underlined UI)**
1. Publish 5+ posts in a row in quick succession.

**Expected UI result**
- All publishes complete at normal speed — the shared circuit breaker
  (`CommunityHealthCircuitBreaker`) trips after 5 consecutive failures regardless of
  which action type is failing, so repeated CH failures from *any* integration point
  (signup, profile edit, or post creation) can't pile up latency on each other.

**Pass criteria:** publish #6+ feels no slower than publish #1.

---

## Summary checklist

| # | Scenario | UI must look like |
|---|----------|--------------------|
| 1 | CH enabled, reachable, accepts | Normal publish; resource + action created |
| 2 | A second, different post | Normal publish; a second, distinct resource |
| 3 | `COMMUNITY_HEALTH_ENABLED=false` (prod default) | Normal publish; zero CH I/O |
| 4 | CH enabled, unreachable | Normal publish; job retries then discards, logged |
| 5 | CH enabled, invalid API key | Normal publish; job retries then discards, logged |
| 6 | Pre-existing posts | Backfilled without any UI interaction |
| 6b | Backfill re-run | No duplicate action rows |
| 7 | Repeated failures | No added latency on later publishes |

If every row's "UI must look like" column holds, Step 3's Community Health integration
is safe to run in production with `COMMUNITY_HEALTH_ENABLED=false` while HealthyCommunity
itself stays local/undeployed — the same posture [Step 1's doc](step_1_plus_integration_tests.md)
established, now proven for posts as well as accounts.

---

## Cleanup

Run both truncate snippets from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty).
That leaves Underlined's and HealthyCommunity's databases empty — schema and containers
untouched, zero rows — so [Step 4's tests](step_4_plus_integration_tests.md) can start
from the same clean slate this file assumed at the top.
