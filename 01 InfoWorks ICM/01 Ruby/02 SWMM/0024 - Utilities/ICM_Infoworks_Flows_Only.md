# Infoworks ICM Network Analysis Script Summary

## Purpose
This script analyzes various attributes of subcatchments in an Infoworks ICM network, calculating the total, maximum, and non-zero count for each selected attribute.

## Key Components

1. **Network Initialization**
   ```ruby
   cn = WSApplication.current_network
   cn_subcatchments = cn.row_object_collection('hw_subcatchment')
   ```
   - Retrieves the current network and its subcatchments.

2. **User Input**
   ```ruby
   val = WSApplication.prompt "Find Infoworks HW Subcatchments Flows", [...], false
   ```
   - Prompts user to select which attributes to analyze.
   - Includes 15 attributes: population, trade_flow, base_flow, additional_foul_flow, trade_profile, and user_number_1 through user_number_10.

3. **Attribute Definition**
   ```ruby
   attribute_pairs = ['population', 'trade_flow', ...]
   ```
   - Defines a list of attributes corresponding to the user prompt.

4. **Main Analysis Loop**
   ```ruby
   val.each_with_index do |is_selected, index|
     # ... analysis code ...
   end
   ```
   - Iterates through selected attributes.
   - For each selected attribute:
     - Initializes counters (total, max, non-zero count).
     - Processes each subcatchment.
     - Calculates total, maximum, and non-zero count.

5. **Results Output**
   ```ruby
   puts "CN Subcatchment.#{hw}:"
   puts "  Total:         ".ljust(10) + format('%.4f', total_hw).rjust(15)
   puts "  Max:           ".ljust(10) + format('%.4f', max_hw).rjust(15)
   puts "  Non-zero count:".ljust(10) + non_zero_count.to_s.rjust(15)
   ```
   - Prints results for each analyzed attribute:
     - Total value
     - Maximum value
     - Count of non-zero values

## Workflow
1. Initialize network and retrieve subcatchments.
2. Prompt user for attribute selection.
3. For each selected attribute:
   - Process all subcatchments.
   - Calculate total, max, and non-zero count.
   - Display results.

## Notes
- The script uses Infoworks ICM-specific functions (`WSApplication`, `row_object_collection`).
- It handles multiple types of subcatchment attributes (population, flows, user numbers).
- Results are formatted for easy reading with aligned decimal points.