# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step8_Infosewer_wetwell_wwellhyd_csv.cfg', 'wwellhyd.csv']
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
