# Copy Database to Cloud

Scripts for copying InfoWorks ICM databases to cloud storage. Each source database is copied in a separate ICM process to prevent transaction conflicts.

## Files

- **Copy_all_to_cloud.rb** - Single database copy script (can be run standalone or called by batch)
- **Batch_copy_all_to_cloud.rb** - Batch processor for multiple databases
- **Batch_Exchange.bat** - Runs batch copy script
- **batch.csv** - List of source database paths (one per line)

## Usage

### Batch Copy
1. Edit `Batch_copy_all_to_cloud.rb` - set `destination_db` 
2. Edit `batch.csv` - add source database paths (one per line)
3. Run `Batch_Exchange.bat`

## CSV Format

```csv
D:\TEMP\Database1.icmt
D:\TEMP\Database2.icmm
//localhost:40000/Database3
```

## Notes

- Cloud database must be created manually through ICM UI first
- Find cloud database path: Help > About InfoWorks > Additional Information > Database
- Each source database copies in isolated ICM process to prevent crashes
- Supports .icmt (transportable), .icmm (standalone), and workgroup databases
- Objects are copied to cloud database root level
- CSV encoding: UTF-8 or Windows-1252 (ANSI) both supported

## Restrictions

See Autodesk documentation for copying limitations:
- [Copying Data Between Databases](https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=GUID-7E1A5878-3242-4B0D-9699-74F4C6929782)
- [Copying Results and Ground Models](https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=GUID-73BE3CC4-90DA-4C86-9488-F4287E372D52)
