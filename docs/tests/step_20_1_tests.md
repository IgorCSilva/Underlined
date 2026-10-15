# Manual Test Plan — Step 20.1: The Bookcase (Read / Reading / To Be Read)

Scope: [roadmap.md](../base_content/roadmap.md) Step 20.1 — a book page gains a
three-way shelf control (to be read / reading / read); shelving a book adds it to the
caller's bookcase under that status, and clicking a different segment later moves it
there instead of creating a second entry. A new Bookcase page (`/bookcase` for your own,
`/bookcase/:id` for anyone's) lists everything a user has shelved, with an All tab plus
one tab per status, each book tile carrying a status tag. Every functional test below
interacts with Underlined's own UI (`http://localhost:3000`) and API
(`http://localhost:4000`). There is no Community Health pairing for this step.

## Before you start

- **Start from an empty database.** This file assumes Underlined's database is empty
  before Test 1. If you're re-running this file, empty it first with the Underlined
  snippet from
  [Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty),
  the same snippet this file's [Cleanup](#cleanup) section ends with.
- Underlined's stack is up: `docker compose up -d`.
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
  it "Book One". Call the two users "Reader" and "Other Reader" below.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — The shelf control appears on a book page, unshelved by default

**Steps (Underlined UI)**
1. Log in as Reader and open "Book One" at `/books/:id`.

**Expected UI result**
- Beside the post/reader stat badges, a pill-shaped three-segment control appears: "To
  be read" / "Reading" / "Read", all three outlined in gray — none filled, since Reader
  hasn't shelved this book yet.

**Pass criteria:** the control renders for any logged-in viewer, with no segment active
until they choose one.

---

### Test 2 — Shelving a book for the first time

**Setup:** continue from Test 1.

**Steps (Underlined UI)**
1. Click "To be read".

**Expected UI result**
- The "To be read" segment immediately fills sand/ochre; the other two stay outlined.

**Backend verification**
```
curl -s http://localhost:4000/api/users/<Reader's id>/bookcase | python3 -m json.tool
```
**Expected result:** `data` is a one-item list: `{"status":"to_read","book":{"title":"Book
One",...}}`.

**Pass criteria:** clicking a segment shelves the book under that status immediately,
with no separate save step.

---

### Test 3 — The bookcase lists the shelved book, under All and its own tab

**Setup:** continue from Test 2.

**Steps (Underlined UI)**
1. Click "My bookcase" in the top nav (`/bookcase`).
2. Click through the "Already Read", "Currently Reading", and "To Be Read" tabs.

**Expected UI result**
- The "All" tab (active by default, yellow underline) shows one tile for "Book One"
  with a sand/ochre "To be read" tag in its corner. "To Be Read" shows the same tile.
  "Already Read" and "Currently Reading" both show the empty state ("Nothing shelved
  here yet.").

**Pass criteria:** the bookcase reflects a shelf change immediately, and each tab
filters to exactly the books on that shelf.

---

### Test 4 — Moving a shelved book to a different status is an upsert, not a duplicate

**Setup:** continue from Test 3, still logged in as Reader.

**Steps (Underlined UI)**
1. Go back to "Book One"'s page and click "Reading" on the shelf control.
2. Return to `/bookcase`.

**Expected UI result**
- The shelf control now shows "Reading" filled solid ink-blue, "To be read" no longer
  filled. On the bookcase, "Currently Reading" now shows the tile; "To Be Read" is back
  to its empty state; "All" still shows exactly **one** tile for "Book One" (now tagged
  "Reading"), not two.

**Backend verification**
```
curl -s http://localhost:4000/api/users/<Reader's id>/bookcase | python3 -m json.tool
```
**Expected result:** still a one-item list, now with `"status":"reading"`.

**Pass criteria:** there is one row per user+book — moving a book between shelves
updates it in place.

---

### Test 5 — Shelf status and bookcases are scoped per viewer

**Setup:** continue from Test 4. Reader has "Book One" shelved as `reading`.

**Steps (Underlined UI)**
1. Log in as Other Reader (a different browser/session) and open "Book One"'s page.
2. Separately, visit Reader's bookcase directly at `/bookcase/<Reader's id>`.
3. Then visit Other Reader's own bookcase at `/bookcase`.

**Expected UI result**
- On "Book One"'s page, Other Reader's shelf control shows no active segment — Reader
  having it on "Reading" has no effect on Other Reader's own shelf. Reader's bookcase
  page (`/bookcase/<Reader's id>`) shows "Reader's bookcase" as its heading with "Book
  One" tagged "Reading". Other Reader's own bookcase is empty.

**Pass criteria:** shelving is scoped per user — visiting someone else's bookcase is a
public, read-only view that never leaks into or is affected by your own.

---

## Negative cases

### Test 6 — Shelving under an unknown status is rejected

The UI only ever sends one of the three fixed statuses, so this is only reachable
directly against the API.

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/books/<Book One's id>/shelf \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Reader's access token>" \
  -d '{"shelf":{"status":"finished"}}'
```

**Expected result:** `422` (changeset `validate_inclusion` error on `status`).

**Pass criteria:** only `to_read`, `reading`, or `read` are accepted.

---

### Test 7 — Shelving a book that doesn't exist is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/books/00000000-0000-0000-0000-000000000000/shelf \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Reader's access token>" \
  -d '{"shelf":{"status":"to_read"}}'
```

**Expected result:** `404`.

**Pass criteria:** a book can never be shelved under an id that doesn't exist.

---

### Test 8 — Shelving requires authentication

**Steps (Underlined UI / API)**
1. Log out and open "Book One"'s page.
2. Separately, replay the request directly:
   ```
   curl -s -o /dev/null -w "%{http_code}\n" -X PUT http://localhost:4000/api/books/<Book One's id>/shelf \
     -H "Content-Type: application/json" -d '{"shelf":{"status":"to_read"}}'
   ```

**Expected result:** the shelf control doesn't render at all for a logged-out viewer
(no crash, no broken control); the direct API call returns `401`.

**Pass criteria:** shelving a book requires authentication; viewing a bookcase (Tests
3-5) does not.

---

### Test 9 — An unknown user id's bookcase degrades gracefully, not a crash

**Steps (Underlined UI / API)**
1. Go to `/bookcase/00000000-0000-0000-0000-000000000000`.
2. Separately, check the API directly:
   ```
   curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/users/00000000-0000-0000-0000-000000000000/bookcase
   ```

**Expected result:** the UI renders "User not found." (no crash); the API call
returns `404`.

**Pass criteria:** an unknown user id degrades gracefully on both the API and the UI.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Open a book page for the first time | Shelf control renders, no segment active |
| 2 | Click a shelf segment | Book shelved under that status immediately |
| 3 | Open the bookcase | All/per-status tabs correctly filter the shelved book |
| 4 | Click a different shelf segment | Updated in place — still one entry, not two |
| 5 | View another user's bookcase / shelve as a different viewer | Fully scoped per user |
| 6 | Shelve under an unknown status | `422` changeset error |
| 7 | Shelve a book that doesn't exist | `404` |
| 8 | Shelve while logged out | Control absent in UI; `401` from the API |
| 9 | Visit/query an unknown user id's bookcase | "User not found." in the UI; `404` from the API |

If every row holds, Step 20.1 lets any reader track their reading life — what they've
read, what they're reading, what they intend to read — directly from a book's page, and
browse it back as their own Bookcase or anyone else's, one row per book that moves
between shelves rather than piling up duplicates.

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty).
That leaves the database empty — schema and containers untouched, zero rows — so the
next step's tests can start from the same clean slate this file assumed at the top.
