# Flow Survey Bulk Import Tool

The in-built flow survey import function can require repetitive mouse clicks and requires individual setup for each event. This tool looks to simplify this process.
Bulk-imports flow survey `.std` files into an InfoWorks ICM database as Flow Survey objects with observed event children (Depth, Flow, Velocity, Rainfall) via CSV files.

## Files

| File | Description |
|------|-------------|
| `hw_flow_survey_import_ui.rb` | UI script — run from ICM to parse `.std` files and generate CSVs |
| `hw_flow_survey_import_exchange.rb` | Exchange script — imports CSVs into the database (launched automatically) |

## Setup

1. Open `hw_flow_survey_import_exchange.rb` and set `DB_PATH` (line 13) to the full path of your `icm` database.
2. Place both `.rb` scripts in the same folder.
3. Place your `.std` files in a single folder (e.g. `Final Data`).

## Usage

1. In ICM, go to **Network > Run Ruby Script** and select `hw_flow_survey_import_ui.rb`.
2. When prompted, select the folder containing your `.std` files.
3. Review the sensor summary (counts of F/D/R sensors, date range, interval).
4. Choose whether to define individual events:
   - **No** — imports the full survey period only.
   - **Yes** — opens a guided workflow:
     - **Dry Days** — one at a time. Each dialog has 2 fields (name + start), pre-filled with suggested values. Duration is fixed at 24 hours. Rainfall is excluded. After each event, choose "Add another?" or finish.
     - **Storm Events** — one at a time. Each dialog has 3 fields (name + start + end), pre-filled with suggested values. Rainfall is included. After each event, choose "Add another?" or finish.
   - Each dialog shows the valid survey date range in the title for reference.
   - Press **Cancel** on any dialog to skip that phase or stop adding events.
5. Review the event summary and confirm to launch the Exchange import.
6. Temporary CSV files are automatically cleaned up after a successful import.

### Date Format

All dates must be entered as: `DD/MM/YYYY HH:MM`

If an invalid date is entered the dialog will re-appear with your previous values so you can correct them.

## Database Structure

The tool creates the following hierarchy:

```
Flow Survey Data (Model Group)
├── Flow Monitors (Model Group)
│   └── [Event Name] (Flow Survey)
│       ├── Observed Depth Event
│       ├── Observed Flow Event
│       ├── Observed Velocity Event
│       └── Rainfall Event (storms and full period only)
└── Depth Monitors (Model Group)
    └── [Event Name] (Flow Survey)
        ├── Observed Depth Event
        └── Rainfall Event (storms and full period only)
```

## Sensor Classification

Sensors are classified by `.std` filename prefix:

| Prefix | Type | Destination |
|--------|------|-------------|
| `F` | Flow monitor | Flow Monitors group (depth, flow, velocity) |
| `D` | Depth-only monitor | Depth Monitors group (depth only) |
| `R` | Rain gauge | Included as rainfall in both groups |

## Running the Exchange Script Manually

If the automatic launch fails, run it directly:

```
ICMExchange.exe hw_flow_survey_import_exchange.rb
```

Ensure `exchange_config.txt` exists in the `csv_output/` folder (written automatically by the UI script), or set the `CSV_FOLDER` variable in the Exchange script.
