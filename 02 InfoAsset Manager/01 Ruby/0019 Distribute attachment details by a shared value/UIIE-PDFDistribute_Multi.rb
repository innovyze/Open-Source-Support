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

	@net.row_objects('cams_cctv_survey').each do |ro|
		if ro.job_number==nil || ro.job_number.size==0
			puts "No Job Number on Survey: #{ro.id}"
		else
			puts "Processing Survey: #{ro.id} Job Number: #{ro.job_number}"
			attachments = ro.attachments
			attachments.each do |a|
				if a.db_ref.downcase[-4..-1] == '.pdf'
					pdf = []
					pdf << a.purpose
					pdf << a.filename
					pdf << a.description
					pdf << a.db_ref
					unless $added_db_refs.include?(a.db_ref)
						$map[ro.job_number] << pdf
						$added_db_refs << (a.db_ref)
						puts "Added PDF for job number: #{ro.job_number} - #{pdf.join(', ')}"
					else
						puts "Duplicate PDF for db_ref: #{a.db_ref} not added."
					end
				end
			end
		end
	end

	# $map.each do |job_number, pdfs|
		# puts "Job Number: #{job_number}"
		# pdfs.each do |pdf|
			# puts "  PDF: #{pdf.join(', ')}"
		# end
	# end
	# puts "\n$map: #{$map.inspect}\n\n"

	@net.transaction_begin
	@net.row_objects('cams_cctv_survey').each do |ro|
		puts "Processing survey ID: #{ro.id} with job number: #{ro.job_number}"
		if !$map.has_key?(ro.job_number)
			puts "Survey #{ro.id} - contract no not matched or can't find PDF"
		else
			puts "Found match for survey ID: #{ro.id} with job number: #{ro.job_number}"
			$map[ro.job_number].each do |pdf|
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
						puts "Duplicate PDF for contract no #{ro.job_number} in survey #{ro.id} with db_ref #{pdf[3]}"
					end
				end
			end
		end
		@net.transaction_commit
		if !WSApplication.ui?
            @dbnet.commit('PDF Distribute script run.') ##Commits the changes when the script is run via Exchange
            puts 'Committed'
        end
	end
end
fred=Attachments.new
fred.doit


endingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = endingTime - startingTime

puts "Done.  Time taken #{Time.at(elapsed).utc.strftime("%H:%M:%S")}"
