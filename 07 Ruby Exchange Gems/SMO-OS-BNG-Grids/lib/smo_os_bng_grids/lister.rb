# frozen_string_literal: true

module SmoOsBngGrids
  class Lister
    # Returns all valid bng_refs at the given resolution.
    #
    # @param resolution [String] "100km", "50km", "10km", "5km", "1km"
    # @param within     [String, nil] parent ref to filter by e.g. "NS" or "NS56"
    # @return [Array<Hash>] each entry: {ref:, min_e:, min_n:, max_e:, max_n:, points:}
    #   points: [[sw_e,sw_n],[se_e,se_n],[ne_e,ne_n],[nw_e,nw_n],[sw_e,sw_n]]
    def list(resolution, within: nil)
      validate_resolution!(resolution)

      entries = raw_entries(resolution)
      if within
        pb = Grid.bounds(within.upcase)
        entries = entries.select do |_ref, (min_e, min_n)|
          min_e >= pb[:min_e] && min_e < pb[:max_e] &&
          min_n >= pb[:min_n] && min_n < pb[:max_n]
        end
      end
      entries.map { |ref, (min_e, min_n)| build_entry(ref, min_e, min_n, resolution) }
    end

    # Finds all grid tiles at the given resolution that intersect a search area
    # centred on easting/northing.
    #
    # @param easting   [Integer] search centre easting (OSGB36)
    # @param northing  [Integer] search centre northing (OSGB36)
    # @param resolution [String] "100km", "50km", "10km", "5km", "1km"
    # @param radius    [Numeric, nil] circular search radius in metres
    # @param box       [Numeric, nil] half-width of a square search area in metres
    # @return [Array<Hash>] matching entries, each with :ref, :min_e, :min_n,
    #                       :max_e, :max_n, :points, :distance_m (circle only)
    def search(easting, northing, resolution: "10km", radius: nil, box: nil)
      raise ArgumentError, MSG_PROVIDE_RADIUS_OR_BOX if radius.nil? && box.nil?
      raise ArgumentError, MSG_PROVIDE_RADIUS_OR_BOX if radius && box

      Grid.validate_coords!(easting, northing)
      validate_resolution!(resolution)

      size = RESOLUTION_SIZE[resolution]

      raw_entries(resolution).each_with_object([]) do |(ref, (min_e, min_n)), result|
        max_e = min_e + size
        max_n = min_n + size

        if radius
          # Circle-rectangle intersection: distance from centre to nearest point on tile.
          clamp_e = [[easting,  min_e].max, max_e].min
          clamp_n = [[northing, min_n].max, max_n].min
          dist_sq = (easting - clamp_e)**2 + (northing - clamp_n)**2
          next unless dist_sq <= radius**2

          entry = build_entry(ref, min_e, min_n, resolution)
          entry[:distance_m] = Math.sqrt(dist_sq).round(1)
          result << entry
        else
          # Box intersection: tile overlaps the search bounding box.
          next unless min_e < easting + box && max_e > easting - box &&
                      min_n < northing + box && max_n > northing - box

          result << build_entry(ref, min_e, min_n, resolution)
        end
      end
    end

    # Returns the full entry hash (ref, bounds, points) for any BNG ref string.
    # Useful for converting find() results into shapefile-ready entries.
    #
    # @param bng_ref [String] e.g. "NT27", "NT27SE", "NT2573"
    # @return [Hash] {ref:, min_e:, min_n:, max_e:, max_n:, points:}
    def entry_for(bng_ref)
      bng_ref  = bng_ref.to_s.strip.upcase
      res      = Grid.resolution_of(bng_ref)
      b        = Grid.bounds(bng_ref)
      build_entry(bng_ref, b[:min_e], b[:min_n], res)
    end

    # Returns all bng_refs containing a given easting/northing point.
    # Returns a Hash keyed by resolution.
    def find(easting, northing)
      Grid.validate_coords!(easting, northing)
      VALID_RESOLUTIONS.each_with_object({}) do |res, h|
        ref = Grid.ref_at(easting, northing, resolution: res)
        h[res] = ref if Grid.valid?(ref)
      rescue ArgumentError
        next
      end
    end

    # Prints a summary table for a resolution with optional filter.
    def summary(resolution, within: nil)
      entries = list(resolution, within: within)
      puts "Resolution : #{resolution}"
      puts "Filter     : #{within || '(all)'}"
      puts "Count      : #{entries.size}"
      puts
      puts format("%-12s %10s %10s %10s %10s", "Ref", "Min E", "Min N", "Max E", "Max N")
      puts "-" * 56
      entries.each do |e|
        puts format("%-12s %10d %10d %10d %10d", e[:ref], e[:min_e], e[:min_n], e[:max_e], e[:max_n])
      end
      entries
    end

    private

    # Builds a single entry hash including corner points (NW→NE→SE→SW→NW, closed ring).
    # Order matches InfoWorks ICM boundary_array convention:
    # top-west, top-east, south-east, south-west.
    def build_entry(ref, min_e, min_n, resolution)
      size  = RESOLUTION_SIZE[resolution]
      max_e = min_e + size
      max_n = min_n + size
      {
        ref:    ref,
        min_e:  min_e, min_n:  min_n,
        max_e:  max_e, max_n:  max_n,
        points: [
          [min_e, max_n],
          [max_e, max_n],
          [max_e, min_n],
          [min_e, min_n],
          [min_e, max_n]
        ]
      }
    end

    def raw_entries(resolution)
      case resolution
      when "100km" then GRID_100KM
      when "50km"  then GRID_50KM
      when "10km"  then GRID_10KM
      when "5km"   then GRID_5KM
      when "1km"   then generate_1km
      end
    end

    # Generates all 1km refs on demand from the hardcoded 10km data.
    # All 100 sub-squares within each valid 10km square are valid.
    def generate_1km
      GRID_10KM.each_with_object({}) do |(ref10, (min_e, min_n)), h|
        100.times do |i|
          e_dig = i / 10
          n_dig = i % 10
          ref1  = ref10[0, 2] + format("%02d%02d", ref10[2].to_i * 10 + e_dig, ref10[3].to_i * 10 + n_dig)
          h[ref1] = [min_e + e_dig * 1_000, min_n + n_dig * 1_000]
        end
      end
    end

    def validate_resolution!(res)
      return if VALID_RESOLUTIONS.include?(res)

      raise ArgumentError, format(MSG_INVALID_RESOLUTION, res.inspect)
    end
  end
end
