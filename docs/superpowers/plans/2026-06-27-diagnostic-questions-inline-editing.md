# Diagnostic Questions Inline Editing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let admins edit a diagnostic question's text, position, and active flag directly in the `/admin/assessments/:id/diagnostic_questions` table, with no page navigation, while the full edit page stays the only way to change kind-dependent fields.

**Architecture:** Extract the table row into a `_question_row` partial shared by the index view and a new turbo_stream response on the existing `Admin::DiagnosticQuestionsController#update` action. A Stimulus controller (`inline-edit`) turns a clicked cell into an input, PATCHes the change via `fetch` with `Accept: text/vnd.turbo-stream.html`, and lets Turbo apply the returned `<turbo-stream>` that replaces the row (success, or failure with the field still in edit mode plus an inline error).

**Tech Stack:** Rails 7, turbo-rails 2.0.16, Stimulus (importmap, eager-loaded from `app/javascript/controllers`), Minitest + `ActionDispatch::IntegrationTest`, Tailwind.

**Spec:** `docs/superpowers/specs/2026-06-27-diagnostic-questions-inline-editing-design.md`

---

### Task 1: Extract the table row into a `_question_row` partial with a stable Turbo DOM id

**Files:**
- Create: `app/views/admin/diagnostic_questions/_question_row.html.erb`
- Modify: `app/views/admin/diagnostic_questions/index.html.erb`
- Test: `test/controllers/admin/diagnostic_questions_controller_test.rb`

This is a pure refactor (no behavior change) that sets up the row as an independently-renderable, Turbo-targetable unit for later tasks.

- [ ] **Step 1: Write the failing test**

Add to `test/controllers/admin/diagnostic_questions_controller_test.rb`, inside the test class:

```ruby
  test "index renders each row with a stable turbo dom id" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "tr##{dom_id(question)}"
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb -n "/stable_turbo_dom_id/"`
Expected: FAIL — `Expected at least 1 element matching "tr#diagnostic_question_...", found 0.`

- [ ] **Step 3: Create the row partial**

Create `app/views/admin/diagnostic_questions/_question_row.html.erb` with the exact content of the current row, plus a `dom_id` on the `<tr>`:

```erb
<%# app/views/admin/diagnostic_questions/_question_row.html.erb %>
<tr id="<%= dom_id(q) %>" class="hover:bg-slate-50" data-id="<%= q.id %>">
  <% if sortable_enabled %>
    <td class="px-4 py-3 text-slate-300 cursor-grab" data-sortable-handle>
      <%= lucide_icon "grip-vertical", class: "w-4 h-4" %>
    </td>
  <% end %>
  <td class="px-4 py-3">
    <% badge_colors = { "disc" => "bg-violet-100 text-violet-700", "interest" => "bg-amber-100 text-amber-700", "skill" => "bg-emerald-100 text-emerald-700" } %>
    <span class="px-2 py-1 rounded-lg text-xs font-bold <%= badge_colors[q.kind] %>">
      <%= q.kind %><%= " · #{q.disc_type}" if q.disc_type.present? %>
    </span>
  </td>
  <td class="px-4 py-3 text-slate-700 max-w-xs truncate"><%= q.text %></td>
  <td class="px-4 py-3 text-slate-400 text-xs">
    <%= q.disc_type || q.skill_slug || (q.options.any? ? "#{q.options.length} options" : "—") %>
  </td>
  <td class="px-4 py-3 text-slate-400"><%= q.position %></td>
  <td class="px-4 py-3 flex gap-2 justify-end">
    <%= link_to "Modifier", edit_admin_assessment_diagnostic_question_path(assessment, q), class: "text-xs text-[var(--color-primary)] hover:underline" %>
    <%= button_to "Supprimer", admin_assessment_diagnostic_question_path(assessment, q), method: :delete,
          data: { turbo_confirm: "Supprimer cette question ?" },
          class: "text-xs text-red-500 hover:underline bg-transparent border-0 cursor-pointer" %>
  </td>
</tr>
```

Note this partial uses a local `assessment`, not `@assessment` — it will also be rendered from the controller (Task 2) where the instance variable name lines up but explicit locals keep the partial self-contained.

- [ ] **Step 4: Render the partial from the index view**

In `app/views/admin/diagnostic_questions/index.html.erb`, replace:

```erb
      <% @questions.each do |q| %>
        <tr class="hover:bg-slate-50" data-id="<%= q.id %>">
          <% if sortable_enabled %>
            <td class="px-4 py-3 text-slate-300 cursor-grab" data-sortable-handle>
              <%= lucide_icon "grip-vertical", class: "w-4 h-4" %>
            </td>
          <% end %>
          <td class="px-4 py-3">
            <% badge_colors = { "disc" => "bg-violet-100 text-violet-700", "interest" => "bg-amber-100 text-amber-700", "skill" => "bg-emerald-100 text-emerald-700" } %>
            <span class="px-2 py-1 rounded-lg text-xs font-bold <%= badge_colors[q.kind] %>">
              <%= q.kind %><%= " · #{q.disc_type}" if q.disc_type.present? %>
            </span>
          </td>
          <td class="px-4 py-3 text-slate-700 max-w-xs truncate"><%= q.text %></td>
          <td class="px-4 py-3 text-slate-400 text-xs">
            <%= q.disc_type || q.skill_slug || (q.options.any? ? "#{q.options.length} options" : "—") %>
          </td>
          <td class="px-4 py-3 text-slate-400"><%= q.position %></td>
          <td class="px-4 py-3 flex gap-2 justify-end">
            <%= link_to "Modifier", edit_admin_assessment_diagnostic_question_path(@assessment, q), class: "text-xs text-[var(--color-primary)] hover:underline" %>
            <%= button_to "Supprimer", admin_assessment_diagnostic_question_path(@assessment, q), method: :delete,
                  data: { turbo_confirm: "Supprimer cette question ?" },
                  class: "text-xs text-red-500 hover:underline bg-transparent border-0 cursor-pointer" %>
          </td>
        </tr>
      <% end %>
```

with:

```erb
      <%= render partial: "question_row", collection: @questions, as: :q,
            locals: { assessment: @assessment, sortable_enabled: sortable_enabled, kind_filter: @kind_filter } %>
```

(The `kind_filter` local isn't used yet — it's threaded through now so Task 2 doesn't need to touch this call site again.)

- [ ] **Step 5: Run the test to verify it passes**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb`
Expected: PASS — `15 runs, ... 0 failures, 0 errors` (14 existing + 1 new)

- [ ] **Step 6: Commit**

```bash
git add app/views/admin/diagnostic_questions/index.html.erb app/views/admin/diagnostic_questions/_question_row.html.erb test/controllers/admin/diagnostic_questions_controller_test.rb
git commit -m "Extract diagnostic question table row into its own partial"
```

---

### Task 2: Add a Turbo Stream response to the update action

**Files:**
- Modify: `app/controllers/admin/diagnostic_questions_controller.rb:29-35`
- Test: `test/controllers/admin/diagnostic_questions_controller_test.rb`

This adds backend support for partial, in-place updates. No view markup changes yet — the existing row already renders correctly via the partial from Task 1, so this is independently testable.

- [ ] **Step 1: Write the failing tests**

Add to `test/controllers/admin/diagnostic_questions_controller_test.rb`, inside the test class:

```ruby
  test "update via turbo stream replaces the row with the new text" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Texte original", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { text: "Texte corrigé" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action=replace][target=?]", dom_id(question)
    assert_match "Texte corrigé", response.body
    assert_equal "Texte corrigé", question.reload.text
  end

  test "update via turbo stream replaces the row with the new position" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { position: 5 } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal 5, question.reload.position
  end

  test "update via turbo stream toggles active" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { active: "0" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal false, question.reload.active
  end

  test "update via turbo stream with blank text re-renders the row with an inline error" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { text: "" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :unprocessable_content
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match "doit être rempli(e)", response.body
    assert_equal "Une question", question.reload.text
  end

  test "update via turbo stream carries the current kind filter to keep the drag handle column consistent" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { text: "Texte corrigé" }, kind: "interest" },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_select "[data-sortable-handle]", count: 1
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb -n "/turbo_stream/"`
Expected: FAIL — the plain HTML `update` action redirects regardless of `Accept`, so `response.media_type` will be `"text/html"`, not `"text/vnd.turbo-stream.html"`.

- [ ] **Step 3: Implement the turbo_stream response**

In `app/controllers/admin/diagnostic_questions_controller.rb`, replace:

```ruby
  def update
    if @question.update(question_params)
      redirect_to redirect_path, notice: "Question mise à jour.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end
```

with:

```ruby
  def update
    @kind_filter = params[:kind].presence || "all"
    sortable_enabled = @kind_filter != "all"
    row_locals = { q: @question, assessment: @assessment, sortable_enabled: sortable_enabled, kind_filter: @kind_filter }

    respond_to do |format|
      if @question.update(question_params)
        format.html { redirect_to redirect_path, notice: "Question mise à jour.", status: :see_other }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@question, partial: "question_row", locals: row_locals) }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@question, partial: "question_row", locals: row_locals.merge(inline_errors: @question.errors)),
                 status: :unprocessable_content
        end
      end
    end
  end
```

- [ ] **Step 4: Make the partial accept an optional `inline_errors` local**

In `app/views/admin/diagnostic_questions/_question_row.html.erb`, add this line at the very top (the partial doesn't use `inline_errors` for anything yet — that comes in Task 4 — but the local must exist so passing it doesn't raise):

```erb
<% inline_errors ||= nil %>
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb`
Expected: PASS — `20 runs, ... 0 failures, 0 errors` (15 + 5 new)

- [ ] **Step 6: Commit**

```bash
git add app/controllers/admin/diagnostic_questions_controller.rb app/views/admin/diagnostic_questions/_question_row.html.erb test/controllers/admin/diagnostic_questions_controller_test.rb
git commit -m "Respond to turbo_stream updates on diagnostic questions"
```

---

### Task 3: Add the inline-edit Stimulus controller

**Files:**
- Create: `app/javascript/controllers/inline_edit_controller.js`

No Ruby/Minitest coverage applies to a plain Stimulus controller (this repo has no JS test runner — confirmed: no `package.json`, no jest/JS test config). This controller is exercised by the markup wired up in Tasks 4–6 and confirmed working in the manual browser pass in Task 7.

- [ ] **Step 1: Create the controller**

Create `app/javascript/controllers/inline_edit_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

// Turns a table cell into an input on click, and PATCHes the change as a
// Turbo Stream request so the row re-renders in place (success or with an
// inline validation error) without a page navigation.
export default class extends Controller {
  static targets = ["display", "field"]
  static values = { url: String, param: String, kindFilter: String }

  edit() {
    this.displayTarget.hidden = true
    this.fieldTarget.hidden = false
    this.fieldTarget.focus()
    this.fieldTarget.select()
  }

  cancel() {
    this.fieldTarget.value = this.fieldTarget.defaultValue
    this.fieldTarget.hidden = true
    this.displayTarget.hidden = false
  }

  save(event) {
    if (event.type === "keydown") event.preventDefault()

    if (this.fieldTarget.value === this.fieldTarget.defaultValue) {
      this.fieldTarget.hidden = true
      this.displayTarget.hidden = false
      return
    }

    this.submit(this.fieldTarget.value)
  }

  toggle(event) {
    this.submit(event.target.checked ? "1" : "0")
  }

  submit(value) {
    const data = new FormData()
    data.append(`diagnostic_question[${this.paramValue}]`, value)
    if (this.kindFilterValue) data.append("kind", this.kindFilterValue)

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: data
    })
      .then(response => response.text())
      .then(html => window.Turbo.renderStreamMessage(html))
      .catch(error => console.error("Error saving inline edit", error))
  }
}
```

This file is eager-loaded automatically by `app/javascript/controllers/index.js` (`eagerLoadControllersFrom("controllers", application)`) — no registration step needed.

- [ ] **Step 2: Commit**

```bash
git add app/javascript/controllers/inline_edit_controller.js
git commit -m "Add inline-edit Stimulus controller"
```

---

### Task 4: Wire the question text cell to inline editing

**Files:**
- Modify: `app/views/admin/diagnostic_questions/_question_row.html.erb`
- Test: `test/controllers/admin/diagnostic_questions_controller_test.rb`

- [ ] **Step 1: Write the failing test**

Add to `test/controllers/admin/diagnostic_questions_controller_test.rb`:

```ruby
  test "index wires the question text cell to inline editing" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "td[data-controller=?][data-inline-edit-param-value=?] textarea[hidden]", "inline-edit", "text"
  end

  test "update via turbo stream with blank text keeps the text field visible with the error" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { text: "" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_select "td[data-inline-edit-param-value=?] textarea:not([hidden])", "text"
    assert_select "td[data-inline-edit-param-value=?] span[hidden]", "text"
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb -n "/inline_editing|keeps_the_text_field/"`
Expected: FAIL — no `data-controller="inline-edit"` exists yet on the text cell.

- [ ] **Step 3: Wire the cell**

In `app/views/admin/diagnostic_questions/_question_row.html.erb`, replace:

```erb
  <td class="px-4 py-3 text-slate-700 max-w-xs truncate"><%= q.text %></td>
```

with:

```erb
  <% text_invalid = inline_errors&.key?(:text) %>
  <td class="px-4 py-3 text-slate-700 max-w-xs" data-controller="inline-edit"
      data-inline-edit-url-value="<%= admin_assessment_diagnostic_question_path(assessment, q) %>"
      data-inline-edit-param-value="text"
      data-inline-edit-kind-filter-value="<%= kind_filter %>">
    <span data-inline-edit-target="display" data-action="click->inline-edit#edit"
          class="truncate block cursor-pointer" title="Cliquer pour modifier" <%= "hidden" if text_invalid %>><%= q.text %></span>
    <textarea data-inline-edit-target="field" rows="2"
              data-action="blur->inline-edit#save keydown.esc->inline-edit#cancel"
              class="w-full border border-slate-200 rounded-lg px-2 py-1 text-sm"
              <%= "hidden" unless text_invalid %>><%= q.text %></textarea>
    <% if text_invalid %>
      <p class="text-red-500 text-xs mt-1"><%= inline_errors[:text].first %></p>
    <% end %>
  </td>
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb`
Expected: PASS — `22 runs, ... 0 failures, 0 errors` (20 + 2 new)

- [ ] **Step 5: Commit**

```bash
git add app/views/admin/diagnostic_questions/_question_row.html.erb test/controllers/admin/diagnostic_questions_controller_test.rb
git commit -m "Wire the question text cell to inline editing"
```

---

### Task 5: Wire the position cell to inline editing

**Files:**
- Modify: `app/views/admin/diagnostic_questions/_question_row.html.erb`
- Test: `test/controllers/admin/diagnostic_questions_controller_test.rb`

- [ ] **Step 1: Write the failing test**

Add to `test/controllers/admin/diagnostic_questions_controller_test.rb`:

```ruby
  test "index wires the position cell to inline editing" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "td[data-controller=?][data-inline-edit-param-value=?] input[type=number][hidden]", "inline-edit", "position"
  end

  test "update via turbo stream with invalid position keeps the position field visible with the error" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { position: 0 } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_select "td[data-inline-edit-param-value=?] input:not([hidden])", "position"
    assert_match "doit être supérieur à 0", response.body
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb -n "/position_cell_to_inline|invalid_position/"`
Expected: FAIL — no `data-controller="inline-edit"` exists yet on the position cell.

- [ ] **Step 3: Wire the cell**

In `app/views/admin/diagnostic_questions/_question_row.html.erb`, replace:

```erb
  <td class="px-4 py-3 text-slate-400"><%= q.position %></td>
```

with:

```erb
  <% position_invalid = inline_errors&.key?(:position) %>
  <td class="px-4 py-3 text-slate-400" data-controller="inline-edit"
      data-inline-edit-url-value="<%= admin_assessment_diagnostic_question_path(assessment, q) %>"
      data-inline-edit-param-value="position"
      data-inline-edit-kind-filter-value="<%= kind_filter %>">
    <span data-inline-edit-target="display" data-action="click->inline-edit#edit"
          class="cursor-pointer" <%= "hidden" if position_invalid %>><%= q.position %></span>
    <input type="number" min="1" data-inline-edit-target="field"
           data-action="blur->inline-edit#save keydown.enter->inline-edit#save keydown.esc->inline-edit#cancel"
           class="w-16 border border-slate-200 rounded-lg px-2 py-1 text-sm"
           value="<%= q.position %>" <%= "hidden" unless position_invalid %>>
    <% if position_invalid %>
      <p class="text-red-500 text-xs mt-1"><%= inline_errors[:position].first %></p>
    <% end %>
  </td>
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb`
Expected: PASS — `24 runs, ... 0 failures, 0 errors` (22 + 2 new)

- [ ] **Step 5: Commit**

```bash
git add app/views/admin/diagnostic_questions/_question_row.html.erb test/controllers/admin/diagnostic_questions_controller_test.rb
git commit -m "Wire the position cell to inline editing"
```

---

### Task 6: Add an inline-editable Active column

**Files:**
- Modify: `app/views/admin/diagnostic_questions/index.html.erb`
- Modify: `app/views/admin/diagnostic_questions/_question_row.html.erb`
- Test: `test/controllers/admin/diagnostic_questions_controller_test.rb`

The table currently has no "Active" column at all (it exists only on the full edit form). This task adds one, wired to the toggle action of the same `inline-edit` controller.

- [ ] **Step 1: Write the failing tests**

Add to `test/controllers/admin/diagnostic_questions_controller_test.rb`:

```ruby
  test "index shows an active checkbox reflecting each question's state" do
    active_q = @assessment.diagnostic_questions.create!(kind: "interest", text: "Active", position: 1, active: true, academic_field_slug: "langues")
    inactive_q = @assessment.diagnostic_questions.create!(kind: "interest", text: "Inactive", position: 2, active: false, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "tr##{dom_id(active_q)} input[type=checkbox][checked]"
    assert_select "tr##{dom_id(inactive_q)} input[type=checkbox]:not([checked])"
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb -n "/active_checkbox/"`
Expected: FAIL — no checkbox exists in the table yet.

- [ ] **Step 3: Add the column header**

In `app/views/admin/diagnostic_questions/index.html.erb`, replace:

```erb
        <th class="px-4 py-3 text-left text-xs font-bold uppercase tracking-widest text-slate-400">Pos.</th>
        <th class="px-4 py-3"></th>
```

with:

```erb
        <th class="px-4 py-3 text-left text-xs font-bold uppercase tracking-widest text-slate-400">Pos.</th>
        <th class="px-4 py-3 text-center text-xs font-bold uppercase tracking-widest text-slate-400">Active</th>
        <th class="px-4 py-3"></th>
```

- [ ] **Step 4: Add the checkbox cell to the row partial**

In `app/views/admin/diagnostic_questions/_question_row.html.erb`, replace:

```erb
  <td class="px-4 py-3 flex gap-2 justify-end">
```

with:

```erb
  <td class="px-4 py-3 text-center" data-controller="inline-edit"
      data-inline-edit-url-value="<%= admin_assessment_diagnostic_question_path(assessment, q) %>"
      data-inline-edit-param-value="active"
      data-inline-edit-kind-filter-value="<%= kind_filter %>">
    <input type="checkbox" data-action="change->inline-edit#toggle"
           class="rounded border-slate-300 text-primary focus:ring-primary w-4 h-4 cursor-pointer"
           <%= "checked" if q.active %>>
  </td>
  <td class="px-4 py-3 flex gap-2 justify-end">
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb`
Expected: PASS — `25 runs, ... 0 failures, 0 errors` (24 + 1 new)

- [ ] **Step 6: Commit**

```bash
git add app/views/admin/diagnostic_questions/index.html.erb app/views/admin/diagnostic_questions/_question_row.html.erb test/controllers/admin/diagnostic_questions_controller_test.rb
git commit -m "Add an inline-editable Active column to the diagnostic questions table"
```

---

### Task 7: Manual browser verification

**Files:** none (verification only)

This feature is a client-side interaction (click a cell, type, blur, watch it save) that Minitest's `ActionDispatch::IntegrationTest` cannot exercise end-to-end. Verify it for real before calling the feature done.

- [ ] **Step 1: Run the full test suite**

Run: `bin/rails test`
Expected: all tests pass, including everything added in Tasks 1–6.

- [ ] **Step 2: Start the dev server**

Run: `bin/dev`

- [ ] **Step 3: Exercise the feature in a real browser**

Navigate to `/admin/assessments/:id/diagnostic_questions` for an assessment with at least one question of each kind (use the seeded/admin data already in the dev database), then:

1. Click a question's text → confirm it turns into a textarea with the full untruncated text, focused and selected.
2. Edit the text, click elsewhere (blur) → confirm the row updates in place with the new text and no page reload (check the URL bar doesn't flash/reload).
3. Click a position number → edit it, press Enter → confirm it saves (Enter should *not* insert a newline the way it would in the text field).
4. Click the text cell, clear it entirely, blur → confirm the cell stays in edit mode, shows "doit être rempli(e)" in red, and the original text is not lost from the database (refresh the page to confirm the persisted value didn't change).
5. Toggle the Active checkbox off and on → confirm each toggle persists (refresh the page to confirm).
6. Filter the table to a single kind (e.g. "DISC") so the drag-handle column appears, then edit that kind's text/position inline → confirm the row keeps its drag handle after the inline save (this exercises the `kind_filter` round-trip from Task 2's last test).
7. Drag-reorder two rows via the handle, then inline-edit one of them → confirm both features keep working side by side.

- [ ] **Step 4: Report back**

Confirm in the conversation which of the above passed, and paste/describe anything that didn't behave as expected so it can be fixed before merging.
