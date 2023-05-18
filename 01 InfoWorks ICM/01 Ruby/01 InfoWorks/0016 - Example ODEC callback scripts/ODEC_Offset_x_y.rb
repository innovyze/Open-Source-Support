class Exporter
	def Exporter.OffsetX(obj)
		(obj['x'] + 15).round
	end
	def Exporter.OffsetY(obj)
		(obj['y'] + 15).round
	end
end