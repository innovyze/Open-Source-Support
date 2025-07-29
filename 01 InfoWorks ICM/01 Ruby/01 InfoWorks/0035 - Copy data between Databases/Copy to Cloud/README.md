# Copy objects to Cloud Database
These scripts copy all or allow a specific Group of data to be copied to a Cloud database. Please see the Help files for the latest restrictions that apply to copying data [Copying Data Between Databases](https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=GUID-7E1A5878-3242-4B0D-9699-74F4C6929782) and [Copying of Simulation Results, Ground Models and Time Series Data Objects Dialog](https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=GUID-73BE3CC4-90DA-4C86-9488-F4287E372D52)

# Create Cloud Database
Cloud database will need to be manually created through the product UI and then manually connected to in ICM to get the database path. 

## Where to find Cloud Database ID
From the top toolbar: Help > About InfoWorks > Additional Information (button): Database

## Back up Cloud Database 
Cloud databases can be manually backed up on the Cloud database management page prior to copying data. [Info360 Model Management Help](https://help.autodesk.com/view/INNCS/ENU/)

## Batch file editing
Batch file is best edited in Notepad++ and not Excel as the encoding can cause the code to error. If you run into issues ensure that the file encoding is set to ANSI.
