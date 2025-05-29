# SWMM Orifice Export Script Documentation

## Overview
This Ruby script automates the export of SWMM orifice data from InfoWorks ICM/InfoSWMM to CSV format. It provides comprehensive field selection, statistical analysis capabilities, and user-friendly prompts for customizing orifice data exports.

## Key Features

### **Data Export Capabilities**
- Exports selected SWMM orifice objects to timestamped CSV files
- Supports 30+ configurable orifice parameters
- Handles complex data types (point arrays, hyperlinks)
- User-selectable field configuration with individual toggles

### **Statistical Analysis**
- Optional statistical calculations for numeric fields
- Generates formatted tables showing:
  - Count, Min, Max, Mean, Standard Deviation
  - Automatically excludes non-numeric fields (IDs, shapes, types)
- Uses sample standard deviation formula (n-1 denominator)

### **User Interface**
- Interactive prompts for field selection
- "Select/Deselect All" toggle option
- Export folder selection with validation
- Summary dialog upon completion
- Progress tracking and comprehensive error reporting

## Supported SWMM Orifice Fields

### **Essential Fields (Default: Enabled)**
- **Orifice ID**: Unique identifier
- **US/DS Node IDs**: Upstream and downstream node connections
- **Link Type**: Should be "ORIFICE" for orifice objects
- **Shape**: Orifice geometry (CIRCULAR, RECT_CLOSED, RECT_OPEN)
- **Orifice Height**: Primary geometric dimension (Geom1 in SWMM5)
- **Invert Level**: Crest height/elevation
- **Discharge Coefficient**: Flow coefficient (Cd)

### **Geometric Properties**
- **Orifice Width**: Secondary dimension for rectangular shapes (Geom2)
- **Shape specifications**: Circular, rectangular configurations
- **Point Array**: Vertex coordinates for complex geometries
- **Dimensional parameters**: Height, width, invert elevations

### **Hydraulic Parameters**
- **Discharge Coefficient**: Flow resistance factor
- **Flap Gate**: Presence of backflow prevention (YES/NO)
- **Time to Open/Close**: Gating operation duration (seconds)
- **Flow control settings**: Operational parameters

### **Network Integration**
- **Branch ID**: Network subdivision identifier
- **Node connections**: Upstream/downstream relationships
- **Spatial data**: Coordinate arrays for positioning

### **User-Defined Fields**
- **10 User Number Fields**: Custom numeric parameters
- **10 User Text Fields**: Custom text annotations
- **Notes**: Detailed descriptions
- **Hyperlinks**: External references and documentation

## Technical Implementation

### **SWMM-Specific Features**
- Targets `sw_orifice` objects specifically
- Compatible with SWMM5 input file structure
- Handles SWMM geometric conventions (Geom1/Geom2)
- Processes SWMM-specific shape definitions

### **Data Processing**
- Processes only selected orifice objects
- Handles boolean values (converts to 1.0/0.0 for statistics)
- Sanitizes CSV data (removes semicolons and commas)
- Type conversion with error handling

### **Error Handling**
- Network validation and connection checks
- Orifice object existence verification
- File permission and disk space validation
- Graceful handling of missing attributes
- Comprehensive logging with object IDs

### **Performance Features**
- Iterator-based processing for memory efficiency
- Progress tracking with object counts
- Execution timing reports
- Automatic cleanup of empty files

## Usage Instructions

### **Prerequisites**
- InfoSWMM or InfoWorks ICM environment
- Network with SWMM orifice objects loaded
- Write permissions to export directory

### **Execution Steps**
1. **Select Orifices**: Use the GUI to select orifice objects for export
2. **Run Script**: Execute within the application environment
3. **Configure Export**:
   - Choose export folder
   - Select desired fields (essential fields enabled by default)
   - Enable statistics calculation if needed
4. **Review Results**: Check console output and summary dialog

### **Output Files**
- CSV format: `selected_swmm_orifices_export_YYYYMMDD_HHMMSS.csv`
- Automatic cleanup of empty files
- Timestamped for version control

## Statistical Output Example

```
| Parameter (Header)            | Count  | Min      | Max      | Mean         | Std Dev      |
|-------------------------------|--------|----------|----------|--------------|--------------|
| OrifHeight                    | 45     | 0.200    | 1.500    | 0.750        | 0.325        |
| InvertElev                    | 45     | 12.500   | 45.800   | 28.150       | 8.450        |
| DischCoeff                    | 45     | 0.600    | 0.650    | 0.620        | 0.015        |
| OpenCloseT                    | 12     | 5.000    | 30.000   | 15.500       | 7.200        |
```

## SWMM Integration Notes

### **SWMM5 Compatibility**
- **Geometry Fields**: Maps to Geom1 (height) and Geom2 (width) in SWMM5
- **Shape Types**: Supports standard SWMM orifice shapes
- **Crest Height**: Corresponds to invert level parameter
- **Flow Coefficients**: Compatible with SWMM discharge coefficients

### **Field Verification**
- Field symbols must match actual SWMM API method names
- Debugging block available for method inspection
- SWMM version-specific field availability may vary

### **Statistics Exclusions**
- Text fields (IDs, notes, shape names)
- Type fields (link_type, opening_type)
- Complex arrays (point_array, hyperlinks)
- Shape descriptors and categorical data

## Error Messages and Troubleshooting

### **Common Issues**
- **"No network loaded"**: Ensure a SWMM network is open before running
- **"No 'sw_orifice' objects found"**: Verify orifices exist in the model
- **"Permission denied"**: Check folder write permissions
- **"AttributeMissing"**: Field not available in current SWMM API version
- **"No orifices selected"**: Select orifice objects in GUI before export

### **Debug Mode**
Uncomment the debugging block to inspect available methods:
```ruby
# orifice_example = cn.row_objects('sw_orifice').first 
# puts orifice_example.methods.sort.inspect
```

## Configuration Notes

### **SWMM-Specific Considerations**
- Orifices typically don't use `link_suffix` like ICM links
- Shape field determines which geometric parameters are relevant
- Flap gate settings affect flow behavior
- Time-based controls may require additional fields

### **Export Customization**
- Essential fields enabled by default for basic SWMM analysis
- Advanced fields (user numbers/text) disabled by default
- Statistics calculation optional to reduce processing time
- Field selection persists through user interface

## Integration with SWMM Workflow

### **Model Comparison Applications**
- Compare orifice specifications between scenarios
- Validate design parameters across model versions
- Export for external analysis tools
- Generate reports for design documentation

### **Quality Assurance**
- Statistical analysis identifies outliers
- Field validation ensures data consistency
- Comprehensive logging tracks processing issues
- Automated cleanup prevents incomplete exports

This script forms part of the larger InfoWorks automation suite, specifically designed for SWMM network analysis and comparison tasks as outlined in Edition 41-44 of the series.