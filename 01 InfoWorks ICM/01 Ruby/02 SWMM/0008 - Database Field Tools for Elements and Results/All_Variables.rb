# Initialize an empty array to store the row objects and field values
$validation = []

# Iterate through each table in the current network
WSApplication.current_network.tables.each do |table|
  # For each table, iterate through each field
  table.fields.each do |field|
    # For each field, iterate through each row object
    WSApplication.current_network.row_objects(table.name).each do |row_object|
      # Add the current row object and field value to the validation array
      $validation << row_object
      $validation << row_object[field.name]
    end
  end
end

# Print out the contents of the validation array
puts $validation

# from xml file

#<tables id='rowobject'>
#<table name='hw_node'>
#  <group name='Node Definition'>
#    <field>node_id</field>
