# Manual Test Plan — Step 2: Book Catalog

Scope: [roadmap.md](../base_content/roadmap.md) Step 2 — search, browse, and add books to
the catalog. Unlike [Step 1](step_1_plus_integration_tests.md), there is **no Community
Health pairing** for this step (confirmed in the roadmap and in code — no
`CommunityHealthWorker`/sync call anywhere in the book usecase path); every test below is
scoped entirely to Underlined's own UI (`http://localhost:3000`) and API
(`http://localhost:4000`).

## Before you start

- Underlined's stack is up: `docker compose up -d` (HealthyCommunity is irrelevant here —
  don't bother starting it).
- You have one **enabled** (not just signed-up) user to log in with, since adding a book
  requires authentication. Sign up at `/signup`, then enable the account the same way
  [Step 1's doc](step_1_plus_integration_tests.md#finding-a-users-id-and-why-signing-up-isnt-enough-to-log-in)
  does — never with `psql`, always from the running `api` container:
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
  Then log in at `/login`. Keep that session open for every "add a book" step below.
- The catalog starts **empty** in a fresh dev DB (no seed data) — Test 1 is what
  populates it; later tests build on the books it creates. Run the tests in order.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql` —
  with:
  ```elixir
  alias Api.Repo
  alias Api.Infrastructure.Repository.Book.Postgres.Book
  import Ecto.Query
  ```
- A few tests call the API directly with `curl` (to reach states the UI's own guards
  prevent you from triggering, like a blank required field or a missing auth token).
  That's calling the HTTP API, not inspecting the database — it doesn't conflict with
  the no-`psql` rule, which is only about DB inspection. Where a test needs a bearer
  token, get one the same way the UI does:
  ```
  curl -s -X POST http://localhost:4000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"<your enabled user's email>","password":"<their password>"}'
  ```
  Copy the `data.access_token` value from the response for the `Authorization: Bearer
  <token>` header in later `curl` commands.

---

## Positive cases

### Test 1 — Adding a new book via the UI creates it and shows up in the catalog

**Steps (Underlined UI)**
1. Go to `http://localhost:3000/books` and click the dashed "Add a book" tile (or go
   straight to `/books/new`).
2. Fill in Title `Sapiens`, Author `Yuval Noah Harari`, leave Cover image URL blank.
3. Submit.

**Expected UI result**
- The button briefly reads "Adding…" (disabled), then you're redirected to `/books`.
- The catalog grid now shows a tile for "Sapiens" / "Yuval Noah Harari" with the 📖
  placeholder (no cover image was given), alongside the "Add a book" tile.

**Backend verification**
```elixir
book = Repo.get_by(Book, title: "Sapiens")
book.author      # => "Yuval Noah Harari"
book.cover_url   # => nil
```
**Pass criteria:** exactly one row exists with those values; the UI reflects it
immediately on landing on `/books`, no manual refresh needed.

---

### Test 2 — Searching by title finds the book

**Setup:** continue from Test 1.

**Steps (Underlined UI)**
1. On `/books`, type `sapiens` (lowercase) into the search box and pause.

**Expected UI result**
- After a short pause (the box is a type-ahead search, not a submit button), the
  "Sapiens" tile is the only result shown (plus the ever-present "Add a book" tile).

**Pass criteria:** a lowercase, partial-looking query matches the book regardless of
the title's original casing — full-text search is case-insensitive.

---

### Test 3 — Searching by author finds the book too (not just title)

**Setup:** continue from Test 1/2.

**Steps (Underlined UI)**
1. Clear the search box and type `Harari` — a word that only appears in the Author
   field, never in the Title.

**Expected UI result**
- The "Sapiens" tile still appears, proving the search covers title **and** author
  together, not title alone.

**Pass criteria:** an author-only match surfaces the book; this is the step's whole
reason for having full-text search span both columns.

---

## Negative cases

### Test 4 — A search with no matches shows an empty grid, not an error

**Steps (Underlined UI)**
1. On `/books`, search for nonsense that can't match anything, e.g. `zzqxnotabook123`.

**Expected UI result**
- The grid shows **only** the dashed "Add a book" tile — no book tiles, no error
  banner, no "no results found" message (there isn't one; the page simply renders an
  empty result set). This is a quiet, not a loud, empty state.

**Pass criteria:** zero matches is handled as a normal, valid state — not an error
page, not a stuck "Searching…" spinner.

---

### Test 5 — Looking up a book by an unknown or malformed id returns 404

There's no dedicated book-detail page yet (that's Step 10), so this is checked directly
against the API.

**Steps**
```
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/books/00000000-0000-0000-0000-000000000000
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/books/not-even-a-uuid
```

**Expected result**
- Both return `404` — a well-formed UUID that doesn't exist and a string that isn't a
  UUID at all are handled identically, neither one crashing with a 500.

**Pass criteria:** both calls return `404` with a normal `{"errors":{"detail":"not
found",...}}` body, never a 500.

---

### Test 6 — Submitting the add-book form with a required field missing is rejected

The Title/Author inputs are marked `required` in the HTML, so the browser itself blocks
an empty submission before any request is sent — you can see that by trying it in the
UI. To confirm the **API** enforces the same rule independently (defense in depth, not
just a client-side nicety), call it directly with the field missing:

**Steps**
```
curl -s -X POST http://localhost:4000/api/books \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your access_token>" \
  -d '{"book":{"author":"No Title Here"}}'
```

**Expected result**
- `422` with `{"errors":{"title":["can't be blank"]}}`.

**Backend verification**
```elixir
Repo.get_by(Book, author: "No Title Here")
# => nil
```
**Pass criteria:** the UI's `required` attribute is only a convenience — the server
rejects the same missing field on its own, and nothing is inserted.

---

## Validation cases

### Test 7 — Title/author length boundaries (1 char ok, 80 ok, 81 rejected)

Typing exactly 80/81 characters by hand isn't practical, so generate the strings and
call the API directly:

**Steps**
```
TITLE_80=$(python3 -c "print('a' * 80)")
TITLE_81=$(python3 -c "print('a' * 81)")
TOKEN="<your access_token>"

curl -s -X POST http://localhost:4000/api/books \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d "{\"book\":{\"title\":\"$TITLE_80\",\"author\":\"Boundary Author 80\"}}"

curl -s -X POST http://localhost:4000/api/books \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d "{\"book\":{\"title\":\"$TITLE_81\",\"author\":\"Boundary Author 81\"}}"
```

**Expected result**
- The 80-character title: `200`, book created.
- The 81-character title: `422`, `{"errors":{"title":["should be at most 80
  character(s)"]}}`.

**Backend verification**
```elixir
Repo.aggregate(from(b in Book, where: b.author == "Boundary Author 80"), :count)  # => 1
Repo.aggregate(from(b in Book, where: b.author == "Boundary Author 81"), :count)  # => 0
```
**Pass criteria:** the boundary sits exactly at 80 — 80 succeeds, 81 doesn't, with no
off-by-one. (The underlying DB column is `varchar(255)`, well above this limit, so
there's no risk of the 500-crashing truncation error a wider application-level limit
would hit — see the note below.)

> **Why 80, not something bigger:** `title`/`author` are plain `:string` columns, which
> Ecto maps to Postgres `varchar(255)` unless a migration says otherwise (see
> `api/priv/repo/migrations/20260930225600_create_books.exs`). The changeset originally
> validated `max: 300` — a limit the *database column itself* couldn't actually hold,
> so a title between 256–300 chars passed the changeset but crashed the insert with a
> raw `Postgrex.Error: string_data_right_truncation` (a 500, not a clean 422). Keeping
> the application-level max comfortably under the column's real capacity avoids that
> class of bug entirely; 80 chars is also simply more realistic for a book title/author
> than 300 was. The same mismatch existed on `users.bio` (validated at 500, same
> `varchar(255)` column) and has been lowered to 200 for the same reason — if you're
> retesting Step 1's profile-edit flow, use that number instead of 500.

---

### Test 8 — Cover URL must be http(s) if present; blank is fine

Test 1 already proved a **blank** cover URL is accepted. This checks a **present but
invalid** one — and it's fully observable through the UI, since the browser's own
`type="url"` validation only checks for *some* URL shape, not the `http(s)` scheme the
backend actually requires.

**Steps (Underlined UI)**
1. Go to `/books/new`. Fill Title `Bad Cover Test`, Author `Test Author`, and Cover
   image URL `ftp://example.com/cover.jpg` — a syntactically valid URL the browser
   won't block, but not http(s).
2. Submit.

**Expected UI result**
- The submission is rejected and the form shows the raw error text **"cover_url must be
  a valid http(s) URL"** (the frontend's generic error fallback renders the field name
  and backend message verbatim — it isn't humanized).

**Backend verification**
```elixir
Repo.get_by(Book, title: "Bad Cover Test")
# => nil
```
**Pass criteria:** an `ftp://` URL passes the browser's native `type="url"` check but is
still rejected server-side; nothing is created.

---

### Test 9 — A blank/whitespace-only search box behaves exactly like no search

**Setup:** continue from earlier tests so at least one book exists.

**Steps (Underlined UI)**
1. On `/books`, click into the search box, type a few spaces, then nothing else.

**Expected UI result**
- The full catalog (every book added so far) is shown — identical to loading `/books`
  with an empty search box. No error, no empty grid.

**Pass criteria:** whitespace-only input is treated the same as "no query" rather than
as a literal (and unmatchable) search term.

---

## Edge cases

### Test 10 — Re-adding the same title + author (any casing) doesn't duplicate

**Steps (Underlined UI)**
1. Go to `/books/new` and submit Title `SAPIENS`, Author `yuval noah harari` — same
   book as Test 1, different casing throughout.

**Expected UI result**
- Submission **succeeds** (redirects to `/books`) exactly like a normal add — there is
  no "already exists" error. The catalog still shows only **one** Sapiens tile, not two.

**Backend verification**
```elixir
Repo.aggregate(from(b in Book, where: ilike(b.title, "sapiens")), :count)
# => 1
```
**Pass criteria:** the duplicate attempt is silently absorbed (the API hands back the
existing row's id instead of inserting a second one) — case-insensitively on **both**
title and author.

---

### Test 11 — Same title, different author is a distinct book, not a duplicate

**Steps (Underlined UI)**
1. Add Title `1984`, Author `George Orwell`.
2. Add Title `1984`, Author `A Different Writer`.

**Expected UI result**
- Both submissions succeed; `/books` shows **two** separate "1984" tiles, distinguished
  by author underneath the title.

**Backend verification**
```elixir
Repo.all(from b in Book, where: b.title == "1984", select: b.author)
# => ["George Orwell", "A Different Writer"] (order may vary)
```
**Pass criteria:** duplicate detection only triggers when **both** fields match — a
shared title alone is not enough to merge two different books.

---

### Test 12 — Search ranks a stronger keyword match above a weaker one

**Setup**
1. Add Title `Learning to Learn`, Author `Some Author` (the word "learning"/"learn"
   stem appears twice across title+author).
2. Add Title `A Guide to Reading`, Author `Learning Press` (the stem appears once).

**Steps (Underlined UI)**
1. Search `learning`.

**Expected UI result**
- Both books appear, but **"Learning to Learn" is listed first** — Postgres full-text
  search ranks results by how strongly the term matches (`ts_rank`), and a term that
  appears more often ranks higher.

**Pass criteria:** result order isn't arbitrary/insertion-order — it tracks match
strength.

---

### Test 13 — Cover image renders for real when a valid URL is given

Contrasts directly with the 📖 placeholder seen in every test above.

**Steps (Underlined UI)**
1. Add a book with a real, stable public image URL as Cover image URL, e.g.
   `https://picsum.photos/200/300`.

**Expected UI result**
- That tile shows the actual image, not the 📖 emoji placeholder — confirming the
  placeholder is specifically a "no cover" fallback, not a rendering bug for every tile.

**Pass criteria:** tiles with a `cover_url` render an `<img>`; tiles without one render
the emoji placeholder — never a broken-image icon either way.

---

### Test 14 (optional) — Typing doesn't fire a search request on every keystroke

**Steps (Underlined UI, with devtools open)**
1. Open the Network tab, filter for `books`.
2. On `/books`, type a multi-character query quickly, letter by letter (e.g. `sapiens`).

**Expected result**
- Only **one** `GET /api/books?q=...` request fires, about 300ms after you stop typing
  — not one request per keystroke.

**Pass criteria:** the search box is debounced; rapid typing doesn't spam the API.

---

### Test 15 — Validation errors appear translated when the UI locale is pt-BR

**Steps (Underlined UI)**
1. Switch the locale to pt-BR (the `LocaleSwitcher` in the top bar).
2. Go to `/books/new`, repeat Test 8's invalid-cover-URL submission (`ftp://...`).

**Expected UI result**
- The error text reads in Portuguese (the backend's gettext "errors" domain is locale-
  aware the same way Step 1's auth errors are) rather than falling back to English.

**Pass criteria:** book-creation validation errors are translated the same way
auth/profile validation errors already are — this isn't a Step 1-only behavior.

---

## Security/Permission cases

### Test 16 — Browsing and searching the catalog needs no login at all

**Steps**
1. Open `/books` in a private/incognito window (no session).
2. Search for something.

Also confirm at the API level:
```
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/books
curl -s -o /dev/null -w "%{http_code}\n" "http://localhost:4000/api/books?q=sapiens"
```

**Expected result**
- Both the UI and the raw `curl` calls return `200` with no `Authorization` header —
  reading the catalog is fully public, by design.

**Pass criteria:** no auth prompt, no redirect, no 401 anywhere in the read path.

---

### Test 17 — Visiting "Add a book" while logged out redirects to login first

**Steps (Underlined UI, with devtools Network tab open)**
1. Log out (or use a private window).
2. Navigate directly to `http://localhost:3000/books/new`.

**Expected UI result**
- You're bounced to `/login?redirect=/books/new` **immediately**, client-side, before
  any request to `/api/books` is made — check the Network tab to confirm no `POST
  /api/books` (or even a failed one) appears; the redirect happens before the form is
  ever usable.

**Pass criteria:** the frontend's route guard, not a failed API call, is what stops an
unauthenticated user here.

---

### Test 18 — Calling the create endpoint directly without a token is rejected

Bypasses the UI's route guard entirely, to confirm the API enforces the same rule on
its own.

**Steps**
```
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/books \
  -H "Content-Type: application/json" \
  -d '{"book":{"title":"Ghost Book","author":"Nobody"}}'
```

**Expected result**
- `401`.

**Backend verification**
```elixir
Repo.get_by(Book, title: "Ghost Book")
# => nil
```
**Pass criteria:** no token means no insert, independent of whatever the frontend
would have done — the server-side auth check is the real gate, not the UI redirect in
Test 17.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Add a book via the UI | Created, shown in catalog immediately |
| 2 | Search by title | Found, case-insensitive |
| 3 | Search by author only | Found — search spans title + author |
| 4 | Search with no matches | Empty grid, no error |
| 5 | Get unknown/malformed book id | `404`, both cases alike |
| 6 | Create with missing field (API) | `422`, nothing inserted |
| 7 | Title length boundary (80/81) | 80 succeeds, 81 rejected |
| 8 | Invalid cover URL scheme | Rejected server-side despite passing browser check |
| 9 | Blank/whitespace search | Same as no search |
| 10 | Duplicate title+author (any case) | No second row created |
| 11 | Same title, different author | Two distinct rows |
| 12 | Search relevance ranking | Stronger match ranks first |
| 13 | Valid cover URL | Real image renders, not placeholder |
| 14 | Rapid typing in search | One debounced request, not one per keystroke |
| 15 | pt-BR locale validation error | Error text translated |
| 16 | Browse/search while logged out | Fully public, `200` |
| 17 | Visit add-book page logged out | Client-side redirect to `/login`, no API call |
| 18 | Create book with no token (API) | `401`, nothing inserted |

If every row holds, Step 2's catalog is safe end-to-end: reads are public, writes are
gated, validation is enforced on the server (not just the browser), and duplicate/edge
input is handled predictably rather than crashing or silently corrupting data.
