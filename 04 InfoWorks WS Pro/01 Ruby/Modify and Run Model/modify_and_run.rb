require 'pp'
require 'json'
require 'date'

# @param network [WSOpenNetwork]
# @param control [WSOpenNetwork]
# @param updates [Hash]
# @param flag [String]
def update_control(network, control, updates, flag)
  control.transaction_begin

  updates.each do |update|
    # Find the ro in the network (the network is most likely to contain Asset IDs)
    net_ros = network.row_objects_from_asset_id(update['table'], update['id'])
    if net_ros.empty?
      puts "Failed to find '#{update['table']}' with ID #{update['id']}"
      next
    elsif net_ros.length > 1
      puts "Ambiguous '#{update['table']}' ID #{update['id']}"
      next
    end

    # Get the OID of the ro (e.g. us.ds.suffix for links)
    oid = net_ros[0].id

    # Get the control ro, or create it if necessary
    ctl_table = update['table'].gsub('wn_', 'wn_ctl_')
    ctl = control.row_object(ctl_table, oid)
    unless ctl
      ctl = control.new_row_object(ctl_table)
      ctl.id = oid
    end

    # Update all the fields
    update['fields'].each do |k, v|
      ctl[k] = v
      ctl[k + '_flag'] = flag rescue nil # some fields may not have flags, ignore the error
    end

    ctl.write
  end

  control.transaction_commit
rescue => e
  control.transaction_rollback rescue nil
  raise e
end

# Note that if the existing run is marked experimental, this will update the run in place
#
# @param run [WSModelObject]
# @param control_mo [WSNumbatNetworkObject]
# @param new_run_time [String, nil]
# @return [WSModelObject] the new run
def update_run(run, control_mo, new_run_time)
  run_scheduler = WSRunScheduler.new()
  run_scheduler.load(run.id)

  new_run_time_parsed = DateTime.parse(new_run_time)

  options = {}
  options['ro_l_control_commit_id'] = control_mo.latest_commit_id
  if new_run_time_parsed
    options['ro_dte_start_date_time'] = new_run_time_parsed
    options['ro_dte_end_date_time'] = new_run_time_parsed + 1
  end

  run_scheduler.set_parameters(options)
  raise 'Failed to validate Run' if !run_scheduler.validate(nil)
  raise 'Failed to save Run' if !run_scheduler.save(false)

  new_run = run_scheduler.get_run_mo()
  puts "Created / updated run '#{new_run.name}'"
  return new_run
end

# Read settings
settings_file = ARGV[1]
raise "missing settings .JSON" unless File.exist?(settings_file)
settings = JSON.parse(File.read(settings_file))

# Will default to last open database if this is nil
database = WSApplication.open(settings['database'])

# Get the run, sim, then the control
run = database.model_object_from_type_and_id('Wesnet Run', settings['run_id'])
sim = run.children[0]
network_mo = database.model_object_from_type_and_id('Geometry', run['Geometry'])
control_mo = database.model_object_from_type_and_id('Control', sim['Control'])

network = network_mo.open
control = control_mo.open

# Make changes and commit
update_control(network, control, settings['updates'], settings['flag'])
control_mo.commit(settings['message'])

# Create a new run
new_run = update_run(run, control_mo, settings['run_time'])

# Run the run (yes, this terminology is a bit confusing)
puts "Running simulation..."
new_run.run()
new_sim = new_run.children[0]
puts "Simulation finished with result: #{new_sim.status}"

# Open the sim results
results = new_sim.open

# Do some stuff with the results...
