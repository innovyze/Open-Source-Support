# Access the current open network in the application
open_net = WSApplication.current_network

  # Define the configuration and CSV file paths
  val = WSApplication.prompt "Pipe Hydraulics for an InfoSewer Scenario", [
    ['Pick the Scenario Name that Matches the InfoSewer Dataset ', 'String', nil, nil, 'FOLDER', 'Pipe Folder']
  ], false

# List of import steps
import_steps = [
    ['Node', 'Step18_User_123_ICM_SWMM_mhhyd_csv.cfg', 'mhhyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"

