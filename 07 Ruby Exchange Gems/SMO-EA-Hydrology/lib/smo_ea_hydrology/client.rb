# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "date"
require "time"

module SmoEaHydrology
  class Client
    BASE_URL    = "https://environment.data.gov.uk/hydrology"
    FM_BASE_URL = "https://environment.data.gov.uk/flood-monitoring"

    # Returns all active stations that have at least one 15-min rainfall measure.
    #
    # @return [Array<Station>]
    def rainfall_15min_stations
      items = paginate("/id/stations", observedProperty: "rainfall", "status.label": "Active")
      items.filter_map do |item|
        measures   = Array(item["measures"])
        measure_15 = measures.find { |m| m.is_a?(Hash) && m["period"] == 900 }
        next unless measure_15

        Station.new(
          id:                item["@id"],
          label:             item["label"],
          station_reference: item["stationReference"] || item["notation"],
          wiski_id:          item["wiskiID"],
          easting:           item["easting"],
          northing:          item["northing"],
          lat:               item["lat"],
          long:              item["long"],
          date_opened:       item["dateOpened"],
          status:            label_of(item["status"]),
          measure_id:        measure_15["@id"],
          measure_label:     derive_measure_label(measure_15)
        )
      end
    end

    # Returns all 15-min rainfall measures for a given station.
    #
    # @param station_reference [String] e.g. "589359"
    # @return [Array<Measure>]
    def measures(station_reference)
      items = get("/id/measures", observedProperty: "rainfall",
                                 periodName:        "15min",
                                 "station.stationReference": station_reference.to_s)
      items.map { |item| parse_measure(item) }
    end

    # Returns 15-min rainfall readings for a measure over a date/datetime range.
    #
    # @param measure_id [String] full measure URI or the path-only ID
    # @param from  [String, Date, Time] start inclusive — "YYYY-MM-DD" or "YYYY-MM-DD HH:MM"
    # @param to    [String, Date, Time] end inclusive   — "YYYY-MM-DD" or "YYYY-MM-DD HH:MM"
    # @return [Array<Reading>]
    def readings(measure_id, from:, to:)
      id_path    = measure_path(measure_id)
      from_str   = parse_datetime(from)
      to_str     = parse_datetime(to)
      date_only  = !from_str.include?("T")
      params     = if date_only
        { "mineq-date": from_str, "maxeq-date": to_str }
      else
        { "mineq-dateTime": from_str, "maxeq-dateTime": to_str }
      end
      items = paginate("#{id_path}/readings", **params)
      items.map { |item| parse_reading(item) }
    end

    # Like rainfall_15min_stations but also fetches coverage_from / coverage_to
    # for every station. Makes 2 extra API calls per station — slow for all 900+.
    # Progress is printed to $stdout.
    #
    # @return [Array<Station>]
    def rainfall_15min_stations_with_coverage
      stations = rainfall_15min_stations
      stations.each_with_index do |station, i|
        $stdout.print "\r  #{i + 1}/#{stations.size} #{station.station_reference}    "
        $stdout.flush
        station.coverage_from = fetch_earliest(station.measure_id)
        station.coverage_to   = fetch_latest_fm(station.station_reference)
      end
      $stdout.puts
      stations
    end

    # Search stations by partial name (case-insensitive) or exact station reference.
    # Calls rainfall_15min_stations internally so no coverage dates are included.
    #
    # @param query [String] partial station name or exact reference
    # @return [Array<Station>]
    def find_stations(query)
      q = query.to_s.strip.downcase
      rainfall_15min_stations.select do |s|
        s.station_reference.to_s.downcase == q ||
          s.label.to_s.downcase.include?(q)
      end
    end

    # Downloads 15-min readings for a single station to a CSV file.
    #
    # @param station_reference [String]
    # @param from  [String, Date] start date inclusive (YYYY-MM-DD)
    # @param to    [String, Date] end date inclusive (YYYY-MM-DD)
    # @param path  [String] output file path
    # @return [Integer] number of readings written
    def readings_to_csv(station_reference:, from:, to:, path:)
      require "csv"
      ms = measures(station_reference)
      raise ApiError, "No 15-min rainfall measure found for #{station_reference}" if ms.empty?

      rows = readings(ms.first.id, from: from, to: to)
      CSV.open(path, "w") do |csv|
        csv << %w[datetime value_mm quality completeness]
        rows.each do |r|
          csv << [r.datetime.strftime("%Y-%m-%d %H:%M:%S"), r.value, r.quality, r.completeness]
        end
      end
      rows.size
    end

    # Writes the full 15-min rainfall inventory to a CSV file.
    # Includes coverage dates — makes 2 extra API calls per station.
    #
    # @param path [String] output file path
    def rainfall_15min_inventory_to_csv(path)
      require "csv"
      entries = rainfall_15min_inventory
      CSV.open(path, "w") do |csv|
        csv << %w[station_reference station_label lat long easting northing
                  date_opened measure_id period_name unit_name value_type
                  coverage_from coverage_to]
        entries.each do |e|
          csv << [
            e.station_reference, e.station_label, e.lat, e.long,
            e.easting, e.northing, e.date_opened, e.measure_id,
            e.period_name, e.unit_name, e.value_type,
            e.coverage_from_s, e.coverage_to_s
          ]
        end
      end
      entries.size
    end

    # Downloads readings for multiple stations to individual CSV files.
    #
    # @param from        [String, Date] start date inclusive (YYYY-MM-DD)
    # @param to          [String, Date] end date inclusive (YYYY-MM-DD)
    # @param output_dir  [String] directory to write CSV files into
    # @param refs        [Array<String>, nil] station references to download;
    #                    nil downloads all active 15-min stations
    # @return [Hash] { station_reference => { path:, count: } }
    def batch_download(from:, to:, output_dir:, refs: nil)
      require "csv"
      require "fileutils"
      FileUtils.mkdir_p(output_dir)

      stations = rainfall_15min_stations
      stations = stations.select { |s| refs.map(&:to_s).include?(s.station_reference.to_s) } if refs

      results = {}
      stations.each_with_index do |station, i|
        ref  = station.station_reference.to_s
        path = File.join(output_dir, "#{ref}_#{parse_date(from)}_#{parse_date(to)}.csv")
        $stdout.print "\r  [#{i + 1}/#{stations.size}] #{ref}    "
        $stdout.flush

        count = readings_to_csv(station_reference: ref, from: from, to: to, path: path)
        results[ref] = { path: path, count: count }
      rescue => e
        results[ref] = { path: path, count: 0, error: e.message }
      end

      $stdout.puts
      results
    end

    # Returns a combined inventory of all active 15-min rainfall stations with
    # their measures and coverage dates (earliest and latest reading timestamps).
    #
    # Note: this makes two additional API calls per station (one to the hydrology
    # API for the earliest reading, one to the flood-monitoring API for the latest),
    # so it is slow for large inventories. Progress is printed to $stdout.
    #
    # @return [Array<InventoryEntry>]
    def rainfall_15min_inventory
      stations = rainfall_15min_stations
      entries  = []

      stations.each_with_index do |station, i|
        $stdout.print "\r  #{i + 1}/#{stations.size} #{station.station_reference}    "
        $stdout.flush

        measures_list = measures(station.station_reference)
        next if measures_list.empty?

        measure = measures_list.first
        from_t  = fetch_earliest(measure.id)
        to_t    = fetch_latest_fm(station.station_reference)

        entries << InventoryEntry.new(
          station_reference: station.station_reference,
          station_label:     station.label,
          lat:               station.lat,
          long:              station.long,
          easting:           station.easting,
          northing:          station.northing,
          date_opened:       station.date_opened,
          measure_id:        measure.id,
          period_name:       measure.period_name,
          unit_name:         measure.unit_name,
          value_type:        measure.value_type,
          coverage_from:     from_t,
          coverage_to:       to_t
        )
      end

      $stdout.puts
      entries
    end

    private

    # Follows pagination automatically until all items are collected.
    def paginate(path, **params)
      limit  = 10_000
      offset = 0
      all    = []

      loop do
        items = get(path, **params, _limit: limit, _offset: offset)
        all.concat(items)
        break if items.size < limit

        offset += limit
      end

      all
    end

    def get(path, **params)
      uri       = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(
        params.merge(_format: "json").reject { |_, v| v.nil? }
      )
      response = request(uri)

      raise ApiError.new("HTTP #{response.code} from #{uri}", status: response.code.to_i) \
        unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      Array(body["items"])
    rescue JSON::ParserError => e
      raise ParseError, "JSON parse error: #{e.message}"
    end

    def request(uri, limit = 5)
      raise ApiError, "Too many redirects" if limit.zero?

      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPRedirection)
        request(URI(response["location"]), limit - 1)
      else
        response
      end
    end

    # Fetches the datetime of the earliest available reading for a measure.
    # Queries the hydrology API with mineq-date=1990-01-01 and _limit=1.
    def fetch_earliest(measure_id)
      path  = measure_path(measure_id)
      items = get("#{path}/readings", "mineq-date": "1990-01-01", _limit: 1)
      return nil if items.empty?

      Time.iso8601(items.first["dateTime"])
    rescue
      nil
    end

    # Fetches the datetime of the latest available reading for a station
    # via the EA Flood Monitoring API, which exposes latestReading.dateTime.
    # Filters locally to rainfall measures with period == 900 (15 min).
    def fetch_latest_fm(station_reference)
      uri = URI("#{FM_BASE_URL}/id/stations/#{station_reference}/measures")
      uri.query = URI.encode_www_form(_format: "json")
      response = request(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      body  = JSON.parse(response.body)
      items = Array(body["items"])
      items.each do |item|
        next unless item["parameter"] == "rainfall" && item["period"] == 900

        lr = item["latestReading"]
        next unless lr.is_a?(Hash) && lr["dateTime"]

        return Time.iso8601(lr["dateTime"])
      end
      nil
    rescue
      nil
    end

    # Builds a human-readable label from the fields available in the embedded
    # measure object returned by the stations endpoint (no label field there).
    def derive_measure_label(measure)
      period   = measure["period"].to_i
      period_s = period == 900 ? "15min" : "#{period}s"
      param    = measure["parameter"].to_s.capitalize
      stat_uri = measure.dig("valueStatistic", "@id").to_s
      stat     = stat_uri.split("/").last.to_s.capitalize
      stat     = "Total" if stat.empty?
      "#{param} #{period_s} #{stat} (mm)"
    end

    def parse_measure(item)
      station = item["station"].is_a?(Hash) ? item["station"] : {}
      Measure.new(
        id:                item["@id"],
        label:             item["label"],
        station_reference: station["stationReference"],
        station_label:     station["label"],
        period_name:       item["periodName"],
        unit_name:         item["unitName"],
        value_type:        item["valueType"],
        timeseries_id:     item["timeseriesID"]
      )
    end

    def parse_reading(item)
      Reading.new(
        datetime:     Time.iso8601(item["dateTime"]),
        value:        item["value"].to_f,
        quality:      item["quality"],
        completeness: item["completeness"]
      )
    end

    # Parses a date or datetime value into a string for the EA API.
    # Returns "YYYY-MM-DD" for date-only, "YYYY-MM-DDTHH:MM:SSZ" when time is present.
    def parse_datetime(val)
      case val
      when Time
        val.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      when DateTime
        val.to_time.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      when Date
        val.strftime("%Y-%m-%d")
      when String
        s = val.strip
        if s =~ /\A\d{4}-\d{2}-\d{2}\z/
          s
        elsif s =~ /\A\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}/
          require "time"
          Time.parse(s).utc.strftime("%Y-%m-%dT%H:%M:%SZ")
        else
          raise ArgumentError, "Invalid date/time: #{val.inspect}"
        end
      else
        raise ArgumentError, "Cannot convert #{val.class} to date/time"
      end
    end

    # Returns a YYYY-MM-DD string from a date/datetime — used for filenames.
    def parse_date(d)
      parse_datetime(d)[0, 10]
    end

    def label_of(field)
      return nil if field.nil?
      return field if field.is_a?(String)
      Array(field).first.then { |f| f.is_a?(Hash) ? f["label"] : f }
    end

    # Extracts the path relative to BASE_URL from a full measure URI.
    # "http://environment.data.gov.uk/hydrology/id/measures/abc" -> "/id/measures/abc"
    def measure_path(id)
      id.to_s.start_with?("http") ? URI(id).path.sub(%r{\A/hydrology}, "") : id.to_s
    end
  end
end
