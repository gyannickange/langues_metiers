# Diagnostic audit: score overview & answer filters

**Date:** 2026-07-21
**Status:** Approved for planning
**Supersedes (partially):** [2026-06-28-diagnostic-admin-scoring-breakdown-design.md](2026-06-28-diagnostic-admin-scoring-breakdown-design.md)

## Problem

The 06-28 spec wove score attribution into `admin/diagnostics#show` as a one-line recap (`Métier 1 : 14 pts · Métier 2 : 11 pts`) plus per-answer badges. That shipped and works, but for an admin actually trying to *audit* a scoring result (verify it, or judge whether it was a close call), it's still missing:

1. **No category breakdown at a glance.** The recap line is a single number per career; to see how much came from DISC vs. intérêts vs. compétences vs. affirmation bonus, an admin has to manually add up badges scattered across the whole answer list.
2. **No visibility into the runner-up.** Only `primary_career`/`complementary_career` are shown. An admin can't tell if the result was a landslide or a near-tie with the 3rd-ranked candidate — which matters when someone disputes a result.
3. **The answer list is one long flat list** with no way to jump to just the answers that mattered for scoring.

## Goal

Redesign the top of `admin/diagnostics#show` to give an admin, in this order:
- A compact score-overview card per career (2 retained + the 3rd/non-retained candidate), each expandable to its full category breakdown.
- A filter bar above the existing chronological answer list, to narrow to a category or to "counted toward the score."

This is purely a presentation/UX change on top of data the 06-28 work already persists. No scoring algorithm changes, no migrations.

## Decisions

**Reverses the 06-28 "3rd candidate out of scope" call.** That spec scoped out the runner-up because the feature was framed as "verify why career 1 and 2 won." The audit use case is broader: judging *how close* the result was requires seeing what didn't win. `PreScoringService` already stores full breakdown data (`disc_match`, `academic_field_match`, `comp_match`, `matched_disc_types`, `matched_skills`) for all 3 entries in `top_career_ids`, not just the top 2 — so this needs no new persistence, only exposing what's already there.

**The 3rd candidate is whichever `top_career_ids` entry isn't `primary_career` or `complementary_career`.** With exactly 3 stored candidates and 2 chosen, the leftover one is unique — no re-ranking needed.

**The 3rd candidate's score excludes the affirmation bonus, and the UI says so.** Affirmations are only ever collected for the 2 recommended careers (`diagnostics#submit_validation` only presents affirmations for those two) — there is no `affirmation_breakdown` entry for a non-retained career, and none can be reconstructed. Its card shows the base score only, labeled so it isn't mistaken for a directly comparable final score (e.g. a footnote: "Score de base, sans bonus affirmations (non proposées pour ce métier)"). This is a known asymmetry, not a bug: it still shows the true gap magnitude, just conservatively (the 3rd candidate's real gap-to-2nd is at least this small, possibly smaller).

**Legacy diagnostics degrade the same way as before.** If `top_career_ids` entries lack `disc_match` (pre-06-28 diagnostics), the overview card for that entry is omitted entirely — same rule the 06-28 spec already established for primary/secondary, now applied uniformly to all 3 slots.

**Category breakdown shows a real max where one exists, never a fabricated one.** Per category:
- DISC: `points / (dominant_disc_types.size * 3)` — the true ceiling given the user's own top-2 DISC types.
- Intérêts: `points / 5` — binary match, fixed ceiling.
- Compétences: raw points only, no denominator (uncapped sum over however many required skills a career has — there's no natural "max").
- Bonus affirmations: `points / max_bonus`, already stored per career (only for the 2 retained careers; omitted for the 3rd).

**Compact-by-default, expand-on-demand.** Each overview card shows name + total + a one-line inline summary (`DISC 9 · Intérêts 5 · Compétences 7 · Bonus 2`) collapsed. Clicking reveals the full per-category table.

**Answer list keeps chronological order; filtering is additive, not a re-sort.** The existing order (matches the real questionnaire session) stays intact — audits often care about session flow, not just final attribution. A filter bar narrows the visible set without reordering.

**Everything client-side, no new requests.** The full answer set is already rendered in one response (no pagination on this list) — filtering and expand/collapse are pure show/hide in the browser. Consistent with the "instant" premium feel used elsewhere (`animate-premium-in`).

## Implementation approach

**Expand/collapse → native `<details>`/`<summary>`, no JS.** Simpler than a Stimulus controller and gets keyboard/accessibility support for free.

**Category filter → new `answer_filter_controller.js` Stimulus controller.** No existing controller does client-side attribute filtering of already-rendered rows (`tab_activation_controller.js` only toggles active/inactive classes on the tabs themselves and is paired with server-side `turbo_frame` navigation on the index page's status tabs — not applicable here since there's nothing to re-fetch). The new controller:
- Targets the filter buttons and the answer rows.
- Each answer row carries `data-answer-filter-category-value="disc|interest|skill"` and `data-answer-filter-scored-value="true|false"` (scored = at least one badge from `AnswerAttributionPresenter#badges_for`).
- Clicking a filter button toggles `hidden` on rows not matching; "Tout" clears the filter. Active button styled the same way the existing filter chips elsewhere in admin are styled (e.g. `tab_activation` active/inactive class pattern, reused visually not functionally).

## Data flow

No changes to `Diagnostics::PreScoringService` or `Diagnostics::ScoringService` — the 06-28 work already persists everything needed for all 3 `top_career_ids` entries.

### `Diagnostics::AnswerAttributionPresenter` changes

- `build_attributions` currently only maps `[["Métier 1", primary_career], ["Métier 2", complementary_career]]`. Add a third mapping for the leftover `top_career_ids` entry (the one whose id isn't `primary_career.id` or `complementary_career.id`), labeled e.g. `"Non retenu"`, resolved to its `Career` record the same way the other two are (`Career.find` or a preloaded lookup — reuse whatever the diagnostic's `includes` already does; add `top_career_ids` career preloading in the controller if needed to avoid N+1).
- New method `category_breakdown(attribution)` returning the 4 rows described above (label, points, max-or-nil) for use in the expandable detail. `final_score` stays as-is (already handles a nil `affirmation` gracefully via `&.dig(...).to_i`).
- `badges_for` / `affirmation_rows` are unaffected — they already only apply to the 2 retained careers because affirmation data literally doesn't exist for the 3rd; no defensive code needed, it falls out of the existing nil-handling.

## View changes

- New partial `app/views/admin/diagnostics/_score_overview.html.erb`: renders up to 3 cards (skipping any with no breakdown data) — takes the presenter and iterates its attributions. Replaces the current one-line recap sitting above "Détail des Réponses" in `show.html.erb`.
- `show.html.erb`: swap the recap line for `render "score_overview", attribution: @attribution`; add the filter bar (new partial or inline) directly above the existing answer-list `div.space-y-4`, wrapped together with the list in the `data-controller="answer-filter"` div so targets resolve.
- Each answer row (and each affirmation row) gets `data-answer-filter-target="row"` plus the two data-value attributes described above.

## Testing

- **`AnswerAttributionPresenter` spec**: 3rd-candidate attribution resolves to the correct leftover career when breakdown data exists; omitted when `top_career_ids` has fewer than 3 usable entries or lacks `disc_match` (legacy); `category_breakdown` returns correct points/max for DISC, intérêt, compétence, and (for retained careers only) affirmation bonus; `final_score`/`badges_for`/`affirmation_rows` behavior unchanged for the 2 retained careers.
- **View/system spec** on `admin/diagnostics#show`: overview renders 3 cards for a fully-scored diagnostic (2 without footnote, 1 with the "no affirmations" footnote); renders only the cards it has data for on a legacy diagnostic; expand/collapse works via `<details>`; filter bar hides/shows rows matching `data-answer-filter-category-value`/`-scored-value` without a page reload.
