# Initialization Phase-In Diagnostic Tool

## Purpose

Analyzes InfoWorks ICM simulation logs to identify initialization phase-in failures (Message 317/250), extracts affected network objects, and creates selection lists for easy review.

**Script Type:** Exchange Script

## Quick Start

1. Run `Run_Diagnostic_Tool.bat`
2. Enter simulation ID when prompted
3. Review CSV and selection lists in results folder

## Configuration

Edit `DATABASE_PATH` at top of `EX_Script.rb` (default: `nil` uses most recent database):
- Standalone: `'C:/MyDatabases/MyDatabase.icmm'`
- Workgroup: `'localhost:40000/MyDatabase'`
- Cloud: `'cloud://mydatabase.4@63f653b1c7cf77/name'`

## Output

1. **CSV**: `SIM[ID]_initialization_issues.csv` in results folder
   - Columns: Sim_ID, Phase_Number, Timestamp, Valid_Links, Valid_Nodes, Unmatched_IDs

2. **Model Group**: `Sim[ID] Diagnostics` (contains selection lists)

3. **Selection Lists**: `[SimName] Init Phase [N]_v[CommitID]`
   - One per phase with valid objects
   - Names auto-append `!` if duplicates exist

## How It Works

1. Parses `SIM[ID].log` for Message 317 (phase-in attempts) and Message 250 (failure)
2. Extracts node/link IDs from "Greatest change at" and "Halving:" lines
3. Strips bridge link suffixes (`_BE`, `_BO`) and validates against network
4. Creates CSV summary and selection lists for each phase

## Troubleshooting

### "Could not open database"
- Edit `DATABASE_PATH` at top of `EX_Script.rb`

### "Unable to open network"
- Close network in InfoWorks ICM UI before running

### "Log file not found"
- Verify simulation has been run and results path is accessible

### "Unmatched IDs" warnings
- Some log IDs may not exist in network (e.g., bridge link variants)
- Script continues normally - warnings are informational

## Requirements

- InfoWorks ICM Exchange
- Completed simulation with log file
- Network not open in UI
- Valid simulation ID

## Version History

- **v1.0** (2025-11-25): Initial release
  - Phase-in failure detection (Message 317/250)
  - CSV export and versioned selection lists
  - Bridge link suffix handling
  - Automatic name conflict resolution
