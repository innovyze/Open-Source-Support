# Recursively find model network

This folder contains scripts to list all "Model Network" (InfoWorks) objects in an InfoWorks ICM database, regardless of nesting depth within model groups.

## Script Versions

- **UI_script.rb** - Operates on the currently open database in InfoWorks ICM; exports results to CSV (run from Network menu)
- **EX_script.rb** - Opens and processes a standalone database file; outputs to console (run from Exchange/Batch)

## Output Format

**UI Script Output:**
- CSV file with columns: Path, Network Name, Object ID
- Saved to: `C:\temp\InfoWorks_Networks_[timestamp].csv`
- File location displayed in console after completion

**Exchange Script Output:**
- Console output showing network name and path for each network found

## How it Works

**UI Script (UI_script.rb):**
1. Accesses the currently open database using `WSApplication.current_database`
2. Creates an empty array, $toProcess, to hold the objects to be processed
3. Adds all root model objects in the database to the $toProcess array
4. Enters a loop that continues until all objects have been processed (breadth-first search):
    - Removes the first object from the $toProcess array and sets it as the current object to process
    - If the current object is a "Model Network" object, collects its path, name, and ID
    - Adds all children of the current object to the $toProcess array for future processing
5. The loop continues until the $toProcess array is empty, meaning all objects have been processed
6. Exports collected data to a timestamped CSV file in C:\temp
7. Displays the CSV file location and summary count

**Exchange Script (EX_script.rb):**
1. Determines the directory of the current script file
2. Sets the name of the standalone database to open and constructs the full path to the database file
3. Opens the specified database without making it the active database
4. Follows the same breadth-first search process as the UI script (steps 2-5 above)
