If video/attachment files are uploaded to another storage location and the file reference on the object is updated to the new storage location, the attachment/video files in the snumbat datastore may be orphaned.  
These obsolete and orphaned attachments may create a storage issue if they take up space on a server.  


The scripts will identify for a database files in the Videos/Attachments store which are not associated to the **latest version** of a database object.  
	Note, that by *latest version of a database object* this will mean if the reference to an attachment on an object is present in a previous commit version but not the latest commit version of the network, this file will be identified as 'non current'.  


## IE-NonCurrentVideos.rb
This script will only look at video file attachments from the snumbat Video Directory and identify those not referenced by the latest version of the networks on the database.  


## IE-AttachmentCheck.rb
This script will look at the attachments and video files on the database's networks, it will identify files which are:  
* Referenced by the networks but are not in the attachments/videos store - into missing.csv.  
* Video files in the video file store which are not referenced in the latest network versions - into NonCurrentVideos.txt.  
* Other attachment files in the attachment file store which are not referenced in the latest network versions - into NonCurrentAttachments.txt.  
