# Manual Test Plan — Step 13: Explicit Post Connections

Scope: [roadmap.md](../base_content/roadmap.md) Step 13 — a user can link two posts
with a typed relationship (similar idea, opposite idea, expands on, contradicts,
provides an example of, personal connection), and the connection shows up on both
posts it links. Like [Step 8](step_8_tests.md), [Step 9](step_9_tests.md),
[Step 10](step_10_tests.md), and [Step 11](step_11_tests.md), there is **no Community
Health pairing** for this step; every test below is scoped entirely to Underlined's
own UI (`http://localhost:3000`) and API (`http://localhost:4000`).

## Before you start

- **Start from an empty database.** This file assumes Underlined's database is empty
  before Test 1. If you're re-running this file, empty it first with the Underlined
  snippet from
  [Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
  (skip the HealthyCommunity one — this step doesn't touch it), the same snippet this
  file's [Cleanup](#cleanup) section ends with.
- Underlined's stack is up: `docker compose up -d` (HealthyCommunity is irrelevant
  here — don't bother starting it).
- You need at least one enabled user, one book, and two posts to connect. Sign up at
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
  Then log in at `/login`, create a book at `/books/new`, and write at least two
  posts about it at `/posts/new` — call them "Post One" and "Post Two" by whatever
  you put in their "What I think about it" field, so you can tell them apart below.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — "+ Connect to another post" appears on a post's action row

**Steps (Underlined UI)**
1. Open "Post One"'s detail page at `/posts/:id`.

**Expected UI result**
- Below the passage/keywords, the action row (like, comment count, report) now also
  shows a dashed ink-blue outline button reading "+ Connect to another post" —
  visually distinct (dashed, not solid) from the like/save actions.

**Pass criteria:** the button renders in the action row with a dashed outline, not a
solid fill.

---

### Test 2 — Connecting two posts opens a search + relationship picker, then links them

**Setup:** continue from Test 1, on "Post One"'s detail page.

**Steps (Underlined UI)**
1. Click "+ Connect to another post". A modal opens with a search field, a list of
   candidate posts, and a relationship dropdown.
2. Type part of "Post Two"'s book title (or its "what I think" text) into the search
   field; confirm the list narrows to matching posts.
3. Click "Post Two" in the list to select it.
4. Choose "Expands on" from the relationship dropdown.
5. Click "Connect".

**Expected UI result**
- The modal closes and a small ink-blue pill labeled "Expands on" (with a → icon)
  appears, linking to "Post Two".

**Backend verification**
```
curl -s http://localhost:4000/api/posts/<Post One's id>/connections | python3 -m json.tool
```
**Expected result:** `data` contains one entry with `"relationship_type": "expands_on"`
and `connected_post.id` equal to "Post Two"'s id.

**Pass criteria:** the connection is created and immediately visible as a pill on
"Post One" without a page reload.

---

### Test 3 — The connection shows on both posts, each pointing at the other

**Setup:** continue from Test 2 (Post One → Post Two, "expands on").

**Steps (Underlined UI)**
1. Open "Post Two"'s detail page at `/posts/:id`.

**Expected UI result**
- The same "Expands on" pill appears here too, but it links to "Post One" — the
  connection is symmetric in visibility even though it was only created once, from
  "Post One"'s side.

**Backend verification**
```
curl -s http://localhost:4000/api/posts/<Post Two's id>/connections | python3 -m json.tool
```
**Expected result:** `data` contains one entry with `"relationship_type": "expands_on"`
and `connected_post.id` equal to "Post One"'s id.

**Pass criteria:** both posts show the connection; each one's pill links to the
*other* post, never to itself.

---

### Test 4 — Pill color reflects the relationship type

**Setup:** on "Post One", create two more connections to other posts (write a third
and fourth post first if needed): one tagged "Similar idea" and one tagged
"Contradicts".

**Steps (Underlined UI)**
1. Open "Post One"'s detail page and look at all three pills.

**Expected UI result**
- "Similar idea" renders as a moss-green pill, "Contradicts" as a terracotta pill,
  and "Expands on" (from Test 2) as an ink-blue pill — each with its own icon (↔, ⇌,
  → respectively).

**Pass criteria:** each relationship type has a visibly distinct pill color matching
the roadmap's color coding, so the type is readable without reading the label.

---

### Test 5 — Repeating the same connection doesn't create a duplicate pill

**Setup:** continue from Test 2 (Post One → Post Two, "expands on").

**Steps (Underlined UI / API)**
1. Repeat Test 2's steps exactly (same two posts, same "Expands on" relationship).
2. Verify directly against the API:
   ```
   curl -s http://localhost:4000/api/posts/<Post One's id>/connections | python3 -m json.tool
   ```

**Expected result:** `data` still contains exactly one "expands_on" entry between
these two posts — the same `id` as before, not a second row.

**Pass criteria:** re-creating an identical connection is a no-op, not a duplicate.

---

## Negative cases

### Test 6 — Connecting a post to itself is rejected

**Steps (Underlined UI / API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/posts/<Post One's id>/connections \
  -H "Content-Type: application/json" -H "Authorization: Bearer <your access token>" \
  -d '{"connection":{"related_post_id":"<Post One's id>","relationship_type":"similar_idea"}}'
```

**Expected result:** `422`, with `"code": "cannot_connect_self"` in the response body.

**Pass criteria:** a post can never appear connected to itself, by API or UI (the
picker's own post is excluded from the candidate list in Test 2's modal).

---

### Test 7 — An unknown relationship type is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/posts/<Post One's id>/connections \
  -H "Content-Type: application/json" -H "Authorization: Bearer <your access token>" \
  -d '{"connection":{"related_post_id":"<Post Two's id>","relationship_type":"made_up"}}'
```

**Expected result:** `422` (changeset validation error on `relationship_type`).

**Pass criteria:** only the roadmap's six relationship types are ever accepted.

---

### Test 8 — An unauthenticated request can't create a connection

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/posts/<Post One's id>/connections \
  -H "Content-Type: application/json" \
  -d '{"connection":{"related_post_id":"<Post Two's id>","relationship_type":"similar_idea"}}'
```

**Expected result:** `401`.

**Pass criteria:** connecting posts requires authentication; reading connections
(Tests 2-5's `GET .../connections` calls) does not.

---

### Test 9 — An unknown post id degrades gracefully, not a crash

**Steps (Underlined UI / API)**
1. Go to `/posts/00000000-0000-0000-0000-000000000000`.
2. Separately, check the connections endpoint directly:
   ```
   curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/posts/00000000-0000-0000-0000-000000000000/connections
   ```

**Expected result:** the existing "Post not found." message renders in the UI (no
crash, no stray pills); the API call returns `404`.

**Pass criteria:** an unknown post id degrades gracefully on both the API and the UI,
for both creating and listing connections.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Open a post's detail page | Dashed "+ Connect to another post" button in the action row |
| 2 | Search, pick a post and a relationship, click Connect | A labeled pill appears immediately, linking to the chosen post |
| 3 | Open the connected post | The same pill appears there too, linking back to the original post |
| 4 | Create connections of different types | Each relationship type renders in its own color (moss green/terracotta/ink-blue/ochre) with its own icon |
| 5 | Repeat an identical connection | No duplicate — the same connection id is returned |
| 6 | Try to connect a post to itself | `422 cannot_connect_self` |
| 7 | Submit an unknown relationship type | `422` changeset error |
| 8 | Create a connection while unauthenticated | `401` |
| 9 | Visit/query an unknown post id | `404` from the API; "Post not found." in the UI |

If every row holds, Step 13 lets any reader explicitly link two posts across books
with a meaningful, typed relationship, visible identically from either side — and
since this step has no Community Health pairing, none of that behavior changes
whether CH is running, disabled, or absent.

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
(HealthyCommunity isn't touched by this step, so there's nothing to reset there). That
leaves Underlined's database empty — schema and containers untouched, zero rows — so
the next step's tests can start from the same clean slate this file assumed at the
top.
