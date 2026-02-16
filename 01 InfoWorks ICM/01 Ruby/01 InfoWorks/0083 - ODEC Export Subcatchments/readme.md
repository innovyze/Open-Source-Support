# ODEC Export: Batch Subcatchment Export to Shapefile

Exchange script to batch export subcatchments from multiple InfoWorks ICM networks to Shapefile via ODEC. Networks are specified in a CSV file with export flags.

## Files

- **IE-odec_export_subcatchments_from_csv.rb** - Main exchange script
- **Network_list.csv** - Network list with export flags
- **config.cfg** - ODEC field mappings

## Quick Start

1. Edit `DATABASE_PATH` in script (default: `'Cloud://'`)
2. Update `Network_list.csv` with your network IDs
3. Customize `config.cfg` field mappings as needed
4. Run via **Network → Run Ruby Script**

## CSV Format

Must have headers. Column structure:

| Column | Content | Description |
|--------|---------|-------------|
| 2 | Network Name | For logging |
| 3 | Network ID | Numeric ID |
| 4 | Export Flag | `1` = export, `0` = skip |

**Example:**
```csv
Column1,Network_Name,Network_ID,Export_Flag
1,Main Network,101,1
2,Test Network,102,0
```

## Configuration

### Database Connection
```ruby
DATABASE_PATH = 'Cloud://'                         # Cloud
DATABASE_PATH = '//localhost:40000/DatabaseName'   # Server
DATABASE_PATH = 'C:/Data/MyModel.icmm'             # Local
```

### Field Mappings (config.cfg)
```ini
[hw_subcatchment]
subcatchment_id=subcatchment_id
node_id=node_id
total_area=total_area
```

## Output

- **subcatchments_[NetworkID].shp** - Exported shapefile (with .shx, .dbf, .prj files)
- **export_errors_[NetworkID].txt** - Error logs (if needed)

## Customization

### Export Different Tables
```ruby
'hw_node'         # Nodes
'hw_conduit'      # Conduits
'sw_subcatchment' # SWMM subcatchments
```

### Multiple Tables per Network
```ruby
net.odec_export_ex(
  'SHP', config_file, options,
  'hw_subcatchment', "subcatchments_#{network_id}.shp",
  'hw_node', "nodes_#{network_id}.shp"
)
```

### Change Export Format
```ruby
'CSV'  # CSV file
'MIF'  # MapInfo
'GDB'  # Geodatabase
```

### Additional Options
```ruby
options['Units Behaviour'] = 'Native'    # or 'User'
options['Export Selection'] = true       # Selected objects only
options['WGS84'] = true                  # Convert to WGS84
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Network ID not found" | Verify ID exists in database |
| "Failed to open database" | Check connection string and permissions |
| "CSV file not found" | Ensure CSV is in same folder as script |
| Empty exports | Check config.cfg field mappings and error logs |

## Notes

- Script continues processing if one network fails
- All files must be in same folder as script
- InfoWorks networks only (use `hw_*` tables)
- For SWMM networks, change to `sw_*` tables
