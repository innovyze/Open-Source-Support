# Summary:

This Ruby script is designed to streamline and automate the process of importing data from the InfoSewer BASE scenario to InfoWorks ICM, thus eliminating the need for manual import of data from each individual CSV or SHP file using ODIC. It is a companion to the published 9-step import process and can be used instead of following the outlined steps: https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Knowledge-Importing-InfoSewer-to-InfoWorks-ICM-Overview-of-all-Import-Steps.html

The code is divided into several steps, each corresponding to different layers of data.

The script first prompts the user to select the folders where the IEDB, SHP, and CFG files are located. Then, it imports various data related to nodes, conduits, unit hydrographs, manholes, pump curves, pump controls, subcatchments, and conduit vertices from the CSV and SHP files using their respective CFG files.

The script handles potential errors during the import process and prints out the status of each import step. It also performs various SQL operations to manipulate the imported data, such as setting node types, creating subcatchments, setting the number of barrels, assigning R values, finding pumps, setting pump on and off levels, and calculating wet well areas.

The import process uses different options for different steps, including unit behavior and duplication behavior, and whether to update based on asset ID or only update existing objects. Once all the steps are executed, a message indicating the completion of the import process is printed.

Before running this script, users must preprocess some data using the DBFtoCSVExcelMacro provided in the same folder as this script and convert Map.mdb to shapefiles using ArcCatalog. After running the script, users need to validate the model and correct any errors that result.

It's important to note that this script is specifically designed to work only for the BASE scenario from InfoSewer to InfoWorks ICM. Its primary benefit is ensuring data consistency and saving users' time by automating the import and processing of data.