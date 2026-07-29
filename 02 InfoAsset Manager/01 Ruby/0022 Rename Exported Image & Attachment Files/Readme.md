# Renaming Exported Attachment Files
Within the InfoAsset Manager you can export images and attachment files which are stored against an object using the standard export methods available.  

When exporting these attachment files, they are exported with a GUID filename - which is what they are stored using within the Database.
Currently there is no built-in utility to rename/define a file's filename when exporting from the database.  

The scripts here will resolve this, allowing bulk renaming of files using a simple CSV mapping file.  

The script is designed to prevent overwriting of files by means of renaming a file to a filename already in use within the folder.  
If this happens, the Script Output will try and append the new filename with an index number based on the line in the CSV[^1].  The outputted log will detail the file renamings which have occured.  
Rows that cannot be renamed (for example, when the source file is missing or the proposed new name is invalid after sanitisation) are skipped and reported in the Ruby console rather than stopping the script.  
Note, we cannot be held liable if the script does overwrite any files.  
[^1]: Handling of multiple proposed filenames being the same is in v4 & later of this script.  

## Renaming Already Exported Files
Script: **[UI-FileRename_v4.rb](./UI-FileRename_v4.rb)**  

The prerequisite of using this script is a CSV file which contains at least two columns - one which has the file's current filename (full filename including file type extension) and a column with the new filename (without file type extension), and that the files to be renamed are all located within one folder.  

When renaming, the script sanitises proposed new filenames to remove characters that are not permitted on Windows file systems. Any extension included in the new filename column is stripped before the source file's extension is appended.  

### Exporting the files & CSV from Infoasset Manager
For example, I have the below CCTV Survey with some attachments.  
![Attachments dialog for a CCTV Survey](./images/img001.png)  
*Attachments dialog for a CCTV Survey.*  

I export the Object ID, the file reference - to export the file itself, and the proposed new filename - either generated using SQL/Script.  
![	ODEC, exporting only the necessary fields](./images/img002.png)  
*ODEC, exporting only the necessary fields.*  

Note, that because these attachments are a blob field, to generate the proposed filename I had to use a Script callback class (on ODEC line 3) - see the [0001A ODEC Callback Examples GitHub repository](../0001A%20ODEC%20Callback%20Examples/) for examples such as this.  
The Callback class syntax I used in this example is:  
```ruby
class Exporter
    def Exporter.Filename(obj)
        if !obj['attachments.purpose'].nil?
            name=obj['id']+'_'+obj['attachments.purpose']
            return name.gsub(/[^0-9A-Za-z _-]/, '')
        else
            name2=obj['id']
            return name2.gsub(/[^0-9A-Za-z _-]/, '')
        end
    end
end
```
Essentially what it is doing is returning the object value for the id field, followed by an underscore character, then the attachments.purpose field value concatenated together if the purpose field has a value, else it is just outputting the Object ID.  
The returned string then has any characters removed that are not alphanumeric, spaces, underscores, or hyphens. The rename script applies further sanitisation when renaming files.  

So that I have a simple CSV file, as below, which I can use to rename the files as well as the files themselves.  
![CSV export in Excel](./images/img003.png)  
*CSV export in Excel*  


### Run the Ruby Script
Run the script using the InfoAsset Manager interface (**Network** > **Run Ruby script...** > select [UI-FileRename_v4.rb](./UI-FileRename_v4.rb)). The script uses two prompts:

1. **Rename Files - Step 1** — select the folder containing the exported files and the CSV mapping file.
2. **Rename Files - Step 2** — select the current and new filename columns from dropdown lists populated from the CSV headers. 

Review the Ruby console output for any rows that were skipped (missing source file, invalid new name, or duplicate target name).  
Like magic, the files are renamed to something more meaningful as defined in the CSV. :satisfied:  
![Files pre and post renaming](./images/img005.png)  
*Files pre and post renaming*  

