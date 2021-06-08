db=WSApplication.open 'snumbat://UKWAL18001301:40000/[SUPPORT] v10.0',false
mo = db.model_object_from_type_and_id 'Waste Water',234
path = 'C:\\DELETE\\test.csv'
format = 'CSV'
mo.export(path,format)
puts "Well done!"