class Attachments
	def initialize
		if WSApplication.ui?
			@net=WSApplication.current_network		## Uses current open network when run in UI
		else
			db=WSApplication.open('//localhost:40000/db', false)
			@dbnet=db.model_object_from_type_and_id 'Collection Network',1		## Run on Collection Network #1 in IE
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
		map=Hash.new
		@net.row_objects('cams_cctv_survey').each do |ro|
			attachments=ro.attachments
			attachments.each do |a|
				if a.db_ref.downcase[-4..-1]=='.pdf'
					if map[ro.contract_no].nil?
						pdf=Array.new
						pdf << a.purpose
						pdf << a.filename
						pdf << a.description
						pdf << a.db_ref
						map[ro.contract_no]=pdf
					else
						puts "Duplicate PDF for contract no #{ro.contract_no} in survey #{ro.id}"
					end
				end
			end
		end
		@net.transaction_begin
		@net.row_objects('cams_cctv_survey').each do |ro|
			if !map.has_key? ro.contract_no
				puts "Survey #{ro.id} - contract no not matched or can't find PDF"
			else
				found=false
				
				attachments=ro.attachments				
				attachments.each do |a|
					if a.db_ref.downcase[-4..-1]=='.pdf'
						found=true
						break
					end
				end
				if !found
					n=attachments.length
					attachments.length=n+1
					attachments[n].purpose=map[ro.contract_no][0]
					attachments[n].filename=map[ro.contract_no][1]
					attachments[n].description=map[ro.contract_no][2]
					attachments[n].db_ref=map[ro.contract_no][3]
					attachments.write
					ro.write
				end
					
			end
		end
		@net.transaction_commit
		if !WSApplication.ui?
			@dbnet.commit('PDF Distribute script run.')		##Commits the changes when the script is run via Exchange
			puts 'Committed'
		end
	end
end
fred=Attachments.new
fred.doit