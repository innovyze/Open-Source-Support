# Copy Network Attachments to Folder

## UI-CopyExport-VideoFileIn.rb

Script: **[UI-CopyExport-VideoFileIn.rb](./UI-CopyExport-VideoFileIn.rb)**

This UI script copies files referenced by the `video_file_in` field on the currently selected CCTV Survey objects to a destination folder defined in the script configuration.

As a first preference the copied filename is the original filename; second preference is the CCTV Survey ID (with non-alphanumeric characters removed). The destination filename used is reported in the script output.

- If a file already exists in the destination with both preferred filenames, the file will not be copied – reported in the log.
- If a referenced file is not found – reported in the log.
- If there is nothing referenced for a selected survey – reported in the log.

---

## IE-CopyNetworkAttachments.rb

Script: **[IE-CopyNetworkAttachments.rb](./IE-CopyNetworkAttachments.rb)**

This InfoAsset Exchange script scans a single configured network for all attachment and image files, copies every referenced file to a chosen destination folder, and produces an index CSV mapping each file back to the network object it belongs to.

### What the script does

1. Reads all attachment and video UIDs from the SNumbat data store for the target database.
2. Opens the configured network and iterates every object across all tables that carry an attachments field.
3. For each object it checks:
   - The **attachments collection** (`ro.attachments`) – carries full metadata (purpose, original filename, description).
   - Individual **image/attachment reference fields** (e.g. `photo`, `sketch`, `location_image`) – uses the field name as the purpose and derives a filename from the object ID and field name.
4. Copies each unique file (identified by its UID) to the destination folder once, using the original filename where available. Duplicate destination filenames are resolved by appending a numeric suffix (e.g. `photo.jpg` → `photo_1.jpg`).
5. If the same UID is referenced by more than one object, the file is copied only once but an index row is written for every referencing object.
6. If an index CSV already exists at the configured path, new rows are appended to it rather than overwriting it.
7. Writes a `log.txt` and an `attachment_index.csv`.

### Configuration

Edit the values at the top of the script before running:

| Variable | Description |
|---|---|
| `db_path` | Connection string for the InfoAsset Manager database (e.g. `localhost:40000/my_db`) |
| `network_type` | Type of network to process, e.g. `Collection Network`, `Distribution Network`, `Asset Network` |
| `network_id` | Numeric ID of the network as it appears in the database |
| `attachmentsRootDirectory` | Root folder of the SNumbat attachments store (default `C:\ProgramData\Innovyze\SNumbatData\Attachments`) |
| `videosRootDirectory` | Root folder of the SNumbat videos store (default `C:\ProgramData\Innovyze\SNumbatData\Videos`) |
| `destinationDirectory` | Folder where copied files will be saved (created automatically if it does not exist) |
| `renameFiles` | `true` – copy files using the original filename (with numeric suffix on conflict); `false` – keep the UID as the destination filename |
| `logFilename` | Path/name for the log file (default `log.txt`) |
| `indexFilename` | Path/name for the index CSV (default `attachment_index.csv` inside `destinationDirectory`) |

### Index CSV columns

| Column | Description |
|---|---|
| Network ID | The ID of the network as stored in the database |
| Network Name | The name of the network |
| Object Type | Human-readable table description (e.g. `CCTV Survey`, `Pipe`) |
| Object ID | The ID of the row object the file is attached to |
| File Name | The filename as saved in the destination folder |
| Purpose | The attachment purpose, or the field name for direct image reference fields |
| Original Filename | The filename the file had when it was originally attached |
| Description | The attachment description (blank for direct image reference fields) |

### Running the script

Run using InfoAsset Exchange from the command line:

```
"C:\Program Files\Autodesk\InfoAsset Manager 2026\iexchange.exe" "path\to\IE-CopyNetworkAttachments.rb" /ADSKASSET
```

Adjust the IExchange executable path and license flag to match your installation (see the [Ruby scripts README](../README.md) for details).

---

## Notes

- The process of copying files is the same as copy-paste using Windows File Explorer; performance depends on file count, file size, and the source/destination storage locations.
- Neither script will overwrite an existing file in the destination folder.
- We cannot be held liable for any issues caused through the use of these scripts.
