# =============================================================================
# InfoWorks ICM - Copy Database to Cloud
# =============================================================================
# Copies all root objects from a source database to a cloud destination.
# Can be run standalone or called by Batch_copy_all_to_cloud.rb script.
#
# Usage:
#   - Standalone: Edit source_db and destination_db defaults below
#   - From Batch: Called automatically with command-line arguments
#
# Note: Opens destination database first to avoid transaction conflicts
#       when copying from transportable databases (.icmt files)
# =============================================================================

# Accept command-line arguments or use defaults
# Note: ICMExchange passes "Autodesk" (or similar) as ARGV[0], so actual args start at index 1
source_db = ARGV[1] || 'D:\Databases\MyDatabase.icmt'
destination_db = ARGV[2] || 'cloud://UserName@1234567890abcdef/region'

db_destination = WSApplication.open(destination_db, false)
db_source = WSApplication.open(source_db, false)

puts "Begin copying data from #{source_db} to #{destination_db}"

# Get all the root objects from the source database
root_objects = db_source.root_model_objects
root_objects = root_objects.to_a if root_objects.respond_to?(:to_a)

# Copy all objects to destination database root
root_objects.each do |object|
  next if object.nil?
  
  db_destination.copy_into_root(object, true, true)
end

puts "All root data copied from #{source_db} to #{destination_db}"