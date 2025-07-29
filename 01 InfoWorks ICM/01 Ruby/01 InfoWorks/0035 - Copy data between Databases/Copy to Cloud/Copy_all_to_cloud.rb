# Default root for WDS of C:\ProgramData\Innovyze\SNumbatData. To point at the database //localhost:40000 replaces the windows path. Don't include .sndb or .d folder names.
master_db='//localhost:40000/Group/TEMP' #'//localhost:40000/DATABASE'
# Easiest to grab from the additional information inside of ICM
cloud_db='cloud://Alex G@0d27b329cc853e210ec49a82/emea' #'cloud://NAME@IDSTRING/REGION'

db_master = WSApplication.open(master_db,false)
db_cloud = WSApplication.open(cloud_db,false)

puts "Begin copying data from #{master_db} to #{cloud_db}"

# Get all the root objects from the master database
root_objects = db_master.root_model_objects

# Iterate over each root object
root_objects.each do |object|
  # Check if object already exists in cloud database
  existing_object = db_cloud.find_root_model_object(object.type, object.name)

  # If the object doesn't exist in the cloud database, copy it
  if existing_object.nil?
    #copy_into_root(object, copy_results, copy_ground_models)
    db_cloud.copy_into_root(object, true, true)
    # Restrictions may apply https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=GUID-73BE3CC4-90DA-4C86-9488-F4287E372D52
  end
end

puts "All root data copied from #{master_db} to #{cloud_db}"