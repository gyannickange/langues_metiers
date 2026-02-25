# Diagnostic Payant Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the complete paid diagnostic flow: Stripe/Pawapay payment → 25-question questionnaire → automatic scoring against 7 profiles → personalized PDF report.

**Architecture:** Payment confirmation via webhooks unlocks a `Diagnostic` record; questionnaire is completed bloc-by-bloc (5 blocs × 5 questions); `Diagnostics::ScoringService` determines the primary and complementary profile by accumulating 1 point per scored answer per profile; PDF is generated synchronously with Prawn (Stripe users) or via Sidekiq background job (Pawapay users, since mobile money confirmation is async).

**Tech Stack:** Rails 8, `stripe` gem, `prawn` + `prawn-table` gems, Pawapay REST API (Net::HTTP), `webmock` gem for tests, Turbo/Stimulus (Hotwire), Sidekiq, Active Storage, Minitest.

**UUID pattern:** All new migrations use `id: :uuid, default: -> { "gen_random_uuid()" }` and `type: :uuid` on foreign keys — matching the existing schema.

---

### Task 1: Add gems

**Files:**
- Modify: `Gemfile`

**Step 1: Add to Gemfile main section**

```ruby
gem "stripe"
gem "prawn"
gem "prawn-table"
```

Add to the `group :test` block:

```ruby
gem "webmock"
```

**Step 2: Install**

```bash
bundle install
```

Expected: No conflicts. `bundle list | grep -E "stripe|prawn|webmock"` shows the 4 gems.

**Step 3: Enable WebMock in tests**

Add to `test/test_helper.rb` after `require "rails/test_help"`:

```ruby
require "webmock/minitest"
```

**Step 4: Commit**

```bash
git add Gemfile Gemfile.lock test/test_helper.rb
git commit -m "feat: add stripe, prawn, prawn-table, webmock gems"
```

---

### Task 2: Profile migration + model

**Files:**
- Create: `db/migrate/TIMESTAMP_create_profiles.rb`
- Create: `app/models/profile.rb`
- Create: `test/models/profile_test.rb`

**Step 1: Generate migration**

```bash
rails generate migration CreateProfiles
```

**Step 2: Edit the generated migration**

```ruby
class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.jsonb :key_skills, default: []
      t.text :first_action
      t.text :premium_pitch
      t.timestamps
    end
    add_index :profiles, :slug, unique: true
  end
end
```

**Step 3: Run migration**

```bash
rails db:migrate
```

Expected: `== CreateProfiles: migrated`

**Step 4: Write failing test**

```ruby
# test/models/profile_test.rb
require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "valid with name and slug" do
    assert Profile.new(name: "Analyste & Veille", slug: "analyste-veille").valid?
  end

  test "invalid without name" do
    p = Profile.new(slug: "test")
    assert_not p.valid?
    assert_includes p.errors[:name], "can't be blank"
  end

  test "invalid without slug" do
    p = Profile.new(name: "Test")
    assert_not p.valid?
    assert_includes p.errors[:slug], "can't be blank"
  end

  test "slug must be unique" do
    Profile.create!(name: "P1", slug: "my-slug")
    assert_not Profile.new(name: "P2", slug: "my-slug").valid?
  end

  test "key_skills defaults to empty array" do
    p = Profile.create!(name: "Test", slug: "test-#{SecureRandom.hex(4)}")
    assert_equal [], p.key_skills
  end

  test "has_many trajectories" do
    assert_respond_to Profile.new, :trajectories
  end
end
```

**Step 5: Run test — expect failure**

```bash
rails test test/models/profile_test.rb
```

Expected: `NameError: uninitialized constant Profile`

**Step 6: Create model**

```ruby
# app/models/profile.rb
class Profile < ApplicationRecord
  has_many :trajectories, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def active_trajectory
    trajectories.active.last
  end
end
```

**Step 7: Run tests — expect pass**

```bash
rails test test/models/profile_test.rb
```

Expected: 6 runs, 0 failures.

**Step 8: Commit**

```bash
git add db/migrate/ app/models/profile.rb test/models/profile_test.rb
git commit -m "feat: add Profile model and migration"
```

---

### Task 3: Trajectory migration + model

**Files:**
- Create: `db/migrate/TIMESTAMP_create_trajectories.rb`
- Create: `app/models/trajectory.rb`
- Create: `test/models/trajectory_test.rb`

**Step 1: Generate migration**

```bash
rails generate migration CreateTrajectories
```

**Step 2: Edit migration**

```ruby
class CreateTrajectories < ActiveRecord::Migration[8.0]
  def change
    create_table :trajectories, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :profile, null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.text :axe_1
      t.text :axe_2
      t.text :axe_3
      t.boolean :active, default: true, null: false
      t.timestamps
    end
  end
end
```

**Step 3: Run migration**

```bash
rails db:migrate
```

**Step 4: Write failing test**

```ruby
# test/models/trajectory_test.rb
require "test_helper"

class TrajectoryTest < ActiveSupport::TestCase
  def setup
    @profile = Profile.create!(name: "Analyste", slug: "analyste-#{SecureRandom.hex(4)}")
  end

  test "valid with a profile" do
    assert Trajectory.new(profile: @profile).valid?
  end

  test "invalid without profile" do
    assert_not Trajectory.new.valid?
  end

  test "active defaults to true" do
    t = Trajectory.create!(profile: @profile)
    assert t.active
  end

  test "scope active returns only active trajectories" do
    active   = Trajectory.create!(profile: @profile, active: true)
    inactive = Trajectory.create!(profile: @profile, active: false)
    assert_includes Trajectory.active, active
    assert_not_includes Trajectory.active, inactive
  end

  test "belongs_to profile" do
    assert_respond_to Trajectory.new, :profile
  end
end
```

**Step 5: Run test — expect failure**

```bash
rails test test/models/trajectory_test.rb
```

**Step 6: Create model**

```ruby
# app/models/trajectory.rb
class Trajectory < ApplicationRecord
  belongs_to :profile

  scope :active, -> { where(active: true) }
end
```

**Step 7: Run tests**

```bash
rails test test/models/trajectory_test.rb
```

Expected: 5 runs, 0 failures.

**Step 8: Commit**

```bash
git add db/migrate/ app/models/trajectory.rb test/models/trajectory_test.rb
git commit -m "feat: add Trajectory model and migration"
```

---

### Task 4: Question migration + model

**Files:**
- Create: `db/migrate/TIMESTAMP_create_questions.rb`
- Create: `app/models/question.rb`
- Create: `test/models/question_test.rb`

**Step 1: Generate migration**

```bash
rails generate migration CreateQuestions
```

**Step 2: Edit migration**

```ruby
class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.integer  :bloc,     null: false
      t.text     :text,     null: false
      t.string   :kind,     null: false, default: "mcq"
      t.jsonb    :options,  default: []
      t.boolean  :scored,   default: false, null: false
      t.integer  :position, null: false, default: 0
      t.boolean  :active,   default: true, null: false
      t.timestamps
    end
    add_index :questions, [:bloc, :position]
  end
end
```

**Step 3: Run migration**

```bash
rails db:migrate
```

**Step 4: Write failing test**

```ruby
# test/models/question_test.rb
require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    assert Question.new(bloc: 1, text: "Votre orientation ?", kind: "mcq", position: 1).valid?
  end

  test "invalid without bloc" do
    assert_not Question.new(text: "Q", kind: "mcq", position: 1).valid?
  end

  test "invalid without text" do
    assert_not Question.new(bloc: 1, kind: "mcq", position: 1).valid?
  end

  test "invalid kind" do
    q = Question.new(bloc: 1, text: "Q", kind: "bad", position: 1)
    assert_not q.valid?
  end

  test "bloc must be 1 through 5" do
    assert_not Question.new(bloc: 6, text: "Q", kind: "mcq", position: 1).valid?
    assert_not Question.new(bloc: 0, text: "Q", kind: "mcq", position: 1).valid?
  end

  test "scope active" do
    a = Question.create!(bloc: 1, text: "A", kind: "mcq", position: 1, active: true)
    i = Question.create!(bloc: 1, text: "I", kind: "mcq", position: 2, active: false)
    assert_includes Question.active, a
    assert_not_includes Question.active, i
  end

  test "scope by_bloc returns ordered by position" do
    q2 = Question.create!(bloc: 1, text: "Q2", kind: "mcq", position: 2)
    q1 = Question.create!(bloc: 1, text: "Q1", kind: "mcq", position: 1)
    assert_equal [q1, q2], Question.by_bloc(1).to_a
  end
end
```

**Step 5: Run — expect failure**

```bash
rails test test/models/question_test.rb
```

**Step 6: Create model**

```ruby
# app/models/question.rb
class Question < ApplicationRecord
  KINDS = %w[likert mcq].freeze

  scope :active,   -> { where(active: true) }
  scope :scored,   -> { where(scored: true) }
  scope :by_bloc,  ->(b) { where(bloc: b).order(:position) }

  validates :bloc,     presence: true, inclusion: { in: 1..5 }
  validates :text,     presence: true
  validates :kind,     presence: true, inclusion: { in: KINDS }
  validates :position, presence: true
end
```

**Step 7: Run tests**

```bash
rails test test/models/question_test.rb
```

Expected: 8 runs, 0 failures.

**Step 8: Commit**

```bash
git add db/migrate/ app/models/question.rb test/models/question_test.rb
git commit -m "feat: add Question model and migration"
```

---

### Task 5: Diagnostic + DiagnosticAnswer migrations + models

**Files:**
- Create: `db/migrate/TIMESTAMP_create_diagnostics.rb`
- Create: `db/migrate/TIMESTAMP_create_diagnostic_answers.rb`
- Create: `app/models/diagnostic.rb`
- Create: `app/models/diagnostic_answer.rb`
- Create: `test/models/diagnostic_test.rb`

**Step 1: Generate both migrations**

```bash
rails generate migration CreateDiagnostics
rails generate migration CreateDiagnosticAnswers
```

**Step 2: Edit diagnostics migration**

```ruby
class CreateDiagnostics < ActiveRecord::Migration[8.0]
  def change
    create_table :diagnostics, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.integer  :status,           null: false, default: 0
      t.integer  :payment_provider
      t.uuid     :primary_profile_id
      t.uuid     :complementary_profile_id
      t.jsonb    :score_data,       default: {}
      t.boolean  :pdf_generated,    default: false, null: false
      t.datetime :paid_at
      t.datetime :completed_at
      t.timestamps
    end
    add_foreign_key :diagnostics, :profiles, column: :primary_profile_id
    add_foreign_key :diagnostics, :profiles, column: :complementary_profile_id
  end
end
```

**Step 3: Edit diagnostic_answers migration**

```ruby
class CreateDiagnosticAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :diagnostic_answers, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :diagnostic, null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.references :question, null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.string  :answer_value
      t.string  :profile_dimension
      t.integer :points_awarded, default: 0
      t.timestamps
    end
    add_index :diagnostic_answers, [:diagnostic_id, :question_id], unique: true
  end
end
```

**Step 4: Run migrations**

```bash
rails db:migrate
```

**Step 5: Write failing test**

```ruby
# test/models/diagnostic_test.rb
require "test_helper"

class DiagnosticTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "diag#{SecureRandom.hex(4)}@test.com", password: "password123")
  end

  test "valid with a user" do
    assert Diagnostic.new(user: @user).valid?
  end

  test "starts as pending_payment" do
    d = Diagnostic.create!(user: @user)
    assert d.pending_payment?
  end

  test "status lifecycle" do
    d = Diagnostic.create!(user: @user)
    d.paid!;        assert d.paid?
    d.in_progress!; assert d.in_progress?
    d.completed!;   assert d.completed?
  end

  test "score_data defaults to empty hash" do
    d = Diagnostic.create!(user: @user)
    assert_equal({}, d.score_data)
  end

  test "has_many diagnostic_answers" do
    assert_respond_to Diagnostic.new, :diagnostic_answers
  end

  test "belongs_to primary_profile optionally" do
    d = Diagnostic.new(user: @user)
    assert d.valid?   # primary_profile is optional
  end
end
```

**Step 6: Run test — expect failure**

```bash
rails test test/models/diagnostic_test.rb
```

**Step 7: Create Diagnostic model**

```ruby
# app/models/diagnostic.rb
class Diagnostic < ApplicationRecord
  belongs_to :user
  belongs_to :primary_profile,       class_name: "Profile", optional: true
  belongs_to :complementary_profile, class_name: "Profile", optional: true
  has_many   :diagnostic_answers, dependent: :destroy
  has_one    :payment, dependent: :destroy
  has_one_attached :pdf_report

  enum :status, {
    pending_payment: 0,
    paid:            1,
    in_progress:     2,
    completed:       3
  }

  enum :payment_provider, {
    stripe:  0,
    pawapay: 1
  }, prefix: :provider
end
```

**Step 8: Create DiagnosticAnswer model**

```ruby
# app/models/diagnostic_answer.rb
class DiagnosticAnswer < ApplicationRecord
  belongs_to :diagnostic
  belongs_to :question
end
```

**Step 9: Run tests**

```bash
rails test test/models/diagnostic_test.rb
```

Expected: 6 runs, 0 failures.

**Step 10: Commit**

```bash
git add db/migrate/ app/models/diagnostic.rb app/models/diagnostic_answer.rb test/models/diagnostic_test.rb
git commit -m "feat: add Diagnostic and DiagnosticAnswer models"
```

---

### Task 6: Payment + MobileOperator migrations + models

**Files:**
- Create: `db/migrate/TIMESTAMP_create_payments.rb`
- Create: `db/migrate/TIMESTAMP_create_mobile_operators.rb`
- Create: `app/models/payment.rb`
- Create: `app/models/mobile_operator.rb`
- Create: `test/models/payment_test.rb`

**Step 1: Generate migrations**

```bash
rails generate migration CreatePayments
rails generate migration CreateMobileOperators
```

**Step 2: Edit payments migration**

```ruby
class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user,       null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.references :diagnostic, null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.integer :provider,            null: false
      t.integer :amount_cents,        null: false, default: 300000
      t.string  :currency,            null: false, default: "XOF"
      t.integer :status,              null: false, default: 0
      t.string  :provider_payment_id
      t.datetime :webhook_confirmed_at
      t.timestamps
    end
    add_index :payments, :provider_payment_id, unique: true,
              where: "provider_payment_id IS NOT NULL"
  end
end
```

**Step 3: Edit mobile_operators migration**

```ruby
class CreateMobileOperators < ActiveRecord::Migration[8.0]
  def change
    create_table :mobile_operators, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string  :name,         null: false
      t.string  :code,         null: false
      t.string  :country_code, null: false
      t.string  :logo_url
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :mobile_operators, [:code, :country_code], unique: true
    add_index :mobile_operators, :country_code
  end
end
```

**Step 4: Run migrations**

```bash
rails db:migrate
```

**Step 5: Write failing test**

```ruby
# test/models/payment_test.rb
require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "pay#{SecureRandom.hex(4)}@test.com", password: "password123")
    @diagnostic = Diagnostic.create!(user: @user)
  end

  test "valid with required attributes" do
    assert Payment.new(user: @user, diagnostic: @diagnostic, provider: :stripe).valid?
  end

  test "starts as pending" do
    p = Payment.create!(user: @user, diagnostic: @diagnostic, provider: :stripe)
    assert p.pending?
  end

  test "can be confirmed" do
    p = Payment.create!(user: @user, diagnostic: @diagnostic, provider: :stripe)
    p.confirmed!
    assert p.confirmed?
  end

  test "defaults to 300000 centimes XOF" do
    p = Payment.create!(user: @user, diagnostic: @diagnostic, provider: :stripe)
    assert_equal 300000, p.amount_cents
    assert_equal "XOF",  p.currency
  end
end
```

**Step 6: Create Payment model**

```ruby
# app/models/payment.rb
class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :diagnostic

  enum :provider, { stripe: 0, pawapay: 1 }
  enum :status,   { pending: 0, confirmed: 1, failed: 2 }

  validates :provider, presence: true
end
```

**Step 7: Create MobileOperator model**

```ruby
# app/models/mobile_operator.rb
class MobileOperator < ApplicationRecord
  scope :active,     -> { where(active: true) }
  scope :by_country, ->(code) { where(country_code: code.to_s.upcase) }

  validates :name, :code, :country_code, presence: true
end
```

**Step 8: Update User model — add associations**

In `app/models/user.rb`, add after the existing `has_many` lines:

```ruby
has_many :diagnostics, dependent: :destroy
has_many :payments,    dependent: :destroy
```

**Step 9: Run tests**

```bash
rails test test/models/payment_test.rb
```

Expected: 4 runs, 0 failures.

**Step 10: Commit**

```bash
git add db/migrate/ app/models/payment.rb app/models/mobile_operator.rb app/models/user.rb test/models/payment_test.rb
git commit -m "feat: add Payment, MobileOperator models and User associations"
```

---

### Task 7: Routes

**Files:**
- Modify: `config/routes.rb`

**Step 1: Add public routes** — insert BEFORE the `namespace :admin` block:

```ruby
# Diagnostics
resources :diagnostics, only: [:new, :create, :show] do
  member do
    get  :questionnaire
    post :submit_bloc
    get  :results
    get  :pdf_status
    get  :download_pdf
  end
end

# Pawapay waiting screen polling
resources :payments, only: [] do
  member do
    get :status
  end
end

# Mobile operator list (Stimulus fetch)
resources :mobile_operators, only: [:index]

# Webhooks — CSRF exempt, handled in controller
post "/webhooks/stripe",  to: "webhooks/stripe#receive"
post "/webhooks/pawapay", to: "webhooks/pawapay#receive"
```

**Step 2: Add admin routes** — inside `namespace :admin do`:

```ruby
resources :diagnostics,      only: [:index, :show]
resources :profiles
resources :trajectories
resources :questions
resources :mobile_operators
```

**Step 3: Verify routes load**

```bash
rails routes | grep -E "diagnostic|webhook|admin/profile"
```

Expected: New routes listed without errors.

**Step 4: Commit**

```bash
git add config/routes.rb
git commit -m "feat: add diagnostic, payment, webhook, and admin routes"
```

---

### Task 8: Seed data

**Files:**
- Modify: `db/seeds.rb`

**Step 1: Replace contents of db/seeds.rb**

```ruby
# ===== PROFILES (7) =====
profiles_data = [
  {
    name: "Coordinateur Stratégique",
    slug: "coordinateur-strategique",
    description: "Pilotage et gestion de projets multi-acteurs.",
    key_skills: ["Gestion de projet", "Leadership", "Communication", "Planification stratégique"],
    first_action: "Rejoignez une organisation et proposez-vous sur un projet transversal.",
    premium_pitch: "Le Roadmap Premium construit votre plan de montée en compétences sur 6 mois avec des jalons concrets.",
    axe_1: "Coordinateur dans une institution internationale ou ONG — pilotage de projets multi-acteurs.",
    axe_2: "Chef de projet dans le secteur privé ou hybride — direction, conseil, management.",
    axe_3: "Expert en gestion de projets complexes — certifications PMP, Prince2, Agile."
  },
  {
    name: "Analyste & Veille",
    slug: "analyste-veille",
    description: "Analyse stratégique, études, recherche appliquée.",
    key_skills: ["Analyse de données", "Recherche documentaire", "Rédaction de rapports", "Pensée critique"],
    first_action: "Réalisez une analyse sectorielle et publiez-la sur LinkedIn.",
    premium_pitch: "Le Roadmap Premium vous guide vers les certifications analytiques les plus reconnues.",
    axe_1: "Analyste dans une organisation internationale, un think tank, ou une administration.",
    axe_2: "Consultant en stratégie ou chargé d'études dans le secteur privé.",
    axe_3: "Expert en intelligence économique ou recherche appliquée à long terme."
  },
  {
    name: "Communication & Influence",
    slug: "communication-influence",
    description: "Narration, plaidoyer, communication institutionnelle.",
    key_skills: ["Storytelling", "Rédaction", "Réseaux sociaux", "Plaidoyer"],
    first_action: "Lancez un blog ou une page LinkedIn dédiée à un sujet de votre domaine.",
    premium_pitch: "Le Roadmap Premium vous aide à construire votre personal brand avec un plan éditorial sur mesure.",
    axe_1: "Chargé de communication dans une organisation internationale, ONG ou institution publique.",
    axe_2: "Responsable communication ou content manager dans le secteur privé ou une startup.",
    axe_3: "Consultant en communication stratégique et personal branding — expert reconnu."
  },
  {
    name: "Développement Territorial",
    slug: "developpement-territorial",
    description: "Climat, urbanisation, aménagement local.",
    key_skills: ["Diagnostic territorial", "Gestion de projets locaux", "Cartographie", "Partenariats publics-privés"],
    first_action: "Identifiez un projet de développement local dans votre commune et rédigez une note de présentation.",
    premium_pitch: "Le Roadmap Premium vous connecte aux réseaux de développement territorial et aux financements.",
    axe_1: "Chargé de développement territorial dans une collectivité locale ou une ONG de développement.",
    axe_2: "Consultant en développement local ou en planification urbaine dans le secteur privé.",
    axe_3: "Expert en aménagement du territoire, urbanisme durable ou gestion environnementale."
  },
  {
    name: "Impact Social & Communautaire",
    slug: "impact-social-communautaire",
    description: "Inclusion, programmes sociaux, mobilisation.",
    key_skills: ["Animation communautaire", "Gestion de programmes sociaux", "Mobilisation des ressources", "Évaluation d'impact"],
    first_action: "Lancez une initiative locale et documentez son impact sur 30 jours.",
    premium_pitch: "Le Roadmap Premium vous aide à créer et financer votre propre projet à impact social.",
    axe_1: "Gestionnaire de programmes sociaux dans une ONG ou une organisation humanitaire.",
    axe_2: "Responsable RSE ou chef de projet impact dans une entreprise ou un fonds social.",
    axe_3: "Fondateur ou directeur d'une structure à impact social — ONG, coopérative, entreprise sociale."
  },
  {
    name: "Digital & Stratégie Contenu",
    slug: "digital-strategie-contenu",
    description: "Stratégie éditoriale, e-learning, communication numérique.",
    key_skills: ["Marketing digital", "Création de contenu", "SEO", "Gestion de communauté"],
    first_action: "Créez un compte professionnel sur une plateforme et publiez 3 contenus en 1 semaine.",
    premium_pitch: "Le Roadmap Premium inclut une formation aux outils digitaux les plus demandés du marché.",
    axe_1: "Community manager ou chargé de communication digitale dans une institution ou ONG.",
    axe_2: "Stratège de contenu ou responsable marketing digital dans une entreprise ou agence.",
    axe_3: "Expert en stratégie digitale, e-learning ou growth hacking — consultant indépendant."
  },
  {
    name: "Data & Transformation",
    slug: "data-transformation",
    description: "Analyse de données sociales, suivi-évaluation digitalisé.",
    key_skills: ["Excel avancé", "Visualisation de données", "Suivi-évaluation", "Bases de données"],
    first_action: "Téléchargez un dataset public et réalisez une analyse simple avec Excel ou Google Sheets.",
    premium_pitch: "Le Roadmap Premium vous guide vers les certifications data (Power BI, Python, Tableau).",
    axe_1: "Chargé de suivi-évaluation ou data analyst dans une ONG, institution ou projet de développement.",
    axe_2: "Analyste de données dans une entreprise, une startup ou un cabinet de conseil.",
    axe_3: "Data scientist ou expert en transformation digitale — spécialisation IA appliquée au secteur social."
  }
]

profiles_data.each do |attrs|
  axe_1 = attrs.delete(:axe_1)
  axe_2 = attrs.delete(:axe_2)
  axe_3 = attrs.delete(:axe_3)

  profile = Profile.find_or_create_by!(slug: attrs[:slug]) do |p|
    p.assign_attributes(attrs)
  end

  unless profile.trajectories.exists?
    profile.trajectories.create!(axe_1: axe_1, axe_2: axe_2, axe_3: axe_3, active: true)
  end
end

puts "✓ #{Profile.count} profils, #{Trajectory.count} trajectoires"

# ===== MOBILE OPERATORS =====
operators = [
  # Côte d'Ivoire
  { name: "Orange Money",    code: "ORANGE_CI",     country_code: "CI" },
  { name: "MTN Mobile Money", code: "MTN_MOMO_CI",  country_code: "CI" },
  { name: "Wave",             code: "WAVE_CI",       country_code: "CI" },
  { name: "Moov Money",       code: "MOOV_CI",       country_code: "CI" },
  # Sénégal
  { name: "Orange Money",    code: "ORANGE_SN",      country_code: "SN" },
  { name: "Wave",            code: "WAVE_SN",         country_code: "SN" },
  { name: "Free Money",      code: "FREE_SN",         country_code: "SN" },
  # Cameroun
  { name: "Orange Money",    code: "ORANGE_CM",      country_code: "CM" },
  { name: "MTN Mobile Money", code: "MTN_MOMO_CM",  country_code: "CM" },
  # Bénin
  { name: "MTN Mobile Money", code: "MTN_MOMO_BJ",  country_code: "BJ" },
  { name: "Moov Money",       code: "MOOV_BJ",       country_code: "BJ" },
  # Ghana
  { name: "MTN MoMo",        code: "MTN_MOMO_GH",    country_code: "GH" },
  { name: "Vodafone Cash",   code: "VODAFONE_GH",    country_code: "GH" },
  { name: "AirtelTigo Money", code: "AIRTELTIGO_GH", country_code: "GH" },
  # Togo
  { name: "Flooz",           code: "MOOV_TG",        country_code: "TG" },
  { name: "T-Money",         code: "TOGOCEL_TG",     country_code: "TG" },
]

operators.each do |op|
  MobileOperator.find_or_create_by!(code: op[:code], country_code: op[:country_code]) do |m|
    m.assign_attributes(op.merge(active: true))
  end
end

puts "✓ #{MobileOperator.count} opérateurs mobiles"
```

**Step 2: Run seed**

```bash
rails db:seed
```

Expected:
```
✓ 7 profils, 7 trajectoires
✓ 16 opérateurs mobiles
```

**Step 3: Commit**

```bash
git add db/seeds.rb
git commit -m "feat: seed 7 profiles, trajectories, and mobile operators"
```

---

### Task 9: ScoringService

**Files:**
- Create: `app/services/diagnostics/scoring_service.rb`
- Create: `test/services/diagnostics/scoring_service_test.rb`

**Step 1: Create directories**

```bash
mkdir -p app/services/diagnostics
mkdir -p test/services/diagnostics
```

**Step 2: Write failing test**

```ruby
# test/services/diagnostics/scoring_service_test.rb
require "test_helper"

class Diagnostics::ScoringServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "scorer#{SecureRandom.hex(4)}@test.com", password: "password123")
    @d    = Diagnostic.create!(user: @user, status: :in_progress)

    @p_analytique    = Profile.create!(name: "Analyste",      slug: "analyste-#{SecureRandom.hex(3)}")
    @p_coordinateur  = Profile.create!(name: "Coordinateur",  slug: "coordo-#{SecureRandom.hex(3)}")
    @p_digital       = Profile.create!(name: "Digital",       slug: "digital-#{SecureRandom.hex(3)}")

    @q_bloc1 = Question.create!(bloc: 1, text: "Q1", kind: "mcq", position: 1, scored: true,
      options: [
        { "value" => "A", "profile_slug" => @p_analytique.slug,   "points" => 1 },
        { "value" => "B", "profile_slug" => @p_digital.slug,      "points" => 1 }
      ])
    @q_bloc2 = Question.create!(bloc: 2, text: "Q2", kind: "mcq", position: 1, scored: true,
      options: [
        { "value" => "A", "profile_slug" => @p_analytique.slug,   "points" => 1 },
        { "value" => "B", "profile_slug" => @p_coordinateur.slug, "points" => 1 }
      ])
    @q_interp = Question.create!(bloc: 4, text: "Q3", kind: "mcq", position: 1, scored: false,
      options: [{ "value" => "A", "profile_slug" => nil, "points" => 0 }])
  end

  test "sets primary profile to highest-scoring dimension" do
    answer(@q_bloc1, "A", @p_analytique.slug, 1)
    answer(@q_bloc2, "A", @p_analytique.slug, 1)

    Diagnostics::ScoringService.call(@d)
    @d.reload

    assert_equal @p_analytique.id, @d.primary_profile_id
    assert_equal 2, @d.score_data[@p_analytique.slug]
  end

  test "sets complementary to second-highest" do
    answer(@q_bloc1, "A", @p_analytique.slug, 1)
    answer(@q_bloc2, "B", @p_coordinateur.slug, 1)

    q3 = Question.create!(bloc: 1, text: "Q3", kind: "mcq", position: 2, scored: true,
      options: [{ "value" => "A", "profile_slug" => @p_analytique.slug, "points" => 1 }])
    answer(q3, "A", @p_analytique.slug, 1)

    Diagnostics::ScoringService.call(@d)
    @d.reload

    assert_equal @p_analytique.id,   @d.primary_profile_id
    assert_equal @p_coordinateur.id, @d.complementary_profile_id
  end

  test "tiebreak favors bloc 2 profile" do
    answer(@q_bloc1, "A", @p_analytique.slug,   1)  # bloc 1 → analytique
    answer(@q_bloc2, "B", @p_coordinateur.slug,  1)  # bloc 2 → coordinateur
    # tied at 1-1; bloc 2 winner = coordinateur

    Diagnostics::ScoringService.call(@d)
    @d.reload

    assert_equal @p_coordinateur.id, @d.primary_profile_id
  end

  test "marks diagnostic as completed" do
    Diagnostics::ScoringService.call(@d)
    assert @d.reload.completed?
  end

  test "ignores unscored answers" do
    answer(@q_interp, "A", nil, 0)
    Diagnostics::ScoringService.call(@d)
    assert @d.reload.completed?  # no crash, graceful
  end

  private

  def answer(question, value, dimension, points)
    DiagnosticAnswer.create!(
      diagnostic: @d, question: question,
      answer_value: value, profile_dimension: dimension, points_awarded: points
    )
  end
end
```

**Step 3: Run — expect failure**

```bash
rails test test/services/diagnostics/scoring_service_test.rb
```

**Step 4: Implement service**

```ruby
# app/services/diagnostics/scoring_service.rb
module Diagnostics
  class ScoringService
    def self.call(diagnostic)
      new(diagnostic).call
    end

    def initialize(diagnostic)
      @diagnostic = diagnostic
    end

    def call
      scores = calculate_scores
      primary, complementary = determine_profiles(scores)

      @diagnostic.update!(
        score_data:              scores,
        primary_profile:         primary,
        complementary_profile:   complementary,
        status:                  :completed,
        completed_at:            Time.current
      )
    end

    private

    def calculate_scores
      scored = @diagnostic.diagnostic_answers
        .joins(:question)
        .where(questions: { scored: true })
        .where.not(profile_dimension: [nil, ""])

      scores = Hash.new(0)
      scored.each { |a| scores[a.profile_dimension] += a.points_awarded.to_i }
      scores
    end

    def determine_profiles(scores)
      return [nil, nil] if scores.empty?

      sorted    = scores.sort_by { |_, v| -v }
      top_score = sorted.first[1]
      tied      = sorted.select { |_, v| v == top_score }.map(&:first)

      primary_slug = tied.size > 1 ? resolve_tiebreak(tied) : tied.first
      secondary_slug = sorted.find { |slug, _| slug != primary_slug }&.first

      [Profile.find_by(slug: primary_slug), Profile.find_by(slug: secondary_slug)]
    end

    def resolve_tiebreak(tied_slugs)
      bloc2 = @diagnostic.diagnostic_answers
        .joins(:question)
        .where(questions: { bloc: 2, scored: true })
        .where(profile_dimension: tied_slugs)

      counts = Hash.new(0)
      bloc2.each { |a| counts[a.profile_dimension] += a.points_awarded.to_i }

      counts.any? ? counts.max_by { |_, v| v }.first : tied_slugs.first
    end
  end
end
```

**Step 5: Run tests**

```bash
rails test test/services/diagnostics/scoring_service_test.rb
```

Expected: 5 runs, 0 failures.

**Step 6: Commit**

```bash
git add app/services/diagnostics/scoring_service.rb test/services/diagnostics/scoring_service_test.rb
git commit -m "feat: add ScoringService with tiebreak logic"
```

---

### Task 10: Stripe checkout service

**Files:**
- Create: `app/services/payments/stripe_checkout_service.rb`
- Create: `config/initializers/stripe.rb`
- Create: `test/services/payments/stripe_checkout_service_test.rb`

**Step 1: Create directories**

```bash
mkdir -p app/services/payments
mkdir -p test/services/payments
```

**Step 2: Add Stripe credentials**

```bash
rails credentials:edit
```

Add:

```yaml
stripe:
  secret_key: sk_test_YOUR_KEY_HERE
  webhook_secret: whsec_YOUR_SECRET_HERE
  price_amount: 300000
  currency: xof
```

**Step 3: Create Stripe initializer**

```ruby
# config/initializers/stripe.rb
Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)
```

**Step 4: Write failing test**

```ruby
# test/services/payments/stripe_checkout_service_test.rb
require "test_helper"

class Payments::StripeCheckoutServiceTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "stripe#{SecureRandom.hex(4)}@test.com", password: "password123")
    @diagnostic = Diagnostic.create!(user: @user)
    @urls       = { success_url: "http://test.host/success", cancel_url: "http://test.host/cancel" }
  end

  test "creates payment and returns checkout URL" do
    fake_session = OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/pay/cs_test_123")

    Stripe::Checkout::Session.stub :create, fake_session do
      result = Payments::StripeCheckoutService.call(diagnostic: @diagnostic, **@urls)

      assert result[:success]
      assert_equal "https://checkout.stripe.com/pay/cs_test_123", result[:url]

      payment = @diagnostic.reload.payment
      assert_not_nil payment
      assert_equal "stripe",      payment.provider
      assert_equal "cs_test_123", payment.provider_payment_id
      assert payment.pending?
    end
  end

  test "returns error when Stripe raises" do
    Stripe::Checkout::Session.stub :create, ->(*) { raise Stripe::StripeError, "Card declined" } do
      result = Payments::StripeCheckoutService.call(diagnostic: @diagnostic, **@urls)
      assert_not result[:success]
      assert_includes result[:error], "Card declined"
    end
  end
end
```

**Step 5: Run — expect failure**

```bash
rails test test/services/payments/stripe_checkout_service_test.rb
```

**Step 6: Implement service**

```ruby
# app/services/payments/stripe_checkout_service.rb
module Payments
  class StripeCheckoutService
    def self.call(**args)
      new(**args).call
    end

    def initialize(diagnostic:, success_url:, cancel_url:)
      @diagnostic  = diagnostic
      @success_url = success_url
      @cancel_url  = cancel_url
    end

    def call
      session = Stripe::Checkout::Session.create(
        payment_method_types: ["card"],
        line_items: [{
          price_data: {
            currency:     Rails.application.credentials.dig(:stripe, :currency) || "xof",
            product_data: { name: "Diagnostic de Repositionnement Stratégique" },
            unit_amount:  Rails.application.credentials.dig(:stripe, :price_amount) || 300000
          },
          quantity: 1
        }],
        mode:                 "payment",
        client_reference_id: @diagnostic.id,
        customer_email:      @diagnostic.user.email,
        success_url:         @success_url,
        cancel_url:          @cancel_url
      )

      @diagnostic.create_payment!(
        user:                @diagnostic.user,
        provider:            :stripe,
        provider_payment_id: session.id,
        status:              :pending
      )

      { success: true, url: session.url }
    rescue Stripe::StripeError => e
      { success: false, error: e.message }
    end
  end
end
```

**Step 7: Run tests**

```bash
rails test test/services/payments/stripe_checkout_service_test.rb
```

Expected: 2 runs, 0 failures.

**Step 8: Commit**

```bash
git add app/services/payments/stripe_checkout_service.rb config/initializers/stripe.rb test/services/payments/stripe_checkout_service_test.rb
git commit -m "feat: add Stripe checkout service"
```

---

### Task 11: Pawapay deposit service

**Files:**
- Create: `app/services/payments/pawapay_deposit_service.rb`
- Create: `test/services/payments/pawapay_deposit_service_test.rb`

**Step 1: Add Pawapay credentials**

```bash
rails credentials:edit
```

Add:

```yaml
pawapay:
  api_token: YOUR_PAWAPAY_TOKEN
  base_url: https://api.pawapay.io
```

**Step 2: Write failing test**

```ruby
# test/services/payments/pawapay_deposit_service_test.rb
require "test_helper"

class Payments::PawapayDepositServiceTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "pawa#{SecureRandom.hex(4)}@test.com", password: "password123")
    @diagnostic = Diagnostic.create!(user: @user)
  end

  test "creates payment and returns deposit_id on success" do
    stub_request(:post, %r{api\.pawapay\.io/v1/deposits})
      .to_return(
        status: 201,
        headers: { "Content-Type" => "application/json" },
        body: { depositId: "pawa-abc-123", status: "ACCEPTED" }.to_json
      )

    result = Payments::PawapayDepositService.call(
      diagnostic:    @diagnostic,
      phone:         "2250701234567",
      operator_code: "ORANGE_CI"
    )

    assert result[:success]
    assert_equal "pawa-abc-123", result[:deposit_id]

    payment = @diagnostic.reload.payment
    assert_equal "pawapay",       payment.provider
    assert_equal "pawa-abc-123",  payment.provider_payment_id
    assert payment.pending?
  end

  test "returns error when Pawapay rejects" do
    stub_request(:post, %r{api\.pawapay\.io/v1/deposits})
      .to_return(
        status: 400,
        headers: { "Content-Type" => "application/json" },
        body: { status: "REJECTED", rejectionReason: "INVALID_MSISDN" }.to_json
      )

    result = Payments::PawapayDepositService.call(
      diagnostic:    @diagnostic,
      phone:         "bad_number",
      operator_code: "ORANGE_CI"
    )

    assert_not result[:success]
    assert_includes result[:error], "INVALID_MSISDN"
  end
end
```

**Step 3: Run — expect failure**

```bash
rails test test/services/payments/pawapay_deposit_service_test.rb
```

**Step 4: Implement service**

```ruby
# app/services/payments/pawapay_deposit_service.rb
require "net/http"
require "json"

module Payments
  class PawapayDepositService
    AMOUNT   = "3000"
    CURRENCY = "XOF"

    def self.call(**args)
      new(**args).call
    end

    def initialize(diagnostic:, phone:, operator_code:)
      @diagnostic    = diagnostic
      @phone         = phone
      @operator_code = operator_code
      @deposit_id    = SecureRandom.uuid
    end

    def call
      response = post_deposit
      body     = JSON.parse(response.body)

      if response.code.to_i == 201 && body["status"] == "ACCEPTED"
        deposit_id = body["depositId"] || @deposit_id
        @diagnostic.create_payment!(
          user:                @diagnostic.user,
          provider:            :pawapay,
          provider_payment_id: deposit_id,
          status:              :pending
        )
        { success: true, deposit_id: deposit_id }
      else
        reason = body["rejectionReason"] || body["message"] || "Payment rejected"
        { success: false, error: reason }
      end
    rescue => e
      { success: false, error: e.message }
    end

    private

    def post_deposit
      uri  = URI("#{base_url}/v1/deposits")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{api_token}"
      req["Content-Type"]  = "application/json"
      req.body = {
        depositId:            @deposit_id,
        amount:               AMOUNT,
        currency:             CURRENCY,
        correspondent:        @operator_code,
        recipient:            { type: "MSISDN", address: { value: @phone } },
        customerTimestamp:    Time.current.iso8601,
        statementDescription: "Diagnostic Repositionnement Strategique"
      }.to_json

      http.request(req)
    end

    def api_token = Rails.application.credentials.dig(:pawapay, :api_token)
    def base_url  = Rails.application.credentials.dig(:pawapay, :base_url) || "https://api.pawapay.io"
  end
end
```

**Step 5: Run tests**

```bash
rails test test/services/payments/pawapay_deposit_service_test.rb
```

Expected: 2 runs, 0 failures.

**Step 6: Commit**

```bash
git add app/services/payments/pawapay_deposit_service.rb test/services/payments/pawapay_deposit_service_test.rb
git commit -m "feat: add Pawapay deposit service"
```

---

### Task 12: Webhook handler services

**Files:**
- Create: `app/services/webhooks/stripe_handler_service.rb`
- Create: `app/services/webhooks/pawapay_handler_service.rb`
- Create: `test/services/webhooks/stripe_handler_service_test.rb`
- Create: `test/services/webhooks/pawapay_handler_service_test.rb`

**Step 1: Create directories**

```bash
mkdir -p app/services/webhooks test/services/webhooks
```

**Step 2: Write Stripe handler test**

```ruby
# test/services/webhooks/stripe_handler_service_test.rb
require "test_helper"

class Webhooks::StripeHandlerServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "stripe_hook#{SecureRandom.hex(4)}@test.com", password: "password123")
    @diagnostic = Diagnostic.create!(user: @user, status: :pending_payment)
    @payment    = @diagnostic.create_payment!(user: @user, provider: :stripe,
                                              provider_payment_id: "cs_test_abc", status: :pending)
  end

  test "confirms payment and sets diagnostic to paid" do
    event = {
      "type" => "checkout.session.completed",
      "data" => { "object" => { "id" => "cs_test_abc", "payment_status" => "paid" } }
    }

    result = Webhooks::StripeHandlerService.call(event)

    assert result[:processed]
    assert @payment.reload.confirmed?
    assert @diagnostic.reload.paid?
    assert_not_nil @diagnostic.paid_at
  end

  test "is idempotent — skips already confirmed payment" do
    @payment.update!(status: :confirmed)
    result = Webhooks::StripeHandlerService.call(
      "type" => "checkout.session.completed",
      "data" => { "object" => { "id" => "cs_test_abc" } }
    )
    assert result[:skipped]
  end

  test "skips unknown event types" do
    result = Webhooks::StripeHandlerService.call("type" => "customer.created")
    assert result[:skipped]
  end
end
```

**Step 3: Write Pawapay handler test**

```ruby
# test/services/webhooks/pawapay_handler_service_test.rb
require "test_helper"

class Webhooks::PawapayHandlerServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "pawa_hook#{SecureRandom.hex(4)}@test.com", password: "password123")
    @diagnostic = Diagnostic.create!(user: @user, status: :pending_payment, payment_provider: :pawapay)
    @payment    = @diagnostic.create_payment!(user: @user, provider: :pawapay,
                                              provider_payment_id: "pawa-456", status: :pending)
  end

  test "confirms payment on COMPLETED" do
    result = Webhooks::PawapayHandlerService.call("depositId" => "pawa-456", "status" => "COMPLETED")
    assert result[:processed]
    assert @payment.reload.confirmed?
    assert @diagnostic.reload.paid?
  end

  test "marks payment as failed on FAILED" do
    Webhooks::PawapayHandlerService.call("depositId" => "pawa-456", "status" => "FAILED")
    assert @payment.reload.failed?
  end

  test "is idempotent" do
    @payment.update!(status: :confirmed)
    result = Webhooks::PawapayHandlerService.call("depositId" => "pawa-456", "status" => "COMPLETED")
    assert result[:skipped]
  end
end
```

**Step 4: Run tests — expect failures**

```bash
rails test test/services/webhooks/
```

**Step 5: Implement Stripe handler**

```ruby
# app/services/webhooks/stripe_handler_service.rb
module Webhooks
  class StripeHandlerService
    def self.call(event_data)
      new(event_data).call
    end

    def initialize(event_data)
      @event_data = event_data
    end

    def call
      case @event_data["type"]
      when "checkout.session.completed"
        handle_checkout_completed
      else
        { skipped: true }
      end
    end

    private

    def handle_checkout_completed
      session = @event_data.dig("data", "object")
      payment = Payment.find_by(provider_payment_id: session["id"], provider: :stripe)

      return { skipped: true } if payment.nil? || payment.confirmed?

      ActiveRecord::Base.transaction do
        payment.update!(status: :confirmed, webhook_confirmed_at: Time.current)
        payment.diagnostic.update!(status: :paid, paid_at: Time.current)
      end

      { processed: true }
    end
  end
end
```

**Step 6: Implement Pawapay handler**

```ruby
# app/services/webhooks/pawapay_handler_service.rb
module Webhooks
  class PawapayHandlerService
    def self.call(payload)
      new(payload).call
    end

    def initialize(payload)
      @payload = payload
    end

    def call
      payment = Payment.find_by(provider_payment_id: @payload["depositId"], provider: :pawapay)
      return { skipped: true } if payment.nil? || payment.confirmed?

      case @payload["status"]
      when "COMPLETED"
        ActiveRecord::Base.transaction do
          payment.update!(status: :confirmed, webhook_confirmed_at: Time.current)
          payment.diagnostic.update!(status: :paid, paid_at: Time.current)
        end
        Diagnostics::GeneratePdfJob.perform_later(payment.diagnostic.id)
        { processed: true }
      when "FAILED"
        payment.update!(status: :failed)
        { processed: true }
      else
        { skipped: true }
      end
    end
  end
end
```

**Step 7: Run all webhook service tests**

```bash
rails test test/services/webhooks/
```

Expected: 6 runs, 0 failures.

**Step 8: Commit**

```bash
git add app/services/webhooks/ test/services/webhooks/
git commit -m "feat: add Stripe and Pawapay webhook handler services"
```

---

### Task 13: PDF generation service + job

**Files:**
- Create: `app/services/diagnostics/generate_pdf_service.rb`
- Create: `app/jobs/diagnostics/generate_pdf_job.rb`
- Create: `test/services/diagnostics/generate_pdf_service_test.rb`

**Step 1: Write failing test**

```ruby
# test/services/diagnostics/generate_pdf_service_test.rb
require "test_helper"

class Diagnostics::GeneratePdfServiceTest < ActiveSupport::TestCase
  def setup
    @user    = User.create!(email: "pdf#{SecureRandom.hex(4)}@test.com", password: "password123")
    @profile = Profile.create!(
      name: "Analyste & Veille", slug: "analyste-#{SecureRandom.hex(3)}",
      description: "Expert en analyse stratégique.",
      key_skills: ["Analyse", "Rédaction"],
      first_action: "Réalisez une analyse sectorielle.",
      premium_pitch: "Découvrez le Roadmap Premium."
    )
    @profile.trajectories.create!(
      axe_1: "ONG / Institution", axe_2: "Secteur privé", axe_3: "Expert long terme",
      active: true
    )
    @complementary = Profile.create!(name: "Coordinateur", slug: "coordo-#{SecureRandom.hex(3)}")
    @diagnostic = Diagnostic.create!(
      user: @user, status: :completed,
      primary_profile: @profile, complementary_profile: @complementary,
      score_data: { @profile.slug => 8, @complementary.slug => 5 }
    )
  end

  test "attaches PDF to diagnostic" do
    Diagnostics::GeneratePdfService.call(@diagnostic)
    @diagnostic.reload
    assert @diagnostic.pdf_report.attached?
    assert @diagnostic.pdf_generated?
  end

  test "generated file is a valid PDF" do
    Diagnostics::GeneratePdfService.call(@diagnostic)
    data = @diagnostic.pdf_report.download
    assert data.start_with?("%PDF")
    assert data.length > 500
  end
end
```

**Step 2: Run — expect failure**

```bash
rails test test/services/diagnostics/generate_pdf_service_test.rb
```

**Step 3: Create job directory**

```bash
mkdir -p app/jobs/diagnostics
```

**Step 4: Implement PDF service**

```ruby
# app/services/diagnostics/generate_pdf_service.rb
require "prawn"
require "prawn/table"

module Diagnostics
  class GeneratePdfService
    BRAND  = "1a365d"
    ACCENT = "2b6cb0"
    TEXT   = "2d3748"

    def self.call(diagnostic)
      new(diagnostic).call
    end

    def initialize(diagnostic)
      @d       = diagnostic
      @primary = diagnostic.primary_profile
      @second  = diagnostic.complementary_profile
      @user    = diagnostic.user
    end

    def call
      pdf = Prawn::Document.new(page_size: "A4", margin: [40, 50])
      build(pdf)
      attach(pdf.render)
    end

    private

    def build(pdf)
      header(pdf)
      pdf.move_down 20
      primary_section(pdf)
      pdf.move_down 12
      secondary_section(pdf)
      pdf.move_down 12
      trajectories_section(pdf)
      pdf.move_down 12
      skills_section(pdf)
      pdf.move_down 12
      action_section(pdf)
      pdf.move_down 12
      upsell_section(pdf)
    end

    def header(pdf)
      pdf.fill_color BRAND
      pdf.text "Diagnostic de Repositionnement Stratégique", size: 18, style: :bold
      pdf.fill_color TEXT
      pdf.text "Rapport généré pour : #{@user.email}", size: 10
      pdf.text "Date : #{I18n.l(Date.current, format: :long) rescue Date.current.to_s}", size: 10
      pdf.stroke_horizontal_rule
    end

    def primary_section(pdf)
      return unless @primary
      heading(pdf, "Votre Profil Principal")
      score = @d.score_data[@primary.slug].to_i
      pdf.text "#{@primary.name} — #{score} point(s)", size: 12, style: :bold, color: TEXT
      pdf.text @primary.description.to_s, size: 11, color: TEXT
    end

    def secondary_section(pdf)
      return unless @second
      heading(pdf, "Profil Complémentaire")
      score = @d.score_data[@second.slug].to_i
      pdf.text "#{@second.name} — #{score} point(s)", size: 11, color: TEXT
    end

    def trajectories_section(pdf)
      trajectory = @primary&.active_trajectory
      return unless trajectory
      heading(pdf, "Vos 3 Axes Stratégiques")
      [
        ["Axe 1 — Institutionnel / ONG",      trajectory.axe_1],
        ["Axe 2 — Secteur privé / hybride",   trajectory.axe_2],
        ["Axe 3 — Spécialisation long terme", trajectory.axe_3]
      ].each_with_index do |(title, text), i|
        pdf.text "#{i + 1}. #{title}", size: 11, style: :bold, color: TEXT
        pdf.text text.to_s, size: 11, color: TEXT
        pdf.move_down 4
      end
    end

    def skills_section(pdf)
      skills = @primary&.key_skills || []
      return if skills.empty?
      heading(pdf, "Compétences Clés à Développer")
      skills.each { |s| pdf.text "• #{s}", size: 11, color: TEXT }
    end

    def action_section(pdf)
      return unless @primary&.first_action
      heading(pdf, "Première Action Concrète")
      pdf.text @primary.first_action, size: 11, color: TEXT
    end

    def upsell_section(pdf)
      return unless @primary&.premium_pitch
      heading(pdf, "Passez au Roadmap Premium")
      pdf.text @primary.premium_pitch, size: 11, color: TEXT
    end

    def heading(pdf, text)
      pdf.fill_color ACCENT
      pdf.text text, size: 13, style: :bold
      pdf.fill_color TEXT
    end

    def attach(pdf_string)
      @d.pdf_report.attach(
        io:           StringIO.new(pdf_string),
        filename:     "diagnostic-#{@d.id}.pdf",
        content_type: "application/pdf"
      )
      @d.update!(pdf_generated: true)
    end
  end
end
```

**Step 5: Create job**

```ruby
# app/jobs/diagnostics/generate_pdf_job.rb
module Diagnostics
  class GeneratePdfJob < ApplicationJob
    queue_as :default

    def perform(diagnostic_id)
      diagnostic = Diagnostic.find_by(id: diagnostic_id)
      return if diagnostic.nil? || diagnostic.pdf_generated?
      Diagnostics::GeneratePdfService.call(diagnostic)
    end
  end
end
```

**Step 6: Run tests**

```bash
rails test test/services/diagnostics/generate_pdf_service_test.rb
```

Expected: 2 runs, 0 failures.

**Step 7: Commit**

```bash
git add app/services/diagnostics/generate_pdf_service.rb app/jobs/diagnostics/generate_pdf_job.rb test/services/diagnostics/generate_pdf_service_test.rb
git commit -m "feat: add PDF generation service and Sidekiq job"
```

---

### Task 14: Webhook controllers

**Files:**
- Create: `app/controllers/webhooks/stripe_controller.rb`
- Create: `app/controllers/webhooks/pawapay_controller.rb`
- Create: `test/controllers/webhooks/stripe_controller_test.rb`

**Step 1: Create directory**

```bash
mkdir -p app/controllers/webhooks test/controllers/webhooks
```

**Step 2: Write Stripe controller test**

```ruby
# test/controllers/webhooks/stripe_controller_test.rb
require "test_helper"

class Webhooks::StripeControllerTest < ActionDispatch::IntegrationTest
  test "returns 200 for valid webhook" do
    payload = { type: "checkout.session.completed",
                data: { object: { id: "cs_x" } } }.to_json

    # Stub signature verification to always pass
    Stripe::Webhook.stub :construct_event, true do
      post "/webhooks/stripe",
        params: payload,
        headers: { "Stripe-Signature" => "t=123,v1=abc", "CONTENT_TYPE" => "application/json" }
    end

    assert_response :ok
  end

  test "returns 400 for bad signature" do
    Stripe::Webhook.stub :construct_event, ->(*) { raise Stripe::SignatureVerificationError.new("bad", "hdr") } do
      post "/webhooks/stripe",
        params: "{}",
        headers: { "Stripe-Signature" => "bad", "CONTENT_TYPE" => "application/json" }
    end

    assert_response :bad_request
  end
end
```

**Step 3: Run — expect failure**

```bash
rails test test/controllers/webhooks/stripe_controller_test.rb
```

**Step 4: Create Stripe webhook controller**

```ruby
# app/controllers/webhooks/stripe_controller.rb
module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_stripe_signature

    def receive
      event_data = JSON.parse(request.body.read)
      Webhooks::StripeHandlerService.call(event_data)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def verify_stripe_signature
      payload    = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      secret     = Rails.application.credentials.dig(:stripe, :webhook_secret)

      Stripe::Webhook.construct_event(payload, sig_header, secret)
      request.body.rewind
    rescue Stripe::SignatureVerificationError
      head :bad_request
    end
  end
end
```

**Step 5: Create Pawapay webhook controller**

```ruby
# app/controllers/webhooks/pawapay_controller.rb
module Webhooks
  class PawapayController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      payload = JSON.parse(request.body.read)
      Webhooks::PawapayHandlerService.call(payload)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end
  end
end
```

**Step 6: Run tests**

```bash
rails test test/controllers/webhooks/stripe_controller_test.rb
```

Expected: 2 runs, 0 failures.

**Step 7: Commit**

```bash
git add app/controllers/webhooks/ test/controllers/webhooks/
git commit -m "feat: add Stripe and Pawapay webhook controllers"
```

---

### Task 15: DiagnosticsController + PaymentsController

**Files:**
- Create: `app/controllers/diagnostics_controller.rb`
- Create: `app/controllers/payments_controller.rb`
- Create: `app/controllers/mobile_operators_controller.rb`
- Create: `test/controllers/diagnostics_controller_test.rb`

**Step 1: Write failing controller tests**

```ruby
# test/controllers/diagnostics_controller_test.rb
require "test_helper"

class DiagnosticsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "ctrl#{SecureRandom.hex(4)}@test.com", password: "password123")
  end

  test "GET new redirects unauthenticated users to login" do
    get new_diagnostic_path
    assert_redirected_to new_user_session_path
  end

  test "GET new renders for authenticated user" do
    sign_in @user
    get new_diagnostic_path
    assert_response :success
  end

  test "GET questionnaire blocks unpaid diagnostic" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :pending_payment)
    get questionnaire_diagnostic_path(d)
    assert_redirected_to new_diagnostic_path
  end

  test "GET questionnaire allows paid diagnostic" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :paid)
    get questionnaire_diagnostic_path(d)
    assert_response :success
  end

  private

  def sign_in(user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end
end
```

**Step 2: Run — expect failure**

```bash
rails test test/controllers/diagnostics_controller_test.rb
```

**Step 3: Create DiagnosticsController**

```ruby
# app/controllers/diagnostics_controller.rb
class DiagnosticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_diagnostic, only: [:show, :questionnaire, :submit_bloc, :results, :pdf_status, :download_pdf]
  before_action :require_paid!,      only: [:questionnaire, :submit_bloc]
  before_action :require_completed!, only: [:results, :pdf_status, :download_pdf]

  def new
    @mobile_operators = MobileOperator.active.group_by(&:country_code)
    @default_country  = detect_country
  end

  def create
    @diagnostic = current_user.diagnostics.create!(payment_provider: payment_provider_param)

    case payment_provider_param
    when "stripe"  then handle_stripe_payment
    when "pawapay" then handle_pawapay_payment
    end
  end

  def questionnaire
    @current_bloc = current_bloc
    @questions    = Question.active.by_bloc(@current_bloc)
  end

  def submit_bloc
    bloc_number = params[:bloc].to_i

    Question.active.by_bloc(bloc_number).each do |question|
      value  = params.dig(:answers, question.id.to_s)
      next if value.blank?

      option = question.options.find { |o| o["value"] == value }
      next unless option

      @diagnostic.diagnostic_answers.find_or_create_by!(question: question) do |a|
        a.answer_value      = value
        a.profile_dimension = option["profile_slug"]
        a.points_awarded    = option["points"].to_i
      end
    end

    @diagnostic.update!(status: :in_progress) if @diagnostic.paid?

    if bloc_number >= 5
      Diagnostics::ScoringService.call(@diagnostic)
      redirect_to results_diagnostic_path(@diagnostic)
    else
      redirect_to questionnaire_diagnostic_path(@diagnostic, bloc: bloc_number + 1)
    end
  end

  def results
    @trajectory = @diagnostic.primary_profile&.active_trajectory

    if @diagnostic.provider_stripe? && !@diagnostic.pdf_generated?
      Diagnostics::GeneratePdfService.call(@diagnostic)
      @diagnostic.reload
    end
  end

  def pdf_status
    render json: { ready: @diagnostic.pdf_generated? }
  end

  def download_pdf
    if @diagnostic.pdf_report.attached?
      redirect_to rails_blob_path(@diagnostic.pdf_report, disposition: "attachment")
    else
      redirect_to results_diagnostic_path(@diagnostic), alert: t("diagnostics.pdf_not_ready", default: "PDF not ready yet")
    end
  end

  private

  def set_diagnostic
    @diagnostic = current_user.diagnostics.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end

  def require_paid!
    unless @diagnostic.paid? || @diagnostic.in_progress? || @diagnostic.completed?
      redirect_to new_diagnostic_path
    end
  end

  def require_completed!
    redirect_to questionnaire_diagnostic_path(@diagnostic) unless @diagnostic.completed?
  end

  def payment_provider_param
    params[:payment_method].in?(%w[stripe pawapay]) ? params[:payment_method] : "stripe"
  end

  def handle_stripe_payment
    result = Payments::StripeCheckoutService.call(
      diagnostic:  @diagnostic,
      success_url: questionnaire_diagnostic_url(@diagnostic),
      cancel_url:  new_diagnostic_url
    )

    if result[:success]
      redirect_to result[:url], allow_other_host: true
    else
      @diagnostic.destroy
      redirect_to new_diagnostic_path, alert: result[:error]
    end
  end

  def handle_pawapay_payment
    result = Payments::PawapayDepositService.call(
      diagnostic:    @diagnostic,
      phone:         params[:phone],
      operator_code: params[:operator_code]
    )

    if result[:success]
      redirect_to status_payment_path(@diagnostic.payment)
    else
      @diagnostic.destroy
      redirect_to new_diagnostic_path, alert: result[:error]
    end
  end

  def detect_country
    cookies[:country].presence || "CI"
  end

  def current_bloc
    (params[:bloc] || 1).to_i.clamp(1, 5)
  end
end
```

**Step 4: Create PaymentsController**

```ruby
# app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def status
    @payment = current_user.payments.find(params[:id])

    respond_to do |format|
      format.html
      format.turbo_stream do
        if @payment.confirmed?
          render turbo_stream: turbo_stream.replace(
            "payment-status",
            partial: "payments/confirmed",
            locals:  { diagnostic: @payment.diagnostic }
          )
        else
          render turbo_stream: turbo_stream.replace("payment-status", partial: "payments/waiting",
                                                    locals: { payment: @payment })
        end
      end
      format.json { render json: { status: @payment.status } }
    end
  end
end
```

**Step 5: Create MobileOperatorsController**

```ruby
# app/controllers/mobile_operators_controller.rb
class MobileOperatorsController < ApplicationController
  def index
    @operators = MobileOperator.active.by_country(params[:country] || "CI")
    render partial: "mobile_operators/list", locals: { operators: @operators }
  end
end
```

**Step 6: Run tests**

```bash
rails test test/controllers/diagnostics_controller_test.rb
```

Expected: 4 runs, 0 failures.

**Step 7: Commit**

```bash
git add app/controllers/diagnostics_controller.rb app/controllers/payments_controller.rb app/controllers/mobile_operators_controller.rb test/controllers/diagnostics_controller_test.rb
git commit -m "feat: add DiagnosticsController, PaymentsController, MobileOperatorsController"
```

---

### Task 16: Views — Checkout

**Files:**
- Create: `app/views/diagnostics/new.html.erb`
- Create: `app/views/mobile_operators/_list.html.erb`
- Create: `app/views/payments/status.html.erb`
- Create: `app/views/payments/_waiting.html.erb`
- Create: `app/views/payments/_confirmed.html.erb`
- Create: `app/javascript/controllers/operators_controller.js`
- Create: `app/javascript/controllers/poll_controller.js`

**Step 1: Create checkout page**

```erb
<%# app/views/diagnostics/new.html.erb %>
<div class="max-w-2xl mx-auto px-4 py-12">
  <h1 class="text-2xl font-bold text-gray-900 mb-2">Diagnostic de Repositionnement Stratégique</h1>
  <p class="text-gray-500 mb-8">3 000 FCFA — Accès immédiat + rapport PDF personnalisé</p>

  <div class="grid gap-6">
    <!-- Stripe card -->
    <div class="border rounded-xl p-6 bg-white shadow-sm">
      <h2 class="text-lg font-semibold mb-4">💳 Payer par carte bancaire</h2>
      <%= form_with url: diagnostics_path do |f| %>
        <%= f.hidden_field :payment_method, value: "stripe" %>
        <%= f.submit "Payer par carte — 3 000 FCFA",
              class: "w-full bg-blue-700 hover:bg-blue-800 text-white py-3 rounded-lg font-semibold" %>
      <% end %>
    </div>

    <!-- Pawapay mobile money -->
    <div class="border rounded-xl p-6 bg-white shadow-sm" data-controller="operators">
      <h2 class="text-lg font-semibold mb-4">📱 Payer par Mobile Money</h2>
      <%= form_with url: diagnostics_path do |f| %>
        <%= f.hidden_field :payment_method, value: "pawapay" %>

        <div class="mb-4">
          <%= f.label :country, "Pays", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= f.select :country,
                @mobile_operators.keys.sort.map { |c| [c, c] },
                { selected: @default_country },
                class: "w-full border rounded-lg px-3 py-2 text-sm",
                data: { operators_target: "country", action: "change->operators#updateList" } %>
        </div>

        <div class="mb-4">
          <%= f.label :phone, "Numéro de téléphone", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= f.telephone_field :phone, placeholder: "Ex: 0701234567", required: true,
                class: "w-full border rounded-lg px-3 py-2 text-sm" %>
        </div>

        <div class="mb-6">
          <%= f.label :operator_code, "Opérateur", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <div data-operators-target="list">
            <%= render "mobile_operators/list", operators: (@mobile_operators[@default_country] || []) %>
          </div>
        </div>

        <%= f.submit "Payer par Mobile Money — 3 000 FCFA",
              class: "w-full bg-green-700 hover:bg-green-800 text-white py-3 rounded-lg font-semibold" %>
      <% end %>
    </div>
  </div>
</div>
```

**Step 2: Create operator list partial**

```erb
<%# app/views/mobile_operators/_list.html.erb %>
<% operators.each do |op| %>
  <label class="flex items-center gap-3 p-3 border rounded-lg mb-2 cursor-pointer hover:bg-blue-50">
    <input type="radio" name="operator_code" value="<%= op.code %>" required class="accent-blue-600">
    <span class="text-sm font-medium"><%= op.name %></span>
  </label>
<% end %>
```

**Step 3: Create Pawapay waiting views**

```erb
<%# app/views/payments/status.html.erb %>
<div class="max-w-lg mx-auto px-4 py-16 text-center">
  <div id="payment-status">
    <%= render "waiting", payment: @payment %>
  </div>
</div>
```

```erb
<%# app/views/payments/_waiting.html.erb %>
<div data-controller="poll"
     data-poll-url-value="<%= status_payment_path(payment, format: :turbo_stream) %>"
     data-poll-interval-value="5000">
  <div class="text-5xl mb-4">📱</div>
  <h2 class="text-xl font-bold text-gray-900 mb-2">Vérifiez votre téléphone</h2>
  <p class="text-gray-600 mb-4">Confirmez la demande de paiement pour accéder au questionnaire.</p>
  <div class="animate-pulse text-blue-600 text-sm">En attente de confirmation…</div>
</div>
```

```erb
<%# app/views/payments/_confirmed.html.erb %>
<div>
  <div class="text-5xl mb-4">✅</div>
  <h2 class="text-xl font-bold text-gray-900 mb-2">Paiement confirmé !</h2>
  <p class="text-gray-600 mb-6">Votre diagnostic est maintenant accessible.</p>
  <%= link_to "Commencer le questionnaire →",
        questionnaire_diagnostic_path(diagnostic),
        class: "inline-block bg-blue-700 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-800" %>
</div>
```

**Step 4: Create Stimulus controllers**

```javascript
// app/javascript/controllers/operators_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["country", "list"]

  updateList() {
    const country = this.countryTarget.value
    fetch(`/mobile_operators?country=${country}`, {
      headers: { Accept: "text/html" }
    })
      .then(r => r.text())
      .then(html => { this.listTarget.innerHTML = html })
  }
}
```

```javascript
// app/javascript/controllers/poll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 5000 } }

  connect() {
    this.timer = setInterval(() => this.#poll(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  #poll() {
    fetch(this.urlValue, { headers: { Accept: "text/vnd.turbo-stream.html" } })
      .then(r => r.text())
      .then(html => {
        const target = document.getElementById("payment-status")
        if (target) target.outerHTML = html
      })
  }
}
```

**Step 5: Register controllers in index.js**

In `app/javascript/controllers/index.js`, add:

```javascript
import OperatorsController from "./operators_controller"
import PollController from "./poll_controller"

application.register("operators", OperatorsController)
application.register("poll", PollController)
```

**Step 6: Commit**

```bash
git add app/views/diagnostics/new.html.erb app/views/payments/ app/views/mobile_operators/ app/javascript/controllers/
git commit -m "feat: add checkout views, Pawapay waiting screen, Stimulus controllers"
```

---

### Task 17: Views — Questionnaire

**Files:**
- Create: `app/views/diagnostics/questionnaire.html.erb`
- Create: `app/views/diagnostics/_question.html.erb`
- Create: `app/helpers/diagnostics_helper.rb`

**Step 1: Create questionnaire view**

```erb
<%# app/views/diagnostics/questionnaire.html.erb %>
<div class="max-w-2xl mx-auto px-4 py-10">
  <div class="mb-8">
    <div class="flex justify-between text-sm text-gray-500 mb-1">
      <span>Bloc <%= @current_bloc %> sur 5</span>
      <span><%= (@current_bloc - 1) * 20 %>%</span>
    </div>
    <div class="w-full bg-gray-200 rounded-full h-2">
      <div class="bg-blue-600 h-2 rounded-full"
           style="width: <%= (@current_bloc - 1) * 20 %>%"></div>
    </div>
  </div>

  <h2 class="text-xl font-bold text-gray-900 mb-1"><%= bloc_title(@current_bloc) %></h2>
  <p class="text-sm text-gray-400 mb-8">
    Questions <%= (@current_bloc - 1) * 5 + 1 %>–<%= @current_bloc * 5 %> sur 25
  </p>

  <%= form_with url: submit_bloc_diagnostic_path(@diagnostic), method: :post do |f| %>
    <%= f.hidden_field :bloc, value: @current_bloc %>

    <% @questions.each_with_index do |question, index| %>
      <%= render "question", question: question, form: f,
                             number: (@current_bloc - 1) * 5 + index + 1 %>
    <% end %>

    <div class="mt-8">
      <%= f.submit(@current_bloc < 5 ? "Continuer →" : "Voir mes résultats",
            class: "w-full bg-blue-700 hover:bg-blue-800 text-white py-3 rounded-lg font-semibold") %>
    </div>
  <% end %>
</div>
```

**Step 2: Create question partial**

```erb
<%# app/views/diagnostics/_question.html.erb %>
<div class="mb-8 p-5 border rounded-xl bg-white shadow-sm">
  <p class="font-medium text-gray-800 mb-4">
    <span class="text-gray-400 text-sm mr-2"><%= number %>.</span>
    <%= question.text %>
  </p>

  <% if question.kind == "likert" %>
    <div class="flex items-center justify-between gap-2">
      <span class="text-xs text-gray-400 shrink-0">Pas du tout</span>
      <div class="flex gap-4">
        <% (1..5).each do |val| %>
          <label class="flex flex-col items-center gap-1 cursor-pointer">
            <%= form.radio_button "answers[#{question.id}]", val.to_s, required: true,
                  class: "accent-blue-600 w-5 h-5" %>
            <span class="text-sm text-gray-600"><%= val %></span>
          </label>
        <% end %>
      </div>
      <span class="text-xs text-gray-400 shrink-0">Tout à fait</span>
    </div>
  <% else %>
    <% question.options.each do |opt| %>
      <label class="flex items-start gap-3 p-3 border rounded-lg mb-2 cursor-pointer hover:bg-blue-50">
        <%= form.radio_button "answers[#{question.id}]", opt["value"], required: true,
              class: "mt-0.5 accent-blue-600" %>
        <span class="text-sm">
          <% if opt["label"].present? %>
            <strong><%= opt["label"] %></strong>
            <% if opt["text"].present? %> — <%= opt["text"] %><% end %>
          <% else %>
            <%= opt["value"] %>
          <% end %>
        </span>
      </label>
    <% end %>
  <% end %>
</div>
```

**Step 3: Create helper**

```ruby
# app/helpers/diagnostics_helper.rb
module DiagnosticsHelper
  BLOC_TITLES = {
    1 => "Orientation naturelle",
    2 => "Projection 5–10 ans",
    3 => "Relation au digital",
    4 => "Situation actuelle",
    5 => "Ambition & mobilité"
  }.freeze

  def bloc_title(n)
    "Bloc #{n} : #{BLOC_TITLES[n]}"
  end
end
```

**Step 4: Commit**

```bash
git add app/views/diagnostics/questionnaire.html.erb app/views/diagnostics/_question.html.erb app/helpers/diagnostics_helper.rb
git commit -m "feat: add questionnaire views and helper"
```

---

### Task 18: Views — Results page

**Files:**
- Create: `app/views/diagnostics/results.html.erb`

**Step 1: Create results view**

```erb
<%# app/views/diagnostics/results.html.erb %>
<div class="max-w-3xl mx-auto px-4 py-12">
  <h1 class="text-2xl font-bold text-gray-900 mb-1">Vos Résultats</h1>
  <p class="text-sm text-gray-400 mb-10">
    Diagnostic complété le <%= l(@diagnostic.completed_at&.to_date, format: :long) rescue @diagnostic.completed_at&.to_date %>
  </p>

  <% if @diagnostic.primary_profile %>
    <div class="bg-blue-50 border border-blue-200 rounded-xl p-6 mb-5">
      <div class="text-xs font-semibold text-blue-500 uppercase tracking-wide mb-1">Profil Principal</div>
      <h2 class="text-xl font-bold text-blue-900"><%= @diagnostic.primary_profile.name %></h2>
      <p class="text-blue-800 text-sm mt-1"><%= @diagnostic.primary_profile.description %></p>
    </div>
  <% end %>

  <% if @diagnostic.complementary_profile %>
    <div class="bg-gray-50 border rounded-xl p-4 mb-5">
      <div class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1">Profil Complémentaire</div>
      <h3 class="font-bold text-gray-800"><%= @diagnostic.complementary_profile.name %></h3>
    </div>
  <% end %>

  <% if @trajectory %>
    <div class="mb-8">
      <h3 class="text-lg font-bold text-gray-900 mb-4">Vos 3 Axes Stratégiques</h3>
      <% [
          ["Institutionnel / ONG",      @trajectory.axe_1],
          ["Secteur privé / hybride",   @trajectory.axe_2],
          ["Spécialisation long terme", @trajectory.axe_3]
         ].each_with_index do |(title, text), i| %>
        <div class="mb-4 pl-4 border-l-4 border-blue-500">
          <div class="font-semibold text-gray-800 text-sm">Axe <%= i + 1 %> — <%= title %></div>
          <p class="text-gray-600 text-sm mt-0.5"><%= text %></p>
        </div>
      <% end %>
    </div>
  <% end %>

  <div class="mt-10 p-6 bg-gray-50 rounded-xl text-center">
    <% if @diagnostic.pdf_generated? %>
      <%= link_to "⬇ Télécharger mon rapport PDF",
            download_pdf_diagnostic_path(@diagnostic),
            class: "inline-block bg-blue-700 text-white px-8 py-3 rounded-lg font-semibold hover:bg-blue-800" %>
    <% else %>
      <div id="pdf-status" data-controller="poll"
           data-poll-url-value="<%= pdf_status_diagnostic_path(@diagnostic, format: :json) %>"
           data-poll-interval-value="3000">
        <p class="text-gray-500 mb-2">Votre rapport PDF est en cours de génération…</p>
        <div class="animate-pulse text-blue-600 text-sm">Veuillez patienter</div>
      </div>
    <% end %>
  </div>
</div>
```

**Step 2: Commit**

```bash
git add app/views/diagnostics/results.html.erb
git commit -m "feat: add results page with PDF download and polling"
```

---

### Task 19: Admin controllers

**Files:**
- Create: `app/controllers/admin/profiles_controller.rb`
- Create: `app/controllers/admin/trajectories_controller.rb`
- Create: `app/controllers/admin/questions_controller.rb`
- Create: `app/controllers/admin/mobile_operators_controller.rb`
- Create: `app/controllers/admin/diagnostics_controller.rb`
- Create: Views for each (index + form)

**Step 1: Create all five admin controllers**

```ruby
# app/controllers/admin/profiles_controller.rb
class Admin::ProfilesController < Admin::BaseController
  before_action :set_profile, only: [:show, :edit, :update, :destroy]

  def index   = render
  def show    = render
  def new     = (@profile = Profile.new) && render
  def edit    = render

  def create
    @profile = Profile.new(profile_params)
    @profile.save ? redirect_to(admin_profiles_path, notice: "Profil créé.") : render(:new, status: :unprocessable_entity)
  end

  def update
    @profile.update(profile_params) ? redirect_to(admin_profiles_path, notice: "Profil mis à jour.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    @profile.destroy
    redirect_to admin_profiles_path, notice: "Profil supprimé."
  end

  private

  def set_profile   = @profile = Profile.find(params[:id])
  def profile_params
    params.require(:profile).permit(:name, :slug, :description, :first_action, :premium_pitch,
                                    key_skills: [])
  end
end
```

```ruby
# app/controllers/admin/trajectories_controller.rb
class Admin::TrajectoriesController < Admin::BaseController
  before_action :set_trajectory, only: [:edit, :update, :destroy]

  def index   = (@trajectories = Trajectory.includes(:profile).order("profiles.name")) && render
  def new     = (@trajectory = Trajectory.new(profile_id: params[:profile_id]); @profiles = Profile.order(:name)) && render
  def edit    = (@profiles = Profile.order(:name)) && render

  def create
    @trajectory = Trajectory.new(trajectory_params)
    @trajectory.save ? redirect_to(admin_trajectories_path, notice: "Trajectoire créée.") : ((@profiles = Profile.order(:name)) && render(:new, status: :unprocessable_entity))
  end

  def update
    @trajectory.update(trajectory_params) ? redirect_to(admin_trajectories_path, notice: "Trajectoire mise à jour.") : ((@profiles = Profile.order(:name)) && render(:edit, status: :unprocessable_entity))
  end

  def destroy
    @trajectory.destroy
    redirect_to admin_trajectories_path, notice: "Trajectoire supprimée."
  end

  private

  def set_trajectory = @trajectory = Trajectory.find(params[:id])
  def trajectory_params = params.require(:trajectory).permit(:profile_id, :axe_1, :axe_2, :axe_3, :active)
end
```

```ruby
# app/controllers/admin/questions_controller.rb
class Admin::QuestionsController < Admin::BaseController
  before_action :set_question, only: [:edit, :update, :destroy]

  def index   = (@questions = Question.order(:bloc, :position)) && render
  def new     = (@question = Question.new) && render
  def edit    = render

  def create
    @question = Question.new(question_params)
    @question.save ? redirect_to(admin_questions_path, notice: "Question créée.") : render(:new, status: :unprocessable_entity)
  end

  def update
    @question.update(question_params) ? redirect_to(admin_questions_path, notice: "Question mise à jour.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    @question.destroy
    redirect_to admin_questions_path, notice: "Question supprimée."
  end

  private

  def set_question = @question = Question.find(params[:id])
  def question_params
    params.require(:question).permit(:bloc, :text, :kind, :scored, :position, :active)
    # Note: options (JSONB) need custom handling — edit via Rails credentials or a JSON textarea
  end
end
```

```ruby
# app/controllers/admin/mobile_operators_controller.rb
class Admin::MobileOperatorsController < Admin::BaseController
  before_action :set_operator, only: [:edit, :update, :destroy]

  def index   = (@operators = MobileOperator.order(:country_code, :name)) && render
  def new     = (@operator = MobileOperator.new) && render
  def edit    = render

  def create
    @operator = MobileOperator.new(operator_params)
    @operator.save ? redirect_to(admin_mobile_operators_path, notice: "Opérateur créé.") : render(:new, status: :unprocessable_entity)
  end

  def update
    @operator.update(operator_params) ? redirect_to(admin_mobile_operators_path, notice: "Opérateur mis à jour.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    @operator.destroy
    redirect_to admin_mobile_operators_path, notice: "Opérateur supprimé."
  end

  private

  def set_operator = @operator = MobileOperator.find(params[:id])
  def operator_params = params.require(:mobile_operator).permit(:name, :code, :country_code, :logo_url, :active)
end
```

```ruby
# app/controllers/admin/diagnostics_controller.rb
class Admin::DiagnosticsController < Admin::BaseController
  def index
    @pagy, @diagnostics = pagy(
      Diagnostic.includes(:user, :primary_profile, :payment).order(created_at: :desc)
    )
  end

  def show
    @diagnostic = Diagnostic.includes(:user, :primary_profile, :complementary_profile,
                                      :diagnostic_answers, :payment).find(params[:id])
  end
end
```

**Step 2: Create minimal admin views — profiles index as example**

```erb
<%# app/views/admin/profiles/index.html.erb %>
<div class="px-6 py-6">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-xl font-bold">Profils (<%= @profiles.count %>)</h1>
    <%= link_to "Nouveau", new_admin_profile_path, class: "bg-blue-700 text-white px-4 py-2 rounded text-sm" %>
  </div>
  <table class="w-full text-sm border-collapse">
    <thead><tr class="border-b text-left text-gray-500">
      <th class="pb-2 pr-4">Nom</th>
      <th class="pb-2 pr-4">Slug</th>
      <th class="pb-2">Trajectoires</th>
      <th></th>
    </tr></thead>
    <tbody>
      <% @profiles.each do |profile| %>
        <tr class="border-b hover:bg-gray-50">
          <td class="py-2 pr-4 font-medium"><%= profile.name %></td>
          <td class="pr-4 text-gray-500"><%= profile.slug %></td>
          <td><%= profile.trajectories.count %></td>
          <td class="text-right">
            <%= link_to "Modifier", edit_admin_profile_path(profile), class: "text-blue-600 mr-3 text-xs" %>
            <%= button_to "Supprimer", admin_profile_path(profile), method: :delete,
                  data: { turbo_confirm: "Confirmer la suppression ?" },
                  class: "text-red-500 text-xs bg-transparent border-0 cursor-pointer" %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

**Create form partial for profiles:**

```erb
<%# app/views/admin/profiles/_form.html.erb %>
<%= form_with model: [:admin, profile], class: "space-y-4 max-w-2xl" do |f| %>
  <% if profile.errors.any? %>
    <div class="bg-red-50 border border-red-200 p-3 rounded text-sm text-red-700">
      <% profile.errors.full_messages.each do |msg| %>
        <div><%= msg %></div>
      <% end %>
    </div>
  <% end %>

  <div>
    <%= f.label :name, "Nom", class: "block text-sm font-medium text-gray-700 mb-1" %>
    <%= f.text_field :name, class: "w-full border rounded px-3 py-2 text-sm" %>
  </div>
  <div>
    <%= f.label :slug, "Slug", class: "block text-sm font-medium text-gray-700 mb-1" %>
    <%= f.text_field :slug, class: "w-full border rounded px-3 py-2 text-sm" %>
  </div>
  <div>
    <%= f.label :description, class: "block text-sm font-medium text-gray-700 mb-1" %>
    <%= f.text_area :description, rows: 3, class: "w-full border rounded px-3 py-2 text-sm" %>
  </div>
  <div>
    <%= f.label :first_action, "Première action concrète", class: "block text-sm font-medium text-gray-700 mb-1" %>
    <%= f.text_area :first_action, rows: 2, class: "w-full border rounded px-3 py-2 text-sm" %>
  </div>
  <div>
    <%= f.label :premium_pitch, "Pitch Roadmap Premium", class: "block text-sm font-medium text-gray-700 mb-1" %>
    <%= f.text_area :premium_pitch, rows: 2, class: "w-full border rounded px-3 py-2 text-sm" %>
  </div>

  <%= f.submit "Enregistrer", class: "bg-blue-700 text-white px-6 py-2 rounded font-medium text-sm" %>
<% end %>
```

Create `new.html.erb` and `edit.html.erb` that just render the form partial. Do the same minimal pattern (index table + form partial + new/edit wrappers) for trajectories, questions, mobile_operators, and diagnostics.

For `admin/diagnostics/index.html.erb`, show: user email, status badge, primary profile name, created_at, and a "Voir" link.

**Step 3: Commit**

```bash
git add app/controllers/admin/ app/views/admin/
git commit -m "feat: add admin controllers and views for profiles, trajectories, questions, operators, diagnostics"
```

---

### Task 20: Pundit policies

**Files:**
- Create: `app/policies/diagnostic_policy.rb`
- Create: `app/policies/profile_policy.rb`
- Create: `app/policies/trajectory_policy.rb`
- Create: `app/policies/question_policy.rb`
- Create: `app/policies/mobile_operator_policy.rb`

**Step 1: Create diagnostic policy**

```ruby
# app/policies/diagnostic_policy.rb
class DiagnosticPolicy < ApplicationPolicy
  def show?        = own_or_admin?
  def create?      = user.present?
  def questionnaire? = own_or_admin?
  def submit_bloc? = own_or_admin?
  def results?     = own_or_admin?
  def pdf_status?  = own_or_admin?
  def download_pdf? = own_or_admin?

  class Scope < Scope
    def resolve
      user.admin? ? scope.all : scope.where(user: user)
    end
  end

  private

  def own_or_admin?
    record.user_id == user.id || user.admin?
  end
end
```

**Step 2: Create admin-only policies**

```ruby
# app/policies/profile_policy.rb
class ProfilePolicy < ApplicationPolicy
  def index?   = user.admin?
  def show?    = user.admin?
  def create?  = user.admin?
  def update?  = user.admin?
  def destroy? = user.admin?
end

# app/policies/trajectory_policy.rb
class TrajectoryPolicy < ApplicationPolicy
  def index?   = user.admin?
  def create?  = user.admin?
  def update?  = user.admin?
  def destroy? = user.admin?
end

# app/policies/question_policy.rb
class QuestionPolicy < ApplicationPolicy
  def index?   = user.admin?
  def create?  = user.admin?
  def update?  = user.admin?
  def destroy? = user.admin?
end

# app/policies/mobile_operator_policy.rb
class MobileOperatorPolicy < ApplicationPolicy
  def index?   = user.admin?
  def create?  = user.admin?
  def update?  = user.admin?
  def destroy? = user.admin?
end
```

**Step 3: Run full test suite**

```bash
rails test
```

Expected: All tests pass. Fix any failures before proceeding.

**Step 4: Commit**

```bash
git add app/policies/
git commit -m "feat: add Pundit policies for diagnostics and admin resources"
```

---

### Task 21: End-to-end smoke test + Stripe webhook local testing

**Step 1: Start the dev server**

```bash
./bin/dev
```

**Step 2: Set up Stripe CLI for local webhook forwarding**

Download Stripe CLI from https://stripe.com/docs/stripe-cli, then:

```bash
stripe login
stripe listen --forward-to localhost:3000/webhooks/stripe
```

Note the webhook signing secret printed — add it to credentials:

```bash
rails credentials:edit
# Update stripe.webhook_secret with the whsec_... value shown by stripe listen
```

**Step 3: Manual smoke test — Stripe flow**

1. Visit `http://localhost:3000/diagnostics/new` (must be logged in)
2. Click "Payer par carte — 3 000 FCFA"
3. Verify redirect to Stripe Checkout test page
4. Use test card `4242 4242 4242 4242`, any future date, any CVC
5. Verify redirect back to `/diagnostics/:id/questionnaire`
6. Complete all 5 blocs
7. Verify redirect to results page with profile shown
8. Verify PDF download works

**Step 4: Manual smoke test — Pawapay flow** (test mode)

1. Visit `http://localhost:3000/diagnostics/new`
2. Select a country, enter a test phone number, select an operator
3. Click "Payer par Mobile Money"
4. Verify redirect to waiting screen with poll animation
5. Simulate Pawapay webhook:
```bash
curl -X POST http://localhost:3000/webhooks/pawapay \
  -H "Content-Type: application/json" \
  -d '{"depositId":"<DEPOSIT_ID_FROM_DB>","status":"COMPLETED","amount":"3000","currency":"XOF"}'
```
6. Verify waiting screen updates to "Paiement confirmé !"
7. Click "Commencer le questionnaire" and complete the flow
8. Verify PDF is generated via Sidekiq (check Sidekiq web at `/sidekiq`)

**Step 5: Commit any fixes found during smoke testing**

```bash
git add -p
git commit -m "fix: smoke test corrections"
```

---

## Deployment Checklist (Railway)

Before deploying:

1. **Set environment variables in Railway:**
   - `RAILS_MASTER_KEY` — from `config/master.key`
   - `REDIS_URL` — from Railway Redis service
   - `DATABASE_URL` — from Railway PostgreSQL service

2. **Configure webhooks:**
   - Stripe Dashboard → Webhooks → Add endpoint: `https://your-app.railway.app/webhooks/stripe`
   - Select event: `checkout.session.completed`
   - Copy the signing secret to credentials

   - Pawapay Dashboard → Webhook URL: `https://your-app.railway.app/webhooks/pawapay`

3. **Active Storage** — Railway uses ephemeral disk. Configure S3 or Cloudflare R2 for production PDF storage in `config/storage.yml` and `config/environments/production.rb`.

4. **Run migrations on deploy:**
   ```bash
   rails db:migrate
   rails db:seed  # only first deploy
   ```
