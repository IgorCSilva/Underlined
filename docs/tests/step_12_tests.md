# Manual Test Plan — Step 12: Interest Profiles & Similar Readers

Scope: [roadmap.md](../base_content/roadmap.md) Step 12 — a user's profile page gains a
"Reading interests" bar chart (keyword usage, most-used first), a "Similar readers"
row (other users ranked by keyword overlap), and — unlike every step since
[Step 7](step_7_integration_tests.md) — a real **Community Health pairing**: a
contribution-level (seedling) badge and a trust-level label, read through from CH's
new reputation/trust endpoints and wrapped in `CommunityHealthGate` so the badge greys
out rather than disappearing if CH is unavailable.

This step required genuinely new HealthyCommunity code, not just a retrofit: CH's own
roadmap had **CH-Step 8 (Reputation Engine)** and **CH-Step 9 (Trust, Authority &
Roles)** both at "Not started" — this work built them. See
[healthy_community/roadmap.md](../../../HealthyCommunity/docs/base_content/healthy_community/roadmap.md)
CH-Step 8/9 and Part B Step 12 for the full backend-side writeup. The interest-profile
bars and similar-readers module themselves have no CH dependency and render
unconditionally, same as any other Underlined-only feature.

For raw setup commands (starting stacks, registering the platform), see
[integration.md](../healthy_community/integration.md) — this file assumes those work.

## Before you start

- Both repos checked out: `Underlined` and `HealthyCommunity`.
- Start HealthyCommunity: `cd HealthyCommunity && docker compose up -d postgres app`.
- Register the platform once and copy the printed API key (skip if already registered
  from earlier testing):
  `docker compose exec app mix community_health.register_platform "Underlined"`
- **New for this step** — provision reputation rules for the `default` community (there
  are none by default; without at least one rule, every action is a no-op for
  reputation purposes):
  ```
  docker compose exec app mix community_health.add_reputation_rule underlined default CREATE 20 100
  docker compose exec app mix community_health.add_reputation_rule underlined default COMMENT 10 50
  ```
  (`20`/`10` are points per action, `100`/`50` are daily caps — see
  `mix help community_health.add_reputation_rule`.) This only works once a community
  named `default` exists for the `underlined` platform — sign up and publish at least
  one post first (Step 1/3) so Underlined's own `ensure_member`/`record_action` calls
  have already created it, or run
  `docker compose exec app mix community_health.add_rule underlined default DUMMY "Dummy" low`
  first, which creates the community as a side effect the same way CH-Step 4's doc
  does.
- Start Underlined with the integration **on**:
  `cd Underlined && COMMUNITY_HEALTH_ENABLED=true COMMUNITY_HEALTH_API_KEY="<key>" docker compose up -d`
- You have one **enabled** user to log in with (see
  [Step 1's doc](step_1_plus_integration_tests.md#finding-a-users-id-and-why-signing-up-isnt-enough-to-log-in)),
  and a book to post against.
- All DB/IEx verification below uses `docker compose exec api iex -S mix` (Underlined)
  and `docker compose exec app iex -S mix` (HealthyCommunity) — never `psql`.

---

## Positive cases

### Test 1 — Publishing posts raises the profile's contribution (seedling) level

**Steps (Underlined UI)**
1. Log in, publish 3-4 posts tagged with a couple of keywords each (`/posts/new`).
2. Visit your own profile at `/profile`.

**Expected UI result**
- Next to the profile actions, a row of 🌱 seedlings appears (more posts → more
  seedlings, capped at 5) next to a small trust-level label ("Low trust" at first —
  trust needs account age, not just reputation).

**Backend verification**
```
curl -s http://localhost:4000/api/users/<your id>/community_health | python3 -m json.tool
```
Expect `community_health_available: true` and `reputation_level` > 0 once at least one
`CREATE` action has landed. Cross-check the raw score directly against CH:
```
curl -s -H "Authorization: Bearer <key>" \
  http://localhost:4100/v1/communities/default/members/<your id>/reputation
```

**Pass criteria:** the seedling count on the profile matches `reputation_level` from
both endpoints, and grows as you publish more (up to the daily cap of 100 points from
`CREATE`).

---

### Test 2 — Trust level reflects account age + reputation, read via CH directly

**Steps (API only — backdating a membership isn't practical through the UI)**
```
docker compose exec app iex -S mix
```
```elixir
alias CommunityHealth.{Communities, Platforms}
alias CommunityHealth.Repo
{:ok, platform} = {:ok, Platforms.get_by_code("underlined")}
{:ok, community} = {:ok, Communities.get_community(platform, "default")}
member = Communities.get_member(community, "<your id>")
backdated = NaiveDateTime.add(NaiveDateTime.utc_now(), -31 * 24 * 60 * 60, :second) |> NaiveDateTime.truncate(:second)
Ecto.Changeset.change(member, inserted_at: backdated) |> Repo.update!()
```

**Steps (Underlined UI)**
1. Refresh your profile page.

**Expected UI result**
- The trust label upgrades from "Low trust" toward "Medium"/"High trust" once both the
  account-age and reputation thresholds are met (30+ days, 100+ reputation for "high").

**Pass criteria:** the trust label changes after backdating, without touching
reputation — confirming trust and reputation are computed independently.

---

### Test 3 — "Reading interests" bars, most-used keyword first

**Setup:** continue with the posts from Test 1, using a keyword repeated on more posts
than the others (e.g. tag 3 posts `attention`, 1 post `nature-writing`).

**Steps (Underlined UI)**
1. On your own profile, look at the "Reading interests" section.

**Expected UI result**
- One sans-serif row per keyword, each with a sand-colored track and an
  ink-blue-to-terracotta gradient bar, and the post count in small gray text at the
  right. `attention` (3 posts) renders a full-width bar; `nature-writing` (1 post)
  renders a shorter one, and the rows are ordered most-used first.

**Backend verification**
```
curl -s http://localhost:4000/api/users/<your id>/interests | python3 -m json.tool
```

**Pass criteria:** row order and relative bar widths match each keyword's post count.

---

### Test 4 — "Similar readers" ranks by shared keyword overlap

**Setup:** log in as a second user and publish posts sharing at least one keyword with
the first user's posts (e.g. also tag something `attention`).

**Steps (Underlined UI)**
1. On the first user's profile, look at the "Similar readers" row below the interest
   bars.

**Expected UI result**
- A horizontal scroll row of 48px circular avatars, each with a small terracotta pill
  underneath reading "N shared ideas". Clicking an avatar navigates to that reader's
  own profile.

**Pass criteria:** the second user appears in the row with a shared-ideas count greater
than zero, and the avatar links to `/profile/<their id>`.

---

### Test 5 — Guardian role-progress is readable (CH-Step 9), even though Underlined doesn't surface it yet

**Steps (API only — this is CH-Step 9's read endpoint; Underlined's Step 12 only reads
reputation/trust, not role-progress — that's Part C's job)**
```
curl -s -H "Authorization: Bearer <key>" \
  http://localhost:4100/v1/communities/default/members/<your id>/role-progress/guardian | python3 -m json.tool
```

**Expected result**
- Four requirements (`account_age_days`, `reputation_score`, `confirmed_violations`,
  `constructive_contributions`), each with its `threshold`, your `current` value, and
  whether it's `met`, plus an overall `eligible` boolean.

**Pass criteria:** the response reflects your actual reputation score and (if you ran
Test 2) backdated account age.

---

## Negative cases

### Test 6 — The contribution badge greys out, never disappears, when CH is unavailable

**Steps (Underlined UI)**
1. Stop HealthyCommunity: `cd HealthyCommunity && docker compose stop app`.
2. Reload your profile page in Underlined.

**Expected UI result**
- The seedling/trust badge is still present in the DOM but rendered at 40% opacity,
  grayscale, and unclickable (same `CommunityHealthGate` treatment as the Report
  button) — it never vanishes or breaks the layout.
- The "Reading interests" and "Similar readers" sections are completely unaffected —
  they have no CH dependency.

**Backend verification**
```
curl -s http://localhost:4000/api/users/<your id>/community_health
```
Expect `{"data":{"reputation_level":null,"trust_level":null,"community_health_available":false}}`.

**Pass criteria:** the API fails closed with a normalized `community_health_available:
false` rather than a raw error, and the UI degrades gracefully. Restart HealthyCommunity
(`docker compose start app`) before continuing.

---

### Test 7 — A user with no posts shows neither section

**Setup:** sign up a brand-new user who has never published anything.

**Steps (Underlined UI)**
1. Visit that user's profile.

**Expected UI result**
- No "Reading interests" section and no "Similar readers" row appear at all — both are
  omitted entirely rather than rendering empty, same convention as
  [Step 11's "Related ideas" panel](step_11_tests.md).

**Backend verification**
```
curl -s http://localhost:4000/api/users/<that user's id>/interests
```
**Expected result:** `{"data":{"interest_profile":[],"similar_readers":[]}}`.

**Pass criteria:** both UI modules are omitted, and the API returns empty lists rather
than an error.

---

## Summary checklist

| # | Scenario | Expected result |
|---|----------|------------------|
| 1 | Publish posts, then view your own profile | Seedling count grows with reputation, matching both Underlined's and CH's own endpoint |
| 2 | Backdate a membership row | Trust label upgrades once age + reputation thresholds are met |
| 3 | Tag posts with uneven keyword usage | "Reading interests" bars ordered most-used first, widths proportional |
| 4 | A second user shares keywords | "Similar readers" row shows them with an accurate shared-ideas count, linking to their profile |
| 5 | Query CH's role-progress endpoint directly | Four Guardian requirements with threshold/current/met, plus overall eligibility |
| 6 | Stop HealthyCommunity | Contribution badge greys out (not hidden); interests/similar-readers unaffected; API reports `community_health_available: false` |
| 7 | View a brand-new user's profile | No interests or similar-readers section renders; API returns empty lists |

If every row holds, Step 12 closes out Phase 1's MVP: every user has a working
interest profile and can discover people who think about the same ideas they do, and
— for the first time since Step 7 — a real Community Health signal (contribution
level, trust level) is visible on the profile page, gracefully degrading whenever CH
itself is disabled, slow, or down.
