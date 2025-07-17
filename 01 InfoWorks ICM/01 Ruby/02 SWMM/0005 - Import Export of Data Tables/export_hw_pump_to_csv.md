# HW_Pump CSV Export Script Summary

## Overview
This Ruby script exports selected `hw_pump` objects from an InfoWorks ICM network to a CSV file. It provides an interactive interface for selecting pump attributes to export and includes comprehensive error handling and data formatting capabilities.

## Key Features

### 1. **Interactive Field Selection**
- User-friendly dialog box for attribute selection
- "SELECT/DESELECT ALL FIELDS" toggle option
- Pre-configured defaults for essential pump fields

### 2. **Comprehensive Field Coverage**
The script supports exporting 45+ pump attributes organized into functional categories:

#### Key Identifiers
- Upstream/Downstream Node IDs
- Link Suffix
- Asset ID/UID
- Infonet ID

#### Basic Pump Properties
- Link Type (should be PUMP)
- System Type
- Sewer Reference
- Branch ID

#### Pump Operational Parameters
- **Switch Levels**: On/Off levels for pump activation
- **Discharge**: Fixed discharge rate
- **Head Discharge ID**: Reference to pump curve
- **Base Level**: Reference level for head-discharge curves
- **Delays**: On/Off delays in seconds

#### Flow and Speed Control (Variable Speed Pumps)
- **Flow Limits**: Min/Max flow rates
- **Flow Rate Changes**: Positive/Negative change rates
- **Flow Threshold**: Control threshold
- **Speed Parameters**:
  - Min/Max/Nominal speeds
  - Positive/Negative speed change rates
  - Speed threshold
- **Electric-Hydraulic Ratio**: For energy calculations

#### Additional Data
- Settlement efficiencies (upstream/downstream)
- Geometry (point arrays)
- User-defined fields (10 numeric, 10 text)
- Notes and hyperlinks

### 3. **Data Processing Features**

#### Selection Filtering
- Only exports pumps marked as selected in the network
- Provides statistics on total vs. selected pumps

#### Special Data Type Handling
- **Point Arrays**: Converted to `X1,Y1;X2,Y2;...` format
- **Hyperlinks**: Formatted as `Description,URL;...`
- **Generic Arrays**: Comma-separated values
- **Null Values**: Exported as empty strings

#### Robust Error Handling
- Gracefully handles missing attributes
- Logs warnings without stopping export
- Continues processing despite individual field errors

### 4. **File Management**

#### Output Configuration
- Timestamped filename: `selected_hw_pumps_export_YYYYMMDD_HHMMSS.csv`
- User-specified export directory
- Automatic directory creation if needed

#### Smart Cleanup
- Detects and removes empty CSV files
- Validates successful file creation
- Platform-aware file size calculations

### 5. **User Feedback System**

#### Real-time Progress
- Console logging during processing
- Current pump identification in logs
- Execution time tracking

#### Summary Reports
- Final dialog showing:
  - Complete export file path
  - Number of pumps exported
  - Field count per pump

#### Comprehensive Error Reporting
- Clear messages for:
  - Missing network
  - Permission denied
  - Disk space issues
  - Attribute access failures

## Technical Implementation

### Dependencies
```ruby
require 'csv'
require 'fileutils'
```

### Core API Methods
- `WSApplication.current_network` - Network access
- `network.row_objects('hw_pump')` - Pump collection
- `pump.selected` - Selection state check
- `WSApplication.prompt` - User dialogs

### Error Handling Categories
1. **Environment**: WSApplication availability
2. **Network**: Network loading status
3. **File System**: Permissions, disk space
4. **Data Access**: Method/attribute availability
5. **CSV Format**: Data formatting issues

## Usage Workflow

1. **Setup**
   - Open InfoWorks ICM network
   - Select pump objects for export

2. **Execute Script**
   - Run script in application environment
   - Select export folder location
   - Choose fields (individual or all)

3. **Results**
   - CSV file generated with timestamp
   - Summary dialog displays statistics
   - Console log available for debugging

## Debugging Capabilities

### Optional Debug Block
```ruby
# Uncomment to inspect pump object methods
# Useful for verifying field availability
# Shows all available methods on first pump
```

### Detailed Logging
- Per-pump processing status
- Missing attribute warnings
- Error stack traces (limited to 5 lines)

## Performance Characteristics

- Sequential processing (memory efficient)
- Direct CSV writing (no buffering)
- Performance metrics (execution time)

## Customization Guide

### Adding New Fields
1. Add entry to `FIELDS_TO_EXPORT`:
   ```ruby
   ['Display Name', :method_symbol, default_selected, 'CSV Header']
   ```

2. Implement special handling if required

### Modifying Export Behavior
- CSV formatting options
- Array/complex type handling
- Null value representation

## Best Practices

### Code Quality
1. **Defensive Programming**
   - Method existence validation
   - Nil value handling
   - Operation verification

2. **User Experience**
   - Intuitive error messages
   - Progress indication
   - Result summaries

3. **Data Integrity**
   - Type preservation
   - Consistent formatting
   - Special character handling

## Script Limitations

1. Requires selected objects (intentional design)
2. InfoWorks ICM environment dependency
3. CSV format constraints for complex data
4. Sequential processing only

## Enhancement Opportunities

1. **Multi-Type Export**: Support multiple object types in one run
2. **Additional Formats**: Excel, JSON, XML export options
3. **Advanced Filtering**: Beyond simple selection status
4. **Performance**: Batch processing for large datasets
5. **Validation**: Pre-export data quality checks
6. **Scheduling**: Automated periodic exports

## Key Differences from HW_Weir Script

### Field Specificity
- Pump-specific parameters (switch levels, speeds, flow rates)
- Variable speed pump support
- Energy efficiency parameters

### Operational Focus
- Emphasis on control parameters
- Flow and speed rate changes
- Delay timings

### Data Structure
- Similar overall architecture
- Pump-specific field naming
- Consistent error handling approach

## Common Use Cases

1. **Asset Management**: Export pump inventory with asset IDs
2. **Operational Analysis**: Switch levels and discharge rates
3. **Performance Studies**: Variable speed pump parameters
4. **Maintenance Planning**: User fields for maintenance data
5. **System Documentation**: Complete pump specifications