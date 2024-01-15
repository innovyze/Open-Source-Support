require_relative 'ddg'

database = WSApplication.open()
ddg_group_mo = database.model_object_from_type_and_id('Demand Diagram Group', 11921)
ddg_mo = database.model_object_from_type_and_id('Demand Diagram', 11928)

# Create a new deamand diagram proxy (DemandDiagram class) from the demand diagram model object
ddg = DemandDiagram.from_ddg(ddg_mo)

# Print something about the demand diagram
puts "Demand Diagram #{ddg.name} has #{ddg.profiles.length} profiles in it"

# Iterate through the profiles (DemandProfile class)
ddg.profiles.each do |profile|
  puts "Profile #{profile.name}"

  # The values property contains of the profile, as you might expect, contains the values
  puts "Contains #{profile.values.length} values"

  # The values property is an array of arrays containing [seconds, minutes] so we can split it
  # using bracket notation and use any Ruby array method, e.g. to check all values are above 0
  all_above_zero = profile.values.all? { |(seconds, value)| value > 0.0 }
  puts all_above_zero ? "All profile values are above zero" : "Some profile values are not above zero"

  # Or use any? to check if this spans multiple days (i.e. any seconds above 86400)
  multile_days = profile.values.any? { |(seconds, value)| seconds > 86400 }
  puts multile_days ? "Profile spans multiple days" : "Profile only spans one day"

  # We can edit the profile values in place using map!
  profile.values.map! { |(seconds, value)| [seconds, value * 10] }
end

# We can import the proxy object into a demand diagram group
# The name of the new demand diagram is taken from the ddg.name property
ddg.name = ddg.name + '_Edited'
new_ddg_mo = ddg.to_ddg(ddg_group_mo)

# That should have returned the new demand diagram model object
puts "New Demand Diagram object ID: #{new_ddg_mo.id}"
