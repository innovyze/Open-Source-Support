class Exporter
       def Exporter.sum(obj)
	   un=obj['unit_hydrograph_id']
	   	if !un.nil? #Script assumes that a non-RTK subcatchment will have a null value
		a1=obj['area_absolute_1'].to_i
		a2=obj['area_absolute_2'].to_i
		a3=obj['area_absolute_3'].to_i
		a4=obj['area_absolute_4'].to_i
		a5=obj['area_absolute_5'].to_i
		a6=obj['area_absolute_6'].to_i
		a7=obj['area_absolute_7'].to_i
		a8=obj['area_absolute_8'].to_i
		a9=obj['area_absolute_9'].to_i
		a10=obj['area_absolute_10'].to_i
		a11=obj['area_absolute_11'].to_i
		a12=obj['area_absolute_12'].to_i
		sum=a1+a2+a3+a4+a5+a6+a7+a8+a9+a10+a11+a12
              return sum.to_i
			 end
       end
end

