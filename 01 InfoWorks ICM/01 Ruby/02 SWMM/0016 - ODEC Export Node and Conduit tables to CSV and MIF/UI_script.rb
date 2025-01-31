require 'date'

# Sets the current directory to a user defined location
Dir.chdir 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\ICM SWMM Ruby\0012 - ODEC Export Node and Conduit tables to CSV and MIF'
cfg_file = './ICMFieldMapping.cfg'
export_date = DateTime.now.strftime("%Y%d%m%H%S")

# Network variables and WSOpenNetwork conversion to WSModelObject
net = WSApplication.current_network
mo = net.model_object

# ODEC method options
options=Hash.new
options['Error File'] = '.\ICMExportErrors.txt'
# options['Export Selection'] = true

# Export (with timer)
outputs = Array.new
outputs << 'CSV'
outputs << 'MIF'

tables = Array.new
tables << 'Node'
tables << 'Conduit'

outputs.each do |output|
    tables.each do |table|
        puts "#{table} - #{output} export commenced: #{DateTime.now.to_time}"
        file_name = "#{export_date} #{mo.name} - #{table}"
        net.odec_export_ex(output, cfg_file, options, table, file_name + ('.csv' if output == 'CSV').to_s)
        puts "=> Exported file: \"#{Dir.getwd}/#{file_name}\""
        puts "#{table} - #{output} export complete: #{DateTime.now.to_time}"
        puts ''
    end
end