$master_db='//localhost:40000/TEMP' #'//localhost:40000/DATABASE'
$cloud_db='cloud://Alex G@0d27b329cc853e210ec49a82/emea' #'cloud://NAME@IDSTRING/REGION'

$db_master= WSApplication.open($master_db,false)
$group=$db_master.model_object 'MASG~CNSWMM testing' #'MASG~Name of the master group folder'

$db=WSApplication.open($cloud_db,false)
$db.copy_into_root $group,true,true

puts 'Group data copied to cloud database'