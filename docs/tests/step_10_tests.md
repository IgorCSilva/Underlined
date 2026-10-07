# Manual Test Plan — Step 10: Book Pages

Scope: [roadmap.md](../base_content/roadmap.md) Step 10 — every book reference across
the app (in the feed, and in a post's detail view) becomes a link to a dedicated book
page showing that book's stats (posts/readers) and every post the community has
written about it. Like [Step 8](step_8_tests.md) and [Step 9](step_9_tests.md), there
is **no Community Health pairing** for this step (HealthyCommunity's own roadmap says
so explicitly for Step 10); every test below is scoped entirely to Underlined's own UI
(`http://localhost:3000`) and API (`http://localhost:4000`).

## Before you start

- **Start from an empty database.** This file assumes Underlined's database is empty
  before Test 1 (then builds up a book and posts, per the next bullet). If you're
  re-running this file, empty it first with the Underlined snippet from
  [Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
  (skip the HealthyCommunity one — this step doesn't touch it), the same snippet this
  file's [Cleanup](#cleanup) section ends with.
- Underlined's stack is up: `docker compose up -d` (HealthyCommunity is irrelevant
  here — don't bother starting it).
- You need at least one enabled user and a book with a couple of posts. Sign up at
  `/signup`, enable the account from the running `api` container — never with `psql`:
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
  Then log in at `/login`, create a book at `/books/new`, and write a few posts about
  it at `/posts/new`.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — Book references are clickable everywhere they appear

**Steps (Underlined UI)**
1. Go to `/feed` and hover over the book title next to a post's author ("… on
   *Sapiens*").
2. Click it.

**Expected UI result**
- The cursor becomes a pointer and the title grows a yellow underline on hover (same
  "this is clickable" treatment as keyword chips). Clicking lands on
  `/books/<that book's id>`.

3. Open a post's detail page at `/posts/:id` and hover/click the book cover+title
   block in the passage hero.

**Expected UI result**
- Same hover underline on the title, same destination: `/books/<book id>`.

**Pass criteria:** every book reference in the app (feed, post detail) is a real
link, not a static label.

---

### Test 2 — The book page shows a wide header band with accurate stats

**Setup:** write three posts as the same user, all about the same book.

**Steps (Underlined UI)**
1. Click the book's title/cover from any of those posts, or go straight to
   `/books/<book id>`.

**Expected UI result**
- A wide header band: the book cover large (~160px) on the left, with the title in
  large serif and the author in gray sans stacked beside it.
- Two sand-bordered badges below the title read "3 posts" and "1 reader" — the same
  badge style as the keyword page, so the two "hub" pages feel like siblings.

**Backend verification**
```
curl -s http://localhost:4000/api/books/<book id>/page | python3 -m json.tool
```
**Pass criteria:** `stats.post_count` is the raw post count; `stats.reader_count`
reflects *distinct* authors, not post count.

---

### Test 3 — Matching posts use the standard feed layout, newest first

**Setup:** continue from Test 2 (three posts about the same book).

**Steps (Underlined UI)**
1. On the book page, scroll past the header band.

**Expected UI result**
- The matching posts render exactly like `/feed` — a divider list, not cards, with
  the same avatar/username/book-line header, passage, thinking, keyword chips, and
  like/bookmark/comment icon row — newest post first.

**Pass criteria:** the book page's post list is indistinguishable in layout from the
main feed; only the header band above it is new.

---

### Test 4 — Load more paginates the same way the main feed does

**Setup:** this requires 21+ posts about one book to see a second page in the UI;
alternatively, verify the cursor contract directly:
```
curl -s "http://localhost:4000/api/books/<book id>/page"
# copy the inserted_at of the last post in the response, then:
curl -s "http://localhost:4000/api/books/<book id>/page?before=<that inserted_at>"
```

**Expected result**
- The second call returns only posts strictly older than the cursor — the exact
  `before`-cursor convention `/feed`, `/saved`, and the keyword page already use.

**Pass criteria:** no duplicate or skipped posts across pages.

---

### Test 5 — An authenticated viewer sees their own like/bookmark state

**Setup:** log in, like one of the posts shown on a book page.

**Steps (Underlined UI)**
1. Reload the book page.

**Expected UI result**
- The liked post's heart icon is filled, exactly as it would be on `/feed` — the book
  page annotates `liked_by_user`/`bookmarked_by_user` for the current viewer the same
  way every other post list in the app does.

**Pass criteria:** like/bookmark state on the book page is per-viewer, not a static
snapshot.

---

## Negative cases

### Test 6 — An unknown book id shows "doesn't exist," not a crash

**Steps (Underlined UI)**
1. Go to `/books/00000000-0000-0000-0000-000000000000`.

**Expected UI result**
- A plain "this book doesn't exist" message — no error page, no crash.

**Backend verification**
```
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/books/00000000-0000-0000-0000-000000000000/page
```
**Expected result:** `404`.

**Pass criteria:** an unknown book id degrades gracefully on both the API and the UI.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Hover/click a book reference in the feed or on post detail | Underline grows on hover; click navigates to `/books/<id>` |
| 2 | View stats for a book | Wide header band with large cover, title, author, and sand badges with accurate distinct post/reader counts |
| 3 | View matching posts | Same layout as `/feed`, newest first |
| 4 | Paginate with `before` | Same cursor convention as `/feed`/`/saved`/keyword page, no dupes/gaps |
| 5 | View as a logged-in viewer who liked a post | That post's heart is filled |
| 6 | Visit an unknown book id | `404` from the API; "doesn't exist" message in the UI |

If every row holds, Step 10's book pages are a real destination: stats are accurate
aggregations (not raw post counts), every book reference in the app is a working link
into its page, and the matching-posts list is a drop-in reuse of the main feed — and
since this step has no Community Health pairing, none of that behavior changes
whether CH is running, disabled, or absent.

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
(HealthyCommunity isn't touched by this step, so there's nothing to reset there). That
leaves Underlined's database empty — schema and containers untouched, zero rows — so
[Step 11's tests](step_11_tests.md) can start from the same clean slate this file
assumed at the top.
