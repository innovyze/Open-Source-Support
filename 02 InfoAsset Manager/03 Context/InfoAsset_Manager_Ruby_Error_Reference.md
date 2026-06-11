# InfoAsset Manager Ruby Error Reference

**Purpose:** Common IAM Ruby failure modes, likely causes, and recovery steps.

**Scope:** Grounded in repository examples, current context files, and documented README behavior.

**Last Updated:** May 29, 2026

## Runtime Boundary Errors

See `InfoAsset_Manager_Ruby_Boundary_Guard.md` → **Runtime Guard** for the authoritative signal lists and correct patterns.

### Symptom: Exchange script starts from `WSApplication.current_network`

**Likely cause:** UI and Exchange entry patterns were mixed.

**Fix:** Use `WSApplication.current_network` only in UI mode. For Exchange, open the database explicitly with `WSApplication.open(...)`.

### Symptom: UI script contains hard-coded database paths and network IDs as required input

**Likely cause:** An Exchange example was copied into a UI script without branching.

**Fix:** Replace the entry flow with `WSApplication.current_network` for UI work. If both runtimes are required, branch early on `WSApplication.ui?`.

## Placeholder Reuse Errors

### Symptom: Database cannot be opened, or the wrong database/network is targeted

**Likely cause:** Example placeholders were reused as if they were production values.

See `InfoAsset_Manager_Ruby_Lessons_Learned.md` → **Do Not Reuse Example Paths or IDs As Real Defaults** for the full list of common placeholder patterns.

**Fix:**
- Treat all connection strings and object IDs in examples as placeholders unless the task explicitly provides real values.
- Replace them with task-specific database paths and object IDs.

## UI Validation And Cancel Errors

### Symptom: `Parameters dialog closed\nScript cancelled`

**Observed in:** attachment rename and WSAA XML export examples.

**Meaning:** The user cancelled the prompt.

**Fix:**
- Exit cleanly after the prompt returns `nil`.
- Do not continue into export or file processing logic.

### Symptom: `No file selected\nProcess cancelled`

**Observed in:** INTERLIS import examples.

**Meaning:** A required file chooser returned no selection.

**Fix:**
- Stop immediately and avoid partial processing.

### Symptom: `Files folder required\nScript cancelled`

**Observed in:** file rename and WSAA XML export examples.

**Meaning:** The selected folder path is missing or blank.

**Fix:**
- Validate folder input before running export logic.

### Symptom: `Mapping file required\nScript cancelled`

**Observed in:** attachment rename example.

**Meaning:** The workflow requires an external mapping file and it was not supplied.

**Fix:**
- Validate the mapping file path before the main processing loop.

### Symptom: `No selected objects were found in the network. Select objects on the GeoPlan and run the script again.`

**Observed in:** coordinate conversion example.

**Meaning:** The script depends on current selection state.

**Fix:**
- Require a selection before processing, or change the script to prompt for target objects another way.

## Database Access Errors

### Symptom: `ERROR: Could not access the current database from the open network.`

**Observed in:** GeoJSON export example.

**Likely cause:** The script expects database access from the current UI network and could not resolve it.

**Fix:**
- Prefer `net.database` when available.
- Fall back to `WSApplication.current_database` when supported.
- Fail fast if neither is available.

### Symptom: `ERROR: Selection List ID '...' was not found in this database.`

**Observed in:** GeoJSON export example.

**Likely cause:** The wrong numeric ID was supplied, often an Asset Group ID instead of a Selection List ID.

**Fix:**
- Validate the object type in the current database before running the export.
- Tell the user to use the Selection List object ID, not the parent Asset Group ID.

## Config-Driven Import/Export Errors

See also `InfoAsset_Manager_Ruby_Lessons_Learned.md` → **ODEC and ODIC Usually Depend On Config Files** for the pitfall guidance.

### Symptom: ODEC or ODIC workflow fails before processing data

**Likely causes:**
- Missing config file
- Wrong table or source class name
- Missing options such as `Error File`, image folder, or callback class

**Fix:**
- Verify the config file path first.
- Verify the import/export table name and external source name.
- Keep an `Error File` path set during troubleshooting.

### Symptom: Import or export silently behaves incorrectly after copy-pasting an example

**Likely cause:** The example carried task-specific table names, source names, or output paths.

**Fix:**
- Audit every positional argument to `odec_export_ex` or `odic_import_ex` before use.
- Replace example-specific filenames, database names, and table names.

## Version And Availability Errors

### Symptom: PACP or MACP method is missing or fails unexpectedly

**Likely cause:** Method availability is version-gated.

**Evidence in repo:** the README for PACP and MACP methods documents a later-version dependency.

**Fix:**
- Verify the installed IAM version against official Help before using these methods as defaults.
- Do not assume every environment supports PACP or MACP import/export.

## Retrieval Errors

### Symptom: Generated IAM Ruby contains ICM objects, runs, scenarios, or SQL syntax

**Likely cause:** Retrieval pulled from the wrong product pack or the wrong language layer.

**Fix:**
- Re-route through `Instructions.md`, `Boundary_Guard.md`, and the correct example index.
- Load this file plus `Lessons_Learned.md` before retrying generation.

## Fast Debug Checklist

1. Confirm product is InfoAsset Manager.
2. Confirm runtime is UI, Exchange, or dual-mode.
3. Check for placeholder database paths or object IDs.
4. Check whether a config file, folder, or mapping file is required.
5. Check whether the workflow depends on current selection or current database access.
6. Check whether the method is version-gated.