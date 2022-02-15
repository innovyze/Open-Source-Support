# Introduction
The script is designed to Copy files from the file reference of the CCTV Survey video_file_in field of the currently selected survey objects to a destination folder as defined on line 3 `dest=`. Ensure to end the folder path with a double-backslash.  
As a first preference, the copied filename is the current filename, second preference is the CCTV Survey ID (less any non-alphanumeric characters, or hyphens, or underscored) - the filename as in the destination is reported in the log.  
If a file already exists in the destination with either preferred filenames, the file will not be copied - reported in the log.  
If a referenced file is not found - this is reported in the logged.  
If there is nothing referenced for a selected survey - this is reported in the logged.  

## Note
The process of copying files using this script is the same as copy-paste using Windows File Explorer, which depending on the source/destination locations and the size/quantity of files it can take a considerable amount of time to complete – bare this in mind when selecting surveys to copy the files for.  

Whilst the script is designed to prevent files in the destination being overwritten, we cannot be liable for any issues caused through the use of this script.  