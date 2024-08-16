# Array to WSStructure

This script demonstrates how to write an array of hashes to a WSStructure. It will run from the User Interface and write some dummy demand data to all selected nodes.

The demand data looks like this:

```ruby
DEMAND_DATA = [
  { 'category_id' => 'CONST_LEAKAGE', 'category_type' => 1, 'average_demand' => 0.1 },
  { 'category_id' => 'CONST_LEAKAGE', 'category_type' => 1, 'average_demand' => 0.2 }
]
```

You can use the method `array_to_structure` in your own scripts.
