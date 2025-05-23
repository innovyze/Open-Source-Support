require 'csv'
require 'fileutils'

# --- Configuration: Define SWMM Table Structures and Fields ---
#
# For each table, define:
#   :display_name         => User-friendly name for the selection prompt.
#   :fields               => Array of field configurations for export. Each entry:
#                            ['Prompt Label', :attribute_symbol, default_selected_boolean, 'CSV Header Name']
#   :id_field_symbol      => The typical primary ID field symbol for this table (for logging).
#   :singular_item_name   => Singular name of the item (e.g., "Subcatchment").
#   :complex_fields       => A hash mapping attribute symbols of complex array fields
#                            to their expected sub-item structure or serialization type.
#                            Example: :coverages => {type: :array_of_hashes, keys: [:land_use, :area], join_char: ':'}
#                                     :boundary_array => {type: :array_of_points, join_char: ','}
#
# IMPORTANT: The :attribute_symbol in :fields MUST match the actual method names
# available on row objects for that table in your WSApplication environment.
# Use the DEBUGGING BLOCK at the end of the configuration to verify these.
#
SWMM_TABLE_CONFIGS = {
  'sw_options' => {
    display_name: 'SWMM Simulation Options',
    id_field_symbol: :itself, # Options might not have a typical ID
    singular_item_name: 'Option Set',
    complex_fields: {}, # Typically flat fields
    fields: [
      # General Options
      ['Include Flow Units', :units, true, 'Flow Units'], # CFS, GPM, MGD, CMS, LPS, MLD
      ['Include Allow Ponding', :allow_ponding, true, 'Allow Ponding'], # TRUE/FALSE
      ['Include Infiltration Model', :infiltration, true, 'Infiltration Model'], # HORTON, MODIFIED_HORTON, GREEN_AMPT, CURVE_NUMBER
      ['Include Flow Routing Method', :flow_routing, false, 'Flow Routing Method'], # STEADY, KINWAVE, DYNWAVE (often a global setting)
      ['Include Force Main Equation', :force_main_equation, false, 'Force Main Equation'], # H-W or D-W
      ['Include Min Slope (%)', :min_slope, false, 'Min Slope for Conduits (%)'],
      ['Include Min Surface Area (Storage)', :min_surfarea, false, 'Min Surface Area (Storage)'],
      # Dynamic Wave Options
      ['Include Inertial Damping', :inertial_damping, false, 'Inertial Damping'], # NONE, PARTIAL, FULL
      ['Include Normal Flow Limited By', :normal_flow_limited, false, 'Normal Flow Limited By'], # BOTH, SLOPE, FROUDE
      ['Include Head Tolerance', :head_tolerance, false, 'Head Tolerance'],
      ['Include Max Trials Per Timestep', :max_trials, false, 'Max Trials Per Timestep'],
      # Add other options fields as needed from your list, e.g., :start_date, :end_date, :report_step, etc.
      # These are often accessed via cn.network.option_name or similar, not always as a 'row_object'.
      # This script assumes they might be exposed as fields on a single 'options' object.
      # If options are accessed differently, this table's export logic might need specific adaptation.
      ['Include Routing Step (sec)', :routing_step, false, 'Routing Step (sec)'],
      ['Include Report Step (sec)', :report_step, false, 'Report Step (sec)'],
      ['Include Start Date', :start_date, false, 'Simulation Start Date'],
      ['Include Start Time', :start_time, false, 'Simulation Start Time'],
      ['Include End Date', :end_date, false, 'Simulation End Date'],
      ['Include End Time', :end_time, false, 'Simulation End Time']
    ]
  },
  'sw_subcatchment' => {
    display_name: 'SWMM Subcatchments',
    id_field_symbol: :subcatchment_id,
    singular_item_name: 'Subcatchment',
    complex_fields: {
      coverages:      { type: :array_of_hashes, keys: [:land_use, :area], join_char: ':' },
      loadings:       { type: :array_of_hashes, keys: [:pollutant, :build_up], join_char: ':' },
      soil:           { type: :array_of_hashes, keys: [:soil, :area], join_char: ':' }, # Assuming 'soil' is key for soil type
      boundary_array: { type: :array_of_points, item_join_char: ',' },
      suds_controls:  { type: :array_of_hashes_complex, join_char: '||' }, # Needs detailed structure
      hyperlinks:     { type: :array_of_hashes, keys: [:description, :url], join_char: ',' }
    },
    fields: [
      ['Include Subcatchment ID', :subcatchment_id, true, 'Subcatchment ID'],
      ['Include Raingauge ID', :raingauge_id, true, 'Raingauge ID'],
      ['Include Outlet ID', :outlet_id, true, 'Outlet ID'],
      ['Include Area', :area, true, 'Total Area'],
      ['Include X Coordinate', :x, false, 'X Coordinate'],
      ['Include Y Coordinate', :y, false, 'Y Coordinate'],
      ['Include Width', :width, true, 'Characteristic Width'],
      ['Include Slope (%)', :catchment_slope, true, 'Avg. Surface Slope (%)'],
      ['Include Percent Impervious', :percent_impervious, true, '% Impervious'],
      ['Include N-Imperv', :roughness_impervious, true, 'N-Imperv'],
      ['Include N-Perv', :roughness_pervious, true, 'N-Perv'],
      ['Include Dstore-Imperv', :storage_impervious, true, 'Dstore-Imperv'],
      ['Include Dstore-Perv', :storage_pervious, true, 'Dstore-Perv'],
      ['Include %Zero-Imperv', :percent_no_storage, false, '%Zero-Imperv'],
      ['Include Route To', :route_to, false, 'Route To'],
      ['Include % Routed', :percent_routed, false, '% Routed'],
      ['Include Infiltration Model', :infiltration, false, 'Infiltration Model'],
      ['Include Max Infil Rate (Horton)', :initial_infiltration, false, 'Max Infil Rate (Horton)'],
      ['Include Min Infil Rate (Horton)', :limiting_infiltration, false, 'Min Infil Rate (Horton)'],
      ['Include Decay Constant (Horton)', :decay_factor, false, 'Decay Constant (Horton)'],
      ['Include Drying Time (Horton)', :drying_time, false, 'Drying Time (Horton)'],
      ['Include Max Infil Volume (ModHorton)', :max_infiltration_volume, false, 'Max Infil Volume (ModHorton)'],
      ['Include Suction Head (Green-Ampt)', :average_capillary_suction, false, 'Suction Head (GA)'],
      ['Include Conductivity (Green-Ampt)', :saturated_hydraulic_conductivity, false, 'Conductivity (GA)'],
      ['Include Initial Deficit (Green-Ampt)', :initial_moisture_deficit, false, 'Initial Deficit (GA)'],
      ['Include Curve Number (SCS)', :curve_number, false, 'Curve Number (SCS)'],
      ['Include Initial Abstraction Depth (SCS)', :initial_abstraction, false, 'Initial Abstr Depth (SCS)'],
      ['Include Initial Abstraction Factor (SCS)', :initial_abstraction_factor, false, 'Initial Abstr Factor (SCS)'],
      ['Include Initial Abstraction Type (SCS)', :initial_abstraction_type, false, 'Initial Abstr Type (SCS)'],
      ['Include Aquifer ID', :aquifer_id, false, 'Aquifer ID'],
      ['Include Aquifer Node ID', :aquifer_node_id, false, 'Aquifer Node ID'],
      ['Include Aquifer Ground Elevation', :aquifer_elevation, false, 'Aquifer Ground Elev'],
      ['Include Aquifer Initial GW Elev', :aquifer_initial_groundwater, false, 'Aquifer Initial GW Elev'],
      ['Include Aquifer Initial Moisture', :aquifer_initial_moisture_content, false, 'Aquifer Initial Moisture'],
      ['Include GW Coeff (A1)', :groundwater_coefficient, false, 'GW Coeff (A1)'],
      ['Include GW Exponent (B1)', :groundwater_exponent, false, 'GW Exponent (B1)'],
      ['Include GW Threshold Elev/Depth', :groundwater_threshold, false, 'GW Threshold Elev/Depth'],
      ['Include Lateral GW Flow Eq', :lateral_gwf_equation, false, 'Lateral GW Flow Eq'],
      ['Include Deep GW Flow Eq', :deep_gwf_equation, false, 'Deep GW Flow Eq'],
      ['Include Surface GW Coeff (A2)', :surface_coefficient, false, 'Surface GW Coeff (A2)'],
      ['Include Surface GW Depth (Hgs)', :surface_depth, false, 'Surface GW Depth (Hgs)'],
      ['Include Surface GW Exponent (B2)', :surface_exponent, false, 'Surface GW Exponent (B2)'],
      ['Include GW Coeff Upper Zone (A3)', :surface_groundwater_coefficient, false, 'GW Coeff Upper Zone (A3)'],
      ['Include Snow Pack ID', :snow_pack_id, false, 'Snow Pack ID'],
      ['Include Hydraulic Length', :hydraulic_length, false, 'Hydraulic Length'],
      ['Include Area for Avg Rain', :area_average_rain, false, 'Area for Avg Rain'],
      ['Include Curb Length', :curb_length, false, 'Curb Length'],
      ['Include Runoff Model Type', :runoff_model_type, false, 'Runoff Model Type'],
      ['Include Shape Factor', :shape_factor, false, 'Shape Factor'],
      ['Include Time of Concentration', :time_of_concentration, false, 'Time of Concentration'],
      ['Include SW Drains To', :sw_drains_to, false, 'SW Drains To'],
      ['Include Land Use Coverages', :coverages, false, 'Land Use Coverages'],
      ['Include Pollutant Loadings', :loadings, false, 'Pollutant Loadings'],
      ['Include Soil Composition', :soil, false, 'Soil Composition'],
      ['Include Boundary Vertices', :boundary_array, false, 'Boundary Vertices'],
      ['Include SUDS Controls', :suds_controls, false, 'SUDS Controls'],
      ['Include N-Perv Pattern ID', :n_perv_pattern, false, 'N-Perv Pattern ID'],
      ['Include Dstore Pattern ID', :dstore_pattern, false, 'Dstore Pattern ID'],
      ['Include Infiltration Pattern ID', :infil_pattern, false, 'Infiltration Pattern ID'],
      ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
      ['Include Notes', :notes, false, 'Notes'],
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
    ]
  },
  'sw_node' => {
    display_name: 'SWMM Nodes',
    id_field_symbol: :node_id,
    singular_item_name: 'Node',
    complex_fields: {
      treatment:          { type: :array_of_hashes, keys: [:pollutant, :result, :function], join_char: ':' },
      pollutant_inflows:  { type: :array_of_hashes, keys: [:pollutant, :baseline, :pattern_id], join_char: ':' }, # Assuming 'baseline' for conc.
      additional_dwf:     { type: :array_of_hashes, keys: [:baseline, :bf_pattern_1, :bf_pattern_2, :bf_pattern_3, :bf_pattern_4], join_char: ':' }, # Or could be simpler
      pollutant_dwf:      { type: :array_of_hashes, keys: [:pollutant, :baseline, :pattern_id], join_char: ':' }, # Assuming 'baseline' for conc.
      hyperlinks:         { type: :array_of_hashes, keys: [:description, :url], join_char: ',' }
    },
    fields: [
      ['Include Node ID', :node_id, true, 'Node ID'],
      ['Include X Coordinate', :x, true, 'X Coordinate'],
      ['Include Y Coordinate', :y, true, 'Y Coordinate'],
      ['Include Node Type', :node_type, true, 'Node Type'],
      ['Include Ground Level', :ground_level, true, 'Ground Level'],
      ['Include Invert Elevation', :invert_elevation, true, 'Invert Elevation'],
      ['Include Maximum Depth', :maximum_depth, false, 'Maximum Depth'],
      ['Include Initial Depth', :initial_depth, false, 'Initial Depth'],
      ['Include Surcharge Depth', :surcharge_depth, false, 'Surcharge Depth'],
      ['Include Ponded Area', :ponded_area, false, 'Ponded Area'],
      ['Include Route to Subcatchment', :route_subcatchment, false, 'Route to Subcatchment'],
      ['Include Unit Hydrograph ID', :unit_hydrograph_id, false, 'Unit Hydrograph ID'],
      ['Include Unit Hydrograph Area', :unit_hydrograph_area, false, 'Unit Hydrograph Area'],
      ['Include Flood Type', :flood_type, false, 'Flood Type'],
      ['Include Flooding Discharge Coeff', :flooding_discharge_coeff, false, 'Flooding Discharge Coeff'],
      ['Include GW Initial Moisture Deficit', :initial_moisture_deficit, false, 'GW Initial Moisture Deficit'],
      ['Include GW Suction Head', :suction_head, false, 'GW Suction Head'],
      ['Include GW Conductivity', :conductivity, false, 'GW Conductivity'],
      ['Include Evaporation Factor', :evaporation_factor, false, 'Evaporation Factor'],
      ['Include Outfall Type', :outfall_type, false, 'Outfall Type'],
      ['Include Outfall Fixed Stage', :fixed_stage, false, 'Outfall Fixed Stage'],
      ['Include Outfall Tidal Curve ID', :tidal_curve_id, false, 'Outfall Tidal Curve ID'],
      ['Include Outfall Flap Gate', :flap_gate, false, 'Outfall Flap Gate'],
      ['Include Storage Type', :storage_type, false, 'Storage Type'],
      ['Include Storage Curve ID', :storage_curve, false, 'Storage Curve ID'],
      ['Include Storage Functional Coeff (A)', :functional_coefficient, false, 'Storage Funct Coeff (A)'],
      ['Include Storage Functional Exponent (B)', :functional_exponent, false, 'Storage Funct Exp (B)'],
      ['Include Storage Functional Constant (C)', :functional_constant, false, 'Storage Funct Const (C)'],
      ['Include Inflow Baseline (Direct)', :inflow_baseline, false, 'Inflow Baseline (Direct)'],
      ['Include Inflow Scaling Factor (Direct)', :inflow_scaling, false, 'Inflow Scaling (Direct)'],
      ['Include Inflow Pattern ID (Direct)', :inflow_pattern, false, 'Inflow Pattern (Direct)'],
      ['Include Base DWF Flow', :base_flow, false, 'Base DWF Flow'],
      ['Include DWF Pattern 1', :bf_pattern_1, false, 'DWF Pattern 1'],
      ['Include DWF Pattern 2', :bf_pattern_2, false, 'DWF Pattern 2'],
      ['Include DWF Pattern 3', :bf_pattern_3, false, 'DWF Pattern 3'],
      ['Include DWF Pattern 4', :bf_pattern_4, false, 'DWF Pattern 4'],
      ['Include Additional DWF', :additional_dwf, false, 'Additional DWF'],
      ['Include Treatment Expressions', :treatment, false, 'Treatment Expressions'],
      ['Include Pollutant Inflows', :pollutant_inflows, false, 'Pollutant Inflows'],
      ['Include Pollutant DWF', :pollutant_dwf, false, 'Pollutant DWF'],
      ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
      ['Include Notes', :notes, false, 'Notes'],
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
    ]
  },
  'sw_conduit' => {
    display_name: 'SWMM Conduits',
    id_field_symbol: :id,
    singular_item_name: 'Conduit',
    complex_fields: {
      point_array: { type: :array_of_points, item_join_char: ',' },
      hyperlinks:  { type: :array_of_hashes, keys: [:description, :url], join_char: ',' }
    },
    fields: [
      ['Include Conduit ID', :id, true, 'Conduit ID'],
      ['Include US Node ID', :us_node_id, true, 'US Node ID'],
      ['Include DS Node ID', :ds_node_id, true, 'DS Node ID'],
      ['Include Length', :length, true, 'Length'],
      ['Include Shape', :shape, true, 'Shape'],
      ['Include Geom1 (Height/Diameter)', :conduit_height, true, 'Geom1 (Height/Diam)'], # SWMM uses Geom1, Geom2, etc.
      ['Include Geom2 (Width)', :conduit_width, true, 'Geom2 (Width)'],
      ['Include Geom3 (e.g., Side Slopes)', :geom3, false, 'Geom3'], # Placeholder, check API
      ['Include Geom4 (e.g., Top Radius)', :geom4, false, 'Geom4'], # Placeholder, check API
      ['Include Barrels', :number_of_barrels, false, 'Barrels'],
      ['Include Manning\'s N', :Mannings_N, true, 'Manning\'s N'],
      ['Include N_Var (Bottom N)', :bottom_mannings_N, false, 'N_Var (Bottom N)'],
      ['Include D_Var (Depth Threshold for N_Var)', :roughness_depth_threshold, false, 'D_Var (N_Var Depth)'],
      ['Include US Invert Elev', :us_invert, false, 'US Invert Elev'],
      ['Include DS Invert Elev', :ds_invert, false, 'DS Invert Elev'],
      ['Include Entry Loss Coeff (Ke)', :us_headloss_coeff, false, 'Entry Loss (Ke)'],
      ['Include Exit Loss Coeff (Kx)', :ds_headloss_coeff, false, 'Exit Loss (Kx)'],
      ['Include Avg Loss Coeff (Kavg)', :av_headloss_coeff, false, 'Avg Loss (Kavg)'],
      ['Include Flap Gate', :flap_gate, false, 'Flap Gate'],
      ['Include Initial Flow', :initial_flow, false, 'Initial Flow'],
      ['Include Max Flow (Qlimit)', :max_flow, false, 'Max Flow (Qlimit)'],
      ['Include Point Array', :point_array, false, 'Point Array'],
      ['Include Horiz Ellipse Size Code', :horiz_ellipse_size_code, false, 'Horiz Ellipse Size Code'],
      ['Include Vert Ellipse Size Code', :vert_ellipse_size_code, false, 'Vert Ellipse Size Code'],
      ['Include Arch Material', :arch_material, false, 'Arch Material'],
      ['Include Arch Concrete Size Code', :arch_concrete_size_code, false, 'Arch Concrete Size Code'],
      ['Include Arch Plate 18 Size Code', :arch_plate_18_size_code, false, 'Arch Plate 18 Size Code'],
      ['Include Arch Plate 31 Size Code', :arch_plate_31_size_code, false, 'Arch Plate 31 Size Code'],
      ['Include Arch Steel Half Size Code', :arch_steel_half_size_code, false, 'Arch Steel Half Size Code'],
      ['Include Arch Steel Inch Size Code', :arch_steel_inch_size_code, false, 'Arch Steel Inch Size Code'],
      ['Include Roughness DW', :roughness_DW, false, 'Roughness DW'],
      ['Include Roughness HW', :roughness_HW, false, 'Roughness HW'],
      ['Include Top Radius', :top_radius, false, 'Top Radius'], # Often part of Geom parameters
      ['Include Left Slope', :left_slope, false, 'Left Slope'], # Often part of Geom parameters
      ['Include Right Slope', :right_slope, false, 'Right Slope'], # Often part of Geom parameters
      ['Include Triangle Height', :triangle_height, false, 'Triangle Height'], # Often part of Geom parameters
      ['Include Bottom Radius', :bottom_radius, false, 'Bottom Radius'], # Often part of Geom parameters
      ['Include Shape Curve ID', :shape_curve, false, 'Shape Curve ID'],
      ['Include Shape Exponent', :shape_exponent, false, 'Shape Exponent'], # SWMM doesn't use this directly for conduits
      ['Include Transect ID', :transect, false, 'Transect ID'],
      ['Include Sediment Depth', :sediment_depth, false, 'Sediment Depth'],
      ['Include Seepage Rate', :seepage_rate, false, 'Seepage Rate'],
      ['Include Culvert Code', :culvert_code, false, 'Culvert Code'],
      ['Include Branch ID', :branch_id, false, 'Branch ID'],
      ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
      ['Include Notes', :notes, false, 'Notes'],
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
    ]
  },
  'sw_raingage' => {
    display_name: 'SWMM Raingages',
    id_field_symbol: :raingage_id, # Or just :id
    singular_item_name: 'Raingage',
    complex_fields: {
      hyperlinks: { type: :array_of_hashes, keys: [:description, :url], join_char: ',' }
    },
    fields: [
      ['Include Raingage ID', :raingage_id, true, 'Raingage ID'], # Or :id
      ['Include X Coordinate', :x, false, 'X Coordinate'],
      ['Include Y Coordinate', :y, false, 'Y Coordinate'],
      ['Include Snow Catch Factor (SCF)', :scf, false, 'Snow Catch Factor'],
      # Timeseries data itself is usually linked, not a direct field here.
      # These fields relate to how the timeseries is used:
      ['Include Data Source', :data_source, false, 'Data Source'], # TIMESERIES or FILE
      ['Include Series Name (if TIMESERIES)', :series_name, false, 'Series Name'],
      ['Include File Name (if FILE)', :file_name, false, 'File Name'],
      ['Include Station ID (in File)', :station_id, false, 'Station ID (in File)'],
      ['Include Rain Units (in File)', :rain_units, false, 'Rain Units (in File)'], # IN or MM
      ['Include Rain Interval (min)', :rain_interval, false, 'Rain Interval (min)'], # Recording interval
      ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
      ['Include Notes', :notes, false, 'Notes'],
      ['Include User Number 1', :user_number_1, false, 'User Number 1'],
      ['Include User Number 2', :user_number_2, false, 'User Number 2'],
      ['Include User Number 3', :user_number_3, false, 'User Number 3'],
      ['Include User Number 4', :user_number_4, false, 'User Number 4'],
      ['Include User Number 5', :user_number_5, false, 'User Number 5'],
      ['Include User Text 1', :user_text_1, false, 'User Text 1'],
      ['Include User Text 2', :user_text_2, false, 'User Text 2']
    ]
  },
  'sw_pollutant' => {
    display_name: 'SWMM Pollutants',
    id_field_symbol: :id,
    singular_item_name: 'Pollutant',
    complex_fields: {
      hyperlinks: { type: :array_of_hashes, keys: [:description, :url], join_char: ',' }
    },
    fields: [
      ['Include Pollutant ID', :id, true, 'Pollutant ID'],
      ['Include Units', :units, true, 'Units'], # MG/L, UG/L, or COUNT/L
      ['Include Rainfall Concentration', :rainfall_conc, false, 'Rainfall Conc.'],
      ['Include Groundwater Concentration', :groundwater_conc, false, 'Groundwater Conc.'],
      ['Include RDII Concentration', :rdii_conc, false, 'RDII Conc.'],
      ['Include DWF Concentration (Avg.)', :dwf_conc, false, 'DWF Conc. (Avg.)'], # Average DWF concentration
      ['Include Initial Concentration (Nodes/Links)', :init_conc, false, 'Initial Conc.'],
      ['Include Decay Coefficient (Kdecay)', :decay_coeff, false, 'Decay Coeff (1/day)'],
      ['Include Snow Build Up Only', :snow_build_up, false, 'Snow Build Up Only'], # TRUE/FALSE
      ['Include Co-Pollutant ID', :co_pollutant, false, 'Co-Pollutant ID'], # Name of co-pollutant
      ['Include Co-Fraction', :co_fraction, false, 'Co-Fraction'], # Fraction of co-pollutant
      ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
      ['Include Notes', :notes, false, 'Notes'],
      ['Include User Number 1', :user_number_1, false, 'User Number 1'],
      ['Include User Text 1', :user_text_1, false, 'User Text 1']
    ]
  },
  'sw_land_use' => {
    display_name: 'SWMM Land Uses',
    id_field_symbol: :id,
    singular_item_name: 'Land Use',
    complex_fields: {
      build_up:   { type: :array_of_hashes_complex, join_char: '||' }, # pollutant, type, C1, C2, C3, unit
      washoff:    { type: :array_of_hashes_complex, join_char: '||' }, # pollutant, type, C1, C2, sweep_eff, bmp_eff
      hyperlinks: { type: :array_of_hashes, keys: [:description, :url], join_char: ',' }
    },
    fields: [
      ['Include Land Use ID', :id, true, 'Land Use ID'],
      ['Include Pollutant Build-Up Functions', :build_up, false, 'Build-Up Functions'],
      ['Include Pollutant Washoff Functions', :washoff, false, 'Washoff Functions'],
      ['Include Street Sweeping Interval (days)', :sweep_interval, false, 'Sweep Interval (days)'],
      ['Include Fraction Available After Sweeping', :sweep_removal, false, 'Fraction Avail. Post-Sweep'], # This is 1.0 - removal efficiency
      ['Include Days Since Last Swept', :last_sweep, false, 'Days Since Last Swept'],
      ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
      ['Include Notes', :notes, false, 'Notes'],
      ['Include User Number 1', :user_number_1, false, 'User Number 1'],
      ['Include User Text 1', :user_text_1, false, 'User Text 1']
    ]
  },
  'sw_transect' => {
    display_name: 'SWMM Transects',
    id_field_symbol: :id,
    singular_item_name: 'Transect',
    complex_fields: {
      profile:    { type: :array_of_hashes, keys: [:x, :z], join_char: ':' }, # Station, Elevation
      hyperlinks: { type: :array_of_hashes, keys: [:description, :url], join_char: ',' }
    },
    fields: [
      ['Include Transect ID', :id, true, 'Transect ID'],
      ['Include Nleft (Left Overbank N)', :left_roughness, false, 'Nleft (Left Bank N)'],
      ['Include Nright (Right Overbank N)', :right_roughness, false, 'Nright (Right Bank N)'],
      ['Include Nchan (Main Channel N)', :channel_roughness, false, 'Nchan (Main Channel N)'],
      ['Include Left Bank Station', :left_offset, false, 'Left Bank Station'], # Station for left overbank
      ['Include Right Bank Station', :right_offset, false, 'Right Bank Station'], # Station for right overbank
      ['Include Width Factor (for Modifiers)', :width_factor, false, 'Width Factor'],
      ['Include Elevation Adjust (for Modifiers)', :elevation_adjust, false, 'Elevation Adjust'],
      ['Include Meander Factor', :meander_factor, false, 'Meander Factor'],
      ['Include Profile Data (Station,Elev;...)', :profile, true, 'Profile Data'],
      ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
      ['Include Notes', :notes, false, 'Notes']
    ]
  }
  # Add more table configurations here following the same pattern...
  # e.g., 'sw_weir', 'sw_orifice', 'sw_pump', 'sw_outlet', 'sw_curve_xxx', etc.
}.freeze

# --- Main Script Logic ---

# Function to serialize complex array fields
def serialize_complex_value(value, field_config_details, attr_sym_for_debug = '')
  return "" if value.nil? || !value.is_a?(Array) || value.empty?

  case field_config_details[:type]
  when :array_of_points # Assumes array of [x,y] or similar
    item_join_char = field_config_details.fetch(:item_join_char, ',')
    value.map { |pt| (pt.is_a?(Array) && pt.length >= 2) ? pt.join(item_join_char) : "InvalidPointData" }.join(';')
  when :array_of_hashes
    keys = field_config_details[:keys]
    join_char = field_config_details.fetch(:join_char, ':')
    value.map { |item|
      keys.map { |k|
        val = item.is_a?(Hash) ? (item[k] || item[k.to_s]) : (item.respond_to?(k) ? item.send(k) : 'N/A')
        val.to_s.gsub(/[;,]/, '') # Basic cleaning of delimiters
      }.join(join_char)
    }.join(';')
  when :array_of_hashes_complex # For very complex structures that need custom logic per table/field
    # This will require specific handling in the main loop based on attr_sym_for_debug
    # For now, a generic join, but this should be expanded.
    # Example for SUDS (very simplified, needs full structure from debug)
    if attr_sym_for_debug == :suds_controls
        return value.map { |sc|
            sc_id = sc.is_a?(Hash) ? (sc[:id] || sc['id']) : (sc.respond_to?(:id) ? sc.id : 'N/A')
            sc_struct = sc.is_a?(Hash) ? (sc[:suds_structure] || sc['suds_structure']) : (sc.respond_to?(:suds_structure) ? sc.suds_structure : 'N/A')
            # Add more fields as known, e.g., area, num_units, etc.
            "ID=#{sc_id.to_s.gsub(/[;:]/, '')}|Struct=#{sc_struct.to_s.gsub(/[;:]/, '')}"
        }.join(' || ') # Double pipe to separate multiple SUDS controls
    elsif attr_sym_for_debug == :build_up # For sw_land_use
        return value.map { |bu|
            p = bu.is_a?(Hash) ? (bu[:pollutant] || bu['pollutant']) : (bu.respond_to?(:pollutant) ? bu.pollutant : 'N/A')
            t = bu.is_a?(Hash) ? (bu[:build_up_type] || bu['build_up_type']) : (bu.respond_to?(:build_up_type) ? bu.build_up_type : 'N/A')
            c1 = bu.is_a?(Hash) ? (bu[:c1] || bu['c1']) : (bu.respond_to?(:c1) ? bu.c1 : 'N/A') # Max buildup or rate constant
            c2 = bu.is_a?(Hash) ? (bu[:c2] || bu['c2']) : (bu.respond_to?(:c2) ? bu.c2 : 'N/A') # Time exponent or sat constant
            c3 = bu.is_a?(Hash) ? (bu[:c3] || bu['c3']) : (bu.respond_to?(:c3) ? bu.c3 : 'N/A') # Normalizer (area/curb)
            u = bu.is_a?(Hash) ? (bu[:unit] || bu['unit']) : (bu.respond_to?(:unit) ? bu.unit : 'N/A')
            "#{p}:#{t}:#{c1}:#{c2}:#{c3}:#{u}"
        }.join(';')
    elsif attr_sym_for_debug == :washoff # For sw_land_use
        return value.map { |wo|
            p = wo.is_a?(Hash) ? (wo[:pollutant] || wo['pollutant']) : (wo.respond_to?(:pollutant) ? wo.pollutant : 'N/A')
            t = wo.is_a?(Hash) ? (wo[:washoff_type] || wo['washoff_type']) : (wo.respond_to?(:washoff_type) ? wo.washoff_type : 'N/A') # e.g. EXP, RC, EMC
            c1 = wo.is_a?(Hash) ? (wo[:c1] || wo['c1']) : (wo.respond_to?(:c1) ? wo.c1 : 'N/A') # Coeff
            c2 = wo.is_a?(Hash) ? (wo[:c2] || wo['c2']) : (wo.respond_to?(:c2) ? wo.c2 : 'N/A') # Exp
            sweep_eff = wo.is_a?(Hash) ? (wo[:sweep_efficiency] || wo['sweep_efficiency']) : (wo.respond_to?(:sweep_efficiency) ? wo.sweep_efficiency : 'N/A')
            bmp_eff = wo.is_a?(Hash) ? (wo[:bmp_efficiency] || wo['bmp_efficiency']) : (wo.respond_to?(:bmp_efficiency) ? wo.bmp_efficiency : 'N/A')
            "#{p}:#{t}:#{c1}:#{c2}:SweepEff=#{sweep_eff}:BmpEff=#{bmp_eff}"
        }.join(';')
    else
        value.map(&:to_s).join('; ') # Fallback for other complex arrays
    end
  else
    value.join(', ') # Default for simple arrays
  end
end


# --- Get Current Network ---
begin
  cn = WSApplication.current_network
  raise "No network loaded. Please open a network before running the script." if cn.nil?
rescue NameError => e
  puts "ERROR: WSApplication not found. Are you running this script within the application environment?"
  puts "Details: #{e.message}"
  exit
rescue => e
  puts "ERROR: Could not get current network."
  puts "Details: #{e.class} - #{e.message}"
  exit
end

# --- Prompt User to Select Table ---
table_choices = SWMM_TABLE_CONFIGS.map { |key, config| "#{config[:display_name]} (#{key})" }
table_prompt_options = [['Select SWMM Table to Export', 'String', nil, table_choices.first, table_choices]]

selected_table_option_str = WSApplication.prompt("Select SWMM Table", table_prompt_options, false)
if selected_table_option_str.nil?
  puts "User cancelled table selection. Exiting."
  exit
end

# Extract internal table name from the selected string (e.g., "SWMM Subcatchments (sw_subcatchment)" -> "sw_subcatchment")
selected_table_name_internal = selected_table_option_str[0][/\((.*?)\)/, 1]
unless selected_table_name_internal && SWMM_TABLE_CONFIGS.key?(selected_table_name_internal)
  puts "ERROR: Invalid table selection or configuration not found for '#{selected_table_option_str[0]}'. Exiting."
  exit
end

CURRENT_TABLE_CONFIG = SWMM_TABLE_CONFIGS[selected_table_name_internal]

# --- Optional Debugging Block (Adapts to selected table) ---
# Uncomment to print available methods for the first object of the SELECTED table.
# ---
# example_object = cn.row_objects(selected_table_name_internal).first
# if example_object
#   puts "\n--- DEBUG: Available methods for the first '#{CURRENT_TABLE_CONFIG[:singular_item_name]}' object (Table: #{selected_table_name_internal}) ---"
#   obj_id_for_debug = "N/A"
#   if example_object.respond_to?(CURRENT_TABLE_CONFIG[:id_field_symbol])
#     obj_id_for_debug = example_object.send(CURRENT_TABLE_CONFIG[:id_field_symbol])
#   elsif example_object.respond_to?(:id) # Fallback
#     obj_id_for_debug = example_object.id
#   end
#   puts "Object ID (for reference): #{obj_id_for_debug}"
#   puts example_object.methods.sort.inspect
#   if example_object.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method ---"
#      puts example_object.fields.inspect
#   end
#   puts "--- END DEBUG for #{selected_table_name_internal} ---"
#   # exit # Uncomment to stop after debugging
# else
#   puts "DEBUG: No '#{CURRENT_TABLE_CONFIG[:singular_item_name]}' objects found in the network for table '#{selected_table_name_internal}' to inspect."
# end
# --- End Optional Debugging Block ---


# --- Prompt for Fields and Export Folder ---
prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false]
]
CURRENT_TABLE_CONFIG[:fields].each do |field_config_arr|
  prompt_options << [field_config_arr[0], 'Boolean', field_config_arr[2]] # Label, Type, Default
end

options = WSApplication.prompt("Export Options for #{CURRENT_TABLE_CONFIG[:display_name]}", prompt_options, false)
if options.nil?
  puts "User cancelled field selection. Exiting."
  exit
end

puts "Starting script for #{CURRENT_TABLE_CONFIG[:display_name]} export at #{Time.now}"
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
file_path = File.join(export_folder, "selected_#{selected_table_name_internal}_export_#{timestamp}.csv")

selected_fields_details = [] # To store { attribute: :sym, header: 'Name', original_label: 'Label' }
csv_header = []
CURRENT_TABLE_CONFIG[:fields].each_with_index do |field_config_arr, index|
  individual_field_selected = options[index + 2] # First two options are folder and select_all
  if select_all_state || individual_field_selected
    selected_fields_details << { 
      attribute: field_config_arr[1], 
      header: field_config_arr[3], 
      original_label: field_config_arr[0] 
    }
    csv_header << field_config_arr[3]
  end
end

if selected_fields_details.empty?
  puts "No fields selected for export. Exiting."
  exit
end

items_iterated_count = 0
items_written_count = 0

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{csv_header.join(', ')}"
    csv << csv_header

    puts "Processing #{CURRENT_TABLE_CONFIG[:display_name]}... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects(selected_table_name_internal)
    raise "Failed to retrieve '#{selected_table_name_internal}' objects." if row_objects_iterator.nil?

    # Special handling for 'sw_options' or similar single-object tables
    if selected_table_name_internal == 'sw_options' && !cn.network.nil? && cn.network.respond_to?(:options_object) # Hypothetical API
        # This part is highly dependent on how your API exposes global options.
        # It might be cn.network, cn.options, or a single object from cn.row_objects('sw_options').
        # The current loop below will try to iterate, which might work if it's a collection of one.
        # If options are a single, directly accessible object, this loop needs to be replaced.
        puts "Note: 'sw_options' might be a single settings object. Attempting to process..."
    end


    row_objects_iterator.each do |item_obj|
      items_iterated_count += 1
      current_item_id_for_log = "ITEM_ITER_#{items_iterated_count}"
      id_sym = CURRENT_TABLE_CONFIG[:id_field_symbol]
      if item_obj.respond_to?(id_sym) && id_sym != :itself # :itself for tables like sw_options
        current_item_id_for_log = item_obj.send(id_sym).to_s
      elsif item_obj.respond_to?(:id) # Generic fallback
         current_item_id_for_log = item_obj.id.to_s
      end
      
      # For tables like 'sw_options', selection might not apply or always be true for the single object.
      is_selected = if selected_table_name_internal == 'sw_options'
                      true # Assume options are always "selected" for export if table is chosen
                    else
                      item_obj.respond_to?(:selected) && item_obj.selected
                    end

      if item_obj && is_selected
        items_written_count += 1
        row_data = []
        
        selected_fields_details.each do |field_info|
          attr_sym = field_info[:attribute]
          begin
            value = item_obj.send(attr_sym)
            
            complex_field_detail = CURRENT_TABLE_CONFIG[:complex_fields][attr_sym]
            if complex_field_detail
              row_data << serialize_complex_value(value, complex_field_detail, attr_sym)
            elsif value.is_a?(Array) # Generic array handling if not in complex_fields
              row_data << value.join(', ')
            else
              row_data << (value.nil? ? "" : value)
            end
          rescue NoMethodError
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for selected #{CURRENT_TABLE_CONFIG[:singular_item_name]} '#{current_item_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing ':#{attr_sym}' (for '#{field_info[:original_label]}') for #{CURRENT_TABLE_CONFIG[:singular_item_name]} '#{current_item_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv << row_data
      end # if item_obj selected
    end # row_objects_iterator.each
  end # CSV.open block

  puts "\n--- Processing Summary (#{CURRENT_TABLE_CONFIG[:display_name]}) ---"
  puts "Total #{CURRENT_TABLE_CONFIG[:singular_item_name]} objects iterated: #{items_iterated_count}"
  if items_written_count > 0
    puts "Successfully wrote #{items_written_count} selected #{CURRENT_TABLE_CONFIG[:singular_item_name]}(s) to #{file_path}"
  else
    puts "No #{CURRENT_TABLE_CONFIG[:singular_item_name]} objects were selected or matched criteria for export."
    if File.exist?(file_path)
      header_line_content_size = csv_header.empty? ? 0 : CSV.generate_line(csv_header).bytesize
      newline_size = (RUBY_PLATFORM =~ /mswin|mingw|cygwin/ ? 2 : 1)
      header_only_file_size = header_line_content_size + (csv_header.empty? ? 0 : newline_size)
      if File.size(file_path) <= header_only_file_size
        line_count_in_file = 0
        begin; line_count_in_file = File.foreach(file_path).count; rescue; end
        if line_count_in_file <= (csv_header.empty? ? 0 : 1)
            puts "Deleting CSV file as it's empty or contains only the header: #{file_path}"
            File.delete(file_path)
        end
      end
    end
  end
  
  if items_written_count > 0 && items_iterated_count > 0 && items_written_count < items_iterated_count && selected_table_name_internal != 'sw_options'
      puts "Note: Some #{CURRENT_TABLE_CONFIG[:singular_item_name]} objects were iterated but not written (likely not selected)."
  end
  puts "If 'AttributeMissing' warnings appeared, uncomment the DEBUG block (after table selection) to verify field names for '#{selected_table_name_internal}'."

rescue Errno::EACCES => e
  puts "FATAL ERROR: Permission denied writing to file '#{file_path}'. - #{e.message}"
rescue Errno::ENOSPC => e
  puts "FATAL ERROR: No space left on device writing to file '#{file_path}'. - #{e.message}"
rescue CSV::MalformedCSVError => e
  puts "FATAL ERROR: CSV formatting issue during write to '#{file_path}'. - #{e.message}"
rescue => e
  puts "FATAL ERROR: Unexpected failure during #{CURRENT_TABLE_CONFIG[:display_name]} CSV export. - #{e.class}: #{e.message}"
  puts "Backtrace (first 5 lines):\n#{e.backtrace.first(5).join("\n")}"
end

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for #{CURRENT_TABLE_CONFIG[:display_name]} export finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && items_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ["Number of Selected #{CURRENT_TABLE_CONFIG[:singular_item_name]}s Written", 'NUMBER', items_written_count],
    ["Number of Fields Exported Per #{CURRENT_TABLE_CONFIG[:singular_item_name]}", 'NUMBER', selected_fields_details.count]
  ]
  WSApplication.prompt("Export Summary (#{CURRENT_TABLE_CONFIG[:display_name]})", summary_layout, false)
elsif items_written_count == 0 && items_iterated_count > 0
  WSApplication.message_box("No #{CURRENT_TABLE_CONFIG[:singular_item_name]} objects were selected for export from table '#{selected_table_name_internal}'. The CSV file was not created or was empty (and thus deleted).", 'Info', :OK, false)
else
  WSApplication.message_box("Export for #{CURRENT_TABLE_CONFIG[:display_name]} did not complete as expected. No items written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for #{CURRENT_TABLE_CONFIG[:display_name]} complete."
