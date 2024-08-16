database = WSApplication.open
network = database.model_object_from_type_and_id('Geometry', 'Badger')

options = {
  'allocate_demand_unallocated' => true,
  'max_dist_to_pipe_native' => 100,
  'max_distance_steps' => 10,
  'max_pipe_diameter_native' => 500
}

allocator = WSDemandAllocation.new()
allocator.network = network.open
allocator.options = options
allocator.allocate()
