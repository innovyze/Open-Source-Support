## Merging Two Or More InfoSWMM models using SWMM5 Exchange

| Step | Description 
|------|---------------------------------------------------------
| 1    | We have two models, call them Model A and Model B. 
| 2    | Set Model A as the Base of the Combined Model. 
| 3    | Export Model B to the SWMM 5 file using the Base Scenario. 
| 4    | Import SWMM5_FromModel B to Model A using the Exchange SWMM 5 command. 
| 5    | Update the Map from the DB to see the combined system or Model C. 
| 6    | It would help if Model A and Model B did not have the same named patterns or time-series as the rows will get duplicated then during the import. 
| 7    | Open Up Model B and copy the names of the Scenarios to the new Combined Model C. 
| 8    | Copy the associated Data Sets in the DB Table from Model B to Model C. 
| 9    | Copy using Windows the directories for the scenarios in the ISDB folder such as Conduit, Junction etc from the Model B ISDB folder to the Model C ISDB folder, you will have to go into each Sub directory and copy the files then and not simply the whole directory. 