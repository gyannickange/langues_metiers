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
