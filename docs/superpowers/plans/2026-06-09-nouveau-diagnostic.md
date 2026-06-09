# Nouveau Diagnostic (DISC + Filières + Métiers) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing 25-question bloc-based diagnostic with a 36-question DISC/filière/compétences system that recommends 2 specific careers from a pool of 37 métiers.

**Architecture:** Four sequential question steps (interest → DISC → competences → validation) each backed by a dedicated controller action. A `PreScoringService` runs after competences to rank careers; `ScoringService` finalises after validation. All questions live in a new `diagnostic_questions` table, admin-editable. Careers gain `disc_types`, `filiere_slug`, `required_competences`, and `affirmations` columns.

**Tech Stack:** Rails 8, PostgreSQL (JSONB), Minitest, Tailwind CSS, Turbo/Stimulus (existing stack), custom admin controllers under `Admin::BaseController`.

---

## File Map

**New files:**
- `db/migrate/*_create_diagnostic_questions.rb`
- `db/migrate/*_add_diagnostic_fields_to_careers.rb`
- `db/migrate/*_add_diagnostic_question_to_diagnostic_answers.rb`
- `app/models/diagnostic_question.rb`
- `app/services/diagnostics/pre_scoring_service.rb`
- `app/views/diagnostics/interest.html.erb`
- `app/views/diagnostics/disc.html.erb`
- `app/views/diagnostics/competences.html.erb`
- `app/views/diagnostics/validation.html.erb`
- `app/views/diagnostics/_likert_question.html.erb`
- `app/controllers/admin/diagnostic_questions_controller.rb`
- `app/views/admin/diagnostic_questions/` (index, new, edit, _form)
- `test/models/diagnostic_question_test.rb`
- `test/services/diagnostics/pre_scoring_service_test.rb`

**Modified files:**
- `app/models/career.rb` — add `diagnostic` scope + new column helpers
- `app/models/diagnostic_answer.rb` — add `belongs_to :diagnostic_question`
- `app/models/assessment.rb` — add `has_many :diagnostic_questions`
- `app/services/diagnostics/scoring_service.rb` — full rewrite
- `app/controllers/diagnostics_controller.rb` — new actions + updated show/new
- `config/routes.rb` — replace assessment/submit_bloc with 8 new member routes + admin route
- `db/seeds.rb` — full rewrite of questions + career diagnostic data
- `test/controllers/diagnostics_controller_test.rb` — update for new routes
- `test/services/diagnostics/scoring_service_test.rb` — full rewrite

**Deferred to cleanup task:**
- `db/migrate/*_drop_assessment_questions.rb`
- Remove `assessment_question_id` FK from `diagnostic_answers`
- Remove `kind` enum (behavioral/profession) from `Career`

---

## Task 1: Create `diagnostic_questions` table and model

**Files:**
- Create: `db/migrate/YYYYMMDDHHMMSS_create_diagnostic_questions.rb`
- Create: `app/models/diagnostic_question.rb`
- Update: `app/models/assessment.rb`
- Create: `test/models/diagnostic_question_test.rb`

- [ ] **Step 1: Write the failing test**

```ruby
# test/models/diagnostic_question_test.rb
require "test_helper"

class DiagnosticQuestionTest < ActiveSupport::TestCase
  def setup
    @assessment = Assessment.create!(title: "Test #{SecureRandom.hex(4)}", active: false)
  end

  test "valid disc question" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :disc, text: "Je prends des décisions sous pression.", disc_type: "D", position: 1)
    assert q.valid?, q.errors.full_messages.inspect
  end

  test "disc question invalid without disc_type" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :disc, text: "X", position: 1)
    assert_not q.valid?
    assert_includes q.errors[:disc_type], "ne peut pas être vide"
  end

  test "disc_type must be D I S or C" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :disc, text: "X", disc_type: "Z", position: 1)
    assert_not q.valid?
  end

  test "valid interest question" do
    opts = [ { "label" => "Écrire", "filiere_slug" => "lettres" } ]
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :interest, text: "Vous aimez :", options: opts, position: 1)
    assert q.valid?, q.errors.full_messages.inspect
  end

  test "interest question invalid without options" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :interest, text: "X", options: [], position: 1)
    assert_not q.valid?
  end

  test "valid competence question" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :competence, text: "Je parle une langue.", competence_slug: "langues_etrangeres", position: 1)
    assert q.valid?, q.errors.full_messages.inspect
  end

  test "competence question invalid without competence_slug" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :competence, text: "X", position: 1)
    assert_not q.valid?
  end

  test "active scope excludes inactive questions" do
    DiagnosticQuestion.create!(assessment: @assessment, kind: :competence, text: "A", competence_slug: "ecoute", position: 1, active: true)
    DiagnosticQuestion.create!(assessment: @assessment, kind: :competence, text: "B", competence_slug: "creativite", position: 2, active: false)
    assert_equal 1, DiagnosticQuestion.where(assessment: @assessment).active.count
  end

  test "ordered scope returns by position" do
    DiagnosticQuestion.create!(assessment: @assessment, kind: :competence, text: "Z", competence_slug: "ecoute", position: 3)
    DiagnosticQuestion.create!(assessment: @assessment, kind: :competence, text: "A", competence_slug: "creativite", position: 1)
    positions = DiagnosticQuestion.where(assessment: @assessment).ordered.pluck(:position)
    assert_equal positions.sort, positions
  end
end
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
bin/rails test test/models/diagnostic_question_test.rb
```
Expected: error — `uninitialized constant DiagnosticQuestion`

- [ ] **Step 3: Generate migration**

```bash
bin/rails generate migration CreateDiagnosticQuestions
```

Edit the generated file:

```ruby
class CreateDiagnosticQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :diagnostic_questions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :assessment, type: :uuid, foreign_key: true, null: false
      t.string  :kind,            null: false
      t.text    :text,            null: false
      t.string  :disc_type
      t.string  :competence_slug
      t.jsonb   :options,         default: []
      t.integer :position,        default: 1, null: false
      t.boolean :active,          default: true, null: false
      t.timestamps
    end
    add_index :diagnostic_questions, [ :assessment_id, :kind, :position ]
  end
end
```

- [ ] **Step 4: Run migration**

```bash
bin/rails db:migrate
```

- [ ] **Step 5: Create model**

```ruby
# app/models/diagnostic_question.rb
class DiagnosticQuestion < ApplicationRecord
  belongs_to :assessment

  enum :kind, { disc: "disc", interest: "interest", competence: "competence" }

  validates :text,     presence: true
  validates :kind,     presence: true
  validates :position, presence: true, numericality: { greater_than: 0 }
  validates :disc_type, inclusion: { in: %w[D I S C] }, allow_nil: true
  validate  :kind_specific_fields_present

  scope :active,   -> { where(active: true) }
  scope :ordered,  -> { order(:position) }

  private

  def kind_specific_fields_present
    case kind
    when "disc"
      errors.add(:disc_type, "ne peut pas être vide") if disc_type.blank?
    when "interest"
      errors.add(:options, "ne peut pas être vide") if options.blank?
    when "competence"
      errors.add(:competence_slug, "ne peut pas être vide") if competence_slug.blank?
    end
  end
end
```

- [ ] **Step 6: Add `has_many :diagnostic_questions` to Assessment**

```ruby
# app/models/assessment.rb — add inside the class body after existing has_many
has_many :diagnostic_questions, -> { order(:position) }, dependent: :destroy
```

- [ ] **Step 7: Run tests**

```bash
bin/rails test test/models/diagnostic_question_test.rb
```
Expected: all pass.

- [ ] **Step 8: Commit**

```bash
git add db/migrate/*_create_diagnostic_questions.rb app/models/diagnostic_question.rb app/models/assessment.rb test/models/diagnostic_question_test.rb
git commit -m "feat: add DiagnosticQuestion model (disc/interest/competence)"
```

---

## Task 2: Add diagnostic fields to `careers`

**Files:**
- Create: `db/migrate/YYYYMMDDHHMMSS_add_diagnostic_fields_to_careers.rb`
- Modify: `app/models/career.rb`
- Modify: `test/models/career_test.rb`

- [ ] **Step 1: Write the failing tests**

Add to `test/models/career_test.rb`:

```ruby
test "diagnostic scope returns only careers with filiere_slug" do
  c1 = Career.create!(title: "Métier A", filiere_slug: "langues", status: :published)
  c2 = Career.create!(title: "Métier B", status: :published)
  assert_includes Career.diagnostic, c1
  assert_not_includes Career.diagnostic, c2
end

test "disc_types defaults to empty array" do
  c = Career.create!(title: "Test Career #{SecureRandom.hex(4)}", status: :published)
  assert_equal [], c.disc_types
end

test "required_competences defaults to empty array" do
  c = Career.create!(title: "Test Career #{SecureRandom.hex(4)}", status: :published)
  assert_equal [], c.required_competences
end

test "affirmations defaults to empty array" do
  c = Career.create!(title: "Test Career #{SecureRandom.hex(4)}", status: :published)
  assert_equal [], c.affirmations
end
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
bin/rails test test/models/career_test.rb
```
Expected: failures on the 4 new tests.

- [ ] **Step 3: Generate and run migration**

```bash
bin/rails generate migration AddDiagnosticFieldsToCareers
```

Edit the generated file:

```ruby
class AddDiagnosticFieldsToCareers < ActiveRecord::Migration[8.0]
  def change
    add_column :careers, :disc_types,           :jsonb, default: []
    add_column :careers, :filiere_slug,          :string
    add_column :careers, :required_competences,  :jsonb, default: []
    add_column :careers, :affirmations,          :jsonb, default: []
  end
end
```

```bash
bin/rails db:migrate
```

- [ ] **Step 4: Add `diagnostic` scope to Career model**

In `app/models/career.rb`, add after the existing enum lines:

```ruby
scope :diagnostic, -> { where.not(filiere_slug: nil) }
```

- [ ] **Step 5: Run tests**

```bash
bin/rails test test/models/career_test.rb
```
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add db/migrate/*_add_diagnostic_fields_to_careers.rb app/models/career.rb test/models/career_test.rb
git commit -m "feat: add disc_types, filiere_slug, required_competences, affirmations to Career"
```

---

## Task 3: Update `diagnostic_answers` to reference `diagnostic_question`

**Files:**
- Create: `db/migrate/YYYYMMDDHHMMSS_add_diagnostic_question_to_diagnostic_answers.rb`
- Modify: `app/models/diagnostic_answer.rb`

- [ ] **Step 1: Generate and run migration**

```bash
bin/rails generate migration AddDiagnosticQuestionToDiagnosticAnswers
```

Edit the generated file:

```ruby
class AddDiagnosticQuestionToDiagnosticAnswers < ActiveRecord::Migration[8.0]
  def change
    add_reference :diagnostic_answers, :diagnostic_question,
                  type: :uuid, foreign_key: true, null: true
    add_column :diagnostic_answers, :dimension_slug, :string
  end
end
```

```bash
bin/rails db:migrate
```

- [ ] **Step 2: Update DiagnosticAnswer model**

Open `app/models/diagnostic_answer.rb` and add:

```ruby
belongs_to :diagnostic_question, optional: true
```

The `assessment_question_id` FK stays for now — it will be removed in Task 12 (cleanup).

- [ ] **Step 3: Verify no test regressions**

```bash
bin/rails test test/models/
```
Expected: all existing model tests pass.

- [ ] **Step 4: Commit**

```bash
git add db/migrate/*_add_diagnostic_question_to_diagnostic_answers.rb app/models/diagnostic_answer.rb
git commit -m "feat: add diagnostic_question_id and dimension_slug to diagnostic_answers"
```

---

## Task 4: Update routes, `new` action and `show` redirect

**Files:**
- Modify: `config/routes.rb`
- Modify: `app/controllers/diagnostics_controller.rb`
- Modify: `test/controllers/diagnostics_controller_test.rb`

- [ ] **Step 1: Write failing controller tests**

Replace the content of `test/controllers/diagnostics_controller_test.rb`:

```ruby
require "test_helper"

class DiagnosticsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user  = User.create!(email: "ctrl#{SecureRandom.hex(4)}@test.com", password: "password123",
                          first_name: "Test", last_name: "User", city: "Cotonou",
                          country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Diagnostic Test #{SecureRandom.hex(4)}", active: true)
  end

  test "GET new redirects unauthenticated users to sign-in" do
    get new_diagnostic_path
    assert_redirected_to new_user_session_path
  end

  test "GET new creates diagnostic and redirects to interest for authenticated user" do
    sign_in @user
    assert_difference "Diagnostic.count", 1 do
      get new_diagnostic_path
    end
    assert_redirected_to interest_diagnostic_path(Diagnostic.last)
  end

  test "GET interest renders for in_progress diagnostic" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
    get interest_diagnostic_path(d)
    assert_response :success
  end

  test "GET disc renders for diagnostic with interest answers" do
    sign_in @user
    q = @assessment.diagnostic_questions.create!(kind: :interest, text: "Q?", options: [{ "label" => "X", "filiere_slug" => "langues" }], position: 1)
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
    d.diagnostic_answers.create!(diagnostic_question: q, dimension_slug: "langues", answer_value: "langues", points_awarded: 1)
    get disc_diagnostic_path(d)
    assert_response :success
  end

  test "GET results blocked for pending_payment diagnostic" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :pending_payment, assessment: @assessment)
    get results_diagnostic_path(d)
    assert_redirected_to pay_diagnostic_path(d)
  end

  test "GET show redirects in_progress to interest when no answers" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
    get diagnostic_path(d)
    assert_redirected_to interest_diagnostic_path(d)
  end

  private

  def sign_in(user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end
end
```

- [ ] **Step 2: Run tests to confirm failures**

```bash
bin/rails test test/controllers/diagnostics_controller_test.rb
```
Expected: multiple failures (routes don't exist yet).

- [ ] **Step 3: Update routes**

Replace the `resources :diagnostics` block in `config/routes.rb`:

```ruby
resources :diagnostics, only: [ :new, :show ] do
  member do
    get  :interest
    post :submit_interest
    get  :disc
    post :submit_disc
    get  :competences
    post :submit_competences
    get  :validation
    post :submit_validation
    get  :pay
    post :process_payment
    get  :results
    get  :pdf_status
    get  :download_pdf
  end
end
```

Also add the admin route for diagnostic questions. In the `namespace :admin` block, replace the `resources :assessments` block with:

```ruby
resources :assessments do
  member { patch :activate }
  resources :diagnostic_questions do
    collection { patch :reorder }
  end
end
resources :diagnostic_questions do
  collection { patch :reorder }
end
```

Remove the old `resources :assessment_questions` lines from the admin namespace.

- [ ] **Step 4: Update `new` and `show` actions in DiagnosticsController**

Replace the `new` and `show` actions, and add the private helper `current_step_path`:

```ruby
def new
  assessment = Assessment.find_by(active: true) || Assessment.first
  unless assessment
    redirect_to root_path, alert: "Aucune évaluation disponible pour le moment."
    return
  end
  @diagnostic = current_user.diagnostics.create!(status: :in_progress, assessment: assessment)
  redirect_to interest_diagnostic_path(@diagnostic)
end

def show
  redirect_to current_step_path(@diagnostic)
end
```

Add these private helpers (keep existing private methods):

```ruby
def current_step_path(diagnostic)
  case diagnostic.status
  when "paid", "completed" then results_diagnostic_path(diagnostic)
  when "pending_payment"   then pay_diagnostic_path(diagnostic)
  when "in_progress"       then in_progress_step_path(diagnostic)
  else root_path
  end
end

def in_progress_step_path(diagnostic)
  answered_kinds = diagnostic.diagnostic_answers
    .joins(:diagnostic_question)
    .distinct
    .pluck("diagnostic_questions.kind")

  if answered_kinds.include?("competence")
    validation_diagnostic_path(diagnostic)
  elsif answered_kinds.include?("disc")
    competences_diagnostic_path(diagnostic)
  elsif answered_kinds.include?("interest")
    disc_diagnostic_path(diagnostic)
  else
    interest_diagnostic_path(diagnostic)
  end
end

def active_assessment
  @active_assessment ||= @diagnostic.assessment || Assessment.find_by(active: true)
end
```

Update `before_action :set_diagnostic` to cover all new actions:

```ruby
before_action :set_diagnostic, only: [
  :show, :interest, :submit_interest, :disc, :submit_disc,
  :competences, :submit_competences, :validation, :submit_validation,
  :pay, :process_payment, :results, :pdf_status, :download_pdf
]
before_action :require_paid!, only: [ :results, :pdf_status, :download_pdf ]
```

- [ ] **Step 5: Run tests**

```bash
bin/rails test test/controllers/diagnostics_controller_test.rb
```
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add config/routes.rb app/controllers/diagnostics_controller.rb test/controllers/diagnostics_controller_test.rb
git commit -m "feat: replace assessment/submit_bloc routes with interest/disc/competences/validation steps"
```

---

## Task 5: Interest step — controller actions + view

**Files:**
- Modify: `app/controllers/diagnostics_controller.rb`
- Create: `app/views/diagnostics/interest.html.erb`

- [ ] **Step 1: Add `interest` and `submit_interest` actions to DiagnosticsController**

```ruby
def interest
  @questions = active_assessment.diagnostic_questions.interest.active.ordered
end

def submit_interest
  active_assessment.diagnostic_questions.interest.active.ordered.each do |q|
    filiere_slug = params.dig(:answers, q.id.to_s)
    next if filiere_slug.blank?
    @diagnostic.diagnostic_answers.find_or_create_by!(diagnostic_question: q) do |a|
      a.dimension_slug  = filiere_slug
      a.answer_value    = filiere_slug
      a.points_awarded  = 1
    end
  end
  redirect_to disc_diagnostic_path(@diagnostic)
end
```

- [ ] **Step 2: Create the interest view**

```erb
<%# app/views/diagnostics/interest.html.erb %>
<div class="max-w-2xl mx-auto px-4 py-8">
  <div class="mb-8">
    <p class="text-xs font-bold uppercase tracking-widest text-[var(--color-primary)] mb-2">Étape 1 sur 4</p>
    <h1 class="text-2xl font-bold text-slate-800">Découvrons ce qui vous anime</h1>
    <p class="text-slate-500 mt-1">Répondez spontanément — il n'y a pas de bonne ou mauvaise réponse.</p>
  </div>

  <%= form_with url: submit_interest_diagnostic_path(@diagnostic), method: :post, data: { turbo: false } do |f| %>
    <div class="space-y-8">
      <% @questions.each_with_index do |question, i| %>
        <div class="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm">
          <p class="font-semibold text-slate-700 mb-4">
            <span class="text-[var(--color-primary)] mr-2"><%= i + 1 %>.</span>
            <%= question.text %>
          </p>
          <div class="space-y-3">
            <% question.options.each do |option| %>
              <label class="flex items-start gap-3 cursor-pointer group">
                <input type="radio"
                       name="answers[<%= question.id %>]"
                       value="<%= option['filiere_slug'] %>"
                       class="mt-1 accent-[var(--color-primary)]"
                       required>
                <span class="text-slate-600 group-hover:text-slate-800 transition-colors">
                  <%= option['label'] %>
                </span>
              </label>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>

    <div class="mt-8">
      <%= f.submit "Continuer →",
            class: "w-full py-4 bg-[var(--color-primary)] text-white font-bold rounded-2xl hover:opacity-90 transition-opacity cursor-pointer" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 3: Smoke-test manually**

```bash
bin/rails server
```
Log in as any user, start a diagnostic (`/diagnostics/new`), confirm you land on the interest page, answer all questions, confirm redirect to `/diagnostics/:id/disc`.

- [ ] **Step 4: Commit**

```bash
git add app/controllers/diagnostics_controller.rb app/views/diagnostics/interest.html.erb
git commit -m "feat: add interest step (filière discovery questions)"
```

---

## Task 6: DISC step — controller actions + view + Likert partial

**Files:**
- Modify: `app/controllers/diagnostics_controller.rb`
- Create: `app/views/diagnostics/disc.html.erb`
- Create: `app/views/diagnostics/_likert_question.html.erb`

- [ ] **Step 1: Add `disc` and `submit_disc` actions**

```ruby
def disc
  @questions = active_assessment.diagnostic_questions.disc.active.ordered
end

def submit_disc
  active_assessment.diagnostic_questions.disc.active.ordered.each do |q|
    value = params.dig(:answers, q.id.to_s).to_i
    next unless (1..5).include?(value)
    @diagnostic.diagnostic_answers.find_or_create_by!(diagnostic_question: q) do |a|
      a.dimension_slug = q.disc_type
      a.answer_value   = value.to_s
      a.points_awarded = value
    end
  end
  redirect_to competences_diagnostic_path(@diagnostic)
end
```

- [ ] **Step 2: Create the Likert partial**

```erb
<%# app/views/diagnostics/_likert_question.html.erb %>
<%# Locals: question (DiagnosticQuestion), index (Integer), current_value (String, optional) %>
<div class="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm">
  <p class="font-semibold text-slate-700 mb-5">
    <span class="text-[var(--color-primary)] mr-2"><%= index + 1 %>.</span>
    <%= question.text %>
  </p>
  <div class="flex gap-2 justify-between">
    <% (1..5).each do |value| %>
      <label class="flex-1 flex flex-col items-center gap-2 cursor-pointer group">
        <input type="radio"
               name="answers[<%= question.id %>]"
               value="<%= value %>"
               class="sr-only peer"
               <%= "checked" if current_value == value.to_s %>
               required>
        <div class="w-full py-3 rounded-xl border-2 border-slate-200 text-center text-slate-500 text-sm font-bold
                    peer-checked:border-[var(--color-primary)] peer-checked:bg-[var(--color-primary)] peer-checked:text-white
                    group-hover:border-slate-400 transition-all">
          <%= value %>
        </div>
      </label>
    <% end %>
  </div>
  <div class="flex justify-between mt-2 text-xs text-slate-400">
    <span>Pas du tout moi</span>
    <span>Tout à fait moi</span>
  </div>
</div>
```

- [ ] **Step 3: Create the DISC view**

```erb
<%# app/views/diagnostics/disc.html.erb %>
<div class="max-w-2xl mx-auto px-4 py-8">
  <div class="mb-8">
    <p class="text-xs font-bold uppercase tracking-widest text-[var(--color-primary)] mb-2">Étape 2 sur 4</p>
    <h1 class="text-2xl font-bold text-slate-800">Comment travaillez-vous ?</h1>
    <p class="text-slate-500 mt-1">Évaluez chaque affirmation de 1 (pas du tout moi) à 5 (tout à fait moi).</p>
  </div>

  <%= form_with url: submit_disc_diagnostic_path(@diagnostic), method: :post, data: { turbo: false } do |f| %>
    <div class="space-y-4">
      <% @questions.each_with_index do |question, i| %>
        <%= render "likert_question", question: question, index: i, current_value: nil %>
      <% end %>
    </div>

    <div class="mt-8">
      <%= f.submit "Continuer →",
            class: "w-full py-4 bg-[var(--color-primary)] text-white font-bold rounded-2xl hover:opacity-90 transition-opacity cursor-pointer" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 4: Smoke-test manually**

Complete the interest step in the browser and confirm you land on the DISC page, answer all 16 questions with scale 1–5, and are redirected to `/diagnostics/:id/competences`.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/diagnostics_controller.rb app/views/diagnostics/disc.html.erb app/views/diagnostics/_likert_question.html.erb
git commit -m "feat: add DISC step with Likert 1-5 affirmations"
```

---

## Task 7: Competences step — controller actions + view

**Files:**
- Modify: `app/controllers/diagnostics_controller.rb`
- Create: `app/views/diagnostics/competences.html.erb`

- [ ] **Step 1: Add `competences` and `submit_competences` actions**

```ruby
def competences
  @questions = active_assessment.diagnostic_questions.competence.active.ordered
end

def submit_competences
  active_assessment.diagnostic_questions.competence.active.ordered.each do |q|
    value = params.dig(:answers, q.id.to_s).to_i
    next unless (1..5).include?(value)
    @diagnostic.diagnostic_answers.find_or_create_by!(diagnostic_question: q) do |a|
      a.dimension_slug = q.competence_slug
      a.answer_value   = value.to_s
      a.points_awarded = value
    end
  end
  Diagnostics::PreScoringService.call(@diagnostic)
  redirect_to validation_diagnostic_path(@diagnostic)
end
```

- [ ] **Step 2: Create the competences view**

```erb
<%# app/views/diagnostics/competences.html.erb %>
<div class="max-w-2xl mx-auto px-4 py-8">
  <div class="mb-8">
    <p class="text-xs font-bold uppercase tracking-widest text-[var(--color-primary)] mb-2">Étape 3 sur 4</p>
    <h1 class="text-2xl font-bold text-slate-800">Vos compétences</h1>
    <p class="text-slate-500 mt-1">Évaluez honnêtement votre niveau sur chaque compétence.</p>
  </div>

  <%= form_with url: submit_competences_diagnostic_path(@diagnostic), method: :post, data: { turbo: false } do |f| %>
    <div class="space-y-4">
      <% @questions.each_with_index do |question, i| %>
        <%= render "likert_question", question: question, index: i, current_value: nil %>
      <% end %>
    </div>

    <div class="mt-8">
      <%= f.submit "Voir mes résultats →",
            class: "w-full py-4 bg-[var(--color-primary)] text-white font-bold rounded-2xl hover:opacity-90 transition-opacity cursor-pointer" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 3: Smoke-test manually**

Complete interest + DISC in the browser, answer the 12 competence questions, and confirm the redirect goes to `/diagnostics/:id/validation`.

- [ ] **Step 4: Commit**

```bash
git add app/controllers/diagnostics_controller.rb app/views/diagnostics/competences.html.erb
git commit -m "feat: add competences step (self-assessment Likert 1-5)"
```

---

## Task 8: `PreScoringService` + tests

**Files:**
- Create: `app/services/diagnostics/pre_scoring_service.rb`
- Create: `test/services/diagnostics/pre_scoring_service_test.rb`

- [ ] **Step 1: Write failing tests**

```ruby
# test/services/diagnostics/pre_scoring_service_test.rb
require "test_helper"

class Diagnostics::PreScoringServiceTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "score#{SecureRandom.hex(4)}@test.com", password: "password123")
    @assessment = Assessment.create!(title: "Scoring Test #{SecureRandom.hex(4)}", active: false)
    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :in_progress)

    # 1 interest question → langues
    @iq = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Vous aimez :",
      options: [ { "label" => "Les langues", "filiere_slug" => "langues" } ],
      position: 1
    )
    # 1 disc question (D type)
    @dq = @assessment.diagnostic_questions.create!(
      kind: :disc, text: "Je décide vite.", disc_type: "D", position: 2
    )
    # 1 competence question
    @cq = @assessment.diagnostic_questions.create!(
      kind: :competence, text: "Je parle une langue.", competence_slug: "langues_etrangeres", position: 3
    )

    # Seed answers
    @diagnostic.diagnostic_answers.create!(diagnostic_question: @iq, dimension_slug: "langues", answer_value: "langues", points_awarded: 1)
    @diagnostic.diagnostic_answers.create!(diagnostic_question: @dq, dimension_slug: "D", answer_value: "4", points_awarded: 4)
    @diagnostic.diagnostic_answers.create!(diagnostic_question: @cq, dimension_slug: "langues_etrangeres", answer_value: "5", points_awarded: 5)

    # A career that should score well
    @career = Career.create!(
      title: "Traducteur", status: :published, filiere_slug: "langues",
      disc_types: [ "C", "D" ], required_competences: [ "langues_etrangeres" ]
    )
  end

  test "stores disc_scores in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 4, @diagnostic.score_data["disc_scores"]["D"]
  end

  test "stores filiere_scores in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 1, @diagnostic.score_data["filiere_scores"]["langues"]
  end

  test "stores competence_scores in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 5, @diagnostic.score_data["competence_scores"]["langues_etrangeres"]
  end

  test "stores top_career_ids in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert @diagnostic.score_data["top_career_ids"].is_a?(Array)
    assert @diagnostic.score_data["top_career_ids"].any? { |h| h["id"] == @career.id }
  end

  test "does not change diagnostic status" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert @diagnostic.in_progress?
  end
end
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
bin/rails test test/services/diagnostics/pre_scoring_service_test.rb
```
Expected: error — `uninitialized constant Diagnostics::PreScoringService`

- [ ] **Step 3: Create `PreScoringService`**

```ruby
# app/services/diagnostics/pre_scoring_service.rb
module Diagnostics
  class PreScoringService
    def self.call(diagnostic)
      new(diagnostic).call
    end

    def initialize(diagnostic)
      @diagnostic = diagnostic
    end

    def call
      scores       = calculate_scores
      top_careers  = rank_careers(scores).first(3)

      @diagnostic.update!(
        score_data: scores.merge(
          top_career_ids: top_careers.map { |career, score| { "id" => career.id, "score" => score } }
        )
      )
    end

    private

    def calculate_scores
      disc_scores       = Hash.new(0)
      filiere_scores    = Hash.new(0)
      competence_scores = {}

      @diagnostic.diagnostic_answers.includes(:diagnostic_question).each do |answer|
        q = answer.diagnostic_question
        next unless q

        case q.kind
        when "disc"
          disc_scores[q.disc_type] += answer.points_awarded.to_i
        when "interest"
          filiere_scores[answer.dimension_slug] += 1
        when "competence"
          competence_scores[q.competence_slug] = answer.points_awarded.to_i
        end
      end

      { "disc_scores" => disc_scores, "filiere_scores" => filiere_scores, "competence_scores" => competence_scores }
    end

    def rank_careers(scores)
      disc_scores       = scores["disc_scores"]
      filiere_scores    = scores["filiere_scores"]
      competence_scores = scores["competence_scores"]

      dominant_disc    = disc_scores.sort_by { |_, v| -v }.first(2).map(&:first)
      dominant_filiere = filiere_scores.max_by { |_, v| v }&.first

      Career.diagnostic.published.map do |career|
        disc_match    = career.disc_types.count { |t| dominant_disc.include?(t) } * 3
        filiere_match = dominant_filiere && career.filiere_slug == dominant_filiere ? 5 : 0
        comp_match    = (career.required_competences || []).sum { |c| competence_scores[c].to_i }
        [ career, disc_match + filiere_match + comp_match ]
      end.sort_by { |_, s| -s }
    end
  end
end
```

- [ ] **Step 4: Run tests**

```bash
bin/rails test test/services/diagnostics/pre_scoring_service_test.rb
```
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add app/services/diagnostics/pre_scoring_service.rb test/services/diagnostics/pre_scoring_service_test.rb
git commit -m "feat: add PreScoringService (ranks careers after competences step)"
```

---

## Task 9: Validation step + `ScoringService` rewrite

**Files:**
- Modify: `app/controllers/diagnostics_controller.rb`
- Create: `app/views/diagnostics/validation.html.erb`
- Modify: `app/services/diagnostics/scoring_service.rb`
- Modify: `test/services/diagnostics/scoring_service_test.rb`

- [ ] **Step 1: Write failing ScoringService tests**

Replace `test/services/diagnostics/scoring_service_test.rb`:

```ruby
require "test_helper"

class Diagnostics::ScoringServiceTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "final#{SecureRandom.hex(4)}@test.com", password: "password123")
    @assessment = Assessment.create!(title: "Final Score Test #{SecureRandom.hex(4)}", active: false)
    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :in_progress)

    @c1 = Career.create!(title: "Métier 1", status: :published, filiere_slug: "langues", disc_types: [ "C" ], required_competences: [])
    @c2 = Career.create!(title: "Métier 2", status: :published, filiere_slug: "socio",   disc_types: [ "I" ], required_competences: [])
    @c3 = Career.create!(title: "Métier 3", status: :published, filiere_slug: "lettres", disc_types: [ "S" ], required_competences: [])

    @diagnostic.update!(score_data: {
      "disc_scores"       => { "C" => 18 },
      "filiere_scores"    => { "langues" => 3 },
      "competence_scores" => {},
      "top_career_ids"    => [
        { "id" => @c1.id, "score" => 20 },
        { "id" => @c2.id, "score" => 15 },
        { "id" => @c3.id, "score" => 10 }
      ]
    })
  end

  test "sets primary and complementary careers" do
    Diagnostics::ScoringService.call(@diagnostic, {})
    @diagnostic.reload
    assert_equal @c1, @diagnostic.primary_career
    assert_equal @c2, @diagnostic.complementary_career
  end

  test "affirmation bonus can change ranking" do
    # Give c2 so many affirmations it overtakes c1
    affirmations = { @c2.id => %w[a b c d e f] }
    Diagnostics::ScoringService.call(@diagnostic, affirmations)
    @diagnostic.reload
    assert_equal @c2, @diagnostic.primary_career
  end

  test "sets status to pending_payment" do
    Diagnostics::ScoringService.call(@diagnostic, {})
    @diagnostic.reload
    assert @diagnostic.pending_payment?
  end

  test "sets completed_at" do
    Diagnostics::ScoringService.call(@diagnostic, {})
    @diagnostic.reload
    assert_not_nil @diagnostic.completed_at
  end
end
```

- [ ] **Step 2: Run tests to confirm failures**

```bash
bin/rails test test/services/diagnostics/scoring_service_test.rb
```
Expected: failures — wrong arity or missing method.

- [ ] **Step 3: Rewrite `ScoringService`**

```ruby
# app/services/diagnostics/scoring_service.rb
module Diagnostics
  class ScoringService
    def self.call(diagnostic, affirmation_counts = {})
      new(diagnostic, affirmation_counts).call
    end

    def initialize(diagnostic, affirmation_counts)
      @diagnostic        = diagnostic
      @affirmation_counts = affirmation_counts
    end

    def call
      top_career_data = @diagnostic.score_data["top_career_ids"] || []

      adjusted = top_career_data.map do |entry|
        bonus = Array(@affirmation_counts[entry["id"]]).length
        { "id" => entry["id"], "score" => entry["score"].to_i + bonus }
      end.sort_by { |e| -e["score"] }

      primary   = Career.find_by(id: adjusted.dig(0, "id"))
      secondary = Career.find_by(id: adjusted.dig(1, "id"))

      @diagnostic.update!(
        primary_career:       primary,
        complementary_career: secondary,
        status:               :pending_payment,
        completed_at:         Time.current
      )
    end
  end
end
```

- [ ] **Step 4: Run ScoringService tests**

```bash
bin/rails test test/services/diagnostics/scoring_service_test.rb
```
Expected: all pass.

- [ ] **Step 5: Add `validation` and `submit_validation` actions**

```ruby
def validation
  top_ids = (@diagnostic.score_data["top_career_ids"] || []).map { |h| h["id"] }
  @top_careers = Career.where(id: top_ids).index_by(&:id).values_at(*top_ids).compact
end

def submit_validation
  affirmation_counts = (params[:affirmations] || {}).to_unsafe_h
  Diagnostics::ScoringService.call(@diagnostic, affirmation_counts)
  redirect_to pay_diagnostic_path(@diagnostic)
end
```

- [ ] **Step 6: Create the validation view**

```erb
<%# app/views/diagnostics/validation.html.erb %>
<div class="max-w-2xl mx-auto px-4 py-8">
  <div class="mb-8">
    <p class="text-xs font-bold uppercase tracking-widest text-[var(--color-primary)] mb-2">Étape 4 sur 4</p>
    <h1 class="text-2xl font-bold text-slate-800">Ces métiers vous correspondent-ils ?</h1>
    <p class="text-slate-500 mt-1">Cochez les affirmations qui vous décrivent vraiment.</p>
  </div>

  <%= form_with url: submit_validation_diagnostic_path(@diagnostic), method: :post, data: { turbo: false } do |f| %>
    <div class="space-y-6">
      <% @top_careers.each_with_index do |career, i| %>
        <% border_colors = %w[border-violet-500 border-cyan-500 border-emerald-500] %>
        <div class="bg-white rounded-2xl border-2 <%= border_colors[i] %> p-6 shadow-sm"
             data-controller="accordion">
          <button type="button"
                  class="w-full flex items-center justify-between text-left"
                  data-action="click->accordion#toggle">
            <div>
              <span class="text-xs font-bold uppercase tracking-widest text-slate-400 block mb-1">
                <%= i == 0 ? "Métier principal" : "Alternative #{i}" %>
              </span>
              <span class="font-bold text-slate-800 text-lg"><%= career.title %></span>
            </div>
            <span class="text-slate-400 text-xl" data-accordion-target="icon">▸</span>
          </button>

          <div class="mt-4 space-y-3" data-accordion-target="content">
            <% (career.affirmations || []).each_with_index do |affirmation, j| %>
              <label class="flex items-start gap-3 cursor-pointer group">
                <input type="checkbox"
                       name="affirmations[<%= career.id %>][]"
                       value="<%= j %>"
                       class="mt-1 accent-[var(--color-primary)]">
                <span class="text-slate-600 group-hover:text-slate-800 text-sm transition-colors">
                  <%= affirmation %>
                </span>
              </label>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>

    <div class="mt-8">
      <%= f.submit "Confirmer et voir mes résultats →",
            class: "w-full py-4 bg-[var(--color-primary)] text-white font-bold rounded-2xl hover:opacity-90 transition-opacity cursor-pointer" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 7: Full end-to-end smoke test**

Complete all 4 steps (interest → disc → competences → validation) in the browser. Confirm redirect to `/diagnostics/:id/pay`.

- [ ] **Step 8: Commit**

```bash
git add app/controllers/diagnostics_controller.rb app/views/diagnostics/validation.html.erb app/services/diagnostics/scoring_service.rb test/services/diagnostics/scoring_service_test.rb
git commit -m "feat: add validation step and rewrite ScoringService with affirmation bonus"
```

---

## Task 10: Admin `DiagnosticQuestion` controller + views

**Files:**
- Create: `app/controllers/admin/diagnostic_questions_controller.rb`
- Create: `app/views/admin/diagnostic_questions/index.html.erb`
- Create: `app/views/admin/diagnostic_questions/new.html.erb`
- Create: `app/views/admin/diagnostic_questions/edit.html.erb`
- Create: `app/views/admin/diagnostic_questions/_form.html.erb`

- [ ] **Step 1: Create the controller**

```ruby
# app/controllers/admin/diagnostic_questions_controller.rb
class Admin::DiagnosticQuestionsController < Admin::BaseController
  before_action :set_assessment, only: [ :index, :new, :create ]
  before_action :set_question,   only: [ :edit, :update, :destroy ]

  def index
    @kind_filter = params[:kind].presence || "all"
    questions = @assessment ? @assessment.diagnostic_questions : DiagnosticQuestion.all
    questions = questions.where(kind: @kind_filter) unless @kind_filter == "all"
    @questions = questions.ordered
  end

  def new
    @question = (@assessment ? @assessment.diagnostic_questions.build : DiagnosticQuestion.new)
  end

  def edit; end

  def create
    @question = @assessment ? @assessment.diagnostic_questions.build(question_params) : DiagnosticQuestion.new(question_params)
    if @question.save
      redirect_to redirect_path, notice: "Question créée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @question.update(question_params)
      redirect_to redirect_path, notice: "Question mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @question.destroy
    redirect_to redirect_path, notice: "Question supprimée."
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:assessment_id]) if params[:assessment_id]
  end

  def set_question
    @question   = DiagnosticQuestion.find(params[:id])
    @assessment = @question.assessment
  end

  def redirect_path
    @assessment ? admin_assessment_diagnostic_questions_path(@assessment) : admin_diagnostic_questions_path
  end

  def question_params
    params.require(:diagnostic_question).permit(
      :kind, :text, :disc_type, :competence_slug, :position, :active,
      options: [ :label, :filiere_slug ]
    )
  end
end
```

- [ ] **Step 2: Create index view**

```erb
<%# app/views/admin/diagnostic_questions/index.html.erb %>
<% content_for :page_title, "Questions du Diagnostic" %>

<%= render "shared/page_header",
    title: @assessment ? "Questions : #{@assessment.title}" : "Questions du Diagnostic",
    subtitle: "Gérer les questions DISC, intérêt thématique et compétences",
    action_text: "Nouvelle Question",
    action_url: @assessment ? new_admin_assessment_diagnostic_question_path(@assessment) : new_admin_diagnostic_question_path,
    action_icon: "plus" %>

<div class="mb-6 flex gap-2">
  <% [["all", "Toutes"], ["interest", "Intérêt"], ["disc", "DISC"], ["competence", "Compétence"]].each do |kind, label| %>
    <%= link_to label,
          @assessment ? admin_assessment_diagnostic_questions_path(@assessment, kind: kind) : admin_diagnostic_questions_path(kind: kind),
          class: "px-4 py-2 rounded-xl text-xs font-bold uppercase tracking-widest transition-all #{@kind_filter == kind ? "bg-[var(--color-primary)] text-white" : "bg-slate-100 text-slate-500 hover:bg-slate-200"}" %>
  <% end %>
</div>

<div class="bg-white rounded-2xl border border-slate-200 overflow-hidden">
  <table class="w-full text-sm">
    <thead class="bg-slate-50 border-b border-slate-200">
      <tr>
        <th class="px-4 py-3 text-left text-xs font-bold uppercase tracking-widest text-slate-400">Type</th>
        <th class="px-4 py-3 text-left text-xs font-bold uppercase tracking-widest text-slate-400">Question</th>
        <th class="px-4 py-3 text-left text-xs font-bold uppercase tracking-widest text-slate-400">Métadonnée</th>
        <th class="px-4 py-3 text-left text-xs font-bold uppercase tracking-widest text-slate-400">Pos.</th>
        <th class="px-4 py-3"></th>
      </tr>
    </thead>
    <tbody class="divide-y divide-slate-100">
      <% @questions.each do |q| %>
        <tr class="hover:bg-slate-50">
          <td class="px-4 py-3">
            <% badge_colors = { "disc" => "bg-violet-100 text-violet-700", "interest" => "bg-amber-100 text-amber-700", "competence" => "bg-emerald-100 text-emerald-700" } %>
            <span class="px-2 py-1 rounded-lg text-xs font-bold <%= badge_colors[q.kind] %>">
              <%= q.kind %>
              <% if q.disc_type.present? %> · <%= q.disc_type %><% end %>
              <% if q.filiere_slug.present? || q.options.any? %> · <%= q.options.first&.dig("filiere_slug") || q.competence_slug %><% end %>
              <% if q.competence_slug.present? %> · <%= q.competence_slug %><% end %>
            </span>
          </td>
          <td class="px-4 py-3 text-slate-700 max-w-xs truncate"><%= q.text %></td>
          <td class="px-4 py-3 text-slate-400 text-xs">
            <%= q.disc_type || q.competence_slug || "#{q.options.length} options" %>
          </td>
          <td class="px-4 py-3 text-slate-400"><%= q.position %></td>
          <td class="px-4 py-3 flex gap-2 justify-end">
            <%= link_to "Modifier", edit_admin_diagnostic_question_path(q), class: "text-xs text-[var(--color-primary)] hover:underline" %>
            <%= button_to "Supprimer", admin_diagnostic_question_path(q), method: :delete,
                  data: { confirm: "Supprimer cette question ?" },
                  class: "text-xs text-red-500 hover:underline bg-transparent border-0 cursor-pointer" %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

- [ ] **Step 3: Create `_form` partial**

```erb
<%# app/views/admin/diagnostic_questions/_form.html.erb %>
<%= form_with model: [:admin, assessment, question], class: "space-y-6 max-w-2xl" do |f| %>
  <% if question.errors.any? %>
    <div class="bg-red-50 border border-red-200 rounded-xl p-4 text-red-700 text-sm">
      <ul><% question.errors.full_messages.each do |msg| %><li><%= msg %></li><% end %></ul>
    </div>
  <% end %>

  <div>
    <%= f.label :kind, "Type de question", class: "block text-sm font-semibold text-slate-700 mb-1" %>
    <%= f.select :kind, [["DISC (personnalité)", "disc"], ["Intérêt thématique", "interest"], ["Compétence", "competence"]],
          {}, class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm",
          data: { action: "change->form-toggle#toggle" } %>
  </div>

  <div>
    <%= f.label :text, "Texte de la question / affirmation", class: "block text-sm font-semibold text-slate-700 mb-1" %>
    <%= f.text_area :text, rows: 2, class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" %>
  </div>

  <div id="disc-fields" class="<%= "hidden" unless question.disc? %>">
    <%= f.label :disc_type, "Type DISC", class: "block text-sm font-semibold text-slate-700 mb-1" %>
    <%= f.select :disc_type, [["D — Dominant", "D"], ["I — Influent", "I"], ["S — Stable", "S"], ["C — Consciencieux", "C"]],
          { include_blank: "— choisir —" }, class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" %>
  </div>

  <div id="competence-fields" class="<%= "hidden" unless question.competence? %>">
    <%= f.label :competence_slug, "Slug de compétence", class: "block text-sm font-semibold text-slate-700 mb-1" %>
    <%= f.select :competence_slug,
          %w[langues_etrangeres communication_ecrite communication_orale analyse_donnees gestion_projet numerique negociation creativite ecoute rigueur_scientifique culture_generale droit_politiques],
          { include_blank: "— choisir —" }, class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" %>
  </div>

  <div>
    <%= f.label :position, "Position (ordre d'affichage)", class: "block text-sm font-semibold text-slate-700 mb-1" %>
    <%= f.number_field :position, min: 1, class: "w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" %>
  </div>

  <div class="flex items-center gap-2">
    <%= f.check_box :active, class: "accent-[var(--color-primary)]" %>
    <%= f.label :active, "Active", class: "text-sm font-semibold text-slate-700" %>
  </div>

  <div class="flex gap-3">
    <%= f.submit question.persisted? ? "Mettre à jour" : "Créer",
          class: "px-6 py-3 bg-[var(--color-primary)] text-white font-bold rounded-xl hover:opacity-90 transition-opacity cursor-pointer" %>
    <%= link_to "Annuler", assessment ? admin_assessment_diagnostic_questions_path(assessment) : admin_diagnostic_questions_path,
          class: "px-6 py-3 bg-slate-100 text-slate-600 font-bold rounded-xl hover:bg-slate-200 transition-colors" %>
  </div>
<% end %>
```

- [ ] **Step 4: Create new and edit views**

```erb
<%# app/views/admin/diagnostic_questions/new.html.erb %>
<% content_for :page_title, "Nouvelle Question" %>
<%= render "shared/page_header", title: "Nouvelle Question du Diagnostic",
    subtitle: @assessment ? "Évaluation : #{@assessment.title}" : nil,
    action_text: "Retour", action_url: @assessment ? admin_assessment_diagnostic_questions_path(@assessment) : admin_diagnostic_questions_path,
    action_icon: "arrow-left", action_type: :secondary %>
<%= render "form", question: @question, assessment: @assessment %>
```

```erb
<%# app/views/admin/diagnostic_questions/edit.html.erb %>
<% content_for :page_title, "Modifier Question" %>
<%= render "shared/page_header", title: "Modifier la Question",
    action_text: "Retour", action_url: admin_assessment_diagnostic_questions_path(@assessment),
    action_icon: "arrow-left", action_type: :secondary %>
<%= render "form", question: @question, assessment: @assessment %>
```

- [ ] **Step 5: Verify admin routes work**

```bash
bin/rails routes | grep diagnostic_question
```
Confirm routes like `admin_assessment_diagnostic_questions` and `admin_diagnostic_questions` are present.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/admin/diagnostic_questions_controller.rb app/views/admin/diagnostic_questions/
git commit -m "feat: add admin DiagnosticQuestion CRUD (replaces AssessmentQuestion admin)"
```

---

## Task 11: Update `db/seeds.rb` with full diagnostic data

**Files:**
- Modify: `db/seeds.rb`

- [ ] **Step 1: Replace the careers and questions sections of seeds.rb**

Replace the entire careers + assessment + questions section (keep only the admin user creation and mobile operators at the top). The new seeds follow the HTML prototype data exactly.

```ruby
# db/seeds.rb
# Keep existing admin user and mobile operators seeding at the top, then:

# ===== ASSESSMENT =====
assessment = Assessment.find_or_initialize_by(title: "Diagnostic Langues & Métiers")
assessment.assign_attributes(description: "Diagnostic d'orientation par profil DISC, intérêt thématique et compétences.", active: true)
assessment.save!

# ===== 37 MÉTIERS (Career) =====
careers_data = [
  { title: "Traducteur / Interprète",                  filiere_slug: "langues",   disc_types: %w[C S], required_competences: %w[langues_etrangeres communication_ecrite culture_generale],        affirmations: ["Je suis passionné(e) par les nuances linguistiques entre les langues.", "Je peux reformuler un texte complexe sans en perdre le sens.", "Je suis à l'aise pour travailler seul(e) de façon concentrée et rigoureuse.", "J'aime décoder les subtilités culturelles derrière les mots.", "Je peux jongler entre plusieurs langues dans une même journée."] },
  { title: "Chargé de communication internationale",   filiere_slug: "langues",   disc_types: %w[I D], required_competences: %w[communication_ecrite communication_orale langues_etrangeres],     affirmations: ["J'aime concevoir des messages clairs pour des publics internationaux.", "Je maîtrise les codes culturels de différents pays.", "Je me sens à l'aise pour représenter une organisation à l'extérieur.", "Adapter un discours à différentes audiences m'intéresse.", "La communication interculturelle est une force que je veux développer."] },
  { title: "Responsable export",                       filiere_slug: "langues",   disc_types: %w[D I], required_competences: %w[negociation langues_etrangeres gestion_projet],                    affirmations: ["Je suis attiré(e) par le commerce international et les marchés étrangers.", "Négocier des contrats avec des partenaires étrangers m'attire.", "Je suis capable de gérer une équipe commerciale à distance.", "Les voyages professionnels fréquents ne me posent pas de problème.", "Je suis motivé(e) par les objectifs chiffrés et les résultats mesurables."] },
  { title: "Localisation Manager",                     filiere_slug: "langues",   disc_types: %w[C S], required_competences: %w[langues_etrangeres gestion_projet numerique],                      affirmations: ["Adapter un produit numérique à différentes cultures m'intéresse.", "Je comprends les enjeux techniques de la traduction logicielle.", "Gérer des projets multilingues avec plusieurs prestataires me plaît.", "La qualité et la cohérence des contenus sont primordiales pour moi.", "Je suis à l'aise avec les outils de gestion de la traduction (CAT tools)."] },
  { title: "Diplomate",                                filiere_slug: "langues",   disc_types: %w[D C], required_competences: %w[langues_etrangeres negociation droit_politiques],                  affirmations: ["Les relations internationales et la géopolitique me passionnent.", "Je suis capable de défendre une position complexe avec tact et conviction.", "Représenter un État ou une institution dans un contexte formel m'attire.", "Je maîtrise les règles du protocole diplomatique.", "Je suis prêt(e) à m'expatrier pour des missions de longue durée."] },
  { title: "Urbaniste",                                filiere_slug: "geo",       disc_types: %w[C S], required_competences: %w[analyse_donnees gestion_projet droit_politiques],                  affirmations: ["Concevoir des villes durables et inclusives est un projet qui me tient à cœur.", "J'aime analyser les usages des espaces publics.", "Je peux lire et produire des plans d'aménagement urbain.", "Équilibrer contraintes réglementaires et vision créative m'intéresse.", "Travailler avec des élus, des habitants et des techniciens me convient."] },
  { title: "Cartographe / Géomaticien",                filiere_slug: "geo",       disc_types: %w[C S], required_competences: %w[analyse_donnees numerique rigueur_scientifique],                   affirmations: ["La cartographie et la représentation spatiale des données m'enthousiasment.", "Je maîtrise ou souhaite maîtriser des outils SIG comme QGIS ou ArcGIS.", "Les données géographiques sont pour moi une source d'informations précieuse.", "Je peux synthétiser des informations complexes en une carte lisible.", "L'exactitude et la rigueur dans la représentation graphique sont essentielles."] },
  { title: "Consultant en développement local",        filiere_slug: "geo",       disc_types: %w[D I], required_competences: %w[gestion_projet negociation analyse_donnees],                       affirmations: ["Aider des territoires défavorisés à se redynamiser est une vocation pour moi.", "Je suis à l'aise pour mener des diagnostics territoriaux.", "Coordonner des acteurs publics, privés et associatifs me plaît.", "Je peux rédiger des rapports d'analyse pour des décideurs.", "Les enjeux de développement rural et péri-urbain m'intéressent."] },
  { title: "Chargé de mission environnement",          filiere_slug: "geo",       disc_types: %w[S C], required_competences: %w[rigueur_scientifique communication_ecrite gestion_projet],         affirmations: ["Les questions environnementales et écologiques sont au cœur de mes valeurs.", "Je peux rédiger des études d'impact et des plans d'action environnementaux.", "Sensibiliser des équipes à la démarche RSE m'enthousiasme.", "Je suis capable de suivre des indicateurs environnementaux sur le long terme.", "Collaborer avec des services techniques et des partenaires institutionnels me convient."] },
  { title: "UX Researcher",                            filiere_slug: "socio",     disc_types: %w[C S], required_competences: %w[analyse_donnees communication_ecrite numerique],                   affirmations: ["Comprendre les comportements humains face aux interfaces numériques m'intéresse.", "Je suis à l'aise pour concevoir et animer des entretiens utilisateurs.", "J'aime synthétiser des données qualitatives en recommandations actionnables.", "Les méthodologies de recherche (observation, test A/B, persona) me sont familières.", "Travailler en équipe avec des designers et des développeurs me plaît."] },
  { title: "Statisticien social",                      filiere_slug: "socio",     disc_types: %w[C S], required_competences: %w[analyse_donnees rigueur_scientifique numerique],                   affirmations: ["L'analyse statistique de données sociales est une activité qui m'enthousiasme.", "Je maîtrise ou veux maîtriser des outils comme R, SPSS ou Python.", "Transformer des chiffres bruts en insights exploitables est un défi qui me motive.", "Je suis rigoureux(se) dans le traitement et la vérification des données.", "Produire des rapports quantitatifs pour des décideurs m'intéresse."] },
  { title: "Consultant D&I",                           filiere_slug: "socio",     disc_types: %w[I S], required_competences: %w[communication_orale negociation culture_generale],                 affirmations: ["Promouvoir la diversité et l'inclusion au sein des organisations est une mission qui me tient à cœur.", "Je suis capable d'animer des formations sur la discrimination et les biais inconscients.", "Accompagner des changements culturels au sein des entreprises m'attire.", "Je peux concevoir des politiques RH inclusives.", "Travailler avec des directions générales sur des sujets sensibles ne me fait pas peur."] },
  { title: "Chargé de projet ONG",                     filiere_slug: "socio",     disc_types: %w[S I], required_competences: %w[gestion_projet communication_orale langues_etrangeres],            affirmations: ["Je suis motivé(e) par les causes humanitaires et sociales.", "Coordonner des projets de terrain dans des contextes difficiles m'attire.", "Je peux gérer un budget et rédiger des rapports pour des bailleurs de fonds.", "Travailler dans des environnements multiculturels et souvent précaires me convient.", "La mobilité internationale est compatible avec mon mode de vie."] },
  { title: "Analyste en intelligence culturelle",      filiere_slug: "socio",     disc_types: %w[C I], required_competences: %w[analyse_donnees langues_etrangeres culture_generale],              affirmations: ["L'analyse des identités culturelles dans un contexte globalisé m'intéresse.", "Je peux produire des études sur les comportements interculturels pour des entreprises.", "Je maîtrise des méthodologies mixtes (quantitatives et qualitatives).", "Conseiller des organisations sur leur stratégie interculturelle m'attire.", "Les questions d'appartenance, de représentation et de culture organisationnelle me passionnent."] },
  { title: "UX Writer",                                filiere_slug: "lettres",   disc_types: %w[C S], required_competences: %w[communication_ecrite numerique creativite],                        affirmations: ["Rédiger des contenus clairs pour des applications numériques m'intéresse.", "Je comprends les principes de l'expérience utilisateur (UX).", "Je peux adapter mon style d'écriture à différents tons et contextes.", "La cohérence éditoriale dans un produit digital est primordiale pour moi.", "Collaborer avec des designers et des chefs de produit me plaît."] },
  { title: "Content Designer",                         filiere_slug: "lettres",   disc_types: %w[I C], required_competences: %w[creativite communication_ecrite numerique],                        affirmations: ["Concevoir des expériences de contenu engageantes pour le numérique m'enthousiasme.", "Je mêle stratégie éditoriale et sens du design.", "Je peux créer des contenus interactifs et pédagogiques.", "Tester et itérer sur des formats de contenu est une démarche que j'apprécie.", "Je suis à l'aise avec les outils de prototypage et de création de contenu."] },
  { title: "Correcteur / Réviseur éditorial",          filiere_slug: "lettres",   disc_types: %w[C S], required_competences: %w[communication_ecrite rigueur_scientifique culture_generale],       affirmations: ["La relecture minutieuse de textes est une activité que je pratique avec plaisir.", "Je détecte instinctivement les erreurs de syntaxe, d'orthographe et de style.", "Je connais les normes typographiques et éditoriales professionnelles.", "Je peux travailler sur des volumes importants de textes avec concentration.", "La langue française et ses règles me fascinent."] },
  { title: "Auteur / Scénariste",                      filiere_slug: "lettres",   disc_types: %w[I C], required_competences: %w[creativite communication_ecrite culture_generale],                 affirmations: ["Écrire des histoires ou des scénarios est une passion qui me définit.", "Je peux développer des univers narratifs cohérents et originaux.", "La fiction comme outil de réflexion sur la société m'intéresse.", "Je suis prêt(e) à accepter l'incertitude économique liée à la carrière d'auteur.", "Les processus créatifs et la réécriture font partie intégrante de mon travail."] },
  { title: "Responsable éditorial",                    filiere_slug: "lettres",   disc_types: %w[D C], required_competences: %w[gestion_projet communication_ecrite creativite],                   affirmations: ["Piloter la ligne éditoriale d'une revue, d'un éditeur ou d'un média m'attire.", "Je peux gérer une équipe de rédacteurs et de correcteurs.", "L'identification de nouveaux talents et sujets éditoriaux m'enthousiasme.", "Je comprends les enjeux économiques de l'édition (ventes, droits, diffusion).", "Arbitrer entre créativité et contraintes commerciales est un défi que j'accepte."] },
  { title: "Consultant RH / DRH",                      filiere_slug: "psycho",    disc_types: %w[D I], required_competences: %w[negociation communication_orale gestion_projet],                   affirmations: ["Accompagner les organisations dans leur gestion des ressources humaines m'intéresse.", "Je peux mener des audits RH et proposer des plans d'amélioration.", "La négociation sociale et le dialogue avec les partenaires sociaux ne me font pas peur.", "Je suis à l'aise pour présenter des recommandations à des comités de direction.", "Les enjeux de transformation des organisations (digitalisation, RSE) m'animent."] },
  { title: "Psychologue du travail",                   filiere_slug: "psycho",    disc_types: %w[S C], required_competences: %w[communication_orale rigueur_scientifique ecoute],                  affirmations: ["Comprendre les dynamiques psychologiques au sein des organisations m'intéresse.", "Je peux réaliser des bilans de compétences et des évaluations psychométriques.", "Accompagner des personnes en souffrance au travail (burnout, conflits) m'attire.", "Je maîtrise ou veux maîtriser les outils d'évaluation psychologique (MBTI, 16PF…).", "Intervenir dans des contextes de crise organisationnelle me convient."] },
  { title: "Coach professionnel",                      filiere_slug: "psycho",    disc_types: %w[I S], required_competences: %w[communication_orale ecoute negociation],                           affirmations: ["Accompagner des individus dans leur développement personnel et professionnel est ma vocation.", "Je pose des questions puissantes plutôt que de donner des réponses toutes faites.", "Je suis à l'aise pour créer un espace de confiance et de bienveillance.", "Les techniques de coaching (PNL, analyse transactionnelle, pleine conscience) m'intéressent.", "Je suis prêt(e) à me certifier et à exercer en libéral."] },
  { title: "Ingénieur pédagogique",                    filiere_slug: "psycho",    disc_types: %w[C S], required_competences: %w[gestion_projet numerique communication_ecrite],                    affirmations: ["Concevoir des dispositifs de formation sur mesure m'enthousiasme.", "Je maîtrise ou veux maîtriser des logiciels de création e-learning (Articulate, Rise…).", "Adapter les contenus aux besoins des apprenants adultes m'intéresse.", "Je travaille de façon méthodique selon des référentiels pédagogiques reconnus.", "Collaborer avec des experts métier pour structurer leurs savoirs me plaît."] },
  { title: "Ergonome",                                 filiere_slug: "psycho",    disc_types: %w[C S], required_competences: %w[analyse_donnees rigueur_scientifique numerique],                   affirmations: ["Améliorer les conditions de travail et les interfaces homme-machine m'intéresse.", "Je peux réaliser des analyses d'activité et des études de poste.", "La prévention des risques professionnels (TMS, RPS) est un enjeu qui me mobilise.", "Je suis à l'aise pour observer, interviewer et synthétiser des données de terrain.", "Travailler à l'interface entre technique, humain et organisation me convient."] },
  { title: "Éthicien en IA",                           filiere_slug: "philo",     disc_types: %w[C D], required_competences: %w[rigueur_scientifique communication_ecrite numerique],              affirmations: ["Les enjeux éthiques liés à l'intelligence artificielle me préoccupent profondément.", "Je peux analyser des systèmes algorithmiques pour en déceler les biais.", "Rédiger des chartes éthiques et des cadres de gouvernance des données m'intéresse.", "Je suis capable de vulgariser des concepts complexes pour des publics non techniques.", "Travailler avec des équipes techniques, juridiques et managériales me convient."] },
  { title: "Analyste en politiques publiques",         filiere_slug: "philo",     disc_types: %w[C D], required_competences: %w[analyse_donnees droit_politiques communication_ecrite],            affirmations: ["L'évaluation des politiques publiques et leur impact social m'intéresse.", "Je peux produire des notes de synthèse pour des décideurs politiques.", "La modélisation des effets des réformes sur les populations m'attire.", "Je suis à l'aise avec les sources institutionnelles (rapports, données officielles).", "Travailler dans un think tank, un cabinet ou une administration centrale me motive."] },
  { title: "Consultant en stratégie",                  filiere_slug: "philo",     disc_types: %w[D C], required_competences: %w[negociation analyse_donnees gestion_projet],                      affirmations: ["Résoudre des problèmes complexes pour des organisations est ce qui me motive le plus.", "Je peux structurer un raisonnement en hypothèses et recommandations claires.", "Travailler dans des secteurs variés sur des missions courtes et intenses me convient.", "Les outils de la stratégie (SWOT, matrices de portefeuille, business cases) me sont naturels.", "Je suis prêt(e) à investir du temps dans des missions exigeantes à fort enjeu."] },
  { title: "Rédacteur juridique",                      filiere_slug: "philo",     disc_types: %w[C S], required_competences: %w[communication_ecrite droit_politiques rigueur_scientifique],       affirmations: ["La rédaction de textes juridiques précis et sans ambiguïté m'attire.", "Je comprends la structure et la logique des textes de droit.", "Adapter un langage technique à des non-juristes est une compétence que j'affectionne.", "Je peux rédiger des contrats, notes juridiques et supports de conformité.", "La rigueur terminologique dans le domaine juridique est une priorité pour moi."] },
  { title: "Archiviste / Documentaliste",              filiere_slug: "histoire",  disc_types: %w[C S], required_competences: %w[rigueur_scientifique culture_generale numerique],                  affirmations: ["La conservation et la valorisation des archives historiques me passionnent.", "Je peux classer, indexer et numériser des fonds documentaires.", "L'accès à la mémoire collective et institutionnelle est une mission qui a du sens pour moi.", "Je suis rigoureux(se) et méthodique dans le traitement des documents.", "Travailler en bibliothèque, aux Archives nationales ou en entreprise me convient."] },
  { title: "Médiateur culturel",                       filiere_slug: "histoire",  disc_types: %w[I S], required_competences: %w[communication_orale culture_generale creativite],                  affirmations: ["Mettre en relation le public avec le patrimoine culturel et artistique m'enthousiasme.", "Je peux concevoir et animer des visites, ateliers et événements culturels.", "La médiation entre les œuvres et les publics éloignés de la culture m'intéresse.", "Je suis à l'aise pour parler devant des groupes variés (enfants, adultes, scolaires).", "Travailler dans des musées, centres d'art ou territoires culturels me motive."] },
  { title: "Guide touristique / patrimonial",          filiere_slug: "histoire",  disc_types: %w[I S], required_competences: %w[communication_orale langues_etrangeres culture_generale],          affirmations: ["Partager ma passion pour l'histoire et le patrimoine avec des visiteurs me comble.", "Je suis à l'aise pour parler en public de façon dynamique et pédagogique.", "Je peux m'adapter à des publics très différents (touristes, scolaires, professionnels).", "Maîtriser plusieurs langues pour guider des groupes internationaux m'attire.", "Travailler dans des sites patrimoniaux ou touristiques est un environnement qui me plaît."] },
  { title: "Data analyst culturel",                    filiere_slug: "histoire",  disc_types: %w[C D], required_competences: %w[analyse_donnees numerique culture_generale],                       affirmations: ["L'analyse de données culturelles (fréquentation, pratiques, tendances) m'intéresse.", "Je maîtrise ou veux maîtriser des outils comme Excel, Python ou Tableau.", "Trouver des insights dans les données pour éclairer des décisions culturelles m'attire.", "Je peux produire des tableaux de bord et des rapports analytiques.", "Travailler au service d'institutions culturelles (musées, collectivités, médias) me motive."] },
  { title: "Instructional Designer",                   filiere_slug: "edu",       disc_types: %w[C S], required_competences: %w[gestion_projet numerique communication_ecrite],                    affirmations: ["Concevoir des parcours de formation engageants et efficaces est ma vocation.", "Je travaille en étroite collaboration avec des experts pour structurer leurs connaissances.", "Les théories de l'apprentissage (cognitivisme, socioconstructivisme) me guident.", "Je peux produire des storyboards et des modules e-learning complets.", "L'évaluation de l'efficacité des formations est une étape que j'inclus systématiquement."] },
  { title: "Formateur",                                filiere_slug: "edu",       disc_types: %w[I S], required_competences: %w[communication_orale ecoute creativite],                            affirmations: ["Transmettre des compétences et des savoirs à des adultes est une passion.", "Je peux animer des sessions de formation de façon dynamique et inclusive.", "Adapter mon discours pédagogique à des profils et niveaux très différents me plaît.", "Je crée des supports de formation clairs et attractifs (slides, fiches, vidéos).", "Le feedback des apprenants m'aide à m'améliorer continuellement."] },
  { title: "Chef de projet e-learning",                filiere_slug: "edu",       disc_types: %w[D C], required_competences: %w[gestion_projet numerique negociation],                            affirmations: ["Piloter des projets de formation en ligne de A à Z m'intéresse.", "Je coordonne des équipes pluridisciplinaires (pédagogues, développeurs, graphistes).", "Je maîtrise ou veux maîtriser des LMS comme Moodle, 360Learning ou Cornerstone.", "Respecter des délais, des budgets et des cahiers des charges est une discipline naturelle pour moi.", "L'innovation pédagogique (serious game, social learning, IA) m'enthousiasme."] },
  { title: "Conseiller en orientation",                filiere_slug: "edu",       disc_types: %w[S I], required_competences: %w[ecoute communication_orale culture_generale],                      affirmations: ["Accompagner des individus dans leurs choix de carrière est un métier qui a du sens pour moi.", "Je sais écouter sans juger et reformuler avec précision.", "Je connais les mécanismes du marché du travail et les dispositifs d'orientation.", "Aider une personne à identifier ses forces et ses valeurs est un exercice que j'apprécie.", "Travailler dans un lycée, une université ou un cabinet de conseil en évolution professionnelle me convient."] },
  { title: "Consultant en transformation digitale",    filiere_slug: "edu",       disc_types: %w[D C], required_competences: %w[numerique gestion_projet negociation],                            affirmations: ["Accompagner des organisations dans leur transformation numérique m'enthousiasme.", "Je comprends les enjeux stratégiques liés à la data, l'IA et les nouveaux usages.", "Je peux diagnostiquer la maturité digitale d'une organisation et proposer une feuille de route.", "La gestion du changement et l'accompagnement humain dans les projets digitaux m'intéressent.", "Travailler en transverse avec les directions métier, IT et RH me convient."] }
]

careers_data.each do |attrs|
  career = Career.find_or_initialize_by(title: attrs[:title])
  career.assign_attributes(
    status: :published,
    filiere_slug: attrs[:filiere_slug],
    disc_types: attrs[:disc_types],
    required_competences: attrs[:required_competences],
    affirmations: attrs[:affirmations]
  )
  career.save!
  career.trajectories.create!(axe_1: "Poste junior dans une organisation — première expérience terrain.", axe_2: "Montée en responsabilités — expert ou chef de projet.", axe_3: "Expert reconnu ou consultant indépendant — leadership sectoriel.") unless career.trajectories.exists?
end
puts "✓ #{Career.diagnostic.count} métiers avec profil diagnostic"

# ===== 8 QUESTIONS D'INTÉRÊT THÉMATIQUE =====
interest_questions = [
  { text: "Parmi ces activités, laquelle vous attire le plus ?", position: 1,
    options: [{ "label" => "Écrire, analyser des textes et décoder des métaphores", "filiere_slug" => "lettres" }, { "label" => "Comprendre pourquoi les sociétés fonctionnent comme elles le font", "filiere_slug" => "socio" }, { "label" => "Analyser des cartes et comprendre les dynamiques territoriales", "filiere_slug" => "geo" }, { "label" => "Apprendre et maîtriser des langues étrangères", "filiere_slug" => "langues" }] },
  { text: "Si vous deviez choisir un projet dans votre formation, vous préféreriez :", position: 2,
    options: [{ "label" => "Rédiger une analyse critique d'une œuvre ou d'un texte", "filiere_slug" => "lettres" }, { "label" => "Mener une enquête sur un groupe social ou une communauté", "filiere_slug" => "socio" }, { "label" => "Réaliser une étude géographique ou environnementale d'un territoire", "filiere_slug" => "geo" }, { "label" => "Traduire ou adapter un contenu pour un public étranger", "filiere_slug" => "langues" }] },
  { text: "Le travail qui vous donnerait le plus de sens serait de :", position: 3,
    options: [{ "label" => "Transmettre un savoir, former et accompagner des apprenants", "filiere_slug" => "edu" }, { "label" => "Aider des individus à traverser des difficultés personnelles", "filiere_slug" => "psycho" }, { "label" => "Défendre une idée ou une cause avec des arguments solides", "filiere_slug" => "philo" }, { "label" => "Valoriser un patrimoine historique ou culturel oublié", "filiere_slug" => "histoire" }] },
  { text: "Vous êtes naturellement plus à l'aise avec :", position: 4,
    options: [{ "label" => "Les concepts abstraits, l'argumentation et les grands débats", "filiere_slug" => "philo" }, { "label" => "Les données, les statistiques et les analyses quantitatives", "filiere_slug" => "socio" }, { "label" => "Les relations humaines, l'écoute et l'empathie", "filiere_slug" => "psycho" }, { "label" => "La créativité, l'écriture et la narration", "filiere_slug" => "lettres" }] },
  { text: "Si vous pouviez transformer un hobby en métier, ce serait :", position: 5,
    options: [{ "label" => "Écrire des articles, des histoires ou des analyses", "filiere_slug" => "lettres" }, { "label" => "Comprendre et expliquer les comportements humains", "filiere_slug" => "psycho" }, { "label" => "Concevoir des solutions pour améliorer un territoire ou une ville", "filiere_slug" => "geo" }, { "label" => "Enseigner, animer des ateliers ou créer des formations", "filiere_slug" => "edu" }] },
  { text: "Votre entourage vous décrit plutôt comme quelqu'un qui :", position: 6,
    options: [{ "label" => "Maîtrise ou apprend facilement les langues étrangères", "filiere_slug" => "langues" }, { "label" => "Réfléchit profondément avant d'agir et questionne tout", "filiere_slug" => "philo" }, { "label" => "S'intéresse à l'histoire, aux origines et aux civilisations", "filiere_slug" => "histoire" }, { "label" => "Aime aider les autres et trouver des solutions aux problèmes humains", "filiere_slug" => "psycho" }] },
  { text: "Dans une équipe, vous aimez apporter :", position: 7,
    options: [{ "label" => "Une vision analytique et une capacité à traiter des données complexes", "filiere_slug" => "socio" }, { "label" => "Une maîtrise des langues et une aisance avec les partenaires internationaux", "filiere_slug" => "langues" }, { "label" => "La compréhension des dynamiques humaines et relationnelles du groupe", "filiere_slug" => "psycho" }, { "label" => "Une organisation rigoureuse et des approches pédagogiques structurées", "filiere_slug" => "edu" }] },
  { text: "Ce qui vous passionne le plus dans vos études, c'est :", position: 8,
    options: [{ "label" => "Décoder les textes, les langues et la richesse du langage", "filiere_slug" => "lettres" }, { "label" => "Comprendre les grandes transformations sociales et politiques", "filiere_slug" => "socio" }, { "label" => "Analyser l'espace, les territoires et les phénomènes géographiques", "filiere_slug" => "geo" }, { "label" => "Explorer les grandes questions philosophiques, éthiques ou historiques", "filiere_slug" => "philo" }] }
]

interest_questions.each do |q|
  DiagnosticQuestion.find_or_initialize_by(assessment: assessment, position: q[:position], kind: "interest").tap do |dq|
    dq.text    = q[:text]
    dq.options = q[:options]
    dq.active  = true
    dq.save!
  end
end
puts "✓ #{DiagnosticQuestion.where(assessment: assessment, kind: 'interest').count} questions d'intérêt"

# ===== 16 QUESTIONS DISC =====
disc_questions = [
  { text: "Je prends facilement des décisions même sous pression.",                    disc_type: "D", position: 9 },
  { text: "J'aime diriger des projets et déléguer les tâches.",                         disc_type: "D", position: 10 },
  { text: "Je préfère agir vite plutôt que d'attendre la perfection.",                  disc_type: "D", position: 11 },
  { text: "J'assume la responsabilité des résultats, bons ou mauvais.",                 disc_type: "D", position: 12 },
  { text: "J'adore rencontrer de nouvelles personnes et élargir mon réseau.",           disc_type: "I", position: 13 },
  { text: "Je convaincs facilement mon entourage avec enthousiasme.",                   disc_type: "I", position: 14 },
  { text: "En groupe, j'aime animer et créer une bonne ambiance.",                      disc_type: "I", position: 15 },
  { text: "Je me motive par la reconnaissance et les encouragements.",                   disc_type: "I", position: 16 },
  { text: "Je préfère les environnements stables et prévisibles.",                       disc_type: "S", position: 17 },
  { text: "Je suis à l'écoute et j'aide volontiers mes collègues.",                     disc_type: "S", position: 18 },
  { text: "Je prends le temps d'analyser avant de changer mes habitudes.",               disc_type: "S", position: 19 },
  { text: "Je suis loyal(e) et m'implique sur le long terme dans mes engagements.",     disc_type: "S", position: 20 },
  { text: "Je travaille avec méthode et j'attache de l'importance aux détails.",        disc_type: "C", position: 21 },
  { text: "Je vérifie plusieurs fois avant de rendre un travail.",                       disc_type: "C", position: 22 },
  { text: "Je me documente en profondeur avant de prendre position.",                    disc_type: "C", position: 23 },
  { text: "Je préfère les règles claires et les processus bien définis.",                disc_type: "C", position: 24 }
]

disc_questions.each do |q|
  DiagnosticQuestion.find_or_initialize_by(assessment: assessment, position: q[:position], kind: "disc").tap do |dq|
    dq.text       = q[:text]
    dq.disc_type  = q[:disc_type]
    dq.active     = true
    dq.save!
  end
end
puts "✓ #{DiagnosticQuestion.where(assessment: assessment, kind: 'disc').count} questions DISC"

# ===== 12 QUESTIONS COMPÉTENCES =====
competence_questions = [
  { text: "Je parle couramment au moins une langue étrangère.",                                              competence_slug: "langues_etrangeres",    position: 25 },
  { text: "Je rédige des textes clairs, structurés et adaptés à mon audience.",                              competence_slug: "communication_ecrite",  position: 26 },
  { text: "Je m'exprime avec aisance en public ou face à des interlocuteurs variés.",                        competence_slug: "communication_orale",   position: 27 },
  { text: "Je sais collecter, traiter et interpréter des données (qualitatives ou quantitatives).",          competence_slug: "analyse_donnees",       position: 28 },
  { text: "Je peux planifier, coordonner et suivre un projet de A à Z.",                                     competence_slug: "gestion_projet",        position: 29 },
  { text: "Je maîtrise des outils numériques avancés (tableurs, logiciels métier, code…).",                  competence_slug: "numerique",             position: 30 },
  { text: "Je suis capable de défendre une position et trouver des compromis satisfaisants.",                competence_slug: "negociation",           position: 31 },
  { text: "J'ai une forte capacité à imaginer des solutions ou des contenus originaux.",                     competence_slug: "creativite",            position: 32 },
  { text: "Je comprends les besoins implicites de mes interlocuteurs avec empathie.",                        competence_slug: "ecoute",                position: 33 },
  { text: "Je travaille de façon précise, vérifiable et conforme aux standards de mon domaine.",             competence_slug: "rigueur_scientifique",   position: 34 },
  { text: "J'ai une bonne connaissance historique, littéraire, artistique et géopolitique.",                 competence_slug: "culture_generale",      position: 35 },
  { text: "Je comprends le cadre juridique, réglementaire et institutionnel de mon secteur.",                competence_slug: "droit_politiques",      position: 36 }
]

competence_questions.each do |q|
  DiagnosticQuestion.find_or_initialize_by(assessment: assessment, position: q[:position], kind: "competence").tap do |dq|
    dq.text            = q[:text]
    dq.competence_slug = q[:competence_slug]
    dq.active          = true
    dq.save!
  end
end
puts "✓ #{DiagnosticQuestion.where(assessment: assessment, kind: 'competence').count} questions compétences"
```

- [ ] **Step 2: Run seeds**

```bash
bin/rails db:seed
```
Expected output includes:
```
✓ 37 métiers avec profil diagnostic
✓ 8 questions d'intérêt
✓ 16 questions DISC
✓ 12 questions compétences
```

- [ ] **Step 3: Full end-to-end smoke test with real data**

Start the server, create a new diagnostic as any logged-in user, complete all 4 steps with real seeded questions, confirm the redirect to the payment page, and confirm `Diagnostic.last.primary_career` is set.

```bash
bin/rails console
Diagnostic.last.primary_career&.title
Diagnostic.last.complementary_career&.title
Diagnostic.last.score_data.keys
```
Expected: a career title and keys `["disc_scores", "filiere_scores", "competence_scores", "top_career_ids"]`.

- [ ] **Step 4: Commit**

```bash
git add db/seeds.rb
git commit -m "feat: seed 37 métiers diagnostics + 36 questions DISC/intérêt/compétences"
```

---

## Task 12: Cleanup — drop `assessment_questions`, remove dead code

**Files:**
- Create: `db/migrate/YYYYMMDDHHMMSS_drop_assessment_questions.rb`
- Modify: `app/models/diagnostic_answer.rb`
- Modify: `app/models/assessment.rb`
- Modify: `app/models/career.rb`
- Modify: `app/controllers/diagnostics_controller.rb` (remove `assessment` and `submit_bloc` actions)

- [ ] **Step 1: Verify no live code references `assessment_question`**

```bash
grep -r "assessment_question" app/ config/ --include="*.rb" --include="*.erb" -l
```
Expected: only `app/models/diagnostic_answer.rb` and possibly old admin views. Fix any remaining references before continuing.

- [ ] **Step 2: Generate the cleanup migration**

```bash
bin/rails generate migration DropAssessmentQuestionsAndCleanDiagnosticAnswers
```

Edit the generated file:

```ruby
class DropAssessmentQuestionsAndCleanDiagnosticAnswers < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :diagnostic_answers, :assessment_questions
    remove_column :diagnostic_answers, :assessment_question_id
    drop_table :assessment_questions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

```bash
bin/rails db:migrate
```

- [ ] **Step 3: Remove `assessment_question_id` reference from DiagnosticAnswer**

In `app/models/diagnostic_answer.rb`, remove the line:
```ruby
belongs_to :assessment_question  # remove this line
```

- [ ] **Step 4: Remove `has_many :assessment_questions` from Assessment**

In `app/models/assessment.rb`, remove:
```ruby
has_many :assessment_questions, -> { order(:bloc, :position) }, dependent: :destroy
```
(The `has_many :diagnostic_questions` added in Task 1 replaces it.)

- [ ] **Step 5: Remove `assessment` and `submit_bloc` actions from DiagnosticsController**

Delete the `assessment` and `submit_bloc` action methods entirely from `app/controllers/diagnostics_controller.rb`.

- [ ] **Step 6: Run full test suite**

```bash
bin/rails test
```
Expected: all tests pass. Fix any failures before continuing.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "chore: drop assessment_questions table and remove legacy diagnostic actions"
```

---

## Self-Review

**Spec coverage check:**
- ✅ Full replacement of existing diagnostic — Tasks 1-3 replace the data model
- ✅ DiagnosticQuestion model (disc/interest/competence kinds) — Task 1
- ✅ Career gains disc_types, filiere_slug, required_competences, affirmations — Task 2
- ✅ Flow: interest → disc → competences → validation → payment → results — Tasks 4-9
- ✅ Filière inferred from interest answers (not asked directly) — Tasks 5, 8
- ✅ DISC Likert 1-5 — Tasks 6, 8
- ✅ PreScoringService ranks careers — Task 8
- ✅ ScoringService applies affirmation bonus, sets primary/complementary — Task 9
- ✅ Admin interface for DiagnosticQuestion — Task 10
- ✅ Seeds with all 37 careers + 36 questions from HTML prototype — Task 11
- ✅ Cleanup of old tables — Task 12
- ✅ `show` redirect handles all steps — Task 4
- ✅ `new` action open to all authenticated users (coming_soon gate removed) — Task 4

**Type consistency check:**
- `DiagnosticQuestion.kind` enum values used consistently: `"disc"`, `"interest"`, `"competence"` (string enum)
- `PreScoringService` stores `score_data` with string keys (`"disc_scores"`, `"top_career_ids"`) — `ScoringService` reads with same string keys ✅
- `Career.diagnostic` scope used in `PreScoringService` ✅
- `affirmation_counts` in `ScoringService` is a hash of `career_id => array` — `submit_validation` passes `params[:affirmations].to_unsafe_h` ✅
