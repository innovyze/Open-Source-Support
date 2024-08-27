# @param structure [WSStructure]
# @param array [Array<Hash>]
def array_to_structure(structure, array)
  # Sanity check
  raise "Structure is not a WSStructure" unless structure.is_a?(WSStructure)
  raise "Array is not an Array" unless array.is_a?(Array)
  raise "Array is not an Array of Hashes" unless array.all? { |item| item.is_a?(Hash) }
  
  # Make the structure length match the array
  structure.length = array.length

  # Update the values in each row in the structure (WSStructureRow)
  array.each_with_index do |hash, i|
    struct_row = structure[i]
    hash.each { |k, v| struct_row[k] = v }
  end

  # Write changes - note that the WSRowObject that this WSStructure belongs to also needs to call #write
  structure.write
end

# Dummy data. The expected format is an array of hashes, the keys of the hash should match the
# fields in the WSStructureRow. You can find the field names in the Exchange help file, or by
# looking in the SQL query tool
DEMAND_DATA = [
  { 'category_id' => 'CONST_LEAKAGE', 'category_type' => 1, 'average_demand' => 0.1 },
  { 'category_id' => 'CONST_LEAKAGE', 'category_type' => 1, 'average_demand' => 0.2 }
]

network = WSApplication.current_network()
network.transaction_begin

network.row_objects_selection('wn_node').each do |node|
  array_to_structure(node['demand_by_category'], DEMAND_DATA)
  node.write
end

network.transaction_commit