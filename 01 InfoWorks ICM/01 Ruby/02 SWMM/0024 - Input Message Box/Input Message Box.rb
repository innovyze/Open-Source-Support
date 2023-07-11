# Modified from Innovyze Ruby Documentation

output = WSApplication.input_box("Message box prompt line 1\nMessage box prompt line 2\nMessage Box prompt line 3", 'Message box title', 'Here is some initial text')

if output.nil?
  puts "Cancel button hit"
else
  puts "OK button hit, the input is: #{output}"
end
