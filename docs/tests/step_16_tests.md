# Manual Test Plan — Step 16: Contradiction / Debate View

Scope: [roadmap.md](../base_content/roadmap.md) Step 16 — a dedicated side-by-side view for
two posts connected as `contradicts`, with a discussion thread scoped to the disagreement
itself rather than to either post. Like [Step 14](step_14_tests.md) and
[Step 15](step_15_tests.md), there is **no Community Health pairing** for this step; every
test below is scoped entirely to Underlined's own UI (`http://localhost:3000`) and API
(`http://localhost:4000`).

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
  comments need auth" tests) — sign up a second account the same way.
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
- Each card shows its post's book, passage, and thinking, same as a normal post card.

**Backend verification**
```
curl -s http://localhost:4000/api/connections/<connection id> | python3 -m json.tool
```
**Expected result:** `data.relationship_type` is `"contradicts"`; `data.post_a` and
`data.post_b` are the two full posts (in either order), each shaped like a normal post
JSON payload (book, passage, thinking, keywords, etc.).

**Pass criteria:** both sides of the disagreement are visible together, visually
distinguished, without needing to click back and forth between two separate post pages.

---

### Test 3 — The debate thread is independent of either post's own comments

**Setup:** continue from Test 2.

**Steps (Underlined UI)**
1. On `/debates/<connection id>`, post a comment in the thread below the cards (e.g.
   "I think post A has it right").
2. Go to post A's own page (`/posts/<post A id>`) and post a separate comment there
   (e.g. "A regular comment on post A").
3. Go back to `/debates/<connection id>`.
4. Open post A's page again.

**Expected UI result**
- The debate-thread comment from step 1 appears only on the debate page — not on post
  A's or post B's own comment thread.
- Post A's own comment from step 2 appears only on post A's page — not on the debate
  thread.
- Both threads otherwise look and behave identically (reply, edit, same comment
  styling) — "the contrast is only in the header, not in how people talk."

**Backend verification**
```
curl -s http://localhost:4000/api/connections/<connection id>/comments | python3 -m json.tool
curl -s http://localhost:4000/api/posts/<post A id>/comments | python3 -m json.tool
```
**Expected result:** the first list contains only the debate comment; the second
contains only the post comment — no overlap.

**Pass criteria:** the discussion is genuinely "scoped to the disagreement itself," a
third thread distinct from either post's own.

---

### Test 4 — Replying and editing works the same as a normal comment thread

**Setup:** continue from Test 3, with at least one top-level debate comment posted.

**Steps (Underlined UI)**
1. Click "Reply" under the debate comment and post a reply.
2. As the comment's author, click "Edit", change the body, and save.

**Expected UI result**
- The reply appears nested under the top-level comment, same indentation/style as a
  post's comment thread.
- The edit saves and an "(edited)" marker appears, same as a post's comment thread.

**Pass criteria:** the debate thread supports the same one-level-deep replies and
author-only editing as Step 6's comments, with no visible difference in behavior.

---

## Negative cases

### Test 5 — Only `contradicts` connections resolve to a debate

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

### Test 6 — An unknown connection id degrades gracefully, not a crash

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/connections/00000000-0000-0000-0000-000000000000
```

**Expected result:** `404`.

**Pass criteria:** an unknown connection id degrades gracefully, matching the existing
`/api/posts/:id`-style not-found behavior elsewhere in the app.

---

### Test 7 — Posting to a debate thread requires authentication

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/connections/<connection id>/comments \
  -H "Content-Type: application/json" \
  -d '{"comment": {"body": "Anonymous comment"}}'
```

**Expected result:** `401`.

**Pass criteria:** reading a debate and its thread is public (`maybe_authenticated`,
same as a post's own connections/comments), but posting to the thread still requires a
logged-in user.

---

### Test 8 — Only a comment's own author can edit it

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

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | View a post with a `contradicts` connection | "Open as debate →" link appears, leads to `/debates/:id` |
| 2 | Open a debate page | Two bordered cards (ink-blue / terracotta) side by side, dashed divider, "Contradicts" badge |
| 3 | Post a comment on the debate thread vs. on either post | Threads stay fully independent |
| 4 | Reply to and edit a debate comment | Same reply/edit behavior as a post's own comments |
| 5 | Query a non-`contradicts` connection's id as a debate | `404` from the API |
| 6 | Query an unknown connection id | `404` from the API |
| 7 | Post a debate comment unauthenticated | `401` from the API |
| 8 | Edit someone else's debate comment | `403` from the API |

If every row holds, Step 16 gives any two posts a dedicated place to be argued out
side by side — and since this step has no Community Health pairing, none of that
behavior changes whether CH is running, disabled, or absent.

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
(HealthyCommunity isn't touched by this step, so there's nothing to reset there). That
leaves Underlined's database empty — schema and containers untouched, zero rows — so
the next step's tests can start from the same clean slate this file assumed at the top.
