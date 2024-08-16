# Retrieves the model objects from a run, including commit ids. Note that this only
# fetches the first scenario / simulation.
#
# @param database [WSDatabase]
# @param run [WSRun]
# @return [Hash<Symbol, WSModelObject>]
def get_model_objects_from_run(database, run)
  sim = run.children[0]
  raise 'Run does not have a simulation' unless sim

  objects = {}
  objects[:network] = database.model_object_from_type_and_id('Geometry', run['Geometry']) rescue nil
  objects[:network_commit_id] = run['GeometryCheckedOutRevisionID'] rescue nil
  objects[:control] = database.model_object_from_type_and_id('Control', sim['Control']) rescue nil
  objects[:control_commit_id] = sim['ControlCheckedOutRevisionID'] rescue nil
  objects[:ldc] = database.model_object_from_type_and_id('Wesnet Live Data', run['Wesnet Live Data']) rescue nil
  objects[:ldc_commit_id] = run['Wesnet Live Data Commit ID'] rescue nil
  objects[:ddg] = database.model_object_from_type_and_id('Demand Diagram', run['Demand Diagram']) rescue nil

  return objects
end

RUN_ID = 1532

database = WSApplication.open()
run = database.model_object_from_type_and_id('Wesnet Run', RUN_ID)
objects = get_model_objects_from_run(database, run)

objects.each do |type, obj|
  case obj
  when WSModelObject
    puts "#{type}: #{obj.name} (#{obj.id})"
  else
    puts "#{type}: #{obj}"
  end
end