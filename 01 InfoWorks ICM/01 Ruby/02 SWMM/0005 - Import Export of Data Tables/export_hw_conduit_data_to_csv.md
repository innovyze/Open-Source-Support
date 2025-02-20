 ## Overview
The export_hw_conduit_data_to_csv.rb script is designed to export conduit data from an InfoWorks ICM network to a CSV file. The script allows users to select various attributes to include in the export and provides a summary of the export process, including the version of InfoWorks ICM used and the number of conduits written.

# Key Features
User Prompt for Export Options:

The script displays a prompt dialog to the user, allowing them to select the folder for the exported file and various attributes to include in the CSV export.
The prompt includes options for attributes such as Pipe ID, US Node ID, Link Suffix, DS Node ID, Link Type, Asset ID, and many more.
Directory Handling:

The script ensures that the selected directory exists and sets the file path for the CSV export.
CSV Export:

The script builds the CSV header based on the selected options and writes the conduit data to the CSV file.
It handles various attributes, including numerical and text fields, and formats them appropriately.
Error Handling:

The script includes error handling for permission issues and unexpected failures during the CSV export process.
Timing and Logging:

The script logs the start and end times of the export process and calculates the time spent.
It provides a summary of the export process, including the number of conduits written and the time spent.
Summary Prompt:

After the export is complete, the script displays a prompt with the InfoWorks ICM version and the number of conduits written.