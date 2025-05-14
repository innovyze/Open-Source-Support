require 'rexml/document'
include REXML

## Function to read and process the XML file
def process_xml(file_path)
  ## Open and parse the XML file
  file = File.open(file_path)
  xml_doc = Document.new(file)

  ## Initialize an empty hash to store the values
  $result = Hash.new { |hash, key| hash[key] = [] }

  ## Initialize hashes to store Bezeichnung values mapped by objekt for Foto and REF for digitales_Video
  foto_bezeichnung_by_objekt = {}
  video_bezeichnung_by_objekt = {}

  ## Iterate through each 'Datei' element to extract Bezeichnung values
  XPath.each(xml_doc, '//VSA_KEK_2020_LV95.KEK.Datei') do |node|
    art = XPath.first(node, 'Art')&.text
    objekt = XPath.first(node, 'Objekt')&.text
    bezeichnung = XPath.first(node, 'Bezeichnung')&.text

    if objekt && bezeichnung
      if art == "Foto"
        foto_bezeichnung_by_objekt[objekt] = bezeichnung
      elsif art == "digitales_Video"
        video_bezeichnung_by_objekt[objekt] = bezeichnung
      end
    end
  end

  ## Iterate through each 'Normschachtschaden' element
  XPath.each(xml_doc, '//VSA_KEK_2020_LV95.KEK.Normschachtschaden') do |node|
    ## Extract the values from the specified elements
    tid = node.attribute('TID')&.value
    anmerkung = XPath.first(node, 'Anmerkung')&.text
    streckenschaden = XPath.first(node, 'Streckenschaden')&.text
    verbindung = XPath.first(node, 'Verbindung')&.text
    videozaehlerstand = XPath.first(node, 'Videozaehlerstand')&.text
    letzte_aenderung = XPath.first(node, 'Letzte_Aenderung')&.text
    distanz = XPath.first(node, 'Distanz')&.text
    schachtschadencode = XPath.first(node, 'SchachtSchadencode')&.text
    quantifizierung1 = XPath.first(node, 'Quantifizierung1')&.text
    quantifizierung2 = XPath.first(node, 'Quantifizierung2')&.text
    schachtbereich = XPath.first(node, 'Schachtbereich')&.text
    schadenlageanfang = XPath.first(node, 'SchadenlageAnfang')&.text
    schadenlageende = XPath.first(node, 'SchadenlageEnde')&.text

    ## Get the REF value
    ref_value = XPath.first(node, 'UntersuchungRef')&.attribute('REF')&.value

    ## Get the Bezeichnung values from the foto_bezeichnung_by_objekt and video_bezeichnung_by_objekt hashes
    foto_bezeichnung = tid ? foto_bezeichnung_by_objekt[tid] : nil
    video_bezeichnung = ref_value ? video_bezeichnung_by_objekt[ref_value] : nil

    ## Store the values in an array within the hash for each REF key
    $result[ref_value] << {
      tid: tid,
      anmerkung: anmerkung,
      streckenschaden: streckenschaden,
      verbindung: verbindung,
      videozaehlerstand: videozaehlerstand,
      letzte_aenderung: letzte_aenderung,
      distanz: distanz,
      schachtschadencode: schachtschadencode,
      quantifizierung1: quantifizierung1,
      quantifizierung2: quantifizierung2,
      schachtbereich: schachtbereich,
      schadenlageanfang: schadenlageanfang,
      schadenlageende: schadenlageende,
      foto_bezeichnung: foto_bezeichnung,  ## Add Foto Bezeichnung value to the hash
      video_bezeichnung: video_bezeichnung  ## Add Video Bezeichnung value to the hash
    }
  end

#  ## Output the result hash to the screen
#  $result.each do |ref, values_array|
#    puts "Ref: #{ref}"
#    values_array.each_with_index do |values, index|
#      puts "  Set #{index + 1}:"
#      values.each do |key, value|
#        puts "    #{key}: #{value}"
#      end
#    end
#    puts
#  end
end


## Run on current open network in UI
net=WSApplication.current_network 

## Specify the path to the XML file via user prompt
file_path = WSApplication.file_dialog(true,'xml','Select INTERLIS XML survey file',nil,false,false)
if file_path.nil?
	WSApplication.message_box("No file selected\nProcess cancelled",'OK','!',false)
else

	## Call the function to process the XML file
	process_xml(file_path)

	## Begin transaction
	net.transaction_begin

	## Iterate through each row object
	net.row_objects('cams_manhole_survey').each do |ro|
	#puts "Processing survey ID: #{ro.id}"
	  
		if $result.has_key?(ro.id)
			## Sort the details by distanz and videozaehlerstand in ascending order
			sorted_details = $result[ro.id].sort_by { |details| [details[:distanz], details[:videozaehlerstand]] }
			puts "Inserting details on survey: #{ro.id} from TIDs:"
			
			sorted_details.each do |details|
				puts "   #{details[:tid]}"
				details_row = ro.details
				n = details_row.length
				details_row.length = n + 1
				details_row[n].remarks = details[:anmerkung]
				details_row[n].cd = details[:streckenschaden].to_s.gsub('A', 'S').gsub('B', 'F')		## Convert the Continious Defect A/B values to S/F.
				details_row[n].joint = details[:verbindung] == 'ja' ? 'true' : 'false'					## Set 'ja' to Boolean true value.
				details_row[n].video_no2 = details[:videozaehlerstand]
				details_row[n].distance = details[:distanz]
				details_row[n].code = details[:schachtschadencode]
				details_row[n].video_file = details[:schachtschadencode]
				details_row[n].quant1 = details[:quantifizierung1]
				details_row[n].quant2 = details[:quantifizierung2]
				details_row[n].descriptive_location = details[:schachtbereich]
				details_row[n].clock_at = details[:schadenlageanfang] == '12' ? '0' : details[:schadenlageanfang]	## Convert Clock At 12 to 0.
				details_row[n].clock_to = details[:schadenlageende] == '12' ? '0' : details[:schadenlageende]	## Convert Clock At 12 to 0.
				details_row[n].photo_no = details[:foto_bezeichnung]
				details_row[n].video_file = details[:video_bezeichnung]
				#details_row[n].characterisation3 = details[:tid]		## The tid code for the observation in the XML
				details_row.write
				ro.video_file_in = details[:video_bezeichnung]
				ro.write
			end
		else
			#puts "Survey #{ro.id} - not matched or no details found"
		end
	end

	## Commit transaction
	net.transaction_commit

end