# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
# The user is prompted to select the folders containing the Configuration (CFG) and CSV files
csv = WSApplication.prompt("InfoSewer IEDB Folder", [
    ['Pick the IEDB Folder', 'String', nil, nil, 'FOLDER', 'Scenario Folder'],
    ['Pick the CFG Folder', 'String', nil, nil, 'FOLDER', 'CFG File Folder']
], false)
csv_folder = csv[0]
cfg_folder = csv[1]
puts csv_folder
puts cfg_folder

# List of import steps
import_steps = [
    ['Node', 'InfoSewer_to_ICM-SWMM_Additional_DWF_InfoSewer_XLOAD_csv.cfg', 'Xload.csv'],
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg_folder, cfg_file), nil, layer, File.join(csv_folder, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM SWMM"