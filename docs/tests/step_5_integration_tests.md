# Manual Test Plan — Community Health Integration (Step 5: Likes)

Scope: [roadmap.md](../base_content/roadmap.md) Step 5 pairs with
[CH-Step 3 (Generic Resource & Action Ingestion)](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md) —
no new HealthyCommunity code was needed for this step; `record_action` already accepts
any `action_type`. Every test below interacts only with Underlined's UI
(`http://localhost:3000`) — the like/heart icon on a post in the feed or on a post's
detail page. Community Health sync is invisible bookkeeping, same principle as
[Step 1's doc](step_1_plus_integration_tests.md) and
[Step 3's doc](step_3_plus_integration_tests.md): liking/unliking must look and behave
**identically** whether the integration is on, off, or broken. `likes_count` on the
post itself stays the only source of truth the UI ever renders from — CH is never read
to show a like count or state.

Unlike Step 3 (one `CREATE` event per post, ever), a post can be liked, unliked, and
re-liked many times by the same user, so each toggle needs its own event:
`LikePostUsecase` emits `action_type: "REACT"` and `UnlikePostUsecase` emits
`"UNREACT"`, both `resource_type: "post"`. `event_key` therefore includes a
microsecond timestamp — `"post:react:<actor_id>:<post_id>:<timestamp>"` (`unreact:` for
the other) — rather than a static per-post key, since CH's idempotency constraint is
`[platform_id, event_key]` and two *different* toggles of the same post by the same
actor must not collide into a single row the way two identical retries of the same
toggle should.

For raw setup commands (starting stacks, registering the platform), see
[integration.md](integration.md) — this file assumes those work.

## Before you start

- **Start from empty databases.** This file assumes both Underlined's and
  HealthyCommunity's databases are empty before Test 1 (then builds up a post to like,
  per the next bullet). If you're re-running this file, empty both first with the two
  snippets from
  [Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
  — the same snippets this file's [Cleanup](#cleanup) section ends with.
- Both repos checked out: `Underlined` and `HealthyCommunity`.
- You have one **enabled** user to log in with (see
  [Step 1's doc](step_1_plus_integration_tests.md#finding-a-users-id-and-why-signing-up-isnt-enough-to-log-in)).
- You have at least one published post (see [Step 3's doc](step_3_plus_integration_tests.md))
  to like.
- All DB verification below uses `docker compose exec api iex -S mix` (Underlined) and
  `docker compose exec app iex -S mix` (HealthyCommunity) — never `psql` — with:
  ```elixir
  # Underlined
  alias Api.Repo
  alias Api.Infrastructure.Repository.Post.Postgres.Post
  import Ecto.Query
  ```
  ```elixir
  # HealthyCommunity
  alias CommunityHealth.Repo
  alias CommunityHealth.Actions.CommunityAction
  import Ecto.Query
  ```

---

## Test 1 — Liking a post records a REACT action (happy path)

**Setup**
1. Start HealthyCommunity: `cd HealthyCommunity && docker compose up -d postgres app`
2. Register the platform once and copy the printed API key (skip if already
   registered from earlier testing):
   `docker compose exec app mix community_health.register_platform "Underlined"`
3. Start Underlined with the integration **on**:
   `cd Underlined && COMMUNITY_HEALTH_ENABLED=true COMMUNITY_HEALTH_API_KEY="<key>" docker compose up -d`

**Steps (Underlined UI)**
1. Log in, go to `http://localhost:3000/feed`.
2. Click the heart icon on any post.

**Expected UI result**
- The heart fills solid and the count increments immediately — exactly as it does with
  the integration fully removed. No loading delay, no error.

**Backend verification**
1. Confirm the post's `like_count` in Underlined:
   ```elixir
   post_id = "<the post id>"
   Repo.get(Post, post_id).like_count
   ```
2. In a **separate** iex shell inside HealthyCommunity's `app` container, confirm a
   `REACT` action landed (re-bind `post_id` there too — it's a different BEAM session):
   ```elixir
   post_id = "<the same post id>"

   action =
     Repo.one(
       from a in CommunityAction,
         join: r in assoc(a, :resource),
         where: a.action_type == "REACT" and r.external_ref == ^post_id,
         order_by: [desc: a.inserted_at],
         limit: 1
     )

   action.action_type  # => "REACT"
   ```

**Pass criteria:** the like UI is unaffected AND, within a few seconds (processed by an
Oban job after the HTTP response), exactly one new `community_actions` row with
`action_type: "REACT"` exists for this post.

---

## Test 2 — Unliking records UNREACT, and re-liking doesn't collide with the first REACT

**Setup:** continue from Test 1, same logged-in user, same post.

**Steps (Underlined UI)**
1. Click the heart again to unlike the post.
2. Click it once more to re-like it.

**Expected UI result**
- The heart/count toggles back and forth normally each time, with no error or stall.

**Backend verification**
```elixir
post_id = "<the same post id>"

actions =
  Repo.all(
    from a in CommunityAction,
      join: r in assoc(a, :resource),
      where: r.external_ref == ^post_id,
      order_by: [asc: a.inserted_at],
      select: {a.action_type, a.event_key}
  )
```

**Pass criteria:** the list now has **three** distinct rows — `REACT`, `UNREACT`,
`REACT` — each with a different `event_key` (the trailing timestamp differs each time).
None of them were silently dropped by CH's `[platform_id, event_key]` uniqueness
constraint, which is exactly why the key can't be a static `post:react:<post_id>`
the way Step 3's `post:create:<post_id>` is.

---

## Test 3 — Liking twice in a row still only increments the count once

**Setup:** continue from Test 2. The post is currently liked.

**Steps (Underlined UI)**
1. Click the heart again while it's already filled (if the UI allows a stray click
   before it disables, e.g. via a fast double-click or a direct API replay).

**Backend verification**
```elixir
Repo.get(Post, post_id).like_count
```

**Pass criteria:** `like_count` doesn't double-increment — `LikePostUsecase`'s
underlying repository call is itself idempotent on the `(user, post)` pair regardless
of how many `REACT` events CH ends up recording for it. CH's event log and Underlined's
`like_count` are deliberately two separate concerns: CH may record one lightweight
`REACT` event per click attempt, but the only number users ever see comes from
Underlined's own `likes` table, which never double-counts.

---

## Test 4 — Kill switch: integration disabled (the production default)

This is the configuration Underlined will actually run in production
(`COMMUNITY_HEALTH_ENABLED=false`).

**Setup**
1. Stop HealthyCommunity entirely (or leave it down).
2. Start/restart Underlined with the flag off:
   `COMMUNITY_HEALTH_ENABLED=false docker compose up -d` (or omit the var — `false` is
   the default).

**Steps (Underlined UI)**
1. Like, then unlike, a post as usual.

**Expected UI result**
- Identical to Tests 1–2 — the heart fills/count increments and decrements normally,
  no error, no slow spinner.

**Backend verification (Underlined side only — HealthyCommunity is down)**
- `docker compose logs api` shows no HTTP calls attempted to port 4100.
- Optionally confirm the no-op adapter is active:
  ```elixir
  Application.get_env(:api, :community_health, Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop)
  # => Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop
  ```

**Pass criteria:** liking/unliking works normally with HealthyCommunity completely
absent — the integration fails *closed*, exactly as it does for Steps 1 and 3.

---

## Test 5 — Kill switch: Community Health unreachable (network failure)

Same scenario as [Step 3's Test 4](step_3_plus_integration_tests.md#test-4--kill-switch-community-health-unreachable-network-failure),
exercised through a like instead of post creation.

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
1. Like a post.

**Expected UI result**
- Same heart-fill/count-increment as Test 1. Liking must not hang or error even though
  the sync attempt behind the scenes will fail.

**Backend verification**
- `docker compose logs -f api` shows the job retrying (`CommunityHealthClient`
  returning a connection error) at Oban's default backoff cadence, same discard path
  documented in Step 1's and Step 3's Test 4.

**Pass criteria:** liking is unaffected by CH being unreachable.

---

## Test 6 — Kill switch: Community Health rejects the request (bad API key)

Same scenario as [Step 3's Test 5](step_3_plus_integration_tests.md#test-5--kill-switch-community-health-rejects-the-request-bad-api-key).

**Setup**
1. Make sure HealthyCommunity is running: `cd HealthyCommunity && docker compose up -d postgres app`
2. Start Underlined with an intentionally wrong key:
   ```
   COMMUNITY_HEALTH_ENABLED=true \
   COMMUNITY_HEALTH_API_KEY=this-is-not-a-real-key \
   docker compose up -d
   ```

**Steps (Underlined UI)**
1. Like a post.

**Expected UI result**
- Same heart-fill/count-increment as every other test.

**Backend verification**
- HealthyCommunity's `app` logs show `401`s on the `/v1/events` call.
- Confirm no new `REACT` action was created for this post's resource (same lookup as
  Test 1) — only whatever existed before this test should be there.

**Pass criteria:** an invalid key degrades exactly like an unreachable service — liking
still succeeds, HealthyCommunity's data is untouched for this attempt.

---

## Test 7 (optional) — Circuit breaker trips after repeated failures

Same resilience check as [Step 1's Test 7](step_1_plus_integration_tests.md#test-7-optional--circuit-breaker-trips-after-repeated-failures)
and [Step 3's Test 7](step_3_plus_integration_tests.md#test-7-optional--circuit-breaker-trips-after-repeated-failures),
exercised through likes.

**Setup:** same as Test 5 (CH enabled, unreachable URL).

**Steps (Underlined UI)**
1. Like/unlike 5+ times in a row in quick succession, across one or more posts.

**Expected UI result**
- All toggles complete at normal speed — the shared circuit breaker
  (`CommunityHealthCircuitBreaker`) trips after 5 consecutive failures regardless of
  which action type or integration point is failing.

**Pass criteria:** toggle #6+ feels no slower than toggle #1.

---

## Summary checklist

| # | Scenario | UI must look like |
|---|----------|--------------------|
| 1 | CH enabled, reachable, accepts | Normal like; `REACT` action recorded |
| 2 | Unlike then re-like | `UNREACT` then a second, distinct `REACT` row |
| 3 | Rapid repeat click while already liked | `like_count` doesn't double-increment |
| 4 | `COMMUNITY_HEALTH_ENABLED=false` (prod default) | Normal like/unlike; zero CH I/O |
| 5 | CH enabled, unreachable | Normal like/unlike; job retries then discards, logged |
| 6 | CH enabled, invalid API key | Normal like/unlike; job retries then discards, logged |
| 7 | Repeated failures | No added latency on later toggles |

If every row's "UI must look like" column holds, Step 5's Community Health integration
is safe to run in production with `COMMUNITY_HEALTH_ENABLED=false` while HealthyCommunity
itself stays local/undeployed — the same posture Steps 1 and 3 established, now proven
for likes as well.

---

## Cleanup

Run both truncate snippets from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty).
That leaves Underlined's and HealthyCommunity's databases empty — schema and containers
untouched, zero rows — so [Step 6's tests](step_6_integration_tests.md) can start from
the same clean slate this file assumed at the top.
