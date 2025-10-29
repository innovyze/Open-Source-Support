# Bulk Delete Existing Scenarios

This script provides a user-friendly interface to delete multiple scenarios from your InfoWorks ICM network, with options to delete all scenarios or select specific ones.

## How it Works

1. **List Scenarios**: The script collects all existing scenarios in the network, excluding the "Base" scenario.

2. **User Selection**: Displays a dialog box with checkboxes for each scenario, plus a "Delete all" option at the top.

3. **Delete All Option**: If "Delete all" is selected, all non-Base scenarios will be marked for deletion.

4. **Confirmation**: Before deleting, the script displays a confirmation dialog showing which scenarios will be deleted.

5. **Delete Scenarios**: Upon confirmation, the selected scenarios are removed from the network.

6. **Reminder**: The script reminds you to commit changes for the deletions to take effect.

## Usage

1. Run the script in InfoWorks ICM with an open network.
2. Select the scenarios you want to delete from the checkbox list, or choose "Delete all" to select all scenarios.
3. Confirm the deletion when prompted.
4. Remember to commit your changes to make the deletions permanent.

## Safety Features

- The "Base" scenario is always protected and cannot be deleted
- Confirmation dialog prevents accidental deletion
- Option to cancel at any point without making changes
- Clear feedback messages throughout the process

---
*Generated using AI*
