# List Master Database Objects  
The scripts will run using the interface or IExchange.  
IExchange will produce a .txt file in the same repository as the script, as names on line 3. Set the database to be queried on line 2.  
The object types being queried for are configured on line 6, add/remove object types to this array to change what is outputted.  


## [UIIE-DatabaseContents.rb](./UIIE-DatabaseContents.rb)
For the Database Object Types listed in the object_types array, a list of the database objects will be outputted, grouped together by type, in order as they are listed in the type array, with a summary count following the list.  
Comment-out line 41 and uncomment 42 to also output the database path of the object.  
The output for this script would look similar to:  
```
Collection Network
Distribution Network
Asset Network
Theme
Stored Query
Selection List

Database Guid: ABCD1234-EFGH-5678-IJKL-90MNOPQRZTUV

Collection Network(s)
4	Croyde
6	SQL
8	Fakenham
10	Malden
    ...

Identified 76 Collection Network
    ...

```


## [UIIE-DatabaseSummary.rb](./UIIE-DatabaseSummary.rb)
For the Database Object Types listed in the object_types array, a summary of the database objects will be outputted, in order as they are listed in the type array.  
The output for this script would look similar to:  
```
Database Guid: ABCD1234-EFGH-5678-IJKL-90MNOPQRZTUV

76	Collection Network
8	Distribution Network
2	Asset Network
51	Theme
412	Stored Query
7	Selection List

Done.
```
