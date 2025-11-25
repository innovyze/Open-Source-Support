# Example Simulation Log File

This directory contains an example simulation log file that demonstrates the format and content that the Simulation Diagnostic Tool expects to parse.

## Example Log File: example_sim.log

The example log file (`example_sim.log`) contains sample entries showing:
- Timestamp format
- Error messages with node/link identifiers
- Warning messages
- Different types of issues (convergence, mass balance, instability)

## How to Use the Example

1. Review the example log file to understand the expected format
2. The tool will parse log files with similar patterns
3. Node and link IDs are extracted from error/warning messages
4. Selection lists are created based on the extracted IDs

## Log File Patterns

The tool recognizes several patterns for extracting node/link IDs:

### Pattern 1: "at node/link [ID]"
```
12:34:56 ERROR: Convergence failure at node MH_123
12:34:57 WARNING: High velocity at link P_456
```

### Pattern 2: "Node/Link [ID]"
```
12:35:00 ERROR: Node MH_789 exceeded max iterations
12:35:01 WARNING: Link P_101 has reverse flow
```

### Pattern 3: IDs in quotes
```
12:35:05 ERROR: Mass balance error for node "MH_555"
12:35:06 WARNING: Instability detected at "P_999"
```

## Testing the Tool

While you cannot test this tool without a running InfoWorks ICM environment, you can:
1. Review the `UI_Script.rb` code to understand the parsing logic
2. Examine the example log file to see what patterns are recognized
3. Understand how IDs are extracted and selection lists are created

## Note

This is an example only. Actual simulation log files from InfoWorks ICM will have more detailed information and different formats depending on the simulation type and version.
