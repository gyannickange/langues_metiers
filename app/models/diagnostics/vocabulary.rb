module Diagnostics
  module Vocabulary
    DISC_TYPES = {
      "D" => "Dominant",
      "I" => "Influent",
      "S" => "Stable",
      "C" => "Consciencieux"
    }.freeze

    module_function

    def filiere_slugs    = Filiere.order(:position).pluck(:slug)
    def competence_slugs = Skill.order(:position).pluck(:slug)
    def disc_type_slugs  = DISC_TYPES.keys

    # [label, slug] pairs, ready for Rails select / collection helpers.
    def filiere_options    = Filiere.order(:position).pluck(:name, :slug)
    def competence_options = Skill.order(:position).pluck(:name, :slug)
    def disc_type_options  = DISC_TYPES.map { |slug, label| [ label, slug ] }
  end
end
