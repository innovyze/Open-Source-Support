# Access the current open network in the application
cn = WSApplication.current_network

# Define the configuration and CSV file paths
# The user is prompted to select the folders containing the configuration and CSV files
val = WSApplication.prompt("ODIC CFG Files Read by this Ruby Code to Convert Infosewer to ICM InfoWorks", [
    ['Pick the IEDB Folder', 'String', nil, nil, 'FOLDER', 'IEDB Folder'],
    ['Pick the CFG File Folder', 'String', nil, nil, 'FOLDER', 'CFG Folder'],
    ['ODIC CFG Files Read by this Ruby Code', 'String'],
    ['Step01_InfoSewer_Node_csv.cfg', 'String'],
    ['Step02_InfoSewer_Link_csv.cfg', 'String'],
    ['Step05_InfoSewer_pump_curve_pumphyd_csv.cfg', 'String'],
    ['Step06_InfoSewer_pump_control_control_csv.cfg', 'String'],
    ['Step08_InfoSewer_wetwell_wwellhyd_csv.cfg', 'String']
    ], false)
  csv = val[0]
  cfg = val[1]
  puts csv
  puts cfg

# List of import steps
# Each step is an array that includes the layer name, the configuration file name, and the CSV file name
import_steps = [
    ['Node', 'Step01_InfoSewer_Node_csv.cfg', 'Node.csv'],
    ['Node', 'Step01a_InfoSewer_Manhole_csv.cfg', 'manhole.csv'],
    ['Conduit', 'Step02_InfoSewer_Link_csv.cfg', 'Link.csv'],
    ['Pump', 'Step05_InfoSewer_pump_curve_pumphyd_csv.cfg', 'pumphyd.csv'],
    ['Pump', 'Step06_InfoSewer_pump_control_control_csv.cfg', 'control.csv'],
    ['Node', 'Step08_InfoSewer_wetwell_wwellhyd_csv.cfg', 'wwellhyd.csv']
]

# Iterate over each import step
import_steps.each do |layer, cfg_file, csv_file|
    begin
        # Import the data from the CSV file to the specified layer using the specified configuration file
        cn.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        # Print a message indicating that the layer has been imported
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        # If an error occurs during the import, catch the error and print an error message
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Print a message indicating that the import process is finished
puts "Finished Import of InfoSewer to ICM InfoWorks"