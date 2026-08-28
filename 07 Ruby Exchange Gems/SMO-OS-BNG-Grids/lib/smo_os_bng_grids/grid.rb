# frozen_string_literal: true

module SmoOsBngGrids
  module Grid
    # Returns the bng_ref string for a given easting/northing at a resolution.
    # resolution: "100km", "50km", "10km", "5km", "1km"
    def self.ref_at(easting, northing, resolution: "10km")
      validate_resolution!(resolution)
      validate_coords!(easting, northing)

      base = ref_100km(easting, northing)
      raise ArgumentError, "No 100km grid square at E=#{easting} N=#{northing}" unless GRID_100KM.key?(base)

      case resolution
      when "100km" then base
      when "50km"  then base + quadrant_suffix(easting, northing, 50_000)
      when "10km"  then base + tenKm_digits(easting, northing)
      when "5km"   then base + tenKm_digits(easting, northing) + quadrant_suffix(easting, northing, 5_000)
      when "1km"   then base + oneKm_digits(easting, northing)
      end
    end

    # Disambiguates 4-char refs: 10km (NS56) vs 50km (NSNE).
    def self.bounds(bng_ref)
      bng_ref = bng_ref.to_s.strip.upcase
      letters = bng_ref[0, 2]
      suffix  = bng_ref[2..]

      case bng_ref.length
      when 2
        bounds_from_data(bng_ref, GRID_100KM, 100_000)
      when 4
        if suffix =~ /\A[0-9]{2}\z/
          bounds_from_data(bng_ref, GRID_10KM, 10_000)
        elsif QUADRANTS.include?(suffix)
          bounds_from_data(bng_ref, GRID_50KM, 50_000)
        else
          raise ArgumentError, "Unknown 4-char ref format: #{bng_ref.inspect}"
        end
      when 6
        bounds_6(bng_ref)
      when 8
        bounds_from_data(bng_ref, GRID_5KM, 5_000)
      else
        raise ArgumentError, "Cannot determine resolution from ref: #{bng_ref.inspect}"
      end
    end

    # Returns true if the bng_ref exists in the OS dataset.
    def self.valid?(bng_ref)
      bng_ref = bng_ref.to_s.strip.upcase
      letters = bng_ref[0, 2]
      suffix  = bng_ref[2..]

      case bng_ref.length
      when 2 then GRID_100KM.key?(bng_ref)
      when 4
        if suffix =~ /\A[0-9]{2}\z/
          GRID_10KM.key?(bng_ref)
        elsif QUADRANTS.include?(suffix)
          GRID_50KM.key?(bng_ref)
        else
          false
        end
      when 6
        if suffix =~ /\A[0-9]{4}\z/
          GRID_10KM.key?(letters + suffix[0, 2])
        elsif suffix =~ /\A[0-9]{2}(NE|NW|SE|SW)\z/
          GRID_5KM.key?(bng_ref)
        else
          false
        end
      when 8
        GRID_5KM.key?(bng_ref)
      else
        false
      end
    end

    # Returns the resolution string for a bng_ref.
    def self.resolution_of(bng_ref)
      bng_ref = bng_ref.to_s.strip.upcase
      suffix  = bng_ref[2..]
      case bng_ref.length
      when 2 then "100km"
      when 4 then QUADRANTS.include?(suffix) ? "50km" : "10km"
      when 6 then suffix =~ /\A[0-9]{4}\z/ ? "1km" : "5km"
      when 8 then "5km"
      else raise ArgumentError, "Cannot determine resolution of #{bng_ref.inspect}"
      end
    end

    private

    def self.bounds_from_data(ref, dataset, size)
      entry = dataset[ref]
      raise ArgumentError, "Unknown grid ref: #{ref.inspect}" unless entry

      min_e, min_n = entry
      { min_e: min_e, min_n: min_n, max_e: min_e + size, max_n: min_n + size }
    end

    # Handles 6-char refs: 1km (NS5566) or ambiguous.
    def self.bounds_6(bng_ref)
      letters = bng_ref[0, 2]
      suffix  = bng_ref[2, 4]

      if suffix =~ /\A[0-9]{4}\z/
        # 1km ref. Derive from parent 100km.
        parent = GRID_100KM[letters]
        raise ArgumentError, "Unknown 100km ref in: #{bng_ref.inspect}" unless parent

        e_digits = suffix[0, 2].to_i
        n_digits = suffix[2, 2].to_i
        min_e = parent[0] + e_digits * 1_000
        min_n = parent[1] + n_digits * 1_000
        { min_e: min_e, min_n: min_n, max_e: min_e + 1_000, max_n: min_n + 1_000 }
      elsif suffix =~ /\A[0-9]{2}(NE|NW|SE|SW)\z/
        # 5km ref (e.g. NS56NE).
        bounds_from_data(bng_ref, GRID_5KM, 5_000)
      else
        raise ArgumentError, "Unknown 6-char ref format: #{bng_ref.inspect}"
      end
    end

    def self.ref_100km(easting, northing)
      e500 = easting  / 500_000
      n500 = northing / 500_000

      first_idx  = (3 - n500) * 5 + e500 + 2
      sub_e = (easting  % 500_000) / 100_000
      sub_n = (northing % 500_000) / 100_000
      second_idx = (4 - sub_n) * 5 + sub_e

      LETTERS[first_idx] + LETTERS[second_idx]
    end

    LETTERS = "ABCDEFGHJKLMNOPQRSTUVWXYZ"

    def self.tenKm_digits(easting, northing)
      letters = ref_100km(easting, northing)
      origin  = GRID_100KM[letters]
      e_digit = (easting  - origin[0]) / 10_000
      n_digit = (northing - origin[1]) / 10_000
      format("%d%d", e_digit, n_digit)
    end

    def self.oneKm_digits(easting, northing)
      letters = ref_100km(easting, northing)
      origin  = GRID_100KM[letters]
      e_digits = (easting  - origin[0]) / 1_000
      n_digits = (northing - origin[1]) / 1_000
      format("%02d%02d", e_digits, n_digits)
    end

    def self.quadrant_suffix(easting, northing, half_size)
      ns = (northing % (half_size * 2)) >= half_size ? "N" : "S"
      ew = (easting  % (half_size * 2)) >= half_size ? "E" : "W"
      ns + ew
    end

    def self.validate_resolution!(res)
      return if VALID_RESOLUTIONS.include?(res)

      raise ArgumentError, format(MSG_INVALID_RESOLUTION, res.inspect)
    end

    def self.validate_coords!(easting, northing)
      raise ArgumentError, "Easting must be >= 0"  if easting  < 0
      raise ArgumentError, "Northing must be >= 0" if northing < 0
      raise ArgumentError, "Easting out of range"  if easting  > 700_000
      raise ArgumentError, "Northing out of range" if northing > 1_300_000
    end
  end
end
