class DemandDiagram
  require 'tmpdir'
  require 'json'

  # Represents a single demand profile
  class DemandProfile
    attr_accessor :name, :comment, :pressure_related, :direct, :leakage, :linear_monthly, :linear_profile, :monthly_coef, :daily_coef, :live_data_point_id, :values

    # Creates a new demand profile from the profile hash (i.e. an item in the DDG JSON 'profiles' array)
    #
    # @param json [Hash]
    # @return [DemandProfile]
    def self.from_json_hash(json)
      profile = self.new()

      profile.name = json['name']
      profile.comment = json['comment']
      profile.pressure_related = json['pressure_related']
      profile.direct = json['direct']
      profile.leakage = json['leakage']
      profile.linear_monthly = json['linear_monthly']
      profile.linear_profile = json['linear_profile']
      profile.monthly_coef = json['monthly_coef']
      profile.daily_coef = json['daily_coef']
      profile.live_data_point_id = json['live_data_point_id']
      profile.values = self.values_from_triplets(json['triplets'])

      return profile
    end

    # Convert this profile into a hash matching the DDG JSON format
    # Does not currently do any kind of validation
    #
    # @return [Hash]
    def to_json_hash
      return {
        'name' => @name,
        'comment' => @comment,
        'pressure_related' => @pressure_related,
        'direct' => @direct,
        'leakage' => @leakage,
        'linear_monthly' => @linear_monthly,
        'linear_profile' => @linear_profile,
        'monthly_coef' => @monthly_coef,
        'daily_coef' => @daily_coef,
        'live_data_point_id' => @live_data_point_id,
        'triplets' => values_to_triplets(@values)
      }
    end

    private

    # Converts DDG JSON triplets (time, value, day) into an array pair of [seconds, value]
    # The DDG JSON format uses a decimal time format where 1.15 indicates 1 hour and 15 minutes
    # This could be modified to convert values to a Ruby Time object instead (using a certain day as the 'base')
    #
    # @param triplets [Array<Hash>]
    # @return [Array<Array>] Array of [seconds, value] arrays
    def self.values_from_triplets(triplets)
      values = []

      triplets.each do |triplet|
        time_div = triplet['time'].divmod(1)
        seconds = (triplet['day'] * 86400) + (time_div[0] * 3600) + (time_div[1] * 6000)
        values << [seconds.to_i, triplet['value']]
      end

      return values
    end

    # Converts the [seconds, value] arrays into DDG JSON triplet format i.e. decimal times
    # @param values [Array<Array>] Array of [seconds, value] arrays
    # @return [Array<Hash>] Array of Hashes with time, value, and day keys
    def values_to_triplets(values)
      triplets = []

      values.each do |(seconds, value)|
        seconds_in_day = seconds % 86400
        hours = seconds_in_day / 3600
        minutes = (seconds_in_day % 3600).to_f / 60

        triplets << {
          'time' => (hours + (minutes / 100)).round(2), # Decimal time format
          'value' => value,
          'day' => seconds / 86400
        }
      end

      return triplets
    end
  end

  # Standard Version GUID for demand diagrams - this shouldn't change except with application version
  VERSION_GUID = '8159EA22-E794-43D5-A1EC-3EA7702EAE91'

  attr_accessor :name, :version_guid, :comment, :profiles

  def initialize(name, profiles, comment = 'Default Comment', version: VERSION_GUID)
    @name = name
    @version = version
    @comment = comment

    if profiles&.all? { |profile| profile.is_a?(DemandProfile) }
      @profiles = profiles
    else
      raise "Profiles for demand diagram is not an array, or not an array of demand profiles"
    end
  end

  # Extract a demand diagram from a model object, and return a new demand diagram class
  #
  # @param ddg [WSModelObject] a model object of type 'Demand Diagram'
  # @return [DemandDiagram]
  def self.from_ddg(ddg)
    raise "Object is an invalid type" unless ddg.is_a?(WSModelObject) && ddg.type == 'Demand Diagram'

    temp_file = File.join(Dir.tmpdir, ddg.name + '.json')
    begin
      ddg.export_demand_diagram(temp_file)
      json = JSON.parse(File.read(temp_file))
      ddg_object = self.from_json(json, ddg.name)
    ensure
      File.delete(temp_file) if File.exist?(temp_file)
    end

    return ddg_object
  end

  # Parse a demand diagram from a JSON string.
  #
  # @param json [String]
  # @param name [String]
  # @return [DemandDiagram]
  def self.from_json(json, name)
    profiles = json['profiles'].map { |json_prof| DemandProfile.from_json_hash(json_prof) }
    ddg = self.new(name, profiles, json['comment'], version: json['version_guid'])
  end

  # Create a JSON string from this demand diagram.
  #
  # @return [String] JSON string
  def to_json
    hash = {
      'version_guid' => @version,
      'comment' => @comment,
      'profiles' => @profiles.map { |profile| profile.to_json_hash }
    }

    return hash.to_json
  end

  # Saves this demand diagram to a model group.
  #
  # @param ddg_group [WSModelObject] a model object of type 'Demand Diagram Group'
  # @return [WSModelObject] the imported demand diagram model object
  def to_ddg(ddg_group)
    raise "Object is an invalid type" unless ddg_group.is_a?(WSModelObject) && ddg_group.type == 'Demand Diagram Group'

    temp_file = File.join(Dir.tmpdir, @name + '.json')
    begin
      File.write(temp_file, to_json())
      ddg = ddg_group.import_demand_diagram(temp_file)
      ddg.name = @name
    ensure
      File.delete(temp_file) if File.exist?(temp_file)
    end

    return ddg
  end
end
