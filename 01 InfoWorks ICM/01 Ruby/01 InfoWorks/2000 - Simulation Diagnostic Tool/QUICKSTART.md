# Quick Start Guide

## What This Tool Does
Parses simulation log files and creates selection lists highlighting nodes/links with issues.

## Quick Steps
1. Open InfoWorks ICM
2. Open a network from your database
3. Run `UI_Script.rb`
4. Enter your simulation ID or name when prompted
5. Review the console output
6. Refresh the database tree to see new selection lists

## Files in This Directory

- **UI_Script.rb** - Main script to run in InfoWorks ICM
- **README.md** - Complete documentation
- **EXAMPLE_LOG.md** - Explanation of log file patterns
- **example_sim.log** - Sample log file showing expected format
- **test_parser.rb** - Standalone test script (doesn't require InfoWorks ICM)

## Selection Lists Created

The tool creates up to 4 selection lists:
- `Sim[ID]_Convergence` - Convergence failures
- `Sim[ID]_MassBalance` - Mass balance errors
- `Sim[ID]_Instability` - Instability issues
- `Sim[ID]_AllErrors` - All error locations

## Testing Without InfoWorks ICM

Run `ruby test_parser.rb` to test the parsing logic with the example log file.

## Troubleshooting

**Q: Simulation not found?**
A: Verify the ID/name exists in the database. Check the database tree for the correct ID.

**Q: Log file not found?**
A: You'll be prompted to manually select the log file. Navigate to the simulation results folder.

**Q: No selection lists created?**
A: The log file may not contain identifiable node/link IDs in error messages. Check the console output for the diagnostic summary.

## Support

See README.md for complete documentation and usage examples.
