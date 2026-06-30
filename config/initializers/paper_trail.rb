# Rails 8's default `yaml_column_permitted_classes` (just `Symbol`) is too
# narrow for PaperTrail's `object_changes` column: every update touches
# `updated_at`, whose changeset value is an `ActiveSupport::TimeWithZone`.
# Without this, `YAML.safe_load` raises `Psych::DisallowedClass`, which
# PaperTrail rescues silently, leaving `version.changeset` empty for every
# update. Add the classes PaperTrail's YAML serializer needs to decode.
ActiveSupport.on_load(:active_record) do
  ActiveRecord.yaml_column_permitted_classes |= [
    ActiveSupport::TimeWithZone,
    ActiveSupport::TimeZone,
    Time,
    Date,
    BigDecimal
  ]
end

# PaperTrail (17.0.0) does not ship `chronological`/`reverse_chronological`
# scopes on PaperTrail::Version. Several admin views (version history
# partials) rely on `versions.reverse_chronological` to list the most recent
# changes first, so we add the scopes here using the gem's own
# `timestamp_sort_order` helper to stay consistent with its sort semantics.
ActiveSupport.on_load(:active_record) do
  PaperTrail::Version.class_eval do
    scope :chronological, -> { reorder(timestamp_sort_order("asc")) }
    scope :reverse_chronological, -> { reorder(timestamp_sort_order("desc")) }
  end
end
