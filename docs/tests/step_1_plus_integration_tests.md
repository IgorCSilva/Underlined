# Manual Test Plan — Community Health Integration (Step 1: User Accounts)

Scope: [roadmap.md](../base_content/roadmap.md) Step 1 pairs with
[CH-Step 1 (Platform Registration) and CH-Step 2 (Community & Membership)](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md).
Every test below interacts only with Underlined's UI (`http://localhost:3000`) —
signup and profile edit. Community Health sync is invisible bookkeeping: the Underlined
UI must look and behave **identically** whether the integration is on, off, or broken.
The point of every test case here is "the user never notices," confirmed on the
Underlined side, with a backend peek into HealthyCommunity only to prove the sync
actually happened (or correctly didn't).

For raw setup commands (starting stacks, registering the platform, iex snippets),
see [integration.md](integration.md) — this file assumes those work and focuses on
*what to click* and *what to expect*, test-case by test-case.

## Before you start

- **Start from empty databases.** This file assumes both Underlined's and
  HealthyCommunity's databases are empty before Test 1 — a fresh dev environment
  already satisfies that. If you're re-running this file (or picking it up after other
  testing), empty both first using
  ["Resetting both databases to empty"](#resetting-both-databases-to-empty) below —
  the same two snippets this file's [Cleanup](#cleanup) section ends with.
- Both repos checked out: `Underlined` and `HealthyCommunity`.
- You can bring up Underlined's stack (`docker compose up -d`) and, separately,
  HealthyCommunity's `postgres` + `app` services.
- Underlined's `web` is reachable at `http://localhost:3000`, `api` at
  `http://localhost:4000`.

### Resetting both databases to empty

Truncates every application table (everything except `schema_migrations`) without
dropping/recreating the database or restarting any container — only the rows are gone,
schema and running services stay untouched. Every later test file's Setup/Cleanup
sections link back here instead of repeating this.

**Underlined** — `docker compose exec api iex -S mix`:
```elixir
alias Api.Repo

{:ok, %{rows: rows}} =
  Ecto.Adapters.SQL.query(Repo, "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename != 'schema_migrations'")

tables = List.flatten(rows)
Ecto.Adapters.SQL.query!(Repo, "TRUNCATE TABLE #{Enum.join(tables, ", ")} RESTART IDENTITY CASCADE")
```

**HealthyCommunity** — `docker compose exec app iex -S mix`:
```elixir
alias CommunityHealth.Repo

{:ok, %{rows: rows}} =
  Ecto.Adapters.SQL.query(Repo, "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename != 'schema_migrations'")

tables = List.flatten(rows)
Ecto.Adapters.SQL.query!(Repo, "TRUNCATE TABLE #{Enum.join(tables, ", ")} RESTART IDENTITY CASCADE")
```

Running the HealthyCommunity snippet also wipes `platforms`/`api_keys` — the platform
registration from
["Finding a user's id" below](#finding-a-users-id-and-why-signing-up-isnt-enough-to-log-in)
and from every test's own Setup step doesn't survive it. That's expected: each test's
Setup already re-registers the platform and restarts Underlined with the freshly
printed key, so nothing extra is needed — just know the key changes every time you
truncate.

### Finding a user's id, and why signing up isn't enough to log in

Every test below needs the new user's `id` — that's `actor_external_id` on the
HealthyCommunity side. Signup doesn't return it anywhere visible in the UI, and it
doesn't log you in either: email sending is disabled in dev, so `auth_controller.ex`
creates every new account with `enabled: false` and there's no confirmation email to
click (see the comment at `api/lib/api_web/controllers/auth_controller.ex:30-35`).
Logging in before flipping that flag fails with `403 account pending confirmation`.

Look both values up (and fix the second one) through Underlined's own API backend —
never with a raw `psql`/SQL client, always `iex -S mix` inside the running `api`
container, right after signing up:

```
docker compose exec api iex -S mix
```
```elixir
alias Api.Repo
alias Api.Infrastructure.Repository.User.Postgres.User
import Ecto.Query

user = Repo.one(from u in User, where: u.email == "<the email you used at signup>")
user.id
user.enabled
```

If a test needs you to actually log in through the UI (Test 2 does), flip `enabled` to
true the same way, from that same shell:

```elixir
{:ok, user} = user |> Ecto.Changeset.change(enabled: true) |> Repo.update()
```

Keep the printed `user.id` handy — every `actor_id = "..."` line in the iex snippets
below is that value. (Once logged in, the same id is also the `sub` claim of the JWT
stored in the `auth` Pinia store/`accessToken` — `jwt.io` can decode it if you'd rather
read it off the token, but the query above works even for users who never logged in.)

---

## Test 1 — Signup syncs a new user as a Community Health member (happy path)

**Setup**
1. Start HealthyCommunity: `cd HealthyCommunity && docker compose up -d postgres app`
2. Register the platform once and copy the printed API key:
   `docker compose exec app mix community_health.register_platform "Underlined"`
3. Start Underlined with the integration **on**:
   `cd Underlined && COMMUNITY_HEALTH_ENABLED=true COMMUNITY_HEALTH_API_KEY="<key>" docker compose up -d`

**Steps (Underlined UI)**
1. Open `http://localhost:3000/signup`.
2. Fill in Name, Email, Password (8+ chars) and submit. Use an email you can
   remember exactly — you'll look the account up by it next.

**Expected UI result**
- The form shows the normal success message and a "back to login" link — exactly as
  it does with the integration fully removed. No loading delay, no error, nothing on
  screen hints that a second system exists.

**Backend verification**
1. Look up the new user's `id` via Underlined's own `api` container, per
   ["Finding a user's id" above](#finding-a-users-id-and-why-signing-up-isnt-enough-to-log-in):
   ```
   docker compose exec api iex -S mix
   ```
   ```elixir
   alias Api.Repo
   alias Api.Infrastructure.Repository.User.Postgres.User
   import Ecto.Query

   user = Repo.one(from u in User, where: u.email == "igor.carneiro.silva13@gmail.com")
   user.id
   ```
2. Open a separate iex shell inside HealthyCommunity's `app` container and check for a
   membership with that id as `actor_external_id`:
   ```
   docker compose exec app iex -S mix
   ```
   ```elixir
   alias CommunityHealth.Repo
   alias CommunityHealth.Communities.Membership
   import Ecto.Query

   actor_id = "<the id from step 1>"
   Repo.exists?(from m in Membership, where: m.actor_external_id == ^actor_id)
   ```

**Pass criteria:** signup UI is unaffected AND the membership row exists within a few
seconds (it's processed by an Oban job after the HTTP response, not inline — allow a
short delay before checking).

---

## Test 2 — Editing your profile re-syncs without duplicating anything

**Setup:** continue from Test 1, using the same user and `actor_id`. Signup alone
doesn't log you in (see above) — flip the account to enabled from the `api` container's
iex shell, then log in through the UI:
```elixir
user = Repo.one(from u in User, where: u.email == "<the email from Test 1>")
{:ok, user} = user |> Ecto.Changeset.change(enabled: true) |> Repo.update()
```
Then go to `http://localhost:3000/login` and sign in with that email/password.

**Steps (Underlined UI)**
1. Go to `http://localhost:3000/profile/edit`.
2. Change the Name field (and optionally bio/avatar) and save.
3. Repeat step 2 a second time with a different name.

**Expected UI result**
- Both saves redirect to `/profile` normally, showing the updated name each time.

**Backend verification**
```elixir
Repo.aggregate(from(m in Membership, where: m.actor_external_id == ^actor_id), :count)
```
**Pass criteria:** the count is still **1** after multiple edits — `ensure_member` is
idempotent (`on_conflict: :nothing` on `[community_id, actor_external_id]`), so re-saving
your profile never creates a second membership row for the same user/community.

---

## Test 3 — Kill switch: integration disabled (the production default)

This is the configuration Underlined will actually run in production
(`COMMUNITY_HEALTH_ENABLED=false`), so it's the most important case to verify.

**Setup**
1. Stop HealthyCommunity entirely (or just leave it down — doesn't matter, Underlined
   must never need it): `docker compose down` in HealthyCommunity, or skip starting it.
2. Start/restart Underlined with the flag off:
   `COMMUNITY_HEALTH_ENABLED=false docker compose up -d` (or just omit the var — `false`
   is the default in `docker-compose.yml`).

**Steps (Underlined UI)**
1. Sign up a brand-new user at `/signup`.
2. Log in, edit the profile at `/profile/edit`, save.

**Expected UI result**
- Identical to Test 1/2 — success message, redirect, updated profile. No error banner,
  no slow spinner, nothing different.

**Backend verification (Underlined side only — HealthyCommunity is down)**
- Check the API logs (`docker compose logs api`) — there should be **no** HTTP calls
  attempted to port 4100 and no errors logged about Community Health.
- Optionally confirm via `docker compose exec api iex -S mix` that the resolved
  adapter is the no-op one:
  ```elixir
  Application.get_env(:api, :community_health, Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop)
  # => Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop
  ```

**Pass criteria:** signup/profile-edit work normally with HealthyCommunity completely
absent; the no-op adapter is in play, confirming the integration fails *closed*.

---

## Test 4 — Kill switch: Community Health unreachable (network failure)

Simulates CH being up for other traffic but unreachable from Underlined (deploy
mismatch, firewall, CH mid-restart, wrong URL).

**Setup**
1. Start Underlined with the integration **on** but pointed at a URL nothing is
   listening on:
   ```
   COMMUNITY_HEALTH_ENABLED=true \
   COMMUNITY_HEALTH_API_URL=http://host.docker.internal:4999 \
   COMMUNITY_HEALTH_API_KEY=anything \
   docker compose up -d
   ```
   (port 4999 is just unused — nothing needs to run there.)

**Steps (Underlined UI)**
1. Sign up a new user at `/signup`.

**Expected UI result**
- Same success message as every other test. Signup must not hang or error even though
  every sync attempt behind the scenes will fail.

**Backend verification (Underlined side)**
- `docker compose logs -f api` shows the job being attempted and failing repeatedly
  (`CommunityHealthClient` returning a connection error). Each retry is spaced out by
  Oban's default backoff — `attempt⁴ + 15 + jitter` seconds — which for
  `max_attempts: 8` adds up to roughly **80 minutes** before the 8th attempt fails and
  the job is discarded. Don't expect the discard line within a normal test session;
  seeing the retries happening (not blocking signup, not visible to the user) is
  already the pass condition for this test.
- To actually see the discard line — `CommunityHealthWorker discarded after N
  attempts: ...` — without waiting ~80 minutes, force one from the `api` container's
  iex shell instead of going through `/signup`: insert the same job the usecases
  enqueue, but with `max_attempts: 1` so it discards right after its first (still
  real, still network-failing) attempt:
  ```
  docker compose exec api iex -S mix
  ```
  ```elixir
  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker

  job =
    CommunityHealthWorker.new(
      %{action: "ensure_member", actor_id: "test-actor-id", community_id: "default"},
      max_attempts: 1
    )

  Oban.insert(job)
  ```
  Oban picks it up within a couple seconds; watch `docker compose logs -f api` for the
  discard line to appear almost immediately.

**Pass criteria:** signup is unaffected by CH being completely unreachable; retries
happen out of band at the default backoff cadence, and the forced `max_attempts: 1`
job confirms the discard/log path actually fires rather than retrying forever.

---

## Test 5 — Kill switch: Community Health rejects the request (bad API key)

Simulates an expired/invalid key — the "CH is up but says no" failure mode, distinct
from "CH is down."

**Setup**
1. Make sure HealthyCommunity is actually running this time:
   `cd HealthyCommunity && docker compose up -d postgres app`
2. Start Underlined with the integration on but an intentionally wrong key:
   ```
   COMMUNITY_HEALTH_ENABLED=true \
   COMMUNITY_HEALTH_API_KEY=this-is-not-a-real-key \
   docker compose up -d
   ```

**Steps (Underlined UI)**
1. Sign up a new user at `/signup`, with a new email you haven't used in another test.

**Expected UI result**
- Same as every other test — unaffected signup flow.

**Backend verification**
- HealthyCommunity's `app` logs show `401`s on `/v1/communities` / membership calls
  (`ApiKeyAuth` rejecting the bad token).
- Underlined's `api` logs show the job retrying at the same ~80-minute-to-discard
  cadence as Test 4 (use the same `max_attempts: 1` trick there if you want to force
  the discard line quickly) — Underlined treats "rejected" and "unreachable"
  identically, as the roadmap's kill-switch contract requires.
- Confirm no membership row was created for this user. Look up its id the same way as
  Test 1, from the `api` container's iex shell (`Repo.one(from u in User, where: u.email
  == "...")`), then in HealthyCommunity's iex shell:
  ```elixir
  actor_id = "<the id you just looked up>"
  Repo.exists?(from m in Membership, where: m.actor_external_id == ^actor_id)
  # => false
  ```

**Pass criteria:** an invalid key degrades exactly like an unreachable service — signup
still succeeds, and HealthyCommunity's own data is untouched for that user.

---

## Test 6 — Backfill existing users

Covers users created while the integration was off (or before it existed).

**Setup**
1. With CH disabled, sign up 1–2 users via the UI (`/signup`) so they exist in
   Underlined's DB without any CH membership.
2. Bring the integration up correctly (valid key, HealthyCommunity running — same as
   Test 1).
3. Run the one-time backfill:
   `docker compose exec api mix community_health.backfill_members`

**Steps (Underlined UI)**
- None — this test is entirely about reconciling past signups; nothing to click.

**Backend verification**
1. List the ids you're checking for, from the `api` container's iex shell:
   ```elixir
   Repo.all(from u in User, select: {u.id, u.email})
   ```
2. For each `id` printed above, confirm a membership now exists in HealthyCommunity's
   iex shell:
   ```elixir
   actor_id = "<one of the ids from step 1>"
   Repo.exists?(from m in Membership, where: m.actor_external_id == ^actor_id)
   ```

**Pass criteria:** every user who signed up before the integration was enabled now has
a membership row after the backfill runs, without needing to touch the Underlined UI
at all.

---

## Test 7 (optional) — Circuit breaker trips after repeated failures

More of a resilience/perf check than a UI check, included because it's easy to verify
alongside Test 4.

**Setup:** same as Test 4 (CH enabled, unreachable URL).

**Steps (Underlined UI)**
1. Sign up 5+ new users in a row at `/signup` in quick succession.

**Expected UI result**
- All signups complete at normal speed — the circuit breaker
  (`CommunityHealthCircuitBreaker`, trips after 5 consecutive failures, 30s cooldown)
  exists specifically so repeated CH failures don't add latency to *later* requests by
  piling up timeouts.

**Pass criteria:** signup #6+ feels no slower than signup #1, even though every one of
them is failing to reach CH behind the scenes.

---

## Account & authentication edge cases

These don't depend on Community Health being on, off, or reachable at all — they're
Step 1's own account rules (`User.registration_changeset/2`, `AuthController.login/2`).
They're here because they sit right next to Tests 1–2 in the same signup/login flow,
and because a few of them double-check that a **rejected** signup never reaches Community
Health either — only a successfully *created* user is ever synced.

### Test 8 — Signup rejects an already-registered email

**Steps (Underlined UI)**
1. Sign up successfully at `/signup` with a fresh email (e.g. `dup@example.com`).
2. Go back to `/signup` and submit the exact same email again (any name/password).

**Expected UI result**
- The second submission is rejected inline with a "has already been taken"-style error
  on the email field; no redirect, no success message.

**Backend verification**
```
docker compose exec api iex -S mix
```
```elixir
alias Api.Repo
alias Api.Infrastructure.Repository.User.Postgres.User
import Ecto.Query

Repo.aggregate(from(u in User, where: u.email == "dup@example.com"), :count)
# => 1 (the second attempt never inserted a row)
```
**Pass criteria:** exactly one user row exists for that email — the duplicate attempt
is rejected at the changeset level (`unsafe_validate_unique` + a DB `unique_constraint`
as a race-safe backstop) and never reaches `enqueue_community_health_sync/1`.

---

### Test 9 — Signup rejects a weak (too short) password

**Steps (Underlined UI)**
1. Go to `/signup` and submit the form with a password under 8 characters (e.g. `abc123`)
   and a fresh email.

**Expected UI result**
- Inline validation error on the password field (minimum length), no account created,
  no redirect.

**Backend verification**
```elixir
Repo.aggregate(from(u in User, where: u.email == "<the email you used above>"), :count)
# => 0
```
**Pass criteria:** no row was created (`validate_length(:password, min: 8, max: 72)`
fails before insert) and — since no user exists — no membership can exist for it either;
no need to check HealthyCommunity, there's no `actor_id` for it to have received.

---

### Test 10 — Signup rejects a malformed email / blank name

Two quick variants of the same idea: client-side validation shouldn't be the only
thing standing between bad input and the database.

**Steps (Underlined UI)**
1. At `/signup`, try an email with no `@` (e.g. `not-an-email`) — reject expected.
2. With a valid email, try submitting with the Name field empty — reject expected.

**Expected UI result**
- Both submissions are rejected inline (email format / name required) and create
  nothing.

**Backend verification**
```elixir
Repo.aggregate(from(u in User, where: u.email == "not-an-email"), :count)
# => 0
```
**Pass criteria:** neither malformed-email nor blank-name reaches the database —
confirms `validate_format(:email, ...)` and `validate_required([:name])` are enforced
server-side, not just by the frontend form.

---

### Test 11 — Login fails with the wrong password

**Setup:** reuse the enabled user from Test 2 (or enable a fresh one the same way).

**Steps (Underlined UI)**
1. Go to `/login`, enter the correct email but a wrong password.

**Expected UI result**
- Generic "invalid email or password" error. Critically, it must **not** reveal
  whether the email exists — the same message a typo'd/unknown email would get.

**Backend verification**
- None needed — a failed login never writes anything. If you want to double-check,
  confirm the user row is untouched (`updated_at` hasn't changed):
  ```elixir
  Repo.one(from u in User, where: u.email == "<the email>")
  ```
**Pass criteria:** 401 with the generic `invalid_credentials` message; no partial hint
that distinguishes "wrong password" from "no such account."

---

### Test 12 — Login fails while the account is still disabled

**Steps (Underlined UI)**
1. Sign up a brand-new user at `/signup` and do **not** flip `enabled` in the DB.
2. Immediately try to log in with that same email/password at `/login`.

**Expected UI result**
- A distinct "account pending confirmation" error — different from Test 11's
  wrong-password message, so a legitimate user who just signed up isn't told their
  password is wrong when the real issue is the pending manual confirmation step.

**Backend verification**
```elixir
user = Repo.one(from u in User, where: u.email == "<the email you just used>")
user.enabled
# => false
```
**Pass criteria:** 403 with `account_pending_confirmation`, and the DB confirms
`enabled: false` is actually why — not a coincidental other failure.

---

### Test 13 — Two accounts with the same display name, different emails

Name is not a uniqueness key — only email is. This confirms two people can share a
display name without colliding, and that each still syncs to Community Health as its
own distinct member (keyed by `id`/`actor_external_id`, never by name).

**Steps (Underlined UI)**
1. Sign up `alice.one@example.com` with Name `Jordan Lee`.
2. Sign up `alice.two@example.com` with Name `Jordan Lee` (same name, different email).
3. Enable both accounts (same DB flip as Test 2) and log into each separately to
   confirm both work independently.

**Expected UI result**
- Both signups succeed normally; both logins succeed and each lands on that account's
  own profile (not the other one's).

**Backend verification**
```elixir
Repo.all(from u in User, where: u.name == "Jordan Lee", select: {u.id, u.email})
# => two distinct ids, one per email
```
Then, in HealthyCommunity's `app` container (only relevant if the integration is
enabled per Test 1's setup):
```elixir
alias CommunityHealth.Repo
alias CommunityHealth.Communities.Membership
import Ecto.Query

Repo.all(from m in Membership, where: m.actor_external_id in ^[<id_1>, <id_2>])
# => two separate membership rows, one per actor_external_id
```
**Pass criteria:** two separate user rows (and, if CH is enabled, two separate
membership rows) exist for the shared name — nothing in either system conflates them.

---

## Summary checklist

| # | Scenario | UI must look like |
|---|----------|--------------------|
| 1 | CH enabled, reachable, accepts | Normal signup; membership created |
| 2 | Repeated profile edits | Normal saves; membership not duplicated |
| 3 | `COMMUNITY_HEALTH_ENABLED=false` (prod default) | Normal signup; zero CH I/O |
| 4 | CH enabled, unreachable | Normal signup; job retries then discards, logged |
| 5 | CH enabled, invalid API key | Normal signup; job retries then discards, logged |
| 6 | Pre-existing users | Backfilled without any UI interaction |
| 7 | Repeated failures | No added latency on later signups |
| 8 | Duplicate email signup | Rejected inline; no row, no sync |
| 9 | Weak (<8 char) password | Rejected inline; no row, no sync |
| 10 | Malformed email / blank name | Rejected inline; no row, no sync |
| 11 | Wrong password at login | Generic `invalid_credentials`, no hint account exists |
| 12 | Login while still disabled | Distinct `account_pending_confirmation` error |
| 13 | Same name, different emails | Both work independently; two distinct ids/members |

If every row's "UI must look like" column holds, Step 1's Community Health integration
is safe to run in production with `COMMUNITY_HEALTH_ENABLED=false` while HealthyCommunity
itself stays local/undeployed — which is exactly the posture this is meant to prove.

---

## Cleanup

Run both truncate snippets from
["Resetting both databases to empty"](#resetting-both-databases-to-empty) above. That
leaves Underlined's and HealthyCommunity's databases empty — schema and containers
untouched, zero rows — so [Step 2's tests](step_2_tests.md) can start from the same
clean slate this file assumed at the top.
