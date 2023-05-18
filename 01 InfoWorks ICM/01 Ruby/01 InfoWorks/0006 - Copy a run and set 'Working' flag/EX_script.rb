require "Date"

db=WSApplication.open('',false)

moGroup=db.model_object_from_type_and_id('Model Group',20)
object=db.model_object_from_type_and_id('Run',21)
							
eventsHash=Hash.new
scenariosHash=Hash.new
object.children.each do |c|
	thisEvent=c['Rainfall Event']
	if !thisEvent.nil?
		eventsHash[c['Rainfall Event']]=0
	end
	scenariosHash[c['NetworkScenarioUID']]=0
end
events=nil
if !eventsHash.empty?
	events=Array.new
	eventsHash.keys.each do |k|
		events << k
	end
end
scenarios=nil
if !scenariosHash.empty?
	scenarios=Array.new
	scenariosHash.keys.each do |k|
		if k.nil?
			scenarios << 'Base'
		else
			scenarios << k
		end
	end
end

params=Hash.new
db.list_read_write_run_fields.each do |p|
	params[p]=object[p]
end
params['Working']=true
network=object['Model Network']
commit_id=object['Model Network Commit ID']
# put in the things in the hash you want to change here

moGroup.new_run("freda",network,commit_id,events,scenarios,params)