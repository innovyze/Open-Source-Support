# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Subcatchment', 'Step7_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg', 'mhhyd.csv']
]

begin
  import_steps.each do |layer, cfg_file, csv_file|
    open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
    puts "Imported #{layer} layer from #{cfg_file}"
  end
  
rescue Errno::ENOENT => e
  puts "File not found error: #{e.message}"
rescue Errno::EACCES => e
  puts "File access error: #{e.message}"
rescue StandardError => e
  puts "An error occurred: #{e.message}"
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"