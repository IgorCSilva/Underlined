# Manual Test Plan — Community Health Integration (Step 4: Global Feed & Post Detail Page)

Scope: [roadmap.md](../base_content/roadmap.md) Step 4 pairs with
[CH-Step 4 (Community Rules)](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md)
and [CH-Step 5 (Reports)](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md).
Every test below interacts only with Underlined's UI (`http://localhost:3000`) — the
feed (`/feed`) and a post's detail page (`/posts/<id>`).

Unlike Steps 1/3/5 — where Community Health is invisible bookkeeping riding along on an
action that works identically either way — the 🚩 **Report** control's very existence
depends on Community Health: Underlined keeps no local notion of moderation at all, so
when CH is off/unreachable/rejecting, the correct behavior is **not** "report silently
succeeds" but "the control visibly greys out and can't be used," per the
`CommunityHealthGate` contract. That's the main thing these tests are checking —
the opposite failure mode from the earlier docs.

Reporting has two moving parts, in order:
1. A **read**, synchronous, with a timeout + fallback: `GET /api/reports/reasons` asks
   CH for the community's currently *active* rules (CH-Step 4) to populate the reason
   dropdown, and returns `community_health_available` alongside them. The frontend's
   `CommunityHealthGate` wraps the 🚩 button itself using that flag.
2. A **write**, fire-and-forget via Oban, exactly like Steps 3/5's events:
   `POST /api/reports` enqueues a job that calls CH-Step 5's `POST /v1/reports`,
   idempotent on `[platform, resource, reporter]` — reporting the same content twice
   never creates two rows.

For raw setup commands (starting stacks, registering the platform), see
[integration.md](integration.md) — this file assumes those work.

## Before you start

- Both repos checked out: `Underlined` and `HealthyCommunity`.
- You have one **enabled** user to log in with (see
  [Step 1's doc](step_1_plus_integration_tests.md#finding-a-users-id-and-why-signing-up-isnt-enough-to-log-in)).
- You have at least one published post (see [Step 3's doc](step_3_plus_integration_tests.md))
  to report — the composer's "View post" link gives you its id, same as before.
- A community needs at least one **active rule** before a report can cite it as a
  reason. Rules are provisioned out-of-band (not self-service, same reasoning as
  platform registration):
  ```
  docker compose exec app mix community_health.add_rule underlined default PERSONAL_ATTACK \
    "Personal attack" high "Attacks another reader rather than discussing the book."
  docker compose exec app mix community_health.add_rule underlined default SPAM "Spam" low
  ```
- All DB verification below uses `docker compose exec api iex -S mix` (Underlined) and
  `docker compose exec app iex -S mix` (HealthyCommunity) — never `psql` — with:
  ```elixir
  # HealthyCommunity
  alias CommunityHealth.Repo
  alias CommunityHealth.Reports.Report
  alias CommunityHealth.Rules.CommunityRule
  import Ecto.Query
  ```

---

## Test 1 — Reasons populate and the Report control is active (happy path)

**Setup**
1. Start HealthyCommunity: `cd HealthyCommunity && docker compose up -d postgres app`
2. Register the platform + community + rules (see "Before you start") if not already
   done.
3. Start Underlined with the integration **on**:
   `COMMUNITY_HEALTH_ENABLED=true COMMUNITY_HEALTH_API_KEY="<key>" docker compose up -d`

**Steps (Underlined UI)**
1. Log in, go to `http://localhost:3000/feed`.
2. Find a post and look at its action row (like icon, comment count, 🚩).

**Expected UI result**
- The 🚩 button is fully opaque/clickable (not greyed out).
3. Click it.
4. A modal opens with a "Reason" dropdown.

**Expected UI result**
- The dropdown lists exactly the active rules you provisioned ("Personal attack",
  "Spam"), by name. No loading spinner stall, no error.
5. Select "Personal attack", optionally type a description, click "Submit report".

**Expected UI result**
- The modal shows a thank-you/confirmation state. No page reload, no error.

**Backend verification**
1. In HealthyCommunity's iex shell:
   ```elixir
   report = Repo.one(from r in Report, order_by: [desc: r.id], limit: 1)
   report.reason          # => "PERSONAL_ATTACK"
   report.status          # => "pending"
   ```

**Pass criteria:** the reason dropdown reflects CH's active rules exactly, and
submitting creates exactly one `reports` row with the chosen reason and "pending"
status — nothing happens to the reported post itself (per CH-Step 5's own scope: a
report records a flag, not a moderation decision).

---

## Test 2 — Reporting the same content twice doesn't duplicate (idempotency)

**Setup:** continue from Test 1, same logged-in user, same post.

**Steps (Underlined UI)**
1. Open the Report modal on the **same post** again and submit again (any reason).

**Backend verification**
```elixir
Repo.aggregate(
  from(r in Report, where: r.reporter_external_id == ^"<the user's id>"),
  :count
)
# => 1
```

**Pass criteria:** the count stays **1** — `[platform_id, resource_id,
reporter_external_id]` is the idempotency contract, so the same actor flagging the
same resource again (a UI double-click, or an Oban retry replaying a submission that
timed out) updates nothing and creates no second row. A **different** post, or the
same post reported by a **different** user, does create a new row — that's not what
this test checks, but is worth knowing isn't blocked by this constraint.

---

## Test 3 — Kill switch: integration disabled (the production default)

This is the configuration Underlined will actually run in production
(`COMMUNITY_HEALTH_ENABLED=false`). Unlike Steps 1/3/5, the Report control doesn't
just keep working invisibly here — it's expected to visibly grey out, since its
_entire reason for existing_ is CH.

**Setup**
1. Stop HealthyCommunity entirely (or leave it down).
2. Start/restart Underlined with the flag off:
   `COMMUNITY_HEALTH_ENABLED=false docker compose up -d` (or omit the var — `false` is
   the default).

**Steps (Underlined UI)**
1. Go to the feed or a post detail page.

**Expected UI result**
- The 🚩 button is still **visible** (per the kill-switch contract — never hidden) but
  rendered at reduced opacity/greyscale, and clicking it does nothing (`pointer-events:
  none`). Hovering may show a "Community features are temporarily unavailable" tooltip.
- Everything else on the page (like button, comments, the feed itself) behaves
  completely normally — only the Report control is affected.

**Backend verification**
- `docker compose logs api` shows no HTTP calls attempted to port 4100.
- Confirm the no-op adapter is active:
  ```elixir
  Application.get_env(:api, :community_health, Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop)
  # => Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop
  ```

**Pass criteria:** the Report control greys out identically to how it will in
production — the rest of the page is completely unaffected by Community Health's
absence.

---

## Test 4 — Kill switch: Community Health unreachable (network failure)

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
1. Go to the feed or a post detail page.

**Expected UI result**
- Same greyed-out 🚩 as Test 3 — the `GET /api/reports/reasons` read times out/fails,
  `community_health_available` comes back `false`, and the gate greys the button. No
  page hang, no visible error, no console-breaking exception.

**Pass criteria:** an unreachable CH degrades to the exact same visual state as CH
being intentionally disabled — the frontend never needs to distinguish the two.

---

## Test 5 — Kill switch: Community Health rejects the request (bad API key)

**Setup**
1. Make sure HealthyCommunity is running: `cd HealthyCommunity && docker compose up -d postgres app`
2. Start Underlined with an intentionally wrong key:
   ```
   COMMUNITY_HEALTH_ENABLED=true \
   COMMUNITY_HEALTH_API_KEY=this-is-not-a-real-key \
   docker compose up -d
   ```

**Steps (Underlined UI)**
1. Go to the feed or a post detail page.

**Expected UI result**
- Same greyed-out 🚩 as Tests 3 and 4.

**Backend verification**
- HealthyCommunity's `app` logs show `401`s on the rules-lookup call.

**Pass criteria:** an invalid key degrades exactly like an unreachable or disabled
service — the greyed-out state is the single signal regardless of which of the three
failure modes is in play.

---

## Test 6 — Submitting a reason that isn't an active rule is rejected

This exercises the backend validation directly — it shouldn't be reachable from the
UI (the dropdown only ever offers active rules), but the API itself must not trust
the client.

**Setup:** CH enabled and reachable, as in Test 1.

**Steps**
```
docker compose exec api iex -S mix
```
```elixir
alias Api.Adapters.Posts
alias Api.Usecases.Report.CreateReport.CreateReportUsecaseDto

Posts.create_report(%CreateReportUsecaseDto{
  user: %{id: "<any user id>"},
  attrs: %{
    "resource_type" => "post",
    "resource_id" => "<any post id>",
    "reason" => "NOT_A_REAL_RULE_CODE"
  }
})
```

**Expected result**
- The Oban job is enqueued regardless (Underlined doesn't know which rules are
  active — that's CH's job); when the job runs, CH's `POST /v1/reports` returns `422`
  because `"NOT_A_REAL_RULE_CODE"` isn't one of the community's active rules, and the
  job is discarded/logged after Oban's retry budget, same as any other CH rejection.
- No `reports` row is created in HealthyCommunity for this submission.

**Pass criteria:** an invalid reason code never produces a phantom report — CH is the
single source of truth for which rules are currently enforceable, and rejects
anything else.

---

## Test 7 — Reporting requires authentication

**Steps**
- Attempt `GET /api/reports/reasons` and `POST /api/reports` without an
  `Authorization` header (e.g. from a logged-out browser tab, or directly).

**Expected result**
- Both return `401`. In the UI, a logged-out visitor viewing the feed/post detail page
  never sees a functional Report control reachable without first logging in (same
  authentication boundary as the Like button).

**Pass criteria:** no reporting identity can ever be anonymous — `reporter_external_id`
on the CH side always traces back to a real, authenticated Underlined user.

---

## Test 8 (optional) — Circuit breaker trips after repeated failures

Same resilience check as [Step 1's Test 7](step_1_plus_integration_tests.md#test-7-optional--circuit-breaker-trips-after-repeated-failures)
and [Step 3's Test 7](step_3_plus_integration_tests.md#test-7-optional--circuit-breaker-trips-after-repeated-failures),
exercised through the reasons read instead of a write.

**Setup:** same as Test 4 (CH enabled, unreachable URL).

**Steps (Underlined UI)**
1. Load the feed page 5+ times in a row in quick succession (each load triggers a
   `GET /api/reports/reasons` the first time a `ReportButton` mounts on that page).

**Expected UI result**
- All loads complete at normal speed — the shared circuit breaker
  (`CommunityHealthCircuitBreaker`) trips after 5 consecutive failures regardless of
  which integration point is failing, so repeated CH failures can't pile up latency on
  the feed itself.

**Pass criteria:** feed load #6+ feels no slower than load #1, and the 🚩 button is
greyed out throughout — consistent with Tests 3–5, never a hang.

---

## Summary checklist

| # | Scenario | UI must look like |
|---|----------|--------------------|
| 1 | CH enabled, reachable, accepts | 🚩 active; reasons populated; report recorded |
| 2 | Same actor reports same content twice | No duplicate report row |
| 3 | `COMMUNITY_HEALTH_ENABLED=false` (prod default) | 🚩 visible but greyed out, disabled |
| 4 | CH enabled, unreachable | 🚩 greyed out, same as disabled |
| 5 | CH enabled, invalid API key | 🚩 greyed out, same as disabled |
| 6 | Reason isn't an active rule | Rejected by CH; no report row created |
| 7 | No auth | `401` on both endpoints |
| 8 | Repeated failures | No added latency on later feed loads |

If every row's "UI must look like" column holds, Step 4's Community Health
integration is safe to run in production with `COMMUNITY_HEALTH_ENABLED=false` while
HealthyCommunity itself stays local/undeployed — the Report control simply greys out,
exactly as designed, and the rest of the feed/post-detail experience is completely
unaffected.
