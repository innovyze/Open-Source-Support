# frozen_string_literal: true

module SmoScottishLidar
  BUCKET = "srsp-open-data"
  BASE_PREFIX = "lidar"
  REGION = "eu-west-2"
  BASE_URL = "https://#{BUCKET}.s3.#{REGION}.amazonaws.com"

  # Valid phases and dataset types derived from the Scottish Government
  # Registry of Open Data on AWS documentation.
  PHASES = %w[phase-1 phase-2 phase-3 phase-4 phase-5 outer-hebrides].freeze
  DATASET_TYPES = %w[dsm dtm laz].freeze

  # Outer Hebrides has resolution sub-folders; all other phases do not.
  OUTER_HEBRIDES_RESOLUTIONS = {
    "dsm" => %w[25cm 50cm],
    "dtm" => %w[25cm 50cm],
    "laz" => %w[4ppm 16ppm]
  }.freeze

  # Canonical S3 prefix builder. Returns the prefix string (no bucket).
  # Examples:
  #   prefix_for("phase-1", "dsm")           => "lidar/phase-1/dsm/27700/gridded/"
  #   prefix_for("outer-hebrides", "dtm", resolution: "50cm") => "lidar/outer-hebrides/2019/dtm/50cm/27700/gridded/"
  def self.prefix_for(phase, type, resolution: nil)
    validate_phase!(phase)
    validate_type!(type)

    if phase == "outer-hebrides"
      res = resolve_outer_hebrides_resolution(type, resolution)
      "#{BASE_PREFIX}/outer-hebrides/2019/#{type}/#{res}/27700/gridded/"
    else
      "#{BASE_PREFIX}/#{phase}/#{type}/27700/gridded/"
    end
  end

  def self.validate_phase!(phase)
    return if PHASES.include?(phase)

    raise ArgumentError, "Unknown phase '#{phase}'. Valid: #{PHASES.join(', ')}"
  end

  def self.validate_type!(type)
    return if DATASET_TYPES.include?(type)

    raise ArgumentError, "Unknown dataset type '#{type}'. Valid: #{DATASET_TYPES.join(', ')}"
  end

  def self.resolve_outer_hebrides_resolution(type, resolution)
    available = OUTER_HEBRIDES_RESOLUTIONS[type]
    if resolution.nil?
      available.first
    elsif available.include?(resolution)
      resolution
    else
      raise ArgumentError,
            "Resolution '#{resolution}' not available for outer-hebrides #{type}. " \
            "Available: #{available.join(', ')}"
    end
  end
end
