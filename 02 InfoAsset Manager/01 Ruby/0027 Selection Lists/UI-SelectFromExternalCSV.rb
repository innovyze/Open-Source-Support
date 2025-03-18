require 'csv'

csv_data = "C:\\TEMP\\test.csv"
## Data in first column of CSV, which has a header row.

array = []
CSV.foreach(csv_data, headers: true) do |csv_row|
  array << csv_row[0]
end
puts array.inspect


db=WSApplication.current_network 

db.row_objects('cams_manhole').each do |v|	
if array.include?(v.node_id)
		v.selected=true
	end
end