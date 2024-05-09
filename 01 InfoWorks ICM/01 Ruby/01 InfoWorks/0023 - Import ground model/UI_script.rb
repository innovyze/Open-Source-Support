# import_grid_ground_model(polgyon row object, array of filenames, hash)

# polygon row object: optional row object which is a boundary polygon i.e. a CRubyRowObject from the network (only used if the use_polygon key in the hash is set to true)
# array of filenames: array of filenames
# Contents of hash:
# 	ground_model_name - string - name of new ground model
# 	data_type - string
# 	cell_size - float
# 	unit_multiplier - float
# 	xy_unit_multiplier - float
# 	systematic_error - float 
# 	integer_format - Boolean
# 	use_polygon - Boolean

db=WSApplication.open
mg=db.model_object_from_type_and_id 'Model Group',2
files=Array.new
files << 'c:\\temp\\small_grid.asc'
fred=Hash.new
fred['ground_model_name']='fredi'
fred['data_type']='badger'
fred['cell_size']=5.0
fred['unit_multipler']=1.0
fred['xy_multiplier']=1.0
fred['integer_format']=false
fred['use_polygon']=false
mg.import_grid_ground_model nil,files,fred