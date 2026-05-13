$primary_db='//localhost:40000/TEMP' #'//localhost:40000/DATABASE'
$cloud_db='cloud://Alex G@0d27b329cc853e210ec49a82/emea' #'cloud://NAME@IDSTRING/REGION'

$db_primary= WSApplication.open($primary_db,false)
$group=$db_primary.model_object 'MASG~CNSWMM testing' #'MASG~Name of the group folder'

$db=WSApplication.open($cloud_db,false)
$db.copy_into_root $group,true,true

puts 'Group data copied to cloud database'