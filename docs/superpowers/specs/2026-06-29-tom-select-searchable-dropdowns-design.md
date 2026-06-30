# Searchable selects via Tom Select — design

## Problem

`shared/form_field`'s `"select"` type renders a plain native `<select>`. For long option lists — `trajectories#career_id` lists every métier with no filtering — finding the right entry means scrolling through a native dropdown. We want Chosen/Select2-style search-as-you-type and a clear ("x") button, applied consistently wherever `shared/form_field` renders a select, without touching the two current call sites (`admin/careers/_form`, `admin/trajectories/_form`).

Chosen.js itself is jQuery-based and unmaintained, so we use **Tom Select** — a modern, dependency-free, actively maintained equivalent — pinned via importmap the same way `sortablejs` already is.

## Scope

In scope:
- `shared/form_field`'s `"select"` branch gets the enhancement unconditionally — no new local/flag needed, both existing call sites (`career_id`, `status`, `academic_field_slug`) upgrade automatically.
- Search-as-you-type filtering and a clear button, single-selection only.
- Custom CSS matching the app's existing input look (slate border, `gabon-blue` focus ring), not Tom Select's bundled theme.

Out of scope (deferred, no current need):
- Multi-select / tag selection.
- A per-field opt-out — if a future select genuinely shouldn't be enhanced (e.g. a 2-option toggle), that's a future flag added when it's actually needed.

## 1. Pin Tom Select via importmap

Run `./bin/importmap pin tom-select`, adding a line to `config/importmap.rb` next to the existing `pin "sortablejs"`. No CSS import from the package — styling is custom (see §4).

## 2. New Stimulus controller: `tom_select_controller.js`

```js
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    this.tomSelect = new TomSelect(this.element, { plugins: ["clear_button"] })
  }

  disconnect() {
    this.tomSelect.destroy()
  }
}
```

Tom Select attaches directly to the `<select>` and reads its existing `<option>` tags — no options data needs to be passed through Stimulus values. `disconnect()` destroys the instance on Turbo navigation, mirroring the existing `sortable_controller.js` lifecycle pattern.

## 3. Wire into `shared/_form_field.html.erb`

In the `"select"` branch, merge a `tom-select` controller into the `data` hash passed to `form.select`, additive with whatever `local_assigns[:data]` already carries (so it composes if a field also needs another controller):

```erb
<% select_data = (local_assigns[:data] || {}).dup %>
<% select_data[:controller] = [select_data[:controller], "tom-select"].compact.join(" ") %>
<%= form.select field, local_assigns[:options] || [], select_options, { class: "#{input_classes} cursor-pointer", data: select_data } %>
```

No changes needed at either call site (`admin/careers/_form.html.erb`, `admin/trajectories/_form.html.erb`).

## 4. Styling: `app/assets/tailwind/tom_select.css`

New file, imported from `application.css` the same way `assessment.css`/`results.css` already are (`@import "./tom_select.css";`). Targets Tom Select's generated DOM classes — `.ts-wrapper`, `.ts-control`, `.ts-dropdown`, `.ts-dropdown .option`, `.ts-control .item`, `.clear-button` — to match the existing input look: slate border, `rounded-md`, `shadow-sm`, `gabon-blue` focus ring on the control; white background with slate borders and a brand-colored hover/active state on dropdown options.

## 5. Behavior notes

- The native `<select>` stays in the DOM (hidden by Tom Select), so any existing or future Stimulus `data-action="change->..."` binding on the field keeps working — Tom Select dispatches a native `change` event on it when the selection changes.
- Rails' `prompt:` and `include_blank:` both render as an empty-value first `<option>`. Tom Select's default behavior treats that as a placeholder (hidden from the dropdown list, shown when nothing's selected) — matching native `<select>` behavior already in use today. The new clear button gives an explicit way to reset back to it, covering the `include_blank` case (e.g. `academic_field_slug`'s "— choisir —") without extra config.
- If the Tom Select asset fails to load for any reason, the field stays a plain native `<select>` — forms keep working, just without the enhancement.

## 6. Testing

This project's test suite is controller tests only (no Capybara/system tests — see `test/` directory). This change is JS/CSS-only: it doesn't alter controller params, validations, or any persisted behavior, so no new automated test is added, consistent with how prior pure-styling changes in this codebase were handled.

Verify manually after implementation: load `admin/trajectories/new`, confirm typing filters the métier list and the clear button resets `career_id`; load `admin/careers/new`, confirm `status` and `academic_field_slug` selects render and behave correctly (including `include_blank`'s clear-to-blank).
