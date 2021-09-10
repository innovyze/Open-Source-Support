# Renaming Exported Attachment Files
Within the InfoAsset Manager you can export images and attachment files which are stored against an object using the standard export methods available.

When exporting these attachment files, they are exported with a GUID filename - which is what they are stored using within the Master Database.
Currently there is no built-in utility to rename/define a file's filename when exporting from the database.


The scripts here will resolve this, allowing bulk renaming of files using a simple CSV mapping file.


Full details of this script can be found in [this article](https://innovyze.force.com/support/s/article/Renaming-Exported-Image-Attachment-Files) on our [Support Portal Knowledgebase](https://innovyze.force.com/support/s/topic/0TO0P000000IdBQWA0).


The script is designed to prevent overwriting of files by means of renaming a file to a filename already in use within the folder. 
If this happens, the Script Output will show a log the current and proposed filenames for your separate investigation.
We cannot be held liable if the scriptdoes overwrite files incorrectly when run.


## Renaming Already Exported Files
 Script: **UI-FileRename_v2.rb**

 The prerequisite of using this script is a CSV file which contains at least two columns - one which has the file's current filename (full filename including file type extension) & a column with the new filename (without file type extension), and that the files to be renamed are all located within one folder.

 As an example, this is what a filename mapping file might look like.

 ![CSV export in Excel](img3.png)
