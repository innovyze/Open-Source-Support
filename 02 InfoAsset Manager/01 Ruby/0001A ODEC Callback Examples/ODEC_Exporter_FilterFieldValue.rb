## Only export certain field values

class Exporter
	def Exporter.PipeConditionScore(obj)
		if obj['condition_score_flag'] == 'KT1' && !obj['condition_score'].nil?		# If the field (flag) value is 'KT1' and the related field is not null
			return obj['condition_score']											# export the field value
		else								# If the value doesn't match any of the above ifs
			return nil						# export nil (null)
		end
	end
end