# Manual Test Plan — Step 15: Personal Idea Graph View

Scope: [roadmap.md](../base_content/roadmap.md) Step 15 — a visual graph page per user,
built from their own posts and keywords (nodes) and the connections between those posts
(edges). Like [Step 14](step_14_tests.md), there is **no Community Health pairing** for
this step; every test below is scoped entirely to Underlined's own UI
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
- You need at least one enabled user, one book, and a few posts with keywords. Sign up
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
  Then log in at `/login`, create a book at `/books/new`, and write at least three
  posts about it at `/posts/new`, giving each one or two keywords (e.g. post A:
  "attention", "nature-writing"; post B: "attention"; post C: no keywords). A second,
  **different** enabled user is also useful (for the "graphs are personal" negative
  test) — sign up a second account the same way.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — "My graph" is reachable from the top bar once logged in

**Steps (Underlined UI)**
1. While logged out, look at the top bar. "My graph" doesn't appear.
2. Log in, then look again.

**Expected UI result**
- "My graph" appears in the top bar only when logged in, and leads to `/graph`.

**Pass criteria:** the graph is a personal, signed-in-only view — not a public page.

---

### Test 2 — Posts and keywords render as nodes, connected by keyword edges

**Setup:** logged in, with post A ("attention", "nature-writing") and post B
("attention") from "Before you start" already written.

**Steps (Underlined UI)**
1. Click "My graph" (or go to `/graph`).

**Expected UI result**
- The page goes full-bleed below the top bar (no narrow reading column), cream
  background.
- Two small yellow dots (post A, post B) and two larger ink-blue circles labeled
  "attention" and "nature-writing" appear, connected by thin gray lines: both yellow
  dots connect to "attention"; only post A's dot connects to "nature-writing".
- A floating white pill-shaped toolbar sits top-right with a "+"/"−" zoom pair and a
  "All keywords" dropdown.
- Dragging a node moves it and its attached edges; the rest of the layout settles
  around it.

**Backend verification**
```
curl -s http://localhost:4000/api/users/<your user id>/graph | python3 -m json.tool
```
**Expected result:** `data.nodes` has one `"type": "post"` entry per post (`post`
populated) and one `"type": "keyword"` entry per distinct keyword across those posts
(`keyword` populated); `data.edges` has one `"type": "keyword"` entry per
post-keyword pairing, `source_id` the post's id, `target_id` the keyword's id.

**Pass criteria:** every post you've written and every keyword you've tagged shows up
as a node, correctly wired to each other.

---

### Test 3 — Hovering a node shows its tooltip

**Setup:** continue from Test 2.

**Steps (Underlined UI)**
1. Hover the mouse over a yellow post dot.
2. Hover over an ink-blue keyword circle.

**Expected UI result**
- Hovering a post dot raises a small white, bordered, rounded-corner tooltip showing
  the book's title (serif) and the start of that post's passage (yellow-underlined).
- Hovering a keyword circle raises a tooltip showing the keyword's name and how many
  posts in the graph are tagged with it (e.g. "2 posts tagged").
- The hovered node/edge also gets a visual highlight (border/line darkens toward
  ink-blue); moving the mouse away clears both the highlight and the tooltip.

**Pass criteria:** hovering any node surfaces enough context to identify it without
leaving the graph.

---

### Test 4 — A connection between two of your own posts renders as an edge

**Setup:** continue from Test 2. Connect post A and post B: open post A at
`/posts/<post A id>`, use its connection UI to link it to post B (any relationship
type, e.g. "expands_on").

**Steps (Underlined UI)**
1. Go back to `/graph` (reload if you were already there).

**Expected UI result**
- A new gray edge now runs directly between post A's and post B's dots, in addition
  to the keyword edges from Test 2.

**Backend verification**
```
curl -s http://localhost:4000/api/users/<your user id>/graph | python3 -m json.tool
```
**Expected result:** `data.edges` has one entry whose `type` is the relationship type
you picked (not `"keyword"`), `source_id`/`target_id` matching post A's and post B's
ids.

**Pass criteria:** a connection you've drawn between two of your own posts shows up as
its own edge, distinct from the automatic keyword edges.

---

### Test 5 — Filtering by keyword dims everything else

**Setup:** continue from Test 4 (post A has "attention" + "nature-writing", post B has
"attention" only).

**Steps (Underlined UI)**
1. On `/graph`, open the toolbar's keyword dropdown and pick "nature-writing".

**Expected UI result**
- Post A's dot and the "nature-writing" circle stay fully visible; post B's dot, the
  "attention" circle, and every edge not touching post A or "nature-writing" fade
  (dim) noticeably.
- Picking "All keywords" again restores everything to full opacity.

**Pass criteria:** the filter is a visual aid for tracing one keyword's reach through
the graph, not a destructive re-fetch — switching back loses nothing.

---

### Test 6 — A post with no keywords still appears as an isolated node

**Setup:** continue from Test 2, using post C (no keywords) from "Before you start".

**Steps (Underlined UI)**
1. On `/graph`, locate post C's dot.

**Expected UI result**
- Post C renders as a yellow dot with no edges touching it (it may drift to its own
  corner of the canvas as the layout settles, since nothing pulls it toward another
  node).

**Pass criteria:** a post needs no keywords or connections to show up — the graph
reflects everything you've written, not just the connected parts.

---

## Negative cases

### Test 7 — Your graph only shows your own posts, never another user's

**Setup:** continue from Test 2. Log in as the **second** user and have them write a
post of their own.

**Steps (Underlined UI / API)**
1. As the second user, go to `/graph`.
2. Confirm directly against the API:
   ```
   curl -s http://localhost:4000/api/users/<second user id>/graph | python3 -m json.tool
   ```

**Expected result:** only the second user's own post (and its keywords, if any) shows
up — none of the first user's nodes/edges appear anywhere in the response.

**Pass criteria:** the graph is strictly personal; it never leaks another user's posts
or connections, even though the endpoint is `maybe_authenticated`-readable by id.

---

### Test 8 — A user with no posts gets an empty-state message, not a crash

**Setup:** a freshly registered, enabled third user who hasn't written anything.

**Steps (Underlined UI / API)**
1. Log in as them and go to `/graph`.
2. Separately, check the API directly:
   ```
   curl -s http://localhost:4000/api/users/<third user id>/graph | python3 -m json.tool
   ```

**Expected result:** the UI shows an empty-state message (e.g. "Write a post to start
your idea graph.") instead of a blank canvas; the API returns
`{"data": {"nodes": [], "edges": []}}`.

**Pass criteria:** no posts degrades gracefully on both the API and the UI.

---

### Test 9 — An unknown user id degrades gracefully, not a crash

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/users/00000000-0000-0000-0000-000000000000/graph
```

**Expected result:** `404`.

**Pass criteria:** an unknown user id degrades gracefully, matching the existing
`/api/users/:id/interests` and `/api/users/:id/community_health` behavior.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Look at the top bar logged out vs. in | "My graph" only visible when logged in |
| 2 | Open `/graph` with posts + keywords | Yellow post dots, ink-blue keyword circles, keyword edges, full-bleed canvas |
| 3 | Hover a post node, then a keyword node | Tooltip with book/passage, or keyword name + tagged-post count |
| 4 | Connect two of your own posts, revisit `/graph` | A direct edge appears between them, typed by relationship |
| 5 | Filter by one keyword | Unrelated nodes/edges dim; "All keywords" restores them |
| 6 | A post with no keywords | Still renders, as an isolated dot |
| 7 | A second user's graph | Shows only their own posts — never the first user's |
| 8 | A user with no posts | Empty-state message in the UI; `{"nodes": [], "edges": []}` from the API |
| 9 | Query an unknown user id's graph | `404` from the API |

If every row holds, Step 15 gives every user a visual map of their own reading and
connections — and since this step has no Community Health pairing, none of that
behavior changes whether CH is running, disabled, or absent.

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
(HealthyCommunity isn't touched by this step, so there's nothing to reset there). That
leaves Underlined's database empty — schema and containers untouched, zero rows — so
the next step's tests can start from the same clean slate this file assumed at the
top.
