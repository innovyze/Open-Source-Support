# Simulation Diagnostic Tool

This Ruby script is designed to parse InfoWorks ICM simulation log files and automatically create selection lists for nodes and links that experienced issues during the simulation run. It helps users quickly identify and visualize problem areas in their network model.

## Purpose

When simulations encounter errors or warnings, the log file contains valuable diagnostic information. This tool:
- Extracts diagnostic information from simulation log files
- Identifies nodes and links mentioned in error/warning messages
- Creates selection lists to help visualize problem areas in the network
- Categorizes issues into different types (convergence, mass balance, instability)

## How It Works

1. **User Input**: Prompts the user to enter a simulation ID or name
2. **Simulation Lookup**: Finds the corresponding simulation object in the database
3. **Log File Access**: Locates the simulation log file (or prompts user if not found automatically)
4. **Log Parsing**: Reads and analyzes the log file for errors and warnings
5. **ID Extraction**: Identifies node and link IDs mentioned in error/warning messages
6. **Selection Lists**: Creates selection lists for each category of issues found
7. **Summary**: Displays a diagnostic summary in the console

## Features

- **User-Friendly Prompts**: Simple interface for entering simulation ID/name
- **Flexible Log File Location**: Automatically searches for log files or allows manual selection
- **Multiple Issue Categories**: Creates separate selection lists for:
  - Convergence issues
  - Mass balance issues
  - Instability issues
- **Light Error Handling**: Provides helpful messages without being overly verbose
- **Automatic Name Management**: Ensures unique selection list names

## Usage

### Prerequisites
- InfoWorks ICM with an open network
- A completed simulation with a log file
- The simulation must be in the current database

### Running the Script

1. Open InfoWorks ICM
2. Open a network from the database
3. Run this script from the UI
4. When prompted, enter the simulation ID (numeric) or simulation name
5. If the log file is not found automatically, you'll be prompted to select it
6. The script will:
   - Parse the log file
   - Display a summary in the console
   - Create selection lists for each issue category
7. Refresh the database tree to see the new selection lists

### Input

- **Simulation ID or Name**: You can provide either:
  - Numeric ID (e.g., `1234`)
  - Simulation name (e.g., `Base Run - 100yr Event`)

### Output

The script creates selection lists with the following naming convention:
- `Sim[ID]_Convergence`: Nodes/links with convergence issues
- `Sim[ID]_MassBalance`: Nodes with mass balance errors
- `Sim[ID]_Instability`: Nodes/links with instability issues

Selection lists are created in the same model group as the network.

## Console Output

The script provides detailed console output including:

```
Found simulation: Base Run (ID: 1234)
Parsing log file: C:\...\SIM1234.log

=== Simulation Diagnostic Summary ===
Total Errors: 15
Total Warnings: 42
Convergence Issues: 8
Mass Balance Issues: 3
Timestep Reductions: 25
Instability Issues: 4

--- Creating selection list for Convergence Issues ---
Selected node: MH_123
Selected link: P_456
Created selection list: Sim1234_Convergence

=== Processing Complete ===
Created 3 selection list(s):
  - Sim1234_Convergence
  - Sim1234_MassBalance
  - Sim1234_Instability

Refresh the database tree to view the new selection lists.
```

## Log File Format

The script expects log files in the standard InfoWorks ICM format:
- File naming: `SIM[ID].log` or `[SimulationName].log`
- Plain text format with timestamped entries
- Standard error/warning keywords: ERROR, FATAL, WARNING, WARN

## ID Extraction Patterns

The script recognizes node and link IDs in log messages using several patterns:
- "at node [ID]" or "at link [ID]"
- "Node [ID]" or "Link [ID]"  
- IDs in quotes or brackets

## Error Handling

The script includes light error handling for common scenarios:
- Simulation not found in database
- Log file not found at expected location
- Empty simulation ID
- Invalid log file path

If an error occurs, the script will display a user-friendly message and exit gracefully.

## Limitations

- Only creates selection lists for issues where node/link IDs can be extracted
- ID extraction depends on log file format and message patterns
- May not capture all issues if they don't follow standard patterns

## Tips

- If you don't know the simulation ID, you can find it in the database tree
- The script works best with recently completed simulations
- Review the console output for details on what was found and created
- Use the created selection lists to visually inspect problem areas in your network

## Example Workflow

1. Run a simulation that encounters some issues
2. Open the network associated with that simulation
3. Run this diagnostic tool script
4. Enter the simulation ID when prompted
5. Review the console summary to understand the types of issues
6. Check the created selection lists in the database tree
7. Use these selection lists to inspect and fix problem areas in your network

## Notes

- Selection lists are created in the parent model group of the current network
- If a selection list with the same name exists, a number suffix is added
- The script uses transactions to ensure database integrity
- Empty or no-issue log files will not create selection lists

## Version History

- Initial version: Comprehensive simulation diagnostic tool with log parsing and selection list creation
