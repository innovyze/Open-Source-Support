# Default root for WDS of C:\ProgramData\Innovyze\SNumbatData. To point at the database //localhost:40000 replaces the windows path. Don't include .sndb or .d folder names.
$master_db='//localhost:40000/Group/TEMP' #'//localhost:40000/DATABASE'

# Current folder from where the script is being run
$project_path=File.dirname(__FILE__)

# Database names and full paths (standalone and transportable)
$transportable_name="2025.1.0_Transportable.icmt"
$transportable_path="#{$project_path}\\#{$transportable_name}"

# Open master database
$db_master = WSApplication.open($master_db,false)

# Create transportable and open it
$transportable_db=WSApplication.create_transportable($transportable_path)
$transportable_db=WSApplication.open $transportable_path,false

puts "Begin copying data from #{$master_db} to #{$transportable_path}"

# Get all the root objects from the master database
$root_objects = $db_master.root_model_objects

# Iterate over each root object
$root_objects.each do |object|
  # Directly copy each object into the transportable database
  # copy_into_root(object, copy_results, copy_ground_models)
  $transportable_db.copy_into_root(object, true, true)
end

puts "All root data copied from #{$master_db} to #{$transportable_path}"