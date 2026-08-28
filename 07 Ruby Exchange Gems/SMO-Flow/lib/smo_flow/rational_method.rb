# frozen_string_literal: true

module SmoFlow
  # Calculates surface runoff flow using the Rational Method.
  # Supports flow from rainfall intensity, rainfall depth, and timestep-based calculations.
  class RationalMethod
    DEPTH_MUST_BE_POSITIVE    = "Depth must be positive"
    TIMESTEP_MUST_BE_POSITIVE = "Timestep must be positive"

    attr_reader :coefficient, :area

    def initialize(coefficient:, area:)
      validate!(coefficient, area)
      @coefficient = coefficient  # C — runoff coefficient (0..1)
      @area        = area         # A — catchment area in hectares
    end

    # Q = C × i × A / 360  →  returns m³/s
    def flow_from_intensity(intensity)
      raise InvalidInput, "Intensity must be positive" unless intensity.positive?

      (coefficient * intensity * area) / 360.0
    end

    # Q = 10 × C × A × d / Δt  →  returns m³/s
    def flow_from_depth(depth:, timestep:)
      raise InvalidInput, DEPTH_MUST_BE_POSITIVE    unless depth.positive?
      raise InvalidInput, TIMESTEP_MUST_BE_POSITIVE unless timestep.positive?

      (10.0 * coefficient * area * depth) / timestep
    end

    # Convert depth (mm) over a timestep (s) to intensity (mm/hr)
    def depth_to_intensity(depth:, timestep:)
      raise InvalidInput, DEPTH_MUST_BE_POSITIVE    unless depth.positive?
      raise InvalidInput, TIMESTEP_MUST_BE_POSITIVE unless timestep.positive?

      (depth / timestep) * 3600.0
    end

    # Runoff volume for a timestep in m³
    def volume(depth:)
      raise InvalidInput, DEPTH_MUST_BE_POSITIVE unless depth.positive?

      10.0 * coefficient * area * depth
    end

    # Flow in L/s from intensity
    def flow_ls_from_intensity(intensity)
      flow_from_intensity(intensity) * 1000.0
    end

    private

    def validate!(coefficient, area)
      raise InvalidInput, "Coefficient must be between 0 and 1" unless (0.0..1.0).cover?(coefficient)
      raise InvalidInput, "Area must be positive"               unless area.positive?
    end
  end
end
