# Reachable question management for /admin/assessments

**Date:** 2026-06-24
**Branch:** main

## Problem

`Admin::DiagnosticQuestionsController` already has full CRUD for questions
nested under an assessment (`/admin/assessments/:assessment_id/diagnostic_questions`),
but there is no link to it anywhere in the admin UI — not in the assessments
index, not on the assessment edit page, not in the sidebar nav
(`app/views/shared/_sidebar.html.erb`). Admins can only reach it by typing the
URL by hand, so in practice questions can't be added or edited.

Two related issues sit in the same code:

1. **Drag-to-reorder doesn't work.** `app/javascript/controllers/sortable_controller.js`
   exists and is fully implemented, but it isn't wired into
   `diagnostic_questions/index.html.erb`, and the controller's `reorder` action
   (`app/controllers/admin/diagnostic_questions_controller.rb:41-43`) is a stub
   that just returns `head :no_content` without persisting anything.
2. **A second, orphaned route is already broken.** `config/routes.rb` also
   defines a top-level `resources :diagnostic_questions` (not nested under an
   assessment). `DiagnosticQuestion belongs_to :assessment` (required), and its
   form has no assessment picker, so submitting the top-level `new` form always
   fails validation. Nothing links to this route either.

## Goal

Make adding/editing/reordering questions for an assessment actually reachable
and working from the admin UI, and remove the dead, broken top-level route
while we're in this code.

## Non-goals

- No redesign of the question form fields themselves (kind-specific fields,
  vocabulary selects, etc. — covered by the prior
  `2026-06-18-admin-diagnostic-manageability-design.md` work and already in
  place).
- No change to the public-facing diagnostic flow (`DiagnosticsController`) or
  scoring.
- No schema/migration changes.

## Design

### 1. Entry point — assessments index

In `app/views/admin/assessments/index.html.erb`, the "Questions" column cell
(currently a plain count, line 14) becomes a `link_to` wrapping the count to
`admin_assessment_diagnostic_questions_path(a)`.

### 2. Exit point — questions index

`app/views/admin/diagnostic_questions/index.html.erb` gains a "← Retour à
l'évaluation" link back to `admin_assessment_path(@assessment)` (or
`edit_admin_assessment_path`), since it currently has no way back once you
arrive.

### 3. Reordering, scoped per kind

The public diagnostic flow (`app/controllers/diagnostics_controller.rb`)
always queries questions scoped by kind — `.interest.active.ordered`,
`.disc.active.ordered`, `.competence.active.ordered` — never across kinds. So
`position` is only meaningful *within* a kind, not globally across an
assessment's questions.

- Drag-to-reorder is only enabled when a single kind filter is active
  (`@kind_filter != "all"`); when viewing "Toutes" the handle is hidden since a
  cross-kind order has no meaning in the app.
- `<tbody>` in the index view gets
  `data-controller="sortable" data-sortable-url-value="<%= reorder_admin_assessment_diagnostic_questions_path(@assessment, kind: @kind_filter) %>"`,
  each `<tr>` gets `data-id="<%= q.id %>"`, and a drag handle
  (`data-sortable-handle`, grip icon) per row.
- `DiagnosticQuestionsController#reorder` stops being a stub: it reads
  `params[:ordered_ids]` and `params[:kind]`, verifies every ID belongs to
  `@assessment` and that kind, then updates positions 1..N in a transaction.
  Mismatched/foreign IDs return `head :unprocessable_content` instead of
  silently doing nothing.

### 4. Position default on create

The "new question" form currently has a blank, required `position` number
field — the admin has to know how many same-kind questions already exist and
guess. `DiagnosticQuestionsController#new` now defaults it to
`@assessment.diagnostic_questions.where(kind: requested_kind).maximum(:position).to_i + 1`
(`requested_kind` from `params[:kind]`, falling back to `"interest"`), while
keeping the field editable.

### 5. Remove the orphaned top-level route

- `config/routes.rb`: delete the top-level `resources :diagnostic_questions`
  block; keep only the one nested under `resources :assessments`.
- `Admin::DiagnosticQuestionsController`: `set_assessment` runs as a
  `before_action` on every action (no more "no assessment" branch); 404s via
  the standard `Assessment.find` raise if missing.
- `redirect_path` simplifies to always `admin_assessment_diagnostic_questions_path(@assessment)`.
- Views (`_form.html.erb`, `new.html.erb`, `edit.html.erb`) drop their
  `assessment ? ... : ...` branches — `assessment` is always present.

## Data flow

Admin clicks "Questions" count on an assessment row → nested index, filtered
by kind → admin drags a row → Stimulus controller POSTs the new `ordered_ids`
to `reorder` → controller validates membership and renumbers 1..N in a
transaction → page re-renders (or the row order is left as-is client-side,
since Sortable already reflects the drop — no full reload needed on success).

Admin clicks "Nouvelle Question" from a kind-filtered view → `new` pre-fills
`position` for that kind → admin submits → `create` persists, redirects back
to the same nested index.

## Error handling

- `reorder` with IDs that don't all belong to `@assessment`/`kind`: no
  partial update, `head :unprocessable_content`, existing positions untouched
  (whole operation in one transaction).
- Visiting a nested questions path for a non-existent assessment: standard
  Rails 404 (`ActiveRecord::RecordNotFound`), same as today's `edit`/`update`
  on assessments.
- Existing form validation errors (kind-specific required fields) are
  unchanged — out of scope here.

## Testing (TDD — tests written first)

- **Admin::AssessmentsController / index view:** the rendered "Questions" cell
  links to the nested path for that assessment.
- **Admin::DiagnosticQuestionsController#reorder:** persists new 1..N
  positions for same-kind questions belonging to the assessment; rejects (422,
  no changes) an ID belonging to a different assessment or a different kind.
- **Admin::DiagnosticQuestionsController#new:** pre-fills `position` as
  `max(same-kind siblings) + 1`; `1` when no siblings exist yet for that kind.
- Remove/replace any existing test that exercises the top-level
  `admin_diagnostic_questions_path` (none currently pass meaningfully since
  that path was already broken).

## Files touched

- `config/routes.rb`
- `app/controllers/admin/diagnostic_questions_controller.rb`
- `app/views/admin/assessments/index.html.erb`
- `app/views/admin/diagnostic_questions/index.html.erb`
- `app/views/admin/diagnostic_questions/_form.html.erb`
- `app/views/admin/diagnostic_questions/new.html.erb`
- `app/views/admin/diagnostic_questions/edit.html.erb`
- new/updated tests under `test/controllers/admin/`
