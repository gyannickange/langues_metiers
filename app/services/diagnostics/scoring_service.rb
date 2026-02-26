# app/services/diagnostics/scoring_service.rb
module Diagnostics
  class ScoringService
    def self.call(diagnostic)
      new(diagnostic).call
    end

    def initialize(diagnostic)
      @diagnostic = diagnostic
    end

    def call
      scores = calculate_scores
      primary, complementary = determine_profiles(scores)

      @diagnostic.update!(
        score_data:              scores,
        primary_profile:         primary,
        complementary_profile:   complementary,
        status:                  :completed,
        completed_at:            Time.current
      )
    end

    private

    def calculate_scores
      scored = @diagnostic.diagnostic_answers
        .joins(:question)
        .where(questions: { scored: true })
        .where.not(profile_dimension: [nil, ""])

      scores = Hash.new(0)
      scored.each { |a| scores[a.profile_dimension] += a.points_awarded.to_i }
      scores
    end

    def determine_profiles(scores)
      return [nil, nil] if scores.empty?

      sorted    = scores.sort_by { |_, v| -v }
      top_score = sorted.first[1]
      tied      = sorted.select { |_, v| v == top_score }.map(&:first)

      primary_slug = tied.size > 1 ? resolve_tiebreak(tied) : tied.first
      secondary_slug = sorted.find { |slug, _| slug != primary_slug }&.first

      [Profile.find_by(slug: primary_slug), Profile.find_by(slug: secondary_slug)]
    end

    def resolve_tiebreak(tied_slugs)
      bloc2 = @diagnostic.diagnostic_answers
        .joins(:question)
        .where(questions: { bloc: 2, scored: true })
        .where(profile_dimension: tied_slugs)

      counts = Hash.new(0)
      bloc2.each { |a| counts[a.profile_dimension] += a.points_awarded.to_i }

      counts.any? ? counts.max_by { |_, v| v }.first : tied_slugs.first
    end
  end
end
