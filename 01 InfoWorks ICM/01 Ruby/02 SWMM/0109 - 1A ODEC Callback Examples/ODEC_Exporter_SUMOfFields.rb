# Output the Sum the User Number 1 - 5 fields where User Number 10 is not NULL.

class Exporter
       def Exporter.sum(obj)
	   un=obj['user_number_10']
	   	if !un.nil?
		un1=obj['user_number_1']
			if !un1.nil?
			u1=obj['user_number_1'].to_i
			else
			u1=0
			end
		un2=obj['user_number_2']
			if !un2.nil?
			u2=obj['user_number_2'].to_i
			else
			u2=0
			end
		un3=obj['user_number_3']
			if !un3.nil?
			u3=obj['user_number_3'].to_i
			else
			u3=0
			end
		un4=obj['user_number_4']
			if !un4.nil?
			u4=obj['user_number_4'].to_i
			else
			u4=0
			end
		un5=obj['user_number_5']
			if !un5.nil?
			u5=obj['user_number_5'].to_i
			else
			u5=0
			end
		sum=u1+u2+u3+u4+u5
              return sum.to_i
			 end
       end
end