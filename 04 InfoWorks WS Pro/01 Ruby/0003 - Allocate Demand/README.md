# Allocate Demand

This script demonstrates how to use the allocate demand method, equivalent to the static demand allocation tool in the user interface. This method is only available in Exchange.

The available options in the hash are:

| **Name**                         | **Type** | **Default** |
| -------------------------------- | :------: | :---------: |
| allocate_demand_unallocated      | Boolean  |    true     |
| reallocate_demand_average        | Boolean  |    false    |
| reallocate_demand_direct         | Boolean  |    false    |
| reallocate_demand_property       | Boolean  |    false    |
| exclude_allocations_flag         |  String  |             |
| exclude_allocations_with_flags   | Boolean  |    false    |
| restrict_allocations_to_polygon  |  String  |             |
| and_pipes_between_selected_nodes | Boolean  |    false    |
| only_pipes_within_polygon        |  String  |             |
| remove_demand_average            | Boolean  |    false    |
| remove_demand_direct             | Boolean  |    false    |
| remove_demand_property           | Boolean  |    false    |
| allocated_flag                   |  String  |             |
| ignore_reservoirs                | Boolean  |    true     |
| max_distance_steps               | Integer  |      1      |
| max_dist_to_pipe_native          |  Float   |     0.0     |
| max_dist_along_pipe_native       |  Float   |     0.0     |
| max_pipe_diameter_native         |  Float   |     0.0     |
| max_properties_per_node          | Integer  |      0      |
| node_within_cp_polygon           | Boolean  |    false    |
| only_to_nearest_node             | Boolean  |    true     |
| only_to_selected_nodes           | Boolean  |    false    |
| use_connection_points            | Boolean  |    false    |
| use_nearest_pipe                 | Boolean  |    true     |
| use_smallest_pipe                | Boolean  |    false    |
