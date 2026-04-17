# SWMM Weir CSV Export Script Summary

## Overview
This Ruby script exports selected SWMM (Storm Water Management Model) weir objects from an InfoSWMM/InfoWorks ICM network to a CSV file. It includes statistical analysis capabilities and handles SWMM-specific weir types including transverse, sideflow, V-notch, trapezoidal, and roadway weirs.

## Key Features

### 1. **Interactive Field Selection with Statistics**
- User-friendly dialog for attribute selection
- "SELECT/DESELECT ALL FIELDS" toggle option
- **Statistical Analysis Option**: Calculate min, max, mean, and standard deviation
- Pre-configured defaults for essential SWMM weir parameters

### 2. **SWMM-Specific Weir Field Coverage**
The script supports exporting 40+ SWMM weir attributes organized by functionality:

#### Core Identifiers
- Weir ID (SWMM link name)
- Upstream Node ID
- Downstream Node ID
- Branch ID

#### Weir Types & Characteristics
- **Link Type**: TRANSVERSE, SIDEFLOW, V-NOTCH, TRAPEZOIDAL, ROADWAY
- **Crest Level**: Elevation of weir crest
- **Weir Height**: Interpretation varies by type:
  - Height for TRANSVERSE/SIDEFLOW/V-NOTCH
  - Depth for ROADWAY
- **Weir Width**: Interpretation varies by type:
  - Width for TRANSVERSE/SIDEFLOW
  - Top width for TRAPEZOIDAL
  - Surface width for ROADWAY

#### Geometric Parameters
- **Left Slope**: For trapezoidal and roadway weirs
- **Right Slope**: For trapezoidal weirs
- **End Contractions**: Number of contracted ends
- **Point Array**: Vertex coordinates for spatial representation

#### Hydraulic Coefficients
- **Discharge Coefficient (Cd)**: Primary flow coefficient
- **Sideflow Discharge Coefficient**: For SIDEFLOW weirs
- **Secondary Discharge Coefficient**: For drowned/surcharge conditions
- **Variable Discharge Coefficient**: YES/NO flag for using weir curves

#### Control Features
- **Weir Curve ID**: Reference to discharge curve
- **Flap Gate**: YES/NO for one-way flow
- **Allows Surcharge**: YES/NO for surcharge algorithm

#### User Data
- Notes and Hyperlinks
- 10 User Number fields
- 10 User Text fields

### 3. **Advanced Data Processing**

#### SWMM-Specific Data Handling
- **Boolean Conversion**: YES/NO or 1/0 values handled for statistics
- **Point Arrays**: Formatted as `X1,Y1;X2,Y2;...`
- **Hyperlinks**: Standard `Description,URL;...` format
- **Type-Specific Parameters**: Different interpretations based on weir type

#### Statistical Analysis Features
When enabled:
- Calculates statistics for numeric fields only
- Intelligently excludes IDs, types, and text fields
- Handles boolean values as 1/0 for statistics
- Formatted table output with aligned columns

### 4. **File Management**

#### Output Configuration
- Timestamped filename: `selected_swmm_weirs_export_YYYYMMDD_HHMMSS.csv`
- User-specified export directory
- Automatic directory creation

#### Intelligent Cleanup
- Detects empty files (header-only)
- Platform-aware file size calculation
- Automatic deletion of empty exports

### 5. **Enhanced User Feedback**

#### Console Output
- Real-time processing status
- Per-weir identification in logs
- Formatted statistics table
- Performance metrics

#### Statistics Table Format
```
----------------------------------------------------------------
| Parameter (Header)    | Count | Min    | Max    | Mean   | Std Dev |
----------------------------------------------------------------
| CrestElev            | 45    | 120.50 | 135.75 | 128.32 | 3.456   |
| WeirHeight           | 45    | 1.500  | 5.500  | 3.250  | 0.875   |
| DischCoeff           | 45    | 2.800  | 3.300  | 3.150  | 0.125   |
----------------------------------------------------------------
```

#### Summary Dialog
- Export file path
- Number of weirs written
- Field count per weir

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
- `network.row_objects('sw_weir')` - SWMM weir collection
- `weir.selected` - Selection state check
- `WSApplication.prompt` - User interface

### Error Handling
1. **Environment**: Application presence validation
2. **Network**: Loading state verification
3. **File System**: Permission and space checks
4. **Data Access**: Method availability
5. **Type Conversion**: Numeric parsing for statistics

## Usage Workflow

1. **Preparation**
   - Load InfoSWMM/InfoWorks ICM network
   - Select SWMM weir objects

2. **Execution**
   - Run script in application
   - Choose export folder
   - Select fields and statistics option

3. **Results**
   - CSV file with selected data
   - Optional statistics display
   - Summary confirmation dialog

## SWMM Weir-Specific Considerations

### Weir Type Support
The script handles all SWMM weir types with their specific parameters:

#### TRANSVERSE
- Standard overflow weir
- Height and width parameters

#### SIDEFLOW
- Lateral overflow structure
- Additional sideflow coefficient

#### V-NOTCH
- Triangular weir
- Height defines notch depth

#### TRAPEZOIDAL
- Trapezoidal cross-section
- Left and right slopes

#### ROADWAY
- Broad-crested weir
- Surface width and road parameters

### SWMM5 Geometry Mapping
- Geom1 → weir_height (varies by type)
- Geom2 → weir_width (varies by type)
- Geom3 → left_slope
- Geom4 → right_slope

## Debugging Features

### Debug Block
```ruby
# Uncomment to inspect sw_weir methods
# Shows all available methods
# Helps verify field names match SWMM structure
```

### Enhanced Logging
- Weir ID in all messages
- Missing attribute warnings
- Numeric conversion notifications

## Performance & Optimization

### Efficiency Features
- Direct CSV writing
- Incremental statistics calculation
- Memory-efficient processing

### Data Validation
- Type checking for statistics
- Boolean to numeric conversion
- Safe array handling

## Customization Guide

### Adding Fields
```ruby
['Display Name', :method_symbol, default_state, 'CSV_Header']
```

### Modifying Type-Specific Logic
- Adjust geometry interpretation
- Add new weir types
- Customize coefficient handling

## Best Practices

### SWMM Compliance
1. **Field Naming**
   - Match SWMM .inp conventions
   - Use standard abbreviations
   - Maintain type consistency

2. **Data Quality**
   - Validate numeric ranges
   - Check type-specific requirements
   - Preserve precision

3. **User Experience**
   - Clear field descriptions
   - Logical grouping
   - Helpful warnings

## Limitations

1. Selection-based export only
2. Application environment required
3. CSV format for complex geometries
4. Single-threaded processing

## Enhancement Opportunities

1. **SWMM Integration**: Direct .inp file generation
2. **Type Filtering**: Export specific weir types only
3. **Validation**: SWMM compliance checking
4. **Visualization**: Weir curve plotting
5. **Batch Processing**: Multiple networks
6. **Cross-Reference**: Node connectivity validation

## Comparison with Other Scripts

### vs. HW_Weir Script
- Simpler parameter set
- SWMM-specific type system
- Different geometry interpretation
- Statistical analysis addition

### vs. SWMM Node Script
- Focused on hydraulic structures
- Type-dependent parameters
- Simpler data structures
- No water quality parameters

### Shared Features
- Statistical analysis option
- Consistent UI approach
- Robust error handling
- Smart file management

## Common Use Cases

1. **Model Migration**: Export weirs for SWMM model building
2. **Hydraulic Analysis**: Review discharge coefficients and dimensions
3. **Type Inventory**: Catalog weir types in the system
4. **Calibration**: Extract parameters for comparison
5. **QA/QC**: Statistical review of weir parameters

## Script Reliability

### Robust Features
- Comprehensive error handling
- Type-safe conversions
- Missing method detection
- Graceful failure modes

### Quality Assurance
- Statistics validation
- Export verification
- File integrity checks
- Clear user feedback

## SWMM-Specific Notes

### Parameter Variations
Different weir types use geometry fields differently:
- Check type before interpreting height/width
- Slopes only apply to certain types
- Some parameters are type-exclusive

### Boolean Handling
SWMM uses YES/NO or 1/0 for:
- Flap gates
- Variable discharge coefficients
- Surcharge allowance

### Curve References
Weir curves allow variable discharge coefficients based on head differential, referenced by ID when var_dis_coeff is YES.