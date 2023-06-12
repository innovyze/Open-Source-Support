##Only import objects where the source values meet the conditions as defined (SOURCE: node_type='G' AND system_type='F'), other source objects will be ignored.

class Importer
	def Importer.OnBeginRecordNode(obj)
		obj.writeRecord=false
		myType=obj['node_type']
		mySystem=obj['system_type']
		if myType=='G' && mySystem=='F'
			obj.writeRecord=true
		else
			obj.writeRecord=false
		end
	end
end