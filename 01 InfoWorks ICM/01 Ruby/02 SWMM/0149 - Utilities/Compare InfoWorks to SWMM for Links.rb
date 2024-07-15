cn = WSApplication.current_network
bn = WSApplication.background_network
puts "CN is the ICM Infoworks Network and BN is the ICM SWMM Network"
# Retrieve hw_nodes from cn
cn_conduits = cn.row_object_collection('hw_conduit')

# Retrieve sw_nodes from bn
bn_conduits = bn.row_object_collection('sw_conduit')

val = WSApplication.prompt "Compare Infoworks HW Conduits to SWMM SW Conduits",
[
  ['hw_conduit conduit_length   vs  sw_conduit length','Boolean',false],
  ['hw_conduit conduit_height   vs  sw_conduit conduit_height','Boolean',false],
  ['hw_conduit conduit_width     vs  sw_conduit conduit_width','Boolean',false],
  ['hw_conduit number_of_barrels  vs  sw_conduit number_of_barrels','Boolean',false],
  ['hw_conduit us_invert  vs  sw_conduit us_invert','Boolean',false],
  ['hw_conduit ds_invert    vs  sw_conduit ds_invert','Boolean',false],
  ['hw_conduit us_headloss_coeff  vs  sw_conduit us_headloss_coeff','Boolean',false],
  ['hw_conduit ds_headloss_coeff  vs  sw_conduit ds_headloss_coeff','Boolean',false],
  ['hw_conduit bottom_roughness_N  vs  sw_conduit Mannings_N','Boolean',false],
  ['hw_conduit top_roughness_N     vs  sw_conduit Mannings_N','Boolean',false],
  ["This tool compares selected attributes between", 'String'],
  ["InfoWorks HW Conduits and SWMM SW Conduits.", 'String'],
  ["Select the attributes you want to compare", 'String'],   
  ["The comparison will be based on Conduit IDs.", 'String'],   
  ["Results will show the values from both networks ", 'String'],   
  ["and their differences.", 'String']
], false

# Define attribute pairs
attribute_pairs = [
  ['conduit_length', 'length'],
  ['conduit_height', 'conduit_height'],
  ['conduit_width', 'conduit_width'],
  ['number_of_barrels', 'number_of_barrels'],
  ['us_invert', 'us_invert'],
  ['ds_invert', 'ds_invert'],
  ['us_headloss_coeff', 'us_headloss_coeff'],
  ['ds_headloss_coeff', 'ds_headloss_coeff'],
  ['bottom_roughness_N', 'Mannings_N'],
  ['top_roughness_N', 'Mannings_N']
]

# Loop through each val and perform comparison if true
val.each_with_index do |is_selected, index|
  next unless is_selected

  hw, sw = attribute_pairs[index]

  # Create a hash map for sw attribute by node_id
  bn_attributes = {}
  bn_conduits.each do |conduit|
    bn_attributes[conduit.id] = conduit[sw]
  end

  # Initialize totals
  total_hw = 0.0
  total_sw = 0.0
  # Initialize counters
  below_threshold_count = 0
  total_comparisons = 0

  # Compare hw attribute from cn to sw attribute from bn using conduit_id
  cn_conduits.each do |conduit|
    conduit_id = conduit.asset_id
    hw_value = conduit[hw]

    if bn_attributes.key?(conduit_id)
      sw_value = bn_attributes[conduit_id]
      # Ensure hw_value and sw_value are not nil
      hw_value = hw_value.nil? ? 0.0 : hw_value
      sw_value = sw_value.nil? ? 0.0 : sw_value

      # Format hw_value and sw_value
      formatted_hw_value = format('%10.4f', hw_value)
      formatted_sw_value = format('%10.4f', sw_value)

      # Calculate the absolute difference percentage
      difference_percentage = ((hw_value - sw_value).abs / ((hw_value + sw_value) / 2.0)) * 100

      # Increment total comparisons counter
      total_comparisons += 1

      # Increment counter if the absolute difference percentage is below 0.1 percent
      if difference_percentage <= 0.1
        below_threshold_count += 1
      end

      # Print only if the absolute difference percentage is more than 0.1 percent
      if difference_percentage > 0.1
        puts "Conduit ID: #{conduit_id.slice(0, 25).ljust(25)} CN #{hw.capitalize}: #{formatted_hw_value}, BN #{sw.capitalize}: #{formatted_sw_value}"
      end

      # Update totals with nil checks
      total_hw += hw_value unless hw_value.nil?
      total_sw += sw_value unless sw_value.nil?
    else
      puts "Conduit ID: #{conduit_id.slice(0, 25).ljust(25)} not found in bn"
    end
  end

  # Calculate the percentage of comparisons below 0.1 percent
  percentage_below_threshold = (below_threshold_count.to_f / total_comparisons) * 100

  # Print totals
  puts "CN conduit.#{hw}:".ljust(30) + format('%.4f', total_hw).rjust(10)
  puts "BN conduit.#{sw}:".ljust(30) + format('%.4f', total_sw).rjust(10)
  puts "Difference:".ljust(30) + format('%.4f', total_hw - total_sw).rjust(10)
  puts

  # Print the count of comparisons below 0.1 percent, total comparisons, and percentage below 0.1 percent
  puts "Number of comparisons below 0.1 percent: #{below_threshold_count}"
  puts "Total number of comparisons: #{total_comparisons}"
  puts "Percentage of comparisons below 0.1 percent: #{format('%.2f', percentage_below_threshold)}%"
end

puts "CN is the ICM Infoworks Network and BN is the ICM SWMM Network"