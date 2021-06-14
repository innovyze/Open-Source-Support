network = WSApplication.current_network
# set options for OPEN DATA EXPORT CENTER (ODEC)
options = Hash.new
options['Units Behaviour'] = 'User'               # default=Native
options['Export Selection'] = true                # checks option in ODEC to export only selected network data in gdb format
# Select Export Folder
gbd_name = 'C:\ICM data\Geodatabase\Geo01.gdb'
#Select configuration file
cfg_file = 'C:\ICM data\Scripts\Config01.cfg'
#Specify Feature Class and Feature Dataset
ftr_class = 'Project/Nodes'
ftr_dataset = 'Design'
network.odec_export_ex(
  'gdb',                                          # File format to be exported
  cfg_file,                                       # Configuration file path
  options,                                        # options in hash for odec
  'Node',                                         # Table to export
  ftr_class,                                      # Feature_class Name
  ftr_dataset,                                    # Feature dataset name
  true,                                           # Update - true to update, false otherwise
  nil,                                            # ArcSDE configuration keyword - nil for Personal/File Geodatabase, and ignored for updates
  gbd_name)                                       # geodatabase file name
puts 'Selected objects exported'