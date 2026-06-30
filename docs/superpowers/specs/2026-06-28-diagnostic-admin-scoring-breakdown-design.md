# Admin scoring breakdown on diagnostic answers

**Date:** 2026-06-28
**Status:** Approved for planning

## Problem

`admin/diagnostics#show` lists every answer a user gave (question text + selected option) but gives no visibility into *why* the diagnostic landed on its `primary_career` and `complementary_career`. The scoring pipeline is:

1. `Diagnostics::PreScoringService` aggregates raw `disc_scores`, `academic_field_scores`, `skill_scores` from the user's answers, ranks all published diagnostic careers by `disc_match + academic_field_match + comp_match`, and keeps the top 3 in `score_data["top_career_ids"]` — but only `{ "id" => ..., "score" => ... }`. The match breakdown (which DISC types matched, which skills counted, how much each contributed) is computed in `rank_careers` and then discarded.
2. The validation step (`diagnostics#submit_validation`) lets the user check "affirmations" for those top 3 careers. `Diagnostics::ScoringService` turns checked affirmations into a bonus (capped at the career's affirmation count) and adds it to the stored score to pick the final `primary_career`/`complementary_career`. The checked affirmations and the bonus are never persisted — they exist only as request params for the duration of that one request.

There's no way today for an admin to verify the scoring logic produced the right result for a given user, or to debug it when it looks wrong.

## Goal

On `admin/diagnostics#show`, weave scoring attribution into the existing answer list: each answer row shows which of the two final careers (if any) its points fed into and how many points, plus a recap line above the list showing each career's final score. Affirmations checked at validation appear as additional rows in the same list, tagged the same way.

## Out of scope

- Showing the 3rd (non-selected) candidate career's breakdown. Only `primary_career` and `complementary_career` — the two careers that actually came out of the pipeline — are annotated. This is a correctness-verification tool for the actual result, not a candidate-ranking explorer.
- Retroactive reconstruction of affirmation choices for diagnostics already completed. They were never persisted anywhere (not in params logs, not in the DB), so there is nothing to recover. These diagnostics will simply show no affirmation rows and no bonus.
- Changing the scoring algorithm itself (disc/academic-field categorical matching, skill point summation, affirmation bonus cap). This is a read-only visibility feature; the math is unchanged.
- Backfilling the new `score_data` keys for existing diagnostics. Per the "going forward only" decision below, legacy diagnostics degrade gracefully rather than being migrated.

## Decisions

**Going forward only, not retroactive.** Affirmation choices are inherently unrecoverable for diagnostics already completed (never stored). To keep the feature's behavior consistent rather than partially backfilled, the DISC/academic-field/skill match breakdown is *also* only persisted starting from this change, even though that part is theoretically reconstructible by re-running today's matching logic against current `Career` attributes. Reconstructing it live would risk showing a breakdown that doesn't match what was actually used at scoring time if a career's `disc_types`/`academic_field_slug`/`required_skills` changed since — an exact snapshot from scoring time is more trustworthy for a correctness-verification tool than a live approximation. Diagnostics scored before this ships show only the final stored score, with no per-answer attribution.

**Only the 2 final careers, not the 3rd candidate.** The feature exists to verify "why career 1 and career 2," not to compare against a hypothetical 3rd. Simpler scope, less to compute and render.

**Categorical vs. summed matching, shown as-is.** DISC and academic-field matching are flat categorical bonuses (+3 per matching dominant DISC type, +5 if the dominant academic field matches), not proportional to the underlying answer's point value. Skill matching (`comp_match`) is a literal sum of the matching answers' points. The view reflects this distinction rather than flattening it into one "points contributed" number that would misrepresent how DISC/academic-field scoring actually works.

**Woven into the existing answer list, not a separate section.** Each existing answer row gets a badge (or badges) showing which final career(s) it fed and how many points. This keeps the admin looking at one list instead of cross-referencing a separate summary against the raw answers.

**Affirmations become synthetic rows appended to the same list.** They aren't tied to a `diagnostic_question`, so they can't annotate an existing row. They're appended after the real answer rows, styled consistently, each showing the affirmation text, which career it was checked for, and its point value.

**Final score recap above the list, not in the existing "Orientation" card.** A simple line (e.g. "Métier 1 : 14 pts · Métier 2 : 11 pts") sits above the annotated list so the per-row badges below have a total to add up to. The "Orientation" card at the top of the page is unchanged.

## Data flow (persistence changes)

`score_data` is `jsonb` on `diagnostics` — all additions below are new keys, no migration needed.

### `Diagnostics::PreScoringService`

`rank_careers` currently returns `[career, total_score]` pairs and discards the match components. Change it to keep, for each of the top 3 careers, the full breakdown:

```ruby
{
  "id"                   => career.id,
  "score"                => total_score,            # unchanged, existing key
  "disc_match"           => disc_match,
  "academic_field_match" => academic_field_match,
  "comp_match"           => comp_match,
  "matched_disc_types"   => [...],                  # career's disc_types ∩ dominant_disc
  "matched_skills"       => { "skill_slug" => points, ... }  # career.required_skills ∩ skill_scores, with points
}
```

Also persist the categorical winners used for matching, since they're intermediate values today and needed to explain *why* a DISC type or academic field counted:

```ruby
score_data["dominant_disc_types"]    # top 2 disc types by score, array
score_data["dominant_academic_field"] # top academic field by score, string or nil
```

`disc_scores`, `academic_field_scores`, `skill_scores` (the raw aggregate totals) are already persisted today and need no change — they're available for every diagnostic regardless of age.

### `Diagnostics::ScoringService`

When computing the affirmation bonus per career, persist the detail instead of discarding it after use:

```ruby
score_data["affirmation_breakdown"] = {
  "<career_id>" => {
    "checked_affirmations" => ["text of affirmation 1", "text of affirmation 2"],  # snapshot text, not index — Career#affirmations can be edited later
    "bonus"                => 2,
    "max_bonus"            => 4
  },
  ...
}
```

Snapshotting affirmation *text* (not index) means the admin view still makes sense even if a career's affirmations list is edited or reordered later.

### Legacy diagnostics

If `score_data` lacks `top_career_ids[].disc_match` (etc.) or `affirmation_breakdown`, the presenter (below) returns no attribution for the affected part. No errors, no fabricated data — the view simply renders the recap/badges it can and omits what it can't.

## View changes (`admin/diagnostics/show.html.erb`)

- **Recap line** above "Détail des Réponses": each career's final score (base + affirmation bonus, or just base if no bonus data). Omitted entirely if neither career has breakdown data.
- **Per-answer badges**: each existing answer row gets 0–2 badges (one per career it fed), each showing the career name and points, using the logic appropriate to that answer's question kind:
  - DISC answer → badge if its `disc_type` is in that career's `matched_disc_types` (+3).
  - Interest answer → badge if its `dimension_slug` is `dominant_academic_field` and matches that career's academic field (+5).
  - Skill answer → badge if its `skill_slug` is in that career's `matched_skills`, showing the actual point value.
- **Affirmation rows**: appended after the real answer rows, one per checked affirmation, showing `Affirmation validée pour {career} : "{text}"` — no per-row point value. The bonus is `min(checked_count, max_bonus)` for the *set* of checked affirmations, so individual affirmations don't each carry an independent point value once the cap is in play. The bonus total appears once, in the recap line, not per affirmation row.
- Rows/badges for a career with no breakdown data (legacy diagnostic) simply don't render; the rest of the page (existing answer list) is unaffected.

## New components

- `Diagnostics::AnswerAttributionPresenter` (new, `app/services/diagnostics/answer_attribution_presenter.rb` or similar) — built from a `diagnostic`. Given one `DiagnosticAnswer`, returns the badges (career, points) for it. Also exposes:
  - the recap data (final score per career)
  - the list of synthetic affirmation rows to append
  Keeps this branching logic out of the view; the view just asks the presenter per row.

## Testing

- **`PreScoringService` spec**: persists `disc_match`/`academic_field_match`/`comp_match`/`matched_disc_types`/`matched_skills` correctly for representative cases (DISC match, academic-field match, skill sum, and a non-matching career that should show zeros).
- **`ScoringService` spec**: persists `affirmation_breakdown` with correct checked-affirmation text and bonus; existing primary/secondary selection behavior unchanged.
- **`AnswerAttributionPresenter` spec**: correct badge(s) for a DISC answer, an interest answer, a skill answer, each against a matching and a non-matching career; returns no badges (without raising) when `score_data` lacks the new keys (legacy diagnostic).
- **Request/view spec**: `admin/diagnostics#show` renders without error for (a) a diagnostic scored after this ships (full breakdown visible) and (b) a pre-existing diagnostic with legacy `score_data` (no breakdown, page still renders the plain answer list as today).
