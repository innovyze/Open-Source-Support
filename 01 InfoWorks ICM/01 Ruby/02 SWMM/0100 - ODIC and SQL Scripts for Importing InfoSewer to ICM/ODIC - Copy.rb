require 'FileUtils'

# Access the current open network in the application
open_net = WSApplication.current_network

# Prompt the user to select a folder for importing csv files
csv_dir = WSApplication.folder_dialog 'Select a folder to import files',  true 
puts "Importing CSV files from #{csv_dir}"

# Determine the directory of the current script to find the configuration files
cfg_dir = File.dirname(WSApplication.script_file)
puts "Configuration files found in #{cfg_dir}"

# Define the path for the error log file
err_file = csv_dir + '\errors.txt'

# Define a hash of layers to import, with each layer's configuration and shapefile
layers = {
    "Node" => { "cfg" => cfg_dir + '\Step1_InfoSewer_Node_csv.cfg', "csv" => csv_dir + '\Node.csv'},
    "Node" => { "cfg" => cfg_dir + '\Step1a_InfoSewer_Manhole_csv.cfg', "csv" => csv_dir + '\Manhole.csv'},
    "Node" => { "cfg" => cfg_dir + '\Step3_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg', "csv" => csv_dir + '\mhhyd.csv' },
    "Node" => { "cfg" => cfg_dir + '\Step8_Infosewer_wetwell_wwellhyd_csv.cfg', "csv" => csv_dir + '\wwellhyd.csv' }
}

# Iterate over each layer and import it into the network
layers.each do | layer, config |
    puts "Importing InfoSewer to ICM InfoWorks layer: #{layer}"

    # Skip the import if the shapefile for the layer doesn't exist
    if File.exist?( config["csv"] ) == false
        puts "CSV file not found for #{layer} layer - #{config["csv"]}"
        next
    end

    # Define options for the import process
    options = {
        "Error File" => err_file,    # Path to save errors encountered during import
        "Set Value Flag" => 'IS'    # Flag to indicate the import action
    }
    
    # Execute the import process
    open_net.odic_import_ex(
        'csv',            # Data Source Type
        config["cfg"],    # Field Mapping Configuration File
        options,          # Additional options
        layer,            # Target InfoWorks Layer for Import
        config["csv"]     # Location of the CSV files to import
    )

    # Log the completion of the import for this layer to the error file
    File.write(err_file, "\n End of #{layer} import \n", File.size(err_file))
end

# Read and output the contents of the error log file to the console
File.readlines(err_file).each do |line|
    puts line
end

# Indicate the completion of the import process
puts "Finished Import of InfosSewer to ICM InfoWorks"
