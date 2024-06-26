### Step 1: Node and Manhole Configuration
1. Convert the DBF files within the InfoSewer model to CSV for ICM Open Data Import Center (ODIC)

This macro converts Excel files with the ".dbf" extension located in a specified folder to CSV format and saves them in another specified folder. It prompts the user to select the source and destination folders. Then, it loops through all the ".dbf" files in the source folder, opens them one by one, saves them as CSV files in the destination folder, and closes them. The Excel macro file is called InfoSewer_InfoSWMM_VBA_DBF_CSV_Conversion.xlsm. The folder to convert is the IEDB folder.

2. Import the file NODE.CSV in the IEDB folder using the ODIC and the CFG file Step1_InfoSewer_Node_csv.cfg

This imports all nodes, manholes, chambers, outlets and wet wells into ICM. What should you expect to see on the GeoPlan of ICM? The node, the x, y, each node has a user_text_10 of WW. This will be changed later as we import the node hydraulic information.


![Alt text](./media/image-24.png)

![Alt text](./media/image-25.png)

3. Import the file MANHOLE.CSV in the IEDB folder using the ODIC and the CFG file Step1a_InfoSewer_Manhole_csv.cfg

What should you expect to see on the GeoPlan of ICM? The node, the x, y, each node now has a user_text_10 of Manhole if it was a Manhole in InfoSewer. The Wet Wells remain as WW. Manholes also have the manhole information table which is imported to the user text field of each imported manhole. Note, import by Asset ID after the nodes are first imported.

![Alt text](image-26.png)


4. Use the SQL script SQL_Make_Subcatchments to create Dummy Subcatchments for the loading of DWF from InfoSewer 

![Alt text](./media/image-27.png)

5. Use the Model tool Create dummy boundaries to make the polygons for the newly created Subcatchments

![Alt text](./media/image-28.png)

Node ID. X, Y have been imported and dummy subcatchments exist

![Alt text](./media/image-29.png)