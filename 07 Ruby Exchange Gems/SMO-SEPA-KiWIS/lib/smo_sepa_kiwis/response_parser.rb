require "json"

module SmoSepaKiwis
  module ResponseParser
    def self.parse(body)
      data = JSON.parse(body)
    rescue JSON::ParserError => e
      raise ParseError, "Invalid JSON: #{e.message}"
    else
      validate_and_convert(data)
    end

    def self.validate_and_convert(data)
      # Empty result.
      return [] if data == []

      unless data.is_a?(Array) && data.first.is_a?(Array) && data.first.all? { |h| h.is_a?(String) }
        raise ParseError, "Unexpected response shape: #{data.class}"
      end

      headers = data.first.map { |h| h.to_sym }
      rows = data[1..]

      # No data rows (headers only).
      return [] if rows.nil? || rows.empty?

      rows.map do |row|
        unless row.is_a?(Array)
          raise ParseError, "Expected row to be an Array, got #{row.class}"
        end
        headers.zip(row).to_h
      end
    end
  end
end
