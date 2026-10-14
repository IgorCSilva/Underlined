# Manual Test Plan — Step 14: Idea Chains

Scope: [roadmap.md](../base_content/roadmap.md) Step 14 — a user assembles an ordered
sequence of connected posts into a named "chain" and publishes it as a browsable unit.
Like [Step 13](step_13_tests.md), there is **no Community Health pairing** for this
step; every test below is scoped entirely to Underlined's own UI
(`http://localhost:3000`) and API (`http://localhost:4000`).

## Before you start

- **Start from an empty database.** This file assumes Underlined's database is empty
  before Test 1. If you're re-running this file, empty it first with the Underlined
  snippet from
  [Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
  (skip the HealthyCommunity one — this step doesn't touch it), the same snippet this
  file's [Cleanup](#cleanup) section ends with.
- Underlined's stack is up: `docker compose up -d` (HealthyCommunity is irrelevant
  here — don't bother starting it).
- You need at least one enabled user, one book, and three posts to chain together.
  Sign up at `/signup`, enable the account from the running `api` container — never
  with `psql`:
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
  posts about it at `/posts/new` — call them "Post One", "Post Two", and "Post Three"
  by whatever you put in their "What I think about it" field, so you can tell them
  apart below. A second, **different** enabled user (for the "someone else's chain"
  negative tests) is also useful — sign up a second account the same way.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — "Chains" is reachable from the top bar, and "+ New chain" shows up logged in

**Steps (Underlined UI)**
1. While logged out, look at the top bar.
2. Log in, then look again.

**Expected UI result**
- "Chains" appears in the top bar at all times (logged in or out) and leads to
  `/chains`.
- Once logged in, `/chains` also shows a "+ New chain" button; logged out, it doesn't.

**Pass criteria:** browsing chains never requires an account; starting one does.

---

### Test 2 — Creating a chain starts empty, then posts can be added to it in order

**Setup:** logged in, on `/chains`.

**Steps (Underlined UI)**
1. Click "+ New chain". Enter a title (e.g. "Four books that changed how I think
   about decision making") and submit.
2. You land on the new chain's page (`/chains/:id`). It shows the title in large
   serif with a yellow underline, and "This chain doesn't have any posts yet."
3. Click "+ Add a post". A modal opens with a search field and a list of candidate
   posts.
4. Type part of "Post One"'s book title into the search field; confirm the list
   narrows. Click it, then click "Add".
5. Repeat for "Post Two", then for "Post Three".

**Expected UI result**
- After each add, the modal closes and the timeline grows by one step: a numbered,
  circular book-cover node (ink-blue outline) on a vertical ink-blue connector line,
  with a card to its right showing the book title and the passage snippet
  (serif, yellow-underlined). Steps appear in the order you added them: One, Two,
  Three.

**Backend verification**
```
curl -s http://localhost:4000/api/chains/<chain id> | python3 -m json.tool
```
**Expected result:** `data.items` has three entries, `position` 0/1/2, in the order
added, each `post` matching the post you picked.

**Pass criteria:** a chain can be built up one post at a time, and the order it's
built in is the order it displays in.

---

### Test 3 — Dragging a step to a new spot reorders the whole chain, and it sticks

**Setup:** continue from Test 2 (chain = One, Two, Three).

**Steps (Underlined UI)**
1. On the chain's page, hover over the first step ("Post One"). A small gray
   six-dot grip appears to the left of its node.
2. Drag the first step and drop it on the third step's position.
3. Reload the page.

**Expected UI result**
- Immediately after dropping, the timeline re-renders as Two, Three, One — numbered
  1, 2, 3 in that new order.
- After reloading, the order is still Two, Three, One (not back to One, Two, Three).

**Backend verification**
```
curl -s http://localhost:4000/api/chains/<chain id> | python3 -m json.tool
```
**Expected result:** `data.items` position 0 is "Post Two", position 1 is "Post
Three", position 2 is "Post One".

**Pass criteria:** reordering is a real write, not a client-only illusion that a
reload would undo.

---

### Test 4 — The chain shows up on the browse page, with a cover stack and post count

**Setup:** continue from Test 3.

**Steps (Underlined UI)**
1. Go to `/chains`.

**Expected UI result**
- The chain appears as a card: its title, "by <your name> · 3 posts", and a small
  stack of up to five overlapping circular book covers.
- Clicking the card opens `/chains/:id` and shows the same timeline as Test 3 left
  it.

**Pass criteria:** a published chain is discoverable by anyone browsing `/chains`,
not just reachable by a direct link.

---

## Negative cases

### Test 5 — Only the chain's author can add to it or reorder it

**Setup:** continue from Test 3. Log in as the **second** user in a different
browser/session (or log out and back in as them).

**Steps (Underlined UI / API)**
1. Open the first user's chain at `/chains/:id` as the second user.
2. Confirm there's no "+ Add a post" button and no drag grips on hover.
3. Confirm directly against the API:
   ```
   curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/chains/<chain id>/items \
     -H "Content-Type: application/json" -H "Authorization: Bearer <second user's access token>" \
     -d '{"item":{"post_id":"<any post id>"}}'
   ```

**Expected result:** `403`, with `"code": "forbidden"` in the response body. The PUT
reorder endpoint rejects the second user's token the same way.

**Pass criteria:** a chain can only be built or reordered by the person who started
it; everyone else gets a read-only view.

---

### Test 6 — Starting a chain requires an account

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/chains \
  -H "Content-Type: application/json" \
  -d '{"chain":{"title":"nope"}}'
```

**Expected result:** `401`.

**Pass criteria:** creating a chain requires authentication; browsing chains
(Tests 2-4's `GET` calls) does not.

---

### Test 7 — A reorder must name every existing item exactly once

**Setup:** continue from Test 3 (chain has 3 items). You'll need the three items'
`id`s from `GET /api/chains/<chain id>`.

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/chains/<chain id>/items \
  -H "Content-Type: application/json" -H "Authorization: Bearer <your access token>" \
  -d '{"item_ids":["<only one of the three item ids>"]}'
```

**Expected result:** `422`, with `"code": "invalid_item_ids"` in the response body.
The chain's order is unchanged.

**Pass criteria:** a reorder can't drop, duplicate, or invent items — it can only
rearrange the exact set that's already there.

---

### Test 8 — An unknown chain id degrades gracefully, not a crash

**Steps (Underlined UI / API)**
1. Go to `/chains/00000000-0000-0000-0000-000000000000`.
2. Separately, check the API directly:
   ```
   curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/chains/00000000-0000-0000-0000-000000000000
   ```

**Expected result:** "Chain not found." renders in the UI (no crash); the API call
returns `404`.

**Pass criteria:** an unknown chain id degrades gracefully on both the API and the
UI.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Look at the top bar logged out vs. in | "Chains" always visible; "+ New chain" only when logged in |
| 2 | Create a chain, add three posts one at a time | Timeline grows in the order added, numbered nodes + cover + passage |
| 3 | Drag a step to a new spot, reload | New order shown immediately and after reload |
| 4 | Visit `/chains` | The chain appears with title, author, post count, cover stack; opening it matches |
| 5 | A second user opens someone else's chain | No add/reorder controls in the UI; `403` from the API |
| 6 | Create a chain while unauthenticated | `401` |
| 7 | Reorder with a partial/incomplete item list | `422 invalid_item_ids`, order unchanged |
| 8 | Visit/query an unknown chain id | `404` from the API; "Chain not found." in the UI |

If every row holds, Step 14 lets any reader assemble a named, ordered reading path
across books and publish it as something anyone can browse — and since this step has
no Community Health pairing, none of that behavior changes whether CH is running,
disabled, or absent.

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
(HealthyCommunity isn't touched by this step, so there's nothing to reset there). That
leaves Underlined's database empty — schema and containers untouched, zero rows — so
the next step's tests can start from the same clean slate this file assumed at the
top.
