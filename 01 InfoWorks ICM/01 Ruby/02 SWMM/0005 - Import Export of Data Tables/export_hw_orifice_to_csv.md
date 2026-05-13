# HW_Orifice CSV Export Script Summary

## Overview
This Ruby script exports selected `hw_orifice` objects from an InfoWorks ICM network to a CSV file. It provides an interactive interface for selecting orifice attributes to export, with robust error handling and data formatting capabilities specifically tailored for orifice hydraulic structures.

## Key Features

### 1. **Interactive Field Selection**
- User-friendly dialog for attribute selection
- "SELECT/DESELECT ALL FIELDS" toggle functionality
- Pre-configured defaults focusing on essential orifice parameters

### 2. **Comprehensive Field Coverage**
The script supports exporting 35+ orifice attributes organized into logical categories:

#### Key Identifiers
- Upstream/Downstream Node IDs
- Link Suffix
- Asset ID/UID
- Infonet ID

#### Basic Orifice Properties
- Link Type (should be ORIFICE)
- System Type
- Sewer Reference
- Branch ID

#### Physical Characteristics
- **Invert Level**: Bottom elevation of the orifice
- **Diameter**: Size of circular orifices
- **Opening Type**: Shape classification (CIRCULAR, RECTANGULAR, etc.)

#### Hydraulic Parameters
- **Discharge Coefficient (Cd)**: Primary flow coefficient
- **Secondary Discharge Coefficient**: For drowned/submerged conditions
- **Limiting Discharge**: Maximum flow capacity

#### Flow Control Parameters (Controllable Orifices)
- **Flow Limits**: Min/Max flow rates
- **Flow Rate Changes**: Positive/Negative change rates
- **Control Threshold**: Trigger level for control actions

#### Additional Data
- Settlement efficiencies (upstream/downstream)
- Geometry (point arrays)
- User-defined fields (10 numeric, 10 text)
- Notes and hyperlinks

### 3. **Data Processing Features**

#### Selection-Based Export
- Exports only orifices marked as selected
- Provides count statistics (total vs. selected)

#### Data Type Handling
- **Point Arrays**: Formatted as `X1,Y1;X2,Y2;...`
- **Hyperlinks**: Structured as `Description,URL;...`
- **Arrays**: Generic comma-separated format
- **Null Values**: Represented as empty strings

#### Error Management
- Graceful handling of missing attributes
- Warning logs for inaccessible fields
- Continuous processing despite errors

### 4. **File Management**

#### Output Configuration
- Timestamped filename: `selected_hw_orifices_export_YYYYMMDD_HHMMSS.csv`
- User-defined export directory
- Automatic directory creation

#### Intelligent Cleanup
- Removes empty CSV files automatically
- Platform-aware file size detection
- Header-only file detection

### 5. **User Feedback**

#### Progress Monitoring
- Real-time console logging
- Orifice identification in logs
- Performance timing metrics

#### Summary Reporting
- Final dialog displaying:
  - Export file location
  - Number of orifices exported
  - Field count per orifice

#### Error Communication
- Clear messages for:
  - Network availability
  - File permissions
  - Disk space
  - Data access issues

## Technical Implementation

### Dependencies
```ruby
require 'csv'
require 'fileutils'
```

### Core API Usage
- `WSApplication.current_network` - Network access
- `network.row_objects('hw_orifice')` - Orifice collection
- `orifice.selected` - Selection state
- `WSApplication.prompt` - User interface

### Error Handling Strategy
1. **Environment**: WSApplication presence
2. **Network**: Loading validation
3. **File System**: Permission and space checks
4. **Data Access**: Method availability
5. **CSV Format**: Data integrity

## Usage Workflow

1. **Preparation**
   - Load InfoWorks ICM network
   - Select orifice objects to export

2. **Execution**
   - Run script in application
   - Choose export directory
   - Select desired fields

3. **Output**
   - Timestamped CSV file
   - Summary statistics
   - Detailed console log

## Debugging Features

### Debug Block (Optional)
```ruby
# Uncomment to inspect orifice object methods
# Lists all available methods
# Helps verify field availability
```

### Logging Detail
- Per-orifice processing status
- Missing attribute notifications
- Limited stack traces (5 lines)

## Performance Aspects

- Memory-efficient sequential processing
- Direct CSV writing
- Execution time measurement

## Customization Guidelines

### Adding Fields
1. Update `FIELDS_TO_EXPORT` array:
   ```ruby
   ['Display Name', :method_name, default_state, 'CSV Header']
   ```

2. Add special handling if needed

### Export Modifications
- CSV delimiter options
- Complex type formatting
- Null representation changes

## Best Practices

### Code Design
1. **Defensive Approach**
   - Method existence checks
   - Null safety
   - Operation validation

2. **User Interface**
   - Clear error messaging
   - Progress indicators
   - Result summaries

3. **Data Handling**
   - Type consistency
   - Format standardization
   - Character escaping

## Limitations

1. Selection-based export only
2. InfoWorks ICM dependency
3. CSV format restrictions
4. Single-threaded execution

## Enhancement Possibilities

1. **Batch Operations**: Multiple object type support
2. **Export Formats**: Excel, JSON, XML options
3. **Filter Options**: Beyond selection status
4. **Performance**: Parallel processing
5. **Validation**: Pre-export checks
6. **Automation**: Scheduled exports

## Orifice-Specific Considerations

### Hydraulic Focus
- Emphasis on discharge coefficients
- Support for drowned conditions
- Flow limiting parameters

### Control Features
- Controllable orifice support
- Flow rate change parameters
- Threshold-based control

### Physical Properties
- Opening type classification
- Dimensional parameters
- Invert level tracking

## Common Applications

1. **Hydraulic Analysis**: Export discharge coefficients and flow limits
2. **Asset Inventory**: Complete orifice specifications with IDs
3. **Control System Review**: Controllable orifice parameters
4. **Maintenance Records**: User fields for inspection data
5. **Model Calibration**: Physical characteristics for validation

## Comparison with Other Export Scripts

### Similarities
- Same overall architecture
- Consistent error handling
- Identical user interface approach

### Differences
- Simpler parameter set than weirs/pumps
- Focus on basic hydraulic properties
- Less complex control logic
- Fewer operational parameters

## Script Reliability

### Data Integrity
- Preserves numeric precision
- Maintains text formatting
- Handles special characters

### Error Recovery
- Continues after field errors
- Logs all issues
- Provides actionable feedback

### File Safety
- Validates write operations
- Cleans up empty files
- Confirms successful export