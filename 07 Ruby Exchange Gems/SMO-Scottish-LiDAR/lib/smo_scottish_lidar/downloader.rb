# frozen_string_literal: true

require "fileutils"

module SmoScottishLidar
  # Downloads LiDAR files from the Scottish Government S3 bucket.
  # No external dependencies. Uses only Ruby stdlib.
  class Downloader
    attr_reader :client, :lister

    def initialize(verbose: false)
      @client  = Client.new(verbose: verbose)
      @lister  = Lister.new(verbose: verbose)
      @verbose = verbose
    end

    # Download all files for a given phase/type, with optional filtering.
    #
    # @param phase        [String]  e.g. "phase-1", "outer-hebrides"
    # @param type         [String]  "dsm", "dtm", or "laz"
    # @param destination  [String]  Local directory to save files into
    # @param grid_square  [String, nil] OS grid square filter e.g. "NS"
    # @param resolution   [String, nil] Outer Hebrides resolution e.g. "50cm"
    # @param skip_existing [Boolean] Skip files that already exist locally (default: true)
    # @param dry_run      [Boolean] List what would be downloaded without downloading
    # @return [Hash] { downloaded: [...], skipped: [...], failed: [...] }
    def download(phase, type,
                 destination:,
                 grid_square: nil,
                 resolution: nil,
                 skip_existing: true,
                 dry_run: false)

      FileUtils.mkdir_p(destination) unless dry_run

      objects = lister.list(phase, type, grid_square: grid_square, resolution: resolution)

      if objects.empty?
        puts "No files matched your criteria."
        return { downloaded: [], skipped: [], failed: [] }
      end

      total_bytes = objects.sum { |o| o[:size] }
      puts "Found #{objects.size} file(s) (#{format_bytes(total_bytes)} total)"
      puts "Destination: #{destination}"
      puts "(Dry run - no files will be downloaded)" if dry_run
      puts

      results = { downloaded: [], skipped: [], failed: [] }

      objects.each_with_index do |obj, idx|
        local_path = File.join(destination, obj[:filename])
        label = "[#{idx + 1}/#{objects.size}] #{obj[:filename]} (#{format_bytes(obj[:size])})"

        if skip_existing && File.exist?(local_path) && File.size(local_path) == obj[:size]
          puts "SKIP  #{label}"
          results[:skipped] << obj[:filename]
          next
        end

        if dry_run
          puts "WOULD #{label}"
          results[:downloaded] << obj[:filename]
          next
        end

        print "GET   #{label} ... "
        $stdout.flush

        begin
          client.download_object(obj[:key], local_path) do |received, total|
            next unless @verbose && total

            pct = (received.to_f / total * 100).round(1)
            print "\rGET   #{label} ... #{pct}%"
            $stdout.flush
          end
          puts "OK"
          results[:downloaded] << obj[:filename]
        rescue StandardError => e
          puts "FAILED (#{e.message})"
          results[:failed] << { file: obj[:filename], error: e.message }
        end
      end

      print_summary(results)
      results
    end

    # Convenience: download a single file by its S3 key or filename.
    #
    # @param phase       [String]
    # @param type        [String]
    # @param filename    [String] Exact filename to download
    # @param destination [String] Local directory
    # @param resolution  [String, nil]
    def download_file(phase, type, filename, destination:, resolution: nil)
      prefix = SmoScottishLidar.prefix_for(phase, type, resolution: resolution)
      key    = "#{prefix}#{filename}"
      local  = File.join(destination, filename)

      FileUtils.mkdir_p(destination)
      puts "Downloading #{filename} ..."
      client.download_object(key, local)
      puts "Saved to #{local}"
      local
    end

    private

    def print_summary(results)
      puts
      puts "Done. Downloaded: #{results[:downloaded].size}, " \
           "Skipped: #{results[:skipped].size}, " \
           "Failed: #{results[:failed].size}"

      return if results[:failed].empty?

      puts "Failed files:"
      results[:failed].each { |f| puts "  #{f[:file]}: #{f[:error]}" }
    end

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
