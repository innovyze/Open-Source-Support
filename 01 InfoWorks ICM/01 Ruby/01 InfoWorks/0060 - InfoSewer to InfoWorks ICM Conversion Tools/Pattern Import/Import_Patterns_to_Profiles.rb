# InfoSewer Pattern Import - Converts InfoSewer PATNDATA.DBF to InfoWorks CSV Format
# 
# WHAT THIS SCRIPT DOES:
#   - Generates CSV files (Wastewater_Profiles.csv, Trade_Waste_Profiles.csv)
#   - CSV files must be manually imported through InfoWorks ICM UI
#   - This script does NOT import the profiles directly into ICM
#
# WHY: Wastewater/Trade Waste profiles are Model Group objects that cannot be
#      created via UI Ruby scripts. CSV import avoids using Exchange scripts.
#
# For InfoSewer models (.IEDB) only
#
# IMPORTANT: This script requires ../lib/dbf_reader.rb to function
# The lib/ folder must be in the parent directory
#
# Author: GitHub Open Source Support
# Last Updated: February 2026

# Get the directory where this script is located
script_dir = File.dirname(__FILE__)
parent_dir = File.dirname(script_dir)

# Load the DBF reader library from parent folder
dbf_reader_path = File.join(parent_dir, 'lib', 'dbf_reader.rb')

unless File.exist?(dbf_reader_path)
  puts "=" * 80
  puts "ERROR: Required file not found"
  puts "=" * 80
  puts ""
  puts "This script requires: lib/dbf_reader.rb"
  puts "Expected location: #{dbf_reader_path}"
  puts ""
  puts "Make sure the lib/ folder is in the parent directory:"
  puts "  0060 - InfoSewer to InfoWorks ICM Conversion Tools/"
  puts "  |-- InfoSewer_Import_UI.rb"
  puts "  |-- lib/"
  puts "  |   +-- dbf_reader.rb"
  puts "  +-- Pattern Import/"
  puts "      +-- Import_Patterns_to_Profiles.rb"
  puts ""
  exit
end

require dbf_reader_path

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Convert InfoSewer pattern data to ICM Wastewater Event CSV format
#
# @param pattern_data [Hash] Hash of pattern ID => {SEQ => {FACTOR => value}}
# @param output_path [String] Path to output CSV file
# @param profile_number [Integer] Starting profile number
# @return [Integer] Number of patterns converted

def export_wastewater_profiles(pattern_data, output_path, profile_number = 1)
  return 0 if pattern_data.empty?
  
  patterns_converted = 0
  
  File.open(output_path, 'w') do |file|
    # Write version header
    file.puts "!Version=1,type=WWG,encoding=UTF8"
    
    # Write title with pollutant count (16 pollutants defined)
    file.puts "TITLE,POLLUTANT_COUNT"
    file.puts "InfoSewer Patterns - Wastewater Profiles,16"
    
    # Write units
    file.puts "Units_Concentration,Units_Salt_Concentration,Units_Temperature,Units_Average_Flow"
    file.puts "mg/l,kg/m3,degC,l/day"
    
    # Process each pattern
    pattern_data.each do |pattern_id, seq_data|
      # Check if pattern has non-standard number of values
      actual_seq_count = seq_data.keys.length
      if actual_seq_count > 24
        puts "WARNING: Pattern '#{pattern_id}' has #{actual_seq_count} values (expected 24)"
        puts "  Using first 24 values (SEQ 0-23), ignoring extra values"
      elsif actual_seq_count < 24
        puts "WARNING: Pattern '#{pattern_id}' has only #{actual_seq_count} values (expected 24)"
        puts "  Missing values will be filled with 1.0"
      end
      
      # Extract factors in sequence order (should be 24 hours)
      # Note: SEQ values in DBF are stored as strings and start at 0 (0-23 for 24 hours)
      factors = []
      (0..23).each do |seq|
        # Try both integer and string keys (DBF stores SEQ as string)
        row = seq_data[seq] || seq_data[seq.to_s]
        
        if row && row['FACTOR']
          factor_value = row['FACTOR'].to_s.strip
          factors << (factor_value.empty? ? 1.0 : factor_value.to_f)
        else
          factors << 1.0
        end
      end
      
      # Validate we have 24 hours
      unless factors.length == 24
        puts "ERROR: Could not extract 24 values for pattern '#{pattern_id}', skipping"
        next
      end
      
      # Write profile header
      file.puts "PROFILE_NUMBER,PROFILE_DESCRIPTION,FLOW"
      file.puts "#{profile_number},#{pattern_id},0"
      
      # Write sediment section (required but set to 0)
      file.puts "SEDIMENT,AVERAGE_CONCENTRATION"
      file.puts "SF1,0"
      file.puts "SF2,0"
      
      # Write pollutant section (required but set to 0)
      file.puts "POLLUTANT,DISSOLVED,SF1,SF2"
      file.puts "BOD,0,0,0"
      file.puts "COD,0,0,0"
      file.puts "TKN,0,0,0"
      file.puts "NH4,0,0,0"
      file.puts "TPH,0,0,0"
      file.puts "PL1,0,0,0"
      file.puts "PL2,0,0,0"
      file.puts "PL3,0,0,0"
      file.puts "PL4,0,0,0"
      file.puts "DO_,0,0,0"
      file.puts "NO2,0,0,0"
      file.puts "NO3,0,0,0"
      file.puts "PH_,0,0,0"
      file.puts "SAL,0,0,0"
      file.puts "TW_,0,0,0"
      file.puts "COL,0,0,0"
      
      # Write CALIBRATION_WEEKDAY section
      file.puts "CALIBRATION_WEEKDAY"
      file.puts "TIME,FLOW,POLLUTANT"
      factors.each_with_index do |factor, i|
        time = sprintf("%02d:00", i)
        file.puts "#{time},#{factor},1"
      end
      
      # Write CALIBRATION_WEEKEND section (same as weekday)
      file.puts "CALIBRATION_WEEKEND"
      file.puts "TIME,FLOW,POLLUTANT"
      factors.each_with_index do |factor, i|
        time = sprintf("%02d:00", i)
        file.puts "#{time},#{factor},1"
      end
      
      # Write CALIBRATION_MONTHLY section (all 1.0)
      file.puts "CALIBRATION_MONTHLY"
      file.puts "MONTH,FLOW,POLLUTANT"
      months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 
                'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER']
      months.each do |month|
        file.puts "#{month},1,1"
      end
      
      # Write DESIGN_PROFILES section (same as weekday)
      file.puts "DESIGN_PROFILES"
      file.puts "TIME,FLOW,POLLUTANT"
      factors.each_with_index do |factor, i|
        time = sprintf("%02d:00", i)
        file.puts "#{time},#{factor},1"
      end
      
      profile_number += 1
      patterns_converted += 1
    end
  end
  
  return patterns_converted
end

# Convert InfoSewer pattern data to ICM Trade Waste Event CSV format
#
# @param pattern_data [Hash] Hash of pattern ID => {SEQ => {FACTOR => value}}
# @param output_path [String] Path to output CSV file
# @param profile_number [Integer] Starting profile number
# @return [Integer] Number of patterns converted

def export_trade_waste_profiles(pattern_data, output_path, profile_number = 1)
  return 0 if pattern_data.empty?
  
  patterns_converted = 0
  
  File.open(output_path, 'w') do |file|
    # Write version header
    file.puts "!Version=1,type=TWG,encoding=UTF8"
    
    # Write title with pollutant count (16 pollutants defined)
    file.puts "TITLE,POLLUTANT_COUNT"
    file.puts "InfoSewer Patterns - Trade Waste Profiles,16"
    
    # Write units (no Units_Average_Flow for trade waste)
    file.puts "Units_Concentration,Units_Salt_Concentration,Units_Temperature"
    file.puts "mg/l,kg/m3,degC"
    
    # Process each pattern
    pattern_data.each do |pattern_id, seq_data|
      # Check if pattern has non-standard number of values
      actual_seq_count = seq_data.keys.length
      if actual_seq_count > 24
        puts "WARNING: Pattern '#{pattern_id}' has #{actual_seq_count} values (expected 24)"
        puts "  Using first 24 values (SEQ 0-23), ignoring extra values"
      elsif actual_seq_count < 24
        puts "WARNING: Pattern '#{pattern_id}' has only #{actual_seq_count} values (expected 24)"
        puts "  Missing values will be filled with 1.0"
      end
      
      # Extract factors in sequence order (should be 24 hours)
      # Note: SEQ values in DBF are stored as strings and start at 0 (0-23 for 24 hours)
      factors = []
      (0..23).each do |seq|
        # Try both integer and string keys (DBF stores SEQ as string)
        row = seq_data[seq] || seq_data[seq.to_s]
        
        if row && row['FACTOR']
          factor_value = row['FACTOR'].to_s.strip
          factors << (factor_value.empty? ? 1.0 : factor_value.to_f)
        else
          factors << 1.0
        end
      end
      
      # Validate we have 24 hours
      unless factors.length == 24
        puts "ERROR: Could not extract 24 values for pattern '#{pattern_id}', skipping"
        next
      end
      
      # Write profile header (FLOW is scaling factor for trade waste, assumed to be 1)
      file.puts "PROFILE_NUMBER,PROFILE_DESCRIPTION,FLOW"
      file.puts "#{profile_number},#{pattern_id},1"
      
      # Write sediment section (required but set to 0)
      file.puts "SEDIMENT,AVERAGE_CONCENTRATION"
      file.puts "SF1,0"
      file.puts "SF2,0"
      
      # Write pollutant section (required but set to 0)
      file.puts "POLLUTANT,DISSOLVED,SF1,SF2"
      file.puts "BOD,0,0,0"
      file.puts "COD,0,0,0"
      file.puts "TKN,0,0,0"
      file.puts "NH4,0,0,0"
      file.puts "TPH,0,0,0"
      file.puts "PL1,0,0,0"
      file.puts "PL2,0,0,0"
      file.puts "PL3,0,0,0"
      file.puts "PL4,0,0,0"
      file.puts "DO_,0,0,0"
      file.puts "NO2,0,0,0"
      file.puts "NO3,0,0,0"
      file.puts "PH_,0,0,0"
      file.puts "SAL,0,0,0"
      file.puts "TW_,0,0,0"
      file.puts "COL,0,0,0"
      
      # Write CALIBRATION_WEEKDAY section
      file.puts "CALIBRATION_WEEKDAY"
      file.puts "TIME,FLOW,POLLUTANT"
      factors.each_with_index do |factor, i|
        time = sprintf("%02d:00", i)
        file.puts "#{time},#{factor},1"
      end
      
      # Write CALIBRATION_WEEKEND section (same as weekday)
      file.puts "CALIBRATION_WEEKEND"
      file.puts "TIME,FLOW,POLLUTANT"
      factors.each_with_index do |factor, i|
        time = sprintf("%02d:00", i)
        file.puts "#{time},#{factor},1"
      end
      
      # Write CALIBRATION_MONTHLY section (all 1.0)
      file.puts "CALIBRATION_MONTHLY"
      file.puts "MONTH,FLOW,POLLUTANT"
      months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 
                'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER']
      months.each do |month|
        file.puts "#{month},1,1"
      end
      
      # Write DESIGN_PROFILES section (same as weekday)
      file.puts "DESIGN_PROFILES"
      file.puts "TIME,FLOW,POLLUTANT"
      factors.each_with_index do |factor, i|
        time = sprintf("%02d:00", i)
        file.puts "#{time},#{factor},1"
      end
      
      profile_number += 1
      patterns_converted += 1
    end
  end
  
  return patterns_converted
end

# ============================================================================
# MAIN SCRIPT
# ============================================================================

puts "=" * 80
puts "InfoSewer Pattern Import - Convert to ICM Profiles"
puts "=" * 80
puts ""

# Prompt for IEDB folder location
val = WSApplication.prompt(
  "InfoSewer Pattern Import - Select Folders",
  [
    ['InfoSewer Model (.IEDB folder)', 'String', nil, nil, 'FOLDER', 'Select the .IEDB folder'],
    ['Output Folder for CSV files', 'String', nil, nil, 'FOLDER', 'Select where to save the CSV files']
  ],
  false
)

# Exit if user cancelled
if val.nil?
  puts "Import cancelled by user"
  exit
end

iedb_folder_path = val[0]
output_folder_path = val[1]

# Validate paths exist
unless Dir.exist?(iedb_folder_path)
  puts "ERROR: IEDB folder does not exist: #{iedb_folder_path}"
  exit
end

unless Dir.exist?(output_folder_path)
  puts "ERROR: Output folder does not exist: #{output_folder_path}"
  exit
end

puts "IEDB Folder: #{iedb_folder_path}"
puts "Output Folder: #{output_folder_path}"
puts ""

# Find PATNDATA.DBF file
patndata_path = nil
possible_names = ['PATNDATA.DBF', 'Patndata.dbf', 'patndata.DBF', 'PATNDATA.dbf']

possible_names.each do |name|
  test_path = File.join(iedb_folder_path, name)
  if File.exist?(test_path)
    patndata_path = test_path
    break
  end
end

unless patndata_path
  puts "ERROR: Could not find PATNDATA.DBF in the IEDB folder"
  puts "Searched for: #{possible_names.join(', ')}"
  exit
end

puts "Found: #{File.basename(patndata_path)}"
puts ""

# Read PATNDATA.DBF file
# This file has ID and SEQ columns (time-series format)
# Each pattern ID has 24 rows (SEQ 0-23) with FACTOR values
puts "Reading PATNDATA.DBF..."
pattern_data = read_dbf_ts(patndata_path, true, make_id_safe: true)

if pattern_data.empty?
  puts "ERROR: No pattern data found in PATNDATA.DBF"
  exit
end

puts "Found #{pattern_data.keys.length} patterns in PATNDATA.DBF"
puts ""

# Display first few pattern IDs for verification
puts "Sample pattern IDs:"
pattern_data.keys.first(5).each { |id| puts "  - #{id}" }
puts "  ..." if pattern_data.keys.length > 5
puts ""

# Debug: Show sample data structure
if pattern_data.keys.length > 0
  first_pattern_id = pattern_data.keys.first
  first_pattern = pattern_data[first_pattern_id]
  puts "Debug - First pattern structure:"
  puts "  Pattern ID: #{first_pattern_id}"
  puts "  Number of time steps: #{first_pattern.keys.length}"
  puts "  Sample SEQ keys: #{first_pattern.keys.first(3).inspect}"
  if first_pattern.keys.length > 0
    first_seq = first_pattern.keys.first
    puts "  Sample row (SEQ=#{first_seq}): #{first_pattern[first_seq].inspect}"
  end
  puts ""
end

# Ask user which profile types to generate
profile_choice = WSApplication.prompt(
  "Select Profile Types to Generate",
  [
    ['Generate Wastewater Profiles CSV', 'Boolean', true],
    ['Generate Trade Waste Profiles CSV', 'Boolean', true]
  ],
  false
)

# Exit if user cancelled
if profile_choice.nil?
  puts "Import cancelled by user"
  exit
end

generate_wastewater = profile_choice[0]
generate_trade_waste = profile_choice[1]

unless generate_wastewater || generate_trade_waste
  puts "No profile types selected, exiting"
  exit
end

puts ""
puts "=" * 80
puts "GENERATING CSV FILES"
puts "=" * 80
puts ""

# Generate Wastewater Profiles CSV
if generate_wastewater
  ww_output_path = File.join(output_folder_path, 'Wastewater_Profiles.csv')
  puts "Creating Wastewater Profiles CSV..."
  ww_count = export_wastewater_profiles(pattern_data, ww_output_path)
  puts "[OK] Exported #{ww_count} wastewater profiles to:"
  puts "  #{ww_output_path}"
  puts ""
end

# Generate Trade Waste Profiles CSV
if generate_trade_waste
  tw_output_path = File.join(output_folder_path, 'Trade_Waste_Profiles.csv')
  puts "Creating Trade Waste Profiles CSV..."
  tw_count = export_trade_waste_profiles(pattern_data, tw_output_path)
  puts "[OK] Exported #{tw_count} trade waste profiles to:"
  puts "  #{tw_output_path}"
  puts ""
end

puts "=" * 80
puts "CSV GENERATION COMPLETE"
puts "=" * 80
puts ""
puts "IMPORTANT: CSV files have been generated but NOT imported into ICM."
puts "You must manually import the CSV files through the InfoWorks ICM UI."
puts ""
puts "Next Steps - Manual Import Required:"
puts "1. In InfoWorks ICM, right-click on Model Group"
puts "2. Select 'Import InfoWorks'"
puts "3. For Wastewater Profiles:"
puts "   - Navigate to: Waste water > from InfoWorks format CSV file..."
puts "   - Select 'Wastewater_Profiles.csv' from your output folder"
puts "4. For Trade Waste Profiles:"
puts "   - Navigate to: Trade waste > from InfoWorks format CSV file..."
puts "   - Select 'Trade_Waste_Profiles.csv' from your output folder"
puts ""
puts "Assumptions:"
puts "- Pattern data uses hourly increments (24 hours, SEQ 0-23)"
puts "- Calibration weekday, weekend, and design profiles use same pattern"
puts "- Calibration monthly factors set to 1.0 (no monthly variation)"
puts "- Trade waste flow scaling factor = 1"
puts "- Wastewater per capita flow = 0"
puts "- Pollutant concentrations set to 0"
puts ""
