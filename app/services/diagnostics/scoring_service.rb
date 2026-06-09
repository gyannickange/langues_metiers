# app/services/diagnostics/scoring_service.rb
module Diagnostics
  class ScoringService
    def self.call(diagnostic, affirmation_counts = {})
      new(diagnostic, affirmation_counts).call
    end

    def initialize(diagnostic, affirmation_counts)
      @diagnostic         = diagnostic
      @affirmation_counts = affirmation_counts
    end

    def call
      top_career_data = @diagnostic.score_data["top_career_ids"] || []
      top_career_ids  = top_career_data.map { |e| e["id"] }
      careers_by_id   = Career.where(id: top_career_ids).index_by { |c| c.id.to_s }

      adjusted = top_career_data.map do |entry|
        id_str    = entry["id"].to_s
        career    = careers_by_id[id_str]
        max_bonus = (career&.affirmations || []).length
        raw_bonus = Array(@affirmation_counts[id_str]).length
        bonus     = [raw_bonus, max_bonus].min
        { "id" => entry["id"], "score" => entry["score"].to_i + bonus }
      end.sort_by { |e| -e["score"] }

      primary   = careers_by_id[adjusted.dig(0, "id").to_s]
      secondary = careers_by_id[adjusted.dig(1, "id").to_s]

      @diagnostic.update!(
        primary_career:       primary,
        complementary_career: secondary,
        status:               :pending_payment,
        completed_at:         Time.current
      )
    end
  end
end
