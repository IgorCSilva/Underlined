# Manual Test Plan — Step 8: Save/Bookmark Posts

Scope: [roadmap.md](../base_content/roadmap.md) Step 8 — saving a post for later and
viewing everything saved on a dedicated `/saved` page. Like [Step 2](step_2_tests.md),
there is **no Community Health pairing** for this step (there's no "Community Health"
note for Step 8 in the roadmap, and nothing in the bookmark usecases calls
`CommunityHealthWorker`/enqueues any CH event); every test below is scoped entirely to
Underlined's own UI (`http://localhost:3000`) and API (`http://localhost:4000`).

## Before you start

- Underlined's stack is up: `docker compose up -d` (HealthyCommunity is irrelevant here
  — don't bother starting it).
- You have one **enabled** user to log in with, since bookmarking requires
  authentication. Sign up at `/signup`, then enable the account from the running `api`
  container — never with `psql`:
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
  Then log in at `/login`.
- You need at least one post to bookmark. Create a book at `/books/new` and a post at
  `/posts/new` if the feed is empty.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql` —
  with:
  ```elixir
  alias Api.Repo
  alias Api.Infrastructure.Repository.Bookmark.Postgres.Bookmark
  import Ecto.Query
  ```
- A few tests call the API directly with `curl`. Where a test needs a bearer token, get
  one the same way the UI does:
  ```
  curl -s -X POST http://localhost:4000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"<your enabled user's email>","password":"<their password>"}'
  ```
  Copy the `data.access_token` value from the response for the `Authorization: Bearer
  <token>` header in later `curl` commands.

---

## Positive cases

### Test 1 — Bookmarking a post via the UI fills the ribbon icon

**Steps (Underlined UI)**
1. Go to `/feed`.
2. Find a post and click the outline ribbon icon in its action row (next to the heart
   and comment-count icons).

**Expected UI result**
- The ribbon fills solid ochre/sand immediately — no loading delay, no error. Clicking
  it doesn't navigate anywhere (the post's passage/thinking link still goes to the post
  page; the ribbon itself is a self-contained toggle).

**Backend verification**
```elixir
post_id = "<the post's id>"

Repo.exists?(from b in Bookmark, where: b.post_id == ^post_id)
# => true
```
**Pass criteria:** exactly one `bookmarks` row exists for this post/user pair, and the
UI reflects the saved state immediately.

---

### Test 2 — A bookmarked post appears on the Saved page

**Setup:** continue from Test 1.

**Steps (Underlined UI)**
1. Open the top nav and click "Saved" (or go straight to `/saved`).

**Expected UI result**
- The post bookmarked in Test 1 appears in the list, laid out exactly like the main
  feed (a divider list, not cards) — same passage/thinking/keyword/icon-row layout as
  `/feed` — but with a small 🔖 badge in the top-right corner of its row, which the main
  feed never shows.

**Pass criteria:** the Saved page is "the same feed, filtered" — identical item layout,
plus the one badge that marks why it's there.

---

### Test 3 — Unbookmarking removes the post from the Saved page

**Setup:** continue from Test 2.

**Steps (Underlined UI)**
1. On `/saved`, click the now-filled ribbon icon on that post's row to unbookmark it.

**Expected UI result**
- The ribbon empties back to its outline state immediately.
2. Reload `/saved`.

**Expected UI result after reload**
- The post is gone from the Saved list entirely.

**Backend verification**
```elixir
Repo.exists?(from b in Bookmark, where: b.post_id == ^post_id)
# => false
```
**Pass criteria:** unbookmarking is reflected both instantly (optimistic UI) and after a
hard reload (server state actually changed) — the Saved page is a live reflection of the
`bookmarks` table, not a cached snapshot.

---

### Test 4 — Bookmarking the same post twice doesn't duplicate it on the Saved page

**Steps**
1. Bookmark a post from `/feed`.
2. Submit a second bookmark request for the same post directly against the API (a stray
   double-click before the button's state updates is the realistic UI equivalent):
   ```
   curl -s -X POST http://localhost:4000/api/posts/<post_id>/bookmarks \
     -H "Authorization: Bearer <your access_token>"
   ```

**Expected result**
- Both calls return `200 {"data":{"bookmarked":true}}`.

**Backend verification**
```elixir
Repo.aggregate(from(b in Bookmark, where: b.post_id == ^post_id), :count)
# => 1
```
**Pass criteria:** exactly one row, and the post appears exactly once on `/saved` — the
unique `[user_id, post_id]` index is enforced at the application level (idempotent
insert), not just left to the DB constraint to silently error on.

---

### Test 5 — The Saved list orders by post creation time, not bookmark time

**Setup**
1. Create two posts, A then B (B created after A).
2. Bookmark A, then bookmark B.

**Steps (Underlined UI)**
1. Open `/saved`.

**Expected UI result**
- B (the more recently *created* post) appears above A — the Saved list orders by each
  post's own `inserted_at`, newest first, the same ordering rule `/feed` uses, **not**
  by the order you bookmarked them in.

**Pass criteria:** this confirms the Saved page reuses `/feed`'s exact sort key and
cursor convention rather than introducing a separate "time saved" ordering — relevant
if you're tempted to bookmark an old post expecting it to jump to the top of your list.

---

## Negative cases

### Test 6 — Bookmarking an unknown or malformed post id returns 404

**Steps**
```
curl -s -o /dev/null -w "%{http_code}\n" -X POST \
  http://localhost:4000/api/posts/00000000-0000-0000-0000-000000000000/bookmarks \
  -H "Authorization: Bearer <your access_token>"

curl -s -o /dev/null -w "%{http_code}\n" -X POST \
  http://localhost:4000/api/posts/not-even-a-uuid/bookmarks \
  -H "Authorization: Bearer <your access_token>"
```

**Expected result**
- Both return `404` — a well-formed UUID that doesn't exist and a string that isn't a
  UUID at all are handled identically, neither one crashing with a 500.

---

### Test 7 — Unbookmarking a post that was never bookmarked is a no-op, not an error

**Steps**
```
curl -s http://localhost:4000/api/posts/<some post you never bookmarked>/bookmarks \
  -X DELETE -H "Authorization: Bearer <your access_token>"
```

**Expected result**
- `200 {"data":{"bookmarked":false}}` — removing a bookmark that doesn't exist succeeds
  quietly instead of returning a 404 or 422.

---

## Security/Permission cases

### Test 8 — Bookmarking, unbookmarking, and listing all require authentication

**Steps**
```
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/posts/<post_id>/bookmarks
curl -s -o /dev/null -w "%{http_code}\n" -X DELETE http://localhost:4000/api/posts/<post_id>/bookmarks
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/me/bookmarks
```

**Expected result**
- All three return `401` with no `Authorization` header.

Also confirm at the UI level:
1. Log out (or use a private window).
2. Navigate directly to `http://localhost:3000/saved`.

**Expected UI result**
- You're bounced to `/login?redirect=/saved` client-side, the same route-guard pattern
  every other auth-gated page (`/profile`, `/books/new`) already uses.

**Pass criteria:** no bookmark state is ever readable or writable without a valid
session, and the Saved page is never reachable while logged out.

---

### Test 9 — The Saved page only ever shows the current user's own bookmarks

**Setup**
1. Log in as User A, bookmark a post.
2. Log out, log in as User B (who hasn't bookmarked anything).

**Steps (Underlined UI)**
1. Open `/saved` as User B.

**Expected UI result**
- The list is empty, even though User A has a bookmark on record.

**Backend verification**
```elixir
alias Api.Infrastructure.Repository.User.Postgres.User

user_b = Repo.one(from u in User, where: u.email == "<User B's email>")
Repo.all(from b in Bookmark, where: b.user_id == ^user_b.id)
# => []
```
**Pass criteria:** `GET /api/me/bookmarks` is scoped to the authenticated caller's own
`user_id` — there is no way to view another user's saved-posts list, by design (there's
no `GET /api/users/:id/bookmarks` route at all).

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Bookmark a post via the UI | Ribbon fills immediately, one row created |
| 2 | View a bookmarked post on `/saved` | Appears, same layout as feed + 🔖 badge |
| 3 | Unbookmark from `/saved` | Ribbon empties; post gone after reload |
| 4 | Bookmark the same post twice | `200` both times, no duplicate row |
| 5 | Bookmark two posts | Saved list orders by post creation time, newest first |
| 6 | Bookmark unknown/malformed post id | `404`, both cases alike |
| 7 | Unbookmark a never-bookmarked post | `200`, no-op, not an error |
| 8 | Bookmark/unbookmark/list with no token | `401`; `/saved` redirects to `/login` |
| 9 | View `/saved` as a different user | Only that user's own bookmarks appear |

If every row holds, Step 8's save/bookmark feature is safe end-to-end: writes are
gated, bookmarking is idempotent, the Saved page is a live, per-user, feed-identical
view of the `bookmarks` table — and since this step has no Community Health pairing,
none of that behavior changes whether CH is running, disabled, or absent.
