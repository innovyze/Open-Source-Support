## Export Choice List values from the database/network

require 'csv'											##call on the Ruby library CSV function

CSV.open("c:\\temp\\choices.csv", "wb") do |csv|		##open the CSV file and iterate through it

	nw = WSApplication.current_network					##use the current open network
	
		fc = nw.field_choices('cams_cctv_survey','category_code')					##select the Field Choice ‘text’ codes for: CCTV Survey – Category Code
		
		fd = nw.field_choice_descriptions('cams_cctv_survey','category_code')		##select the Field Choice descriptions codes for: CCTV Survey – Category Code
		
		i=0										##this starts a counter, needed to iterate through all the values
		
		tbl='cams_cctv_survey'					##sets a table name variable for the export
		
		col='category_code'						##sets a field name variable for the export
		
		if fc and fd then						##runs both fc & fd together
		
			fc.each do | value|											##runs through each fc to retrieve all values
			
			puts("""#{tbl}"",""#{col}"",""#{value}"",""#{fd[i]}""")		##where the output should go: to screen (“puts”) and what the output should be
			
			csv << ["#{tbl}", "#{col}", "#{value}", "#{fd[i]}"]			##where the output should go: csv (“<<” inserts as an additional line) and what the output should be
			
			i=i+1														##add 1 to the interaction counter
			
			end
		end
 
end
