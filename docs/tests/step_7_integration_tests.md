# Manual Test Plan — Community Health Integration (Step 7: Follow Users)

Scope: [roadmap.md](../base_content/roadmap.md) Step 7 pairs with
[CH-Step 3 (Generic Resource & Action Ingestion)](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md) —
no new HealthyCommunity code was needed for this step; `record_action` already accepts
any `action_type` and `resource_type`. Every test below interacts only with Underlined's
UI (`http://localhost:3000`) — the Follow button on a profile page. Community Health
sync is invisible bookkeeping, same principle as [Step 1's doc](step_1_plus_integration_tests.md),
[Step 3's doc](step_3_plus_integration_tests.md), and [Step 5's doc](step_5_integration_tests.md):
following/unfollowing must look and behave **identically** whether the integration is
on, off, or broken. Unlike Steps 4 and 6, there is **no Report-style control gated on
CH here** — per HealthyCommunity's own roadmap, Step 7's frontend update is "none": the
Follow button's filled/outlined state reflects the follow relationship itself, never
the kill switch.

Like Step 5's likes, a user can follow, unfollow, and re-follow the same person many
times, so each toggle needs its own event: `FollowUserUsecase` emits
`action_type: "FOLLOW"` and `UnfollowUserUsecase` emits `"UNFOLLOW"`, both
`resource_type: "actor"`, `resource_id: <followee_id>`. `event_key` includes a
microsecond timestamp — `"follow:create:<follower_id>:<followee_id>:<timestamp>"`
(`follow:remove:` for the other) — rather than a static per-pair key, for the same
reason Step 5's `REACT`/`UNREACT` needs one: CH's idempotency constraint is
`[platform_id, event_key]`, and two *different* toggles of the same follow relationship
by the same actor must not collide into a single row the way two identical retries of
the same toggle should. The `following` boolean returned to the UI stays the only
source of truth the UI ever renders from — CH is never read to show follow state or
decide whether a follow can happen.

For raw setup commands (starting stacks, registering the platform), see
[integration.md](integration.md) — this file assumes those work.

## Before you start

- Both repos checked out: `Underlined` and `HealthyCommunity`.
- You have two **enabled** users to log in with (see
  [Step 1's doc](step_1_plus_integration_tests.md#finding-a-users-id-and-why-signing-up-isnt-enough-to-log-in)) —
  one to act as the follower, one to be the followee.
- All DB verification below uses `docker compose exec api iex -S mix` (Underlined) and
  `docker compose exec app iex -S mix` (HealthyCommunity) — never `psql` — with:
  ```elixir
  # HealthyCommunity
  alias CommunityHealth.Repo
  alias CommunityHealth.Actions.CommunityAction
  import Ecto.Query
  ```

---

## Test 1 — Following a user records a FOLLOW action (happy path)

**Setup**
1. Start HealthyCommunity: `cd HealthyCommunity && docker compose up -d postgres app`
2. Register the platform once and copy the printed API key (skip if already
   registered from earlier testing):
   `docker compose exec app mix community_health.register_platform "Underlined"`
3. Start Underlined with the integration **on**:
   `cd Underlined && COMMUNITY_HEALTH_ENABLED=true COMMUNITY_HEALTH_API_KEY="<key>" docker compose up -d`

**Steps (Underlined UI)**
1. Log in as the follower, visit the followee's profile page.
2. Click the Follow button.

**Expected UI result**
- The button fills solid ink-blue with a checkmark immediately — exactly as it does
  with the integration fully removed. No loading delay, no error.

**Backend verification**
```elixir
followee_id = "<the followee's user id>"

action =
  Repo.one(
    from a in CommunityAction,
      join: r in assoc(a, :resource),
      where: a.action_type == "FOLLOW" and r.external_ref == ^followee_id,
      order_by: [desc: a.inserted_at],
      limit: 1
  )

action.action_type  # => "FOLLOW"
```

**Pass criteria:** the Follow UI is unaffected AND, within a few seconds (processed by
an Oban job after the HTTP response), exactly one new `community_actions` row with
`action_type: "FOLLOW"` exists for this followee.

---

## Test 2 — Unfollowing records UNFOLLOW, and re-following doesn't collide with the first FOLLOW

**Setup:** continue from Test 1, same follower and followee.

**Steps (Underlined UI)**
1. Click the Follow button again to unfollow.
2. Click it once more to re-follow.

**Expected UI result**
- The button toggles back and forth normally each time (filled ↔ outlined), with no
  error or stall.

**Backend verification**
```elixir
followee_id = "<the same followee id>"

actions =
  Repo.all(
    from a in CommunityAction,
      join: r in assoc(a, :resource),
      where: r.external_ref == ^followee_id,
      order_by: [asc: a.inserted_at],
      select: {a.action_type, a.event_key}
  )
```

**Pass criteria:** the list now has **three** distinct rows — `FOLLOW`, `UNFOLLOW`,
`FOLLOW` — each with a different `event_key` (the trailing timestamp differs each
time). None of them were silently dropped by CH's `[platform_id, event_key]`
uniqueness constraint, which is exactly why the key can't be a static
`follow:create:<follower_id>:<followee_id>`.

---

## Test 3 — Following twice in a row still only shows as following once

**Setup:** continue from Test 2. The follower currently follows the followee.

**Steps (Underlined UI)**
1. Submit a second follow request for the same pair (e.g. via a direct API replay, or
   a stray double-click before the button's state updates).

**Backend verification**
```elixir
# Underlined
alias Api.Repo
alias Api.Infrastructure.Repository.Follow.Postgres.Follow
import Ecto.Query

Repo.aggregate(from(f in Follow, where: f.followee_id == ^followee_id), :count)
```

**Pass criteria:** there is still exactly one `follows` row for this pair —
`FollowUserUsecase`'s underlying repository call is itself idempotent on the
`(follower, followee)` pair regardless of how many `FOLLOW` events CH ends up
recording for it. CH's event log and Underlined's `follows` table are deliberately two
separate concerns, the same split Step 5 established for likes.

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
1. Follow, then unfollow, a user as usual.

**Expected UI result**
- Identical to Tests 1–2 — the button fills/empties normally, no error, no slow
  spinner. There is no Report-style control to grey out here — Step 7, unlike Steps 4
  and 6, adds no new UI element that depends on CH.

**Backend verification (Underlined side only — HealthyCommunity is down)**
- `docker compose logs api` shows no HTTP calls attempted to port 4100.
- Optionally confirm the no-op adapter is active:
  ```elixir
  Application.get_env(:api, :community_health, Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop)
  # => Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop
  ```

**Pass criteria:** following/unfollowing works normally with HealthyCommunity
completely absent — the integration fails *closed*, exactly as it does for Steps 1, 3,
and 5.

---

## Test 5 — Kill switch: Community Health unreachable (network failure)

Same scenario as [Step 5's Test 5](step_5_integration_tests.md#test-5--kill-switch-community-health-unreachable-network-failure),
exercised through a follow instead of a like.

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
1. Follow a user.

**Expected UI result**
- Same button-fill as Test 1. Following must not hang or error even though the sync
  attempt behind the scenes will fail.

**Backend verification**
- `docker compose logs -f api` shows the job retrying (`CommunityHealthClient`
  returning a connection error) at Oban's default backoff cadence, same discard path
  documented in earlier steps.

**Pass criteria:** following is unaffected by CH being unreachable.

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
1. Follow a user.

**Expected UI result**
- Same button-fill as every other test.

**Backend verification**
- HealthyCommunity's `app` logs show `401`s on the `/v1/events` call.
- Confirm no new `FOLLOW` action was created for this followee's resource (same lookup
  as Test 1) — only whatever existed before this test should be there.

**Pass criteria:** an invalid key degrades exactly like an unreachable service —
following still succeeds, HealthyCommunity's data is untouched for this attempt.

---

## Test 7 (optional) — Circuit breaker trips after repeated failures

Same resilience check as [Step 1's Test 7](step_1_plus_integration_tests.md#test-7-optional--circuit-breaker-trips-after-repeated-failures)
and [Step 5's Test 7](step_5_integration_tests.md#test-7-optional--circuit-breaker-trips-after-repeated-failures),
exercised through follows.

**Setup:** same as Test 5 (CH enabled, unreachable URL).

**Steps (Underlined UI)**
1. Follow/unfollow 5+ times in a row in quick succession, across one or more profiles.

**Expected UI result**
- All toggles complete at normal speed — the shared circuit breaker
  (`CommunityHealthCircuitBreaker`) trips after 5 consecutive failures regardless of
  which action type or integration point is failing.

**Pass criteria:** toggle #6+ feels no slower than toggle #1.

---

## Summary checklist

| # | Scenario | UI must look like |
|---|----------|--------------------|
| 1 | CH enabled, reachable, accepts | Normal follow; `FOLLOW` action recorded |
| 2 | Unfollow then re-follow | `UNFOLLOW` then a second, distinct `FOLLOW` row |
| 3 | Rapid repeat click while already following | `follows` row doesn't duplicate |
| 4 | `COMMUNITY_HEALTH_ENABLED=false` (prod default) | Normal follow/unfollow; zero CH I/O; no control to grey out |
| 5 | CH enabled, unreachable | Normal follow/unfollow; job retries then discards, logged |
| 6 | CH enabled, invalid API key | Normal follow/unfollow; job retries then discards, logged |
| 7 | Repeated failures | No added latency on later toggles |

If every row's "UI must look like" column holds, Step 7's Community Health integration
is safe to run in production with `COMMUNITY_HEALTH_ENABLED=false` while HealthyCommunity
itself stays local/undeployed — the same posture every earlier step established, now
proven for follows as well, and the lowest-priority retrofit of the seven is caught up
with the rest.
