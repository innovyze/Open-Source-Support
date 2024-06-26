# Step 3 - Import Manhole Hydraulics in the Import of InfoSewer to ICM InfoWorks using ODIC

1. Import the file Mhhyd.CSV in the IEDB foder using the ODIC Center and the CFG file Step3_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg

What is imported?  The manhole Rim Elevation and Flood Level

![Alt text](./media/image-20.png)

2.  Need to use the SQL Script SET node_type = 'Outfall' to convert some manholes to Outfalls based on the node type imported when the Manhole CSV file was imported.
Solution

![Alt text](./media/image-21.png)


