# Update Run to Latest Network Commit

This script demonstrates how to programmatically update an existing run to the latest committed version of its network using `update_to_latest`. This is the direct equivalent of pressing the **Update to Latest Version of Network** button in the Run view in the ICM user interface.

## Prerequisites

All three conditions must be satisfied before calling `update_to_latest`, otherwise Exchange will raise an exception:

1. The run's **Working** field must be set to `true`
2. There must be **no uncommitted changes** for the run's network
3. All **scenarios** configured for the run must still exist and be valid

## Usage

1. Set `DATABASE_PATH` to your database path, or leave it as `nil` to use the most recently opened database.
2. Set `RUN_ID` to the ID of the run you want to update.
3. Run the script from ICM Exchange.

## Notes

- This script is for **ICM Exchange only**. It will not run in the ICM UI scripting environment.
- After a successful update the run will display **"(latest commit)"** in the UI rather than a specific commit number. This is expected — the run now dynamically tracks the latest commit.
- Any existing simulation results for the run will be removed when the network version changes. The run must be re-executed after updating.
- If you need to also launch simulations after updating, refer to script **0007 - Running simulations**.
