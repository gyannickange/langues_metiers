module Diagnostics
  module Vocabulary
    DISC_TYPES = {
      "D" => "Dominant",
      "I" => "Influent",
      "S" => "Stable",
      "C" => "Consciencieux"
    }.freeze

    module_function

    def academic_field_slugs    = AcademicField.order(:position).pluck(:slug)
    def skill_slugs = Skill.order(:position).pluck(:slug)
    def disc_type_slugs  = DISC_TYPES.keys

    # [label, slug] pairs, ready for Rails select / collection helpers.
    def academic_field_options    = AcademicField.order(:position).pluck(:name, :slug)
    def skill_options = Skill.order(:position).pluck(:name, :slug)
    def disc_type_options  = DISC_TYPES.map { |slug, label| [ label, slug ] }
  end
end
