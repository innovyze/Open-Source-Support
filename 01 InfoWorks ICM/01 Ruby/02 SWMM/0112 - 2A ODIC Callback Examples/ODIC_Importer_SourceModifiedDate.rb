## When importing data, set the user_date_5 field to be the Date Modified attribute of the source data file (as set on lines 5).
## If this is being incorperated into an IExchange script, the variable defining the file can be te same as is used for the ODIC source file.
require 'Date'

NodeModDate = File.mtime("C:\\Temp\\shp\\Node.shp")

class Importer
	def Importer.onEndRecordNode(obj)
		obj['user_date_5']=NodeModDate.strftime('%F %T')
	end
end
