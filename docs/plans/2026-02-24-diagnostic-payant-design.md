# Diagnostic Payant — Design Document

**Date:** 2026-02-24
**Feature:** Étape 2 — Diagnostic Payant
**Status:** Approved

---

## Overview

A paid diagnostic feature that gates access to a 25-question professional positioning questionnaire behind a payment (Stripe or mobile money via Pawapay). After completing the questionnaire, a score is calculated automatically and a personalized PDF report is generated.

**Price:** 3,000 FCFA (Diagnostic Essentiel)

---

## Data Model

### New Tables

#### `profiles` (7 records, seeded + admin-editable)
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| name | string | e.g., "Coordinateur Stratégique" |
| slug | string | unique, for scoring keys |
| description | text | |
| key_skills | jsonb | array of skill strings |
| first_action | text | "Première action concrète" for PDF |
| premium_pitch | text | Roadmap Premium upsell text for PDF |

**7 profiles:**
1. Coordinateur Stratégique — Pilotage et gestion de projets multi-acteurs
2. Analyste & Veille — Analyse stratégique, études, recherche appliquée
3. Communication & Influence — Narration, plaidoyer, communication institutionnelle
4. Développement Territorial — Climat, urbanisation, aménagement local
5. Impact Social & Communautaire — Inclusion, programmes sociaux, mobilisation
6. Digital & Stratégie Contenu — Stratégie éditoriale, e-learning, communication numérique
7. Data & Transformation — Analyse de données sociales, suivi-évaluation digitalisé

#### `trajectories` (up to 3 per profile, admin-editable)
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| profile_id | uuid | FK → profiles |
| axe_1 | text | Institutionnel / ONG |
| axe_2 | text | Secteur privé / hybride |
| axe_3 | text | Spécialisation long terme |
| active | boolean | Only one active trajectory used per profile |

#### `questions` (25 records, seeded + admin-editable)
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| bloc | integer | 1–5 |
| text | text | Question text |
| kind | string | enum: `likert` \| `mcq` |
| scored | boolean | true for blocs 1–3 (15 questions) |
| options | jsonb | `[{label, value, profile_slug, points}]` |
| position | integer | Order within bloc |
| active | boolean | |

**5 blocs:**
- Bloc 1: Orientation naturelle (5 questions, scored)
- Bloc 2: Projection 5–10 ans (5 questions, scored — tie-break priority)
- Bloc 3: Relation au digital (5 questions, scored)
- Bloc 4: Situation actuelle (5 questions, interpretation only)
- Bloc 5: Ambition & mobilité (5 questions, interpretation only)

#### `diagnostics`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| user_id | uuid | FK → users |
| status | string | enum: `pending_payment \| paid \| in_progress \| completed` |
| payment_provider | string | enum: `stripe \| pawapay` |
| primary_profile_id | uuid | FK → profiles (set after scoring) |
| complementary_profile_id | uuid | FK → profiles (set after scoring) |
| score_data | jsonb | `{"coordinateur_strategique": 4, "analyste_veille": 3, ...}` |
| pdf_generated | boolean | default: false |
| paid_at | datetime | |
| completed_at | datetime | |

#### `diagnostic_answers`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| diagnostic_id | uuid | FK → diagnostics |
| question_id | uuid | FK → questions |
| answer_value | string | The option value selected |
| profile_dimension | string | Denormalized profile slug for scoring |
| points_awarded | integer | 1 if scored question, 0 if interpretation bloc |

#### `payments`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| user_id | uuid | FK → users |
| diagnostic_id | uuid | FK → diagnostics |
| provider | string | enum: `stripe \| pawapay` |
| amount_cents | integer | 300000 (3000 FCFA in centimes) |
| currency | string | `XOF` |
| status | string | enum: `pending \| confirmed \| failed` |
| provider_payment_id | string | Stripe session ID or Pawapay payment ID |
| webhook_confirmed_at | datetime | |

#### `mobile_operators` (seeded per country, admin-editable)
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| name | string | e.g., "Orange Money" |
| code | string | Pawapay operator code |
| country_code | string | ISO 3166-1 alpha-2 (CI, SN, CM…) |
| logo_url | string | |
| active | boolean | |

---

## User Flow

### Pre-requisite
User must be logged in to initiate payment. If not authenticated, redirect to `/login` with return path.

### Payment — Stripe (card)
```
1. User clicks "Payer par carte" on /diagnostics/new
2. Rails creates: Payment (pending), Diagnostic (pending_payment)
3. Rails creates Stripe Checkout Session
4. User redirected to Stripe hosted checkout
5. User completes card payment
6. Stripe sends POST /webhooks/stripe (checkout.session.completed)
   → Verify signature → Payment confirmed → Diagnostic = paid
7. Stripe redirects user to /diagnostics/:id/questionnaire
```

### Payment — Pawapay (mobile money)
```
1. User clicks "Payer par mobile money" on /diagnostics/new
2. Step 1 form:
   - Country selector (pre-filled from locale cookie)
   - Changing country reloads operator list (Turbo/Stimulus)
   - Phone number field
   - Operator dropdown (filtered by country from mobile_operators table)
3. Submit → Rails creates Payment (pending) + Diagnostic (pending_payment)
4. Rails calls Pawapay API to initiate deposit
5. Step 2: "Vérifiez votre téléphone" waiting screen
   - Turbo polls GET /payments/:id/status every 5 seconds
6. User accepts payment push on phone
7. Pawapay sends POST /webhooks/pawapay (deposit.completed)
   → Verify signature → Payment confirmed → Diagnostic = paid
8. Poll detects paid status → redirect to /diagnostics/:id/questionnaire
9. Email confirmation sent
```

Both webhook handlers are idempotent (duplicate webhooks ignored if already confirmed).

---

## Questionnaire

**Route:** `GET /diagnostics/:id/questionnaire`
**Guard:** `before_action` checks `diagnostic.paid?` — unauthorized if not paid.

**UX:**
- 5 blocs displayed sequentially (one bloc per screen)
- Progress bar: "Bloc 1 sur 5"
- Each bloc submitted via Turbo — answers saved to `diagnostic_answers`
- Forward-only navigation (no back)
- Partial saves per bloc (browser close = progress preserved)
- Likert questions: 5-point radio scale (Pas du tout → Tout à fait)
- MCQ questions: labeled radio buttons (A–G with text labels)

**On final bloc submission:**
1. `Diagnostics::ScoringService.call(diagnostic)` runs synchronously
2. Service counts points per profile dimension from scored questions (blocs 1–3)
3. `primary_profile` = dimension with max points
4. `complementary_profile` = second highest
5. Tie-break: Bloc 2 answers take priority
6. Diagnostic status → `completed`, profiles stored
7. Redirect to `/diagnostics/:id/results`

---

## PDF Generation

### Stripe users (synchronous)
```
Results page loads → Diagnostics::GeneratePdfService.call(diagnostic)
  → Prawn builds PDF in memory
  → Stored via Active Storage
  → PDF download button shown immediately
```

### Pawapay users (asynchronous)
```
Results page loads → Diagnostics::GeneratePdfJob.perform_later(diagnostic.id)
  → Page shows "Votre rapport est en cours de génération…"
  → Turbo polls GET /diagnostics/:id/pdf_status every 5s
  → Sidekiq job calls GeneratePdfService → stores in Active Storage → sets pdf_generated = true
  → Poll detects ready → page updates with download button
  → Email sent with PDF attachment
```

### PDF content (6 sections, via Prawn)
1. Header: user name, date, app branding
2. Profil principal: profile name, description, score
3. Profil complémentaire: name, score
4. 3 Axes stratégiques: axe_1, axe_2, axe_3 from `trajectories.where(profile: primary, active: true)`
5. Compétences clés à développer: from `primary_profile.key_skills`
6. Première action concrète + Proposition Roadmap Premium upsell

---

## Controllers & Routes

```ruby
# New routes
resources :diagnostics, only: [:new, :create, :show] do
  member do
    get  :questionnaire
    post :submit_bloc
    get  :results
    get  :pdf_status
    get  :download_pdf
  end
end

resources :payments, only: [] do
  member do
    get :status   # Turbo polling endpoint
  end
end

# Webhooks
post '/webhooks/stripe',  to: 'webhooks/stripe#receive'
post '/webhooks/pawapay', to: 'webhooks/pawapay#receive'

# Admin
namespace :admin do
  resources :diagnostics, only: [:index, :show]
  resources :profiles
  resources :trajectories
  resources :questions
  resources :mobile_operators
end
```

---

## Services

| Service | Responsibility |
|---------|---------------|
| `Diagnostics::ScoringService` | Calculate scores, set primary/complementary profile, handle tie-break |
| `Diagnostics::GeneratePdfService` | Build Prawn PDF with all 6 sections |
| `Payments::StripeCheckoutService` | Create Stripe Checkout Session |
| `Payments::PawapayDepositService` | Initiate Pawapay deposit via REST API |
| `Webhooks::StripeHandlerService` | Verify Stripe signature, update payment/diagnostic |
| `Webhooks::PawapayHandlerService` | Verify Pawapay signature, update payment/diagnostic |

---

## Gems to Add

```ruby
gem 'stripe'          # Stripe card payments
gem 'prawn'           # PDF generation
gem 'prawn-table'     # Tables in Prawn PDFs
# Pawapay: REST API calls via standard Net::HTTP or Faraday (already available via Rails)
```

---

## Authorization (Pundit)

- `DiagnosticPolicy`: user can only view/access their own diagnostics
- `Admin::DiagnosticPolicy`: admin can view all
- `Admin::ProfilePolicy` / `Admin::TrajectoryPolicy` / `Admin::QuestionPolicy`: admin only

---

## Deployment Notes

- App runs on **Railway**
- Webhook URLs must be configured in Stripe Dashboard and Pawapay Dashboard with the Railway public URL
- Active Storage: configure for file storage (Railway ephemeral disk → use S3/R2 or Railway volume)
- Sidekiq requires Redis (add Redis service in Railway)
