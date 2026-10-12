# frozen_string_literal: true

module SmoScottishLidar
  # Lists available LiDAR files from the Scottish Government S3 bucket.
  # All filtering is done client-side after fetching the S3 listing.
  class Lister
    attr_reader :client

    def initialize(verbose: false)
      @client = Client.new(verbose: verbose)
    end

    # List files for a given phase and dataset type.
    #
    # @param phase       [String] e.g. "phase-1", "outer-hebrides"
    # @param type        [String] "dsm", "dtm", or "laz"
    # @param grid_square [String, nil] Optional OS grid square filter, e.g. "NS", "NT"
    # @param resolution  [String, nil] For outer-hebrides only, e.g. "50cm", "4ppm"
    # @return [Array<Hash>] Array of { key:, size:, last_modified:, filename: }
    def list(phase, type, grid_square: nil, resolution: nil)
      prefix = SmoScottishLidar.prefix_for(phase, type, resolution: resolution)
      objects = client.list_objects(prefix)

      objects.map! do |obj|
        obj.merge(filename: File.basename(obj[:key]))
      end

      if grid_square
        pattern = grid_square.upcase
        objects.select! { |obj| obj[:filename].upcase.start_with?(pattern) }
      end

      objects
    end

    # Print a human-readable summary of available files.
    def summary(phase, type, grid_square: nil, resolution: nil)
      objects = list(phase, type, grid_square: grid_square, resolution: resolution)

      if objects.empty?
        puts "No files found."
        return objects
      end

      total_bytes = objects.sum { |o| o[:size] }

      puts "Phase     : #{phase}"
      puts "Type      : #{type}"
      puts "Grid sq.  : #{grid_square || '(all)'}"
      puts "Files     : #{objects.size}"
      puts "Total size: #{format_bytes(total_bytes)}"
      puts
      puts format("%-50s %10s  %s", "Filename", "Size", "Last Modified")
      puts "-" * 80
      objects.each do |obj|
        puts format("%-50s %10s  %s", obj[:filename], format_bytes(obj[:size]), obj[:last_modified])
      end

      objects
    end

    private

    def format_bytes(bytes)
      units = %w[B KB MB GB TB]
      idx = 0
      size = bytes.to_f
      while size >= 1024 && idx < units.size - 1
        size /= 1024.0
        idx += 1
      end
      format("%.1f %s", size, units[idx])
    end
  end
end
