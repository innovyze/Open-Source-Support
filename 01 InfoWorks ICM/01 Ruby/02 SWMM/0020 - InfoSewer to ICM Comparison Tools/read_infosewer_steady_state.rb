# Prompt the user to select any .rpt file
steady_rpt_path = WSApplication.file_dialog(false, "Select an RPT file", "*.rpt", "", 
false, true)


# Check if the user selected a file
if steady_rpt_path.nil?
  puts "No file selected. Exiting script."
  exit
end

# Check if the selected file is steady.rpt
unless File.basename(steady_rpt_path) == 'STEADY.RPT'
  puts "Selected file is not steady.rpt. Exiting script."
  exit
end

puts "steady.rpt file found at: #{steady_rpt_path}"

# You can add further processing of the steady.rpt file here if needed