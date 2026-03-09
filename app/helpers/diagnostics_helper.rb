# app/helpers/diagnostics_helper.rb
module DiagnosticsHelper
  BLOC_TITLES = {
    1 => "Identité Professionnelle",
    2 => "Relation au Marché",
    3 => "Dimension Digitale",
    4 => "Potentiel Stratégique",
    5 => "Clarté & Action"
  }.freeze

  BLOC_LABELS = {
    1 => "IDENTITÉ",
    2 => "MARCHÉ",
    3 => "DIGITAL",
    4 => "STRATÉGIE",
    5 => "CLARTÉ"
  }.freeze

  def bloc_title(n)
    "Bloc #{n} — #{BLOC_TITLES[n]}"
  end

  def bloc_label(n)
    BLOC_LABELS[n]
  end
end
