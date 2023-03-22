class Exporter
	def Exporter.PipeConditionScore(obj)
		if obj['condition_score_flag'] == 'KT1'			# IF the field flag value is 'CT'
			return obj['condition_score']						# export the field value
		else								# If the value doesn't match any of the above ifs
			return nil						# export nil (null)
		end
	end
	def Exporter.PipeServiceScore(obj)
		if obj['service_condition_score_flag'] == 'KT1'			# IF the field flag value is 'CT'
			return obj['service_condition_score']						# export the field value
		else								# If the value doesn't match any of the above ifs
			return nil						# export nil (null)
		end
	end
end