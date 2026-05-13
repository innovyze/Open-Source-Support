# Import Export of Data Tables

## Description

Scripts and files for handling the import and export of various data types within InfoWorks ICM and SWMM:

- **Data Assessment:** `Drainage Capacity Factor Assessment.csv` likely contains pre-assessment data or results for drainage capacity factors.
- **Binary Results Export:** `EX_script_ICM Binary Results Export.rb` and `ICM Binary Results Export.docx` provide scripts and documentation for exporting binary results from ICM.
- **GIS Export:** `hw_UI-GIS_export.rb` and `sw_UI-GIS_export.rb` are scripts for exporting data to GIS formats for HW (HydroWorks) and SW (SWMM) respectively.
- **Field Mapping Configuration:** `ICMFieldMapping.cfg` is a configuration file for mapping fields, possibly used in data export/import processes.
- **BefDSS Operations:** Scripts like `IE-befdss_export.rb`, `IE-befdss_import_ctv-BulkImport.rb`, `IE-befdss_import_ctv.rb`, and `IE-befdss_import_manhole_surveys.rb` handle operations related to the BefDSS (Bulk Export for Decision Support System) for various data types.
- **CSV Operations:** Various scripts (`IE-csv_changes.rb`, `UI-CSV_export-selection.rb`, `UI-CSV_export.rb`, `UIIE-CSV_export.rb`, `UI_script_Output CSV of calcs based on Subcatchment Data.rb`) manage CSV file operations, including exporting data, making changes, and outputting calculations.
- **Dashboard and Snapshot:** `IE-DashboardExport.rb` and scripts like `IE-Snapshot export_ex.rb`, `UI-Snapshot_export_ex.rb`, `UI-Snapshot-Bulk-Import-Filename.rb`, `UI-Snapshot-Bulk-Import.rb` are for exporting and importing dashboard data or snapshots, useful for quick data reviews or updates.
- **Node and Conduit Data Export:** `UI_script_ODEC Export Node and Conduit tables to CSV and MIF.rb` exports node and conduit data to CSV and MIF formats.
- **Choice List and Pipe Array:** `UI-ExportChoiceListValues.rb` and `UI-ExportPipeArrayCSV.rb` handle exporting choice list values and pipe array data to CSV.
- **External CSV Update:** `UI-UpdateFromExternalCSV.rb` updates data from an external CSV file.

## Usage

1. **Environment Setup:** Ensure Ruby is installed on your system.
2. **Execution:** Run the Ruby scripts from the command line or integrate them into your InfoWorks ICM or SWMM workflow.

For example, to export binary results:
```sh
ruby EX_script_ICM Binary Results Export.rb

Note
Always ensure you have the necessary permissions to run these scripts.
Backup your data before running scripts that might alter or process datasets.
The README.md file within this directory might contain specific instructions, notes, or prerequisites for running these import/export scripts.


This README now focuses exclusively on the `0005 - Import Export of Data Tables` folder, detailing its contents and usage.  