# Nouveau Diagnostic — Design Spec
**Date:** 2026-06-09  
**Statut:** Approuvé

---

## Contexte

L'application Langues & Métiers propose un diagnostic payant (2 000 F CFA) pour aider des étudiants en sciences humaines à identifier leurs métiers cibles. Le système actuel mappe 25 questions en blocs vers 7 profils comportementaux génériques (coordinateur-stratégique, analyste-veille, etc.).

Ce spec décrit le remplacement complet de ce système par un diagnostic plus riche et plus personnalisé, inspiré d'un prototype HTML (questionnaire_orientation_metiers2.html), qui utilise le modèle DISC, des questions d'intérêt thématique et une auto-évaluation des compétences pour recommander parmi 37 métiers spécifiques.

---

## Objectif

Un étudiant qui ne sait pas ce qu'il veut faire répond à une série de questions sur ce qui l'anime et ce qu'il sait faire. Le système déduit en interne son profil DISC, sa filière naturelle et ses compétences fortes, puis recommande 2 métiers précis avec une trajectoire en 3 axes.

L'utilisateur ne voit jamais les labels DISC, les filières ou les scores — il vit une expérience de découverte, pas un test académique.

---

## Flux utilisateur

```
Étape 1 : Questions d'intérêt thématique (6–8 questions)
    ↓ choix multiples, chaque réponse vote pour une filière en interne
Étape 2 : Affirmations DISC (16 questions, Likert 1–5)
    ↓ 4 questions × 4 types (D/I/S/C), répond "pas du tout moi" → "tout à fait moi"
Étape 3 : Auto-évaluation des compétences (12 questions, Likert 1–5)
    ↓ 1 question par compétence
[Scoring interne — invisible pour l'utilisateur]
Étape 4 : Validation par affirmations (top 3 métiers × 5 affirmations)
    ↓ l'utilisateur coche/décoche, score final ajusté
Étape 5 : Paiement (2 000 F CFA — Stripe ou PawaPay)
    ↓
Étape 6 : Résultats (métier principal + complémentaire + trajectoire + PDF)
```

---

## Données de référence (hardcodées en seeds, admin-éditables)

Les données suivantes viennent du prototype HTML et sont seeded puis gérables via l'admin :

- **8 filières** : langues, géo, socio, lettres, psycho, philo, histoire, edu
- **37 métiers** (Career), chacun avec : disc_types (ex: ["C","S"]), filiere_slug, required_competences (ex: ["langues_etrangeres","communication_ecrite"]) et 5 affirmations de validation
- **12 compétences** : langues_etrangeres, communication_ecrite, communication_orale, analyse_donnees, gestion_projet, numerique, negociation, creativite, ecoute, rigueur_scientifique, culture_generale, droit_politiques
- **Questions** : 8 interest + 16 DISC + 12 compétences = 36 questions au total

---

## Modèle de données

### Nouveau : `diagnostic_questions`

Remplace `assessment_questions`.

| Colonne | Type | Notes |
|---|---|---|
| id | uuid | PK |
| assessment_id | uuid | FK → assessments |
| kind | enum | `disc` / `interest` / `competence` |
| text | string | L'affirmation ou question affichée |
| disc_type | string | D / I / S / C (disc uniquement) |
| filiere_slug | string | ex: "langues" (interest uniquement) |
| competence_slug | string | ex: "langues_etrangeres" (competence uniquement) |
| position | integer | Ordre d'affichage dans son étape |
| active | boolean | default: true |
| created_at / updated_at | datetime | |

### Modifications : `careers`

Colonnes ajoutées :

| Colonne | Type | Notes |
|---|---|---|
| disc_types | jsonb | ex: `["C", "S"]` — top 2 types DISC compatibles |
| filiere_slug | string | ex: `"langues"` — filière principale du métier |
| required_competences | jsonb | ex: `["langues_etrangeres", "communication_ecrite"]` |
| affirmations | jsonb | 5 phrases de validation, ex: `["Je suis passionné(e) par…", …]` |

Le `kind` enum (behavioral/profession) est supprimé — tous les métiers sont du même type dans le nouveau modèle.

### Modifications : `diagnostic_answers`

| Colonne | Changement |
|---|---|
| assessment_question_id | Renommé en `diagnostic_question_id` (FK → diagnostic_questions) |
| dimension_slug | Nouveau — stocke disc_type / filiere_slug / competence_slug selon le kind |
| points_awarded | Conservé — stocke la valeur Likert (1–5) ou le nombre de votes |

### `diagnostics` — inchangé structurellement

`score_data` (JSONB) stockera désormais :
```json
{
  "disc_scores": { "D": 14, "I": 11, "S": 8, "C": 18 },
  "filiere_scores": { "langues": 3, "lettres": 2 },
  "competence_scores": { "langues_etrangeres": 5, "communication_ecrite": 4 },
  "top_careers": [{ "id": "uuid", "score": 87 }, ...]
}
```

### Conservé intact

`assessments`, `payments`, `trajectories`, `users`, `mobile_operators`, ActiveStorage (PDF), DiagnosticReminderJob, DiagnosticMailer, Stripe/PawaPay services.

---

## Algorithme de scoring (`Diagnostics::ScoringService`)

1. **Filière dominante** : compter les votes par filiere_slug dans les réponses interest → filière avec le plus de votes gagne. En cas d'égalité : prendre la première par ordre alphabétique.

2. **Profil DISC** : sommer les points_awarded par disc_type (max 20 par type). Les 2 types avec les scores les plus hauts forment le profil dominant.

3. **Scores de compétences** : la valeur Likert (1–5) de chaque réponse competence est le score direct de la compétence.

4. **Score de chaque Career** :
   - DISC match : +3 par type DISC du métier présent dans le profil dominant (max +6)
   - Filière match : +5 si `career.filiere_slug == filière_dominante`
   - Compétence match : somme des scores utilisateur pour chaque compétence dans `career.required_competences`

5. **Top 3 carrières** sélectionnées pour l'étape de validation.

6. **Ajustement par affirmations** : +1 par affirmation cochée par l'utilisateur sur chaque métier. Le classement final détermine le métier principal (1er) et complémentaire (2ème).

---

## Routes & Controller

```ruby
resources :diagnostics, only: [:show] do
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

La logique de redirection dans `show` est mise à jour pour couvrir les nouveaux statuts d'étape (stockés dans `diagnostics.status` ou via la présence de réponses).

---

## Interface admin

L'admin (via la gem activeadmin ou les vues admin existantes) aura une interface pour :

- Lister/filtrer les `DiagnosticQuestion` par kind (onglets : Toutes / Interest / DISC / Compétence)
- Créer/modifier/supprimer des questions (formulaire dynamique selon le kind : disc_type affiché si kind=disc, filiere_slug si kind=interest, etc.)
- Modifier les métiers (Career) : disc_types, filiere_slug, required_competences, affirmations

---

## Migration

### Supprimé
- Table `assessment_questions` (remplacée par `diagnostic_questions`)
- Colonne `kind` sur `careers` (behavioral/profession — plus pertinent) et les scopes `Career.behavioral` / `Career.profession` qui en dépendent (les appels dans seeds.rb et ScoringService doivent être mis à jour)

### Créé
- Table `diagnostic_questions` avec toutes ses colonnes
- Colonnes sur `careers` : `disc_types`, `filiere_slug`, `required_competences`, `affirmations`
- Colonne `dimension_slug` sur `diagnostic_answers`
- FK `diagnostic_question_id` sur `diagnostic_answers` (remplace `assessment_question_id`)

### Seeds mis à jour
- 8 questions d'intérêt thématique (filière-discovery)
- 16 affirmations DISC (depuis le prototype HTML)
- 12 questions de compétences (depuis le prototype HTML)
- 37 carrières avec disc_types, filiere_slug, required_competences, affirmations (depuis le prototype HTML)

### Conservé
Toutes les autres tables, services, jobs et vues sont conservés sans modification structurelle.

---

## Hors périmètre

- Modification du flow de paiement (Stripe/PawaPay inchangé)
- Modification du format PDF
- Nouveau design de la page de résultats (contenu enrichi possible en V2)
- Internationalisation
