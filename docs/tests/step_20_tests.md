# Manual Test Plan — Step 20: Questions & Answers

Scope: [roadmap.md](../base_content/roadmap.md) Step 20 — a "Question" is generated
from a passage exactly like a post is (the asker writes the passage and the question
together), other users submit answers underneath it, and the question's own asker can
mark one answer as the best. Tests 1-10 below interact only with Underlined's own UI
(`http://localhost:3000`) and API (`http://localhost:4000`). This step also pairs with
[CH-Step 3 (Generic Resource & Action Ingestion)](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md) —
asking, answering, and marking a best answer each emit an action event, the same
invisible-bookkeeping principle as [Step 3's doc](step_3_plus_integration_tests.md).
The optional Test 11 at the end covers that pairing and does require the paired
HealthyCommunity stack; Tests 1-10 must pass identically whether it's enabled or not.

## Before you start

- **Start from an empty database.** This file assumes Underlined's database is empty
  before Test 1. If you're re-running this file, empty it first with the Underlined
  snippet from
  [Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty),
  the same snippet this file's [Cleanup](#cleanup) section ends with.
- Underlined's stack is up: `docker compose up -d` (HealthyCommunity is irrelevant for
  Tests 1-10 — don't bother starting it).
- You need at least two **enabled** users and one book. Sign up both at `/signup`,
  enable each account from the running `api` container — never with `psql`:
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
  Then log in as the first user at `/login` and create a book at `/books/new` — call
  it "Book One". Call the two users "Asker" and "Answerer" below.
- Still logged in as Asker, publish one post about "Book One" (see
  [Step 3's doc](step_3_plus_integration_tests.md) if you need the steps) — Test 2
  needs an existing post to confirm questions and posts interleave in the same feed.
- All DB verification below uses `docker compose exec api iex -S mix` — never `psql`.

---

## Positive cases

### Test 1 — Asking a question from a passage

**Steps (Underlined UI)**
1. Log in as Asker and click "Ask a question" in the top nav (`/questions/new`).
2. Pick "Book One".
3. Type "A passage about habits." as the passage and "What habit matters most?" as
   the question.
4. Submit.

**Expected UI result**
- An "Asked!" success card appears with a "View question" button. Clicking it opens
  `/questions/:id`, showing the passage, the question body, and "0 answers".

**Backend verification**
```
curl -s http://localhost:4000/api/questions/<the question's id> | python3 -m json.tool
```
**Expected result:** `data.body` is `"What habit matters most?"`, `data.passage.text`
is `"A passage about habits."`, `data.answer_count` is `0`, `data.user.id` is Asker's id.

**Pass criteria:** asking a question writes a fresh passage and question together, in
one request — there is no "pick an existing passage" step, same as publishing a post.

---

### Test 2 — The question appears in the book's feed, interleaved with posts

**Setup:** continue from Test 1. "Book One" has one post (from "Before you start") and
one question (from Test 1).

**Steps (Underlined UI)**
1. Open "Book One"'s page at `/books/:id`.

**Expected UI result**
- The feed shows both the post and the question, newest first by when each was
  created — not grouped by type. The question's card carries a small circular "?"
  badge at the top-left corner; the post's card doesn't.

**Backend verification**
```
curl -s http://localhost:4000/api/books/<Book One's id>/page | python3 -m json.tool
```
**Expected result:** the response has both a `posts` array and a separate `questions`
array, each containing their own item.

**Pass criteria:** posts and questions are two independent resources under the hood,
merged into one chronological feed only for display.

---

### Test 3 — A second user can answer

**Setup:** continue from Test 1.

**Steps (Underlined UI)**
1. Log in as Answerer (a different browser/session) and open the question from Test 1
   at `/questions/:id`.
2. Type "Probably sleep." in the answer composer and submit.

**Expected UI result**
- The answer appears in the list immediately, in a compact bordered row below the
  question. Reloading the page shows "1 answers" in the heading.

**Backend verification**
```
curl -s http://localhost:4000/api/questions/<the question's id>/answers | python3 -m json.tool
```
**Expected result:** `data` has one answer, `"body": "Probably sleep."`, `"best":
false`.

**Pass criteria:** anyone (not just the asker) can answer a question.

---

### Test 4 — The asker (and only the asker) can mark an answer as best

**Setup:** continue from Test 3.

**Steps (Underlined UI)**
1. Log in as Asker and open the question's page.
2. On Answerer's answer row, click "Mark as best".

**Expected UI result**
- The row gets a small ochre star badge and a faint sand background tint.
3. Log in as Answerer and reload the same page.

**Expected UI result**
- The star and tint are still there, but no "Mark as best" button appears on any row —
  only the asker ever sees that control.

**Backend verification**
```
curl -s -X PUT http://localhost:4000/api/answers/<the answer's id>/best \
  -H "Authorization: Bearer <Asker's access token>"
```
**Expected result:** `{"data":{..., "best": true}}`.

**Pass criteria:** marking a best answer is the asker's own judgment call, visible to
everyone but only actionable by them.

---

### Test 5 — Marking a different answer as best switches which one is marked

**Setup:** continue from Test 4. As Answerer, submit a second answer, "Maybe diet.",
on the same question.

**Steps (Underlined UI)**
1. As Asker, click "Mark as best" on the new "Maybe diet." answer.

**Expected UI result**
- The star and tint move to "Maybe diet."; "Probably sleep." (Test 4's pick) loses
  both and its "Mark as best" button reappears.

**Backend verification**
```
curl -s http://localhost:4000/api/questions/<the question's id>/answers | python3 -m json.tool
```
**Expected result:** exactly one answer has `"best": true` — the new pick — and it's
first in the list.

**Pass criteria:** only one answer can be the best answer at a time; choosing a new one
un-marks the previous one in the same request.

---

## Negative cases

### Test 6 — Asking a question with a blank body is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/books/<Book One's id>/questions \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Asker's access token>" \
  -d '{"question":{"passage_text":"A passage.","body":""}}'
```

**Expected result:** `422` (changeset validation error on `body`).

**Pass criteria:** a question always has a non-empty body.

---

### Test 7 — Asking a question under an unknown book is rejected

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X POST http://localhost:4000/api/books/00000000-0000-0000-0000-000000000000/questions \
  -H "Content-Type: application/json" -H "Authorization: Bearer <Asker's access token>" \
  -d '{"question":{"passage_text":"A passage.","body":"Anything?"}}'
```

**Expected result:** `404`.

**Pass criteria:** a question can never be created against a book that doesn't exist.

---

### Test 8 — Unauthenticated requests can't ask, answer, or mark best

**Steps (API)**
```
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/books/<Book One's id>/questions \
  -H "Content-Type: application/json" -d '{"question":{"passage_text":"A passage.","body":"Anything?"}}'
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:4000/api/questions/<the question's id>/answers \
  -H "Content-Type: application/json" -d '{"answer":{"body":"Nope."}}'
curl -s -o /dev/null -w "%{http_code}\n" -X PUT http://localhost:4000/api/answers/<an answer's id>/best
```

**Expected result:** `401` for all three.

**Pass criteria:** asking, answering, and marking best all require authentication;
reading a question and its answers (Tests 1 and 3's `GET` calls) do not.

---

### Test 9 — A non-asker marking best is rejected

**Setup:** continue from Test 3 — Answerer has at least one answer on the question.

**Steps (API)**
```
curl -s -w "\n%{http_code}\n" -X PUT http://localhost:4000/api/answers/<the answer's id>/best \
  -H "Authorization: Bearer <Answerer's access token>"
```

**Expected result:** `403`.

**Pass criteria:** marking best is never a self-service or majority-vote action —
only the question's own asker may do it.

---

### Test 10 — An unknown question or answer id degrades gracefully, not a crash

**Steps (Underlined UI / API)**
1. Go to `/questions/00000000-0000-0000-0000-000000000000`.
2. Separately, check the API directly:
   ```
   curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/questions/00000000-0000-0000-0000-000000000000
   curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/questions/00000000-0000-0000-0000-000000000000/answers
   curl -s -o /dev/null -w "%{http_code}\n" -X PUT http://localhost:4000/api/answers/00000000-0000-0000-0000-000000000000/best \
     -H "Authorization: Bearer <Asker's access token>"
   ```

**Expected result:** the UI renders "Question not found." (no crash); the `GET`s
return `404`; the unknown-answer `PUT` returns `404` too.

**Pass criteria:** an unknown question or answer id degrades gracefully on both the API
and the UI.

---

## Optional — Community Health pairing (CH-Step 3)

This step pairs with
[CH-Step 3 (Generic Resource & Action Ingestion)](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md) —
no new HealthyCommunity code was needed; `record_action` already accepts any
caller-supplied `resource_type`. Like [Step 3's doc](step_3_plus_integration_tests.md)
and [Step 7's doc](step_7_integration_tests.md), asking/answering/marking best must
look and behave identically whether this is on, off, or broken — the UI never reads CH
to show a question or decide whether one can be asked, answered, or resolved.

### Test 11 (optional) — Asking, answering, and marking best each record their own action event

**Setup**
1. Start HealthyCommunity: `cd HealthyCommunity && docker compose up -d postgres app`
2. Register the platform once and copy the printed API key (skip if already
   registered from earlier testing):
   `docker compose exec app mix community_health.register_platform "Underlined"`
3. Start Underlined with the integration **on**:
   `cd Underlined && COMMUNITY_HEALTH_ENABLED=true COMMUNITY_HEALTH_API_KEY="<key>" docker compose up -d`
4. Repeat Test 1 (ask a question), Test 3 (answer it), and Test 4 (mark that answer
   best).

**Backend verification**
```elixir
# HealthyCommunity — docker compose exec app iex -S mix
alias CommunityHealth.Repo
alias CommunityHealth.Actions.CommunityAction
import Ecto.Query

question_id = "<the question's id>"
answer_id = "<the answer's id>"

Repo.one(
  from a in CommunityAction,
    join: r in assoc(a, :resource),
    where: a.action_type == "ASK_QUESTION" and r.external_ref == ^question_id
).action_type
# => "ASK_QUESTION"

Repo.one(
  from a in CommunityAction,
    join: r in assoc(a, :resource),
    where: a.action_type == "ANSWER" and r.external_ref == ^answer_id
).context
# => %{"question_id" => question_id}

Repo.one(
  from a in CommunityAction,
    join: r in assoc(a, :resource),
    where: a.action_type == "BEST_ANSWER_SELECTED" and r.external_ref == ^answer_id
).action_type
# => "BEST_ANSWER_SELECTED"
```

**Pass criteria:** within a few seconds (processed by an Oban job after each HTTP
response, never on the request path), all three actions exist with the right
`action_type`/`resource_type`/`context` — and none of them ever delayed or changed the
UI's own response in Tests 1, 3, or 4.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Ask a question about a passage | Question created with its own fresh passage, `answer_count: 0` |
| 2 | Open a book with a post and a question | Both appear in one feed, newest first; question carries the "?" badge |
| 3 | A second user answers | Answer appears immediately; anyone can answer |
| 4 | Asker marks an answer best | Star + tint appear; only the asker sees "Mark as best" |
| 5 | Asker marks a different answer best | Star moves; only one answer is ever best |
| 6 | Ask with a blank body | `422` changeset error |
| 7 | Ask under an unknown book | `404` |
| 8 | Ask/answer/mark best while unauthenticated | `401` |
| 9 | A non-asker marks best | `403` |
| 10 | Visit/query an unknown question or answer id | `404` from the API; "Question not found." in the UI |
| 11 (optional) | Ask, answer, and mark best, with CH enabled | `ASK_QUESTION`, `ANSWER`, and `BEST_ANSWER_SELECTED` actions recorded |

If every row holds, Step 20 lets any reader turn a passage into a structured
discussion — ask a question, gather answers from anyone, and let the asker surface the
best one — and (optionally) each of those three moments is already emitting the same
kind of reputation-bearing action event Community Health already records for posts and
comments, invisibly, without that pairing ever being able to block or slow down the
core flow.

---

## Cleanup

Run the Underlined snippet from
[Step 1's "Resetting both databases to empty"](step_1_plus_integration_tests.md#resetting-both-databases-to-empty)
(and the HealthyCommunity one too, if you ran Test 11). That leaves both databases
empty — schema and containers untouched, zero rows — so the next step's tests can
start from the same clean slate this file assumed at the top.
