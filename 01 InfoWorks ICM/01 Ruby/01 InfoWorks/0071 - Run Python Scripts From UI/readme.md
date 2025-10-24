# Run Python Scripts From UI

This script demonstrates how to integrate Python scripts with Ruby in InfoWorks ICM by exporting network data, processing it with Python, and using the results to update selections in the network.

## How it Works

1. **Export Data**: The Ruby script exports all node data (manhole ID, system type, and depth) to a CSV file.

2. **Run Python Script**: The Ruby script executes a Python script located in the same folder that reads the exported CSV file.

3. **Filter Data**: The Python script filters nodes based on criteria (e.g., system type = "storm" and depth > 0.5 meters) and exports the filtered results to a new CSV file.

4. **Apply Selection**: The Ruby script reads the filtered CSV file and selects the matching nodes in the network.

## Requirements

- Python must be installed and accessible from the command line
- Python packages: `pandas`
- Both `ui.rb` and `python.py` must be in the same folder

## Usage

1. Place both the Ruby script (`ui.rb`) and Python script (`python.py`) in the same folder.
2. Run the Ruby script from the InfoWorks ICM UI.
3. The script will automatically export data, run the Python filtering, and select the filtered nodes in the network.

## Files Included

- `ui.rb`: Main Ruby script that handles data export, Python execution, and selection
- `python.py`: Python script that filters node data based on specified criteria

---
*Generated using AI*
