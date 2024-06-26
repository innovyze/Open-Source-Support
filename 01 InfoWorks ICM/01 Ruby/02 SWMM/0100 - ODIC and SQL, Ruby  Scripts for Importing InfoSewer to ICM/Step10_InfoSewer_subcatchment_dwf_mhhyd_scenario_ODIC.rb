require 'csv'
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
  val=WSApplication.prompt "Manhole Loadings for InfoSewer Scenario",
  [
  ['Scenario Name that Matches the InfoSewer Dataset','String',nil,nil,'FOLDER','Manhole Folder']
  ],false
    # Exit the program if the user cancelled the prompt
    return  if val.nil?
  csv  = val[0] + "\\mhhyd.csv"
  puts csv

  cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
  puts cfg

# List of import steps
import_steps = [
    ['Subcatchment','Step7_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg', 'mhhyd.csv']
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
