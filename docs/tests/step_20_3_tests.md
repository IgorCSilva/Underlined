# Manual Test Plan — Step 20.3: Wishlist

Scope: [roadmap.md](../base_content/roadmap.md) Step 20.3 — a book page gains a heart
icon beside the Step 20.1 shelf control, independent of it: no shelf status to manage,
just "I want this." The same heart appears in the corner of every tile in the Step 2
catalog grid. The Step 20.1 Bookcase gains a fifth "Wish" tab collecting everything a
user has hearted, shown with a filled heart badge instead of a shelf-status tag. Every
functional test below interacts with Underlined's own UI (`http://localhost:3000`) and
API (`http://localhost:4000`). There is no Community Health pairing for this step.

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
  it "Book One". Call the two users "Wisher" and "Other Reader" below.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — The heart icon appears beside the shelf control, outline by default

**Steps (Underlined UI)**
1. Log in as Wisher and open "Book One" at `/books/:id`.

**Expected UI result**
- Beside the three-segment shelf control, a small gray outline heart (♡) appears.
  Clicking it is not required to shelve the book, and shelving the book is not required
  to use it.

**Pass criteria:** the heart renders independently of the shelf control, with no filled
state until Wisher clicks it.

---

### Test 2 — Clicking the heart wishlists the book immediately

**Setup:** continue from Test 1.

**Steps (Underlined UI)**
1. Click the heart on "Book One"'s page.

**Expected UI result**
- The heart fills solid terracotta with a small bounce-and-settle animation (the same
  gesture as the Step 5 like button).

**Backend verification**
```
curl -s http://localhost:4000/api/users/<Wisher's id>/wishlist | python3 -m json.tool
```
**Expected result:** `data` is a one-item list: `{"book":{"title":"Book One",...}}`.

**Pass criteria:** clicking the heart wishlists the book immediately, with no separate
save step.

---

### Test 3 — The heart also appears, and works, on every tile in the catalog grid

**Setup:** continue from Test 2. Add a second book from `/books/new` — call it "Book
Two" — and leave it unwishlisted.

**Steps (Underlined UI)**
1. Open `/books`.
2. Find "Book One"'s tile — its corner heart is already filled (matches Test 2).
3. Click "Book Two"'s tile's corner heart.

**Expected UI result**
- "Book One"'s tile shows a filled heart in its corner on page load, with no click
  needed. Clicking "Book Two"'s tile heart fills it the same way, without navigating to
  "Book Two"'s own page (the heart button swallows the click that would otherwise
  follow the tile's link).

**Backend verification**
```
curl -s http://localhost:4000/api/users/<Wisher's id>/wishlist | python3 -m json.tool
```
**Expected result:** `data` is now a two-item list containing both "Book One" and "Book
Two".

**Pass criteria:** the catalog grid's hearts reflect the viewer's wishlist on load, and
toggling one there never navigates away from the grid.

---

### Test 4 — Unwishlisting a book empties its heart everywhere

**Setup:** continue from Test 3.

**Steps (Underlined UI)**
1. On "Book One"'s page, click the filled heart again.
2. Go back to `/books`.

**Expected UI result**
- "Book One"'s heart on its own page returns to the outline (♡) state. On `/books`,
  "Book One"'s tile heart is outline again; "Book Two"'s stays filled.

**Backend verification**
```
curl -s http://localhost:4000/api/users/<Wisher's id>/wishlist | python3 -m json.tool
```
**Expected result:** `data` is now a one-item list containing only "Book Two".

**Pass criteria:** the heart is a true toggle (want/don't-want), not a one-way action —
unlike the shelf control, it has a genuine "off" state.

---

### Test 5 — The Bookcase's "Wish" tab collects every hearted book

**Setup:** continue from Test 4. Wisher has "Book Two" wishlisted and nothing shelved.

**Steps (Underlined UI)**
1. Click "My bookcase" in the top nav (`/bookcase`).
2. Click the "Wish" tab.

**Expected UI result**
- The "Wish" tab shows one tile for "Book Two", with a small filled-heart badge in its
  corner (not a status tag like the other tabs). The "All", "Already Read", "Currently
  Reading", and "To Be Read" tabs are unaffected — wishlisting never shelves a book.

**Pass criteria:** the Wish tab reuses the same tile grid as the other tabs, reflecting
the wishlist rather than any shelf status.

---

### Test 6 — Wishlisting and shelf status are independent of each other

**Setup:** continue from Test 5.

**Steps (Underlined UI)**
1. On "Book Two"'s page, click "To be read" on the shelf control (leaving the heart
   filled from Test 3).
2. Return to `/bookcase`.

**Expected UI result**
- "Book Two" now appears under both "To Be Read" and "Wish" — shelving it didn't
  unwishlist it, and wishlisting it earlier didn't shelve it.

**Backend verification**
```
curl -s http://localhost:4000/api/users/<Wisher's id>/bookcase | python3 -m json.tool
curl -s http://localhost:4000/api/users/<Wisher's id>/wishlist | python3 -m json.tool
```
**Expected result:** the first call's `data` has one entry (`"status":"to_read"`) for
"Book Two"; the second call's `data` still has one entry for "Book Two" too.

**Pass criteria:** the two features never interfere — a book can be on a shelf, on the
wishlist, both, or neither, independently.

---

### Test 7 — Wishlist status is scoped per viewer

**Setup:** continue from Test 6. Wisher has "Book Two" wishlisted.

**Steps (Underlined UI)**
1. Log in as Other Reader (a different browser/session) and open "Book Two"'s page.

**Expected UI result**
- Other Reader's heart on "Book Two"'s page shows the outline (♡) state — Wisher
  having it filled has no effect on Other Reader's own heart.

**Backend verification**
```
curl -s http://localhost:4000/api/users/<Other Reader's id>/wishlist | python3 -m json.tool
```
**Expected result:** `{"data":[]}`.

**Pass criteria:** wishlisting is scoped per user, same as shelving.

---

## Negative cases

### Test 8 — Wishlisting a book that doesn't exist is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/books/00000000-0000-0000-0000-000000000000/wishlist \
  -H "Authorization: Bearer <Wisher's access token>"
```

**Expected result:** `404`.

**Pass criteria:** a book can never be wishlisted under an id that doesn't exist.

---

### Test 9 — Wishlisting requires authentication; viewing a wishlist does not

**Steps (Underlined UI / API)**
1. Log out and open "Book One"'s page.
2. Separately, replay the request directly:
   ```
   curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/books/<Book One's id>/wishlist
   curl -s -o /dev/null -w "%{http_code}\n" -X DELETE http://localhost:4000/api/books/<Book One's id>/wishlist
   ```
3. Separately, check that reading a wishlist needs no auth:
   ```
   curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/users/<Wisher's id>/wishlist
   ```

**Expected result:** the heart doesn't render at all for a logged-out viewer (no crash,
no broken button); both the `POST` and `DELETE` return `401`; the `GET` returns `200`.

**Pass criteria:** wishlisting a book requires authentication; viewing anyone's
wishlist (Tests 5-7's `GET` calls) does not.

---

### Test 10 — An unknown user id's wishlist degrades gracefully, not a crash

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/users/00000000-0000-0000-0000-000000000000/wishlist
```

**Expected result:** `404`.

**Pass criteria:** an unknown user id degrades gracefully, same as the Step 20.1
bookcase endpoint.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Open a book page for the first time | Heart renders outline, independent of the shelf control |
| 2 | Click the heart | Book wishlisted immediately, heart fills with a bounce |
| 3 | Open the catalog grid | Every tile's heart reflects the wishlist; clicking one toggles it without navigating |
| 4 | Click a filled heart again | Book is unwishlisted everywhere — a true toggle |
| 5 | Open the Bookcase's "Wish" tab | Shows every hearted book with a filled-heart badge |
| 6 | Shelve a wishlisted book | Appears under both its shelf tab and "Wish" — independent features |
| 7 | View/toggle as a different viewer | Fully scoped per user |
| 8 | Wishlist a book that doesn't exist | `404` |
| 9 | Wishlist while logged out / read any wishlist | Heart absent in UI; `401` to mutate, `200` to read |
| 10 | Query an unknown user id's wishlist | `404` |

If every row holds, Step 20.3 lets any reader mark a book as wanted with one click, see
that want reflected everywhere the book appears, and browse everything they've wanted
back on their own Bookcase — with no commitment to a shelf, and no interference with
whatever shelf status (if any) the book already carries.

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty).
That leaves the database empty — schema and containers untouched, zero rows — so the
next step's tests can start from the same clean slate this file assumed at the top.
