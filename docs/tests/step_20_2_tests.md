# Manual Test Plan — Step 20.2: Book Genres & Series Metadata

Scope: [roadmap.md](../base_content/roadmap.md) Step 20.2 — the add-book form gains an
optional genres field — a book can carry more than one — entered as chips with
autocomplete against genres already in the catalog, plus a "Part of a series?" toggle
that, switched on, reveals a series name and its numeric position. Once saved, every
genre renders as its own small outline chip on the book's page and on every tile
showing that book; series position renders as a plain line under the author — "Book 2
of *The Broken Earth*" — linking to every other book sharing that series name. Every
functional test below interacts with Underlined's own UI (`http://localhost:3000`) and
API (`http://localhost:4000`). There is no Community Health pairing for this step.

## Before you start

- **Start from an empty database.** This file assumes Underlined's database is empty
  before Test 1. If you're re-running this file, empty it first with the Underlined
  snippet from
  [Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty),
  the same snippet this file's [Cleanup](#cleanup) section ends with.
- Underlined's stack is up: `docker compose up -d`.
- You need one **enabled** user. Sign up at `/signup`, then enable the account from
  the running `api` container — never with `psql`:
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
  Then log in at `/login`. Call this user "Cataloger" below.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — The add-book form offers an optional genres field and a series toggle

**Steps (Underlined UI)**
1. Log in as Cataloger and open `/books/new`.

**Expected UI result**
- Below "Cover image URL (optional)", a "Genres (optional)" field appears — an empty
  chip row with a text input inside it ("Type a genre, press Enter…"). Below that, a
  pill-shaped "Part of a series?" button, outlined and inactive — clicking it is not
  required to submit the form.

**Pass criteria:** the form renders both new controls; neither is required to add a
book (mirrors the existing title/author-only required fields).

---

### Test 2 — Adding a book with more than one genre shows every genre as its own chip everywhere that book appears

**Setup:** continue from Test 1.

**Steps (Underlined UI)**
1. Fill in title "Sapiens", author "Yuval Noah Harari".
2. In the genres field, type "History" and press Enter — it becomes a chip with a "✕"
   remove button. Type "Nonfiction" and press Enter — a second chip appears next to
   the first.
3. Leave the series toggle off. Submit.
4. Open the book's page, then go back to `/books`.

**Expected UI result**
- The book's page shows two small outline sand chips, "History" and "Nonfiction",
  under the author, above the post/reader stat badges. The book's tile on `/books`
  shows the same two chips under its title/author.

**Backend verification**
```
curl -s http://localhost:4000/api/books | python3 -m json.tool
```
**Expected result:** the book's entry has `"genres":["History","Nonfiction"]`,
`"series_name":null`, `"series_position":null`.

**Pass criteria:** every genre chipped on the add-book form round-trips to the API,
in order, and every one of them renders on both the book's own page and its tile.

---

### Test 3 — Marking a book as part of a series reveals the two series fields and renders the series line

**Setup:** continue from Test 2.

**Steps (Underlined UI)**
1. Open `/books/new`. Fill in title "The Fifth Season", author "N. K. Jemisin", and
   chip in the genre "Fantasy".
2. Click "Part of a series?" — a series name field and a numeric position field
   appear.
3. Enter "The Broken Earth" as the series name and "1" as the position.
4. Submit, then open the new book's page.

**Expected UI result**
- The series name/position fields are invisible until the toggle is clicked. After
  submitting, the book's page shows "Book 1 of The Broken Earth" in plain gray sans
  under the author, above the "Fantasy" genre chip.

**Backend verification**
```
curl -s http://localhost:4000/api/books | python3 -m json.tool
```
**Expected result:** the new book's entry has `"series_name":"The Broken Earth"` and
`"series_position":1`.

**Pass criteria:** the series fields only exist in the payload when the toggle was
switched on, and what's typed round-trips into the "Book N of Series" line.

---

### Test 4 — The series line links to every other book sharing that series name

**Setup:** continue from Test 3. Add a second book the same way: title "The Obelisk
Gate", author "N. K. Jemisin", genre "Fantasy", series name "The Broken Earth",
position "2".

**Steps (Underlined UI)**
1. On "The Obelisk Gate"'s page, click the "Book 2 of The Broken Earth" line.

**Expected UI result**
- Lands on `/books?series=The%20Broken%20Earth`, replacing the usual search box with
  a "Books in the The Broken Earth series" heading, and a grid showing exactly "The
  Fifth Season" and "The Obelisk Gate" — not "Sapiens" — ordered by position (Fifth
  Season, then Obelisk Gate).

**Backend verification**
```
curl -s "http://localhost:4000/api/books?series=The%20Broken%20Earth" | python3 -m json.tool
```
**Expected result:** `data` is a two-item list, "The Fifth Season" before "The Obelisk
Gate", neither item being "Sapiens".

**Pass criteria:** the series link filters to exactly the books sharing that series
name, in reading order, excluding every unrelated book.

---

### Test 5 — Genre autocomplete offers every distinct genre already in the catalog

**Setup:** continue from Test 4. The catalog now has genres "History", "Nonfiction",
and "Fantasy" (Fantasy used twice, by both Broken Earth books).

**Steps (Underlined UI)**
1. Open `/books/new` and click into the genres field's text input.

**Expected UI result**
- The browser's native autocomplete dropdown offers "Fantasy", "History", and
  "Nonfiction" — one entry each, even though "Fantasy" was chipped on two different
  books.

**Backend verification**
```
curl -s http://localhost:4000/api/books/genres | python3 -m json.tool
```
**Expected result:** `{"data":["Fantasy","History","Nonfiction"]}`, alphabetical, no
duplicates.

**Pass criteria:** the add-book form's genre suggestions come from the catalog's own
distinct genres flattened across every book, so typing "Fantasy" again never
fragments into "fantasy"/"Fantasy fiction"/etc., and a genre shared by many books is
only suggested once.

---

### Test 5b — Typing the same genre twice, or a blank one, doesn't create junk chips

**Setup:** continue from Test 5.

**Steps (Underlined UI)**
1. Open `/books/new`. In the genres field, type "Fantasy" and press Enter.
2. Type "Fantasy" again (same spelling) and press Enter.
3. Press Enter with the text input empty.

**Expected UI result**
- Only one "Fantasy" chip ever appears — the second "Fantasy" and the empty Enter are
  both no-ops, not a duplicate chip or a blank one.

**Pass criteria:** the chip input itself prevents duplicate/blank genres from ever
reaching the API, matching `KeywordChipInput`'s existing keyword behavior.

---

## Negative cases

### Test 6 — A series position without a series name is rejected

The UI only ever sends `series_position` alongside a `series_name` (the position field
is inside the same toggle-revealed block), so this is only reachable directly against
the API.

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/books \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Cataloger's access token>" \
  -d '{"book":{"title":"Orphan Position","author":"Someone","series_position":3}}'
```

**Expected result:** `422` (changeset error on `series_position`: "can only be set
when the book is part of a series").

**Pass criteria:** a series position can never exist on a book with no series name.

---

### Test 7 — A non-positive series position is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/books \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Cataloger's access token>" \
  -d '{"book":{"title":"Zeroth Book","author":"Someone","series_name":"Some Series","series_position":0}}'
```

**Expected result:** `422` (changeset error: "must be greater than 0").

**Pass criteria:** a series position is always a positive number — the UI's `min="1"`
on the number input is backed by the same rule server-side.

---

### Test 8 — An oversized genre or series name is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/books \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Cataloger's access token>" \
  -d "{\"book\":{\"title\":\"Too Long\",\"author\":\"Someone\",\"genres\":[\"$(python3 -c 'print("x"*61)')\"]}}"
```

**Expected result:** `422` (changeset length error on `genres`).

**Pass criteria:** catalog metadata has the same sane length bounds as title/author,
so a pasted-in wall of text can never become one of a book's genres.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Open the add-book form | Genres field and series toggle both render, both optional |
| 2 | Add a book with two genres | Both chips render on the book's page and its tile |
| 3 | Toggle "Part of a series?" and fill it in | Series fields appear only when toggled; "Book N of Series" renders |
| 4 | Click the series line | Navigates to `/books?series=...`, showing only that series, in order |
| 5 | Open the genres field again | Autocomplete offers exactly the catalog's existing distinct genres, each once |
| 5b | Chip the same genre twice, or an empty one | No duplicate or blank chip is created |
| 6 | Send a series position with no series name | `422` changeset error |
| 7 | Send a non-positive series position | `422` changeset error |
| 8 | Send an oversized genre | `422` changeset error |

If every row holds, Step 20.2 lets the catalog carry what a book is about and where it
sits in a series, typed once on the add-book form, surfaced everywhere that book is
shown, and discoverable as a trail from one installment to the next — exactly the
signal Step 20.1's personal bookcase needs to answer "what do I read next."

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty).
That leaves the database empty — schema and containers untouched, zero rows — so the
next step's tests can start from the same clean slate this file assumed at the top.
