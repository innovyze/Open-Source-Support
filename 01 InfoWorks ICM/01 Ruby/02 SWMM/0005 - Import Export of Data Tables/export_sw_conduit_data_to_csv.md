# SWMM Conduit Export Script Documentation

## Overview
This Ruby script automates the export of SWMM conduit data from InfoWorks ICM to CSV format. It includes comprehensive field selection, statistical analysis capabilities, and user-friendly prompts for customizing exports.

## Key Features

### **Data Export Capabilities**
- Exports selected SWMM conduit objects to timestamped CSV files
- Supports 50+ configurable conduit parameters
- Handles complex data types (arrays, point coordinates, hyperlinks)
- User-selectable field configuration with individual field toggles

### **Statistical Analysis**
- Optional statistical calculations for numeric fields
- Generates formatted tables showing:
  - Count, Min, Max, Mean, Standard Deviation
  - Automatically excludes non-numeric fields (IDs, codes, text)
- Uses sample standard deviation formula (n-1 denominator)

### **User Interface**
- Interactive prompts for field selection
- "Select/Deselect All" toggle option
- Export folder selection
- Summary dialog upon completion
- Progress tracking and error reporting

## Supported SWMM Conduit Fields

### **Essential Fields (Default: Enabled)**
- Conduit ID, US/DS Node IDs
- Length, Height, Width
- Manning's N coefficient
- US/DS Invert elevations
- Shape designation

### **Geometric Properties**
- Cross-sectional dimensions
- Arch and ellipse size codes
- Material specifications
- Barrel configurations
- Slope and radius parameters

### **Hydraulic Parameters**
- Roughness coefficients (DW, HW, Manning's N)
- Headloss coefficients
- Flow limits and initial conditions
- Seepage rates
- Culvert specifications

### **User-Defined Fields**
- 10 user number fields
- 10 user text fields
- Custom notes and hyperlinks
- Branch ID assignments

## Technical Implementation

### **Error Handling**
- Network validation and connection checks
- Field existence verification
- File permission and disk space validation
- Graceful handling of missing attributes

### **Data Processing**
- Processes only selected conduit objects
- Handles special data types (point arrays, hyperlinks)
- Sanitizes CSV data (removes problematic characters)
- Type conversion for statistical analysis

### **Performance Features**
- Efficient iterator-based processing
- Memory-conscious data handling
- Progress tracking with object counts
- Execution timing reports

## Usage Instructions

### **Prerequisites**
- InfoWorks ICM or InfoSWMM environment
- Network with SWMM conduit objects loaded
- Write permissions to export directory

### **Execution Steps**
1. **Select Conduits**: Use the GUI to select conduits for export
2. **Run Script**: Execute within the application environment
3. **Configure Export**: 
   - Choose export folder
   - Select desired fields
   - Enable statistics if needed
4. **Review Results**: Check console output and summary dialog

### **Output Files**
- CSV format: `selected_swmm_conduits_export_YYYYMMDD_HHMMSS.csv`
- Automatic cleanup of empty files
- Timestamped for version control

## Statistical Output Example

```
| Parameter (Header)            | Count  | Min      | Max      | Mean         | Std Dev      |
|-------------------------------|--------|----------|----------|--------------|--------------|
| Length                        | 156    | 12.500   | 245.800  | 89.450       | 45.230       |
| CondHeight                    | 156    | 0.300    | 2.400    | 1.200        | 0.456        |
| ManningsN                     | 156    | 0.010    | 0.035    | 0.013        | 0.004        |
```

## Configuration Notes

### **Field Verification**
- Field symbols must match actual API method names
- Debugging block available for method inspection
- Version-specific field availability may vary

### **Statistics Exclusions**
- Text fields (IDs, notes, shapes)
- Code fields (size codes, material codes)
- Complex arrays (point arrays, hyperlinks)
- Boolean values converted to 1.0/0.0 for analysis

## Error Messages and Troubleshooting

### **Common Issues**
- **"No network loaded"**: Ensure a network is open before running
- **"Permission denied"**: Check folder write permissions
- **"AttributeMissing"**: Field not available in current API version
- **"No conduits selected"**: Select conduits in GUI before export

### **Debug Mode**
Uncomment the debugging block to inspect available methods:
```ruby
# conduit_example = cn.row_objects('sw_conduit').first 
# puts conduit_example.methods.sort.inspect
```

## Integration Notes
- Part of larger InfoWorks automation suite (Editions 41-50)
- Designed for SWMM to ICM InfoWorks network comparison
- Compatible with Innovyze GitHub repository standards
- Extensible for additional conduit parameters or object types