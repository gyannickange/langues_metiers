# Admin manageability for the new diagnostic architecture

**Date:** 2026-06-18
**Branch:** feature/nouveau-diagnostic

## Problem

The new diagnostic architecture added fields that drive scoring, but the admin
dashboard's forms and strong-params were never migrated to expose them. Every
model has CRUD scaffolding, yet the fields that actually power the diagnostic
can only be set via `db/seeds.rb`. Concretely:

1. **Career / métiers** — `filiere_slug`, `disc_types`, `required_competences`,
   `affirmations` are neither in `career_params` nor in the form
   (`app/controllers/admin/careers_controller.rb`,
   `app/views/admin/careers/_form.html.erb`). The whole scoring input for the
   37 métiers is uneditable in the UI.
2. **DiagnosticQuestion / interest** — the model requires `filiere_slug` for
   `kind == "interest"`, but `question_params` does not permit it, so creating
   or editing an interest question through the dashboard always fails
   validation. The form's `options_json` instructions are stale (they describe
   the pre-migration architecture where `filiere_slug` lived inside `options`).
3. **DiagnosticQuestion Stimulus** — `assessment_question_form_controller.js`
   toggles on `kind === "mcq"`, a kind that no longer exists, and is not wired
   into any view. Dead leftover from the old assessment/MCQ model.
4. **Career / behavioral profiles** — `key_skills`, `first_action`,
   `premium_pitch` are permitted but absent from the form, so they are
   UI-uneditable.
5. **Trajectory** — the new/edit dropdown lists only `Career.behavioral`, so
   trajectories for the 37 profession careers cannot be managed in the UI even
   though seeds create them.

There is also no single source of truth for the vocabularies: the filière slug
list lives only in `test/integration/questionnaire_seed_test.rb`, the competence
slug list is hardcoded in the question form, and the human-readable labels live
only in `db/seeds.rb`.

## Goal

Make every part of the new diagnostic architecture fully manageable from the
admin dashboard, with a single source of truth for the shared vocabularies so
the lists stop drifting.

## Non-goals

- No schema/migration changes — all required columns already exist.
- No redesign of the diagnostic flow, scoring, or public-facing views.
- No unrelated refactoring of admin areas outside careers / questions /
  trajectories.

## Design

### 1. Shared vocabulary (single source of truth)

New file `app/models/diagnostics/vocabulary.rb` exposing slug→label maps:

- `FILIERES`:
  - `langues` → "Langues"
  - `geo` → "Géographie & territoires"
  - `socio` → "Sociologie"
  - `lettres` → "Lettres"
  - `psycho` → "Psychologie"
  - `philo` → "Philosophie"
  - `histoire` → "Histoire"
  - `edu` → "Sciences de l'éducation"
- `COMPETENCES` — the 12 slug→label pairs currently in the
  `competence_questions` array of `db/seeds.rb`:
  - `langues_etrangeres` → "Langues étrangères"
  - `communication_ecrite` → "Communication écrite"
  - `communication_orale` → "Communication orale"
  - `analyse_donnees` → "Analyse de données"
  - `gestion_projet` → "Gestion de projet"
  - `numerique` → "Compétences numériques"
  - `negociation` → "Négociation"
  - `creativite` → "Créativité"
  - `ecoute` → "Écoute active"
  - `rigueur_scientifique` → "Rigueur et méthode"
  - `culture_generale` → "Culture générale"
  - `droit_politiques` → "Droit et politiques publiques"
- `DISC_TYPES`:
  - `D` → "Dominant", `I` → "Influent", `S` → "Stable", `C` → "Consciencieux"

Helper readers for `*_slugs` / `*_options` (the `[label, slug]` pairs Rails
`select`/`collection_check_boxes` expect).

Repoint existing duplicated lists at this module:
- the hardcoded competence array in `app/views/admin/diagnostic_questions/_form.html.erb`
- `FILIERE_SLUGS` in `test/integration/questionnaire_seed_test.rb`

The French labels are all in this one file and can be corrected later without
touching forms.

### 2. Career — métier diagnostic fields

- **Model (`app/models/career.rb`):**
  - virtual `affirmations_text` accessor — getter joins `affirmations` with
    newlines, setter splits on newlines and strips blanks — mirroring the
    existing `options_json` pattern on `DiagnosticQuestion`.
  - validations (profession kind): `disc_types` ⊆ `DISC_TYPES` keys,
    `required_competences` ⊆ `COMPETENCES` keys, `filiere_slug` ∈ `FILIERES`
    keys. `filiere_slug` validation `allow_nil` so behavioral profiles are
    unaffected.
- **Controller (`app/controllers/admin/careers_controller.rb`):** permit
  `:filiere_slug`, `:affirmations_text`, `disc_types: []`,
  `required_competences: []` (in addition to the existing permitted attrs).
- **Form (`_form.html.erb`):** when `kind == "profession"`, show:
  - filière `select` from `FILIERES`
  - DISC `collection_check_boxes` (4) from `DISC_TYPES`
  - required-competence `collection_check_boxes` (12) from `COMPETENCES`
  - affirmations `text_area` bound to `affirmations_text` (one per line)

### 3. Career — behavioral profile fields

When `kind == "behavioral"`, the form also shows `first_action` (text_area),
`premium_pitch` (text_area), and `key_skills` via a `key_skills_text` virtual
accessor (same newline join/split pattern). `career_params` already permits
`first_action`, `premium_pitch`, `key_skills: []`; add `:key_skills_text`.

A `kind` selector drives which block is shown; default for new records follows
the model default (`behavioral`). Conditional display via the rewritten
Stimulus controller in §4 (or server-rendered both blocks with a small toggle —
implementation detail for the plan).

### 4. DiagnosticQuestion form fix

- **Controller (`app/controllers/admin/diagnostic_questions_controller.rb`):**
  add `:filiere_slug` and `:competence_label` to `question_params` (drop the
  now-unused `:options_json`, since the form no longer submits raw JSON).
- **Form (`_form.html.erb`):**
  - add a `filiere_slug` `select` from `FILIERES` (shown for `interest`).
  - replace the raw `options_json` textarea + stale instructions with a
    "Label affiché" text field used by competence questions; on submit it
    persists as `options = [{ "label" => value }]`. (A `competence_label`
    virtual accessor on the model reads `options.dig(0, "label")` and writes the
    `options` array.)
  - competence `select` repointed at `Vocabulary::COMPETENCES`.
- **Stimulus (`assessment_question_form_controller.js`):** rewrite to toggle the
  per-kind fields by the real kinds — `disc` → disc_type, `interest` →
  filiere_slug, `competence` → competence_slug + label — and wire
  `data-controller` / targets into the form.

### 5. Trajectory

`app/controllers/admin/trajectories_controller.rb` `new`/`edit`/error branches:
replace `Career.behavioral` with all careers, ordered and grouped for the
`select` ("Profils" vs "Métiers", e.g. via `grouped_collection_select` or two
`optgroup`s keyed on `kind`). No change to `trajectory_params`.

## Data flow

Admin edits a métier → structured form posts `disc_types[]`,
`required_competences[]`, `filiere_slug`, `affirmations_text` → controller
permits them → model validates each array against `Vocabulary` and splits
`affirmations_text` into the `affirmations` jsonb column → the existing
`Diagnostics::PreScoringService` (filière/DISC/competence matching) and
`ScoringService` (affirmation bonus) read these columns unchanged.

## Error handling

- Out-of-vocabulary slugs are rejected by model validations with French
  messages surfaced in the existing form error block.
- Interest question without `filiere_slug` still fails validation, but the field
  is now present in the form so the admin can satisfy it.
- Blank lines in the affirmations / key_skills textareas are stripped, not
  stored as empty strings.

## Testing (TDD — tests written first)

- **Vocabulary model spec:** maps are non-empty; helper option arrays have the
  expected shape; slug sets match what seeds use.
- **Career model spec:** `affirmations_text` / `key_skills_text` round-trip
  (join on read, split + strip on write); validations reject out-of-vocab
  `disc_types` / `required_competences` / `filiere_slug`; behavioral profiles
  pass with `filiere_slug` nil.
- **Admin::CareersController request spec:** updating a profession career
  persists all four diagnostic fields; invalid vocab re-renders with errors;
  behavioral fields persist.
- **Admin::DiagnosticQuestionsController request spec:** an interest question is
  creatable end-to-end with `filiere_slug`; a competence question persists its
  label into `options`.
- **Admin::TrajectoriesController request spec:** a trajectory can be created for
  a profession career.

## Files touched

- `app/models/diagnostics/vocabulary.rb` (new)
- `app/models/career.rb`
- `app/controllers/admin/careers_controller.rb`
- `app/views/admin/careers/_form.html.erb`
- `app/controllers/admin/diagnostic_questions_controller.rb`
- `app/views/admin/diagnostic_questions/_form.html.erb`
- `app/javascript/controllers/assessment_question_form_controller.js`
- `app/controllers/admin/trajectories_controller.rb`
- `db/seeds.rb` (repoint competence labels at Vocabulary)
- `test/integration/questionnaire_seed_test.rb` (repoint FILIERE_SLUGS)
- new tests under `test/controllers/admin/` and `test/models/`
