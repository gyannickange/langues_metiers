# Admin Diagnostic Manageability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every field of the new diagnostic architecture editable from the admin dashboard, backed by a single source of truth for the filière / competence / DISC vocabularies.

**Architecture:** A new `Diagnostics::Vocabulary` module holds the slug→label maps. `Career` and `DiagnosticQuestion` gain virtual text accessors and vocabulary-backed validations. The three admin forms (careers, diagnostic_questions, trajectories) and their controllers are updated to expose the missing fields, with structured inputs (checkboxes, selects, newline textareas) and Stimulus-driven per-kind field toggling. Seeds and the seed integration test are repointed at the vocabulary module.

**Tech Stack:** Rails 7+, Minitest (`ActiveSupport::TestCase` for models, `ActionDispatch::IntegrationTest` for controllers), Hotwire/Stimulus (importmap, eager-loaded by filename), ERB + Tailwind.

**Spec:** `docs/superpowers/specs/2026-06-18-admin-diagnostic-manageability-design.md`

**Conventions:**
- Run a single test file: `bin/rails test test/path/to/file_test.rb`
- Run one test by name: `bin/rails test test/path/to/file_test.rb -n "/pattern/"`
- Admin login in controller tests: create a `role: :admin` user, then `post user_session_path, params: { user: { email:, password: } }`.
- Model validation error messages are French (e.g. `"doit être rempli(e)"`).

---

## Task 1: Vocabulary module (single source of truth)

**Files:**
- Create: `app/models/diagnostics/vocabulary.rb`
- Test: `test/models/diagnostics/vocabulary_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/models/diagnostics/vocabulary_test.rb`:

```ruby
require "test_helper"

class Diagnostics::VocabularyTest < ActiveSupport::TestCase
  test "filiere slugs match the eight diagnostic filieres" do
    assert_equal %w[langues geo socio lettres psycho philo histoire edu].sort,
                 Diagnostics::Vocabulary.filiere_slugs.sort
  end

  test "competence slugs cover the twelve diagnostic competences" do
    assert_equal 12, Diagnostics::Vocabulary.competence_slugs.length
    assert_includes Diagnostics::Vocabulary.competence_slugs, "langues_etrangeres"
    assert_includes Diagnostics::Vocabulary.competence_slugs, "droit_politiques"
  end

  test "disc type slugs are the four DISC letters" do
    assert_equal %w[D I S C], Diagnostics::Vocabulary.disc_type_slugs
  end

  test "option helpers return [label, slug] pairs for selects" do
    assert_equal ["Langues", "langues"], Diagnostics::Vocabulary.filiere_options.first
    assert_equal ["Dominant", "D"], Diagnostics::Vocabulary.disc_type_options.first
    label, slug = Diagnostics::Vocabulary.competence_options.first
    assert_equal "Langues étrangères", label
    assert_equal "langues_etrangeres", slug
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/diagnostics/vocabulary_test.rb`
Expected: FAIL with `uninitialized constant Diagnostics::Vocabulary`.

- [ ] **Step 3: Write the module**

Create `app/models/diagnostics/vocabulary.rb`:

```ruby
module Diagnostics
  module Vocabulary
    FILIERES = {
      "langues"  => "Langues",
      "geo"      => "Géographie & territoires",
      "socio"    => "Sociologie",
      "lettres"  => "Lettres",
      "psycho"   => "Psychologie",
      "philo"    => "Philosophie",
      "histoire" => "Histoire",
      "edu"      => "Sciences de l'éducation"
    }.freeze

    COMPETENCES = {
      "langues_etrangeres"   => "Langues étrangères",
      "communication_ecrite" => "Communication écrite",
      "communication_orale"  => "Communication orale",
      "analyse_donnees"      => "Analyse de données",
      "gestion_projet"       => "Gestion de projet",
      "numerique"            => "Compétences numériques",
      "negociation"          => "Négociation",
      "creativite"           => "Créativité",
      "ecoute"               => "Écoute active",
      "rigueur_scientifique" => "Rigueur et méthode",
      "culture_generale"     => "Culture générale",
      "droit_politiques"     => "Droit et politiques publiques"
    }.freeze

    DISC_TYPES = {
      "D" => "Dominant",
      "I" => "Influent",
      "S" => "Stable",
      "C" => "Consciencieux"
    }.freeze

    module_function

    def filiere_slugs    = FILIERES.keys
    def competence_slugs = COMPETENCES.keys
    def disc_type_slugs  = DISC_TYPES.keys

    # [label, slug] pairs, ready for Rails select / collection helpers.
    def filiere_options    = FILIERES.map { |slug, label| [ label, slug ] }
    def competence_options = COMPETENCES.map { |slug, label| [ label, slug ] }
    def disc_type_options  = DISC_TYPES.map { |slug, label| [ label, slug ] }
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/models/diagnostics/vocabulary_test.rb`
Expected: PASS (4 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add app/models/diagnostics/vocabulary.rb test/models/diagnostics/vocabulary_test.rb
git commit -m "feat: add Diagnostics::Vocabulary single source of truth"
```

---

## Task 2: Career model — virtual text accessors, array normalization, vocabulary validations

**Files:**
- Modify: `app/models/career.rb`
- Test: `test/models/career_test.rb` (append)

- [ ] **Step 1: Write the failing tests**

Append to `test/models/career_test.rb` (inside the `class CareerTest`):

```ruby
  test "affirmations_text round-trips through newlines, stripping blanks" do
    c = Career.new
    c.affirmations_text = "Première\n  Deuxième  \n\n Troisième \n"
    assert_equal ["Première", "Deuxième", "Troisième"], c.affirmations
    assert_equal "Première\nDeuxième\nTroisième", c.affirmations_text
  end

  test "key_skills_text round-trips through newlines" do
    c = Career.new
    c.key_skills_text = "Leadership\nGestion de projet\n"
    assert_equal ["Leadership", "Gestion de projet"], c.key_skills
  end

  test "normalizes array fields by removing blank entries" do
    c = Career.new(title: "X", slug: "x-#{SecureRandom.hex(4)}", kind: :profession,
                   disc_types: ["D", "", nil], required_competences: ["numerique", ""])
    c.valid?
    assert_equal ["D"], c.disc_types
    assert_equal ["numerique"], c.required_competences
  end

  test "rejects disc_types outside the DISC vocabulary" do
    c = Career.new(title: "X", slug: "x-#{SecureRandom.hex(4)}", kind: :profession, disc_types: ["Z"])
    assert_not c.valid?
    assert_includes c.errors[:disc_types].join, "Z"
  end

  test "rejects required_competences outside the vocabulary" do
    c = Career.new(title: "X", slug: "x-#{SecureRandom.hex(4)}", kind: :profession, required_competences: ["bogus"])
    assert_not c.valid?
    assert_includes c.errors[:required_competences].join, "bogus"
  end

  test "rejects filiere_slug outside the vocabulary" do
    c = Career.new(title: "X", slug: "x-#{SecureRandom.hex(4)}", kind: :profession, filiere_slug: "nope")
    assert_not c.valid?
    assert_not_empty c.errors[:filiere_slug]
  end

  test "behavioral profile is valid with no filiere_slug" do
    c = Career.new(title: "X", slug: "x-#{SecureRandom.hex(4)}", kind: :behavioral, filiere_slug: nil)
    assert c.valid?, c.errors.full_messages.to_sentence
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/models/career_test.rb -n "/affirmations_text|key_skills_text|normalizes array|outside the|behavioral profile is valid/"`
Expected: FAIL with `NoMethodError: undefined method 'affirmations_text='` (and others).

- [ ] **Step 3: Implement model changes**

Edit `app/models/career.rb`. Add the accessors, normalization callback, and validations. The full updated model:

```ruby
class Career < ApplicationRecord
  enum :status, { draft: 0, published: 1, archived: 2 }, default: :published
  enum :kind, { behavioral: "behavioral", profession: "profession" }, default: "behavioral"

  scope :diagnostic, -> { where.not(filiere_slug: nil) }

  has_many :trajectories, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true
  validates :slug, uniqueness: true, presence: true, if: :behavioral?

  validates :filiere_slug,
            inclusion: { in: Diagnostics::Vocabulary.filiere_slugs, message: "n'est pas une filière valide" },
            allow_blank: true
  validate :diagnostic_arrays_within_vocabulary

  before_validation :parameterize_slug, if: :behavioral?
  before_validation :normalize_diagnostic_arrays

  def affirmations_text
    Array(affirmations).join("\n")
  end

  def affirmations_text=(value)
    self.affirmations = split_lines(value)
  end

  def key_skills_text
    Array(key_skills).join("\n")
  end

  def key_skills_text=(value)
    self.key_skills = split_lines(value)
  end

  def active_trajectory
    trajectories.active.last
  end

  private

  def parameterize_slug
    self.slug = slug.parameterize if slug.present?
  end

  def split_lines(value)
    value.to_s.split("\n").map(&:strip).reject(&:blank?)
  end

  def normalize_diagnostic_arrays
    self.disc_types           = Array(disc_types).map(&:to_s).reject(&:blank?)
    self.required_competences = Array(required_competences).map(&:to_s).reject(&:blank?)
  end

  def diagnostic_arrays_within_vocabulary
    invalid_disc = disc_types - Diagnostics::Vocabulary.disc_type_slugs
    if invalid_disc.any?
      errors.add(:disc_types, "contient des valeurs invalides : #{invalid_disc.join(', ')}")
    end

    invalid_comp = required_competences - Diagnostics::Vocabulary.competence_slugs
    if invalid_comp.any?
      errors.add(:required_competences, "contient des valeurs invalides : #{invalid_comp.join(', ')}")
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bin/rails test test/models/career_test.rb`
Expected: PASS (all CareerTest cases, including the originals).

- [ ] **Step 5: Commit**

```bash
git add app/models/career.rb test/models/career_test.rb
git commit -m "feat: Career virtual text accessors + vocabulary validations"
```

---

## Task 3: Career admin controller params + form (métier diagnostic fields & behavioral fields)

**Files:**
- Modify: `app/controllers/admin/careers_controller.rb:51-53` (the `career_params` method)
- Modify: `app/views/admin/careers/_form.html.erb` (full rewrite)
- Create: `app/javascript/controllers/career_form_controller.js`
- Create: `test/controllers/admin/careers_controller_test.rb`

- [ ] **Step 1: Write the failing controller test**

Create `test/controllers/admin/careers_controller_test.rb`:

```ruby
require "test_helper"

class Admin::CareersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
    @metier = Career.create!(title: "Métier #{SecureRandom.hex(4)}", status: :published, kind: :profession)
    @profil = Career.create!(title: "Profil #{SecureRandom.hex(4)}", slug: "profil-#{SecureRandom.hex(4)}",
                             status: :published, kind: :behavioral)
  end

  test "update persists the four diagnostic fields on a profession career" do
    patch admin_career_path(@metier), params: { career: {
      filiere_slug: "langues",
      disc_types: ["C", "S"],
      required_competences: ["langues_etrangeres", "communication_ecrite"],
      affirmations_text: "Affirmation une\nAffirmation deux"
    } }

    assert_redirected_to admin_careers_path
    @metier.reload
    assert_equal "langues", @metier.filiere_slug
    assert_equal ["C", "S"], @metier.disc_types
    assert_equal ["langues_etrangeres", "communication_ecrite"], @metier.required_competences
    assert_equal ["Affirmation une", "Affirmation deux"], @metier.affirmations
  end

  test "update with invalid filiere re-renders with an error" do
    patch admin_career_path(@metier), params: { career: { filiere_slug: "bogus" } }

    assert_response :unprocessable_entity
    assert_select "li", text: /filière/
  end

  test "update persists behavioral profile fields" do
    patch admin_career_path(@profil), params: { career: {
      first_action: "Faites X",
      premium_pitch: "Le premium fait Y",
      key_skills_text: "Leadership\nCommunication"
    } }

    assert_redirected_to admin_careers_path
    @profil.reload
    assert_equal "Faites X", @profil.first_action
    assert_equal ["Leadership", "Communication"], @profil.key_skills
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/admin/careers_controller_test.rb`
Expected: FAIL — diagnostic fields not persisted (params not permitted) and form lacks the error markup.

- [ ] **Step 3: Permit the new params**

In `app/controllers/admin/careers_controller.rb`, replace the `career_params` method:

```ruby
    def career_params
      params.require(:career).permit(
        :title, :slug, :description, :status, :kind,
        :first_action, :premium_pitch, :key_skills_text,
        :filiere_slug, :affirmations_text,
        key_skills: [], disc_types: [], required_competences: []
      )
    end
```

- [ ] **Step 4: Rewrite the form**

Replace `app/views/admin/careers/_form.html.erb` in full:

```erb
<div class="glass-card rounded-2xl p-8 shadow-premium animate-premium-in max-w-2xl">
  <%= form_with model: [:admin, career], class: "space-y-6",
        data: { controller: "career-form" } do |f| %>
    <% if career.errors.any? %>
      <div class="bg-red-50 border border-red-100 p-4 rounded-xl text-sm text-red-700 mb-6 animate-shake">
        <div class="font-bold flex items-center gap-2 mb-1">
          <%= lucide_icon "alert-circle", class: "w-4 h-4" %>
          <%= t("errors.messages.not_saved", count: career.errors.count, resource: "métier") %>
        </div>
        <ul class="list-disc list-inside opacity-90">
          <% career.errors.full_messages.each do |msg| %>
            <li><%= msg %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div class="space-y-1">
      <%= f.label :title, class: "text-[10px] font-black uppercase tracking-widest text-slate-400" %>
      <%= f.text_field :title, placeholder: "Ex: Traducteur / Interprète",
            class: "w-full bg-slate-50 border-0 rounded-xl px-4 py-3 text-sm font-medium focus:ring-2 focus:ring-[var(--color-primary)]/20 transition-all" %>
    </div>

    <div class="space-y-1">
      <%= f.label :kind, "Type", class: "text-[10px] font-black uppercase tracking-widest text-slate-400" %>
      <%= f.select :kind,
            [["Profil comportemental", "behavioral"], ["Métier (diagnostic)", "profession"]], {},
            data: { career_form_target: "kind", action: "change->career-form#toggle" },
            class: "w-full bg-slate-50 border-0 rounded-xl px-4 py-3 text-sm font-medium focus:ring-2 focus:ring-[var(--color-primary)]/20 transition-all cursor-pointer" %>
    </div>

    <div class="space-y-1">
      <%= f.label :description, class: "text-[10px] font-black uppercase tracking-widest text-slate-400" %>
      <%= f.text_area :description, rows: 6, placeholder: "Décrivez les missions et responsabilités...",
            class: "w-full bg-slate-50 border-0 rounded-xl px-4 py-3 text-sm font-medium focus:ring-2 focus:ring-[var(--color-primary)]/20 transition-all" %>
    </div>

    <div class="space-y-1">
      <%= f.label :status, class: "text-[10px] font-black uppercase tracking-widest text-slate-400" %>
      <%= f.select :status, Career.statuses.keys.map { |k| [k.humanize, k] }, {},
            class: "w-full bg-slate-50 border-0 rounded-xl px-4 py-3 text-sm font-medium focus:ring-2 focus:ring-[var(--color-primary)]/20 transition-all cursor-pointer" %>
    </div>

    <%# ---- Behavioral profile fields ---- %>
    <div data-career-form-target="behavioralFields" class="space-y-6 border-t border-slate-100 pt-6">
      <p class="text-[10px] font-black uppercase tracking-widest text-[var(--color-primary)]">Champs profil comportemental</p>

      <div class="space-y-1">
        <%= f.label :key_skills_text, "Compétences clés (une par ligne)", class: "text-[10px] font-black uppercase tracking-widest text-slate-400" %>
        <%= f.text_area :key_skills_text, rows: 4,
              class: "w-full bg-slate-50 border-0 rounded-xl px-4 py-3 text-sm font-medium focus:ring-2 focus:ring-[var(--color-primary)]/20 transition-all" %>
      </div>

      <div class="space-y-1">
        <%= f.label :first_action, "Première action", class: "text-[10px] font-black uppercase tracking-widest text-slate-400" %>
        <%= f.text_area :first_action, rows: 3,
              class: "w-full bg-slate-50 border-0 rounded-xl px-4 py-3 text-sm font-medium focus:ring-2 focus:ring-[var(--color-primary)]/20 transition-all" %>
      </div>

      <div class="space-y-1">
        <%= f.label :premium_pitch, "Pitch premium", class: "text-[10px] font-black uppercase tracking-widest text-slate-400" %>
        <%= f.text_area :premium_pitch, rows: 3,
              class: "w-full bg-slate-50 border-0 rounded-xl px-4 py-3 text-sm font-medium focus:ring-2 focus:ring-[var(--color-primary)]/20 transition-all" %>
      </div>
    </div>

    <%# ---- Métier (diagnostic) fields ---- %>
    <div data-career-form-target="professionFields" class="space-y-6 border-t border-slate-100 pt-6">
      <p class="text-[10px] font-black uppercase tracking-widest text-[var(--color-primary)]">Champs métier (diagnostic)</p>

      <div class="space-y-1">
        <%= f.label :filiere_slug, "Filière", class: "text-[10px] font-black uppercase tracking-widest text-slate-400" %>
        <%= f.select :filiere_slug, Diagnostics::Vocabulary.filiere_options,
              { include_blank: "— choisir —" },
              class: "w-full bg-slate-50 border-0 rounded-xl px-4 py-3 text-sm font-medium focus:ring-2 focus:ring-[var(--color-primary)]/20 transition-all cursor-pointer" %>
      </div>

      <div class="space-y-1">
        <span class="text-[10px] font-black uppercase tracking-widest text-slate-400">Types DISC</span>
        <div class="flex flex-wrap gap-3">
          <%= f.collection_check_boxes :disc_types, Diagnostics::Vocabulary::DISC_TYPES.to_a, :first, :last do |b| %>
            <label class="flex items-center gap-2 text-sm font-medium cursor-pointer">
              <%= b.check_box(class: "rounded border-slate-300 text-[var(--color-primary)]") %>
              <%= b.text %>
            </label>
          <% end %>
        </div>
      </div>

      <div class="space-y-1">
        <span class="text-[10px] font-black uppercase tracking-widest text-slate-400">Compétences requises</span>
        <div class="grid grid-cols-2 gap-2">
          <%= f.collection_check_boxes :required_competences, Diagnostics::Vocabulary::COMPETENCES.to_a, :first, :last do |b| %>
            <label class="flex items-center gap-2 text-sm font-medium cursor-pointer">
              <%= b.check_box(class: "rounded border-slate-300 text-[var(--color-primary)]") %>
              <%= b.text %>
            </label>
          <% end %>
        </div>
      </div>

      <div class="space-y-1">
        <%= f.label :affirmations_text, "Affirmations (une par ligne)", class: "text-[10px] font-black uppercase tracking-widest text-slate-400" %>
        <%= f.text_area :affirmations_text, rows: 6, placeholder: "Une affirmation par ligne...",
              class: "w-full bg-slate-50 border-0 rounded-xl px-4 py-3 text-sm font-medium focus:ring-2 focus:ring-[var(--color-primary)]/20 transition-all" %>
      </div>
    </div>

    <div class="pt-4 flex items-center gap-4">
      <%= f.submit t("Save"), class: "bg-[var(--color-primary)] text-white px-8 py-3 rounded-xl font-bold text-sm uppercase tracking-widest hover:opacity-90 transition-all shadow-sm transform hover:translate-y-[-1px]" %>
      <%= link_to t("Cancel"), admin_careers_path, class: "text-slate-400 text-xs font-bold uppercase tracking-widest hover:text-slate-600 transition-colors" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 5: Add the Stimulus toggle controller**

Create `app/javascript/controllers/career_form_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

// Shows behavioral-profile fields or métier (diagnostic) fields based on `kind`.
export default class extends Controller {
  static targets = ["kind", "behavioralFields", "professionFields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const profession = this.kindTarget.value === "profession"
    this.behavioralFieldsTarget.hidden = profession
    this.professionFieldsTarget.hidden = !profession
  }
}
```

- [ ] **Step 6: Run the controller test to verify it passes**

Run: `bin/rails test test/controllers/admin/careers_controller_test.rb`
Expected: PASS (3 runs, 0 failures).

- [ ] **Step 7: Commit**

```bash
git add app/controllers/admin/careers_controller.rb app/views/admin/careers/_form.html.erb app/javascript/controllers/career_form_controller.js test/controllers/admin/careers_controller_test.rb
git commit -m "feat: edit métier diagnostic fields and profile fields in admin careers form"
```

---

## Task 4: DiagnosticQuestion model — competence_label accessor

**Files:**
- Modify: `app/models/diagnostic_question.rb`
- Test: `test/models/diagnostic_question_test.rb` (append)

- [ ] **Step 1: Write the failing tests**

Append inside `class DiagnosticQuestionTest` in `test/models/diagnostic_question_test.rb`:

```ruby
  test "competence_label writes into the options array" do
    q = DiagnosticQuestion.new
    q.competence_label = "  Langues étrangères  "
    assert_equal [{ "label" => "Langues étrangères" }], q.options
    assert_equal "Langues étrangères", q.competence_label
  end

  test "blank competence_label clears the options array" do
    q = DiagnosticQuestion.new(options: [{ "label" => "X" }])
    q.competence_label = ""
    assert_equal [], q.options
    assert_nil q.competence_label
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/models/diagnostic_question_test.rb -n "/competence_label/"`
Expected: FAIL with `NoMethodError: undefined method 'competence_label='`.

- [ ] **Step 3: Add the accessor**

In `app/models/diagnostic_question.rb`, add these public methods (e.g. just after the `options_json` method):

```ruby
  def competence_label
    options.is_a?(Array) ? options.dig(0, "label") : nil
  end

  def competence_label=(value)
    self.options = value.to_s.strip.present? ? [ { "label" => value.to_s.strip } ] : []
  end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bin/rails test test/models/diagnostic_question_test.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/models/diagnostic_question.rb test/models/diagnostic_question_test.rb
git commit -m "feat: DiagnosticQuestion competence_label accessor over options"
```

---

## Task 5: DiagnosticQuestion admin controller, form, and Stimulus fix

**Files:**
- Modify: `app/controllers/admin/diagnostic_questions_controller.rb` (`question_params`)
- Modify: `app/views/admin/diagnostic_questions/_form.html.erb` (full rewrite)
- Rewrite: `app/javascript/controllers/assessment_question_form_controller.js`
- Modify: `test/controllers/admin/diagnostic_questions_controller_test.rb` (replace the stale options-JSON test)

- [ ] **Step 1: Replace the stale controller test with new behavior tests**

In `test/controllers/admin/diagnostic_questions_controller_test.rb`, delete the `"create preserves invalid options JSON and shows an error"` test and add:

```ruby
  test "create persists filiere_slug on an interest question" do
    assert_difference "DiagnosticQuestion.count", 1 do
      post admin_assessment_diagnostic_questions_path(@assessment), params: {
        diagnostic_question: {
          kind: "interest", text: "J'aime les langues", position: 1, active: true,
          filiere_slug: "langues"
        }
      }
    end

    assert_redirected_to admin_assessment_diagnostic_questions_path(@assessment)
    assert_equal "langues", DiagnosticQuestion.order(:created_at).last.filiere_slug
  end

  test "interest question without filiere_slug is rejected" do
    assert_no_difference "DiagnosticQuestion.count" do
      post admin_assessment_diagnostic_questions_path(@assessment), params: {
        diagnostic_question: { kind: "interest", text: "Sans filière", position: 1, active: true }
      }
    end
    assert_response :unprocessable_content
  end

  test "competence question persists its label into options" do
    post admin_assessment_diagnostic_questions_path(@assessment), params: {
      diagnostic_question: {
        kind: "competence", text: "Je maîtrise X", position: 2, active: true,
        competence_slug: "numerique", competence_label: "Compétences numériques"
      }
    }

    question = DiagnosticQuestion.order(:created_at).last
    assert_equal "Compétences numériques", question.options.dig(0, "label")
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb`
Expected: FAIL — `filiere_slug` / `competence_label` not permitted, so the interest question fails validation and the competence label is not stored.

- [ ] **Step 3: Update permitted params**

In `app/controllers/admin/diagnostic_questions_controller.rb`, replace `question_params`:

```ruby
  def question_params
    params.require(:diagnostic_question).permit(
      :kind, :text, :disc_type, :competence_slug, :competence_label, :filiere_slug, :position, :active
    )
  end
```

- [ ] **Step 4: Rewrite the question form**

Replace `app/views/admin/diagnostic_questions/_form.html.erb` in full:

```erb
<%# app/views/admin/diagnostic_questions/_form.html.erb %>
<div class="bg-white rounded-[2rem] p-8 border border-slate-100 shadow-sm max-w-2xl mx-auto">
  <%= form_with model: [:admin, assessment, question], class: "space-y-6",
        data: { controller: "assessment-question-form" } do |f| %>
    <% if question.errors.any? %>
      <div class="bg-red-50 border border-red-200 rounded-xl p-4 text-red-700 text-sm">
        <ul class="list-disc pl-5">
          <% question.errors.full_messages.each do |msg| %>
            <li><%= msg %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div>
      <%= f.label :kind, "Type de question", class: "block text-sm font-semibold text-slate-700 mb-1" %>
      <%= f.select :kind, [["DISC (personnalité)", "disc"], ["Intérêt thématique", "interest"], ["Compétence", "competence"]],
            {}, data: { assessment_question_form_target: "kind", action: "change->assessment-question-form#toggle" },
            class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" %>
    </div>

    <div>
      <%= f.label :text, "Texte de la question / affirmation", class: "block text-sm font-semibold text-slate-700 mb-1" %>
      <%= f.text_area :text, rows: 2, class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" %>
    </div>

    <div data-assessment-question-form-target="discField">
      <%= f.label :disc_type, "Type DISC", class: "block text-sm font-semibold text-slate-700 mb-1" %>
      <%= f.select :disc_type, Diagnostics::Vocabulary.disc_type_options,
            { include_blank: "— choisir —" }, class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" %>
    </div>

    <div data-assessment-question-form-target="filiereField">
      <%= f.label :filiere_slug, "Filière", class: "block text-sm font-semibold text-slate-700 mb-1" %>
      <%= f.select :filiere_slug, Diagnostics::Vocabulary.filiere_options,
            { include_blank: "— choisir —" }, class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" %>
    </div>

    <div data-assessment-question-form-target="competenceField" class="space-y-4">
      <div>
        <%= f.label :competence_slug, "Compétence", class: "block text-sm font-semibold text-slate-700 mb-1" %>
        <%= f.select :competence_slug, Diagnostics::Vocabulary.competence_options,
              { include_blank: "— choisir —" }, class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" %>
      </div>
      <div>
        <%= f.label :competence_label, "Label affiché", class: "block text-sm font-semibold text-slate-700 mb-1" %>
        <%= f.text_field :competence_label, placeholder: "Ex: Compétences numériques",
              class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" %>
      </div>
    </div>

    <div>
      <%= f.label :position, "Position (ordre d'affichage)", class: "block text-sm font-semibold text-slate-700 mb-1" %>
      <%= f.number_field :position, min: 1, class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" %>
    </div>

    <div class="flex items-center gap-2">
      <%= f.check_box :active, class: "rounded border-slate-300 text-primary focus:ring-primary w-5 h-5 cursor-pointer" %>
      <%= f.label :active, "Active", class: "text-sm font-semibold text-slate-700 cursor-pointer" %>
    </div>

    <div class="pt-6 border-t border-slate-100 flex justify-end gap-4">
      <%= link_to "Annuler", assessment ? admin_assessment_diagnostic_questions_path(assessment) : admin_diagnostic_questions_path,
            class: "px-6 py-2.5 rounded-xl font-bold text-slate-500 hover:bg-slate-50 transition-colors" %>
      <%= f.submit question.persisted? ? "Mettre à jour" : "Créer",
            class: "btn-primary hover:scale-[1.02] active:scale-95 transition-all shadow-md cursor-pointer" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 5: Rewrite the Stimulus controller**

Replace `app/javascript/controllers/assessment_question_form_controller.js` in full:

```javascript
import { Controller } from "@hotwired/stimulus"

// Shows the per-kind fields (disc_type / filiere_slug / competence) based on `kind`.
export default class extends Controller {
  static targets = ["kind", "discField", "filiereField", "competenceField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const kind = this.kindTarget.value
    this.discFieldTarget.hidden = kind !== "disc"
    this.filiereFieldTarget.hidden = kind !== "interest"
    this.competenceFieldTarget.hidden = kind !== "competence"
  }
}
```

- [ ] **Step 6: Run the controller test to verify it passes**

Run: `bin/rails test test/controllers/admin/diagnostic_questions_controller_test.rb`
Expected: PASS (3 runs, 0 failures).

- [ ] **Step 7: Commit**

```bash
git add app/controllers/admin/diagnostic_questions_controller.rb app/views/admin/diagnostic_questions/_form.html.erb app/javascript/controllers/assessment_question_form_controller.js test/controllers/admin/diagnostic_questions_controller_test.rb
git commit -m "feat: manage filiere_slug and competence label in admin question form"
```

---

## Task 6: Trajectories — attach to any career (grouped select)

**Files:**
- Modify: `app/controllers/admin/trajectories_controller.rb` (`new`, `edit`, and the two error branches)
- Modify: `app/views/admin/trajectories/_form.html.erb` (the `career_id` select block)
- Create: `test/controllers/admin/trajectories_controller_test.rb`

- [ ] **Step 1: Write the failing controller test**

Create `test/controllers/admin/trajectories_controller_test.rb`:

```ruby
require "test_helper"

class Admin::TrajectoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
    @metier = Career.create!(title: "Métier #{SecureRandom.hex(4)}", status: :published, kind: :profession)
  end

  test "create attaches a trajectory to a profession career" do
    assert_difference "Trajectory.count", 1 do
      post admin_trajectories_path, params: { trajectory: {
        career_id: @metier.id, axe_1: "A1", axe_2: "A2", axe_3: "A3", active: true
      } }
    end
    assert_redirected_to admin_trajectories_path
    assert_equal @metier.id, Trajectory.order(:created_at).last.career_id
  end

  test "new form lists profession careers in the select" do
    get new_admin_trajectory_path
    assert_response :success
    assert_select "select[name='trajectory[career_id]'] optgroup[label='Métiers'] option", text: @metier.title
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/admin/trajectories_controller_test.rb`
Expected: FAIL — the `Métiers` optgroup does not exist yet (the select only lists behavioral careers).

- [ ] **Step 3: Broaden the controller's career list**

In `app/controllers/admin/trajectories_controller.rb`, replace every `Career.behavioral.order(:title)` with `Career.order(:title)`. The updated methods:

```ruby
  def new     = (@trajectory = Trajectory.new(career_id: params[:career_id]); @careers = Career.order(:title)) && render
  def edit    = (@careers = Career.order(:title)) && render

  def create
    @trajectory = Trajectory.new(trajectory_params)
    @trajectory.save ? redirect_to(admin_trajectories_path, notice: "Trajectoire créée.") : ((@careers = Career.order(:title)) && render(:new, status: :unprocessable_entity))
  end

  def update
    @trajectory.update(trajectory_params) ? redirect_to(admin_trajectories_path, notice: "Trajectoire mise à jour.") : ((@careers = Career.order(:title)) && render(:edit, status: :unprocessable_entity))
  end
```

- [ ] **Step 4: Use a grouped select in the form**

In `app/views/admin/trajectories/_form.html.erb`, replace the `career_id` block (the `f.collection_select` div) with:

```erb
    <div class="space-y-1">
      <%= f.label :career_id, "Profil ou métier associé", class: "text-[10px] font-black uppercase tracking-widest text-slate-400" %>
      <% career_groups = @careers.group_by { |c| c.behavioral? ? "Profils" : "Métiers" }
                                  .transform_values { |careers| careers.map { |c| [c.title, c.id] } } %>
      <%= f.select :career_id,
            grouped_options_for_select(career_groups, trajectory.career_id),
            { prompt: "Choisir un profil ou métier..." },
            class: "w-full bg-slate-50 border-0 rounded-xl px-4 py-3 text-sm font-medium focus:ring-2 focus:ring-[var(--color-primary)]/20 transition-all" %>
    </div>
```

- [ ] **Step 5: Run the controller test to verify it passes**

Run: `bin/rails test test/controllers/admin/trajectories_controller_test.rb`
Expected: PASS (2 runs, 0 failures).

- [ ] **Step 6: Commit**

```bash
git add app/controllers/admin/trajectories_controller.rb app/views/admin/trajectories/_form.html.erb test/controllers/admin/trajectories_controller_test.rb
git commit -m "feat: allow trajectories on profession careers via grouped select"
```

---

## Task 7: Repoint seeds and the seed integration test at the Vocabulary module

**Files:**
- Modify: `db/seeds.rb` (the `competence_questions` array's `label:` values)
- Modify: `test/integration/questionnaire_seed_test.rb:4` (the `FILIERE_SLUGS` constant)

- [ ] **Step 1: Repoint the seed integration test constant**

In `test/integration/questionnaire_seed_test.rb`, replace line 4:

```ruby
  FILIERE_SLUGS = Diagnostics::Vocabulary.filiere_slugs
```

- [ ] **Step 2: Run the seed integration test to verify it still passes**

Run: `bin/rails test test/integration/questionnaire_seed_test.rb`
Expected: PASS — `Diagnostics::Vocabulary.filiere_slugs` equals the previous hardcoded list.

- [ ] **Step 3: Derive competence labels in seeds from the vocabulary**

In `db/seeds.rb`, in the `competence_questions` array, the `label:` of each entry must equal `Diagnostics::Vocabulary::COMPETENCES[competence_slug]`. Rather than restate each label, build the array from the vocabulary. Replace the `competence_questions = [ ... ]` literal with:

```ruby
competence_texts = {
  "langues_etrangeres"   => "Je parle couramment au moins une langue étrangère.",
  "communication_ecrite" => "Je rédige des textes clairs, structurés et adaptés à mon audience.",
  "communication_orale"  => "Je m'exprime avec aisance en public ou face à des interlocuteurs variés.",
  "analyse_donnees"      => "Je sais collecter, traiter et interpréter des données (qualitatives ou quantitatives).",
  "gestion_projet"       => "Je peux planifier, coordonner et suivre un projet de A à Z.",
  "numerique"            => "Je maîtrise des outils numériques avancés (tableurs, logiciels métier, code…).",
  "negociation"          => "Je suis capable de défendre une position et trouver des compromis satisfaisants.",
  "creativite"           => "J'ai une forte capacité à imaginer des solutions ou des contenus originaux.",
  "ecoute"               => "Je comprends les besoins implicites de mes interlocuteurs avec empathie.",
  "rigueur_scientifique" => "Je travaille de façon précise, vérifiable et conforme aux standards de mon domaine.",
  "culture_generale"     => "J'ai une bonne connaissance historique, littéraire, artistique et géopolitique.",
  "droit_politiques"     => "Je comprends le cadre juridique, réglementaire et institutionnel de mon secteur."
}

competence_questions = competence_texts.each_with_index.map do |(slug, text), index|
  { label: Diagnostics::Vocabulary::COMPETENCES.fetch(slug), text: text, competence_slug: slug, position: 18 + index }
end
```

(Positions 18–29 are preserved by `18 + index`, matching the original.)

- [ ] **Step 4: Verify seeds run cleanly**

Run: `bin/rails db:seed`
Expected: completes without error; prints the `✓ … questions compétences` line with count 12.

- [ ] **Step 5: Run the full suite**

Run: `bin/rails test`
Expected: all tests pass (green).

- [ ] **Step 6: Commit**

```bash
git add db/seeds.rb test/integration/questionnaire_seed_test.rb
git commit -m "refactor: seeds and seed test reference Diagnostics::Vocabulary"
```

---

## Done

After Task 7, every field of the new diagnostic architecture is editable in the admin dashboard, validated against a single shared vocabulary, and the seeds + seed test consume that same vocabulary. Run `bin/rails test` once more to confirm a fully green suite before opening a PR.
