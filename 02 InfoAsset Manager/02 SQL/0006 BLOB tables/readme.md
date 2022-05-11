# Introduction
BLOB tables are fields in structure blobs whereby on the object there is a table of fields with a one-to-many relationship. E.G. CCTV Survey’s Details table, on an individual CCTV Survey object there are many records in the Details table for the survey observations.  
The SQL tool in InfoAsset Manager works on an object-by-object basis, so the insertion and deletion of fields within structure blobs is done via the object itself.  
  
## Insertion
To add individual rows into an individual object's structured blob the syntax is:  
`INSERT INTO <table name>.<blob name> (field1,field,2... fieldn) VALUES (val1,val2,... valn)`  
The field names must be either:  
- a key field name of the table   
- the array name followed by a . followed by a field in the blob  
All key field names of the table must be specified and objects into which lines in the structure blob are beinginserted must exist.  

To insert values into a table from a SELECT statement, the syntax is:  
`INSERT INTO <table name> (field1,field2,... fieldn) SELECT <select statement>`  
To insert values into a structure blob from a SELECT statement the syntax is:  
`INSERT INTO <table name>.<blob name>(field1,field2,... fieldn) SELECT <select statement>`  
As with the values insert statement, the field names must be either:  
a key field name of the table  
the array name followed by a . followed by a field in the blob  
All key field names of the table must be specified and the objects into which lines are being inserted must exist.  
The number of items being selected must match the number of fields being set in the INSERT  
The select statement can include WHERE and ORDER BY but not GROUP BY or HAVING and can include selection of SCENARIO, TOP and BOTTOM and SELECTED etc.  
It is possible to add objects to a scenario by adding the scenario details after the list of fields e.g.  
`INSERT INTO node(node_id,x,y) IN BASE SCENARIO VALUES ('N2',3,4)`  
`INSERT INTO node(node_id,x,y) IN SCENARIO 'SC1' VALUES ('N3,4,5)`  

## Deletion  
It is possible to delete from structure blobs by saying:  
`DELETE FROM [Table Name].blob_name WHERE condition`  
This deletes the contents of the blobs but not the object in the table. The condition may be omitted. The condition may include fields in the blob and fields in the object i.e. you can selectively delete rows in the blobs based on a combination of conditions for the blob and the object.  
