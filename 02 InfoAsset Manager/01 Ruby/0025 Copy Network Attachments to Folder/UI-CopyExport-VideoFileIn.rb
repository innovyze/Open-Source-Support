require 'Fileutils'

dest='C:\\Temp\\test\\'		## Set DESTINATION folder for files - end with double-backslash.

net=WSApplication.current_network
net.row_objects_selection('cams_cctv_survey').each do |o|
	if o.video_file_in!=nil && o.video_file_in.length>0
		if File.file?(o.video_file_in) == true
			copy=dest+File.basename(o.video_file_in)
			new=dest+File.basename(o.id.gsub(/[^0-9A-Za-z _-]/, ''))+File.extname(o.video_file_in)
				if File.file?(copy) == false
					FileUtils.cp o.video_file_in, copy
					puts o.id+" :SUCCESS: "+o.video_file_in+" >> "+copy
				elsif File.file?(copy) == true
					if File.file?(new) == false
						FileUtils.cp o.video_file_in, new
						puts o.id+" :SUCCESS: "+o.video_file_in+" >> "+new
					else
						puts o.id+" :FAIL: No file copied ["+File.basename(copy)+"] & ["+File.basename(new)+"] already exist in destination."
					end
				end
			else
				puts o.id+" :FAIL: Referenced file not found [#{o.video_file_in}]."
			end
		else
			puts o.id+" :FAIL: No file referenced on survey."
	end
end

