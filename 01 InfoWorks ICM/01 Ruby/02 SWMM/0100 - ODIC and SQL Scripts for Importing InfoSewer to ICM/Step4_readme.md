# Step 4 - Import Link Hydraulics in the Import of InfoSewer to ICM InfoWorks using ODIC

1. Import the file Pipehyd.CSV in the IEDB foder using the ODIC Center and the CFG file Step4_InfoSewer_link_hydraulics_pipehyd_csv.cfg

We now import the pipe lengths, roughness, diameter and inverts from the PIPE hydraullics CSV file

2. Often the barrels are undefined in InfoSewer and InfoSewer assumes it is 1.  We do the same with the SQl Script SQL  number_of_barrels.  Use the SQL to set the zero barrels to 1.  

![Alt text](./media/image-22.png)

![Alt text](./media/image-23.png)