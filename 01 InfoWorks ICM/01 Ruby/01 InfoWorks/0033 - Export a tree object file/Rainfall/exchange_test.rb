db=WSApplication.open 'snumbat://localhost:40000/[Testing] ICM 10.5',false
mo = db.model_object_from_type_and_id 'Rainfall Event',998
path = 'C:\\DELETE\\rainfall.csv'
format = 'CSV'
mo.export(path,format)
puts "Well done!"