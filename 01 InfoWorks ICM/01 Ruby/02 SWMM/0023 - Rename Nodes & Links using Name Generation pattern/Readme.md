# Renaming Nodes and Links
Within the InfoAsset Manager you can configure a pattern to automatically set the ID a Node (in Collection & Distribution Networks) and Links (in Distribution Networks).  
This is configured from Network > Name Generation.  

From that dialog, it is possible to rename the selected or all Nodes / Links on the Network to the selected/defined pattern.  
To script the renaming process, use the `autoname` method. This can be used in a UI or IE script.  
This can be run on the whole Network or a Selection of objects, using either `_nodes` / `_links` or the individual object table name (such as `cams_manhole` or `wams_fitting`) as suitable.  

Whilst there are no parameters to record the old object ID, like there is on the dialog tool, through scripting you can write the current object ID to another field as needed before renaming the object.  
