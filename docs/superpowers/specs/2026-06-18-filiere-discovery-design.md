# Design — Découverte de filière par questionnaire Likert

**Date :** 2026-06-18
**Branche :** feature/nouveau-diagnostic

## Problème

L'étape "intérêt" du diagnostic demande actuellement à l'étudiant de sélectionner directement sa filière parmi 8 options (Langues, Géographie, Lettres, etc.). Un étudiant qui ne connaît pas encore son orientation ne peut pas répondre à cette question honnêtement.

## Solution

Remplacer la sélection directe par **16 affirmations Likert 1–5** (2 par filière × 8 filières), structurées exactement comme le DISC. Le système calcule la filière dominante à partir des scores cumulés — l'étudiant ne voit jamais les noms de filières pendant l'étape.

## Décisions clés

- **16 questions** (2 par filière × 8 filières), notées 1–5
- **Approche miroir du DISC** : même modèle de données, même logique de scoring
- **Aucun changement de route ni de flux** : `interest_start → create_from_interest → disc → competences → validation → results`
- **Questions configurables en admin** via les `DiagnosticQuestion` existants

---

## 1. Modèle de données

### Migration

```ruby
add_column :diagnostic_questions, :filiere_slug, :string
```

### `DiagnosticQuestion`

| kind | disc_type | filiere_slug | competence_slug | options |
|------|-----------|--------------|-----------------|---------|
| disc | D/I/S/C | nil | nil | [] |
| interest | nil | langues/geo/… | nil | [] |
| competence | nil | nil | langues_etrangeres/… | [] |

Validation `kind_specific_fields_present` pour `interest` : `filiere_slug` présent (plus `options` non vide).

### `DiagnosticAnswer`

Inchangée. `dimension_slug` stocke le slug de filière, `points_awarded` stocke la note 1–5.

---

## 2. Les 16 questions

| Filière | Position | Texte |
|---------|----------|-------|
| langues | 1 | Les langues étrangères et la richesse des cultures qu'elles véhiculent me passionnent. |
| langues | 2 | Lire ou traduire des textes dans une autre langue est une activité qui me captive. |
| geo | 3 | Les dynamiques des territoires, l'urbanisme et l'aménagement de l'espace m'intéressent profondément. |
| geo | 4 | Analyser des cartes, comprendre les flux migratoires ou les inégalités spatiales me fascine. |
| socio | 5 | Observer et comprendre les comportements humains au sein des sociétés est ce qui me motive. |
| socio | 6 | Les questions de diversité, d'identité culturelle et d'inégalités sociales m'animent. |
| lettres | 7 | Écrire, analyser des textes littéraires ou travailler la langue française est une vocation pour moi. |
| lettres | 8 | La narration, la critique littéraire et le travail sur le style m'enthousiasment. |
| psycho | 9 | Comprendre le fonctionnement de l'esprit humain, les émotions et les comportements me passionne. |
| psycho | 10 | Accompagner des personnes dans leur développement ou résoudre des problèmes psychologiques m'attire. |
| philo | 11 | Questionner les idées, débattre de concepts abstraits et construire des arguments rigoureux me plaît. |
| philo | 12 | Les grandes questions éthiques, politiques ou existentielles stimulent ma réflexion. |
| histoire | 13 | Comprendre les événements passés et leur impact sur le monde actuel me passionne. |
| histoire | 14 | Explorer les civilisations anciennes, les archives et le patrimoine culturel est ce qui m'anime. |
| edu | 15 | Former, transmettre des savoirs et accompagner l'apprentissage des autres est une vocation. |
| edu | 16 | Les mécanismes de l'apprentissage, la pédagogie et la conception de formations m'intéressent. |

---

## 3. Flux et contrôleur

Aucune route ne change. Les deux actions qui traitent les réponses intérêt évoluent identiquement.

### Validation (bloc `valid_answers_for`)

**Avant :**
```ruby
value if question.options.map { |o| o["filiere_slug"] }.include?(value)
```

**Après (identique à `submit_disc`) :**
```ruby
numeric_value = Integer(value, exception: false)
numeric_value if (1..5).include?(numeric_value)
```

### Sauvegarde des réponses (`submit_interest` et `create_from_interest`)

**Avant :**
```ruby
answer.assign_attributes(
  dimension_slug: filiere_slug,   # valeur saisie = slug filière
  answer_value:   filiere_slug,
  points_awarded: 1
)
```

**Après :**
```ruby
answer.assign_attributes(
  dimension_slug: question.filiere_slug,  # slug filière vient de la question
  answer_value:   value.to_s,             # note 1–5
  points_awarded: value                   # note 1–5 pour scoring
)
```

`create_from_interest` crée aussi le diagnostic et redirige vers DISC — comportement inchangé.

---

## 4. Scoring (`PreScoringService`)

```ruby
# Avant
when "interest"
  filiere_scores[answer.dimension_slug] += 1

# Après
when "interest"
  filiere_scores[answer.dimension_slug] += answer.points_awarded.to_i
```

`dominant_filiere = filiere_scores.max_by { |_, v| v }&.first` — inchangé.
Bonus filière (+5 pts dans `rank_careers`) — inchangé.

Score filière possible par filière : min 2, max 10.

---

## 5. Vues

- `interest_start.html.erb` et `interest.html.erb` : remplacer la grille de radio boutons par le partial `_likert_question` (déjà utilisé pour DISC et compétences).
- En-tête : "Étape 1 sur 4 — Vos affinités" (sans mention du mot "filière").
- L'étudiant ne voit jamais à quelle filière chaque affirmation correspond.

---

## 6. Seeds

Remplacer la question `interest` existante ("Votre filière" avec options) par les 16 nouvelles questions avec `filiere_slug`. Les positions 1–16 sont utilisées pour le kind `interest` — sans conflit avec les positions DISC (2–17) car les seeds cherchent par `(assessment, kind, position)` et le scope `ordered` filtre toujours par kind d'abord.

Le `assessment.diagnostic_questions.where.not(id: seeded_question_ids).destroy_all` existant en fin de seeds supprime automatiquement l'ancienne question de sélection directe.

Positions DISC (2–17) et compétences (18–29) : inchangées.

---

## Hors périmètre

- Questions DISC (16) : inchangées
- Questions compétences (12) : inchangées
- 37 métiers et leurs données : inchangés
- Scoring final (`ScoringService`) : inchangé
- Vues résultats, PDF : inchangés
