startingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
class Attachments
	def initialize
		if WSApplication.ui?
            @net=WSApplication.current_network ## Uses current open network when run in UI
        else
            db=WSApplication.open('//localhost:40000/db', false)
            @dbnet=db.model_object_from_type_and_id 'Collection Network',1 ## Run on Collection Network #1 in IE
            current_commit_id = @dbnet.current_commit_id
            latest_commit_id = @dbnet.latest_commit_id
                if(latest_commit_id > current_commit_id) then
                    puts "Updating from Commit ID #{current_commit_id} to Commit ID #{latest_commit_id}"
                    @dbnet.update
                else
                    puts 'Network is up to date'
                end
                @net=@dbnet.open
			end
		end
		def doit
	$map = Hash.new { |hash, key| hash[key] = [] }
	$added_db_refs = []

	@net.row_objects('cams_manhole_survey').each do |ro|
		if ro.node_id==nil || ro.node_id.size==0
			puts "No Node ID on Survey: #{ro.id}"
		else
			puts "Processing Survey: #{ro.id} Node ID: #{ro.node_id}"
			attachments = ro.attachments
			attachments.each do |a|
				if a.purpose.downcase == 'cctv video'
					pdf = []
					pdf << a.purpose
					pdf << a.filename
					pdf << a.description
					pdf << a.db_ref
					unless $added_db_refs.include?(a.db_ref)
						$map[ro.node_id] << pdf
						$added_db_refs << (a.db_ref)
						puts "Added for: #{ro.node_id} - #{pdf.join(', ')}"
					else
						puts "Duplicate for db_ref: #{a.db_ref} not added."
					end
				end
			end
		end
	end

	# $map.each do |node_id, pdfs|
		# puts "Job Number: #{node_id}"
		# pdfs.each do |pdf|
			# puts "  PDF: #{pdf.join(', ')}"
		# end
	# end
	# puts "\n$map: #{$map.inspect}\n\n"

	@net.transaction_begin
	@net.row_objects('cams_manhole_survey').each do |ro|
		puts "Processing survey ID: #{ro.id} with job number: #{ro.node_id}"
		if !$map.has_key?(ro.node_id)
			puts "Survey #{ro.id} - not matched or can't find attachment"
		else
			puts "Found match for survey ID: #{ro.id} with: #{ro.node_id}"
			$map[ro.node_id].each do |pdf|
				db_ref_match_found = false
				ro.attachments.each do |attachment|
					if attachment.db_ref.downcase == pdf[3].downcase
						db_ref_match_found = true
						break
					end
				end
					unless db_ref_match_found
						puts "Adding new attachment on survey: #{ro.id} for db_ref: #{pdf[3]}"
						attachments = ro.attachments
						n = attachments.length
						attachments.length = n + 1
						attachments[n].purpose = pdf[0]
						attachments[n].filename = pdf[1]
						attachments[n].description = pdf[2]
						attachments[n].db_ref = pdf[3]
						attachments.write
						ro.write
					else
						puts "Duplicate PDF for contract no #{ro.node_id} in survey #{ro.id} with db_ref #{pdf[3]}"
					end
				end
			end
		end
		@net.transaction_commit
		if !WSApplication.ui?
            @dbnet.commit('Attachment Distribute script run.') ##Commits the changes when the script is run via Exchange
            puts 'Committed'
        end
	end
end
fred=Attachments.new
fred.doit


endingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = endingTime - startingTime

puts "Done.  Time taken #{Time.at(elapsed).utc.strftime("%H:%M:%S")}"
