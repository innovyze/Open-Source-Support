# Top 10 Fail and Unconverge Objects

Self-contained InfoWorks ICM (`hw_*`) UI script that reads a simulation's `SIM{id}.log`, builds **top 10** selection lists per fail/unconverge category from the SIMULATING-phase summary, and opens a short HTML report in your browser.

Everything is in one file: [UIIE_top10_fail_unconverge.rb](UIIE_top10_fail_unconverge.rb). No extra folders or suite files are required.

## How it works

When you run the script from the UI with a database open, it automatically starts a short **ICMExchange** run on the **same script file**, passing it your database path and Sim ID. That headless pass reads the log, writes selection lists into the database, and builds the HTML summary. You do not open ICM Exchange or run command-line steps yourself.

Selection lists are built in the headless pass by opening the simulation's model network (writable latest commit), selecting the log's object IDs, then calling `save_selection`. All six category lists are saved directly into a single `Sim{n} Diagnostics` group (no per-category sub-group).

## UI usage

1. Open the database. Do not have the **latest version** of the simulation's model network open in GeoPlan — it stops the background task from saving selection lists. Older (read-only) versions and other networks can stay open.
2. Run the script; confirm **Yes**, then enter the **ID** of the completed Sim when prompted (right click > properties > ID, or "show details" in the database tree). Selecting a Sim in the tree first does **not** currently feed into this prompt — you always need to type the ID.
3. Review the **HTML summary** that opens in your browser. A message box confirms completion and tells you where to find the new selection lists; it replaces the old "Script Output" console entirely — the UI run no longer writes anything there.
4. If the browser does not open, the completion message box shows a text summary and the temp HTML path instead.
5. Refresh the database tree and open **`Sim{n} Diagnostics`** for the new selection lists.

## Prerequisites

- `SIM{id}.log` exists (the simulation has been run).
- Diagnostic logging is not level 48.
- The log contains a 1D timestep fail/unconverge summary section.

## Optional configuration

If the script cannot find ICMExchange on your PC, set `ICM_EXCHANGE_PATH` at the top of the script to the full path of `ICMExchange.exe`. This is install detection only — you still run the tool from the ICM Scripts list.

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| Script says ICMExchange was not found | Set `ICM_EXCHANGE_PATH` in the script header |
| Script says lists could not be saved because the network is open in GeoPlan | Close the latest version of that network, then run again |
| No result marker / log analysis failed | Check the error dialog; confirm Sim ID, database, and that results exist locally (cloud: download results first) |
| No lists created | Confirm the log has 1D data; check that the Run/network still resolves |
| Report did not open in browser | Use the text summary in the completion message or the temp HTML path shown there |
| List has fewer than 10 objects | Expected if log IDs are not on the latest network — the HTML report's **In latest network?** column and the text summary both list which IDs were skipped |

## Limitations

List names are deterministic (`Top 10 {Category}_v{commit_id}`), so re-running this script against the **same** network commit replaces that commit's existing lists in place (old one deleted, new one created) rather than duplicating or silently failing. In the rare case a previous list of that name cannot be deleted (e.g. a permissions/API error), the script leaves the old list untouched, does not create a new one for that category, and the completion message says so explicitly instead of just reporting "no selection lists were saved." In the rarer, worse case where the old list *is* deleted but saving its replacement then fails too, that category is left with no selection list at all (it had one before this run); the completion message calls this out explicitly as a warning and recommends running the script again. Lists contain only log top-10 IDs that exist on the **latest** network; missing IDs are listed in the HTML report and text summary (not backfilled with lower ranks). Category **%** is each object's share of the total counts in that category from the log.
