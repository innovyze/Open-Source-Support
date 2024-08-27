cn = WSApplication.current_network

puts "CN is the ICM Infoworks Network"

cn_subcatchments = cn.row_object_collection('hw_subcatchment')

val = WSApplication.prompt "Find Infoworks HW Subcatchments Flows",
[
  ['hw_subcatchment population', 'Boolean', true],
  ['hw_subcatchment trade_flow ', 'Boolean', true],
  ['hw_subcatchment base_flow ', 'Boolean', true],
  ['hw_subcatchment additional_foul_flow ', 'Boolean', true],
  ['hw_subcatchment trade_profile', 'Boolean', true],
  ['hw_subcatchment user_number_1', 'Boolean', true],
  ['hw_subcatchment user_number_2', 'Boolean', true],
  ['hw_subcatchment user_number_3', 'Boolean', true],
  ['hw_subcatchment user_number_4', 'Boolean', true],
  ['hw_subcatchment user_number_5', 'Boolean', true],
  ['hw_subcatchment user_number_6', 'Boolean', true],
  ['hw_subcatchment user_number_7', 'Boolean', true],
  ['hw_subcatchment user_number_8', 'Boolean', true],
  ['hw_subcatchment user_number_9', 'Boolean', true],
  ['hw_subcatchment user_number_10', 'Boolean', true]
], false

# Define attribute pairs
attribute_pairs = [
  'population',
  'trade_flow',
  'base_flow',
  'additional_foul_flow',
  'trade_profile',
  'user_number_1',
  'user_number_2',
  'user_number_3',
  'user_number_4',
  'user_number_5',
  'user_number_6',
  'user_number_7',
  'user_number_8',
  'user_number_9',
  'user_number_10'
]

# Loop through each val and perform comparison if true
val.each_with_index do |is_selected, index|
  next unless is_selected

  hw = attribute_pairs[index]

  # Initialize totals, max, and non-zero counter
  total_hw = 0.0
  max_hw = -Float::INFINITY
  non_zero_count = 0

  # Compare hw attribute from cn to sw attribute 
  cn_subcatchments.each do |sub|
    hw_value = sub[hw].to_f # Convert hw_value to float

    # Update totals and max
    total_hw += hw_value
    max_hw = [max_hw, hw_value].max

    # Increment non-zero counter if hw_value is not zero
    non_zero_count += 1 if hw_value != 0.0
  end

  # Print totals, max, and non-zero count
  puts "CN Subcatchment.#{hw}:"
  puts "  Total:         ".ljust(10) + format('%.4f', total_hw).rjust(15)
  puts "  Max:           ".ljust(10) + format('%.4f', max_hw).rjust(15)
  puts "  Non-zero count:".ljust(10) + non_zero_count.to_s.rjust(15)
end

puts "CN is the ICM Infoworks Network"