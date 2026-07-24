# Diagnostic Audit Score Overview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the top of `admin/diagnostics#show` so an admin auditing a diagnostic sees a compact, expandable score-overview card per career (the 2 retained plus the 3rd/non-retained candidate) and can filter the answer list by category or "counted toward the score."

**Architecture:** Pure presentation layer change on top of data already persisted by `Diagnostics::PreScoringService`/`Diagnostics::ScoringService`. Extend `Diagnostics::AnswerAttributionPresenter` to expose a 3rd attribution and a per-category breakdown; add a new view partial for the score cards; add one small Stimulus controller for client-side answer filtering. No migrations, no new endpoints.

**Tech Stack:** Rails 8, ERB views, Tailwind (existing `glass-card`/`shadow-premium`/`--color-primary` design system), Stimulus, Minitest (`ActiveSupport::TestCase` / `ActionDispatch::IntegrationTest`, `assert_select`).

**Spec:** `docs/superpowers/specs/2026-07-21-diagnostic-audit-score-overview-design.md`

---

### Task 1: Presenter — 3rd candidate + category breakdown

**Files:**
- Modify: `app/services/diagnostics/answer_attribution_presenter.rb`
- Test: `test/services/diagnostics/answer_attribution_presenter_test.rb`

This task only touches the presenter. `recap_line` and its call site in the view are left untouched for now (removed together with the view rewrite in Task 2) so the app stays in a working state after this task's commit.

- [ ] **Step 1: Write the failing tests**

Add these tests to `test/services/diagnostics/answer_attribution_presenter_test.rb`, inside the existing `Diagnostics::AnswerAttributionPresenterTest` class (after the `"is unavailable when score_data lacks the match breakdown (legacy diagnostic)"` test). They rely on a 3rd career existing in `top_career_ids` beyond the 2 already set up in `setup` — add it via `@diagnostic.update!` inside each test rather than changing shared `setup`, to keep the existing tests' fixtures untouched.

```ruby
test "overview_cards includes the 3rd-ranked candidate as a non-retained attribution" do
  third = Career.create!(title: "Guide touristique #{SecureRandom.hex(4)}", status: :published,
                          academic_field_slug: "tourisme", disc_types: [ "S" ], required_skills: [])
  @diagnostic.score_data["top_career_ids"] << {
    "id" => third.id, "score" => 6,
    "disc_match" => 0, "academic_field_match" => 0, "comp_match" => 6,
    "matched_disc_types" => [], "matched_skills" => { "guidage" => 6 }
  }
  @diagnostic.save!
  presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)

  labels = presenter.overview_cards.map { |c| c[:label] }
  assert_equal [ "Métier 1", "Métier 2", "Non retenu" ], labels

  third_card = presenter.overview_cards.last
  assert_equal third, third_card[:career]
  assert_equal 6, third_card[:total]
  assert_equal false, third_card[:has_affirmation_data]
end

test "overview_cards omits the 3rd candidate when only 2 candidates exist" do
  presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)

  assert_equal [ "Métier 1", "Métier 2" ], presenter.overview_cards.map { |c| c[:label] }
end

test "overview_cards omits the 3rd candidate when it lacks breakdown data" do
  third = Career.create!(title: "Guide touristique #{SecureRandom.hex(4)}", status: :published,
                          academic_field_slug: "tourisme", disc_types: [], required_skills: [])
  @diagnostic.score_data["top_career_ids"] << { "id" => third.id, "score" => 6 }
  @diagnostic.save!
  presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)

  assert_equal [ "Métier 1", "Métier 2" ], presenter.overview_cards.map { |c| c[:label] }
end

test "category_breakdown reports DISC max as the number of dominant DISC types times 3" do
  presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)
  primary_card = presenter.overview_cards.first

  disc_row = primary_card[:categories].find { |c| c[:label] == "DISC" }
  assert_equal({ label: "DISC", points: 3, max: 3 }, disc_row)
end

test "category_breakdown reports Intérêts with a fixed max of 5" do
  presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)
  primary_card = presenter.overview_cards.first

  interest_row = primary_card[:categories].find { |c| c[:label] == "Intérêts" }
  assert_equal({ label: "Intérêts", points: 5, max: 5 }, interest_row)
end

test "category_breakdown reports Compétences with no max" do
  presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)
  primary_card = presenter.overview_cards.first

  skill_row = primary_card[:categories].find { |c| c[:label] == "Compétences" }
  assert_equal({ label: "Compétences", points: 5, max: nil }, skill_row)
end

test "category_breakdown includes the affirmation bonus row only when affirmation data exists" do
  presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)
  primary_card, secondary_card = presenter.overview_cards

  assert primary_card[:categories].any? { |c| c[:label] == "Bonus affirmations" }
  assert_equal({ label: "Bonus affirmations", points: 2, max: 3 },
               primary_card[:categories].find { |c| c[:label] == "Bonus affirmations" })
  assert_not secondary_card[:categories].any? { |c| c[:label] == "Bonus affirmations" }
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/services/diagnostics/answer_attribution_presenter_test.rb`
Expected: FAIL — `NoMethodError: undefined method 'overview_cards'` (and `category_breakdown`) for the new tests; all pre-existing tests in this file still PASS.

- [ ] **Step 3: Implement**

Replace the full contents of `app/services/diagnostics/answer_attribution_presenter.rb` with:

```ruby
module Diagnostics
  class AnswerAttributionPresenter
    Attribution = Struct.new(:label, :career, :entry, :affirmation, :retained, keyword_init: true)

    def initialize(diagnostic)
      @diagnostic   = diagnostic
      @score_data   = diagnostic.score_data.is_a?(Hash) ? diagnostic.score_data : {}
      @attributions = build_attributions
    end

    def available?
      @attributions.any?
    end

    def recap_line
      return nil unless available?

      @attributions.map { |a| "#{a.label} : #{final_score(a)} pts" }.join(" · ")
    end

    def overview_cards
      @attributions.map do |attribution|
        {
          label:                attribution.label,
          career:               attribution.career,
          total:                final_score(attribution),
          categories:           category_breakdown(attribution),
          has_affirmation_data: attribution.affirmation.present?
        }
      end
    end

    def category_breakdown(attribution)
      entry = attribution.entry
      dominant_disc_count = Array(@score_data["dominant_disc_types"]).size

      rows = [
        { label: "DISC",        points: entry["disc_match"].to_i,           max: dominant_disc_count * 3 },
        { label: "Intérêts",    points: entry["academic_field_match"].to_i, max: 5 },
        { label: "Compétences", points: entry["comp_match"].to_i,           max: nil }
      ]

      if attribution.affirmation.present?
        rows << {
          label:  "Bonus affirmations",
          points: attribution.affirmation["bonus"].to_i,
          max:    attribution.affirmation["max_bonus"].to_i
        }
      end

      rows
    end

    def badges_for(answer)
      question = answer.diagnostic_question
      return [] unless question

      @attributions.filter_map do |attribution|
        points = points_for(attribution, question)
        next unless points

        { label: attribution.label, points: points }
      end
    end

    def affirmation_rows
      @attributions.flat_map do |attribution|
        Array(attribution.affirmation&.dig("checked_affirmations")).map do |text|
          { label: attribution.label, text: text }
        end
      end
    end

    private

    def build_attributions
      top_career_ids = @score_data["top_career_ids"]
      return [] unless top_career_ids.is_a?(Array)

      retained = [ [ "Métier 1", @diagnostic.primary_career ], [ "Métier 2", @diagnostic.complementary_career ] ].filter_map do |label, career|
        next unless career

        entry = top_career_ids.find { |h| h.is_a?(Hash) && h["id"].to_s == career.id.to_s }
        next unless entry && entry.key?("disc_match")

        affirmation = @score_data.dig("affirmation_breakdown", career.id.to_s)
        Attribution.new(label: label, career: career, entry: entry, affirmation: affirmation, retained: true)
      end

      retained + Array(build_third_candidate(top_career_ids, retained))
    end

    def build_third_candidate(top_career_ids, retained)
      return nil unless retained.size == 2

      retained_ids = retained.map { |a| a.career.id.to_s }
      entry = top_career_ids.find do |h|
        h.is_a?(Hash) && h["id"].present? && h.key?("disc_match") && !retained_ids.include?(h["id"].to_s)
      end
      return nil unless entry

      career = Career.find_by(id: entry["id"])
      return nil unless career

      Attribution.new(label: "Non retenu", career: career, entry: entry, affirmation: nil, retained: false)
    end

    def final_score(attribution)
      attribution.entry["score"].to_i + attribution.affirmation&.dig("bonus").to_i
    end

    def points_for(attribution, question)
      case question.kind
      when "disc"
        3 if Array(attribution.entry["matched_disc_types"]).include?(question.disc_type)
      when "interest"
        return nil unless @score_data["dominant_academic_field"] == question.academic_field_slug
        5 if attribution.career.academic_field_slug == question.academic_field_slug
      when "skill"
        attribution.entry.dig("matched_skills", question.skill_slug)
      end
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bin/rails test test/services/diagnostics/answer_attribution_presenter_test.rb`
Expected: PASS (all tests, old and new).

- [ ] **Step 5: Commit**

```bash
git add app/services/diagnostics/answer_attribution_presenter.rb test/services/diagnostics/answer_attribution_presenter_test.rb
git commit -m "feat: expose 3rd-candidate career and category breakdown in diagnostic attribution"
```

---

### Task 2: Score overview partial, wired into the show page

**Files:**
- Create: `app/views/admin/diagnostics/_score_overview.html.erb`
- Modify: `app/views/admin/diagnostics/show.html.erb:45-59` (removes the old recap line, inserts the new partial)
- Modify: `app/services/diagnostics/answer_attribution_presenter.rb` (remove `recap_line`, now unused)
- Test: `test/services/diagnostics/answer_attribution_presenter_test.rb` (remove `recap_line` tests)
- Test: `test/controllers/admin/diagnostics_controller_test.rb`

- [ ] **Step 1: Write the failing test**

In `test/controllers/admin/diagnostics_controller_test.rb`, replace the test named `"show renders the recap line, per-answer badge, and affirmation row for a fully scored diagnostic"` with:

```ruby
test "show renders the score overview cards and affirmation row for a fully scored diagnostic" do
  @diagnostic.update!(score_data: {
    "dominant_disc_types"     => [ "D" ],
    "dominant_academic_field" => nil,
    "top_career_ids" => [
      {
        "id" => @primary.id, "score" => 3,
        "disc_match" => 3, "academic_field_match" => 0, "comp_match" => 0,
        "matched_disc_types" => [ "D" ], "matched_skills" => {}
      },
      {
        "id" => @secondary.id, "score" => 0,
        "disc_match" => 0, "academic_field_match" => 0, "comp_match" => 0,
        "matched_disc_types" => [], "matched_skills" => {}
      }
    ],
    "affirmation_breakdown" => {
      @primary.id.to_s => { "checked_affirmations" => [ "a" ], "bonus" => 1, "max_bonus" => 2 }
    }
  })

  get admin_diagnostic_path(@diagnostic)

  assert_response :success
  assert_select "div", text: /Métier 1/
  assert_select "div", text: /Métier 2/
  assert_select "details", count: 2
  assert_select ".bg-indigo-50", text: /Métier 1 · \+3 pts/
  assert_select "p", text: /Affirmation validée pour Métier 1 : « a »/
end
```

Also update the legacy test `"show renders the plain answer list without scoring badges for a legacy diagnostic"` to additionally assert no score cards render — add this line right after the existing `assert_select ".bg-indigo-50", count: 0`:

```ruby
  assert_select "details", count: 0
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/admin/diagnostics_controller_test.rb`
Expected: FAIL on the new "score overview cards" test — the page still renders the old one-line recap, not `<details>` elements (`assert_select "details", count: 2` fails, found 0).

- [ ] **Step 3: Create the partial**

Create `app/views/admin/diagnostics/_score_overview.html.erb`:

```erb
<%#
  Usage: render "admin/diagnostics/score_overview", attribution: @attribution
%>
<% if attribution.available? %>
  <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8 animate-premium-in">
    <% attribution.overview_cards.each do |card| %>
      <div class="glass-card rounded-2xl p-6 shadow-premium <%= "opacity-70" if card[:label] == "Non retenu" %>">
        <div class="flex items-start justify-between mb-4">
          <div>
            <div class="text-[10px] font-black uppercase text-slate-400 tracking-wide"><%= card[:label] %></div>
            <div class="text-base font-bold text-slate-800 mt-1"><%= card[:career].title %></div>
          </div>
          <div class="text-2xl font-black text-[var(--color-primary)]"><%= card[:total] %></div>
        </div>

        <p class="text-[11px] font-semibold text-slate-400">
          <%= card[:categories].map { |c| "#{c[:label]} #{c[:points]}" }.join(" · ") %>
        </p>

        <details class="mt-4 group">
          <summary class="text-[10px] font-black text-[var(--color-primary)] cursor-pointer list-none">
            Voir le détail ▾
          </summary>
          <dl class="mt-4 pt-4 border-t border-slate-100 space-y-2">
            <% card[:categories].each do |c| %>
              <div class="flex items-center justify-between text-xs">
                <dt class="font-bold text-slate-500"><%= c[:label] %></dt>
                <dd class="font-black text-slate-700"><%= c[:max] ? "#{c[:points]} / #{c[:max]}" : c[:points] %></dd>
              </div>
            <% end %>
          </dl>
          <% unless card[:has_affirmation_data] %>
            <p class="mt-3 text-[10px] font-medium text-slate-400 italic">
              Score de base, sans bonus affirmations (non proposées pour ce métier).
            </p>
          <% end %>
        </details>
      </div>
    <% end %>
  </div>
<% end %>
```

- [ ] **Step 4: Wire the partial into `show.html.erb` and remove the old recap markup**

In `app/views/admin/diagnostics/show.html.erb`, the current lines 45-59 are:

```erb
  <!-- Bottom Side: Answers -->
  <div>
    <div class="glass-card rounded-[2rem] shadow-premium min-h-[600px]">
      <div class="animate-premium-in">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-8 pb-6 border-b border-slate-100">
          <div>
            <h3 class="text-xl font-bold text-slate-800">Détail des Réponses</h3>
            <p class="text-slate-400 text-xs font-medium mt-1">Réponses du diagnostic</p>
          </div>
          <% if @attribution.available? %>
            <div class="text-xs font-bold text-slate-500 tracking-wide">
              <%= @attribution.recap_line %>
            </div>
          <% end %>
        </div>
```

Replace them with:

```erb
  <%= render "admin/diagnostics/score_overview", attribution: @attribution %>

  <!-- Bottom Side: Answers -->
  <div>
    <div class="glass-card rounded-[2rem] shadow-premium min-h-[600px]">
      <div class="animate-premium-in">
        <div class="mb-8 pb-6 border-b border-slate-100">
          <h3 class="text-xl font-bold text-slate-800">Détail des Réponses</h3>
          <p class="text-slate-400 text-xs font-medium mt-1">Réponses du diagnostic</p>
        </div>
```

(The score recap that used to sit in this header is now the dedicated overview section above; the header keeps just the title/subtitle.)

- [ ] **Step 5: Remove the now-unused `recap_line` method and its tests**

In `app/services/diagnostics/answer_attribution_presenter.rb`, delete the `recap_line` method:

```ruby
    def recap_line
      return nil unless available?

      @attributions.map { |a| "#{a.label} : #{final_score(a)} pts" }.join(" · ")
    end

```

In `test/services/diagnostics/answer_attribution_presenter_test.rb`, delete this test entirely:

```ruby
  test "recap_line shows each career's final score including affirmation bonus" do
    assert_equal "Métier 1 : 15 pts · Métier 2 : 0 pts", @presenter.recap_line
  end

```

And in the legacy test (`"is unavailable when score_data lacks the match breakdown (legacy diagnostic)"`), remove this line:

```ruby
    assert_nil presenter.recap_line
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bin/rails test test/controllers/admin/diagnostics_controller_test.rb test/services/diagnostics/answer_attribution_presenter_test.rb`
Expected: PASS (all tests).

- [ ] **Step 7: Commit**

```bash
git add app/views/admin/diagnostics/_score_overview.html.erb app/views/admin/diagnostics/show.html.erb app/services/diagnostics/answer_attribution_presenter.rb test/services/diagnostics/answer_attribution_presenter_test.rb test/controllers/admin/diagnostics_controller_test.rb
git commit -m "feat: replace diagnostic score recap line with expandable per-career overview cards"
```

---

### Task 3: Answer-list category filter

**Files:**
- Create: `app/javascript/controllers/answer_filter_controller.js`
- Modify: `app/views/admin/diagnostics/show.html.erb` (current lines 61-116, the answers list block)
- Test: `test/controllers/admin/diagnostics_controller_test.rb`

- [ ] **Step 1: Write the failing test**

Add this test to `test/controllers/admin/diagnostics_controller_test.rb`:

```ruby
test "show renders the answer filter bar with category data attributes on each row" do
  get admin_diagnostic_path(@diagnostic)

  assert_response :success
  assert_select "[data-controller='answer-filter']"
  assert_select "[data-answer-filter-filter-param='disc']"
  assert_select "[data-answer-filter-filter-param='scored']"
  assert_select "[data-category='disc'][data-scored]"
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/admin/diagnostics_controller_test.rb -n test_show_renders_the_answer_filter_bar_with_category_data_attributes_on_each_row`
Expected: FAIL — none of these `data-*` attributes exist yet.

- [ ] **Step 3: Create the Stimulus controller**

Create `app/javascript/controllers/answer_filter_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

// Filters the diagnostic answer list client-side: no server round-trip,
// since every answer is already rendered in one response (no pagination here).
export default class extends Controller {
  static targets = ["row", "button"]
  static classes = ["active", "inactive"]

  filter(event) {
    const selected = event.params.filter

    this.buttonTargets.forEach(button => {
      const isSelected = button === event.currentTarget
      this.activeClasses.forEach(c => button.classList.toggle(c, isSelected))
      this.inactiveClasses.forEach(c => button.classList.toggle(c, !isSelected))
    })

    this.rowTargets.forEach(row => {
      const matches =
        selected === "all" ||
        (selected === "scored" ? row.dataset.scored === "true" : row.dataset.category === selected)
      row.hidden = !matches
    })
  }
}
```

- [ ] **Step 4: Wire the filter bar and row data attributes into `show.html.erb`**

The current answers block (lines 61-116) reads:

```erb
        <% affirmation_rows = @attribution.affirmation_rows %>
        <% if @answers.any? || affirmation_rows.any? %>
          <div class="space-y-4">
            <% @answers.each_with_index do |answer, idx| %>
              <div class="p-6 rounded-2xl bg-white border border-slate-100 hover:border-[var(--color-primary)]/20 hover:shadow-premium-sm transition-all group">
                <div class="flex gap-4">
                  <div class="flex-shrink-0 w-8 h-8 rounded-full bg-slate-50 flex items-center justify-center text-[10px] font-black text-slate-400 border border-slate-100">
                    <%= idx + 1 %>
                  </div>
                  <div class="flex-1">
                    <p class="text-slate-800 font-bold leading-relaxed mb-3">
                      <%= answer.diagnostic_question.text %>
                    </p>
                    <div class="flex flex-col items-start gap-2 mt-4">
                       <span class="text-[10px] font-black text-slate-300">Réponse :</span>
                       <span class="px-3 py-1 bg-green-50 text-green-700 text-xs font-bold rounded-lg border border-green-100">
                         <% selected_option = answer.diagnostic_question.options&.find { |o| o["value"] == answer.answer_value } %>
                         <%= selected_option ? "#{answer.answer_value}: #{selected_option['text']}" : answer.answer_value %>
                       </span>
                    </div>
                    <% badges = @attribution.badges_for(answer) %>
                    <% if badges.any? %>
                      <div class="flex flex-wrap items-center gap-2 mt-3">
                        <% badges.each do |badge| %>
                          <span class="px-2.5 py-1 bg-indigo-50 text-indigo-700 text-[10px] font-black rounded-lg border border-indigo-100 tracking-wide">
                            <%= badge[:label] %> · +<%= badge[:points] %> pts
                          </span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>

            <% affirmation_rows.each_with_index do |row, idx| %>
              <div class="p-6 rounded-2xl bg-white border border-slate-100 hover:border-[var(--color-primary)]/20 hover:shadow-premium-sm transition-all group">
                <div class="flex gap-4">
                  <div class="flex-shrink-0 w-8 h-8 rounded-full bg-slate-50 flex items-center justify-center text-[10px] font-black text-slate-400 border border-slate-100">
                    <%= @answers.size + idx + 1 %>
                  </div>
                  <div class="flex-1">
                    <p class="text-slate-800 font-bold leading-relaxed mb-3">
                      Affirmation validée pour <%= row[:label] %> : « <%= row[:text] %> »
                    </p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
```

Replace it with:

```erb
        <% affirmation_rows = @attribution.affirmation_rows %>
        <% if @answers.any? || affirmation_rows.any? %>
          <div data-controller="answer-filter"
               data-answer-filter-active-class="bg-white text-[var(--color-primary)] shadow-sm border border-slate-100"
               data-answer-filter-inactive-class="text-slate-400 hover:text-slate-600">
            <div class="flex flex-wrap items-center gap-1 bg-slate-100/50 p-1.5 rounded-2xl border border-slate-100 mb-6">
              <% [["all", "TOUT"], ["disc", "DISC"], ["interest", "INTÉRÊTS"], ["skill", "COMPÉTENCES"], ["scored", "A COMPTÉ DANS LE SCORE"]].each_with_index do |(value, text), i| %>
                <button type="button"
                        class="px-4 py-2 rounded-xl text-[10px] font-black transition-all duration-300 <%= i.zero? ? "bg-white text-[var(--color-primary)] shadow-sm border border-slate-100" : "text-slate-400 hover:text-slate-600" %>"
                        data-answer-filter-target="button"
                        data-action="click->answer-filter#filter"
                        data-answer-filter-filter-param="<%= value %>">
                  <%= text %>
                </button>
              <% end %>
            </div>

            <div class="space-y-4">
              <% @answers.each_with_index do |answer, idx| %>
                <% badges = @attribution.badges_for(answer) %>
                <div class="p-6 rounded-2xl bg-white border border-slate-100 hover:border-[var(--color-primary)]/20 hover:shadow-premium-sm transition-all group"
                     data-answer-filter-target="row"
                     data-category="<%= answer.diagnostic_question.kind %>"
                     data-scored="<%= badges.any? %>">
                  <div class="flex gap-4">
                    <div class="flex-shrink-0 w-8 h-8 rounded-full bg-slate-50 flex items-center justify-center text-[10px] font-black text-slate-400 border border-slate-100">
                      <%= idx + 1 %>
                    </div>
                    <div class="flex-1">
                      <p class="text-slate-800 font-bold leading-relaxed mb-3">
                        <%= answer.diagnostic_question.text %>
                      </p>
                      <div class="flex flex-col items-start gap-2 mt-4">
                         <span class="text-[10px] font-black text-slate-300">Réponse :</span>
                         <span class="px-3 py-1 bg-green-50 text-green-700 text-xs font-bold rounded-lg border border-green-100">
                           <% selected_option = answer.diagnostic_question.options&.find { |o| o["value"] == answer.answer_value } %>
                           <%= selected_option ? "#{answer.answer_value}: #{selected_option['text']}" : answer.answer_value %>
                         </span>
                      </div>
                      <% if badges.any? %>
                        <div class="flex flex-wrap items-center gap-2 mt-3">
                          <% badges.each do |badge| %>
                            <span class="px-2.5 py-1 bg-indigo-50 text-indigo-700 text-[10px] font-black rounded-lg border border-indigo-100 tracking-wide">
                              <%= badge[:label] %> · +<%= badge[:points] %> pts
                            </span>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>

              <% affirmation_rows.each_with_index do |row, idx| %>
                <div class="p-6 rounded-2xl bg-white border border-slate-100 hover:border-[var(--color-primary)]/20 hover:shadow-premium-sm transition-all group"
                     data-answer-filter-target="row"
                     data-category="affirmation"
                     data-scored="true">
                  <div class="flex gap-4">
                    <div class="flex-shrink-0 w-8 h-8 rounded-full bg-slate-50 flex items-center justify-center text-[10px] font-black text-slate-400 border border-slate-100">
                      <%= @answers.size + idx + 1 %>
                    </div>
                    <div class="flex-1">
                      <p class="text-slate-800 font-bold leading-relaxed mb-3">
                        Affirmation validée pour <%= row[:label] %> : « <%= row[:text] %> »
                      </p>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% else %>
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bin/rails test test/controllers/admin/diagnostics_controller_test.rb`
Expected: PASS (all tests in the file).

- [ ] **Step 6: Commit**

```bash
git add app/javascript/controllers/answer_filter_controller.js app/views/admin/diagnostics/show.html.erb test/controllers/admin/diagnostics_controller_test.rb
git commit -m "feat: add category filter bar to the diagnostic audit answer list"
```

---

### Task 4: Manual browser verification

This project has no system/Capybara tests, so the client-side interactions (details expand/collapse, filter bar clicks) aren't covered by an automated test — verify them by hand.

- [ ] **Step 1: Start the dev server**

Run: `bin/dev` (or `bin/rails server` + `bin/rails tailwindcss:watch` if `bin/dev` isn't set up for this project — check `Procfile.dev` first).

- [ ] **Step 2: Sign in as an admin and open a scored diagnostic**

Navigate to `/admin/diagnostics`, filter to "completed" or "paid", open one that has `primary_career`/`complementary_career` set (a diagnostic scored after this change, or any fixture/seed data with full `score_data`).

- [ ] **Step 3: Verify the score overview**

Confirm: up to 3 cards render (2 solid + 1 dimmed "Non retenu" if a 3rd candidate exists in that diagnostic's `top_career_ids`); each card's collapsed line shows `DISC · Intérêts · Compétences · Bonus` points; clicking "Voir le détail" expands a table with the same values plus max where applicable; the "Non retenu" card shows the "sans bonus affirmations" footnote.

- [ ] **Step 4: Verify the answer filter**

Confirm: clicking "DISC"/"Intérêts"/"Compétences"/"A compté dans le score" hides non-matching rows instantly (no page reload, no flash of unstyled content); clicking "Tout" restores the full list; the active button's style updates on click.

- [ ] **Step 5: Verify a legacy diagnostic still renders cleanly**

Open a diagnostic whose `score_data` predates the 06-28 breakdown work (or one missing `top_career_ids[].disc_match`). Confirm: no score overview section renders, the answer list renders as a plain list with no badges, and the filter bar still functions (all rows are unscored/uncategorized in this case, which is expected).
