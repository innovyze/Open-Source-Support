# Batch Copy Model Group to Multiple Databases

Copies a model group (e.g., "Automation") from a source database to multiple target databases using `copy_into_root()`.

## Usage

1. Edit `database_list.csv` with target database paths
2. Edit the script constants for source database and group name
3. Run: `ICMExchange.exe batch_copy_model_group.rb`

## Process

For each target database:
- Deletes existing group if present
- Copies group from source using `db.copy_into_root()`
- Logs success/failure

## Files

- `batch_copy_model_group.rb` - Main script
- `database_list.csv` - List of target databases (edit this)
- `test_single.rb` - Test on one database first

## Configuration

Edit in script:
```ruby
SOURCE_DB = 'cloud://user@id/region'
GROUP_TYPE = 'MODG'       # 'MODG' (Model), 'MASG' (Master), 'AG' (Asset)
GROUP_NAME = 'Automation'
APPEND_DATE = true        # Appends date: Automation_20251212
DRY_RUN = false           # Preview changes without executing
```

CSV format:
```csv
database_path
cloud://user@id/db1
cloud://user@id/db2
```
