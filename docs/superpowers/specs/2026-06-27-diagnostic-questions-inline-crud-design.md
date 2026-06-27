# Inline create/edit and drag-only positioning for diagnostic questions

**Date:** 2026-06-27
**Status:** Approved for planning

## Problem

`/admin/assessments/:id/diagnostic_questions` already supports inline single-field edits (text, position, active — see `2026-06-27-diagnostic-questions-inline-editing-design.md`), but two things still force a full page navigation:

- Creating a question ("Nouvelle Question") goes to `new.html.erb`.
- Changing `kind`, `disc_type`, `skill_slug`, `skill_label`, or `academic_field_slug` ("Modifier") goes to `edit.html.erb`.

Separately, `position` is editable two ways at once today — a number field in the form and a single-field inline edit — while drag-and-drop reordering (`sortable_controller.js`) also exists. Three ways to change the same value invites them to disagree, and manual entry doesn't enforce the "no gaps, no duplicates within a kind" invariant the way drag-to-reorder does.

The filter tabs (Toutes / Intérêt / DISC / Skill) also look inconsistent with the tab style already used on `/admin/diagnostics`.

## Goal

- Creating and fully editing a question (all fields) happens on the same page, no navigation.
- `position` becomes **read-only except via drag-and-drop** — removed from both the create/edit form and the single-field inline edit.
- The filter tabs adopt the `/admin/diagnostics` pill style.
- In the "Toutes" filter, rows are grouped by kind (in tab order: Intérêt, DISC, Skill) so each kind's 1..N position sequence reads cleanly instead of interleaving with other kinds.
- An empty state renders when a filter matches zero questions.

## Out of scope

- Changing how `destroy` works — it already redirects back to the same index, which is effectively already "same page."
- Changing drag-and-drop itself (`sortable_controller.js`, `reorder` action) — unchanged, still scoped to a single kind filter.
- The single-field inline edits for `text` and `active` — unchanged, still available independently of the new full-row form.
- **No-JS fallback.** Today, `new.html.erb`/`edit.html.erb` give a working (if clunky) path if JS fails. Removing those pages means question creation/editing has a hard JS dependency afterward, same as the single-field inline edits already do. This is a deliberate tradeoff, not an oversight — flagged here because it's a real reduction in robustness, not because anything in this app currently relies on no-JS support.

## Approach

Extend the existing inline-edit machinery (`Admin::DiagnosticQuestionsController`'s `X-Inline-Edit` header branch, the `question_row` partial, turbo streams) to cover the rest of the fields and creation, rather than introducing Turbo Frames or a different mechanism.

**Why extend the existing pattern instead of Turbo Frames per row:** the prior spec already considered and rejected a row-level Turbo Frame edit mode in favor of click-to-edit cells. Now that we *do* want a row-level edit mode (for the kind-dependent fields), the cheapest path is to reuse the already-proven `X-Inline-Edit` header + turbo_stream replace mechanism rather than introduce a second, frame-based system alongside it. One request/response pattern for the whole page.

**Why a sibling hidden `<tr>` instead of cramming both states into one row:** the kind-dependent fields (`disc_type` / `skill_slug` + `skill_label` / `academic_field_slug`) aren't part of the display row at all today. Squeezing select inputs for all of them into the existing cells would clutter the display markup for a state that's hidden most of the time. Instead, each question gets a second `<tr>` directly below it — the "edit-form row" — rendered once, hidden by default, shown in place of the display row when "Modifier" is clicked. Visually it's a swap at the same table position; structurally it's two rows toggling visibility.

**Why replace the whole `<tbody>` on full-row save, but just the one row for single-field edits:** a full-row edit can change `kind`, which changes the question's sort position in the grouped "Toutes" view (and its position scope entirely). A single-row turbo_stream replace can't move a row to a different place in the table. The existing single-field edits (`text`, `active`) can never change `kind`, so they keep their narrower, cheaper single-row replace. The rule: if the submitted params include `kind`, it's a full-row request and the whole `<tbody>` is replaced; otherwise it's a single-field request and only that row is replaced.

**Why position becomes drag-only:** the model's invariant (`position` numbered 1..N within a `kind`, no gaps/duplicates) is automatically maintained by the existing `reorder` action, which always re-numbers the entire scope from 1. Manual entry (either via the form or the single-field inline edit) bypasses that and can create gaps or duplicates that drag-and-drop wasn't designed to repair. Removing manual entry leaves exactly one code path that touches `position` outside of creation.

### Components

1. **`app/views/admin/diagnostic_questions/index.html.erb`**
   - Filter tabs restyled to match `/admin/diagnostics`: `bg-slate-100/50 p-1.5 rounded-2xl` container, `data-controller="tab-activation"` (existing controller, unchanged), active tab = white background + shadow + primary text, inactive = gray text.
   - `<tbody>` gets `id="questions_tbody"` so it can be targeted by `turbo_stream.replace`.
   - When `@kind_filter == "all"`, the controller orders rows by kind (Intérêt, DISC, Skill) then position; for a single-kind filter, ordering is unchanged (`position` only).
   - A hidden "new question" `<tr>` is appended at the end of `<tbody>`, rendered via the new `_question_form_row` partial in "create" mode. "Nouvelle Question" stops being a link to `new_admin_assessment_diagnostic_question_path` and becomes a button that reveals this row and scrolls it into view (via the new Stimulus controller, no request).
   - When `@questions.empty?`, render `shared/empty_state` (icon "list-checks", title "Aucune question", description naming the active filter) instead of the table.

2. **`app/views/admin/diagnostic_questions/_question_row.html.erb`**
   - "Modifier" becomes a button (not a link to `edit_admin_assessment_diagnostic_question_path`) that hides the display `<tr>` and reveals a sibling edit-form `<tr>` (rendered via `_question_form_row` in "edit" mode), via the new Stimulus controller.
   - The Position cell drops its `inline-edit` wrapper — becomes plain text (`q.position`), no longer clickable.
   - Everything else (text/active single-field inline edit, drag handle when `sortable_enabled`, Supprimer) is unchanged.

3. **`app/views/admin/diagnostic_questions/_question_form_row.html.erb`** (new, replaces `_form.html.erb`)
   - A `<tr>` containing `kind`, `text`, the kind-dependent field(s) (same conditional show/hide logic as today, via the existing `assessment-question-form` Stimulus controller), and `active` — no `position` field.
   - Shared between the per-row edit-form row (pre-filled, PATCHes to `update`) and the bottom new-row (blank, POSTs to `create`). The new-row's `kind` defaults to the active filter tab, or `"interest"` when the active filter is "Toutes" — matching today's `new` action default (`params[:kind].presence || "interest"`).
   - Submits via `fetch` with `X-Inline-Edit: true`, same pattern as the existing single-field inline edits.
   - Accepts an `inline_errors` local so a failed save can redisplay the same row-form with messages instead of losing the admin's in-progress input.
   - A "Annuler" button hides the form (and, for the edit case, re-shows the display row) without any request, resetting fields to their last-saved values.

4. **`app/javascript/controllers/row_form_controller.js`** (new)
   - Toggles visibility between a row and its paired form-row (edit case) or shows/hides+resets a standalone form-row (create case). No network calls for opening/cancelling — only the form's own submit triggers a request.

5. **`Admin::DiagnosticQuestionsController`**
   - `create`: position is computed server-side via the existing `next_position_for(kind)` helper and `position` is dropped from `question_params` entirely — the client never sends it. When `inline_edit_request?`: success replaces `questions_tbody` (the new question's row appears in its correct grouped position); failure replaces just the new-row form with `inline_errors`, staying open with the admin's input intact.
   - `update`: same `inline_edit_request?` branch as today, but now: if `params[:diagnostic_question][:kind]` is present (a full-row submission), success replaces `questions_tbody`; if not (a single-field `text`/`active` submission, as today), success replaces just that row. Failure always replaces just the relevant row/form-row, never the whole tbody.
   - `index`: when `@kind_filter == "all"`, order by kind (via an explicit case matching tab order) then position; otherwise unchanged.
   - Remove the `new` and `edit` actions — nothing renders them anymore.

6. **`config/routes.rb`**
   - `resources :diagnostic_questions` narrows to `only: [:index, :create, :update, :destroy]` (plus the existing `collection { patch :reorder }`) — `new`/`edit` routes are deleted since nothing links to them after this change.

7. **Removed files:** `app/views/admin/diagnostic_questions/new.html.erb`, `edit.html.erb`, `_form.html.erb` (superseded by `_question_form_row.html.erb`).

### Data flow

**Editing kind-dependent fields:**

```text
Admin clicks "Modifier"
  → row_form controller hides the display <tr>, shows the paired edit-form <tr> (already rendered, just hidden)
Admin changes kind/text/type-field/active, clicks "Enregistrer"
  → fetch PATCH .../diagnostic_questions/:id  body includes kind, text, ..., active (no position)
    headers: X-Inline-Edit: true
  → controller#update sees `kind` present → full-row path
    - valid: turbo_stream replace of <tbody id="questions_tbody"> with the freshly grouped/ordered list
    - invalid: turbo_stream replace of just this row's edit-form <tr>, with inline_errors, still open
Admin clicks "Annuler" instead
  → row_form controller hides the edit-form row, re-shows the display row, no request
```

**Creating a question:**

```text
Admin clicks "Nouvelle Question"
  → row_form controller un-hides the bottom new-row <tr>, scrolls it into view, kind preselected from the active filter tab
Admin fills fields, clicks "Créer"
  → fetch POST .../diagnostic_questions  body includes kind, text, ..., active (no position)
    headers: X-Inline-Edit: true
  → controller#create sets position = next_position_for(kind) server-side
    - valid: turbo_stream replace of <tbody id="questions_tbody">, including a fresh blank (hidden) new-row at the end
    - invalid: turbo_stream replace of just the new-row, with inline_errors, still open
Admin clicks "Annuler" instead
  → row_form controller hides the new-row and resets its fields, no request
```

**Drag reorder:** unchanged — only available within a single-kind filter, calls the existing `reorder` action.

### Error handling

Validation failures (blank `text`, missing kind-specific field, invalid JSON options) render inline within the same row/form-row that was being edited, with the model's error messages — no flash, no navigation, no lost scroll position. This is the same pattern the existing single-field inline edit already uses, just applied to the full-row form. No new validations are introduced; `DiagnosticQuestion`'s existing validations are reused as-is.

### Testing

- Controller tests (`test/controllers/admin/diagnostic_questions_controller_test.rb`):
  - `create` with `X-Inline-Edit: true` and a full field set: response replaces `questions_tbody`, the new question is persisted with `position` auto-assigned to `next_position_for(kind)` regardless of any `position` sent in params.
  - `create` with `X-Inline-Edit: true` and invalid params (e.g. missing `academic_field_slug` for an `interest` question): `:unprocessable_content`, turbo_stream targets the new-row, no question persisted.
  - `update` with `X-Inline-Edit: true` and a `kind` change: response replaces `questions_tbody`, not just the row.
  - `update` with `X-Inline-Edit: true` and only `text` (no `kind`): still replaces just the row — regression guard that the existing single-field path is untouched.
  - Sending `position` in `create`/`update` params has no effect on the persisted value (params dropped server-side).
  - `index` with `kind=all` and questions of mixed kinds: asserts rows render in kind-then-position order.
  - `index` with a filter matching zero questions: asserts the empty-state content renders, not the table.
  - Old `new_admin_assessment_diagnostic_question_path` / `edit_admin_assessment_diagnostic_question_path` route helpers no longer exist (route removal verified by the test file itself failing to compile/reference them — these tests are deleted, not ported).
- Manual browser verification after implementation: open/cancel the new-row form, open/cancel an edit-form row, save each (success and a forced validation error), confirm drag-reorder still works within a single kind filter, confirm the "Toutes" view groups by kind, confirm the empty state appears for a kind with no questions.
