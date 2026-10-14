# Manual Test Plan — Step 18.1: Schedule Tab

Scope: [roadmap.md](../base_content/roadmap.md) Step 18.1 — the club page's Schedule
tab, previously a "coming soon" placeholder, now shows the full reading schedule as a
vertical list (status + optional target date per chapter), and the club's creator can
edit a chapter's label/target date, reorder the schedule, and add a new chapter without
leaving the tab. Like [Step 18's doc](step_18_tests.md), there is no Community Health
pairing for this step — every test below interacts only with Underlined's own UI
(`http://localhost:3000`) and API (`http://localhost:4000`), and this file builds
directly on Step 18's club, so start from a club that already has a schedule (Tests
1-5 of that file) rather than an empty database.

## Before you start

- **Start from an empty database and re-run [Step 18's "Before you start" through Test 5](step_18_tests.md#before-you-start)**
  so "Free Will Thinkers" exists with two chapters ("Chapter 1 - The first day",
  completed, and "Chapter 2 - Meeting my friends", current) and Joiner has joined.
- Underlined's stack is up: `docker compose up -d`.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — The Schedule tab shows the chapter list, not a placeholder

**Steps (Underlined UI)**
1. Log in as Creator and open "Free Will Thinkers" at `/clubs/:id`.
2. Click the "Schedule" tab.

**Expected UI result**
- Two rows appear, one per chapter, each with a status dot, the chapter's label, and
  (since neither has a target date yet) no date text. "Chapter 1 - The first day" is
  styled completed (moss green dot/border); "Chapter 2 - Meeting my friends" is styled
  current (ink-blue dot/border). Each row has up/down arrows and an "Edit" link (visible
  because Creator owns this club); below the list there's an inline "Add Chapter" form.

**Pass criteria:** the tab renders every chapter as its own row with the same
completed/current/upcoming color language as the strip above the tabs, and shows
creator-only management controls, not the old "coming soon" text.

---

### Test 2 — The creator sets a target date on a chapter

**Setup:** continue from Test 1.

**Steps (Underlined UI)**
1. Click "Edit" on "Chapter 2 - Meeting my friends".
2. Leave the label as-is, pick a date in the date field, and click "Save".

**Expected UI result**
- The row leaves edit mode and now shows "Target: `<the date>`" under the label.

**Backend verification**
```
curl -s http://localhost:4000/api/clubs/<the club's id>/chapters | python3 -m json.tool
```
**Expected result:** the matching entry in `data` has `"target_date"` set to the date
you chose (`YYYY-MM-DD`); the other chapter's `"target_date"` is still `null`.

**Pass criteria:** editing a chapter updates its target date without touching its
position or any other chapter.

---

### Test 3 — The creator reorders the schedule

**Setup:** continue from Test 2.

**Steps (Underlined UI)**
1. Click the up arrow (↑) on "Chapter 2 - Meeting my friends".

**Expected UI result**
- The two rows swap places: "Chapter 2 - Meeting my friends" (still styled current) now
  appears first, "Chapter 1 - The first day" (still styled completed) now appears
  second. The chapter strip above the tabs reflects the same new order.

**Backend verification**
```
curl -s http://localhost:4000/api/clubs/<the club's id>/chapters | python3 -m json.tool
```
**Expected result:** `data` is ordered `[{"label":"Chapter 2 - Meeting my friends","position":1,...}, {"label":"Chapter 1 - The first day","position":2,...}]` — `current` is still `true` only for "Chapter 2", unaffected by the position swap.

**Pass criteria:** reordering swaps exactly the two neighboring chapters' positions and
leaves which chapter is "current" untouched.

---

### Test 4 — The creator adds a new chapter from the Schedule tab

**Setup:** continue from Test 3.

**Steps (Underlined UI)**
1. In the "Add Chapter" form at the bottom of the Schedule tab, type "Chapter 3 - The
   turning point", pick a target date, and submit.

**Expected UI result**
- A third row appears at the end of the list (styled upcoming — outlined gray, dimmed),
  showing the new label and target date.

**Backend verification**
```
curl -s http://localhost:4000/api/clubs/<the club's id>/chapters | python3 -m json.tool
```
**Expected result:** `data` now has three entries; the new one has `"position":3`.

**Pass criteria:** a chapter can be added from the Schedule tab itself, not only from
the strip's own "+ Add Chapter" control, and it's appended at the next position exactly
like Step 18's Test 3.

---

### Test 5 — A non-creator member sees the schedule but no management controls

**Setup:** continue from Test 4, logged in as Joiner.

**Steps (Underlined UI)**
1. Open "Free Will Thinkers" and click the "Schedule" tab.

**Expected UI result**
- All three rows render with their statuses and target dates, but there are no up/down
  arrows, no "Edit" links, and no "Add Chapter" form anywhere on the tab.

**Pass criteria:** reading the schedule stays open to every member (and to signed-out
visitors); only the creator sees any affordance to change it — consistent with the
strip's own creator-only add/advance controls.

---

## Negative cases

### Test 6 — A non-creator member cannot edit, reorder, or add a chapter

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/clubs/<the club's id>/chapters/<a chapter id> \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Joiner's access token>" \
  -d '{"chapter":{"label":"Hijacked"}}'
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/clubs/<the club's id>/chapters/<a chapter id>/move \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Joiner's access token>" \
  -d '{"direction":"down"}'
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/clubs/<the club's id>/chapters \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Joiner's access token>" \
  -d '{"chapter":{"label":"Chapter 4"}}'
```

**Expected result:** `403` for all three.

**Pass criteria:** editing, reordering, and adding chapters stay restricted to the
club's creator, the same rule Step 18 already enforces for adding the first chapter and
advancing the current one.

---

### Test 7 — A blank label is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/clubs/<the club's id>/chapters/<a chapter id> \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Creator's access token>" \
  -d '{"chapter":{"label":""}}'
```

**Expected result:** `422`.

**Pass criteria:** a chapter can never be edited down to an empty label, matching the
1-100 character rule already enforced when a chapter is first created.

---

### Test 8 — A chapter at either end of the schedule can't move past the edge

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/clubs/<the club's id>/chapters/<the first chapter's id>/move \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Creator's access token>" \
  -d '{"direction":"up"}'
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/clubs/<the club's id>/chapters/<the last chapter's id>/move \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Creator's access token>" \
  -d '{"direction":"down"}'
```

**Expected result:** `422`, with `"code": "no_neighbor"` in both response bodies.

**Pass criteria:** moving the first chapter further up, or the last chapter further
down, fails cleanly instead of silently doing nothing or corrupting positions — and in
the UI, the corresponding arrow is disabled rather than clickable.

---

### Test 9 — A chapter id from a different club is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/clubs/<club A's id>/chapters/<a chapter id that belongs to club B> \
  -H "Content-Type: application/json" -H "Authorization: Bearer <a creator of club A's access token>" \
  -d '{"chapter":{"label":"Hello"}}'
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/clubs/<club A's id>/chapters/<that same club B chapter id>/move \
  -H "Content-Type: application/json" -H "Authorization: Bearer <that same creator's access token>" \
  -d '{"direction":"down"}'
```

**Expected result:** `422`, with `"code": "invalid_chapter"` in both response bodies.

**Pass criteria:** editing or reordering can never reach across club boundaries, even
when the requester is a real creator and the chapter id is well-formed — the same rule
[Step 18's Test 11](step_18_tests.md#test-11--a-chapter-id-from-a-different-club-is-rejected)
already covers for posts and the current-chapter selection.

---

### Test 10 — Unauthenticated requests can't edit, reorder, or add a chapter

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" -X PUT http://localhost:4000/api/clubs/<the club's id>/chapters/<a chapter id> \
  -H "Content-Type: application/json" -d '{"chapter":{"label":"Nope"}}'
curl -s -o /dev/null -w "%{http_code}\n" -X PUT http://localhost:4000/api/clubs/<the club's id>/chapters/<a chapter id>/move \
  -H "Content-Type: application/json" -d '{"direction":"down"}'
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/clubs/<the club's id>/chapters \
  -H "Content-Type: application/json" -d '{"chapter":{"label":"Chapter 4"}}'
```

**Expected result:** `401` for all three.

**Pass criteria:** editing, reordering, and adding chapters all require authentication;
reading the schedule (Test 5's `GET`) does not.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Open the Schedule tab | A vertical list of rows, styled like the strip, with creator controls |
| 2 | Set a chapter's target date | Row shows "Target: `<date>`"; other chapter unaffected |
| 3 | Reorder two neighboring chapters | Positions swap; `current` stays on the same chapter |
| 4 | Add a chapter from the Schedule tab | Appended at the next position, styled upcoming |
| 5 | A non-creator member opens the tab | Sees the list, no edit/reorder/add controls |
| 6 | A member (not the creator) tries to edit/reorder/add | `403` for all three |
| 7 | Edit a chapter down to a blank label | `422` |
| 8 | Move the first chapter up, or the last down | `422 no_neighbor` for both |
| 9 | Reference another club's chapter when editing or moving | `422 invalid_chapter` for both |
| 10 | Edit/reorder/add while unauthenticated | `401` for all three |

If every row holds, Step 18.1 gives a club's creator one place to plan and adjust the
whole reading schedule — editing, reordering, and adding chapters — instead of only
being able to advance one chapter at a time from the strip, while every member keeps a
read-only, at-a-glance view of the full plan.

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
(HealthyCommunity isn't touched by this step, so there's nothing to reset there). That
leaves Underlined's database empty — schema and containers untouched, zero rows — so
the next step's tests can start from the same clean slate this file assumed at the top.
