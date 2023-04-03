class Exporter
	def Exporter.PipeConditionScore(obj)
		if obj['condition_score_flag'] == 'KT1' && !obj['condition_score'].nil?		# IF the field flag value is 'KT1' and the related field is not null
			return obj['condition_score']											# export the field value
		else								# If the value doesn't match any of the above ifs
			return nil						# export nil (null)
		end
	end
	def Exporter.PipeServiceScore(obj)
		if obj['service_condition_score_flag'] == 'KT1' && !obj['service_condition_score'].nil?
			return obj['service_condition_score']
		else
			return nil
		end
	end
end