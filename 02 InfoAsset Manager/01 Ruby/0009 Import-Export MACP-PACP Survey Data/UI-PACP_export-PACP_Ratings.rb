## Export surveys to the PACP 7 Access MDB format including PACP Ratings

require 'win32ole'
require 'csv'

# Get the network
net = WSApplication.current_network

# Prompt for variables
val=WSApplication.prompt "Export PACP 7",
[
['MDB filename:','String',nil,nil,'FILE',false,'mdb','PACP7 Export File',false],
['Export SELECTION?','Boolean',true],
['Export InfoAsset Survey ID to Custom_Field:','Number',1,0,'RANGE',1,10],
['Export IMAGES?','Boolean',false],
['Export Imperial Units?','Boolean',true]
],false
if val==nil
	WSApplication.message_box("Parameters dialog closed\nScript cancelled",'OK','!',nil)
else
puts "[Filename, Selection, InfoAsset ID, Images, Imperial]\n"+val.to_s

exportFile=val[0].to_s
exportSel=val[1]
exportID=val[2].to_i
exportImages=val[3]
exportImperial=val[4]

if val[0]==nil
	WSApplication.message_box("Export file required\nScript cancelled",'OK','!',nil)
elsif val[2]==nil
	WSApplication.message_box("InfoAsset Survey ID to Custom_Field required\nScript cancelled",'OK','!',nil)
else

exportLog=File.dirname(exportFile)+'\\exportLog.txt'

# Export to PACP7 mdb
expOptions=Hash.new
expOptions["Selection Only"]=exportSel				## Boolean, true for selection only, all objects otherwise | Default=false
expOptions["Images"]=exportImages						## Boolean, if true the images are exported to same location as .mdb | Default=false
expOptions["Imperial"]=exportImperial						## Boolean, true for imperial values (the WSApplication setting for units is ignored) | Default=false
expOptions["InfoAsset"]=exportID						## nil or an Integer, if an integer must be between 1 and 10 – corresponds to the dialog setting | Default=nil
expOptions["Format"]="7"						## String, PACP db version format (must be "6" or "7") | Default=7
expOptions["LogFile"]=exportLog				## String, path of a log file, if nil or blank then nothing is logged to the file | Default=nil
puts expOptions
net.PACP_export(exportFile,expOptions)





# Initialize arrays to store field information
fields = Array.new
fieldsHash = Hash.new

# Get the field structure of the 'details' blob field
net.table('cams_cctv_survey').fields.each do |f|
    if f.name == 'details'
        n = 0
        f.fields.each do |bf|
            fields << bf.name
            fieldsHash[bf.name] = n
            n += 1
        end
        break
    end
end

puts "Found #{fields.length} fields in details blob:"
fields.each_with_index do |field, index|
    puts "  #{index}: #{field}"
end
puts "\n"

# Check if required fields exist
missingFields = []
if !fieldsHash.key?('service_score')
    missingFields << 'service_score'
end
if !fieldsHash.key?('structural_score')
    missingFields << 'structural_score'
end

if missingFields.length > 0
    puts "ERROR: Required fields not found in details blob: #{missingFields.join(', ')}"
    puts "Available fields: #{fields.join(', ')}"
    exit
end

puts "service_score field found at index #{fieldsHash['service_score']}"
puts "structural_score field found at index #{fieldsHash['structural_score']}"

# Check for PACP fields (optional - won't fail if missing)
pacpFields = ['pacp_struct_quick_rating', 'pacp_oandm_quick_rating', 'pacp_overall_quick_rating', 
              'pacp_struct_index_rating', 'pacp_oandm_index_rating', 'pacp_overall_index_rating', 'likelihood_score']
availablePacpFields = []
pacpFields.each do |field|
    if fieldsHash.key?(field)
        availablePacpFields << field
        puts "#{field} field found at index #{fieldsHash[field]}"
    else
        puts "WARNING: #{field} field not found - will be set to null"
    end
end
puts "\n"

# Array to store survey results
surveyResults = Array.new

# Counter for total surveys processed
totalSurveys = 0

# Initialize counters for all score values (1-5)
totalServiceScoreCounts = {1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0}
totalStructuralScoreCounts = {1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0}

# Iterate through CCTV surveys (all or selected based on exportSel variable)
if exportSel
    survey_objects = net.row_objects_selection('cams_cctv_survey')
    puts "Processing selected CCTV surveys only..."
else
    survey_objects = net.row_objects('cams_cctv_survey')
    puts "Processing all CCTV surveys..."
end

survey_objects.each do |survey|
    puts "Processing Survey ID: #{survey.id}"
    
    # Get the details blob
    details = survey.details
    
    # Initialize counters for this survey
    serviceScoreCounts = {1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0}
    structuralScoreCounts = {1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0}
    
    if details.size > 0
        puts "  Found #{details.size} detail records"
        
        # Process each detail record
        (0...details.size).each do |i|
            serviceScore = details[i]['service_score']
            structuralScore = details[i]['structural_score']
            
            # Count service_score values (1-5) - handle null values
            if !serviceScore.nil? && serviceScore.is_a?(Numeric) && serviceScore >= 1 && serviceScore <= 5
                serviceScoreCounts[serviceScore.to_i] += 1
                totalServiceScoreCounts[serviceScore.to_i] += 1
            end
            
            # Count structural_score values (1-5) - handle null values
            if !structuralScore.nil? && structuralScore.is_a?(Numeric) && structuralScore >= 1 && structuralScore <= 5
                structuralScoreCounts[structuralScore.to_i] += 1
                totalStructuralScoreCounts[structuralScore.to_i] += 1
            end
            
            # Display values, showing "null" for nil values
            serviceDisplay = serviceScore.nil? ? "null" : serviceScore.to_s
            structuralDisplay = structuralScore.nil? ? "null" : structuralScore.to_s
            puts "    Detail #{i+1}: service_score=#{serviceDisplay}, structural_score=#{structuralDisplay}"
        end
        
        puts "  Survey #{survey.id} summary:"
        puts "    Service scores: #{serviceScoreCounts}"
        puts "    Structural scores: #{structuralScoreCounts}"
    else
        puts "  No details found"
    end
    
    # Calculate totals for cleaner code
    stPipeRating = (structuralScoreCounts[1] * 1) + (structuralScoreCounts[2] * 2) + (structuralScoreCounts[3] * 3) + (structuralScoreCounts[4] * 4) + (structuralScoreCounts[5] * 5)
    omPipeRating = (serviceScoreCounts[1] * 1) + (serviceScoreCounts[2] * 2) + (serviceScoreCounts[3] * 3) + (serviceScoreCounts[4] * 4) + (serviceScoreCounts[5] * 5)
    overallPipeRating = stPipeRating + omPipeRating
    
    # Get PACP field values from the survey object (top-level fields)
    pacpValues = {}
    pacpFields.each do |field|
        value = survey[field]
        pacpValues[field] = value.nil? ? nil : value
    end
    
    # Store the result with weighted values (count * score) and PACP values
    surveyResult = {
        'survey_id' => survey.id,
        'structural_score_1' => structuralScoreCounts[1] * 1,
        'structural_score_2' => structuralScoreCounts[2] * 2,
        'structural_score_3' => structuralScoreCounts[3] * 3,
        'structural_score_4' => structuralScoreCounts[4] * 4,
        'structural_score_5' => structuralScoreCounts[5] * 5,
        'service_score_1' => serviceScoreCounts[1] * 1,
        'service_score_2' => serviceScoreCounts[2] * 2,
        'service_score_3' => serviceScoreCounts[3] * 3,
        'service_score_4' => serviceScoreCounts[4] * 4,
        'service_score_5' => serviceScoreCounts[5] * 5,
        'STPipeRating' => stPipeRating,
        'OMPipeRating' => omPipeRating,
        'OverallPipeRating' => overallPipeRating,
        'STQuickRating' => pacpValues['pacp_struct_quick_rating'],
        'OMQuickRating' => pacpValues['pacp_oandm_quick_rating'],
        'PACPQuickRating' => pacpValues['pacp_overall_quick_rating'],
        'STPipeRatingsIndex' => pacpValues['pacp_struct_index_rating'],
        'OMPipeRatingsIndex' => pacpValues['pacp_oandm_index_rating'],
        'OverallPipeRatingsIndex' => pacpValues['pacp_overall_index_rating'],
        'LoFPACP' => pacpValues['likelihood_score']
    }
    
    surveyResults << surveyResult
    totalSurveys += 1
    puts ""
end

puts "Summary:"
puts "Total surveys processed: #{totalSurveys}"
puts ""
puts "Total service_score counts (raw counts):"
(1..5).each do |score|
    puts "  Score #{score}: #{totalServiceScoreCounts[score]} records"
end
puts ""
puts "Total structural_score counts (raw counts):"
(1..5).each do |score|
    puts "  Score #{score}: #{totalStructuralScoreCounts[score]} records"
end
puts ""
puts "Total weighted service_score values:"
(1..5).each do |score|
    weighted = totalServiceScoreCounts[score] * score
    puts "  Score #{score}: #{totalServiceScoreCounts[score]} records × #{score} = #{weighted}"
end
puts ""
puts "Total weighted structural_score values:"
(1..5).each do |score|
    weighted = totalStructuralScoreCounts[score] * score
    puts "  Score #{score}: #{totalStructuralScoreCounts[score]} records × #{score} = #{weighted}"
end
puts ""

# Export to existing Access MDB file
if surveyResults.length > 0
    mdb_filename = exportFile
    
    begin
        # Check if file exists
        if !File.exist?(mdb_filename)
            puts "ERROR: Database file does not exist at: #{mdb_filename}"
            exit
        end
        
        puts "Connecting to database: #{mdb_filename}"
        
        # Create Access database connection
        conn = WIN32OLE.new('ADODB.Connection')
        
        # Try ACE provider first (newer), then fall back to Jet
        begin
            conn.Open("Provider=Microsoft.ACE.OLEDB.12.0;Data Source=#{mdb_filename};")
            puts "Connected using ACE OLEDB provider"
        rescue => e1
            puts "ACE provider failed: #{e1.message}"
            begin
                conn.Open("Provider=Microsoft.Jet.OLEDB.4.0;Data Source=#{mdb_filename};")
                puts "Connected using Jet OLEDB provider"
            rescue => e2
                puts "Jet provider also failed: #{e2.message}"
                raise e2
            end
        end
        
        puts "Successfully connected to database"
        
        # Check if PACP_Ratings table exists and clear it
        begin
            result = conn.Execute("DELETE FROM PACP_Ratings")
            puts "Cleared existing data from PACP_Ratings table"
            puts "Records deleted: #{result.RecordsAffected}" if result.respond_to?(:RecordsAffected)
        rescue => e
            puts "Warning: Could not clear PACP_Ratings table: #{e.message}"
            puts "Table may not exist or may have different structure"
            
            # Try to check if table exists
            begin
                test_result = conn.Execute("SELECT COUNT(*) FROM PACP_Ratings")
                puts "Table exists - record count: #{test_result.Fields(0).Value}"
            rescue => e2
                puts "Table does not exist or cannot be accessed: #{e2.message}"
                puts "Available tables:"
                # Try to list tables
                begin
                    schema_result = conn.Execute("SELECT Name FROM MSysObjects WHERE Type=1 AND Flags=0")
                    while !schema_result.EOF
                        puts "  - #{schema_result.Fields(0).Value}"
                        schema_result.MoveNext
                    end
                rescue => e3
                    puts "Could not list tables: #{e3.message}"
                end
            end
        end
        
        # Check table structure
        begin
            puts "Checking PACP_Ratings table structure..."
            structure_result = conn.Execute("SELECT TOP 1 * FROM PACP_Ratings")
            puts "Table structure check successful"
        rescue => e
            puts "Cannot access PACP_Ratings table structure: #{e.message}"
        end
        
        # First, get the mapping between survey_id and InspectionID from PACP_Custom_Fields table
        # Use the exportID variable to determine which Custom_Field to use
        custom_field_names = {
            1 => 'Custom_Field_One',
            2 => 'Custom_Field_Two',
            3 => 'Custom_Field_Three',
            4 => 'Custom_Field_Four',
            5 => 'Custom_Field_Five',
            6 => 'Custom_Field_Six',
            7 => 'Custom_Field_Seven',
            8 => 'Custom_Field_Eight',
            9 => 'Custom_Field_Nine',
            10 => 'Custom_Field_Ten'
        }
        
        custom_field_name = custom_field_names[exportID]
        if custom_field_name.nil?
            puts "ERROR: Invalid exportID value: #{exportID}. Must be between 1 and 10."
            exit
        end
        
        puts "Looking up InspectionID values from PACP_Custom_Fields table using #{custom_field_name}..."
        
        begin
            # Get both InspectionID and the specified Custom_Field together
            mapping_sql = "SELECT InspectionID, #{custom_field_name} FROM PACP_Custom_Fields WHERE #{custom_field_name} IS NOT NULL"
            mapping_result = conn.Execute(mapping_sql)
            survey_id_to_inspection_id = {}
            
            while !mapping_result.EOF
                inspection_id = mapping_result.Fields(0).Value
                custom_field_value = mapping_result.Fields(1).Value
                if !inspection_id.nil? && !custom_field_value.nil?
                    survey_id_to_inspection_id[custom_field_value.to_s] = inspection_id
                end
                mapping_result.MoveNext
            end
            
            puts "Found #{survey_id_to_inspection_id.length} custom field mappings"
            
        rescue => e
            puts "Warning: Could not read PACP_Custom_Fields table: #{e.message}"
            survey_id_to_inspection_id = {}
        end
        
        # Insert data into existing PACP_Ratings table
        # Note: RatingID is AutoNumber, so we don't include it in the INSERT statement
        puts "Inserting #{surveyResults.length} records..."
        
        surveyResults.each_with_index do |result, index|
            begin
                # Look up the InspectionID for this survey_id
                inspection_id = survey_id_to_inspection_id[result['survey_id'].to_s]
                
                if inspection_id.nil?
                    puts "Warning: No InspectionID found for survey_id '#{result['survey_id']}' - skipping record"
                    next
                end
                
                # Debug: Show the values we're trying to insert
                puts "Debug - Record #{index + 1} values:"
                puts "  Survey ID: '#{result['survey_id']}' -> InspectionID: #{inspection_id}"
                puts "  STQuickRating: #{result['STQuickRating']} (#{result['STQuickRating'].class})"
                puts "  OMQuickRating: #{result['OMQuickRating']} (#{result['OMQuickRating'].class})"
                puts "  PACPQuickRating: #{result['PACPQuickRating']} (#{result['PACPQuickRating'].class})"
                
                # Fix: InspectionID is Number field, STQuickRating/OMQuickRating/PACPQuickRating are Short Text fields
                insertSQL = <<-SQL
                    INSERT INTO PACP_Ratings (
                        InspectionID,
                        STGradeScore1, STGradeScore2, STGradeScore3, STGradeScore4, STGradeScore5,
                        OMGradeScore1, OMGradeScore2, OMGradeScore3, OMGradeScore4, OMGradeScore5,
                        STPipeRating, OMPipeRating, OverallPipeRating,
                        STQuickRating, OMQuickRating, PACPQuickRating,
                        STPipeRatingsIndex, OMPipeRatingsIndex, OverallPipeRatingsIndex, LoFPACP
                    ) VALUES (
                        #{inspection_id},
                        #{result['structural_score_1'] || 0},
                        #{result['structural_score_2'] || 0},
                        #{result['structural_score_3'] || 0},
                        #{result['structural_score_4'] || 0},
                        #{result['structural_score_5'] || 0},
                        #{result['service_score_1'] || 0},
                        #{result['service_score_2'] || 0},
                        #{result['service_score_3'] || 0},
                        #{result['service_score_4'] || 0},
                        #{result['service_score_5'] || 0},
                        #{result['STPipeRating'] || 0},
                        #{result['OMPipeRating'] || 0},
                        #{result['OverallPipeRating'] || 0},
                        #{result['STQuickRating'].nil? ? 'NULL' : "'#{result['STQuickRating'].to_s.gsub("'", "''")}'"},
                        #{result['OMQuickRating'].nil? ? 'NULL' : "'#{result['OMQuickRating'].to_s.gsub("'", "''")}'"},
                        #{result['PACPQuickRating'].nil? ? 'NULL' : "'#{result['PACPQuickRating'].to_s.gsub("'", "''")}'"},
                        #{result['STPipeRatingsIndex'].nil? ? 'NULL' : result['STPipeRatingsIndex']},
                        #{result['OMPipeRatingsIndex'].nil? ? 'NULL' : result['OMPipeRatingsIndex']},
                        #{result['OverallPipeRatingsIndex'].nil? ? 'NULL' : result['OverallPipeRatingsIndex']},
                        #{result['LoFPACP'].nil? ? 'NULL' : result['LoFPACP']}
                    )
                SQL
                
                insert_result = conn.Execute(insertSQL)
                puts "Record #{index + 1}/#{surveyResults.length} inserted successfully"
                
                # Check if the insert actually worked by counting records
                if (index + 1) % 5 == 0  # Check every 5 records
                    count_result = conn.Execute("SELECT COUNT(*) FROM PACP_Ratings")
                    current_count = count_result.Fields(0).Value
                    puts "  Current record count in table: #{current_count}"
                end
                
            rescue => e
                puts "ERROR inserting record #{index + 1}: #{e.message}"
                puts "SQL: #{insertSQL}"
                break
            end
        end
        
        # Verify the insert by counting records and showing sample data
        begin
            count_result = conn.Execute("SELECT COUNT(*) FROM PACP_Ratings")
            record_count = count_result.Fields(0).Value
            puts "Verification: PACP_Ratings table now contains #{record_count} records"
            
            # Show a sample of the data that was inserted
            if record_count > 0
                puts "Sample data from PACP_Ratings table:"
                sample_result = conn.Execute("SELECT TOP 3 InspectionID, STPipeRating, OMPipeRating, OverallPipeRating FROM PACP_Ratings")
                sample_count = 0
                while !sample_result.EOF && sample_count < 3
                    puts "  InspectionID: #{sample_result.Fields(0).Value}, STPipeRating: #{sample_result.Fields(1).Value}, OMPipeRating: #{sample_result.Fields(2).Value}, OverallPipeRating: #{sample_result.Fields(3).Value}"
                    sample_result.MoveNext
                    sample_count += 1
                end
            end
        rescue => e
            puts "Could not verify record count: #{e.message}"
        end
        
        conn.Close
        puts "Database connection closed"
        
        puts "Data export completed to: #{mdb_filename}"
        puts "Exported #{surveyResults.length} survey records to PACP_Ratings table"
        
        # Display results in console
        puts "\nResults (weighted values - count × score + PACP ratings):"
        puts "Survey ID\t\tSTPipeRating\tOMPipeRating\tOverallPipeRating\tSTQuickRating\tOMQuickRating\tPACPQuickRating\tSTPipeRatingsIndex\tOMPipeRatingsIndex\tOverallPipeRatingsIndex\tLoFPACP"
        puts "-" * 200
        surveyResults.each do |result|
            puts "#{result['survey_id']}\t\t#{result['STPipeRating']}\t\t#{result['OMPipeRating']}\t\t#{result['OverallPipeRating']}\t\t#{result['STQuickRating']}\t\t#{result['OMQuickRating']}\t\t#{result['PACPQuickRating']}\t\t#{result['STPipeRatingsIndex']}\t\t#{result['OMPipeRatingsIndex']}\t\t#{result['OverallPipeRatingsIndex']}\t\t#{result['LoFPACP']}"
        end
        
    rescue => e
        puts "Error writing to Access database: #{e.message}"
        puts "Make sure the database file exists and Microsoft Access Database Engine is installed"
        puts "Database file should be at: #{mdb_filename}"
        puts "Full error details: #{e.backtrace.join('\n')}"
        
        # Fallback to CSV export
        puts "\nFalling back to CSV export..."
        csv_filename = "C:\\TEMP\\02060385.TRA\\CCTV_Survey_Data.csv"
        
        begin
            CSV.open(csv_filename, "w") do |csv|
                # Write header row
                header = ['InspectionID']
                header += ['STGradeScore1', 'STGradeScore2', 'STGradeScore3', 'STGradeScore4', 'STGradeScore5']
                header += ['OMGradeScore1', 'OMGradeScore2', 'OMGradeScore3', 'OMGradeScore4', 'OMGradeScore5']
                header += ['STPipeRating', 'OMPipeRating', 'OverallPipeRating']
                header += ['STQuickRating', 'OMQuickRating', 'PACPQuickRating']
                header += ['STPipeRatingsIndex', 'OMPipeRatingsIndex', 'OverallPipeRatingsIndex', 'LoFPACP']
                csv << header
                
                # Write data rows
                surveyResults.each do |result|
                    row = [result['survey_id']]
                    row += [result['structural_score_1'], result['structural_score_2'], result['structural_score_3'], result['structural_score_4'], result['structural_score_5']]
                    row += [result['service_score_1'], result['service_score_2'], result['service_score_3'], result['service_score_4'], result['service_score_5']]
                    row += [result['STPipeRating'], result['OMPipeRating'], result['OverallPipeRating']]
                    row += [result['STQuickRating'], result['OMQuickRating'], result['PACPQuickRating']]
                    row += [result['STPipeRatingsIndex'], result['OMPipeRatingsIndex'], result['OverallPipeRatingsIndex'], result['LoFPACP']]
                    csv << row
                end
            end
            
            puts "Data successfully exported to CSV: #{csv_filename}"
            puts "Exported #{surveyResults.length} survey records"
            
        rescue => csv_error
            puts "CSV export also failed: #{csv_error.message}"
        end
    end
else
    puts "No data to export"
end

puts "\nScript completed successfully!"

end
end