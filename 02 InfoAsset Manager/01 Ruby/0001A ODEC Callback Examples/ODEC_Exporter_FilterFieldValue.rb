<<<<<<< HEAD
## Only export certain field values

class Exporter
	def Exporter.PipeConditionScore(obj)
		if obj['condition_score_flag'] == 'KT1'						# If the field (flag) value is 'KT1'
			return obj['condition_score']						# export the field value
		else						# If the value doesn't match any of the above ifs
			return nil						# export nil (null)
		end
	end
=======
## Only export certain field values

class Exporter
	def Exporter.PipeConditionScore(obj)
		if obj['condition_score_flag'] == 'KT1'						# If the field (flag) value is 'KT1'
			return obj['condition_score']						# export the field value
		else						# If the value doesn't match any of the above ifs
			return nil						# export nil (null)
		end
	end
>>>>>>> 1de88b4851d0d455bf279f3270b0a2d790a58b83
end