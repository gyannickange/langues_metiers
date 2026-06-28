# PaperTrail (17.0.0) does not ship `chronological`/`reverse_chronological`
# scopes on PaperTrail::Version. Several admin views (version history
# partials) rely on `versions.reverse_chronological` to list the most recent
# changes first, so we add the scopes here using the gem's own
# `timestamp_sort_order` helper to stay consistent with its sort semantics.
ActiveSupport.on_load(:active_record) do
  PaperTrail::Version.class_eval do
    scope :chronological, -> { order(timestamp_sort_order("asc")) }
    scope :reverse_chronological, -> { order(timestamp_sort_order("desc")) }
  end
end
