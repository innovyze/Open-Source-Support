# Get object representing RTC table
network = WSApplication.current_network
row_object = network.row_object('hw_rtc',nil)  

# Set the path and txt files that contain the imported and/or exported RTC text
path = 'E:/TEMP/'
imported_file = 'imported_rtc.txt'
exported_file = 'exported_rtc.txt'

# Select mode (1) Export or (2) Import
mode = 1

# Example 1: Export RTC from current network to a txt file
if mode == 1
    rtc_string = row_object['rtc_data']
    File.open(path + exported_file, 'w') { |file| file.write(rtc_string) }
    puts "File \'#{exported_file}\' exported to path \'#{path}\'"
end

# Example 2: Import RTC from a file into current network
if mode == 2
    import_rtc = File.read(path + imported_file)    
    network.transaction_begin
    row_object['rtc_data'] = import_rtc
    row_object.write
    network.transaction_commit
    puts "RTC imported from file \'#{imported_file}\' on path \'#{path}\'"
end