require 'csv'

# Read your CSV file into an array of arrays
csv_data = CSV.read('batch.csv')

# Iterate over each row in your CSV file
csv_data.each do |row|
  # Assign the values from your CSV file to your variables
  master_db = row[0] # Assumes master DB is in the first column
  cloud_db = row[1]  # Assumes cloud DB is in the second column

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
end