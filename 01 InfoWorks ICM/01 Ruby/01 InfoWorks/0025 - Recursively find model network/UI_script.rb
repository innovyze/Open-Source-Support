# UI Script: Recursively find all InfoWorks Networks in the current database
# This script searches through the entire database hierarchy (including nested model groups)
# and exports all "Model Network" objects to a CSV file with path, name, and ID

require 'csv'

puts "Searching current database for InfoWorks Networks..."
puts "=" * 70
puts ""

# Access the currently open database
$db = WSApplication.current_database

# Initialize processing queue with root objects
$toProcess = Array.new
$db.root_model_objects.each do |o|
	$toProcess << o
end

# Collect network information
networks = []

# Breadth-first search through database hierarchy
while $toProcess.size>0
	working = $toProcess.delete_at(0)
	if working.type == "Model Network"
		networks << {
			path: working.path,
			name: working.name,
			id: working.id
		}
	end
	working.children.each do |c|
		$toProcess << c
	end
end

# Generate CSV file path
timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
csv_filename = "InfoWorks_Networks_#{timestamp}.csv"
csv_path = File.join('C:\\temp', csv_filename)

# Write to CSV
CSV.open(csv_path, 'w') do |csv|
	# Header row
	csv << ['Path', 'Network Name', 'Object ID']
	
	# Data rows
	networks.each do |net|
		csv << [net[:path], net[:name], net[:id]]
	end
end

# Summary
puts "=" * 70
puts "Found #{networks.size} InfoWorks Network(s) in the database"
puts ""
puts "CSV file created: #{csv_path}"
puts "=" * 70
