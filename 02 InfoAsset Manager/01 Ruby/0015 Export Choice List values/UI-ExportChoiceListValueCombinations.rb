# Displays on screen (line 21) & outputs to CSV (line 22) a combination of all choice list Values separated by commas.

require 'csv'

CSV.open("c:\\temp\\cohortChoices.csv", "wb") do |csv|

	nw = WSApplication.current_network
		
	fc = nw.field_choices('cams_pipe','system_type')
	fd = nw.field_choices('cams_pipe','pipe_material')
	fe = nw.field_choices('cams_pipe','user_text_1')
	ff = nw.field_choices('cams_pipe','user_text_2')

	i=0

	fc.each do |v|
		fd.each do |w|
			fe.each do |x|
				ff.each do |y|
	
					puts("#{v}"",""#{w}"",""#{x}"",""#{y}")
					csv << ["#{v}"",""#{w}"",""#{x}"",""#{y}"]
					i=i+1
					
				end
			end
		end
	end
end