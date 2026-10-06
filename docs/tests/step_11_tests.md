# Manual Test Plan — Step 11: Related Posts (Keyword Overlap)

Scope: [roadmap.md](../base_content/roadmap.md) Step 11 — a post's detail page gains
a "Related ideas" module showing other posts that share one or more keywords with it.
Like [Step 8](step_8_tests.md), [Step 9](step_9_tests.md), and
[Step 10](step_10_tests.md), there is **no Community Health pairing** for this step
(HealthyCommunity's own roadmap says so explicitly for Step 11); every test below is
scoped entirely to Underlined's own UI (`http://localhost:3000`) and API
(`http://localhost:4000`).

## Before you start

- Underlined's stack is up: `docker compose up -d` (HealthyCommunity is irrelevant
  here — don't bother starting it).
- You need at least one enabled user and a few posts with overlapping keywords. Sign
  up at `/signup`, enable the account from the running `api` container — never with
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
  Then log in at `/login`, create a book at `/books/new`, and write at least three
  posts at `/posts/new`: one "target" post tagged `attention, nature-writing`, one
  tagged `attention, nature-writing` as well (shares both), one tagged just
  `attention` (shares one), and one tagged something unrelated like `cooking` (shares
  none).
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — The post detail page shows a "Related ideas" panel

**Steps (Underlined UI)**
1. Open the "target" post's detail page at `/posts/:id`, scrolling past the comment
   thread.

**Expected UI result**
- Below the comments, a cream-colored panel (same fill as the passage hero above —
  no hard border, just the color shift from the white page) labeled "Related ideas"
  appears, listing compact rows: a short passage snippet in serif with a yellow
  underline, and the source book's title in small gray sans beneath it.

**Pass criteria:** the panel renders with the expected cream/serif/underline styling,
distinct from the comment thread above it.

---

### Test 2 — Posts with more shared keywords rank first

**Setup:** continue with the four posts described above (two-shared, one-shared,
unrelated, and the target itself).

**Steps (Underlined UI / API)**
1. On the target post's detail page, read the order of the "Related ideas" rows.
2. Verify directly against the API:
   ```
   curl -s http://localhost:4000/api/posts/<target post id>/related | python3 -m json.tool
   ```

**Expected result**
- The post sharing both keywords appears before the post sharing only one. The
  unrelated post (no shared keywords) and the target post itself never appear.

**Pass criteria:** ranking reflects keyword-overlap count, most shared keywords
first; the panel never includes the post it's shown on.

---

### Test 3 — Clicking a row navigates to that post

**Steps (Underlined UI)**
1. Click any row in the "Related ideas" panel.

**Expected UI result**
- The browser navigates to `/posts/<that related post's id>` — the entire row (snippet
  and book title) is one clickable link, not just the text.

**Pass criteria:** every row is a working link to its own post detail page.

---

### Test 4 — A post with no keywords shows no related-ideas panel

**Setup:** write a post without adding any keywords.

**Steps (Underlined UI)**
1. Open that post's detail page.

**Expected UI result**
- No "Related ideas" panel appears at all (there is nothing to relate it to).

**Backend verification**
```
curl -s http://localhost:4000/api/posts/<that post's id>/related
```
**Expected result:** `{"data": []}`.

**Pass criteria:** the module is omitted entirely rather than rendering empty.

---

## Negative cases

### Test 5 — An unknown post id degrades gracefully, not a crash

**Steps (Underlined UI)**
1. Go to `/posts/00000000-0000-0000-0000-000000000000`.

**Expected UI result**
- The existing "Post not found." message renders — no crash, and no stray
  "Related ideas" panel.

**Backend verification**
```
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/posts/00000000-0000-0000-0000-000000000000/related
```
**Expected result:** `404`.

**Pass criteria:** an unknown post id degrades gracefully on both the API and the UI.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Open a post's detail page | Cream "Related ideas" panel below the comment thread, serif snippet + yellow underline, gray book title |
| 2 | Compare posts with different keyword overlap | Most shared keywords first; the post itself and unrelated posts never appear |
| 3 | Click a related-ideas row | Navigates to that post's detail page |
| 4 | Open a post with no keywords | No "Related ideas" panel renders |
| 5 | Visit an unknown post id | `404` from the API; "Post not found." in the UI, no stray panel |

If every row holds, Step 11 gives every post a working, accurate "discover adjacent
ideas" module driven purely by keyword overlap — and since this step has no Community
Health pairing, none of that behavior changes whether CH is running, disabled, or
absent.
