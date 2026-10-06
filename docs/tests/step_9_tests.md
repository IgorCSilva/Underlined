# Manual Test Plan — Step 9: Keyword Pages

Scope: [roadmap.md](../base_content/roadmap.md) Step 9 — every keyword chip across
the app becomes a link to a dedicated keyword page showing that keyword's stats
(posts/books/readers), related keywords, and every matching post. Like
[Step 8](step_8_tests.md), there is **no Community Health pairing** for this step
(HealthyCommunity's own roadmap says so explicitly for Step 9, and nothing in the
keyword usecase calls `CommunityHealthWorker`/enqueues any CH event); every test
below is scoped entirely to Underlined's own UI (`http://localhost:3000`) and API
(`http://localhost:4000`).

## Before you start

- Underlined's stack is up: `docker compose up -d` (HealthyCommunity is irrelevant
  here — don't bother starting it).
- You need at least one enabled user and a couple of posts with keywords. Sign up
  at `/signup`, enable the account from the running `api` container — never with
  `psql`:
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
  Then log in at `/login`, create a book at `/books/new`, and write a few posts at
  `/posts/new` — give some of them overlapping keywords (e.g. "attention" on one
  post, "attention, ecology" on another) so stats and related keywords have
  something to show.
- All DB verification below uses `docker compose exec api iex -S mix` — never
  `psql`.

---

## Positive cases

### Test 1 — Keyword chips are clickable everywhere they appear

**Steps (Underlined UI)**
1. Go to `/feed` (or any post detail page at `/posts/:id`).
2. Hover over a keyword chip under a post.

**Expected UI result**
- The cursor becomes a pointer and the chip's text grows a yellow underline
  stroke — no background/color change, matching the design note that hover here
  means "this is clickable," not a generic hover state.
3. Click the chip.

**Expected UI result**
- You land on `/keywords/<that keyword>`.

**Pass criteria:** every keyword chip in the app (feed, post detail) is a real
link, not a static label.

---

### Test 2 — The keyword page shows accurate stats

**Setup:** write three posts as the same user, same book, all tagged "focus."

**Steps (Underlined UI)**
1. Click the "focus" chip on any of those posts, or go straight to
   `/keywords/focus`.

**Expected UI result**
- A large serif headline "focus" with a permanent yellow underline beneath it
  (not just on hover — this is the one place the stroke never goes away).
- Three sand-bordered badges below the headline read "3 posts", "1 book", "1
  reader" — book/reader counts reflect *distinct* books/readers, not post count.

**Backend verification**
```elixir
# (optional) cross-check directly against the API
```
```
curl -s http://localhost:4000/api/keywords/focus | python3 -m json.tool
```
**Pass criteria:** `stats.post_count` is the raw post count, but
`stats.book_count`/`stats.reader_count` stay at 1 each despite three posts,
because they're the same book and the same author.

---

### Test 3 — Related keywords are shown as outline chips, most-shared first

**Setup:** write two posts tagged "attention, ecology" and one post tagged
"attention, focus" (three posts total sharing "attention").

**Steps (Underlined UI)**
1. Go to `/keywords/attention`.

**Expected UI result**
- Below the stat badges, a row of outline ink-blue chips reads "ecology" then
  "focus" — visually lighter (no fill, just a border) than the solid sand
  keyword chips on posts, since these read as "explore next" rather than
  "attached to this." "ecology" appears first because it co-occurs with
  "attention" on two posts, "focus" on only one.
2. Click "ecology".

**Expected UI result**
- You land on `/keywords/ecology`, with its own stats and its own related
  keywords (which now includes "attention").

**Pass criteria:** related keywords are ranked by how many posts they share with
the current keyword, and each one is itself a working link into the idea graph.

---

### Test 4 — Matching posts use the standard feed layout, newest first

**Setup:** continue from Test 3 (three posts tagged "attention").

**Steps (Underlined UI)**
1. On `/keywords/attention`, scroll past the stats/related row.

**Expected UI result**
- The matching posts render exactly like `/feed` — a divider list, not cards,
  with the same avatar/username/book header, passage, thinking, keyword chips,
  and like/bookmark/comment icon row — newest post first.

**Pass criteria:** the keyword page's post list is indistinguishable in layout
from the main feed; only the headline/stats/related section above it is new.

---

### Test 5 — Keyword lookup is trimmed and case-insensitive

**Setup:** a post tagged with the keyword "Nature-Writing" (mixed case, as typed
in the composer).

**Steps (Underlined UI)**
1. Go directly to `/keywords/nature-writing` (lowercase, as the keyword chip
   itself always renders).

**Expected UI result**
- The page loads normally and shows the post — the same trim+downcase
  normalization used when the post was created is applied to the URL lookup, so
  case or stray whitespace in the URL never produces a false "not found."

**Pass criteria:** `/keywords/Nature-Writing`, `/keywords/nature-writing`, and
`/keywords/ NATURE-WRITING ` (if your browser lets you type the spaces) all
resolve to the same page.

---

### Test 6 — Load more paginates the same way the main feed does

**Setup:** this requires 21+ posts sharing one keyword to see a second page in
the UI; alternatively, verify the cursor contract directly:
```
curl -s "http://localhost:4000/api/keywords/attention"
# copy the inserted_at of the last post in the response, then:
curl -s "http://localhost:4000/api/keywords/attention?before=<that inserted_at>"
```

**Expected result**
- The second call returns only posts strictly older than the cursor — the exact
  `before`-cursor convention `/feed` and `/saved` already use, so "Load more" on
  the keyword page behaves identically to everywhere else in the app.

**Pass criteria:** no duplicate or skipped posts across pages.

---

### Test 7 — An authenticated viewer sees their own like/bookmark state

**Setup:** log in, like one of the posts shown on a keyword page.

**Steps (Underlined UI)**
1. Reload the keyword page.

**Expected UI result**
- The liked post's heart icon is filled, exactly as it would be on `/feed` — the
  keyword page annotates `liked_by_user`/`bookmarked_by_user` for the current
  viewer the same way every other post list in the app does.

**Pass criteria:** like/bookmark state on the keyword page is per-viewer, not a
static snapshot.

---

## Negative cases

### Test 8 — An unknown or never-used keyword shows "doesn't exist," not a crash

**Steps (Underlined UI)**
1. Go to `/keywords/this-keyword-was-never-used`.

**Expected UI result**
- A plain "this keyword doesn't exist yet" message — no error page, no crash.

**Backend verification**
```
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/keywords/this-keyword-was-never-used
```
**Expected result:** `404`.

**Pass criteria:** a keyword with no posts (or that never existed) degrades
gracefully on both the API and the UI.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Hover/click a keyword chip anywhere | Underline grows on hover; click navigates to `/keywords/<name>` |
| 2 | View stats for a keyword | Sand badges show distinct post/book/reader counts |
| 3 | View related keywords | Outline ink-blue chips, most-shared first, each a working link |
| 4 | View matching posts | Same layout as `/feed`, newest first |
| 5 | Visit a keyword URL in a different case | Resolves to the same page as the lowercase chip |
| 6 | Paginate with `before` | Same cursor convention as `/feed`/`/saved`, no dupes/gaps |
| 7 | View as a logged-in viewer who liked a post | That post's heart is filled |
| 8 | Visit an unknown keyword | `404` from the API; "doesn't exist" message in the UI |

If every row holds, Step 9's keyword pages are a real destination: stats and
related keywords are accurate aggregations (not raw post counts), every keyword
chip in the app is a working link into the idea graph, and the matching-posts
list is a drop-in reuse of the main feed — and since this step has no Community
Health pairing, none of that behavior changes whether CH is running, disabled, or
absent.
