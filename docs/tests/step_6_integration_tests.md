# Manual Test Plan — Community Health Integration (Step 6: Comments)

Scope: [roadmap.md](../base_content/roadmap.md) Step 6 pairs with
[CH-Step 3 (Generic Resource & Action Ingestion)](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md)
and [CH-Step 5 (Reports)](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md).
Every test below interacts only with Underlined's UI (`http://localhost:3000`) — a
post's detail page (`/posts/<id>`), where the comment thread lives.

Step 6 combines both patterns already covered by earlier docs:
1. **Invisible bookkeeping**, same principle as [Step 3's doc](step_3_plus_integration_tests.md)
   and [Step 5's doc](step_5_integration_tests.md): posting a comment or a reply emits a
   `COMMENT` action event behind the scenes; commenting must look and behave
   **identically** whether the integration is on, off, or broken.
2. **A control whose existence depends on CH**, same principle as
   [Step 4's doc](step_4_plus_integration_tests.md): the 🚩 Report control on a comment
   must visibly grey out — never silently no-op — whenever CH is off/unreachable/
   rejecting, exactly like the Report control on a post.

`CreateCommentUsecase` emits `action_type: "COMMENT"`, `resource_type: "comment"`, with
`event_key: "comment:create:<comment_id>"` — idempotent on the comment's own id, the
same one-time-action reasoning as Step 3's `post:create:` key, since a comment (unlike a
like) is never re-created. It also sets `context: %{parent_type: "comment"}` or
`context: %{parent_type: "reply"}` depending on the comment's own `type` field — the
first use of CH's free-form `context` map from Underlined's side, letting a future
reputation engine weigh a top-level comment differently from a reply without needing a
different `action_type` for each. `comments_count`/the comment thread itself stays the
only source of truth the UI renders from — CH is never read to show a comment or decide
whether one can be posted.

For raw setup commands (starting stacks, registering the platform), see
[integration.md](integration.md) — this file assumes those work.

## Before you start

- Both repos checked out: `Underlined` and `HealthyCommunity`.
- You have one **enabled** user to log in with (see
  [Step 1's doc](step_1_plus_integration_tests.md#finding-a-users-id-and-why-signing-up-isnt-enough-to-log-in)).
- You have at least one published post (see [Step 3's doc](step_3_plus_integration_tests.md))
  to comment on.
- For the Report tests, a community needs at least one active rule (see
  [Step 4's doc](step_4_plus_integration_tests.md#before-you-start) for the
  `mix community_health.add_rule` commands) if not already provisioned.
- All DB verification below uses `docker compose exec api iex -S mix` (Underlined) and
  `docker compose exec app iex -S mix` (HealthyCommunity) — never `psql` — with:
  ```elixir
  # HealthyCommunity
  alias CommunityHealth.Repo
  alias CommunityHealth.Actions.CommunityAction
  alias CommunityHealth.Reports.Report
  import Ecto.Query
  ```

---

## Test 1 — Posting a top-level comment records a COMMENT action (happy path)

**Setup**
1. Start HealthyCommunity: `cd HealthyCommunity && docker compose up -d postgres app`
2. Register the platform once and copy the printed API key (skip if already
   registered from earlier testing):
   `docker compose exec app mix community_health.register_platform "Underlined"`
3. Start Underlined with the integration **on**:
   `cd Underlined && COMMUNITY_HEALTH_ENABLED=true COMMUNITY_HEALTH_API_KEY="<key>" docker compose up -d`

**Steps (Underlined UI)**
1. Log in, open a post's detail page.
2. Type a comment in the composer and submit it.

**Expected UI result**
- The comment appears in the thread immediately — exactly as it does with the
  integration fully removed. No loading delay, no error.

**Backend verification**
```elixir
post_id = "<the post id>"

action =
  Repo.one(
    from a in CommunityAction,
      join: r in assoc(a, :resource),
      where: a.action_type == "COMMENT" and r.external_ref == ^"<the comment id>",
      order_by: [desc: a.inserted_at],
      limit: 1
  )

action.action_type  # => "COMMENT"
action.context      # => %{"parent_type" => "comment"}
```

**Pass criteria:** the comment UI is unaffected AND, within a few seconds (processed by
an Oban job after the HTTP response), exactly one new `community_actions` row with
`action_type: "COMMENT"` and `context: %{"parent_type" => "comment"}` exists for this
comment.

---

## Test 2 — Replying records a COMMENT action with a distinct parent_type

**Setup:** continue from Test 1, same post, same top-level comment.

**Steps (Underlined UI)**
1. Click "Reply" on the comment from Test 1 and submit a reply.

**Expected UI result**
- The reply appears nested under its parent, as usual.

**Backend verification**
```elixir
action =
  Repo.one(
    from a in CommunityAction,
      join: r in assoc(a, :resource),
      where: a.action_type == "COMMENT" and r.external_ref == ^"<the reply's comment id>",
      limit: 1
  )

action.context  # => %{"parent_type" => "reply"}
```

**Pass criteria:** the reply gets its own `community_actions` row, with its own
`event_key` (`comment:create:<reply_id>`, distinct from the parent's), and
`context: %{"parent_type" => "reply"}` — distinguishable from Test 1's row without
needing a different `action_type`.

---

## Test 3 — The Report control is active on a comment and submitting records a report

**Setup:** continue from Test 1, CH still enabled and reachable, at least one active
rule provisioned (see "Before you start").

**Steps (Underlined UI)**
1. On the comment from Test 1, look at its action row (Reply, Edit if you're the
   author, 🚩).

**Expected UI result**
- The 🚩 button is fully opaque/clickable (not greyed out) — same as on a post.
2. Click it, pick a reason, submit.

**Expected UI result**
- The modal shows a thank-you/confirmation state, same as reporting a post.

**Backend verification**
```elixir
report = Repo.one(from r in Report, order_by: [desc: r.id], limit: 1)
report.resource_id  # resolves to the comment's resource, not the post's
```

**Pass criteria:** reporting a comment behaves identically to reporting a post (Step 4
Test 1), just scoped to `resource_type: "comment"` — this required zero new backend
code, since `CreateReportUsecase` already accepted `"comment"` as a valid
`resource_type` from Step 4 onward; only `ReportButton.vue` needed to be mounted here.

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
1. Post a comment and a reply, as in Tests 1–2.

**Expected UI result**
- Identical to Tests 1–2 — comments/replies post normally, no error, no slow spinner.
- The 🚩 button on each comment is visible but greyed out/disabled, exactly like on a
  post (Step 4 Test 3) — never hidden, never clickable.

**Backend verification (Underlined side only — HealthyCommunity is down)**
- `docker compose logs api` shows no HTTP calls attempted to port 4100.
- Optionally confirm the no-op adapter is active:
  ```elixir
  Application.get_env(:api, :community_health, Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop)
  # => Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop
  ```

**Pass criteria:** commenting/replying works normally with HealthyCommunity completely
absent, and the Report control greys out — the same two behaviors Steps 1/3/5 and
Step 4 each established individually, now both holding at once on the same component.

---

## Test 5 — Kill switch: Community Health unreachable (network failure)

Same scenario as [Step 3's Test 4](step_3_plus_integration_tests.md#test-4--kill-switch-community-health-unreachable-network-failure)
and [Step 4's Test 4](step_4_plus_integration_tests.md#test-4--kill-switch-community-health-unreachable-network-failure),
exercised through a comment instead of a post/report read.

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
1. Post a comment.

**Expected UI result**
- Same as Test 1 for the comment itself — it must not hang or error even though the
  sync attempt behind the scenes will fail.
- The 🚩 button greys out, same as Test 4 (the reasons read fails/times out).

**Backend verification**
- `docker compose logs -f api` shows the `record_action` job retrying (`CommunityHealthClient`
  returning a connection error) at Oban's default backoff cadence, same discard path
  documented in earlier steps.

**Pass criteria:** commenting is unaffected by CH being unreachable; the Report control
degrades visibly, the comment action itself does not.

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
1. Post a comment.

**Expected UI result**
- Same comment-posting behavior as every other test; 🚩 greys out.

**Backend verification**
- HealthyCommunity's `app` logs show `401`s on the `/v1/events` call.
- Confirm no new `COMMENT` action was created for this comment's resource (same lookup
  as Test 1) — only whatever existed before this test should be there.

**Pass criteria:** an invalid key degrades exactly like an unreachable service —
commenting still succeeds, HealthyCommunity's data is untouched for this attempt.

---

## Test 7 (optional) — Circuit breaker trips after repeated failures

Same resilience check as [Step 1's Test 7](step_1_plus_integration_tests.md#test-7-optional--circuit-breaker-trips-after-repeated-failures)
and [Step 5's Test 7](step_5_integration_tests.md#test-7-optional--circuit-breaker-trips-after-repeated-failures),
exercised through comments.

**Setup:** same as Test 5 (CH enabled, unreachable URL).

**Steps (Underlined UI)**
1. Post 5+ comments/replies in a row in quick succession.

**Expected UI result**
- All posts complete at normal speed — the shared circuit breaker
  (`CommunityHealthCircuitBreaker`) trips after 5 consecutive failures regardless of
  which action type or integration point is failing.

**Pass criteria:** comment #6+ feels no slower than comment #1.

---

## Summary checklist

| # | Scenario | UI must look like |
|---|----------|--------------------|
| 1 | CH enabled, reachable, accepts | Normal comment; `COMMENT` action recorded, `context.parent_type == "comment"` |
| 2 | Reply to that comment | Separate `COMMENT` action, `context.parent_type == "reply"` |
| 3 | Reporting a comment | 🚩 active; reason dropdown populated; report recorded, scoped to the comment |
| 4 | `COMMUNITY_HEALTH_ENABLED=false` (prod default) | Normal comment/reply; 🚩 greyed out; zero CH I/O |
| 5 | CH enabled, unreachable | Normal comment/reply; 🚩 greyed out; job retries then discards, logged |
| 6 | CH enabled, invalid API key | Normal comment/reply; 🚩 greyed out; job retries then discards, logged |
| 7 | Repeated failures | No added latency on later comments |

If every row's "UI must look like" column holds, Step 6's Community Health integration
is safe to run in production with `COMMUNITY_HEALTH_ENABLED=false` while HealthyCommunity
itself stays local/undeployed — the same posture every earlier step established, now
proven for comments and replies as well.
