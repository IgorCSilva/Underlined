# Manual Test Plan — Step 17: Book Clubs (Create & Join)

Scope: [roadmap.md](../base_content/roadmap.md) Step 17 — a user can create a club
scoped to one book, join/leave a club, and see its member list. Every functional test
below (Tests 1-10) interacts only with Underlined's own UI (`http://localhost:3000`)
and API (`http://localhost:4000`) and must pass identically whether the Community
Health integration is enabled or not, same principle as
[Step 13's doc](step_13_tests.md). The optional Test 11 at the end covers the CH
pairing itself (CH-Step 2: Community & Membership) and does require the paired
HealthyCommunity stack.

## Before you start

- **Start from an empty database.** This file assumes Underlined's database is empty
  before Test 1. If you're re-running this file, empty it first with the Underlined
  snippet from
  [Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty),
  the same snippet this file's [Cleanup](#cleanup) section ends with.
- Underlined's stack is up: `docker compose up -d` (HealthyCommunity is irrelevant for
  Tests 1-10 — don't bother starting it).
- You need at least two **enabled** users and one book. Sign up both at `/signup`,
  enable each account from the running `api` container — never with `psql`:
  ```
  docker compose exec api iex -S mix
  ```
  ```elixir
  alias Api.Repo
  alias Api.Infrastructure.Repository.User.Postgres.User
  import Ecto.Query

  user = Repo.one(from u in User, where: u.email == "<the email you signed up with>")
  {:ok, user} = user |> Ecto.Changeset.change(enabled: true) |> Repo.update()
  ```
  Then log in as the first user at `/login` and create a book at `/books/new` — call
  it "Book One". Call the two users "Creator" and "Joiner" below.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — "Create a club" appears on a book's page

**Steps (Underlined UI)**
1. Log in as Creator and open "Book One"'s page at `/books/:id`.

**Expected UI result**
- Below the book header, a "Clubs" section appears with "No clubs for this book yet."
  and a dashed terracotta "+ Create a club" button.

**Pass criteria:** the section and button render even when the book has zero clubs.

---

### Test 2 — Creating a club makes its creator the first member

**Setup:** continue from Test 1.

**Steps (Underlined UI)**
1. Click "+ Create a club". A modal opens with a name field and an optional
   description field.
2. Enter "Free Will Thinkers" as the name and "Discussing determinism" as the
   description.
3. Submit.

**Expected UI result**
- The modal closes and a club card appears in the "Clubs" section: cover (from "Book
  One"), "Free Will Thinkers" in bold serif, one avatar in the member stack, "1
  members", and a solid terracotta "Joined" pill (Creator is already a member).

**Backend verification**
```
curl -s http://localhost:4000/api/books/<Book One's id>/clubs | python3 -m json.tool
```
**Expected result:** `data` contains one club with `"member_count": 1`,
`"joined_by_user"` reflecting the viewer, and `creator.id` equal to Creator's id.

**Pass criteria:** a club is never left without at least one member — its creator is
added automatically, in the same request that creates the club.

---

### Test 3 — The club page shows its header, tabs, and description

**Setup:** continue from Test 2.

**Steps (Underlined UI)**
1. Click the "Free Will Thinkers" club card.

**Expected UI result**
- `/clubs/:id` renders a wide header band (book cover, club name in serif, "Book
  One" as the subtitle, the description, the member avatar stack, member count, and
  the Join/Leave button) followed by a tab bar: Discussion / Members / Schedule, with
  "Discussion" active by default (yellow underline). The Discussion tab shows a
  "coming in a future update" placeholder — no crash, no empty white space.

**Pass criteria:** the header and all three tabs render; switching to Schedule shows
its own placeholder; neither placeholder is mistaken for an error state.

---

### Test 4 — A second user can join, and the member list reflects join order

**Setup:** continue from Test 3.

**Steps (Underlined UI)**
1. Log in as Joiner (a different browser/session) and open the same club's page.
2. Click "Join".
3. Click the "Members" tab.

**Expected UI result**
- The button fills solid terracotta with a checkmark immediately. The Members tab
  lists Creator first, then Joiner — earliest joiner first.

**Backend verification**
```
curl -s http://localhost:4000/api/clubs/<the club's id>/members | python3 -m json.tool
```
**Expected result:** `data` is `[Creator, Joiner]` in that order.

**Pass criteria:** join order is preserved and visible without a page reload.

---

### Test 5 — Joining twice stays joined (idempotent)

**Setup:** continue from Test 4, logged in as Joiner.

**Steps (API)**
```
curl -s -X POST http://localhost:4000/api/clubs/<the club's id>/membership \
  -H "Authorization: Bearer <Joiner's access token>"
```
(repeat the exact same request once more)

**Expected result:** both calls return `{"data":{"joined":true}}`; the member list
from Test 4 still has exactly two rows, not three.

**Pass criteria:** re-joining an already-joined club never creates a duplicate
membership row.

---

### Test 6 — Leaving removes a member, and leaving twice is a no-op

**Setup:** continue from Test 5, Joiner is a member.

**Steps (Underlined UI)**
1. As Joiner, click "Leave" on the club page. The button returns to its outlined
   "Join" state immediately.
2. Click "Leave" again via a direct API replay:
   ```
   curl -s -X DELETE http://localhost:4000/api/clubs/<the club's id>/membership \
     -H "Authorization: Bearer <Joiner's access token>"
   ```

**Expected result:** both calls return `{"data":{"joined":false}}`; the Members tab
(reload the page) now shows only Creator.

**Pass criteria:** leaving a club you're not a member of degrades to a no-op, not an
error.

---

## Negative cases

### Test 7 — Creating a club without a name is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/books/<Book One's id>/clubs \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Creator's access token>" \
  -d '{"club":{"name":""}}'
```

**Expected result:** `422` (changeset validation error on `name`).

**Pass criteria:** a club always has a non-empty name.

---

### Test 8 — Creating a club under an unknown book is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/books/00000000-0000-0000-0000-000000000000/clubs \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Creator's access token>" \
  -d '{"club":{"name":"Readers"}}'
```

**Expected result:** `404`.

**Pass criteria:** a club can never be created against a book that doesn't exist.

---

### Test 9 — Unauthenticated requests can't create, join, or leave

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/books/<Book One's id>/clubs \
  -H "Content-Type: application/json" -d '{"club":{"name":"Readers"}}'
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/clubs/<the club's id>/membership
curl -s -o /dev/null -w "%{http_code}\n" -X DELETE http://localhost:4000/api/clubs/<the club's id>/membership
```

**Expected result:** `401` for all three.

**Pass criteria:** creating, joining, and leaving a club all require authentication;
reading a club, its book's club list, and its member list (Tests 2-4's `GET` calls) do
not.

---

### Test 10 — An unknown club id degrades gracefully, not a crash

**Steps (Underlined UI / API)**
1. Go to `/clubs/00000000-0000-0000-0000-000000000000`.
2. Separately, check the API directly:
   ```
   curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/clubs/00000000-0000-0000-0000-000000000000
   curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/clubs/00000000-0000-0000-0000-000000000000/members
   ```

**Expected result:** the UI renders "This club doesn't exist." (no crash); both API
calls return `404`.

**Pass criteria:** an unknown club id degrades gracefully on both the API and the UI.

---

## Optional — Community Health pairing (CH-Step 2)

This step pairs with
[CH-Step 2 (Community & Membership)](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md) —
no new HealthyCommunity code was needed; `ensure_member` already registers its
community on first sight. Each club becomes its own CH community
(`external_ref: "club_<club id>"`), invisible to users today. Like
[Step 7's doc](step_7_integration_tests.md), club creation/joining must look and
behave identically whether this is on, off, or broken — the UI never reads CH to show
membership or decide whether a join can happen.

### Test 11 — Creating a club and joining it register/sync the club's own CH community

**Setup**
1. Start HealthyCommunity: `cd HealthyCommunity && docker compose up -d postgres app`
2. Register the platform once and copy the printed API key (skip if already
   registered from earlier testing):
   `docker compose exec app mix community_health.register_platform "Underlined"`
3. Start Underlined with the integration **on**:
   `cd Underlined && COMMUNITY_HEALTH_ENABLED=true COMMUNITY_HEALTH_API_KEY="<key>" docker compose up -d`
4. Repeat Test 2 (create a club) and Test 4 (a second user joins).

**Backend verification**
```elixir
# HealthyCommunity — docker compose exec app iex -S mix
alias CommunityHealth.Repo
alias CommunityHealth.Communities.{Community, CommunityMember}
import Ecto.Query

club_ref = "club_<the club's id>"
community = Repo.one(from c in Community, where: c.external_ref == ^club_ref)
Repo.all(from m in CommunityMember, where: m.community_id == ^community.id) |> length()
```

**Pass criteria:** within a few seconds (processed by an Oban job after each HTTP
response, never on the request path), a community with `external_ref` equal to
`"club_<the club's id>"` exists, with exactly two members — Creator and Joiner — none
of which ever delayed or changed the UI's own response in Tests 2 or 4.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Open a book with no clubs | "Clubs" section with empty state + "+ Create a club" |
| 2 | Create a club | Club card with the creator as its only, automatic member |
| 3 | Open a club's page | Header band + Discussion/Members/Schedule tabs |
| 4 | A second user joins | Join button fills solid; Members tab lists both, joiner order preserved |
| 5 | Join twice | Stays joined — no duplicate membership |
| 6 | Leave, then leave again | Removed once; second leave is a no-op |
| 7 | Create a club with no name | `422` changeset error |
| 8 | Create a club under an unknown book | `404` |
| 9 | Create/join/leave while unauthenticated | `401` |
| 10 | Visit/query an unknown club id | `404` from the API; "This club doesn't exist." in the UI |
| 11 (optional) | Create a club and join it, with CH enabled | The club's own CH community exists with the right members |

If every row holds, Step 17 lets any reader organize a club around a single book —
create it, join it, leave it, and see who else is in it — and (optionally) each club
is already laying the groundwork for club-scoped moderation/trust/roles in Community
Health, invisibly, without that pairing ever being able to block or slow down the
core flow.

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
(and the HealthyCommunity one too, if you ran Test 11). That leaves both databases
empty — schema and containers untouched, zero rows — so the next step's tests can
start from the same clean slate this file assumed at the top.
