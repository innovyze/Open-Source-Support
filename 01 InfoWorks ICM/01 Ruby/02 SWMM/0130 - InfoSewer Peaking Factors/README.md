Below is a step-by-step explanation of the Ruby script and how it interacts with Innovyze InfoWorks ICM. The script performs two main tasks:

1. **Processing results from selected links**  
2. **Gathering and reporting statistics on subcatchment database fields**  

---

## 1. Processing Results from Selected Links

### a. Require Libraries and Get Current Network
```ruby
require 'date'
net = WSApplication.current_network
```
- **`require 'date'`**: Loads the Ruby standard library for date/time operations (though it appears this script doesn’t strictly rely on the `Date` library, it could be useful in other contexts).  
- **`WSApplication.current_network`**: Fetches the currently active network in InfoWorks ICM. This gives the script a reference to the network object so that subsequent calls can operate on it.

### b. Retrieve List of Timesteps and Validate
```ruby
ts = net.list_timesteps
if ts.size <= 1
  puts "Not enough timesteps available!"
  return
end
```
- **`ts = net.list_timesteps`**: Retrieves an array of timesteps (date/time points) from the simulation results in the current network.
- The script checks that there is more than one timestep available. If there is only one or zero, it prints a message and exits early.

### c. Define the Field to Extract from Results
```ruby
res_field_name = 'us_flow'
```
- This is the name of the result field from which the script will read data for each selected link (e.g., `'us_flow'` could be the upstream flow in a pipe or channel).

### d. Iterate over Selected Network Objects
```ruby
net.each_selected do |sel|
  ...
end
```
- **`net.each_selected`**: Loops through all currently selected objects in the network. This could be pipes (links), nodes, subcatchments, etc., depending on what the user has selected in ICM.

Within this block, the script attempts to process each selected object as though it were a link:

```ruby
ro = net.row_object('_links', sel.id)
next if ro.nil?
```
- **`net.row_object('_links', sel.id)`**: Tries to retrieve the row object that belongs to the `'_links'` table with an ID matching the selected object. If this fails (i.e., the object is not in the `'_links'` table, or `sel.id` doesn’t exist in the links table), `ro` will be `nil`.  
- If `ro` is `nil`, the script skips that selection and moves to the next.

### e. Extract and Process Results
```ruby
results = ro.results(res_field_name)
if results.size == ts.size
  ...
else
  ...
end
```
- **`ro.results(res_field_name)`**: Fetches an array of result values (one per timestep) for the specified result field (in this case, `'us_flow'`).
- The script checks that the number of result values matches the number of timesteps. If there’s a mismatch, it prints an error message.

### f. Convert and Calculate Statistics
```ruby
val = val * 448.8 # Convert from MGD to GPM
peak_gpm = val * 2.6 / (val * 1.547) ** 0.16
```
- Within the loop over each result:
  1. **`val * 448.8`**: Converts the flow from **MGD (million gallons per day)** to **GPM (gallons per minute)**. (1 MGD ≈ 694.4 gpm, but the script uses 448.8—this conversion factor can depend on how the flow was originally measured or defined in ICM.)
  2. **`peak_gpm = val * 2.6 / (val * 1.547) ** 0.16`**: This appears to be a custom formula for computing a peaking factor or peak flow based on GPM. The exact rationale depends on the engineering flow-peaking method used.

The script then accumulates totals, tracks min/max, and increments a counter. After iterating through each timestep for that link, it calculates and prints out:
- **Mean flow**  
- **Max flow**  
- **Min flow**  
- **Number of steps**  

If an exception occurs for a given link, it is caught by:
```ruby
rescue => e
  puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
```
so that other selected objects can continue processing.

---

## 2. Gathering and Reporting Statistics on Subcatchment Database Fields

### a. Clear Selection and Print Scenario
```ruby
net.clear_selection
puts "Scenario     : #{net.current_scenario}"
```
- **`net.clear_selection`**: Clears the current selection so the script can operate on an unfiltered set of objects in the next part (the subcatchments).  
- **`net.current_scenario`**: Displays the name of the currently active scenario.

### b. Define Target Database Fields
```ruby
database_fields = [
  'trade_flow',
  'base_flow',
  'additional_foul_flow',
  'user_number_1'
]
```
- This array contains the names of the database fields in the `hw_subcatchment` table that the script wants to analyze. These are not simulation result fields but rather underlying hydraulic or user-defined properties in the database.

### c. Collect Field Data
```ruby
fields_data = {}
database_fields.each { |field| fields_data[field] = [] }

net.row_objects('hw_subcatchment').each do |ro|
  row_count += 1
  database_fields.each do |field|
    fields_data[field] << ro[field] if ro[field]
  end
end
```
- **`fields_data`**: A hash that will store an array of values for each field.  
- **`net.row_objects('hw_subcatchment')`**: Retrieves all row objects from the `hw_subcatchment` table.  
- For each row object (subcatchment), the script appends the value of each field into `fields_data[field]` if the value is not `nil`.

### d. Calculate and Print Statistics
```ruby
database_fields.each do |field|
  data = fields_data[field]
  ...
  min_value = data.min
  max_value = data.max
  sum = data.inject(0.0) { |sum, val| sum + val }
  mean_value = sum / data.size
  ...
  standard_deviation = Math.sqrt(sum_of_squares / data.size)
  total_value = sum

  printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
         field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
end
```
For each field in `database_fields`:

1. **`min_value`** and **`max_value`** are the smallest and largest values in the data array.  
2. **`sum`** is computed with `inject`.  
3. **`mean_value`** is the average of all values.  
4. **`standard_deviation`** uses the population standard deviation formula \(\sqrt{\frac{1}{N} \sum (x_i - \bar{x})^2}\).  
5. **`printf`**: Prints the statistics in a nicely formatted single-line output.

---

## Summary of the Script’s Workflow

1. **Fetch the current network** and verify timesteps for simulation results.  
2. **Iterate over selected links** to retrieve result data (e.g., `'us_flow'`) for each timestep.  
3. **Convert flows** (MGD to GPM), apply a custom peaking formula, and print individual and aggregated (mean, min, max) flow metrics.  
4. **Clear selection** and **switch focus to subcatchments**, where it pulls user/database fields (`'trade_flow'`, `'base_flow'`, etc.).  
5. **Accumulate data** from each subcatchment in arrays, compute **statistics** (min, max, mean, std dev, total) for each field, and **print** the results.  

Overall, this script demonstrates how to use the Ruby API in InfoWorks ICM to:
- Access simulation results for specific fields and timesteps,  
- Perform calculations or conversions,  
- Print out statistics,  
- Access and analyze underlying database fields from subcatchments (or other objects).

This kind of script is often used in InfoWorks ICM for reporting or for automating repeated tasks, such as generating QA/QC summaries, validating input data, or post-processing simulation results.