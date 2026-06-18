# Filière Discovery via Likert Questionnaire — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single filière selection question with 16 Likert-scale affirmations (2 per filière × 8 filières) so the diagnostic determines the student's best filière automatically from their answers.

**Architecture:** Mirror the existing DISC pattern. `DiagnosticQuestion` gains a `filiere_slug` column for `kind: "interest"` questions. Answers store `dimension_slug = question.filiere_slug` and `points_awarded = 1–5`. `PreScoringService` sums `points_awarded` by filière slug instead of counting answers. Views replace the radio filière grid with the existing `_likert_question` partial.

**Tech Stack:** Rails 8, PostgreSQL, Minitest, Tailwind CSS, ERB

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `db/migrate/20260618100000_add_filiere_slug_to_diagnostic_questions.rb` | Create | Adds `filiere_slug` string column |
| `app/models/diagnostic_question.rb` | Modify | `kind_specific_fields_present`: `interest` requires `filiere_slug`, not `options` |
| `db/seeds.rb` | Modify | Replace 1 selection question with 16 Likert questions (2 per filière) |
| `app/controllers/diagnostics_controller.rb` | Modify | `submit_interest` & `create_from_interest`: validate 1–5 int, save `dimension_slug: question.filiere_slug` |
| `app/services/diagnostics/pre_scoring_service.rb` | Modify | `filiere_scores[slug] += answer.points_awarded.to_i` instead of `+= 1` |
| `app/views/diagnostics/interest_start.html.erb` | Modify | Replace radio filière grid with `_likert_question` partial |
| `app/views/diagnostics/interest.html.erb` | Modify | Same (member route version) |
| `test/models/diagnostic_question_test.rb` | Modify | Add tests for `interest` kind with `filiere_slug` |
| `test/controllers/diagnostics_controller_test.rb` | Modify | Update broken tests + add Likert behavior tests |
| `test/services/diagnostics/pre_scoring_service_test.rb` | Modify | Update setup to use `filiere_slug`, update filière score assertion |

---

## Task 1: Migration — add `filiere_slug` to `diagnostic_questions`

**Files:**
- Create: `db/migrate/20260618100000_add_filiere_slug_to_diagnostic_questions.rb`

- [ ] **Step 1: Create the migration file**

```ruby
# db/migrate/20260618100000_add_filiere_slug_to_diagnostic_questions.rb
class AddFiliereSugToDiagnosticQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :diagnostic_questions, :filiere_slug, :string
  end
end
```

- [ ] **Step 2: Run the migration**

```bash
bin/rails db:migrate
```

Expected output:
```
== 20260618100000 AddFiliereSugToDiagnosticQuestions: migrating ==============
-- add_column(:diagnostic_questions, :filiere_slug, :string)
== 20260618100000 AddFiliereSugToDiagnosticQuestions: migrated
```

- [ ] **Step 3: Commit**

```bash
git add db/migrate/20260618100000_add_filiere_slug_to_diagnostic_questions.rb db/schema.rb
git commit -m "feat: add filiere_slug to diagnostic_questions"
```

---

## Task 2: Update `DiagnosticQuestion` model validation

**Files:**
- Modify: `app/models/diagnostic_question.rb`
- Modify: `test/models/diagnostic_question_test.rb`

- [ ] **Step 1: Write failing tests**

Replace the full content of `test/models/diagnostic_question_test.rb`:

```ruby
require "test_helper"

class DiagnosticQuestionTest < ActiveSupport::TestCase
  setup do
    @assessment = Assessment.create!(title: "Test #{SecureRandom.hex(4)}", active: false)
  end

  test "interest question valid with filiere_slug" do
    q = DiagnosticQuestion.new(
      assessment:   @assessment,
      kind:         :interest,
      text:         "Les langues m'attirent.",
      filiere_slug: "langues",
      position:     1
    )
    assert q.valid?, q.errors.full_messages.inspect
  end

  test "interest question invalid without filiere_slug" do
    q = DiagnosticQuestion.new(
      assessment: @assessment,
      kind:       :interest,
      text:       "Les langues m'attirent.",
      position:   1
    )
    assert_not q.valid?
    assert_includes q.errors[:filiere_slug], "ne peut pas être vide"
  end

  test "interest question does not require options" do
    q = DiagnosticQuestion.new(
      assessment:   @assessment,
      kind:         :interest,
      text:         "L'espace m'attire.",
      filiere_slug: "geo",
      position:     1
    )
    assert q.valid?, q.errors.full_messages.inspect
  end

  test "disc question requires disc_type" do
    q = DiagnosticQuestion.new(
      assessment: @assessment,
      kind:       :disc,
      text:       "Je décide vite.",
      position:   1
    )
    assert_not q.valid?
    assert_includes q.errors[:disc_type], "ne peut pas être vide"
  end

  test "competence question requires competence_slug" do
    q = DiagnosticQuestion.new(
      assessment: @assessment,
      kind:       :competence,
      text:       "Je parle une langue.",
      position:   1
    )
    assert_not q.valid?
    assert_includes q.errors[:competence_slug], "ne peut pas être vide"
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bin/rails test test/models/diagnostic_question_test.rb
```

Expected: `interest question valid with filiere_slug` FAILS — validation currently checks `options` not `filiere_slug`.

- [ ] **Step 3: Update model validation**

In `app/models/diagnostic_question.rb`, replace the `kind_specific_fields_present` method:

```ruby
def kind_specific_fields_present
  case kind
  when "disc"
    errors.add(:disc_type, "ne peut pas être vide") if disc_type.blank?
  when "interest"
    errors.add(:filiere_slug, "ne peut pas être vide") if filiere_slug.blank?
  when "competence"
    errors.add(:competence_slug, "ne peut pas être vide") if competence_slug.blank?
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
bin/rails test test/models/diagnostic_question_test.rb
```

Expected: 5 tests, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/models/diagnostic_question.rb test/models/diagnostic_question_test.rb
git commit -m "feat: interest DiagnosticQuestion requires filiere_slug instead of options"
```

> **Note:** After this commit, the pre-scoring and controller tests will have broken `setup` blocks (they create interest questions with `options:` and no `filiere_slug`). This is expected — Tasks 4 and 5 fix them.

---

## Task 3: Update seeds — 16 Likert interest questions

**Files:**
- Modify: `db/seeds.rb`

- [ ] **Step 1: Replace the `# ===== FILIÈRE =====` block in `db/seeds.rb`**

Find and replace the entire block (from `# ===== FILIÈRE =====` through `puts "✓ #{DiagnosticQuestion.where(assessment: assessment, kind: 'interest').count} question de filière"`):

```ruby
# ===== 16 QUESTIONS FILIÈRE (Likert 1–5, 2 par filière) =====
interest_questions = [
  { text: "Les langues étrangères et la richesse des cultures qu'elles véhiculent me passionnent.",               filiere_slug: "langues",  position: 1  },
  { text: "Lire ou traduire des textes dans une autre langue est une activité qui me captive.",                    filiere_slug: "langues",  position: 2  },
  { text: "Les dynamiques des territoires, l'urbanisme et l'aménagement de l'espace m'intéressent profondément.", filiere_slug: "geo",      position: 3  },
  { text: "Analyser des cartes, comprendre les flux migratoires ou les inégalités spatiales me fascine.",          filiere_slug: "geo",      position: 4  },
  { text: "Observer et comprendre les comportements humains au sein des sociétés est ce qui me motive.",           filiere_slug: "socio",    position: 5  },
  { text: "Les questions de diversité, d'identité culturelle et d'inégalités sociales m'animent.",                filiere_slug: "socio",    position: 6  },
  { text: "Écrire, analyser des textes littéraires ou travailler la langue française est une vocation pour moi.", filiere_slug: "lettres",  position: 7  },
  { text: "La narration, la critique littéraire et le travail sur le style m'enthousiasment.",                     filiere_slug: "lettres",  position: 8  },
  { text: "Comprendre le fonctionnement de l'esprit humain, les émotions et les comportements me passionne.",     filiere_slug: "psycho",   position: 9  },
  { text: "Accompagner des personnes dans leur développement ou résoudre des problèmes psychologiques m'attire.", filiere_slug: "psycho",   position: 10 },
  { text: "Questionner les idées, débattre de concepts abstraits et construire des arguments rigoureux me plaît.", filiere_slug: "philo",    position: 11 },
  { text: "Les grandes questions éthiques, politiques ou existentielles stimulent ma réflexion.",                  filiere_slug: "philo",    position: 12 },
  { text: "Comprendre les événements passés et leur impact sur le monde actuel me passionne.",                    filiere_slug: "histoire", position: 13 },
  { text: "Explorer les civilisations anciennes, les archives et le patrimoine culturel est ce qui m'anime.",     filiere_slug: "histoire", position: 14 },
  { text: "Former, transmettre des savoirs et accompagner l'apprentissage des autres est une vocation.",          filiere_slug: "edu",      position: 15 },
  { text: "Les mécanismes de l'apprentissage, la pédagogie et la conception de formations m'intéressent.",       filiere_slug: "edu",      position: 16 }
]

seeded_question_ids = interest_questions.map do |q|
  DiagnosticQuestion.find_or_initialize_by(assessment: assessment, position: q[:position], kind: "interest").tap do |dq|
    dq.text         = q[:text]
    dq.filiere_slug = q[:filiere_slug]
    dq.options      = []
    dq.active       = true
    dq.save!
  end.id
end

puts "✓ #{DiagnosticQuestion.where(assessment: assessment, kind: 'interest').count} questions de filière"
```

- [ ] **Step 2: Run seeds**

```bash
bin/rails db:seed
```

Expected output includes: `✓ 16 questions de filière`

- [ ] **Step 3: Verify in Rails console**

```bash
bin/rails runner "puts DiagnosticQuestion.interest.count; puts DiagnosticQuestion.interest.pluck(:filiere_slug).tally.inspect"
```

Expected:
```
16
{"langues"=>2, "geo"=>2, "socio"=>2, "lettres"=>2, "psycho"=>2, "philo"=>2, "histoire"=>2, "edu"=>2}
```

- [ ] **Step 4: Commit**

```bash
git add db/seeds.rb
git commit -m "feat: seed 16 Likert interest questions (2 per filière)"
```

---

## Task 4: Update controller — `submit_interest` & `create_from_interest`

**Files:**
- Modify: `test/controllers/diagnostics_controller_test.rb`
- Modify: `app/controllers/diagnostics_controller.rb`

- [ ] **Step 1: Update broken tests and add new ones**

In `test/controllers/diagnostics_controller_test.rb`:

**Replace** `"GET interest renders for in_progress diagnostic"`:
```ruby
test "GET interest renders Likert questions for in_progress diagnostic" do
  sign_in @user
  @assessment.diagnostic_questions.create!(
    kind: :interest, text: "Les langues m'attirent.", filiere_slug: "langues", position: 1
  )
  d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
  get interest_diagnostic_path(d)
  assert_response :success
  assert_select "fieldset", count: 1
  assert_select "legend", text: /Les langues m'attirent/
  assert_select "input[type='radio'][value='1']", count: 1
  assert_select "input[type='radio'][value='5']", count: 1
end
```

**Replace** `"GET interest renders the source questionnaire filiere choices"`:
```ruby
test "GET interest renders Likert scale labels" do
  sign_in @user
  @assessment.diagnostic_questions.create!(
    kind: :interest, text: "L'espace m'attire.", filiere_slug: "geo", position: 1
  )
  d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
  get interest_diagnostic_path(d)
  assert_response :success
  assert_includes response.body, "Pas du tout moi"
  assert_includes response.body, "Tout à fait moi"
end
```

**Replace** `"GET disc renders for diagnostic with interest answers"`:
```ruby
test "GET disc renders for diagnostic with interest answers" do
  sign_in @user
  q = @assessment.diagnostic_questions.create!(
    kind: :interest, text: "Q?", filiere_slug: "langues", position: 1
  )
  @assessment.diagnostic_questions.create!(
    kind: :disc, text: "Je prends des initiatives.", disc_type: "D", position: 2
  )
  d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
  d.diagnostic_answers.create!(
    diagnostic_question: q, dimension_slug: "langues", answer_value: "3", points_awarded: 3
  )
  get disc_diagnostic_path(d)
  assert_response :success
  assert_select "fieldset", count: 1
  assert_select "fieldset.diagnostic-motion-item"
  assert_select ".peer-focus-visible\\:ring-2", count: 5
end
```

**Replace** `"POST submit_interest rejects missing answers"`:
```ruby
test "POST submit_interest rejects missing answers" do
  sign_in @user
  @assessment.diagnostic_questions.create!(
    kind: :interest, text: "Q?", filiere_slug: "langues", position: 1
  )
  d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)

  assert_no_difference "DiagnosticAnswer.count" do
    post submit_interest_diagnostic_path(d), params: { answers: {} }
  end

  assert_redirected_to interest_diagnostic_path(d)
end
```

**Add** after that test:
```ruby
test "POST submit_interest saves answer with filiere_slug from question and Likert value" do
  sign_in @user
  q = @assessment.diagnostic_questions.create!(
    kind: :interest, text: "Q?", filiere_slug: "lettres", position: 1
  )
  d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)

  assert_difference "DiagnosticAnswer.count", 1 do
    post submit_interest_diagnostic_path(d), params: { answers: { q.id => "4" } }
  end

  answer = d.diagnostic_answers.last
  assert_equal "lettres", answer.dimension_slug
  assert_equal "4",       answer.answer_value
  assert_equal 4,         answer.points_awarded
  assert_redirected_to disc_diagnostic_path(d)
end

test "POST submit_interest rejects out-of-range Likert value" do
  sign_in @user
  q = @assessment.diagnostic_questions.create!(
    kind: :interest, text: "Q?", filiere_slug: "langues", position: 1
  )
  d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)

  assert_no_difference "DiagnosticAnswer.count" do
    post submit_interest_diagnostic_path(d), params: { answers: { q.id => "6" } }
  end

  assert_redirected_to interest_diagnostic_path(d)
end
```

- [ ] **Step 2: Run tests to verify the new ones fail**

```bash
bin/rails test test/controllers/diagnostics_controller_test.rb
```

Expected: `POST submit_interest saves answer with filiere_slug from question and Likert value` fails.

- [ ] **Step 3: Replace `submit_interest` in `app/controllers/diagnostics_controller.rb`**

```ruby
def submit_interest
  questions = active_assessment.diagnostic_questions.interest.active.ordered
  answers = valid_answers_for(questions) do |_question, value|
    numeric_value = Integer(value, exception: false)
    numeric_value if (1..5).include?(numeric_value)
  end
  return redirect_incomplete_answers(:interest) unless answers

  ActiveRecord::Base.transaction do
    answers.each do |question, value|
      answer = @diagnostic.diagnostic_answers.find_or_initialize_by(diagnostic_question: question)
      answer.assign_attributes(
        dimension_slug: question.filiere_slug,
        answer_value:   value.to_s,
        points_awarded: value
      )
      answer.save!
    end
  end
  redirect_to disc_diagnostic_path(@diagnostic)
end
```

- [ ] **Step 4: Replace `create_from_interest` in `app/controllers/diagnostics_controller.rb`**

```ruby
def create_from_interest
  assessment = Assessment.find_by(active: true) || Assessment.first
  unless assessment
    redirect_to root_path, alert: "Aucune évaluation disponible pour le moment."
    return
  end

  questions = assessment.diagnostic_questions.interest.active.ordered
  answers = valid_answers_for(questions) do |_question, value|
    numeric_value = Integer(value, exception: false)
    numeric_value if (1..5).include?(numeric_value)
  end
  return redirect_to interest_diagnostics_path, alert: "Veuillez répondre à toutes les questions." unless answers

  ActiveRecord::Base.transaction do
    @diagnostic = current_user.diagnostics.create!(status: :in_progress, assessment: assessment)
    answers.each do |question, value|
      @diagnostic.diagnostic_answers.create!(
        diagnostic_question: question,
        dimension_slug:      question.filiere_slug,
        answer_value:        value.to_s,
        points_awarded:      value
      )
    end
  end

  redirect_to disc_diagnostic_path(@diagnostic)
end
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
bin/rails test test/controllers/diagnostics_controller_test.rb
```

Expected: All green.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/diagnostics_controller.rb test/controllers/diagnostics_controller_test.rb
git commit -m "feat: submit_interest accepts Likert 1-5, stores filiere_slug from question"
```

---

## Task 5: Update `PreScoringService` — sum `points_awarded`

**Files:**
- Modify: `test/services/diagnostics/pre_scoring_service_test.rb`
- Modify: `app/services/diagnostics/pre_scoring_service.rb`

- [ ] **Step 1: Update test setup and assertions**

In `test/services/diagnostics/pre_scoring_service_test.rb`:

**In `setup`**, replace the `@iq` creation block:

```ruby
# 1 interest question → langues
@iq = @assessment.diagnostic_questions.create!(
  kind: :interest, text: "Les langues m'attirent.",
  filiere_slug: "langues",
  position: 1
)
```

**In `setup`**, replace the interest answer creation:

```ruby
@diagnostic.diagnostic_answers.create!(
  diagnostic_question: @iq, dimension_slug: "langues", answer_value: "4", points_awarded: 4
)
```

**Update** `"stores filiere_scores in score_data"`:

```ruby
test "stores filiere_scores in score_data" do
  Diagnostics::PreScoringService.call(@diagnostic)
  @diagnostic.reload
  assert_equal 4, @diagnostic.score_data["filiere_scores"]["langues"]
end
```

**Add** after `"stores filiere_scores in score_data"`:

```ruby
test "filiere_scores accumulates points_awarded across multiple interest answers" do
  iq2 = @assessment.diagnostic_questions.create!(
    kind: :interest, text: "La traduction m'attire.",
    filiere_slug: "langues",
    position: 100
  )
  @diagnostic.diagnostic_answers.create!(
    diagnostic_question: iq2, dimension_slug: "langues",
    answer_value: "3", points_awarded: 3
  )

  Diagnostics::PreScoringService.call(@diagnostic)
  @diagnostic.reload
  assert_equal 7, @diagnostic.score_data["filiere_scores"]["langues"]
end
```

- [ ] **Step 2: Run tests to verify the updated assertion fails**

```bash
bin/rails test test/services/diagnostics/pre_scoring_service_test.rb
```

Expected: `stores filiere_scores in score_data` fails — `Expected: 4, Actual: 1`.

- [ ] **Step 3: Update `PreScoringService`**

In `app/services/diagnostics/pre_scoring_service.rb`, in `calculate_scores`, replace:

```ruby
when "interest"
  filiere_scores[answer.dimension_slug] += 1
```

With:

```ruby
when "interest"
  filiere_scores[answer.dimension_slug] += answer.points_awarded.to_i
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
bin/rails test test/services/diagnostics/pre_scoring_service_test.rb
```

Expected: All green.

- [ ] **Step 5: Commit**

```bash
git add app/services/diagnostics/pre_scoring_service.rb test/services/diagnostics/pre_scoring_service_test.rb
git commit -m "feat: filiere scoring sums points_awarded instead of counting answers"
```

---

## Task 6: Update views

**Files:**
- Modify: `app/views/diagnostics/interest_start.html.erb`
- Modify: `app/views/diagnostics/interest.html.erb`

- [ ] **Step 1: Replace `interest_start.html.erb`**

```erb
<%# app/views/diagnostics/interest_start.html.erb %>
<div class="max-w-2xl mx-auto px-4 py-8">
  <div class="mb-8">
    <p class="text-xs font-bold uppercase tracking-widest text-[var(--color-primary)] mb-2">Étape 1 sur 4</p>
    <h1 class="text-2xl font-bold text-slate-800">Vos affinités</h1>
    <p class="text-slate-500 mt-1">Évaluez chaque affirmation de 1 (pas du tout moi) à 5 (tout à fait moi).</p>
  </div>

  <%= form_with url: submit_interest_diagnostics_path, method: :post, data: { turbo: false } do |f| %>
    <div class="space-y-4">
      <% @questions.each_with_index do |question, i| %>
        <%= render "likert_question", question: question, index: i, current_value: nil %>
      <% end %>
    </div>

    <div class="mt-8">
      <%= f.submit "Continuer →",
            class: "diagnostic-action w-full min-h-12 py-4 bg-[var(--color-primary)] text-secondary-900 font-bold rounded-xl hover:bg-primary-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-secondary-700 focus-visible:ring-offset-2 transition-colors cursor-pointer" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 2: Replace `interest.html.erb`**

```erb
<%# app/views/diagnostics/interest.html.erb %>
<div class="max-w-2xl mx-auto px-4 py-8">
  <div class="mb-8">
    <p class="text-xs font-bold uppercase tracking-widest text-[var(--color-primary)] mb-2">Étape 1 sur 4</p>
    <h1 class="text-2xl font-bold text-slate-800">Vos affinités</h1>
    <p class="text-slate-500 mt-1">Évaluez chaque affirmation de 1 (pas du tout moi) à 5 (tout à fait moi).</p>
  </div>

  <%= form_with url: submit_interest_diagnostic_path(@diagnostic), method: :post, data: { turbo: false } do |f| %>
    <div class="space-y-4">
      <% @questions.each_with_index do |question, i| %>
        <%= render "likert_question", question: question, index: i, current_value: nil %>
      <% end %>
    </div>

    <div class="mt-8">
      <%= f.submit "Continuer →",
            class: "diagnostic-action w-full min-h-12 py-4 bg-[var(--color-primary)] text-secondary-900 font-bold rounded-xl hover:bg-primary-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-secondary-700 focus-visible:ring-offset-2 transition-colors cursor-pointer" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 3: Run the full test suite**

```bash
bin/rails test
```

Expected: All green.

- [ ] **Step 4: Commit**

```bash
git add app/views/diagnostics/interest_start.html.erb app/views/diagnostics/interest.html.erb
git commit -m "feat: interest step shows 16 Likert affirmations instead of filiere selector"
```

---

## Final Verification

- [ ] **Run complete test suite**

```bash
bin/rails test
```

Expected: All tests pass, 0 failures.

- [ ] **Reset DB and run seeds to verify end-to-end**

```bash
bin/rails db:reset
```

Expected: Completes without error. Output shows `16 questions de filière`, `16 questions DISC`, `12 questions compétences`.

- [ ] **Smoke test in browser**

Start the dev server (`bin/dev`) and log in as a user, then:

1. Visit `/diagnostics/new` → redirects to `/diagnostics/interest`
2. Page shows "Vos affinités" heading and 16 Likert affirmations (numbered 1–16), not a filière selector
3. Answer all 16 with any value 1–5 → continue → DISC step loads (16 questions)
4. Answer all DISC → continue → compétences step loads (12 questions)
5. Answer all compétences → continue → validation page shows 2+ careers
6. Submit validation → pay page loads
