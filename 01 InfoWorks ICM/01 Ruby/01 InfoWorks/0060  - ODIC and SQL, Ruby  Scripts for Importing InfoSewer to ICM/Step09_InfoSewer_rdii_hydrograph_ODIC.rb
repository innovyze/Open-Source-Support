# Access the current open network in the application
open_net = WSApplication.current_network

# Prompt the user to pick a folder
csv = WSApplication.prompt "Folder for an InfoSewer IED", 
[ ['Pick the IEDB Folder ','String',nil,nil,'FOLDER','IEDB Folder']], false

cfg = 'C:\\Users\\dickinre\\Documents\\Open-Source-Support-main\\01 InfoWorks ICM\\InfoSewer to ICM\\Open-Source-Support\\01 InfoWorks ICM\\01 Ruby\\02 SWMM\\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'

puts "CSV Folder: #{csv}"
puts "Config Folder: #{cfg}"

# List of import steps
import_steps = [
  ['RTK Hydrograph', 'Step9_rdii_hydrograph_csv.cfg', 'Hydrograph.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
  begin
    cfg_path = File.join(cfg, cfg_file)
    csv_path = File.join(csv, csv_file)

    # Check if the files exist before trying to import
    if File.exist?(cfg_path) && File.exist?(csv_path)
      open_net.odic_import_ex('csv', cfg_path, nil, layer, csv_path)
      puts "Imported #{layer} layer from #{cfg_file}"
    else
      puts "Could not find files: #{cfg_path}, #{csv_path}"
    end
  rescue StandardError => e
    puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
  end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"