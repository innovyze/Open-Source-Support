markdown
# Generic Infoworks/SWMM Object Data Exporter with Statistics

## Overview
This Ruby script facilitates the export of selected object types (e.g., `hw_node`, `sw_subcatchment`) and their fields from a network in a WSApplication environment to a CSV file. It also calculates basic statistics for numeric fields based on a user-provided `parameters.rb` file (`hw_parameters.rb` or `sw_parameters.rb`).

## Key Features
- **Dynamic Object and Field Selection**: Users can select object types and specific fields for export.
- **Statistics Calculation**: Computes mean, standard deviation, min, and max for numeric fields.
- **CSV Export**: Writes selected data to CSV files with timestamps.
- **Error Handling**: Robust error handling for file operations, network access, and data processing.
- **User Interaction**: Utilizes WSApplication dialogs for file and field selection.

## Dependencies
- Ruby libraries: `csv`, `fileutils`
- WSApplication environment for network access and UI prompts.

## Script Structure

### Helper Functions
1. **calculate_mean(arr)**:
   - Computes the mean of an array of numbers.
   - Returns `nil` if the array is empty or `nil`.

2. **calculate_std_dev(arr, mean)**:
   - Calculates the sample standard deviation of an array given its mean.
   - Returns `nil` if the array is empty, mean is `nil`, or array length is less than 2.

3. **parse_parameters_file(file_path)**:
   - Parses a `parameters.rb` file to extract table names and their fields.
   - Uses regex to identify table names (`****hw_node`, `****sw_node`) and fields.
   - Excludes fields ending with `_flag`.
   - Returns a hash: `{ "table_name" => ["field1", "field2", ...], ... }`.
   - Handles errors for missing or malformed files.

### Main Logic (`run_export_script`)
1. **Initialization**:
   - Starts the script, logs the start time, and connects to the current WSApplication network.
   - Exits if no network is loaded or WSApplication is unavailable.

2. **Parameters File Selection**:
   - Prompts the user to select a `parameters.rb` file using `WSApplication.file_dialog`.
   - Validates file existence and parses it to retrieve available tables and fields.

3. **Object Type Selection**:
   - Displays a dialog for users to select object types (tables) from the parsed parameters file.
   - Exits if no tables are selected or available.

4. **Per-Table Processing**:
   - For each selected table:
     - Prompts for field selection, export folder, and whether to calculate statistics.
     - Creates a timestamped CSV file in the specified folder.
     - Iterates through selected objects in the network, writing data for chosen fields to the CSV.
     - Handles special cases for array-type fields (e.g., `treatment`, `pollutant_inflows`, `additional_dwf`, `hyperlinks`) with custom formatting.
     - Collects numeric data for statistics if enabled.

5. **CSV Export**:
   - Writes a header row based on selected fields.
   - Processes each selected object, extracting field values and handling errors (e.g., missing attributes).
   - Writes data rows to the CSV, converting arrays to semicolon-separated strings.

6. **Statistics Calculation**:
   - For numeric fields, calculates count, min, max, mean, and standard deviation.
   - Filters out likely non-numeric fields (e.g., IDs, names, text fields) based on naming conventions.
   - Outputs a formatted table of statistics if applicable.

7. **Summary and Cleanup**:
   - Displays a summary dialog for each table, showing the export file path, objects written, and fields exported.
   - Deletes empty CSV files (containing only headers).
   - Logs processing time and any warnings (e.g., missing attributes).

8. **Script Completion**:
   - Logs total execution time and displays a completion message via `WSApplication.message_box`.

### String Helper
- **String#singularize**:
  - Basic method to singularize table names (e.g., `nodes` to `node`, `categories` to `category`).
  - Used to identify ID fields.

## Error Handling
- Handles file access errors (`Errno::ENOENT`, `Errno::EACCES`, `Errno::ENOSPC`).
- Catches invalid field access (`NoMethodError`) and logs warnings.
- Manages user cancellations during dialogs.
- Provides detailed error messages with backtraces for unexpected failures.

## Output
- **CSV Files**: One per selected table, named `selected_[table_name]_export_[timestamp].csv`.
- **Console Output**: Logs progress, errors, warnings, and statistics.
- **UI Dialogs**: Prompts for file/field selection and displays summaries.

## Usage Notes
- Run within a WSApplication environment with a loaded network.
- Requires a valid `parameters.rb` file with table and field definitions.
- Uncomment DEBUG blocks (not shown in the provided code) to troubleshoot field name issues.
- Statistics are calculated only for fields deemed numeric (excluding IDs, names, etc.).

## Example Workflow
1. User selects `hw_parameters.rb` via file dialog.
2. Script parses file, identifying tables like `hw_node`, `sw_subcatchment`.
3. User selects tables and fields, specifies an export folder, and opts for statistics.
4. For each table, a CSV is generated with selected fields, and statistics are printed for numeric fields.
5. Summary dialogs confirm the export details.

## Limitations
- Relies on WSApplication-specific methods (`current_network`, `file_dialog`, `prompt`, `message_box`).
- Assumes `parameters.rb` follows a specific format with `****table_name` and numbered field definitions.
- Statistics exclude fields likely to be non-numeric based on heuristic naming rules.
- No built-in validation for field data types beyond basic checks.

## Future Improvements
- Add support for custom field type definitions in `parameters.rb`.
- Enhance array field formatting with user-configurable separators.
- Include advanced statistics (e.g., median, quartiles).
- Add logging to a file in addition to console output.

## Execution
- Call `run_export_script` to start the process.
- Script execution time is tracked and reported.

**Last Updated**: June 9, 2025