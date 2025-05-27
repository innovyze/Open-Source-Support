require 'csv'
require 'fileutils'

# --- Configuration: Define hw_subcatchment Fields (excluding top-level flags) ---
# IMPORTANT: The symbols MUST match the actual method names available on
# 'hw_subcatchment' objects in your environment.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names.
FIELDS_TO_EXPORT = [
  # Key Identifiers & Coordinates
  ['Include Subcatchment ID', :subcatchment_id, true, 'Subcatchment ID'],
  ['Include X Coordinate', :x, true, 'X Coordinate'],
  ['Include Y Coordinate', :y, true, 'Y Coordinate'],

  # Basic Properties
  ['Include System Type', :system_type, false, 'System Type'],
  ['Include Drains To', :drains_to, false, 'Drains To Node'],
  ['Include Outlet Node ID', :node_id, false, 'Outlet Node ID'],
  ['Include Outlet Link Suffix', :link_suffix, false, 'Outlet Link Suffix'],
  ['Include To Subcatchment ID', :to_subcatchment_id, false, 'To Subcatchment ID'],
  ['Include 2D Point ID', :_2d_pt_id, false, '2D Point ID'],

  # Area and Geometry
  ['Include Total Area', :total_area, true, 'Total Area'],
  ['Include Contributing Area', :contributing_area, true, 'Contributing Area'],
  ['Include Boundary Array', :boundary_array, false, 'Boundary Array (X1,Y1;X2,Y2;...)'],
  ['Include Catchment Slope', :catchment_slope, false, 'Catchment Slope'],
  ['Include Catchment Dimension', :catchment_dimension, false, 'Catchment Dimension'],
  ['Include Area Measurement Type', :area_measurement_type, false, 'Area Measurement Type'],

  # Lateral Links & Weights
  ['Include Lateral Links', :lateral_links, false, 'Lateral Links (NodeID,Suffix,Weight;...)'],
  ['Include Lateral Weights', :lateral_weights, false, 'Lateral Weights'],

  # ReFH Descriptors (serialized into one field)
  ['Include ReFH Descriptors', :refh_descriptors, false, 'ReFH Descriptors (Key:Val;...)'],

  # SUDS Controls (serialized array of objects)
  ['Include SUDS Controls', :suds_controls, false, 'SUDS Controls (ID,Struct,Type,Area...;...)'],

  # SWMM Coverage (serialized array of objects)
  ['Include SWMM Coverage', :swmm_coverage, false, 'SWMM Coverage (LandUse,Area;...)'],

  # Flow and Capacity
  ['Include Capacity Limit', :capacity_limit, false, 'Capacity Limit'],
  ['Include Exceed Flow Type', :exceed_flow_type, false, 'Exceed Flow Type'],

  # Soil and Runoff Parameters
  ['Include UKWIR Soil Runoff', :ukwir_soil_runoff, false, 'UKWIR Soil Runoff Code'],
  ['Include Soil Class Type', :soil_class_type, false, 'Soil Class Type'],
  ['Include Soil Class', :soil_class, false, 'Soil Class'],
  ['Include Soil Class HOST', :soil_class_host, false, 'Soil Class HOST'],
  ['Include Max Soil Moisture Capacity', :max_soil_moisture_capacity, false, 'Max Soil Moisture Capacity'],
  ['Include Curve Number (SCS)', :curve_number, false, 'Curve Number (SCS)'],
  ['Include Drying Time (SCS)', :drying_time, false, 'Drying Time (SCS)'],
  ['Include Soil Moisture Deficit', :soil_moist_def, false, 'Initial Soil Moisture Deficit'],

  # Rainfall and Evaporation
  ['Include Rainfall Profile', :rainfall_profile, false, 'Rainfall Profile'],
  ['Include Evaporation Profile', :evaporation_profile, false, 'Evaporation Profile'],
  ['Include Area Average Rain', :area_average_rain, false, 'Area Average Rain Flag/Value'],

  # Unit Hydrograph and Routing Parameters
  ['Include Unit Hydrograph ID', :unit_hydrograph_id, false, 'Unit Hydrograph ID'],
  ['Include UH Definition', :uh_definition, false, 'UH Definition Model'],
  ['Include Time of Concentration Method', :tc_method, false, 'TC Method'],
  ['Include Time of Concentration', :time_of_concentration, false, 'Time of Concentration'],
  ['Include Overland Flow Time', :overland_flow_time, false, 'Overland Flow Time (kinematic wave)'],
  ['Include Flood Wave Celerity', :flood_wave_celerity, false, 'Flood Wave Celerity (kinematic wave)'],
  ['Include Equivalent Roughness', :equivalent_roughness, false, 'Equivalent Roughness (kinematic wave)'],
  ['Include Hydraulic Radius', :hydraulic_radius, false, 'Hydraulic Radius (kinematic wave)'],
  ['Include PWRI Coefficient', :pwri_coefficient, false, 'PWRI Coefficient'],
  ['Include TC Timestep Factor', :tc_timestep_factor, false, 'TC Timestep Factor'],
  ['Include TC Time to Peak Factor', :tc_time_to_peak_factor, false, 'TC Time to Peak Factor'],
  ['Include Time to Peak', :time_to_peak, false, 'Time to Peak (UH)'],
  ['Include Base Time', :base_time, false, 'Base Time (UH)'],
  ['Include Lag Time (Snyder/User)', :lag_time, false, 'Lag Time (Snyder/User)'],
  ['Include Peaking Coefficient (Snyder)', :peaking_coeff, false, 'Peaking Coefficient (Snyder)'],
  ['Include UH Peak (User Defined)', :uh_peak, false, 'UH Peak (User Defined)'],
  ['Include UH Kink (User Defined)', :uh_kink, false, 'UH Kink (User Defined)'],
  ['Include Non-linear Routing Method', :non_linear_routing_method, false, 'Non-linear Routing Method'],
  ['Include Lag Time Method (Non-linear)', :lag_time_method, false, 'Lag Time Method (Non-linear)'],
  ['Include Storage Factor (Non-linear)', :storage_factor, false, 'Storage Factor (Non-linear)'],
  ['Include Storage Exponent (Non-linear)', :storage_exponent, false, 'Storage Exponent (Non-linear)'],
  ['Include Internal Routing Model', :internal_routing, false, 'Internal Routing Model'],
  ['Include Percent Routed', :percent_routed, false, 'Percent Routed (Pervious Area)'],

  # SRM Model Parameters
  ['Include SRM Runoff Coefficient', :srm_runoff_coeff, false, 'SRM Runoff Coefficient'],
  ['Include SRM K1', :srm_k1, false, 'SRM K1'],
  ['Include SRM K2', :srm_k2, false, 'SRM K2'],
  ['Include SRM TDLY', :srm_tdly, false, 'SRM TDLY'],

  # ARMA Model
  ['Include ARMA ID', :arma_id, false, 'ARMA ID'],
  ['Include Output Lag (ARMA)', :output_lag, false, 'Output Lag (ARMA)'],
  ['Include Bypass Runoff (ARMA)', :bypass_runoff, false, 'Bypass Runoff (ARMA)'],

  # RAFTS Model Parameters
  ['Include RAFTS Per Surface', :rafts_per_surface, false, 'RAFTS Per Surface (No. of Storages)'],
  ['Include Degree of Urbanisation (RAFTS)', :degree_urbanisation, false, 'Degree of Urbanisation (RAFTS)'],
  ['Include RAFTS Adapt Factor', :rafts_adapt_factor, false, 'RAFTS Adapt Factor'],
  ['Include RAFTS B (Storage Coeff)', :rafts_b, false, 'RAFTS B (Storage Coeff)'],
  ['Include RAFTS N (Non-linearity Exp)', :rafts_n, false, 'RAFTS N (Non-linearity Exp)'],
  ['Include Connectivity (RAFTS)', :connectivity, false, 'Connectivity (RAFTS)'],

  # Wastewater and Baseflow
  ['Include Wastewater Profile', :wastewater_profile, false, 'Wastewater Profile ID'],
  ['Include Population', :population, false, 'Population'],
  ['Include Trade Flow', :trade_flow, false, 'Trade Flow'],
  ['Include Additional Foul Flow', :additional_foul_flow, false, 'Additional Foul Flow'],
  ['Include Base Flow (Wastewater)', :base_flow, false, 'Base Flow (Wastewater)'],
  ['Include Trade Profile ID', :trade_profile, false, 'Trade Profile ID'],

  # Groundwater Interaction
  ['Include Ground ID (Aquifer)', :ground_id, false, 'Ground ID (Aquifer)'],
  ['Include Ground Node (Aquifer Connection)', :ground_node, false, 'Ground Node (Aquifer Connection)'],
  ['Include Baseflow Lag (Groundwater)', :baseflow_lag, false, 'Baseflow Lag (Groundwater)'],
  ['Include Baseflow Recharge Rate (Groundwater)', :baseflow_recharge, false, 'Baseflow Recharge Rate (Groundwater)'],
  ['Include Baseflow Calculation Type', :baseflow_calc, false, 'Baseflow Calculation Type'],

  # Land Use and PDM
  ['Include Land Use ID', :land_use_id, false, 'Land Use ID'],
  ['Include PDM Descriptor ID', :pdm_descriptor_id, false, 'PDM Descriptor ID'],

  # Snow Pack
  ['Include Snow Pack ID', :snow_pack_id, false, 'Snow Pack ID'],

  # Area Absolute Values (1-12) - Explicitly listed
  ['Include Area Absolute 1', :area_absolute_1, false, 'Area Absolute 1'],
  ['Include Area Absolute 2', :area_absolute_2, false, 'Area Absolute 2'],
  ['Include Area Absolute 3', :area_absolute_3, false, 'Area Absolute 3'],
  ['Include Area Absolute 4', :area_absolute_4, false, 'Area Absolute 4'],
  ['Include Area Absolute 5', :area_absolute_5, false, 'Area Absolute 5'],
  ['Include Area Absolute 6', :area_absolute_6, false, 'Area Absolute 6'],
  ['Include Area Absolute 7', :area_absolute_7, false, 'Area Absolute 7'],
  ['Include Area Absolute 8', :area_absolute_8, false, 'Area Absolute 8'],
  ['Include Area Absolute 9', :area_absolute_9, false, 'Area Absolute 9'],
  ['Include Area Absolute 10', :area_absolute_10, false, 'Area Absolute 10'],
  ['Include Area Absolute 11', :area_absolute_11, false, 'Area Absolute 11'],
  ['Include Area Absolute 12', :area_absolute_12, false, 'Area Absolute 12'],

  # Area Percent Values (1-12) - Explicitly listed
  ['Include Area Percent 1', :area_percent_1, false, 'Area Percent 1'],
  ['Include Area Percent 2', :area_percent_2, false, 'Area Percent 2'],
  ['Include Area Percent 3', :area_percent_3, false, 'Area Percent 3'],
  ['Include Area Percent 4', :area_percent_4, false, 'Area Percent 4'],
  ['Include Area Percent 5', :area_percent_5, false, 'Area Percent 5'],
  ['Include Area Percent 6', :area_percent_6, false, 'Area Percent 6'],
  ['Include Area Percent 7', :area_percent_7, false, 'Area Percent 7'],
  ['Include Area Percent 8', :area_percent_8, false, 'Area Percent 8'],
  ['Include Area Percent 9', :area_percent_9, false, 'Area Percent 9'],
  ['Include Area Percent 10', :area_percent_10, false, 'Area Percent 10'],
  ['Include Area Percent 11', :area_percent_11, false, 'Area Percent 11'],
  ['Include Area Percent 12', :area_percent_12, false, 'Area Percent 12'],

  # User Number (1-10) - Explicitly listed
  ['Include User Number 1', :user_number_1, false, 'User Number 1'],
  ['Include User Number 2', :user_number_2, false, 'User Number 2'],
  ['Include User Number 3', :user_number_3, false, 'User Number 3'],
  ['Include User Number 4', :user_number_4, false, 'User Number 4'],
  ['Include User Number 5', :user_number_5, false, 'User Number 5'],
  ['Include User Number 6', :user_number_6, false, 'User Number 6'],
  ['Include User Number 7', :user_number_7, false, 'User Number 7'],
  ['Include User Number 8', :user_number_8, false, 'User Number 8'],
  ['Include User Number 9', :user_number_9, false, 'User Number 9'],
  ['Include User Number 10', :user_number_10, false, 'User Number 10'],

  # User Text (1-10) - Explicitly listed
  ['Include User Text 1', :user_text_1, false, 'User Text 1'],
  ['Include User Text 2', :user_text_2, false, 'User Text 2'],
  ['Include User Text 3', :user_text_3, false, 'User Text 3'],
  ['Include User Text 4', :user_text_4, false, 'User Text 4'],
  ['Include User Text 5', :user_text_5, false, 'User Text 5'],
  ['Include User Text 6', :user_text_6, false, 'User Text 6'],
  ['Include User Text 7', :user_text_7, false, 'User Text 7'],
  ['Include User Text 8', :user_text_8, false, 'User Text 8'],
  ['Include User Text 9', :user_text_9, false, 'User Text 9'],
  ['Include User Text 10', :user_text_10, false, 'User Text 10']
].freeze

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
# Uncomment the following lines to print available methods for the first 'hw_subcatchment' object.
# This helps verify the symbols used in FIELDS_TO_EXPORT.
# ---
# sc_example = cn.row_objects('hw_subcatchment').first # Target 'hw_subcatchment'
# if sc_example
#   puts "--- DEBUG: Available methods for the first 'hw_subcatchment' object ---"
#   puts sc_example.methods.sort.inspect # Print sorted methods
#   if sc_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'hw_subcatchment' object ---"
#      puts sc_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit # Uncomment to stop after debugging
# else
#   puts "DEBUG: No 'hw_subcatchment' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false]
]
FIELDS_TO_EXPORT.each do |field_config|
  prompt_options << [field_config[0], 'Boolean', field_config[2]]
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
FIELDS_TO_EXPORT.each_with_index do |field_config, index|
  individual_field_selected = options[index + 2] # First two options are folder and select_all
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

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing 'hw_subcatchment' objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('hw_subcatchment') # Target 'hw_subcatchment'
    raise "Failed to retrieve 'hw_subcatchment' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |sc_obj| # Renamed loop variable
      subcatchments_iterated_count += 1
      current_sc_id_for_log = "UNKNOWN_SC_ID_ITER_#{subcatchments_iterated_count}"
      # Try to get a meaningful ID for the subcatchment
      if sc_obj.respond_to?(:subcatchment_id) && sc_obj.subcatchment_id
        current_sc_id_for_log = sc_obj.subcatchment_id.to_s
      elsif sc_obj.respond_to?(:id) && sc_obj.id # Generic fallback
        current_sc_id_for_log = sc_obj.id.to_s
      end

      if sc_obj && sc_obj.respond_to?(:selected) && sc_obj.selected
        subcatchments_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          begin
            value = sc_obj.send(attr_sym)
            
            # Special handling for complex array/object fields for hw_subcatchment
            if value.is_a?(Array) && attr_sym == :lateral_links
              row_data << value.map { |ll|
                node_id = ll.is_a?(Hash) ? (ll[:node_id] || ll['node_id']) : (ll.respond_to?(:node_id) ? ll.node_id : '')
                suffix = ll.is_a?(Hash) ? (ll[:link_suffix] || ll['link_suffix']) : (ll.respond_to?(:link_suffix) ? ll.link_suffix : '')
                weight = ll.is_a?(Hash) ? (ll[:weight] || ll['weight']) : (ll.respond_to?(:weight) ? ll.weight : '')
                "#{node_id.to_s.gsub(/[;,]/, '')},#{suffix.to_s.gsub(/[;,]/, '')},#{weight.to_s.gsub(/[;,]/, '')}"
              }.join(';')
            elsif value.is_a?(Array) && attr_sym == :boundary_array
               row_data << value.map { |pt|
                x_val = pt.is_a?(Hash) ? (pt[:x] || pt['x']) : (pt.respond_to?(:x) ? pt.x : 'N/A')
                y_val = pt.is_a?(Hash) ? (pt[:y] || pt['y']) : (pt.respond_to?(:y) ? pt.y : 'N/A')
                "#{x_val.to_s.gsub(/[;,]/, '')},#{y_val.to_s.gsub(/[;,]/, '')}"
              }.join(';')
            elsif value.is_a?(Array) && attr_sym == :suds_controls
              row_data << value.map { |suds|
                id = suds.is_a?(Hash) ? (suds[:id] || suds['id']) : (suds.respond_to?(:id) ? suds.id : '')
                suds_structure = suds.is_a?(Hash) ? (suds[:suds_structure] || suds['suds_structure']) : (suds.respond_to?(:suds_structure) ? suds.suds_structure : '')
                control_type = suds.is_a?(Hash) ? (suds[:control_type] || suds['control_type']) : (suds.respond_to?(:control_type) ? suds.control_type : '')
                area = suds.is_a?(Hash) ? (suds[:area] || suds['area']) : (suds.respond_to?(:area) ? suds.area : '')
                num_units = suds.is_a?(Hash) ? (suds[:num_units] || suds['num_units']) : (suds.respond_to?(:num_units) ? suds.num_units : '')
                [id, suds_structure, control_type, area, num_units].map { |v| v.to_s.gsub(/[;,]/, '') }.join(',')
              }.join(';')
            elsif value.is_a?(Array) && attr_sym == :swmm_coverage
              row_data << value.map { |swmm|
                land_use = swmm.is_a?(Hash) ? (swmm[:land_use] || swmm['land_use']) : (swmm.respond_to?(:land_use) ? swmm.land_use : '')
                area = swmm.is_a?(Hash) ? (swmm[:area] || swmm['area']) : (swmm.respond_to?(:area) ? swmm.area : '')
                "#{land_use.to_s.gsub(/[;,]/, '')},#{area.to_s.gsub(/[;,]/, '')}"
              }.join(';')
            elsif attr_sym == :refh_descriptors && value 
              if value.is_a?(Hash)
                row_data << value.map { |k, v_item| "#{k.to_s.gsub(/[;:,]/, '')}:#{v_item.to_s.gsub(/[;:,]/, '')}" }.join(';')
              elsif value.respond_to?(:methods) 
                row_data << value.to_s.gsub(/[;\n]/, ' ') 
              else
                row_data << (value.nil? ? "" : value.to_s.gsub(/[;\n]/, ' '))
              end
            elsif value.is_a?(Array) && attr_sym == :hyperlinks 
              row_data << value.map { |hl|
                desc = hl.is_a?(Hash) ? (hl[:description] || hl['description']) : (hl.respond_to?(:description) ? hl.description : '')
                url = hl.is_a?(Hash) ? (hl[:url] || hl['url']) : (hl.respond_to?(:url) ? hl.url : '')
                "#{desc.to_s.gsub(/[;,]/, '')},#{url.to_s.gsub(/[;,]/, '')}"
              }.join(';')
            elsif value.is_a?(Array)
              row_data << value.map{|item| item.to_s.gsub(/[;,]/, '')}.join(', ')
            else
              row_data << (value.nil? ? "" : value) 
            end
          rescue NoMethodError
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for selected 'hw_subcatchment' '#{current_sc_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for 'hw_subcatchment' '#{current_sc_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv << row_data
      end 
    end 
  end 

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
puts "\nScript for 'hw_subcatchment' finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && subcatchments_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected Subcatchments Written', 'NUMBER', subcatchments_written_count],
    ['Number of Fields Exported Per Subcatchment', 'NUMBER', selected_fields_config.count]
  ]
  WSApplication.prompt("Export Summary (Selected 'hw_subcatchment' Objects)", summary_layout, false)
elsif subcatchments_written_count == 0 && subcatchments_iterated_count > 0
  WSApplication.message_box("No 'hw_subcatchment' objects were selected for export. The CSV file was not created or was empty (and thus deleted).", 'Info', :OK, false)
else
  WSApplication.message_box("Export for 'hw_subcatchment' did not complete as expected. No subcatchments written. Check console messages. The CSV file may not exist or is empty.", ,'OK',nil,false)
end

puts "\nScript execution for 'hw_subcatchment' complete."