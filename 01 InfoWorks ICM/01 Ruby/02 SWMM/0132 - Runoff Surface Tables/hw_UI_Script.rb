# Initialize the current network
cn = WSApplication.current_network

# Initialize an array to store runoff surface variables
runoff_surface_variables = []

# Loop through each runoff surface in the network
cn.row_objects('hw_runoff_surface').each do |ro|
  # Add the runoff surface variables to the array
  # Each runoff surface is represented as a hash with keys corresponding to variable names and values corresponding to variable values
  runoff_surface_variables << {
    'Runoff surface ID' => ro.runoff_index,
    'Description' => ro.surface_description,
    'Runoff routing type' => ro.runoff_routing_type,
    'Runoff routing value' => ro.runoff_routing_value,
    'Runoff volume type' => ro.runoff_volume_type,
    'Surface type' => ro.surface_type,
    'Ground slope' => ro.ground_slope,
    'Initial loss type' => ro.initial_loss_type,
    'Initial loss value' => ro.initial_loss_value,
    'Initial abstraction factor' => ro.initial_abstraction_factor,
    'Routing model' => ro.routing_model,
    'Fixed runoff coefficient' => ro.runoff_coefficient,
    'Minimum runoff' => ro.minimum_runoff,
    'Maximum runoff' => ro.maximum_runoff,
    'RAFTS adapt factor' => ro.rafts_adapt_factor,
    'Equivalent Manning\'s n' => ro.equivalent_roughness,
    'Wal. proc. distribution' => ro.runoff_distribution_factor,
    'New UK depth' => ro.moisture_depth_parameter,
    'SCS depth' => ro.storage_depth,
    'Initial infiltration' => ro.initial_infiltration,
    'Limiting infiltration' => ro.limiting_infiltration,
    'Decay factor' => ro.decay_factor,
    'Horton drying time' => ro.drying_time,
    'Horton max infiltration volume' => ro.max_infiltration_volume,
    'Recovery factor' => ro.recovery_factor,
    'Number of reservoirs' => ro.number_of_reservoirs,
    'Depression Loss' => ro.depression_loss,
    'Green-Ampt suction' => ro.average_capillary_suction,
    'Green-Ampt conductivity' => ro.saturated_hydraulic_conductivity,
    'Green-Ampt deficit' => ro.initial_moisture_deficit,
    'Horner alpha' => ro.halpha,
    'Horner beta' => ro.hbeta,
    'Horner recovery (min)' => ro.hrecovery,
    'Initial loss porosity' => ro.initial_loss_porosity,
    'Infiltration loss coefficient' => ro.infiltration_coeff,
    'Maximum deficit' => ro.maximum_deficit,
    'Effective impermeability' => ro.effective_impermeability,
    'Precipitation decay coefficient' => ro.precipitation_decay,
    'Power coefficient for PI' => ro.power_coeff_paved,
    'Storage depth' => ro.storage_depth_paved,
    'Wetness decay for NAPI' => ro.napi_decay_coeff,
    'Power coefficient' => ro.power_coeff_pervious,
    'Storage depth' => ro.storage_depth_pervious,
    'Minimum NAPI' => ro.minimum_napi,
    'Saturated rainfall' => ro.saturated_rainfall
  }
end

# Print the column labels
# The labels are the keys of the first hash in the runoff_surface_variables array
# Each label is left-justified and padded with spaces on the right to a total width of 15 characters, except for the sixth label which has a width of 30 characters
puts runoff_surface_variables.first.keys.each_with_index.map { |key, index| index == 5 ? key[0, 30].ljust(30) : key[0, 15].ljust(15) }.join(", ")

# Print the runoff surface variables
# For each hash in the runoff_surface_variables array, the values are printed as a single row
# Each value is left-justified and padded with spaces on the right to a total width of 15 characters, except for the sixth value which has a width of 30 characters
runoff_surface_variables.each do |variables|
  row = variables.values.each_with_index.map { |value, index| index == 5 ? value.to_s[0, 20].ljust(20) : value.to_s[0, 15].ljust(15) }.join(", ")
  puts row
end