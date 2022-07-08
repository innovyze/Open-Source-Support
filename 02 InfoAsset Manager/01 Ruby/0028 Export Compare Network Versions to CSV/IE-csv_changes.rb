db=WSApplication.open('localhost:40000/database')       ## Open databaswe
net=db.model_object_from_type_and_id 'Collection Network',20        ## Network to use

net.csv_changes(100,120,'C:\\temp\\changes.csv')        ## nno.csv_changes(commit_id1, commit_id2, filename)