module Diagnostics
  module LikertScoring
    module_function

    def effective_value(raw_value, reverse_scored: false)
      raw = raw_value.to_i
      reverse_scored ? 6 - raw : raw
    end

    def average(effective_values)
      return 0.0 if effective_values.empty?

      effective_values.sum.to_f / effective_values.size
    end

    def normalize(average_value)
      ((average_value - 1) / 4.0) * 100
    end
  end
end
