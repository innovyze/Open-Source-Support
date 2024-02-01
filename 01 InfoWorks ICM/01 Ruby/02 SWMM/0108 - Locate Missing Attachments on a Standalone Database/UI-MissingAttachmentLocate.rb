class Images
	def initialize
		@net=WSApplication.current_network
		@missing=false
		@root='C:\\Temp\\34D08B56-C9D9-437B-A9F5-B3089279E6AB\\Extras\\'
	end
	def handleimage(t,id,purpose,filename)
		if !filename.nil? && filename.strip.length>0
			found=false
			if File.exists? @root+filename
				found=true
			end
			if !found
				puts "#{t},#{id},#{purpose},#{filename.strip}"
				@missing=true
			end
		end
	end 
	def doit
		['cams_cctv_survey','cams_manhole_survey'].each do |t|
			@net.row_objects(t).each do |ro|
				details=ro.details
				details.each do |d|
					handleimage(t,ro.id,'details image',d.detail_image)
				end
				attachments=ro.attachments
				attachments.each do |a|
					handleimage(t,ro.id,"attachments #{a.purpose}",a.db_ref)
				end
				if t=='cams_manhole_survey'
					handleimage(t,ro.id,"internal image",ro.internal_image)
					handleimage(t,ro.id,"location_image",ro.location_image)
					handleimage(t,ro.id,"location_sketch",ro.location_sketch)
					handleimage(t,ro.id,"plan_sketch",ro.plan_sketch)
				elsif t=='cams_cctv_survey'
					handleimage(t,ro.id,"location_photo",ro.location_photo)
					handleimage(t,ro.id,"location_sketch",ro.location_sketch)
				end
			end
		end
	if !@missing	
		puts "No missing attachments found for objects: cams_cctv_survey, cams_manhole_survey"
	end
	end
end
fred=Images.new
fred.doit