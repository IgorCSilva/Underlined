# Manual Test Plan — Step 18: Reading Schedule & Chapter-Scoped Discussion

Scope: [roadmap.md](../base_content/roadmap.md) Step 18 — a club tracks a "current
chapter" (the club itself chooses the word — "Chapter", "Letter", "Date", or anything
else), and its discussion is grouped by that schedule instead of one giant thread. Like
[Step 17's doc](step_17_tests.md), there is no Community Health pairing for this step —
every test below interacts only with Underlined's own UI (`http://localhost:3000`) and
API (`http://localhost:4000`), and this file builds directly on Step 17's club, so
start from a club that already exists (Tests 1-11 of that file) rather than an empty
database.

## Before you start

- **Start from an empty database and re-run [Step 17's "Before you start"](step_17_tests.md#before-you-start)**
  up through Test 2 (Creator has created "Free Will Thinkers" on "Book One" and is its
  only member; Joiner is registered and enabled but hasn't joined yet).
- Underlined's stack is up: `docker compose up -d`.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — A club with no schedule yet shows a setup form, not an empty strip

**Steps (Underlined UI)**
1. Log in as Creator and open "Free Will Thinkers"'s page at `/clubs/:id`.

**Expected UI result**
- Below the club header (above the Discussion/Members/Schedule tabs), instead of a
  pill strip there's a small form with two fields: a chapter label (placeholder
  mentioning "Chapter") and a second field asking what to call it ("Chapter", "Letter",
  "Date"...), plus a "Save" button.

**Pass criteria:** a club with zero chapters prompts its creator to set up a schedule
instead of rendering an empty strip; a non-creator sees neither the form nor any
strip at all (just [Test 1's](step_17_tests.md#test-1--create-a-club-appears-on-a-books-page)
baseline page).

---

### Test 2 — Creating the first chapter also sets the schedule's unit word

**Setup:** continue from Test 1, logged in as Creator.

**Steps (Underlined UI)**
1. Type "Chapter 1 - The first day" in the label field and "Chapter" in the unit field.
2. Click "Save".

**Expected UI result**
- A single pill reading "Chapter 1 - The first day" appears, outlined gray (not yet
  marked as current), plus a dashed "+ Add Chapter" trigger next to it.

**Backend verification**
```
curl -s http://localhost:4000/api/clubs/<the club's id> | python3 -m json.tool
```
**Expected result:** `data.chapter_unit_label` is `"Chapter"` and
`data.current_chapter_label` is `null` (nothing has been marked current yet).

**Pass criteria:** the unit word chosen alongside the first chapter is stored on the
club itself, not just that one chapter.

---

### Test 3 — Adding a second chapter appends it, in order

**Setup:** continue from Test 2.

**Steps (Underlined UI)**
1. Click "+ Add Chapter".
2. Type "Chapter 2 - Meeting my friends" and click "Save" (the unit-word field no
   longer appears — it's already set).

**Expected UI result**
- The strip now shows two pills in order, both outlined gray.

**Backend verification**
```
curl -s http://localhost:4000/api/clubs/<the club's id>/chapters | python3 -m json.tool
```
**Expected result:** `data` is `[{"label":"Chapter 1 - The first day","position":1,...}, {"label":"Chapter 2 - Meeting my friends","position":2,...}]`.

**Pass criteria:** chapters are always appended in schedule order; position is assigned
by the server, never the client.

---

### Test 4 — The creator marks a chapter current, and the strip reflects progress

**Setup:** continue from Test 3.

**Steps (Underlined UI)**
1. Click the "Chapter 1 - The first day" pill.

**Expected UI result**
- That pill fills solid ink-blue; "Chapter 2" stays outlined gray and dimmed (upcoming).
  Below the header, a line reads "Currently reading: Chapter 1 - The first day".

**Backend verification**
```
curl -s http://localhost:4000/api/clubs/<the club's id> | python3 -m json.tool
```
**Expected result:** `data.current_chapter_label` is `"Chapter 1 - The first day"`.

**Pass criteria:** marking a chapter current updates both the strip's styling and the
club's own `current_chapter_label` immediately, without a page reload.

---

### Test 5 — Advancing again marks the first chapter completed

**Setup:** continue from Test 4.

**Steps (Underlined UI)**
1. Click the "Chapter 2 - Meeting my friends" pill.

**Expected UI result**
- "Chapter 1" now outlines moss green (completed); "Chapter 2" fills solid ink-blue
  (current). There is no "upcoming" chapter left.

**Pass criteria:** a chapter's pill color is derived purely from its position relative
to whichever chapter is current — completed (moss green), current (solid ink-blue), or
upcoming (dimmed gray) — recomputed every time the current chapter changes.

---

### Test 6 — A club member can post to the discussion, tagged to a chapter

**Setup:** continue from Test 5. As Joiner, join the club first (repeat
[Step 17's Test 4](step_17_tests.md#test-4--a-second-user-can-join-and-the-member-list-reflects-join-order)).

**Steps (Underlined UI)**
1. As Creator, on the Discussion tab, type "What did everyone think of the opening?"
   in the composer, choose "Chapter 1 - The first day" from the dropdown, and click
   "Post".

**Expected UI result**
- The post appears immediately under a "Chapter 1 - The first day" heading (serif,
  yellow underline) — a new heading, separate from any "General discussion" posts.

**Backend verification**
```
curl -s http://localhost:4000/api/clubs/<the club's id>/posts | python3 -m json.tool
```
**Expected result:** `data` contains one entry with `"body"` matching and
`"chapter":{"label":"Chapter 1 - The first day",...}`.

**Pass criteria:** a post tagged to a chapter is grouped under that chapter's own
heading, not mixed into general discussion.

---

### Test 7 — A post with no chapter chosen lands in "General discussion"

**Setup:** continue from Test 6.

**Steps (Underlined UI)**
1. Type "Welcome, everyone!" in the composer, leave the dropdown on "General
   discussion", and click "Post".

**Expected UI result**
- The post appears under a "General discussion" heading, which sorts before every
  chapter heading.

**Pass criteria:** untagged posts get their own heading and always sort first,
regardless of which chapter is current.

---

### Test 8 — Commenting on a club post works exactly like commenting on a regular post

**Setup:** continue from Test 7, logged in as Joiner.

**Steps (Underlined UI)**
1. Click "0 comments" under Creator's "What did everyone think..." post to expand its
   thread.
2. Type "Loved it!" and submit.

**Expected UI result**
- The comment appears immediately under that post; the toggle now reads "1 comments".

**Backend verification**
```
curl -s http://localhost:4000/api/club_posts/<that post's id>/comments | python3 -m json.tool
```
**Expected result:** `data` contains one comment with `"body":"Loved it!"` and no
`"side"` field (that field only exists on a connection's debate comments).

**Pass criteria:** a club post's comment thread behaves identically to a regular post's
— same reply nesting, same edit-your-own-comment rule — reusing the exact same
`/comments` shape.

---

## Negative cases

### Test 9 — A non-creator member cannot add a chapter or change the current one

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/clubs/<the club's id>/chapters \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Joiner's access token>" \
  -d '{"chapter":{"label":"Chapter 3"}}'
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/clubs/<the club's id>/chapters/<a chapter id>/current \
  -H "Authorization: Bearer <Joiner's access token>"
```

**Expected result:** `403` for both.

**Pass criteria:** managing the reading schedule (adding chapters, advancing progress)
is restricted to the club's creator — any other member, even a joined one, is
forbidden.

---

### Test 10 — A non-member cannot post to the discussion or comment on a club post

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/clubs/<the club's id>/posts \
  -H "Content-Type: application/json" -H "Authorization: Bearer <a non-member's access token>" \
  -d '{"post":{"body":"Can I post?"}}'
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/club_posts/<a club post's id>/comments \
  -H "Content-Type: application/json" -H "Authorization: Bearer <that same non-member's access token>" \
  -d '{"comment":{"body":"Hey"}}'
```

**Expected result:** `403` for both.

**Pass criteria:** the discussion, unlike the club's own page and member list, is
closed to non-members — reading it stays open to everyone, but only members can add
to it.

---

### Test 11 — A chapter id from a different club is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/clubs/<club A's id>/posts \
  -H "Content-Type: application/json" -H "Authorization: Bearer <a member of club A's access token>" \
  -d '{"post":{"body":"Hello","chapter_id":"<a chapter id that belongs to club B>"}}'
```

**Expected result:** `422`, with `"code": "invalid_chapter"` in the response body.
Repeating the same request against
`PUT /api/clubs/<club A's id>/chapters/<club B's chapter id>/current` returns the same
`422 invalid_chapter`.

**Pass criteria:** a post or a "current chapter" selection can never reference another
club's chapter, even if both clubs are real and the chapter id is well-formed.

---

### Test 12 — Unauthenticated requests can't manage the schedule, post, or comment

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/clubs/<the club's id>/chapters \
  -H "Content-Type: application/json" -d '{"chapter":{"label":"Chapter 3"}}'
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/clubs/<the club's id>/posts \
  -H "Content-Type: application/json" -d '{"post":{"body":"Hello"}}'
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/club_posts/<a club post's id>/comments \
  -H "Content-Type: application/json" -d '{"comment":{"body":"Hey"}}'
```

**Expected result:** `401` for all three.

**Pass criteria:** adding a chapter, posting, and commenting all require
authentication; reading the schedule, the discussion, and a post's comments (Tests
3, 6, and 8's `GET` calls) do not.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Open a club with no schedule yet | A setup form (label + unit word), not an empty strip |
| 2 | Save the first chapter with a unit word | A single pill; club's `chapter_unit_label` is stored |
| 3 | Add a second chapter | Appended at the next position, in order |
| 4 | Mark a chapter current | That pill fills solid; `current_chapter_label` updates |
| 5 | Advance to the next chapter | The previous chapter now shows completed (moss green) |
| 6 | Post tagged to a chapter | Grouped under that chapter's own heading |
| 7 | Post with no chapter chosen | Grouped under "General discussion", sorting first |
| 8 | Comment on a club post | Behaves exactly like a regular post's comment thread |
| 9 | A member (not the creator) tries to manage the schedule | `403` |
| 10 | A non-member tries to post or comment | `403` |
| 11 | Reference another club's chapter | `422 invalid_chapter` |
| 12 | Manage/post/comment while unauthenticated | `401` |

If every row holds, Step 18 lets a club organize its entire discussion around its own
reading pace — in whatever words its creator chooses to describe that pace — without
ever forcing every book club into the word "chapter."

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
(HealthyCommunity isn't touched by this step, so there's nothing to reset there). That
leaves Underlined's database empty — schema and containers untouched, zero rows — so
the next step's tests can start from the same clean slate this file assumed at the top.
