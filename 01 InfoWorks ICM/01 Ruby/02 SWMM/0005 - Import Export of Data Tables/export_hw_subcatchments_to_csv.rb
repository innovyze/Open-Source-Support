require 'csv'
require 'fileutils'

# --- Configuration: Define hw_subcatchment Fields (excluding top-level flags) ---
# IMPORTANT: The symbols MUST match the actual method names available on
# 'hw_subcatchment' objects in your environment.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names.
FIELDS_TO_EXPORT = [
  # Key Identifiers & Coordinates
  ['Include Subcatchment ID', :subcatchment_id, true, 'SubcID'],
  ['Include X Coordinate', :x, true, 'X_Coord'],
  ['Include Y Coordinate', :y, true, 'Y_Coord'],

  # Basic Properties
  ['Include System Type', :system_type, false, 'SysType'],
  ['Include Drains To', :drains_to, false, 'DrainsTo'], # Node ID
  ['Include Outlet Node ID', :node_id, false, 'OutletNode'], # Often the same as drains_to
  ['Include Outlet Link Suffix', :link_suffix, false, 'OutletLinkSuf'],
  ['Include To Subcatchment ID', :to_subcatchment_id, false, 'ToSubcID'],
  ['Include 2D Point ID', :_2d_pt_id, false, '2D_PtID'], # Note leading underscore for symbol

  # Area and Geometry
  ['Include Total Area', :total_area, true, 'TotalArea'],
  ['Include Contributing Area', :contributing_area, true, 'ContribArea'],
  ['Include Boundary Array', :boundary_array, false, 'BoundaryXY'], # Complex
  ['Include Catchment Slope', :catchment_slope, false, 'CatchSlope'],
  ['Include Catchment Dimension', :catchment_dimension, false, 'CatchDim'],
  ['Include Area Measurement Type', :area_measurement_type, false, 'AreaMeasType'],

  # Lateral Links & Weights
  ['Include Lateral Links', :lateral_links, false, 'LatLinks'], # Complex
  ['Include Lateral Weights', :lateral_weights, false, 'LatWeights'], # Could be single value or array

  # ReFH Descriptors (serialized into one field)
  ['Include ReFH Descriptors', :refh_descriptors, false, 'ReFH_Desc'], # Complex

  # SUDS Controls (serialized array of objects)
  ['Include SUDS Controls', :suds_controls, false, 'SUDS_Ctrl'], # Complex

  # SWMM Coverage (serialized array of objects)
  ['Include SWMM Coverage', :swmm_coverage, false, 'SWMM_Cov'], # Complex

  # Flow and Capacity
  ['Include Capacity Limit', :capacity_limit, false, 'CapLimit'],
  ['Include Exceed Flow Type', :exceed_flow_type, false, 'ExceedFlwTyp'],

  # Soil and Runoff Parameters
  ['Include UKWIR Soil Runoff', :ukwir_soil_runoff, false, 'UKWIR_Soil'],
  ['Include Soil Class Type', :soil_class_type, false, 'SoilClassTyp'],
  ['Include Soil Class', :soil_class, false, 'SoilClass'],
  ['Include Soil Class HOST', :soil_class_host, false, 'SoilClsHOST'],
  ['Include Max Soil Moisture Capacity', :max_soil_moisture_capacity, false, 'MaxSoilMoist'],
  ['Include Curve Number (SCS)', :curve_number, false, 'CurveNum'],
  ['Include Drying Time (SCS)', :drying_time, false, 'DryTimeSCS'],
  ['Include Soil Moisture Deficit', :soil_moist_def, false, 'SoilMoistDef'],

  # Rainfall and Evaporation
  ['Include Rainfall Profile', :rainfall_profile, false, 'RainProfile'],
  ['Include Evaporation Profile', :evaporation_profile, false, 'EvapProfile'],
  ['Include Area Average Rain', :area_average_rain, false, 'AreaAvgRain'], # Boolean or value

  # Unit Hydrograph and Routing Parameters
  ['Include Unit Hydrograph ID', :unit_hydrograph_id, false, 'UH_ID'],
  ['Include UH Definition', :uh_definition, false, 'UH_Def'],
  ['Include TC Method', :tc_method, false, 'TC_Method'],
  ['Include Time of Concentration', :time_of_concentration, false, 'ToC'],
  ['Include Overland Flow Time', :overland_flow_time, false, 'OvrlndFlwT'],
  ['Include Flood Wave Celerity', :flood_wave_celerity, false, 'FldWaveCel'],
  ['Include Equivalent Roughness', :equivalent_roughness, false, 'EquivRough'],
  ['Include Hydraulic Radius', :hydraulic_radius, false, 'HydRadius'],
  ['Include PWRI Coefficient', :pwri_coefficient, false, 'PWRI_Coeff'],
  ['Include TC Timestep Factor', :tc_timestep_factor, false, 'TC_TimeFac'],
  ['Include TC Time to Peak Factor', :tc_time_to_peak_factor, false, 'TC_PeakFac'],
  ['Include Time to Peak', :time_to_peak, false, 'TimeToPeak'],
  ['Include Base Time', :base_time, false, 'BaseTime'],
  ['Include Lag Time (Snyder/User)', :lag_time, false, 'LagTime'],
  ['Include Peaking Coefficient (Snyder)', :peaking_coeff, false, 'PeakCoeff'],
  ['Include UH Peak (User Defined)', :uh_peak, false, 'UH_Peak'],
  ['Include UH Kink (User Defined)', :uh_kink, false, 'UH_Kink'],
  ['Include Non-linear Routing Method', :non_linear_routing_method, false, 'NonLinRouteM'],
  ['Include Lag Time Method (Non-linear)', :lag_time_method, false, 'LagTimeM_NL'],
  ['Include Storage Factor (Non-linear)', :storage_factor, false, 'StoreFac_NL'],
  ['Include Storage Exponent (Non-linear)', :storage_exponent, false, 'StoreExp_NL'],
  ['Include Internal Routing Model', :internal_routing, false, 'IntRouteMdl'],
  ['Include Percent Routed', :percent_routed, false, 'PctRouted'],

  # SRM Model Parameters
  ['Include SRM Runoff Coefficient', :srm_runoff_coeff, false, 'SRM_RunCo'],
  ['Include SRM K1', :srm_k1, false, 'SRM_K1'],
  ['Include SRM K2', :srm_k2, false, 'SRM_K2'],
  ['Include SRM TDLY', :srm_tdly, false, 'SRM_TDLY'],

  # ARMA Model
  ['Include ARMA ID', :arma_id, false, 'ARMA_ID'],
  ['Include Output Lag (ARMA)', :output_lag, false, 'OutputLag'],
  ['Include Bypass Runoff (ARMA)', :bypass_runoff, false, 'BypassRunoff'],

  # RAFTS Model Parameters
  ['Include RAFTS Per Surface', :rafts_per_surface, false, 'RAFTS_PerSrf'],
  ['Include Degree of Urbanisation (RAFTS)', :degree_urbanisation, false, 'RAFTS_Urb'],
  ['Include RAFTS Adapt Factor', :rafts_adapt_factor, false, 'RAFTS_AdaptF'],
  ['Include RAFTS B (Storage Coeff)', :rafts_b, false, 'RAFTS_B'],
  ['Include RAFTS N (Non-linearity Exp)', :rafts_n, false, 'RAFTS_N'],
  ['Include Connectivity (RAFTS)', :connectivity, false, 'RAFTS_Conn'],

  # Wastewater and Baseflow
  ['Include Wastewater Profile', :wastewater_profile, false, 'WW_ProfileID'],
  ['Include Population', :population, false, 'Population'],
  ['Include Trade Flow', :trade_flow, false, 'TradeFlow'],
  ['Include Additional Foul Flow', :additional_foul_flow, false, 'AddFoulFlow'],
  ['Include Base Flow (Wastewater)', :base_flow, false, 'BaseFlow_WW'],
  ['Include Trade Profile ID', :trade_profile, false, 'Trade_ProfID'],

  # Groundwater Interaction
  ['Include Ground ID (Aquifer)', :ground_id, false, 'GroundID_Aq'],
  ['Include Ground Node (Aquifer Connection)', :ground_node, false, 'GroundNodeAq'],
  ['Include Baseflow Lag (Groundwater)', :baseflow_lag, false, 'BaseflowLag'],
  ['Include Baseflow Recharge Rate (Groundwater)', :baseflow_recharge, false, 'BaseflowRech'],
  ['Include Baseflow Calculation Type', :baseflow_calc, false, 'BaseflowCalc'],

  # Land Use and PDM
  ['Include Land Use ID', :land_use_id, false, 'LandUseID'],
  ['Include PDM Descriptor ID', :pdm_descriptor_id, false, 'PDM_DescID'],

  # Snow Pack
  ['Include Snow Pack ID', :snow_pack_id, false, 'SnowPackID'],

  # Area Absolute Values (1-12) - Explicitly listed
  ['Include Area Absolute 1', :area_absolute_1, false, "AreaAbs1"],
  ['Include Area Absolute 2', :area_absolute_2, false, "AreaAbs2"],
  ['Include Area Absolute 3', :area_absolute_3, false, "AreaAbs3"],
  ['Include Area Absolute 4', :area_absolute_4, false, "AreaAbs4"],
  ['Include Area Absolute 5', :area_absolute_5, false, "AreaAbs5"],
  ['Include Area Absolute 6', :area_absolute_6, false, "AreaAbs6"],
  ['Include Area Absolute 7', :area_absolute_7, false, "AreaAbs7"],
  ['Include Area Absolute 8', :area_absolute_8, false, "AreaAbs8"],
  ['Include Area Absolute 9', :area_absolute_9, false, "AreaAbs9"],
  ['Include Area Absolute 10', :area_absolute_10, false, "AreaAbs10"],
  ['Include Area Absolute 11', :area_absolute_11, false, "AreaAbs11"],
  ['Include Area Absolute 12', :area_absolute_12, false, "AreaAbs12"],

  # Area Percent Values (1-12) - Explicitly listed
  ['Include Area Percent 1', :area_percent_1, false, "AreaPct1"],
  ['Include Area Percent 2', :area_percent_2, false, "AreaPct2"],
  ['Include Area Percent 3', :area_percent_3, false, "AreaPct3"],
  ['Include Area Percent 4', :area_percent_4, false, "AreaPct4"],
  ['Include Area Percent 5', :area_percent_5, false, "AreaPct5"],
  ['Include Area Percent 6', :area_percent_6, false, "AreaPct6"],
  ['Include Area Percent 7', :area_percent_7, false, "AreaPct7"],
  ['Include Area Percent 8', :area_percent_8, false, "AreaPct8"],
  ['Include Area Percent 9', :area_percent_9, false, "AreaPct9"],
  ['Include Area Percent 10', :area_percent_10, false, "AreaPct10"],
  ['Include Area Percent 11', :area_percent_11, false, "AreaPct11"],
  ['Include Area Percent 12', :area_percent_12, false, "AreaPct12"],

  # User Data and Notes
  ['Include Notes', :notes, false, 'Notes'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'], # Complex

  # User Number (1-10) - Explicitly listed
  ['Include User Number 1', :user_number_1, false, "UserNum1"],
  ['Include User Number 2', :user_number_2, false, "UserNum2"],
  ['Include User Number 3', :user_number_3, false, "UserNum3"],
  ['Include User Number 4', :user_number_4, false, "UserNum4"],
  ['Include User Number 5', :user_number_5, false, "UserNum5"],
  ['Include User Number 6', :user_number_6, false, "UserNum6"],
  ['Include User Number 7', :user_number_7, false, "UserNum7"],
  ['Include User Number 8', :user_number_8, false, "UserNum8"],
  ['Include User Number 9', :user_number_9, false, "UserNum9"],
  ['Include User Number 10', :user_number_10, false, "UserNum10"],

  # User Text (1-10) - Explicitly listed
  ['Include User Text 1', :user_text_1, false, "UserTxt1"],
  ['Include User Text 2', :user_text_2, false, "UserTxt2"],
  ['Include User Text 3', :user_text_3, false, "UserTxt3"],
  ['Include User Text 4', :user_text_4, false, "UserTxt4"],
  ['Include User Text 5', :user_text_5, false, "UserTxt5"],
  ['Include User Text 6', :user_text_6, false, "UserTxt6"],
  ['Include User Text 7', :user_text_7, false, "UserTxt7"],
  ['Include User Text 8', :user_text_8, false, "UserTxt8"],
  ['Include User Text 9', :user_text_9, false, "UserTxt9"],
  ['Include User Text 10', :user_text_10, false, "UserTxt10"]
].freeze # .flatten(1) is no longer needed as the array is already flat


# --- Helper Functions for Statistics ---
def calculate_mean(arr)
  return nil if arr.nil? || arr.empty?
  arr.sum.to_f / arr.length
end

def calculate_std_dev(arr, mean)
  return nil if arr.nil? || arr.empty? || mean.nil? || arr.length < 2
  sum_sq_diff = arr.map { |x| (x - mean)**2 }.sum
  Math.sqrt(sum_sq_diff / (arr.length - 1))
end

# --- Main Script Logic ---

begin
  # Get the current network
  cn = WSApplication.current_network
  raise "No network loaded. Please open a network before running the script." if cn.nil?
rescue NameError => e
  puts "ERROR: WSApplication not found. Are you running this script within the application environment (e.g., InfoWorks ICM)?"
  puts "Details: #{e.message}"
  exit
rescue => e
  puts "ERROR: Could not get current network."
  puts "Details: #{e.class} - #{e.message}"
  exit
end

# --- Optional Debugging Block ---
# sc_example = cn.row_objects('hw_subcatchment').first 
# if sc_example
#   puts "--- DEBUG: Available methods for the first 'hw_subcatchment' object ---"
#   puts sc_example.methods.sort.inspect 
#   if sc_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'hw_subcatchment' object ---"
#      puts sc_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit 
# else
#   puts "DEBUG: No 'hw_subcatchment' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false],
  ['Calculate Statistics for Numeric Fields', 'Boolean', false] # New option
]
FIELDS_TO_EXPORT.each do |field_config|
  # Corrected check for valid field_config structure
  if field_config.is_a?(Array) && field_config.length >= 3 && field_config[0].is_a?(String) && (field_config[2].is_a?(TrueClass) || field_config[2].is_a?(FalseClass))
    prompt_options << [field_config[0], 'Boolean', field_config[2]]
  else
    puts "Warning: Skipping invalid entry in FIELDS_TO_EXPORT when building prompt: #{field_config.inspect}"
  end
end

options = WSApplication.prompt("Select options for CSV export of SELECTED 'hw_subcatchment' Objects", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for 'hw_subcatchment' export at #{Time.now}"
start_time = Time.now

export_folder = options[0]
select_all_state = options[1]
calculate_stats = options[2] # Get state of the new checkbox

unless export_folder && !export_folder.empty?
  puts "ERROR: Export folder not specified. Exiting."
  exit
end

begin
  Dir.mkdir(export_folder) unless Dir.exist?(export_folder)
rescue Errno::EACCES => e
  puts "ERROR: Permission denied creating directory '#{export_folder}'. Check permissions. - #{e.message}"
  exit
rescue => e
  puts "ERROR: Could not create directory '#{export_folder}'. - #{e.message}"
  exit
end
timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
file_path = File.join(export_folder, "selected_hw_subcatchments_export_#{timestamp}.csv")

selected_fields_config = []
header = []
field_option_start_index = 3 
FIELDS_TO_EXPORT.each_with_index do |field_config, index|
  unless field_config.is_a?(Array) && field_config.length >= 4
    puts "Warning: Skipping invalid field_config during header/selection setup: #{field_config.inspect}"
    next
  end
  individual_field_selected = options[index + field_option_start_index]
  if select_all_state || individual_field_selected
    selected_fields_config << { attribute: field_config[1], header: field_config[3], original_label: field_config[0] }
    header << field_config[3]
  end
end

if selected_fields_config.empty?
  puts "No fields selected for export. Exiting."
  exit
end

subcatchments_iterated_count = 0
subcatchments_written_count = 0
numeric_data_for_stats = {} # To store numeric data

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing 'hw_subcatchment' objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('hw_subcatchment') 
    raise "Failed to retrieve 'hw_subcatchment' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |sc_obj| 
      subcatchments_iterated_count += 1
      current_sc_id_for_log = "UNKNOWN_SC_ID_ITER_#{subcatchments_iterated_count}"
      if sc_obj.respond_to?(:subcatchment_id) && sc_obj.subcatchment_id
        current_sc_id_for_log = sc_obj.subcatchment_id.to_s
      elsif sc_obj.respond_to?(:id) && sc_obj.id 
        current_sc_id_for_log = sc_obj.id.to_s
      end

      if sc_obj && sc_obj.respond_to?(:selected) && sc_obj.selected
        subcatchments_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          value_for_csv = ""
          value_for_stats = nil
          begin
            raw_value = sc_obj.send(attr_sym)
            
            if raw_value.is_a?(Array)
              case attr_sym
              when :lateral_links
                value_for_csv = raw_value.map { |ll|
                  node_id = ll.is_a?(Hash) ? (ll[:node_id] || ll['node_id']) : (ll.respond_to?(:node_id) ? ll.node_id : '')
                  suffix = ll.is_a?(Hash) ? (ll[:link_suffix] || ll['link_suffix']) : (ll.respond_to?(:link_suffix) ? ll.link_suffix : '')
                  weight = ll.is_a?(Hash) ? (ll[:weight] || ll['weight']) : (ll.respond_to?(:weight) ? ll.weight : '')
                  "#{node_id.to_s.gsub(/[;,]/, '')},#{suffix.to_s.gsub(/[;,]/, '')},#{weight.to_s.gsub(/[;,]/, '')}"
                }.join(';')
              when :boundary_array
                 value_for_csv = raw_value.map { |pt|
                  x_val = pt.is_a?(Hash) ? (pt[:x] || pt['x']) : (pt.respond_to?(:x) ? pt.x : 'N/A')
                  y_val = pt.is_a?(Hash) ? (pt[:y] || pt['y']) : (pt.respond_to?(:y) ? pt.y : 'N/A')
                  "#{x_val.to_s.gsub(/[;,]/, '')},#{y_val.to_s.gsub(/[;,]/, '')}"
                }.join(';')
              when :suds_controls
                value_for_csv = raw_value.map { |suds|
                  id_val = suds.is_a?(Hash) ? (suds[:id] || suds['id']) : (suds.respond_to?(:id) ? suds.id : '')
                  suds_structure = suds.is_a?(Hash) ? (suds[:suds_structure] || suds['suds_structure']) : (suds.respond_to?(:suds_structure) ? suds.suds_structure : '')
                  control_type = suds.is_a?(Hash) ? (suds[:control_type] || suds['control_type']) : (suds.respond_to?(:control_type) ? suds.control_type : '')
                  area_val = suds.is_a?(Hash) ? (suds[:area] || suds['area']) : (suds.respond_to?(:area) ? suds.area : '')
                  num_units = suds.is_a?(Hash) ? (suds[:num_units] || suds['num_units']) : (suds.respond_to?(:num_units) ? suds.num_units : '')
                  [id_val, suds_structure, control_type, area_val, num_units].map { |v| v.to_s.gsub(/[;,]/, '') }.join(',')
                }.join('||') # Using double pipe to separate SUDS controls
              when :swmm_coverage
                value_for_csv = raw_value.map { |swmm|
                  land_use = swmm.is_a?(Hash) ? (swmm[:land_use] || swmm['land_use']) : (swmm.respond_to?(:land_use) ? swmm.land_use : '')
                  area_val = swmm.is_a?(Hash) ? (swmm[:area] || swmm['area']) : (swmm.respond_to?(:area) ? swmm.area : '')
                  "#{land_use.to_s.gsub(/[;,]/, '')},#{area_val.to_s.gsub(/[;,]/, '')}"
                }.join(';')
              when :hyperlinks 
                value_for_csv = raw_value.map { |hl|
                  desc = hl.is_a?(Hash) ? (hl[:description] || hl['description']) : (hl.respond_to?(:description) ? hl.description : '')
                  url = hl.is_a?(Hash) ? (hl[:url] || hl['url']) : (hl.respond_to?(:url) ? hl.url : '')
                  "#{desc.to_s.gsub(/[;,]/, '')},#{url.to_s.gsub(/[;,]/, '')}"
                }.join(';')
              else
                value_for_csv = raw_value.map{|item| item.to_s.gsub(/[;,]/, '')}.join(', ')
              end
            elsif attr_sym == :refh_descriptors && raw_value 
              if raw_value.is_a?(Hash)
                value_for_csv = raw_value.map { |k, v_item| "#{k.to_s.gsub(/[;:,]/, '')}:#{v_item.to_s.gsub(/[;:,]/, '')}" }.join(';')
              elsif raw_value.respond_to?(:methods) 
                value_for_csv = raw_value.to_s.gsub(/[;\n]/, ' ') 
              else
                value_for_csv = (raw_value.nil? ? "" : raw_value.to_s.gsub(/[;\n]/, ' '))
              end
            else
              value_for_csv = (raw_value.nil? ? "" : raw_value)
              if calculate_stats && !raw_value.nil? && raw_value.to_s != ""
                begin
                  if raw_value.is_a?(TrueClass)
                    value_for_stats = 1.0
                  elsif raw_value.is_a?(FalseClass)
                    value_for_stats = 0.0
                  else
                    value_for_stats = Float(raw_value)
                  end
                rescue ArgumentError, TypeError
                  # Not a number
                end
              end
            end
            row_data << value_for_csv

            if calculate_stats && !value_for_stats.nil?
              numeric_data_for_stats[attr_sym] ||= []
              numeric_data_for_stats[attr_sym] << value_for_stats
            end

          rescue NoMethodError
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for 'hw_subcatchment' '#{current_sc_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for 'hw_subcatchment' '#{current_sc_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv << row_data
      end # if sc_obj selected
    end # cn.row_objects.each
  end # CSV.open block

  puts "\n--- Processing Summary (hw_subcatchment) ---"
  puts "Total 'hw_subcatchment' objects iterated in network: #{subcatchments_iterated_count}"
  if subcatchments_written_count > 0
    puts "Successfully wrote #{subcatchments_written_count} selected 'hw_subcatchment' objects to #{file_path}"
  else
    puts "No 'hw_subcatchment' objects were selected or matched criteria for export."
    if File.exist?(file_path)
      header_line_content_size = header.empty? ? 0 : CSV.generate_line(header).bytesize
      newline_size = (RUBY_PLATFORM =~ /mswin|mingw|cygwin/ ? 2 : 1) 
      header_only_file_size = header_line_content_size + (header.empty? ? 0 : newline_size)

      if File.size(file_path) <= header_only_file_size
        line_count_in_file = 0
        begin; line_count_in_file = File.foreach(file_path).count; rescue; end
        if line_count_in_file <= (header.empty? ? 0 : 1)
            puts "Deleting CSV file as it's empty or contains only the header: #{file_path}"
            File.delete(file_path)
        end
      end
    end
  end
  
  if calculate_stats && subcatchments_written_count > 0
    puts "\n--- Statistics for Exported Numeric Fields (hw_subcatchment) ---"
    param_col_width = 35 
    count_col_width = 8
    min_col_width = 12
    max_col_width = 12
    mean_col_width = 15
    std_dev_col_width = 15
    total_width = param_col_width + count_col_width + min_col_width + max_col_width + mean_col_width + std_dev_col_width + (6 * 3) # 6 columns, 7 separators " | "

    puts "-" * total_width
    puts "| %-#{param_col_width}s | %-#{count_col_width}s | %-#{min_col_width}s | %-#{max_col_width}s | %-#{mean_col_width}s | %-#{std_dev_col_width}s |" % 
         ["Parameter (Header)", "Count", "Min", "Max", "Mean", "Std Dev"]
    puts "-" * total_width
    
    found_numeric_data_for_table = false
    selected_fields_config.each do |field_info|
      attr_sym = field_info[:attribute]
      data_array = numeric_data_for_stats[attr_sym]

      non_numeric_symbols = [
        :subcatchment_id, :system_type, :drains_to, :node_id, :link_suffix, 
        :to_subcatchment_id, :_2d_pt_id, :area_measurement_type, :lateral_links, 
        :refh_descriptors, :suds_controls, :swmm_coverage, :exceed_flow_type, 
        :ukwir_soil_runoff, :soil_class_type, :soil_class, :soil_class_host, 
        :rainfall_profile, :evaporation_profile, :area_average_rain, # area_average_rain can be boolean
        :unit_hydrograph_id, :uh_definition, :tc_method, :non_linear_routing_method, 
        :lag_time_method, :internal_routing, :arma_id, :wastewater_profile, 
        :trade_profile, :ground_id, :ground_node, :baseflow_calc, :land_use_id, 
        :pdm_descriptor_id, :snow_pack_id, :notes, :hyperlinks, :boundary_array
      ]
      
      is_likely_text_or_id = field_info[:header].downcase.include?('id') ||
                              field_info[:header].downcase.include?('type') ||
                              field_info[:header].downcase.include?('profile') ||
                              field_info[:header].downcase.include?('method') ||
                              field_info[:header].downcase.include?('desc') || # for descriptors
                              field_info[:header].downcase.include?('array') ||
                              field_info[:header].downcase.include?('links') ||
                              field_info[:header].downcase.include?('ctrl') || # for suds_controls
                              field_info[:header].downcase.include?('cov') || # for swmm_coverage
                              field_info[:header].downcase.include?('def') || # for uh_definition
                              non_numeric_symbols.include?(attr_sym)

      if data_array && !data_array.empty? && !is_likely_text_or_id
        found_numeric_data_for_table = true
        count_val = data_array.length
        min_val = data_array.min
        max_val = data_array.max
        mean_val = calculate_mean(data_array)
        std_dev_val = calculate_std_dev(data_array, mean_val)
        display_header = field_info[:header].length > param_col_width ? field_info[:header][0...(param_col_width-3)] + "..." : field_info[:header]

        puts "| %-#{param_col_width}s | %-#{count_col_width}d | %-#{min_col_width}.3f | %-#{max_col_width}.3f | %-#{mean_col_width}.3f | %-#{std_dev_col_width}s |" % [
          display_header,
          count_val, 
          min_val, 
          max_val, 
          mean_val,
          (std_dev_val.nil? ? "N/A (n<2)" : "%.3f" % std_dev_val)
        ]
      end
    end
    puts "-" * total_width
    unless found_numeric_data_for_table
        puts "No suitable numeric data found among selected fields to calculate statistics."
    end
  elsif calculate_stats
    puts "\nNo subcatchments were written to the CSV, so no statistics calculated."
  end

rescue Errno::EACCES => e
  puts "FATAL ERROR: Permission denied writing to file '#{file_path}'. - #{e.message}"
rescue Errno::ENOSPC => e
  puts "FATAL ERROR: No space left on device writing to file '#{file_path}'. - #{e.message}"
rescue CSV::MalformedCSVError => e
  puts "FATAL ERROR: CSV formatting issue during write to '#{file_path}'. - #{e.message}"
rescue => e
  puts "FATAL ERROR: Unexpected failure during 'hw_subcatchment' CSV export. - #{e.class}: #{e.message}"
  puts "Backtrace (first 5 lines):\n#{e.backtrace.first(5).join("\n")}"
end

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for 'hw_subcatchment' export finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && subcatchments_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected Subcatchments Written', 'NUMBER', subcatchments_written_count],
    ['Number of Fields Exported Per Subcatchment', 'NUMBER', selected_fields_config.count]
  ]
  WSApplication.prompt("Export Summary (Selected 'hw_subcatchment' Objects)", summary_layout, false)
elsif subcatchments_written_count == 0 && subcatchments_iterated_count >= 0
  message = "No 'hw_subcatchment' objects were selected for export."
  message += " The CSV file was not created or was empty (and thus deleted)." if !file_path.empty? && !File.exist?(file_path)
  WSApplication.message_box(message,  'OK',nil,false) 
else
  WSApplication.message_box("Export for 'hw_subcatchment' did not complete as expected. No subcatchments written. Check console messages. The CSV file may not exist or is empty.",'OK',nil,false) 
end

puts "\nScript execution for 'hw_subcatchment' complete."
