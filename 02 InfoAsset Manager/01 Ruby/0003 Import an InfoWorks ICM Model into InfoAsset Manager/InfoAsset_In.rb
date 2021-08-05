# Define a useful class
#
class ImportTable
	attr_accessor :in_table, :cfg_file, :csv_file, :cb_class

	def initialize(in_table, cfg_file, csv_file, cb_class)
		@in_table = in_table
		@cfg_file = cfg_file
		@csv_file = csv_file
		@cb_class = cb_class
	end
end

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Attribute Conversion from InfoWorks ICM CSV Files into InfoAsset
#

# Callback Classes
#

# Node - from ICM Node
#
class ImporterClassNode
	def ImporterClassNode.onBeginNode(obj)
		@systemTypeLookup={
			'storm' => 'S',
			'foul' => 'F',
			'sanitary' => 'F',
			'combined' => 'C',
			'overland' => 'LD',
			'other' => 'Z'
		}
		
		@nodeTypeLookup = {
			'manhole' => 'M',
			'break' => 'G',
			'outfall' => 'F',
			'outfall 2d' => 'F'
		}
	end
	
	def ImporterClassNode.onEndRecordNode(obj)
		icmSystemType = obj['system_type']
		icmNodeType = obj['node_type']
		
		if !icmSystemType.nil?
			icmSystemType = icmSystemType.downcase
		end
		
		if !icmNodeType.nil?
			icmNodeType = icmNodeType.downcase
		end
		
		if @systemTypeLookup.has_key? icmSystemType
			inNodeSystemType = @systemTypeLookup[icmSystemType]
		else
			inNodeSystemType = 'U'
		end
		
		if @nodeTypeLookup.has_key? icmNodeType
			inNodeNodeType = @nodeTypeLookup[icmNodeType]
		else
			inNodeNodeType = 'U'
		end
		
		obj['node_type'] = inNodeNodeType
		obj['system_type'] = inNodeSystemType
		
		if !obj['ground_level'].nil? & !obj['chamber_floor'].nil? 
			obj['chamber_floor_depth'] = (obj['ground_level'].to_f - obj['chamber_floor'].to_f) * 1000
		end
	end
end

# Pipe - from ICM Conduit
#
class ImporterClassPipe
	def ImporterClassPipe.OnEndRecordPipe(obj)
		@systemTypeLookup={
			'storm' => 'S',
			'foul' => 'F',
			'sanitary' => 'F',
			'combined' => 'C',
			'overland' => 'LD',
			'other' => 'Z'
		}
		
		@shapeLookup={
			'ARCH' => 'A',
			'ARCHSPRUNG' => 'A',
			'CIRC' => 'C',
			'CNET' => 'CSC',
			'EGG' => 'E',
			'EGG2' => 'E',
			'OEGB' => 'Z',
			'OEGN' => 'Z',
			'OREC' => 'Z',
			'OT1:1' => 'T',
			'OT1:2' => 'T',
			'OT1:4' => 'T',
			'OT1:6' => 'T',
			'OT2:1' => 'T',
			'OT4:1' => 'T',
			'OU' => 'Z',
			'OVAL' => 'O',
			'RECT' => 'R',
			'UTOP' => 'U'
		}
		
		icmSystemType = obj['system_type']
		icmShape = obj['shape']
		
		if !icmSystemType.nil?
			icmSystemType = icmSystemType.downcase
		end
		
		if !icmShape.nil?
			icmShape = icmShape.upcase
		end
		
		if @systemTypeLookup.has_key? icmSystemType
			inPipeSystemType = @systemTypeLookup[icmSystemType]
		else
			inPipeSystemType = 'U'
		end
		
		if @shapeLookup.has_key? icmShape
			inShape = @shapeLookup[icmShape]
		else
			inShape = 'Z'
		end
		
		obj['system_type'] = inPipeSystemType
		obj['shape'] = inShape
	end
end

# Pump - from ICM Pump
#
class ImporterClassPump
	def ImporterClassPump.OnEndRecordPump(obj)
		@systemTypeLookup={
			'storm' => 'S',
			'foul' => 'F',
			'sanitary' => 'F',
			'combined' => 'C',
			'overland' => 'LD',
			'other' => 'Z'
		}
		
		obj['id'] = obj['us_node_id'] + '.' + obj['link_suffix']
		
		icmSystemType=obj['system_type']
		
		if !icmSystemType.nil?
			icmSystemType = icmSystemType.downcase
		end
		
		if @systemTypeLookup.has_key? icmSystemType
			inPipeSystemType = @systemTypeLookup[icmSystemType]
		else
			inPipeSystemType = 'U'
		end
		
		obj['system_type'] = inPipeSystemType
		
		if obj['link_type'].upcase == 'FIXPMP'
			obj['type'] == 'F'
		elsif obj['link_type'].upcase == 'VSPPMP'
			obj['type'] == 'V'
		elsif obj['link_type'].upcase == 'VFDPMP'
			obj['type'] = 'V'
		elsif obj['link_type'].upcase == 'ROTPMP'
			obj['type'] = 'R'
		elsif obj['link_type'].upcase == 'SCRPMP'
			obj['type'] = 'S'
		end
	end
end

# Screen - from ICM Screen
#
class ImporterClassScreen
	def ImporterClassScreen.OnEndRecordScreen(obj)
		@systemTypeLookup={
			'storm' => 'S',
			'foul' => 'F',
			'sanitary' => 'F',
			'combined' => 'C',
			'overland' => 'LD',
			'other' => 'Z'
		}
		
		obj['id'] = obj['us_node_id'] + '.' + obj['link_suffix']
		
		icmSystemType = obj['system_type']
		
		if !icmSystemType.nil?
			icmSystemType = icmSystemType.downcase
		end
		
		if @systemTypeLookup.has_key? icmSystemType
			inPipeSystemType = @systemTypeLookup[icmSystemType]
		else
			inPipeSystemType = 'U'
		end
		
		obj['system_type'] = inPipeSystemType
	end
end

# Orifice - from ICM Orifice
#
class ImporterClassOrifice
	def ImporterClassOrifice.OnEndRecordOrifice(obj)
		@systemTypeLookup={
			'storm' => 'S',
			'foul' => 'F',
			'sanitary' => 'F',
			'combined' => 'C',
			'overland' => 'LD',
			'other' => 'Z'
		}
		
		obj['id'] = obj['us_node_id'] + '.' + obj['link_suffix']
		
		icmSystemType=obj['system_type']
		
		if !icmSystemType.nil?
			icmSystemType = icmSystemType.downcase
		end
		
		if @systemTypeLookup.has_key? icmSystemType
			inPipeSystemType = @systemTypeLookup[icmSystemType]
		else
			inPipeSystemType = 'U'
		end
		
		obj['system_type'] = inPipeSystemType
	end
end

# Sluice - from ICM Sluice
#
class ImporterClassSluice
	def ImporterClassSluice.OnEndRecordSluice(obj)
		@systemTypeLookup={
			'storm' => 'S',
			'foul' => 'F',
			'sanitary' => 'F',
			'combined' => 'C',
			'overland' => 'LD',
			'other' => 'Z'
		}
		
		obj['id'] = obj['us_node_id'] + '.' + obj['link_suffix']
		
		icmSystemType = obj['system_type']
		
		if !icmSystemType.nil?
			icmSystemType = icmSystemType.downcase
		end
		
		if @systemTypeLookup.has_key? icmSystemType
			inPipeSystemType = @systemTypeLookup[icmSystemType]
		else
			inPipeSystemType = 'U'
		end
		
		obj['system_type'] = inPipeSystemType
		
		if obj['link_type'] = 'Sluice'
			obj['type'] = 'S'
		elsif obj['link_type'] = 'VSGate' || obj['link_type'] = 'RSGate' || obj['link_type'] = 'VRGate'
			obj['type'] = 'V'
		end
	end
end

# Flume - from ICM Flume
#
class ImporterClassFlume
	def ImporterClassFlume.OnEndRecordFlume(obj)
		@systemTypeLookup={
			'storm' => 'S',
			'foul' => 'F',
			'sanitary' => 'F',
			'combined' => 'C',
			'overland' => 'LD',
			'other' => 'Z'
		}
		
		obj['id'] = obj['us_node_id'] + '.' + obj['link_suffix']
		
		icmSystemType = obj['system_type']
		
		if !icmSystemType.nil?
			icmSystemType = icmSystemType.downcase
		end
		
		if @systemTypeLookup.has_key? icmSystemType
			inPipeSystemType = @systemTypeLookup[icmSystemType]
		else
			inPipeSystemType = 'U'
		end
		
		obj['system_type'] = inPipeSystemType
		
		obj['type'] = 'F'
	end
end

# Siphon - from ICM Siphon
#
class ImporterClassSiphon
	def ImporterClassSiphon.OnEndRecordSiphon(obj)
		@systemTypeLookup={
		'storm' => 'S',
		'foul' => 'F',
		'sanitary' => 'F',
		'combined' => 'C',
		'overland' => 'LD',
		'other' => 'Z'
		}
		
		obj['id'] = obj['us_node_id'] + '.' + obj['link_suffix']
		
		icmSystemType = obj['system_type']
		
		if !icmSystemType.nil?
			icmSystemType = icmSystemType.downcase
		end
		
		if @systemTypeLookup.has_key? icmSystemType
			inPipeSystemType = @systemTypeLookup[icmSystemType]
		else
			inPipeSystemType = 'U'
		end
		
		obj['system_type'] = inPipeSystemType
	end
end

# Weir - from ICM Weir
#
class ImporterClassWeir
	def ImporterClassWeir.OnEndRecordWeir(obj)
		@systemTypeLookup={
			'storm' => 'S',
			'foul' => 'F',
			'sanitary' => 'F',
			'combined' => 'C',
			'overland' => 'LD',
			'other' => 'Z'
		}
		
		obj['id'] = obj['us_node_id'] + '.' + obj['link_suffix']
		
		icmSystemType = obj['system_type']
		
		if !icmSystemType.nil?
			icmSystemType = icmSystemType.downcase
		end
		
		if @systemTypeLookup.has_key? icmSystemType
			inPipeSystemType = @systemTypeLookup[icmSystemType]
		else
			inPipeSystemType = 'U'
		end
		
		obj['system_type'] = inPipeSystemType
		
		if obj['link_type'].upcase == 'WEIR'
			obj['type'] == 'S'
		elsif obj['link_type'].upcase == 'VCWEIR'
			obj['type'] == 'VC'
		elsif obj['link_type'].upcase == 'VWWEIR'
			obj['type'] = 'VW'
		elsif obj['link_type'].upcase == 'COWEIR'
			obj['type'] = 'CO'
		elsif obj['link_type'].upcase == 'VNWEIR'
			obj['type'] = 'VN'
		elsif obj['link_type'].upcase == 'TRWEIR'
			obj['type'] = 'TR'
		elsif obj['link_type'].upcase == 'BRWEIR'
			obj['type'] = 'BR'
		end
	end
end

# Valve - from ICM Flap Valve
#
class ImporterClassValve
	def ImporterClassValve.OnEndRecordValve(obj)
		@systemTypeLookup={
			'storm' => 'S',
			'foul' => 'F',
			'sanitary' => 'F',
			'combined' => 'C',
			'overland' => 'LD',
			'other' => 'Z'
		}
		
		obj['id'] = obj['us_node_id'] + '.' + obj['link_suffix']
		
		icmSystemType = obj['system_type']
		
		if !icmSystemType.nil?
			icmSystemType = icmSystemType.downcase
		end
		
		if @systemTypeLookup.has_key? icmSystemType
			inPipeSystemType = @systemTypeLookup[icmSystemType]
		else
			inPipeSystemType = 'U'
		end
		
		obj['system_type'] = inPipeSystemType
	end
end

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
begin
#Is Configuration File in Import Folder?
#
MsgBoxCfgFile = WSApplication.message_box('Has the \'Import Configuration File\' (named \'ICM_Model_Importer.cfg\') been placed in the import folder?', 'YesNoCancel', '?', false)

puts MsgBoxCfgFile + ' - Configuration File Present'

if MsgBoxCfgFile == 'No'
	puts 'No - Then please place the Import Configuration File named \'ICM_Model_Importer.cfg\' in the import folder before continuing'

elsif MsgBoxCfgFile == 'Cancel'
	puts 'Import operation cancelled'

#Select import folder, containing the exported InfoWorks ICM CSV files.
#
elsif MsgBoxCfgFile.to_s == 'Yes'

	ImportFolder = WSApplication.folder_dialog('ICM CSV folder', true)
	puts 'Import Folder - "' + ImportFolder + '"'


# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#

# Set up the config files and table names
#
import_tables = Array.new

# import_tables.push ImportTable.new('<InfoAsset Table Name>', '<Configuration File Name>.cfg', '<CSV File Name>', <Callback Class>)
#
import_tables.push ImportTable.new('Node', ImportFolder + '/ICM_Model_Importer.cfg', ImportFolder + '/model_node.csv', ImporterClassNode)
import_tables.push ImportTable.new('Pipe', ImportFolder + '/ICM_Model_Importer.cfg', ImportFolder + '/model_conduit.csv', ImporterClassPipe)
import_tables.push ImportTable.new('Pump', ImportFolder + '/ICM_Model_Importer.cfg', ImportFolder + '/model_pump.csv', ImporterClassPump)
import_tables.push ImportTable.new('Screen', ImportFolder + '/ICM_Model_Importer.cfg', ImportFolder + '/model_screen.csv', ImporterClassScreen)
import_tables.push ImportTable.new('Orifice', ImportFolder + '/ICM_Model_Importer.cfg', ImportFolder + '/model_orifice.csv', ImporterClassOrifice)
import_tables.push ImportTable.new('Sluice', ImportFolder + '/ICM_Model_Importer.cfg', ImportFolder + '/model_sluice.csv', ImporterClassSluice)
import_tables.push ImportTable.new('Flume', ImportFolder + '/ICM_Model_Importer.cfg', ImportFolder + '/model_flume.csv', ImporterClassFlume)
import_tables.push ImportTable.new('Siphon', ImportFolder + '/ICM_Model_Importer.cfg', ImportFolder + '/model_siphon.csv', ImporterClassSiphon)
import_tables.push ImportTable.new('Weir', ImportFolder + '/ICM_Model_Importer.cfg', ImportFolder + '/model_weir.csv', ImporterClassWeir)
import_tables.push ImportTable.new('Valve', ImportFolder + '/ICM_Model_Importer.cfg', ImportFolder + '/model_flap_valve.csv', ImporterClassValve)

#set options
#
options=Hash.new

options['Allow Multiple Asset IDs'] = false
options['Blob Merge'] = false
options['Delete Missing Objects'] = false
options['Update Based On Asset ID'] = false
options['Update Only'] = false
options['Update Links From Points'] = false
options['Use Network Naming Conventions'] = false
options['Error File'] = ImportFolder + '/ERROR.txt'
options['Default Value Flag'] = 'DV'
options['Set Value Flag'] = 'CV'
options['Duplication Behaviour'] = 'Overwrite'
options['Units Behaviour'] = 'Native'

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#


	net = WSApplication.current_network

if !ImportFolder.nil?
	
	import_tables.each{|table_info| # Loop over table configs
		
		options['Callback Class'] = table_info.cb_class
		
		# Do the import
		net.odic_import_ex(	'csv',										# import data format
							table_info.cfg_file,						# field mapping config file
							options,									# specified options override the default options
							table_info.in_table,						# import to InfoAsset table name
							table_info.csv_file							# import from MapDrain table name
		)
	}
	
	puts 'Import Completed'
end
	puts 'Check - ' + ImportFolder + '\ERROR.txt' + ' for any Import Errors'

end

# handle excepticlsons
#
rescue Exception => exception
	puts "[#{exception.backtrace}] #{exception.to_s}"
	
end