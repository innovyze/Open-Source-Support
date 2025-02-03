### **Summary of the Ruby Code (Markdown)**

#### **Overview**
This Ruby script is used in **InfoWorks ICM** to **calculate and update the SWMM5 subcatchment width (or dimension) based on user-selected methods**. The script:
1. **Prompts the user** to select a width calculation method.
2. **Iterates over subcatchments** to compute **perimeter, max height, and max width**.
3. **Applies the selected width formula** to update the SWMM5 model.
4. **Displays the total changes** in subcatchment dimensions before and after the update.

---

### **Step-by-Step Breakdown**

#### **1. Retrieve the Current Network**
```ruby
cn = WSApplication.current_network
```
- Gets the active **InfoWorks ICM** hydraulic network.

#### **2. User Prompt for Width Calculation Method**
```ruby
val = WSApplication.prompt "Choose USA or SI Units SWMM5 Subcatchment Width Calculation Method",
[
  ['USA Units','Boolean',false],
  ['SI  Units','Boolean',true],
  ['Width = 1.7 * Max(Height, Width)', 'Boolean',false],
  ['Width = K * SQRT(Area)', 'Boolean',false],
  ['Width = K * Perimeter', 'Boolean',false],
  ['Width = Area / Flow Length', 'Boolean',false],
  ['K value 0.2 to 5 default of 1', 'String'],
  ['Choose the Unit type and Width Option', 'String']
], false
```
- **Displays a dialog box** where the user selects a width calculation method.
- Options include:
  - **USA vs. SI Units**
  - **Different formulas** for calculating subcatchment width.
  - **Custom scaling factor (K value)**, with a default of **1.0**.

#### **3. Extract User Selections**
```ruby
USA = val[0]
SI  = val[1]
K   = val[6].to_f
K   = 1.0 if K.nil? || K == 0
MaxHeight = val[2]
SQRT_Area = val[3]
Width_Perimeter = val[4]
Flow_Length = val[5]
```
- Extracts user choices from the prompt.
- **Ensures the K value is valid**, defaulting to **1.0** if not specified.

#### **4. Start Transaction**
```ruby
cn.transaction_begin
```
- Begins a **transaction** so that all modifications are committed together.

#### **5. Compute Perimeter, Max Height, and Max Width for Each Subcatchment**
```ruby
subcatchment_measurements = {}
cn.row_object_collection('hw_subcatchment').each do |polygon|
  boundary_array = polygon.boundary_array
  perimeter = 0.0
  max_height = 0.0
  max_width = 0.0

  if boundary_array.any?
    points = boundary_array.each_slice(2).to_a
    min_x = points.map(&:first).min
    max_x = points.map(&:first).max
    min_y = points.map(&:last).min
    max_y = points.map(&:last).max
    max_width = max_x - min_x
    max_height = max_y - min_y

    points.each_with_index do |point, index|
      next_point = points[(index + 1) % points.size]
      distance = Math.sqrt((next_point[0] - point[0])**2 + (next_point[1] - point[1])**2)
      perimeter += distance
    end
  end

  subcatchment_measurements[polygon.subcatchment_id] = {
    perimeter: perimeter,
    max_height: max_height,
    max_width: max_width
  }
end
```
- **Iterates through each subcatchment** and calculates:
  - **Perimeter** (sum of segment lengths).
  - **Max height & max width** (bounding box dimensions).
- Stores these values in a hash **indexed by subcatchment ID**.

#### **6. Display Computed Measurements**
```ruby
subcatchment_measurements.each do |id, measurements|
  puts "Subcatchment ID: #{id}, Perimeter: #{'%.4f' % measurements[:perimeter]}, Max Height: #{'%.4f' % measurements[:max_height]}, Max Width: #{'%.4f' % measurements[:max_width]}"
end
```
- **Outputs the computed perimeter, height, and width** for each subcatchment.

#### **7. Apply Selected Width Calculation to Each Subcatchment**
```ruby
total_before = 0
total_after = 0
cn.row_objects('hw_subcatchment').each do |ro|
  if ro.total_area && ro.catchment_dimension
    total_before += ro.catchment_dimension
    if MaxHeight  
      ro.catchment_dimension = 1.7 * [subcatchment_measurements[ro.subcatchment_id][:max_width], subcatchment_measurements[ro.subcatchment_id][:max_height]].max
    end 
    if SQRT_Area 
      ro.catchment_dimension = K * Math.sqrt(ro.total_area * (USA ? 43560.0 : 10000.0))
    end  
    if Width_Perimeter  
      ro.catchment_dimension = K * subcatchment_measurements[ro.subcatchment_id][:perimeter]
    end 
    if Flow_Length 
      ro.catchment_dimension = (ro.total_area * (USA ? 43560.0 : 10000.0)) / ([subcatchment_measurements[ro.subcatchment_id][:max_width], subcatchment_measurements[ro.subcatchment_id][:max_height]].max)
    end
    total_after += ro.catchment_dimension
    ro.write
  end
end
```
- Loops through each subcatchment and applies the **selected width calculation formula**.
- Updates `catchment_dimension` based on the chosen method.
- Keeps track of **total width before and after the update**.

#### **8. Display Summary of Changes**
```ruby
puts "Total SWMM5 Width or dimension before update: #{'%.4f' % total_before}"
puts "Total SWMM5 Width or dimension after update:  #{'%.4f' % total_after}"
puts "Total SWMM5 Width or dimension change:        #{'%.4f' % (total_after - total_before)}"
if SQRT_Area 
  puts K == 1 ? "Width = K * SQRT(Area) with K = 1" : "Width = K * SQRT(Area) with K = #{K}"
end
if Width_Perimeter 
  puts K == 1 ? "Width = K * Perimeter with K = 1" : "Width = K * Perimeter with K = #{K}"
end
```
- **Displays the total width change** for all subcatchments.
- **Clarifies the width formula used**, including the **K value** if applicable.

#### **9. Commit the Transaction**
```ruby
cn.transaction_commit
```
- Saves all modifications to the network.

---

### **Key Features**
✅ **User-Defined Width Calculation**: Allows selection of different methods for width estimation.  
✅ **Bounding Box Computation**: Calculates **perimeter, max height, and max width** for each subcatchment.  
✅ **Transaction Control**: Ensures all changes are applied **safely in one commit**.  
✅ **Summary Statistics**: Displays total width before and after updates.  
✅ **Handles USA & SI Units**: Converts areas appropriately.  

---

### **Potential Applications**
- **Customizing SWMM5 Model Inputs**: Provides flexibility in defining subcatchment width.  
- **Ensuring Consistent Width Assignments**: Standardizes different width estimation methods.  
- **Hydrologic Model Calibration**: Adjusts subcatchment widths based on observed data.  

Would you like to enhance this script with **data visualization** or **CSV export** for further analysis? 🚀