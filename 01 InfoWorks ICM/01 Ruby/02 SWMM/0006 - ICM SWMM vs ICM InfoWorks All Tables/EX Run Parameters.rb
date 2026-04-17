def retrieve_run_parameters(run_id)
    # Retrieve all the parameters in the specified run as a Hash
    database = WSApplication.open
    simulation = database.model_object_from_type_and_id('Run', run_id)
    parameters = {}
    database.list_read_write_run_fields.each do |field|
        parameters[field] = simulation[field]    
    end
    return parameters
end

run_id = # specify the run ID here
puts retrieve_run_parameters(run_id)
