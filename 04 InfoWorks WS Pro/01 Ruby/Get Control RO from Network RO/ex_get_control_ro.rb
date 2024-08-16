# Gets the control WSRowObject for a given network WSRowObject, creating it if necessary.
#
# @param control [WSOpenNetwork]
# @param net_ro [WSRowObject]
# @param create_missing [Boolean] whether to create the control object if not found
# @return [WSRowObject, nil]
def control_ro(control, net_ro, create_missing: false)
  return nil unless control && net_ro

  ctl_table = net_ro.table.gsub('wn_', 'wn_ctl_')

  ctl_ro = control.row_object(ctl_table, ro.id)

  if ctl_ro.nil? && create_missing
    ctl_ro = control.new_row_object(ctl_table)
    ctl_ro.id = ro.id
    ctl_ro['asset_id'] = ro['asset_id']
    ctl_ro.write
  elsif ctl_ro && ctl_ro['asset_id'].nil?
    ctl_ro['asset_id'] = ro['asset_id']
    ctl_ro.write
  end

  return ctl_ro
end

NETWORK_ID = 1517
CONTROL_ID = 1518
NODE_ID = 'ST27363601'

database = WSApplication.open()
network = database.model_object_from_type_and_id('Geometry', NETWORK_ID).open
control = database.model_object_from_type_and_id('Control', CONTROL_ID).open

control.transaction_begin # In case we need to create a new control record

net_ro = network.row_object('wn_node', NODE_ID)
puts "Network Row Object: #{net_ro.id}"

con_ro = control_ro(control, net_ro, create_missing: true)
puts "Control Row Object: #{con_ro.id}"

control.transaction_rollback