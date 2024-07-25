# Current folder from where the script is being run
$project_path=File.dirname(__FILE__)

# Database names and full paths (standalone and transportable)
$standalone_name="2021.1.1_Standalone.icmm"
$transportable_name="2021.1.1_Transportable.icmt"
$standalone_path="#{$project_path}\\#{$standalone_name}"
$transportable_path="#{$project_path}\\#{$transportable_name}"

# Model object from standalone database
$standalone_db=WSApplication.open $standalone_path,false
$group=$standalone_db.model_object '>MODG~Model group'

# Create transportable and copy model object
$transportable_db=WSApplication.create_transportable($transportable_path)
$transportable_db=WSApplication.open $transportable_path,false
$transportable_db.copy_into_root $group,false,false