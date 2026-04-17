# SWMM Node CSV Export Script Summary

## Overview
This Ruby script exports selected SWMM (Storm Water Management Model) node objects from an InfoSWMM/InfoWorks ICM network to a CSV file. It includes advanced features like statistical analysis of numeric fields and specialized handling for SWMM-specific data structures such as pollutant inflows, treatment expressions, and dry weather flows.

## Key Features

### 1. **Interactive Field Selection with Statistics Option**
- User-friendly dialog for attribute selection
- "SELECT/DESELECT ALL FIELDS" toggle
- **NEW**: "Calculate Statistics for Numeric Fields" option
- Pre-configured defaults for essential SWMM node parameters

### 2. **Comprehensive SWMM-Specific Field Coverage**
The script supports exporting 60+ SWMM node attributes organized by functionality:

#### Core Identifiers & Location
- Node ID
- Node Type (Junction, Outfall, Storage, etc.)
- X/Y Coordinates

#### Routing & Hydrology
- Route to Subcatchment
- Unit Hydrograph ID
- Unit Hydrograph Area

#### Elevations and Depths
- Ground Level
- Invert Elevation
- Maximum Depth
- Surcharge Depth
- Initial Depth
- Ponded Area

#### Flooding Parameters
- Flood Type
- Flooding Discharge Coefficient

#### Groundwater Parameters
- Initial Moisture Deficit
- Suction Head
- Conductivity
- Evaporation Factor

#### Outfall-Specific Parameters
- Outfall Type
- Fixed Stage
- Tidal Curve ID
- Flap Gate

#### Storage Node Parameters
- Storage Type
- Storage Curve ID
- Functional Parameters (Coefficient, Constant, Exponent)

#### Inflows & Dry Weather Flow (DWF)
- Inflow Baseline/Scaling/Pattern
- Base DWF Flow
- DWF Patterns (1-4)
- Additional DWF (complex array)

#### Water Quality
- Treatment Expressions (complex pollutant-function pairs)
- Pollutant Inflows (concentration and patterns)
- Pollutant DWF

#### User Data
- Notes and Hyperlinks
- 10 User Number fields
- 10 User Text fields

### 3. **Advanced Data Processing**

#### Complex SWMM Data Structures
- **Treatment Arrays**: Formatted as `Pollutant:Result:Function;...`
- **Pollutant Data**: Structured as `Pollutant:Concentration:Pattern;...`
- **Additional DWF**: Multiple entries as `B:Baseline|P1:Pattern||...`
- **Hyperlinks**: Standard `Description,URL;...` format

#### Statistical Analysis (New Feature)
When enabled, calculates for numeric fields:
- Count
- Minimum value
- Maximum value
- Mean
- Standard deviation

Intelligently excludes text-based fields (IDs, types, patterns) from statistics.

### 4. **File Management**

#### Output Configuration
- Timestamped filename: `selected_swmm_nodes_export_YYYYMMDD_HHMMSS.csv`
- User-specified export directory
- Automatic directory creation

#### Smart Cleanup
- Platform-aware empty file detection
- Automatic removal of header-only files
- Comprehensive file validation

### 5. **Enhanced User Feedback**

#### Console Output
- Real-time processing status
- Detailed statistics table with formatted columns
- Performance metrics
- Warning messages for missing attributes

#### Statistics Display Format
```
----------------------------------------------------------------
| Parameter (Header)    | Count | Min    | Max    | Mean   | Std Dev |
----------------------------------------------------------------
| Gnd_Level            | 125   | 100.50 | 150.75 | 125.32 | 12.456  |
| Inv_Elev             | 125   | 95.20  | 145.50 | 120.10 | 11.234  |
----------------------------------------------------------------
```

#### Summary Dialog
- Export file path
- Number of nodes exported
- Field count per node

## Technical Implementation

### Dependencies
```ruby
require 'csv'
require 'fileutils'
```

### Statistical Functions
```ruby
def calculate_mean(arr)
def calculate_std_dev(arr, mean)
```

### Core API Methods
- `WSApplication.current_network` - Network access
- `network.row_objects('sw_node')` - SWMM node collection
- `node.selected` - Selection state
- `WSApplication.prompt` - User dialogs

### Error Handling
1. **Environment**: Application availability
2. **Network**: Loading validation
3. **File System**: Permissions and space
4. **Data Access**: Method availability
5. **Statistics**: Numeric conversion handling

## Usage Workflow

1. **Setup**
   - Open InfoSWMM/InfoWorks ICM network
   - Select SWMM nodes for export

2. **Execute**
   - Run script in application
   - Choose export folder
   - Select fields and statistics option

3. **Results**
   - CSV file with selected data
   - Optional statistics in console
   - Summary dialog

## SWMM-Specific Considerations

### Node Type Support
- Junctions
- Outfalls
- Storage nodes
- Dividers

### Water Quality Features
- Complex treatment expressions
- Multiple pollutant support
- Pattern-based variations

### Hydraulic Complexity
- Groundwater interactions
- Variable stage outfalls
- Storage curves

## Debugging Capabilities

### Debug Block
```ruby
# Uncomment to inspect sw_node methods
# Lists all available methods
# Helps verify field names
```

### Enhanced Logging
- Per-node processing status
- Missing attribute warnings
- Non-numeric field detection

## Performance & Optimization

### Efficiency Features
- Sequential processing
- Direct CSV writing
- Selective statistics calculation

### Memory Management
- No data buffering
- Incremental statistics updates
- Efficient array handling

## Customization Guide

### Adding Fields
```ruby
['Display Name', :method_symbol, default_state, 'CSV_Header']
```

### Modifying Complex Data Formats
- Treatment expression parsing
- Pollutant data structuring
- DWF pattern handling

## Best Practices

### Data Quality
1. **Type Safety**
   - Numeric validation for statistics
   - Boolean to numeric conversion
   - Error handling for type mismatches

2. **SWMM Compliance**
   - Proper field naming
   - Standard data formats
   - Pattern ID preservation

3. **User Experience**
   - Clear field descriptions
   - Logical grouping
   - Helpful error messages

## Limitations

1. Selection-based export only
2. Application environment dependency
3. CSV format constraints for complex arrays
4. Single-threaded processing

## Enhancement Opportunities

1. **Export Options**: Multiple formats (INP, Excel, JSON)
2. **Filtering**: Node type specific exports
3. **Validation**: SWMM compliance checking
4. **Visualization**: Statistics graphs
5. **Batch Processing**: Multiple networks
6. **Integration**: Direct SWMM import compatibility

## Key Differences from HW Scripts

### SWMM-Specific Features
- Treatment expressions handling
- Pollutant data structures
- DWF pattern support
- Groundwater parameters

### Statistical Analysis
- Automatic numeric field detection
- Formatted statistics table
- Intelligent field exclusion

### Data Complexity
- More complex array handling
- Multiple data relationship types
- Pattern-based time series

## Common Use Cases

1. **Model Migration**: Export nodes for SWMM model creation
2. **Quality Analysis**: Statistical review of elevations and depths
3. **Pollutant Studies**: Export treatment and concentration data
4. **Calibration**: Extract node parameters for comparison
5. **Documentation**: Complete node inventory with user fields

## Script Reliability

### Robust Features
- Comprehensive error handling
- Data type validation
- Missing method detection
- Graceful failure recovery

### Quality Assurance
- Statistics verification
- Export confirmation
- File integrity checks
- User notification system