# HW_Weir CSV Export Script Summary

## Overview
This Ruby script exports selected `hw_weir` objects from an InfoWorks ICM network to a CSV file. It provides a user-friendly interface for selecting which weir attributes to export and handles various data types and error conditions.

## Key Features

### 1. **Interactive Field Selection**
- Presents a dialog box allowing users to select which weir attributes to export
- Includes a "SELECT/DESELECT ALL FIELDS" option for convenience
- Pre-configured with sensible defaults for commonly needed fields

### 2. **Comprehensive Field Coverage**
The script supports exporting 50+ weir attributes organized into categories:

#### Key Identifiers
- Upstream/Downstream Node IDs
- Link Suffix
- Asset ID/UID
- Infonet ID

#### Physical Characteristics
- Crest Level
- Width/Height
- Gate Height
- Length
- Orientation

#### Hydraulic Parameters
- Discharge Coefficients (primary, reverse, secondary)
- Modular Limit
- Notch parameters (height, angle, width, count)

#### Control Parameters (for gated weirs)
- Min/Max values and crest levels
- Opening ranges (min, max, initial)
- Gate movement speeds
- Control thresholds

#### Additional Data
- Settlement efficiencies
- Geometry (point arrays)
- User-defined fields (10 numeric, 10 text)
- Notes and hyperlinks

### 3. **Data Processing Features**

#### Selection Filtering
- Only exports weirs that are currently selected in the network
- Provides count of total weirs vs. selected weirs

#### Special Data Handling
- **Point Arrays**: Converted to `X1,Y1;X2,Y2;...` format
- **Hyperlinks**: Formatted as `Description,URL;...`
- **Arrays**: General arrays joined with commas
- **Null Values**: Exported as empty strings

#### Error Handling
- Gracefully handles missing attributes
- Logs warnings for inaccessible fields
- Continues processing despite individual field errors

### 4. **File Management**

#### Output Format
- CSV file with timestamp: `selected_hw_weirs_export_YYYYMMDD_HHMMSS.csv`
- User-specified export folder
- Creates folder if it doesn't exist

#### Cleanup Logic
- Automatically deletes empty CSV files (header-only)
- Validates file creation and permissions

### 5. **User Feedback**

#### Progress Reporting
- Console output during processing
- Shows current weir being processed
- Time tracking (start, end, duration)

#### Summary Dialog
- Final dialog showing:
  - Export file path
  - Number of weirs exported
  - Number of fields per weir

#### Error Messages
- Clear error reporting for:
  - No network loaded
  - Permission issues
  - Missing attributes
  - File write failures

## Technical Implementation

### Dependencies
```ruby
require 'csv'
require 'fileutils'
```

### Key Methods Used
- `WSApplication.current_network` - Access current network
- `network.row_objects('hw_weir')` - Get weir objects
- `weir.selected` - Check selection status
- `WSApplication.prompt` - User interface dialogs

### Error Categories Handled
1. **Environment Errors**: WSApplication not found
2. **Network Errors**: No network loaded
3. **File System Errors**: Permission denied, disk full
4. **Data Access Errors**: Missing methods/attributes
5. **CSV Format Errors**: Malformed data

## Usage Workflow

1. **Prerequisites**
   - Open a network in InfoWorks ICM
   - Select the weir objects you want to export

2. **Run Script**
   - Execute the script within the application
   - Choose export folder
   - Select desired fields (or use SELECT ALL)

3. **Output**
   - CSV file created in specified folder
   - Summary dialog confirms export details
   - Console shows detailed processing log

## Debugging Features

### Optional Debug Block (Commented)
```ruby
# Uncomment to inspect available methods on weir objects
# Helps verify field names match actual object methods
```

### Logging
- Detailed console output for troubleshooting
- Warning messages for missing attributes
- Error stack traces (first 5 lines)

## Performance Considerations

- Processes weirs one at a time to avoid memory issues
- Writes directly to CSV without intermediate storage
- Time tracking to measure performance

## Customization Options

### Adding New Fields
1. Add to `FIELDS_TO_EXPORT` array:
   ```ruby
   ['Display Name', :method_name, default_selected, 'CSV Header']
   ```

2. Add special handling if needed in the data processing section

### Modifying Export Format
- Change delimiter in CSV options
- Adjust array/point formatting logic
- Customize null value representation

## Best Practices Implemented

1. **Defensive Programming**
   - Checks for method existence before calling
   - Handles nil values gracefully
   - Validates file operations

2. **User Experience**
   - Clear error messages
   - Progress feedback
   - Summary of results

3. **Data Integrity**
   - Preserves data types where possible
   - Consistent formatting for complex types
   - No data loss from special characters

## Limitations

1. Only exports selected weirs (by design)
2. Requires InfoWorks ICM environment
3. CSV format limitations for complex nested data
4. Single-threaded processing

## Potential Enhancements

1. **Batch Processing**: Support for multiple object types
2. **Format Options**: Excel, JSON, or XML export
3. **Filtering**: Additional criteria beyond selection
4. **Performance**: Parallel processing for large networks
5. **Validation**: Data quality checks before export