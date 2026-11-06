require "net/http"
require "uri"
require "json"
require "csv"
require "date"
require "time"

module SmoSepaKiwis
  class Client
    DEFAULT_BASE_URL = "https://timeseries.sepa.org.uk/KiWIS/KiWIS"

    def initialize(
      base_url: DEFAULT_BASE_URL,
      timeout: 60,
      user_agent: "smo_sepa_kiwis/#{VERSION}"
    )
      @uri      = URI.parse(base_url)
      @timeout  = timeout
      @user_agent = user_agent
    end

    # Returns Array<Station>. Fetches all rainfall stations from SEPA.
    def rainfall_stations
      rows = request("getStationList",
        stationparameter_no: "RE",
        returnfields: "station_no,station_name,station_latitude,station_longitude," \
                      "catchment_name,river_name"
      )
      rows.map { |h| build_station(h) }
    end

    # Returns Array<Timeseries> for a given station_no.
    def rainfall_15min_timeseries(station_no:)
      rows = request("getTimeseriesList",
        station_no: station_no,
        parametertype_name: "Precipitation",
        ts_path: "1/*/RE/15*",
        returnfields: "ts_id,ts_path,ts_name,station_no,coverage"
      )
      rows.map { |h| build_timeseries(h) }
    end

    # Returns Array<Hash> with combined station and timeseries fields.
    # Uses two API calls (getTimeseriesList + getStationList) and joins in Ruby,
    # because getTimeseriesList on SEPA's instance rejects station detail fields.
    def rainfall_15min_inventory
      ts_rows = request("getTimeseriesList",
        parametertype_name: "Precipitation",
        ts_path: "1/*/RE/15*",
        returnfields: "ts_id,ts_path,ts_name,station_no,coverage"
      )

      station_map = rainfall_stations.each_with_object({}) { |s, m| m[s.no] = s }

      ts_rows.map do |h|
        s      = station_map[h[:station_no].to_s]
        from_t = safe_parse_time(h[:from])
        to_t   = safe_parse_time(h[:to])
        {
          station_no:    presence(h[:station_no]),
          station_name:  s&.name,
          lat:           s&.lat,
          lon:           s&.lon,
          catchment:     s&.catchment,
          river:         s&.river,
          ts_id:         to_integer(h[:ts_id]),
          ts_path:       presence(h[:ts_path]),
          coverage_from: from_t,
          coverage_to:   to_t
        }
      end
    end

    # Returns Array<Value>. Accepts String/Date/Time/DateTime for from/to.
    # If chunk_days is set, splits the window into N-day chunks and concatenates results.
    def timeseries_values(ts_id:, from:, to:, chunk_days: nil)
      from_time = parse_time_arg(from)
      to_time   = parse_time_arg(to)

      if chunk_days
        fetch_chunked(ts_id: ts_id, from: from_time, to: to_time, chunk_days: chunk_days)
      else
        fetch_values(ts_id: ts_id, from: from_time, to: to_time)
      end
    end

    # Writes the full rainfall 15-min inventory to a CSV file.
    def rainfall_15min_inventory_to_csv(path)
      rows = rainfall_15min_inventory
      CSV.open(path, "w") do |csv|
        csv << %w[station_no station_name lat lon catchment river ts_id ts_path coverage_from coverage_to]
        rows.each do |r|
          csv << [
            r[:station_no], r[:station_name], r[:lat], r[:lon],
            r[:catchment], r[:river],
            r[:ts_id], r[:ts_path],
            r[:coverage_from]&.strftime("%Y-%m-%dT%H:%M:%SZ"),
            r[:coverage_to]&.strftime("%Y-%m-%dT%H:%M:%SZ")
          ]
        end
      end
    end

    # Writes timeseries values to a CSV file.
    def timeseries_values_to_csv(ts_id:, from:, to:, path:, chunk_days: nil)
      values = timeseries_values(ts_id: ts_id, from: from, to: to, chunk_days: chunk_days)
      CSV.open(path, "w") do |csv|
        csv << %w[timestamp value quality_code]
        values.each do |v|
          csv << [v.timestamp.strftime("%Y-%m-%dT%H:%M:%SZ"), v.value, v.quality_code]
        end
      end
    end

    private

    def request(function, **params)
      ResponseParser.parse(request_body(build_uri(function, **params)))
    end

    def build_uri(function, **params)
      uri = @uri.dup
      uri.query = URI.encode_www_form(
        service: "kisters",
        type: "queryServices",
        datasource: "0",
        request: function,
        format: "json",
        **params
      )
      uri
    end

    def request_body(uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: @timeout) do |http|
        req = Net::HTTP::Get.new(uri)
        req["User-Agent"] = @user_agent
        response = http.request(req)

        unless response.is_a?(Net::HTTPSuccess)
          snippet = response.body.to_s[0, 300]
          raise ApiError.new(
            "HTTP #{response.code} from KiWIS: #{snippet}",
            status: response.code.to_i
          )
        end

        response.body
      end
    end

    def build_station(h)
      Station.new(
        no:        presence(h[:station_no]),
        name:      presence(h[:station_name]),
        lat:       to_float(h[:station_latitude]),
        lon:       to_float(h[:station_longitude]),
        catchment: presence(h[:catchment_name]),
        river:     presence(h[:river_name])
      )
    end

    def build_timeseries(h)
      from_t, to_t = parse_coverage(h)
      Timeseries.new(
        ts_id:         to_integer(h[:ts_id]),
        ts_path:       presence(h[:ts_path]),
        ts_name:       presence(h[:ts_name]),
        station_no:    presence(h[:station_no]),
        coverage_from: from_t,
        coverage_to:   to_t
      )
    end

    def build_inventory_row(h)
      from_t, to_t = parse_coverage(h)
      {
        station_no:    presence(h[:station_no]),
        station_name:  presence(h[:station_name]),
        lat:           to_float(h[:station_latitude]),
        lon:           to_float(h[:station_longitude]),
        catchment:     presence(h[:catchment_name]),
        river:         presence(h[:river_name]),
        ts_id:         to_integer(h[:ts_id]),
        ts_path:       presence(h[:ts_path]),
        coverage_from: from_t,
        coverage_to:   to_t
      }
    end

    def parse_values_body(body)
      # getTimeseriesValues returns [{ts_id, rows, columns: "Timestamp,Value,...", data: [[ts,val],...]}]
      outer = JSON.parse(body)
    rescue JSON::ParserError => e
      raise ParseError, "Invalid JSON from getTimeseriesValues: #{e.message}"
    else
      return [] if outer.nil? || outer.empty?
      block = outer.first
      raise ParseError, "Unexpected values shape" unless block.is_a?(Hash) && block["data"]

      cols   = block["columns"].to_s.split(",").map { |c| c.strip.downcase }
      ts_idx = cols.index("timestamp") || 0
      v_idx  = cols.index("value")     || 1
      qc_idx = cols.index("quality code")

      (block["data"] || []).map do |row|
        Value.new(
          timestamp:    parse_iso8601(row[ts_idx].to_s),
          value:        row[v_idx].nil? ? nil : to_float(row[v_idx]),
          quality_code: qc_idx ? to_integer(row[qc_idx]) : nil
        )
      end
    end

    # Parses coverage field. KiWIS may return a combined "from/to" string
    # in :coverage, or separate :from and :to fields.
    def parse_coverage(h)
      if h.key?(:coverage) && h[:coverage]
        parts = h[:coverage].to_s.split("/")
        [safe_parse_time(parts[0]), safe_parse_time(parts[1])]
      else
        [safe_parse_time(h[:from]), safe_parse_time(h[:to])]
      end
    end

    def fetch_values(ts_id:, from:, to:)
      uri = build_uri("getTimeseriesValues",
        ts_id: ts_id,
        from:  from.strftime("%Y-%m-%dT%H:%M:%SZ"),
        to:    to.strftime("%Y-%m-%dT%H:%M:%SZ")
      )
      parse_values_body(request_body(uri))
    end

    def fetch_chunked(ts_id:, from:, to:, chunk_days:)
      results = {}
      window_start = from
      chunk_secs = chunk_days * 86400

      while window_start < to
        window_end = [window_start + chunk_secs, to].min
        fetch_values(ts_id: ts_id, from: window_start, to: window_end).each do |v|
          results[v.timestamp] = v
        end
        window_start = window_end
      end

      results.values.sort_by(&:timestamp)
    end

    def parse_time_arg(val)
      case val
      when Time     then val.utc
      when DateTime then val.to_time.utc
      when Date     then Time.utc(val.year, val.month, val.day)
      when String
        # Accept full ISO 8601 datetimes or bare date strings (YYYY-MM-DD).
        if val =~ /\A\d{4}-\d{2}-\d{2}\z/
          d = Date.parse(val)
          Time.utc(d.year, d.month, d.day)
        else
          Time.iso8601(val).utc
        end
      else raise ArgumentError, "Cannot convert #{val.class} to Time"
      end
    end

    def safe_parse_time(str)
      return nil if str.nil? || str.to_s.strip.empty?
      Time.iso8601(str.to_s.strip).utc
    rescue ArgumentError
      nil
    end

    def parse_iso8601(str)
      return nil if str.nil? || str.to_s.strip.empty?
      Time.iso8601(str.to_s.strip).utc
    rescue ArgumentError
      nil
    end

    def presence(val)
      return nil if val.nil?
      s = val.to_s.strip
      s.empty? ? nil : s
    end

    def to_float(val)
      return nil if val.nil?
      s = val.to_s.strip
      return nil if s.empty?
      Float(s)
    rescue ArgumentError
      nil
    end

    def to_integer(val)
      return nil if val.nil?
      s = val.to_s.strip
      return nil if s.empty?
      Integer(s, exception: false)
    end
  end
end
