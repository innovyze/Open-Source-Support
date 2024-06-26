# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\dickinre\Desktop\NLV_Model_2021_09_16_final\NLV_Model_2021_09_16_final\MPU_MODEL_UPDATE_20210916.IEDB\Manhole\MH2020-2'
puts csv
puts cfg

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

