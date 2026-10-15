# Step 19 — Spoiler Protection: Tests

Scope: each reader sets their own reading progress *within a club* (the only
place the app has chapter metadata — Step 18's `club_chapters`). Club
discussion posts tagged to a chapter beyond that progress come back from the
API with their body stripped and `spoiler_blocked: true`; the frontend
renders those as a frosted, locked placeholder with a "Reveal anyway" escape
hatch that fetches the real content on demand. Blocking is decided entirely
server-side — the client never receives a spoiler body it isn't supposed to
see yet.

## Backend — `mix test`

### `test/api_web/controllers/club_discussion_controller_test.exs`

- `GET /api/clubs/:club_id/posts` (existing describe block, assertion
  updated): confirms the general chat post stays unblocked while the
  chapter-tagged post comes back with `"body" => nil, "spoiler_blocked" =>
  true` for a viewer with no reading progress set — the pre-existing
  "general-first" ordering test now also documents the default-blocked
  behavior.

- `describe "spoiler protection on GET /api/clubs/:club_id/posts"` (new, 4
  tests, seeds two chapters and one tagged post per chapter):
  - a reader who hasn't set any progress has **every** chapter-tagged post
    blocked (chapter 1 *and* chapter 2), proving "haven't started" blocks
    from the very first chapter, not just chapters past some default.
  - setting progress to chapter 1 (`PUT .../reading_progress`) reveals the
    chapter 1 post (`spoiler_blocked: false`, real body) while chapter 2
    stays blocked — the core "caught up to here, no further" behavior.
  - the club's **creator** is not exempt from their own unset progress —
    confirms there's no implicit "author of the schedule can see
    everything" bypass; everyone's progress is personal.
  - `GET /api/club_posts/:id/reveal` returns the full post (real body,
    `spoiler_blocked: false`) regardless of the viewer's progress — the
    explicit, self-chosen spoiler bypass.

### `test/api_web/controllers/club_reading_progress_controller_test.exs` (new file, 6 tests)

- `GET /api/clubs/:club_id/reading_progress`
  - defaults to `{"chapter": null}` when the reader has never set progress.
  - rejects an unauthenticated request (401) — progress is personal, no
    anonymous read.
- `PUT /api/clubs/:club_id/reading_progress`
  - sets the caller's furthest-read chapter and a follow-up `GET` reflects
    it (upsert, not insert-only).
  - can reset progress back to "not started" by sending `chapter_id: null`.
  - rejects a `chapter_id` that doesn't belong to this club (422,
    `invalid_chapter` — the same error code Step 18 already uses for the
    equivalent chapter-ownership check on posts/current-chapter).
  - rejects an unauthenticated request (401).

### Full suite

`mix test` (reduced to `--max-cases 8` to avoid unrelated DB-pool
contention under high concurrency in this dev sandbox): **307 tests, 0
failures** — no existing behavior broke.

## Frontend — manual verification (no component test runner in this repo; same convention as Steps 17/18)

- `npx nuxt typecheck` inside the `web` container: only the two
  pre-existing, unrelated errors (`app/app.vue` TS2322,
  `app/components/LocaleSwitcher.vue` TS2345) — both present before and
  after this change, confirmed not introduced by it.
- Live verification against the running `docker compose` stack (seeded
  Portuguese-locale club data):
  - `GET /api/clubs/:id/reading_progress` unauthenticated → `401`.
  - `GET /api/clubs/:id/posts` → the untagged post has
    `"spoiler_blocked": false`; the chapter-tagged post has `"body": null,
    "spoiler_blocked": true` for the anonymous/no-progress viewer.
  - `GET /api/club_posts/:id/reveal` on that same blocked post → returns
    the real body and `"spoiler_blocked": false`.
  - `curl http://localhost:3000/clubs/:id` (SSR, anonymous) renders the
    frosted spoiler placeholder markup (`discussion-post-spoiler*` classes,
    "Spoiler beyond Capítulo 1 - O primeiro dia", "Reveal anyway") for the
    blocked post, and the reading-progress slider is correctly absent from
    the anonymous SSR render (it only mounts once `auth.user` is confirmed
    client-side, same pattern as the rest of the club page).

## Notes

- Reading progress is scoped per **club**, not per book — a book can have
  several clubs with independently paced/organized schedules (Step 18
  already models chapters this way), so progress has to follow the same
  scoping to mean anything.
- "Haven't set any progress" is treated as position `0`, strictly less than
  any real chapter's position (positions start at `1`) — so a reader who's
  never touched the slider sees every chapter-tagged post blocked by
  default, never accidentally unblocked.
- Only club posts are spoiler-gated. Comments on a blocked post are never
  fetched in the first place (the frontend only loads a post's comments
  when its "N comments" toggle is rendered, which only happens once the
  post itself is unblocked or revealed) — so there's no separate
  comment-level gate to build.
- The club's collective `current_chapter_id` (Step 18 — what the group is
  discussing now) and a reader's own progress are deliberately independent:
  one is the creator's steering wheel for the group, the other is each
  reader's own bookmark.
