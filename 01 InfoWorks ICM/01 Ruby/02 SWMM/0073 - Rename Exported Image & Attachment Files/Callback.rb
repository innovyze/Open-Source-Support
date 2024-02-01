class Exporter
	def Exporter.Filename(obj)
		if !obj['attachments.filename'].nil?
			name=obj['id']+'_'+obj['attachments.filename']
			return name.gsub(/[^0-9A-Za-z _-]/, '')
		elsif !obj['attachments.purpose'].nil?
			name=obj['id']+'_'+obj['attachments.purpose']
			return name.gsub(/[^0-9A-Za-z _-]/, '')
		else
			name2=obj['id']
			return name2.gsub(/[^0-9A-Za-z _-]/, '')
		end
	end
end