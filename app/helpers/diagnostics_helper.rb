# app/helpers/diagnostics_helper.rb
module DiagnosticsHelper
  BLOC_TITLES = {
    1 => "Orientation naturelle",
    2 => "Projection 5–10 ans",
    3 => "Relation au digital",
    4 => "Situation actuelle",
    5 => "Ambition & mobilité"
  }.freeze

  def bloc_title(n)
    "Bloc #{n} : #{BLOC_TITLES[n]}"
  end
end
