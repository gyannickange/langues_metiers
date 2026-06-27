# Inline editing for the diagnostic questions admin table

**Date:** 2026-06-27
**Status:** Approved for planning

## Problem

`/admin/assessments/:id/diagnostic_questions` lists all questions for an assessment in a table (`app/views/admin/diagnostic_questions/index.html.erb`). Every edit — even fixing a typo or nudging a position — requires clicking "Modifier", navigating to a separate full-page form (`edit.html.erb` / `_form.html.erb`), submitting, and being redirected back to the index. For the fields admins touch most often (question wording, position, active flag), this round trip is disproportionate to the size of the change.

## Goal

Let admins edit a question's **text**, **position**, and **active** flag directly in the table, without a page navigation, while keeping the table easy to scan. Less frequently changed, kind-dependent fields (`kind`, `disc_type`, `skill_slug`, `skill_label`, `academic_field_slug`) stay on the existing full edit page — they have conditional-field UI logic (`assessment_question_form_controller`) that isn't worth duplicating inline.

## Out of scope

- Editing `kind`, `disc_type`, `skill_slug`, `skill_label`, `academic_field_slug` inline — unchanged, still via "Modifier".
- Drag-and-drop reordering (`sortable_controller.js`, `reorder` action) — unchanged, runs alongside inline position editing.
- Removing or restyling the "Modifier" / "Supprimer" actions.
- Changing question text truncation in the *display* state (`max-w-xs truncate` stays); the full text becomes visible once a cell is clicked into edit mode.

## Approach

Extend the existing `Admin::DiagnosticQuestionsController#update` action to also respond to Turbo Stream requests, and add a Stimulus controller that turns a table cell into an input on click. No new routes or controller actions.

**Why this over the alternatives considered:**
- *Turbo Frame per field*: would need a frame + a tiny edit-form route per editable field per row (6+ frames per row across all questions). More moving parts for no behavioral benefit over the chosen approach.
- *Row-level Turbo Frame edit mode*: matches "Modifier" already (full row swap to a form), but the chosen interaction model is click-to-edit on a single cell, not a whole-row mode — already decided against during brainstorming.

### Components

1. **`app/views/admin/diagnostic_questions/_question_row.html.erb`** (new, extracted from the `<% @questions.each %>` block in `index.html.erb`)
   - Rendered both by `index.html.erb` (looping over `@questions`) and by the controller's turbo_stream response (replacing a single row).
   - Root `<tr>` gets `id: dom_id(q)` so Turbo Streams can target it.
   - The "Question" `<td>` and "Pos." `<td>` each wrap their value in a small inline-edit unit (display span + hidden input), `data-controller="inline-edit"` scoped to that `<td>`.
   - The "Active" state is exposed as a checkbox bound to `q.active`, no display/edit toggle — `change` submits immediately.

2. **`app/javascript/controllers/inline_edit_controller.js`** (new)
   - Targets: `display` (the span shown by default) and `field` (the input/textarea, hidden by default).
   - Values: `url` (the question's update path), `param` (the param name to send, e.g. `text` or `position`).
   - `edit()` (click on display): hide display, show field, focus and select its content.
   - `cancel()` (Esc keydown on field): revert field's value to the original, hide field, show display — no request sent.
   - `save()` (blur on field; also Enter keydown, but only for the `position` field — Enter in the `text` field is a no-op so multi-line editing isn't disrupted): if the value didn't change, just revert to display with no request. Otherwise PATCH via `fetch`, same CSRF pattern as `sortable_controller.js`, with header `Accept: text/vnd.turbo-stream.html` and body `diagnostic_question[<param>]=<value>`.
   - On a successful response, Turbo processes the returned `<turbo-stream>` itself (the browser's `fetch` response is handled by dispatching it through `Turbo.renderStreamMessage`), replacing the row — the controller doesn't need to manually update the DOM on success.
   - The "Active" checkbox reuses the same `url`/PATCH/turbo-stream mechanism via a one-line `change` action, not the full inline-edit target/state machinery (no display/edit split needed for a checkbox).

3. **`Admin::DiagnosticQuestionsController#update`**
   - Existing behavior (HTML format: `update` → `redirect_to redirect_path` / re-render `:edit` on failure) is unchanged — the full edit page keeps working exactly as today.
   - Add a turbo_stream branch:
     - Success: `render turbo_stream: turbo_stream.replace(@question, partial: "question_row", locals: { q: @question })`.
     - Failure: `render turbo_stream: turbo_stream.replace(@question, partial: "question_row", locals: { q: @question, inline_errors: @question.errors }), status: :unprocessable_content` — the row partial checks `inline_errors` to keep the just-edited field in its edit state (input visible, with the field's error message shown below it in red) rather than reverting to a display state that would hide the problem.
   - `question_params` is reused unchanged — inline requests only ever send one of `text`, `position`, or `active`, so no new fields become writable that the full form doesn't already permit.

### Data flow

```
User clicks "Question" cell
  → inline-edit controller swaps display span for a textarea, focuses it
User edits text, clicks away (blur)
  → fetch PATCH .../diagnostic_questions/:id  body: diagnostic_question[text]=...
    headers: Accept: text/vnd.turbo-stream.html, X-CSRF-Token
  → controller#update validates via existing DiagnosticQuestion validations
  → turbo_stream replace of <tr id="diagnostic_question_:id">
    - valid: row re-renders in display state with new text
    - invalid: row re-renders with the text cell still in edit state + inline error text
```

### Error handling

Validation failures (e.g. blank `text`, non-positive `position`) are surfaced inline, in place — no flash banner, no navigation, no loss of scroll position. The offending field stays in edit mode with the user's attempted value still in the input plus the model's error message rendered beneath it, so they can fix it immediately. This relies entirely on `DiagnosticQuestion`'s existing validations (`validates :text, presence: true`; `validates :position, presence: true, numericality: { greater_than: 0 }`) — no new validation logic.

### Browser / compatibility

No new browser APIs beyond what Turbo/Stimulus (already a dependency, loaded via importmap) and `fetch` (already used in `sortable_controller.js`) provide — runs on the same evergreen-browser baseline as the rest of the admin app. After implementation, manually exercise the feature in a real browser: click-edit text, click-edit position, toggle active, trigger a validation error (blank text), and confirm the drag-reorder feature (`sortable_controller.js`) still works unaffected alongside inline position edits.

### Testing

- Controller test (`test/controllers/admin/diagnostic_questions_controller_test.rb`): `PATCH update` with `Accept: text/vnd.turbo-stream.html` —
  - valid `text` update returns the turbo-stream content type and the new text in the body.
  - valid `position` update, same shape.
  - invalid update (blank `text`) returns `:unprocessable_content` with a turbo-stream body containing the error message.
  - existing HTML-format tests for `update`/`create`/`destroy`/`reorder` continue to pass unmodified.
- No new system tests planned — the existing controller-level coverage plus manual browser verification (above) covers this feature; the app's test suite is Minitest + `ActionDispatch::IntegrationTest` with no system/browser test setup currently in place.
