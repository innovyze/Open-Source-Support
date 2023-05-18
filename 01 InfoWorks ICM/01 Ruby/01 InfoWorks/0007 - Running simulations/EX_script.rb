# External libraries
require 'Win32API'
require 'Date'

# Select database from this path
$project_path=File.dirname(__FILE__)
$db_name="2021.1.1_Standalone.icmm"
$db_file="#{$project_path}\\#{$db_name}"
$db=WSApplication.open $db_file,false

# Creates a new_guid string that can be used as a unique global identifier for the run
$uuid_create = Win32API.new('rpcrt4', 'UuidCreate', 'P', 'L')
def new_guid
  result = ' ' * 16
  $uuid_create.call(result)
  a, b, c, d, e, f, g, h = result.unpack('SSSSSSSS')
  sprintf('%04X%04X-%04X-%04X-%04X-%04X%04X%04X', a, b, c, d, e, f, g, h)
end

# OR Creates a now_time string that can be used as an identifier for the run
now_time = Time.now.strftime("%Y/%m/%d %H:%M:%S") 

# ICM API commands start here
group=$db.model_object '>MODG~Model group'
runParamsHash=Hash.new
runParamsHash['ExitOnFailedInit']=true
runParamsHash['Duration']=14*60
runParamsHash['DurationUnit']='Hours'
runParamsHash['Level']='>MODG~Model group>LEV~Level'
runParamsHash['ResultsMultiplier']=300
runParamsHash['TimeStep']=1
runParamsHash['StorePRN']=true
runParamsHash['DontLogModeSwitches']=false
runParamsHash['DontLogRTCRuleChanges']=false

run=group.new_run(
	"Run: #{new_guid}",			# you can use $uuid_create instead to use a global unique ID instead of time
	'MODG~Model Group>NNET~Model network',
	nil, # commit ID
	1, # rainfall event ID
	nil,
	runParamsHash
)

# Select run mode
mode=1

# Code which starts each of the different modes
begin
	if mode==1
		simsArray=Array.new
		sim=run.children[0]
		simsArray << sim
		WSApplication.connect_local_agent(1)	
		handles=WSApplication.launch_sims simsArray,'.',false,0,0
		while sim.status=='None'
			puts  'running'
			sleep 1
		end
	elsif mode==2
		simsArray=Array.new
		sim=run.children[0]
		simsArray << sim
		WSApplication.connect_local_agent(1)	
		handles=WSApplication.launch_sims simsArray,'.',false,0,0
		puts handles
		WSApplication.wait_for_jobs handles,true,86400000	
	elsif mode==3
		sims=run.children
		sims.each do |sim|
			puts 'running sim'
			sim.run_ex '.',1
		end
	elsif mode==4
		settingsArray=Hash.new
		settingsArray['Server'] = 'innocpu01'
		settingsArray['Threads'] = 1
		settingsArray['SU'] = false
		settingsArray['ResultsOnServer'] = false
		
		sims=run.children
		sims.each do |sim|
			puts 'running sim'
			sim.run_ex(settingsArray)
		end
	end
	puts 'done'
rescue => e
	puts e
	sleep 10
end