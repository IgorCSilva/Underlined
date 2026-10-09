# Manual Test Plan — Step 16: Contradiction / Debate View

Scope: [roadmap.md](../base_content/roadmap.md) Step 16 — a dedicated side-by-side view for
two posts connected as `contradicts`, with a discussion thread scoped to the disagreement
itself rather than to either post. Like [Step 14](step_14_tests.md) and
[Step 15](step_15_tests.md), there is **no Community Health pairing** for this step; every
test below is scoped entirely to Underlined's own UI (`http://localhost:3000`) and API
(`http://localhost:4000`).

This file also covers the follow-up redesign of the debate comment UI
([improvements.md](improvements.md)): each debate comment now declares a **side** —
ink-blue (agrees with post A), terracotta (agrees with post B), or neutral — is laid out in
a two-column grid matching the post cards, and a reply is a flat, side-colored comment
carrying a clickable reference back to the comment it replies to, rather than a nested,
indented reply.

## Before you start

- **Start from an empty database.** This file assumes Underlined's database is empty
  before Test 1. If you're re-running this file, empty it first with the Underlined
  snippet from
  [Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
  (skip the HealthyCommunity one — this step doesn't touch it), the same snippet this
  file's [Cleanup](#cleanup) section ends with.
- Underlined's stack is up: `docker compose up -d` (HealthyCommunity is irrelevant
  here — don't bother starting it).
- You need at least one enabled user with two posts about the same (or different) book.
  Sign up at `/signup`, enable the account from the running `api` container — never with
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
  Then log in at `/login`, create a book at `/books/new`, and write two posts about it at
  `/posts/new` (post A, post B). On post A's page (`/posts/<post A id>`), use "+ Connect
  to another post" to link it to post B with relationship type "Contradicts". A second,
  **different** enabled user is also useful (for the "debates are public reads, but
  comments need auth" tests, and for replying as someone other than the original
  commenter) — sign up a second account the same way.
- A few tests call the API directly with `curl` (to reach states the UI's own guards
  prevent, or to inspect the raw JSON shape). Where a test needs a bearer token, get one
  the same way the UI does:
  ```
  curl -s -X POST http://localhost:4000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"<your enabled user's email>","password":"<their password>"}'
  ```
  Copy the `data.access_token` value from the response for the `Authorization: Bearer
  <token>` header in later `curl` commands.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — A `contradicts` connection shows an "Open as debate" link

**Setup:** logged in, with post A and post B connected as "Contradicts" from "Before you
start" already done.

**Steps (Underlined UI)**
1. Go to post A's page (`/posts/<post A id>`).

**Expected UI result**
- Among post A's connection pills, the "Contradicts" pill row also shows an "Open as
  debate →" link, next to the normal link to post B.
- Clicking it navigates to `/debates/<connection id>`.

**Pass criteria:** the debate view is reachable from exactly the connections that are
`contradicts` — not from `similar_idea`, `expands_on`, or any other relationship type.

---

### Test 2 — The debate page shows both posts side by side

**Setup:** continue from Test 1, on `/debates/<connection id>`.

**Expected UI result**
- The page breaks the normal single-column layout: two equal-width post cards sit side
  by side.
- The left card (post A) has a 4px ink-blue top border; the right card (post B) has a
  4px terracotta top border.
- Between the two cards, a vertical dashed sand-colored divider has a small centered
  pill badge reading "Contradicts" in terracotta.
- Each card shows its post's book, passage, and thinking, same as a normal post card,
  including its own heart "Like" icon/count and 💬 comment-count icon, same as a normal
  feed card — this is the **existing** post Like feature, reused as-is for each side of
  the debate (see Test 9), not a new "agree" feature.

**Backend verification**
```
curl -s http://localhost:4000/api/connections/<connection id> | python3 -m json.tool
```
**Expected result:** `data.relationship_type` is `"contradicts"`; `data.post_a` and
`data.post_b` are the two full posts (in either order), each shaped like a normal post
JSON payload (book, passage, thinking, keywords, like_count, comment_count, etc.).

**Pass criteria:** both sides of the disagreement are visible together, visually
distinguished, without needing to click back and forth between two separate post pages.

---

### Test 3 — The debate thread is independent of either post's own comments, and only debate comments carry a `side`

**Setup:** continue from Test 2.

**Steps (Underlined UI)**
1. On `/debates/<connection id>`, post a comment in the thread below the cards (e.g.
   "I think post A has it right"), choosing any of the three side buttons (see Test 4).
2. Go to post A's own page (`/posts/<post A id>`) and post a separate comment there
   (e.g. "A regular comment on post A").
3. Go back to `/debates/<connection id>`.
4. Open post A's page again.

**Expected UI result**
- The debate-thread comment from step 1 appears only on the debate page — not on post
  A's or post B's own comment thread.
- Post A's own comment from step 2 appears only on post A's page — not on the debate
  thread.
- Post A's own comment thread looks exactly as it did before this redesign: a single
  generic "Post" submit button, no side coloring, no column layout, nested replies —
  the redesign in this file is scoped entirely to the debate page.

**Backend verification**
```
curl -s http://localhost:4000/api/connections/<connection id>/comments | python3 -m json.tool
curl -s http://localhost:4000/api/posts/<post A id>/comments | python3 -m json.tool
```
**Expected result:** the first list contains only the debate comment, and each comment
object has a `"side"` key (`"post_a"`, `"post_b"`, or `"neutral"`). The second list
contains only the post comment, and its comment objects have **no** `"side"` key at
all — no overlap between threads, and the `side` concept never leaks onto a post's own
comments.

**Pass criteria:** the discussion is genuinely "scoped to the disagreement itself," a
third thread distinct from either post's own, and `side` is a debate-thread-only concept.

---

### Test 4 — Posting a side-colored comment places it in the matching column

**Setup:** continue from Test 3, on `/debates/<connection id>` at a desktop-width
browser window (≥ 720px wide).

**Steps (Underlined UI)**
1. Type a comment agreeing with post A (e.g. "Post A is clearly right") into the
   comment box at the bottom of the thread.
2. Click the **ink-blue** button under the box, labeled "Agree with the first post" (not
   a single generic "Post" button — the debate composer replaces it with three buttons).
3. Type a second comment (e.g. "No, post B nailed it") and click the **terracotta**
   button, labeled "Agree with the second post".

**Expected UI result**
- The first comment appears as a card with a 4px **ink-blue** top border, positioned in
  the **left** column (under/aligned with post A's card).
- The second comment appears as a card with a 4px **terracotta** top border, positioned
  in the **right** column (under/aligned with post B's card).
- The comment box's placeholder reads "Share your take on this debate…", not the
  generic "Add a comment…" placeholder a post's own comment box uses.

**Backend verification**
```
curl -s http://localhost:4000/api/connections/<connection id>/comments | python3 -m json.tool
```
**Expected result:** the two new comments have `"side": "post_a"` and `"side":
"post_b"` respectively, matching which button was clicked.

**Pass criteria:** the side chosen at posting time both colors the comment and places
it in the matching column — the UI and the stored `side` always agree.

---

### Test 5 — A neutral comment spans both columns, centered; omitting `side` on the API defaults to neutral

**Setup:** continue from Test 4.

**Steps (Underlined UI)**
1. Type a third comment (e.g. "Both have a point, honestly") and click the **gray**
   middle button, labeled "Neutral".

**Expected UI result**
- The new comment appears as a full-width card (spanning both columns, horizontally
  centered on the page) with a 4px gray top border — not aligned to either side.

**Backend verification**
```
curl -s -X POST http://localhost:4000/api/connections/<connection id>/comments \
  -H "Authorization: Bearer <your access token>" \
  -H "Content-Type: application/json" \
  -d '{"comment": {"body": "Posted with no side at all"}}' | python3 -m json.tool
```
**Expected result:** `201`, and the created comment's `"side"` is `"neutral"` even
though the request body never mentioned `side` — the column's "gray" visual default
and the API's field default agree.

**Pass criteria:** a comment that takes neither side is visually and structurally
distinct from both — centered, full-width, gray — and `neutral` is always a safe
default, never a validation error.

---

### Test 6 — Replying creates a flat, side-colored comment with a clickable reference, not a nested reply

**Setup:** continue from Test 5, with at least the ink-blue comment from Test 4 visible
("Post A is clearly right").

**Steps (Underlined UI)**
1. Click "Reply" under the ink-blue comment from Test 4.
2. Observe the page smoothly scroll down to the comment box, which now shows a dismissible
   "Replying to <name>" chip above it.
3. Type a reply (e.g. "Actually, post B's point about deliberation is fair") and click
   the **terracotta** button — deliberately the *opposite* side from the comment being
   replied to.
4. Locate the new reply and click the small reference chip on it (reading something like
   `↪ <name>: "Post A is clearly right."`).

**Expected UI result**
- Step 1/2: clicking "Reply" scrolls to the comment box and attaches a visible reply
  target — it does not open a separate inline reply box under the original comment (that
  was the old, pre-redesign behavior).
- Step 3: the new reply appears as its own card with a terracotta top border, in the
  **right** column — it is *not* indented/nested under the original ink-blue comment,
  even though it's a reply to it. Its side (terracotta) is independent of the side of
  the comment it replies to (ink-blue).
- The reply card shows the reference chip quoting the original comment's author and a
  snippet of its text.
- Step 4: clicking the reference chip smoothly scrolls the page back up to the original
  ink-blue comment's card.
- The "Replying to <name>" chip in the comment box has a ✕ button that clears the reply
  target without posting anything, returning the box to a normal (non-reply) state.
- "Reply" only appears on top-level comments, not on a comment that is itself a reply —
  same one-level-deep limit as a normal post's comment thread.

**Backend verification**
```
curl -s http://localhost:4000/api/connections/<connection id>/comments | python3 -m json.tool
```
**Expected result:** the reply appears nested under its parent in the JSON (`replies:
[...]`, same shape as before), but its own `"side"` is `"post_b"`, independent of its
parent's `"side": "post_a"` — nesting in the API response is just how the parent/child
relationship is represented; it does not determine the reply's visual column.

**Pass criteria:** a reply can take any side regardless of the comment it replies to,
renders flat (not indented) in the matching column, and the reference chip provides a
working round-trip back to the comment being replied to.

---

### Test 7 — Editing a debate comment behaves the same as before

**Setup:** continue from Test 6, as the author of one of the posted debate comments.

**Steps (Underlined UI)**
1. Click "Edit" under your own debate comment, change the body, and save.

**Expected UI result**
- The edit saves and an "(edited)" marker appears next to the date, same as a post's
  own comment thread.
- The comment's side/column/border color are unchanged by the edit — only the body
  text changes.

**Pass criteria:** editing is the one part of the debate comment UI that is unchanged
from a normal comment thread — author-only, body-only, same "(edited)" marker.

---

### Test 8 — On a narrow screen, every debate comment becomes full width regardless of side

**Setup:** continue from Test 7. Resize the browser window (or use devtools' device
toolbar) to a narrow width, e.g. 375px.

**Expected UI result**
- The two post cards stack vertically (existing behavior, unchanged by this redesign).
- Every comment card — ink-blue, terracotta, and neutral alike — becomes full width in
  a single column, in posting order. None of them render in a second, partially
  off-screen column.
- The three side-selection buttons under the comment box still fit on screen without
  visibly breaking the layout (wrapping to a second line is fine; horizontal overflow
  is not).

**Pass criteria:** the two-column desktop layout collapses cleanly to one column on
small screens, the same breakpoint (720px) the post cards already use — no side's
comments are left overflowing the viewport.

---

### Test 9 — Each debate post's existing Like button works independently of the other

**Setup:** continue from Test 8, back at a desktop-width window.

**Steps (Underlined UI)**
1. Note post A's and post B's current heart/like counts.
2. Click post A's heart icon only.

**Expected UI result**
- Post A's like count increments by one and its heart fills in; post B's count and
  heart are unaffected.

**Backend verification**
```
curl -s http://localhost:4000/api/connections/<connection id> | python3 -m json.tool
```
**Expected result:** `data.post_a.like_count` increased by one; `data.post_b.like_count`
unchanged.

**Pass criteria:** this confirms the debate page's "I agree"-style indicator per post is
the **existing** post Like feature, reused unmodified — not a new per-debate "agree"
concept — and that liking one side never affects the other's count.

---

## Negative cases

### Test 10 — Only `contradicts` connections resolve to a debate

**Setup:** continue from Test 1. Connect post A to a third post (post C) with a
relationship type other than "Contradicts" (e.g. "Similar idea"), and note that
connection's id from the API:
```
curl -s http://localhost:4000/api/posts/<post A id>/connections | python3 -m json.tool
```

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/connections/<similar_idea connection id>
```

**Expected result:** `404`.

**Pass criteria:** the debate view is specific to contradictions — a `similar_idea` (or
any other) connection doesn't resolve to a debate page, even though the connection
itself exists.

---

### Test 11 — An unknown connection id degrades gracefully, not a crash

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/connections/00000000-0000-0000-0000-000000000000
```

**Expected result:** `404`.

**Pass criteria:** an unknown connection id degrades gracefully, matching the existing
`/api/posts/:id`-style not-found behavior elsewhere in the app.

---

### Test 12 — Posting to a debate thread requires authentication

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/connections/<connection id>/comments \
  -H "Content-Type: application/json" \
  -d '{"comment": {"body": "Anonymous comment", "side": "post_a"}}'
```

**Expected result:** `401`.

**Pass criteria:** reading a debate and its thread is public (`maybe_authenticated`,
same as a post's own connections/comments), but posting to the thread still requires a
logged-in user — a `side` in the body doesn't bypass that.

---

### Test 13 — Only a comment's own author can edit it

**Setup:** continue from Test 1, with the **second** user from "Before you start" also
logged in at some point.

**Steps (UI or API)**
1. As the first user, post a comment on the debate thread.
2. As the second user, attempt to edit that comment:
   ```
   curl -s -o /dev/null -w "%{http_code}\n" -X PUT \
     http://localhost:4000/api/connections/<connection id>/comments/<comment id> \
     -H "Authorization: Bearer <second user's token>" \
     -H "Content-Type: application/json" \
     -d '{"comment": {"body": "Hijacked"}}'
   ```

**Expected result:** `403`.

**Pass criteria:** the debate thread's comments are author-locked for editing, same as
a post's own comments.

---

### Test 14 — An invalid `side` value is rejected

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/connections/<connection id>/comments \
  -H "Authorization: Bearer <your access token>" \
  -H "Content-Type: application/json" \
  -d '{"comment": {"body": "Hi", "side": "post_c"}}'
```

**Expected result:** `422`.

**Pass criteria:** `side` is restricted to exactly `post_a`, `post_b`, or `neutral` —
anything else is rejected, the same way an invalid `relationship_type` or comment
`type` is rejected elsewhere in the app.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | View a post with a `contradicts` connection | "Open as debate →" link appears, leads to `/debates/:id` |
| 2 | Open a debate page | Two bordered cards (ink-blue / terracotta) side by side, dashed divider, "Contradicts" badge, each with its own Like/comment-count icons |
| 3 | Post a comment on the debate thread vs. on either post | Threads stay fully independent; only debate comments carry `side` |
| 4 | Post an ink-blue / terracotta comment | Colored border + placed in the matching column; `side` in the API matches the button clicked |
| 5 | Post a neutral comment / omit `side` on the API | Full-width, centered, gray border; API defaults `side` to `"neutral"` |
| 6 | Reply to a comment with a different side | Flat (not nested) comment in the new side's column, with a reference chip that scrolls back to the original |
| 7 | Edit a debate comment | Same author-only edit + "(edited)" marker as before; side/column unchanged |
| 8 | View the debate thread on a narrow screen | All comments become single-column, full width, regardless of side |
| 9 | Like post A only | Post A's like count increments; post B's is unaffected (existing Like feature, reused) |
| 10 | Query a non-`contradicts` connection's id as a debate | `404` from the API |
| 11 | Query an unknown connection id | `404` from the API |
| 12 | Post a debate comment unauthenticated | `401` from the API |
| 13 | Edit someone else's debate comment | `403` from the API |
| 14 | Post a debate comment with an invalid `side` | `422` from the API |

If every row holds, Step 16 gives any two posts a dedicated place to be argued out
side by side, each comment visibly declaring which side (if any) it takes — and since
this step has no Community Health pairing, none of that behavior changes whether CH is
running, disabled, or absent.

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
(HealthyCommunity isn't touched by this step, so there's nothing to reset there). That
leaves Underlined's database empty — schema and containers untouched, zero rows — so
the next step's tests can start from the same clean slate this file assumed at the top.
