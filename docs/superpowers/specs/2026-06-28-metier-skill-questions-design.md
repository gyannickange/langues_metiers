# Questions de diagnostic par métier

## Objectif

Enrichir le questionnaire existant avec les 37 métiers et leurs 185 affirmations, sans supprimer les 12 compétences et questions actuellement utilisées.

## Source des données

Chaque entrée de `careers_data` reçoit un `skill_slug` correspondant à la clé de `METIER_AFFIRMATIONS`, par exemple `traducteur`. Le titre du métier devient le nom de la compétence et le tableau `affirmations` fournit ses cinq questions.

Cette structure garde une source unique pour les titres et les affirmations. Les champs propres au seed des métiers restent explicitement sélectionnés lors de l'enregistrement d'un `Career`.

## Compétences

Le seed conserve les 12 compétences existantes aux positions 1 à 12. Il crée ou met à jour 37 compétences métier aux positions 13 à 49 :

- `slug` : clé de `METIER_AFFIRMATIONS` ;
- `name` : titre correspondant dans `careers_data` ;
- `position` : ordre du métier dans `careers_data`, décalé de 12.

La recherche par slug garantit l'idempotence et met à jour le nom ou la position lors d'une nouvelle exécution.

## Questions

Le seed conserve les 12 questions de compétence existantes. Pour chaque métier, il crée cinq questions supplémentaires :

- `kind` : `skill` ;
- `skill_slug` : slug métier ;
- `text` : affirmation du métier ;
- `options` : tableau contenant le titre du métier comme `label` ;
- `active` : `true` ;
- `position` : séquence continue après les 12 questions existantes.

Le seed continue de supprimer, pour cette évaluation, les questions absentes de la source déclarative. Le résultat attendu est donc de 197 questions de type `skill`, dont 185 questions métier.

## Vérification

Le test d'intégration du seed vérifie :

- 49 compétences au total ;
- 197 questions actives de type `skill` ;
- 37 slugs métier distincts ;
- exactement cinq questions par slug métier ;
- la correspondance entre un métier représentatif, son titre et ses affirmations ;
- la conservation des 12 questions historiques.

Le test est modifié avant le seed et doit échouer sur les anciens totaux, puis réussir après l'implémentation.
