
# Running sims in ICM

## Contents

[Introduction](#Introduction)

[Creating runs](#Creating-runs)

[Running simulations](#Running-simulations)

[Exporting results](#Exporting-results)

[Exporting to GIS](#Exporting-to-GIS)

[CSV exports](#CSV-exports)

[Binary export](#Binary-export)

## Introduction

Refer to the main [Exchange](https://innovyze-emea01.s3-eu-west-1.amazonaws.com/WorkgroupProducts/Dropbear/2021.8/Exchange.pdf) documentation for the objects, their methods and the parameters of those methods.

Some of the examples below are snippets and are not designed to run on their own.

## Creating runs

This is an example of setting up runs, setting up one run for each combination of 4 levels, 4 ground infiltrations and two rainfall events.

```ruby
db = WSApplication.open

group_name = '>MODG~Sensitivity'
variables_name = '>MODG~Variables'
runs_name = '>MODG~RUNS'

levels = ['none','38.5','39.5','40.5']
gis = ['none','25','50','75']
rainfall_names = ['Dry','Wet']
run_group = db.model_object group_name + runs_name

rainfalls = Array.new
rainfall_names.each do |rn|
    rainfalls << group_name + '>MODG~Rainfall>RAIN~RAIN 5YR 2hr ' + rn
end

levels.each do |l|
    level = nil
    ic2d = nil
    if l! = 'none'
        level = db.model_object group_name + variables_name + '>LEV~LEV_' + l
        ic2d = db.model_object group_name + variables_name + '>IC2D~IC2D_' + l
    end
    gis.each do |gi_name|
    gi = nil
    if gi_name! = 'none'
        gi = db.model_object group_name + variables_name + '>IFN~GI_' + gi_name
    end
    runParamsHash = Hash.new
    runParamsHash['ExitOnFailedInit'] = true
    runParamsHash['Duration'] = 24\*60
    runParamsHash['DurationUnit'] = "Hours"
    runParamsHash['ResultsMultiplier'] = 5
    runParamsHash['TimeStep'] = 60
    runParamsHash['StorePRN'] = true
    runParamsHash['Level'] = level
    runParamsHash['Ground Infiltration'] = gi
    runParamsHash['Initial Conditions 2D'] = ic2d
    run_group.new_run "level #{l},gi #{gi_name}",group_name + '>NNET~Network',nil,rainfalls,nil,runParamsHash
    end
end
```

Notice that one run is created for each pair of ground infiltration and levels (amongst the many parameters put into the parameter hash) – then the rainfall events are put into an array which is passed into the `new_run` method as the 4th parameter.

This code takes a run, changes one parameter (the results multiplier) and creates an otherwise unchanged run. As you can see the complexity here is the need to take all the sims which are each for one rainfall event and one scenario and recreate those lists as parameters for new_run. In this case I have used the IDs of the run being copied and the model group into which the new run is being created – there are of course other ways of doing this – see the main [Exchange](https://github.com/innovyze/Open-Source-Support/blob/main/Exchange.docx) documentation for details

```ruby
db = WSApplication.open

moParent = db.model_object_from_type_and_id('Model Group',59)
moCopyThis = db.model_object_from_type_and_id('Run',181)
eventsHash = Hash.new
scenariosHash = Hash.new

moCopyThis.children.each do |c|
    thisEvent = c['Rainfall Event']
    if !thisEvent.nil?
        eventsHash[c['Rainfall Event']] = 0
    end
    scenariosHash[c['NetworkScenarioUID']] = 0
end

events = nil
    if !eventsHash.empty?
        events = Array.new
        eventsHash.keys.each do |k|
        events << k
    end
end

scenarios = nil
    if !scenariosHash.empty?
        scenarios = Array.new
        scenariosHash.keys.each do |k|
        if k.nil?
            scenarios << 'Base'
        else
        scenarios << k
        end
    end
end

params = Hash.new
db.list_read_write_run_fields.each do |p|
    params[p] = moCopyThis[p]
end

network = moCopyThis['Model Network']
commit_id = moCopyThis['Model Network Commit ID']
params['ResultsMultiplier'] = 678

newRun = moParent.new_run("Example2",network,commit_id,events,scenarios,params)
```

Here are examples of two of the water quality parameters being set – see the appendix of the main documentation for details.

```ruby
params['QM Pollutant Enabled'] = ['DO_','PH_']
params['Sediment Fraction Enabled'] = [false,false]
```

## Running simulations

There are essentially two ways of doing this, one of them is synchronous, one is asynchronous.

To run a run synchronously (notice that the `run_ex` method is a method of the simulation, therefore if the run has multiple simulations you need to loop through them)

```ruby
newRun.children.each do |c|
    c.run_ex('.',1)
end
```

To run two sims asynchronously – again I am using the sim IDs

```ruby
puts WSApplication.version
db = WSApplication.open
WSApplication.connect_local_agent(1)
sims = Array.new
(0..2).each do |i|
    mo = db.model_object_from_type_and_id 'Sim',97 + i
    sims << mo
end
handles = WSApplication.launch_sims(sims,'.',false,0,0)
puts WSApplication.wait_for_jobs(handles,true,2147483647)
puts 'done'
```

The above code waits indefinitely, to wait for 60 seconds and then cancel any that haven't finished you can do something like this

```ruby
puts WSApplication.version
db = WSApplication.open

sim1 = db.model_object_from_type_and_id 'Sim',163
sim2 = db.model_object_from_type_and_id 'Sim',164
sim3 = db.model_object_from_type_and_id 'Sim',165
sim4 = db.model_object_from_type_and_id 'Sim',166
sims = Array.new
sims << sim1
sims << sim2
sims << sim3
sims << sim4

WSApplication.connect_local_agent(1)
handles = WSApplication.launch_sims sims,'.',false,0,0
handles.each do |h|
    puts "handle #{h}"
end

index = WSApplication.wait_for_jobs handles,true,60000

handles.reverse.each do |h|
    puts "cancelling #{h}"
    WSApplication.cancel_job h
end
```
## Exporting results

### Exporting to GIS

The export of results to GIS is done using the `results_GIS_export` method of the sim.

Here is an example of exporting the maximum 2D elements for all the runs in a model group

```ruby
exportHash = Hash.new

exportHash['Tables'] = ['_2DElements']
@group.children.each do |c|
    if c.type =  = 'Run'
        c.children.each do |sim|
            sim.results_GIS_export 'shp','Max',exportHash,@resultspath
        end
    end
end
```

This rather contrived example demonstrate the parameters for this method and some supporting functionality by taking a simulation and

1. Listing the timesteps
2. Listing the results attributes
3. Listing the tables available to export
4. Performing a shape file export for the listed tables, creating some expression fields for the 2D zones, using the alternative naming system (see the main documentation), and outputting the results for timesteps 0, 2, 4 and 6 (counting from 0) as well as the maximum results

```ruby
puts WSApplication.version

db = WSApplication.open nil,true
    mo = db.model_object_from_type_and_id 'Sim',163
    arr = mo.list_timesteps
    arr.each do |ts|
    puts ts
end

arr = mo.list_results_attributes

arr.each do |e|
    puts '----'
    puts e[0]
    puts '\*\*\*\*'
    puts e[1]
end

arr = mo.list_results_GIS_export_tables
arr.each do |t|
    puts t
end

params = Hash.new
params['Tables'] = ['_2DElements','_links','hw_bridge_opening']
params['2DZoneSQL'] = [['one','1'],['two','2'],['three','678',3],['params','sim.depth2d  +  234',5]]
params['ExportMaxima'] = true
params['AlternativeNaming'] = true

mo.results_GIS_export 'SHP',[0,2,4,6],params,'c:\\temp\\s'
```

### CSV exports

This example uses the `results_csv_export_ex` method to export only the *downstream flow* and *downstream velocity* results for links for a simulation

```ruby
puts WSApplication.version
db = WSApplication.open nil,false
mo = db.model_object_from_type_and_id 'Sim',163
arr = mo.list_results_attributes
puts arr.to_s
mo.results_csv_export_ex nil,[["Link",["ds_flow","ds_vel"]]], 'c:\\temp'
```

### Binary export

It is possible to export files in a documented binary file format. The documentation and an example Ruby script are available [here](https://github.com/innovyze/Open-Source-Support/tree/main/01%20InfoWorks%20ICM/01%20Ruby/0009%20-%20ICM%20Binary%20Results%20Export).
