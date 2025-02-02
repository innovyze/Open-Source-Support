# Modified from Innovyze Ruby Documentation

# Display an input message box with a multi-line prompt and a title
user_input = WSApplication.input_box(
  "Once upon a time in the land of hydraulic modeling,\n" \
  "there were two mighty kingdoms: SWMM5 and ICM InfoWorks.\n" \
  "Both kingdoms thrived on managing water networks with great precision.\n" \
  "One day, someone sought to unite their strengths in a single UX.\n" \
  "What message would you send to the kingdoms to inspire this union?",
  'A Tale of Two H&H Kingdoms',
  'EPPA EPASWMM AND Wallingford Software in the Autodesk World!'
)

# Check the user's response
if user_input.nil?
  puts "Cancel button hit"
else
  puts "OK button hit, the input is: #{user_input}"
end