#If source field 'SYSTEMDATE' is not null, import in the value into User_text_2 as a string value
require 'Date'
class Importer
	def Importer.onEndRecordNode(obj)
		obj['user_text_2']=obj['SYSTEMDATE'].to_s
	end
end
