module Diagnostics
  class PreScoringService
    class InsufficientCareersError < StandardError; end

    RETAINED_CAREERS_COUNT = 2

    def self.call(diagnostic)
      new(diagnostic).call
    end

    def initialize(diagnostic)
      @diagnostic = diagnostic
    end

    def call
      academic_field_scores = dimension_scores(kind: "interest")
      disc_scores           = dimension_scores(kind: "disc")

      dominant_academic_fields = top_dimensions(academic_field_scores)
      dominant_disc_types      = top_dimensions(disc_scores)

      pool_a = Career.diagnostic.published.where(academic_field_slug: dominant_academic_fields).to_a
      raise InsufficientCareersError, "Not enough careers for the dominant academic fields" if pool_a.size < RETAINED_CAREERS_COUNT

      @diagnostic.update!(
        score_data: {
          "academic_field_scores"    => academic_field_scores,
          "disc_scores"              => disc_scores,
          "dominant_academic_fields" => dominant_academic_fields,
          "dominant_disc_types"      => dominant_disc_types,
          "retained_careers"         => retained_careers(pool_a, dominant_disc_types, academic_field_scores)
        }
      )
    end

    private

    def dimension_scores(kind:)
      grouped = Hash.new { |h, k| h[k] = [] }

      @diagnostic.diagnostic_answers.includes(:diagnostic_question).each do |answer|
        question = answer.diagnostic_question
        next unless question && question.kind == kind

        dimension = kind == "disc" ? question.disc_type : question.academic_field_slug
        next unless dimension

        value = answer.effective_value || Diagnostics::LikertScoring.effective_value(answer.points_awarded, reverse_scored: question.reverse_scored?)
        grouped[dimension] << value
      end

      grouped.transform_values do |values|
        Diagnostics::LikertScoring.normalize(Diagnostics::LikertScoring.average(values)).round(2)
      end
    end

    def top_dimensions(scores)
      # Secondary sort key (dimension name) makes the top-2 cutoff deterministic on ties —
      # Array#sort_by isn't guaranteed stable, and a tie here changes which fields/types
      # actually govern the rest of the pipeline, not just their display order.
      scores.sort_by { |dimension, score| [ -score, dimension ] }.first(RETAINED_CAREERS_COUNT).map(&:first)
    end

    def retained_careers(pool_a, dominant_disc_types, academic_field_scores)
      scored_pool_a = pool_a.map do |career|
        matched = career.disc_types & dominant_disc_types
        {
          career:                career,
          matched_disc_types:    matched,
          disc_match_count:      matched.size,
          academic_field_score:  academic_field_scores[career.academic_field_slug].to_f
        }
      end

      pool_b = scored_pool_a.select { |entry| entry[:disc_match_count].positive? }

      fallback_ids = []
      if pool_b.size < RETAINED_CAREERS_COUNT
        already_in_b = pool_b.map { |entry| entry[:career].id }
        ranked_a     = scored_pool_a.sort_by { |entry| ranking_key(entry) }
        additions    = ranked_a.reject { |entry| already_in_b.include?(entry[:career].id) }.first(RETAINED_CAREERS_COUNT - pool_b.size)
        fallback_ids = additions.map { |entry| entry[:career].id }
        pool_b      += additions
      end

      pool_b
        .sort_by { |entry| ranking_key(entry) }
        .first(RETAINED_CAREERS_COUNT)
        .map do |entry|
          {
            "career_id"            => entry[:career].id,
            "academic_field_slug"  => entry[:career].academic_field_slug,
            "academic_field_score" => entry[:academic_field_score],
            "matched_disc_types"   => entry[:matched_disc_types],
            "disc_match_count"     => entry[:disc_match_count],
            "fallback"             => fallback_ids.include?(entry[:career].id)
          }
        end
    end

    # Deterministic tiebreak: career_id as the final sort key ensures a tie on
    # disc_match_count/academic_field_score doesn't depend on unordered DB row order.
    def ranking_key(entry)
      [ -entry[:disc_match_count], -entry[:academic_field_score], entry[:career].id.to_s ]
    end
  end
end
