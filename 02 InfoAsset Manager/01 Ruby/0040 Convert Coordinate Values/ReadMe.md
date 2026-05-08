# Convert Coordinate Values

Scripts to convert geographic coordinate values stored on InfoAsset Manager network objects from WGS84 (decimal degrees) to UTM easting/northing under the NAD 83 datum (EPSG 26917, UTM Zone 17).

The conversion is calculated natively in Ruby using the standard Transverse Mercator projection formulae — no external libraries or dependencies are required.

## Prerequisites

- The `x` and `y` fields on the target objects must already hold WGS84 coordinates, where `x` is longitude and `y` is latitude in decimal degrees.
- Objects must be selected on the GeoPlan before running either script.
- Scripts must be run from the InfoAsset Manager UI (filename prefix `UI-`).

## WGS84 Validation

Before converting, each object's coordinates are validated against the legal range for WGS84 decimal degrees:

| Field | Valid range |
|---|---|
| `y` (latitude) | -90.0 to +90.0 |
| `x` (longitude) | -180.0 to +180.0 |

Objects whose coordinates fall outside these bounds are logged as `[INVALID]` and skipped without modification. This prevents double-conversion of objects that have already been projected to UTM (where easting values are typically 100,000–900,000 and northing values 0–10,000,000, both of which exceed the WGS84 longitude/latitude ranges).

## Scripts

### [UI-WGS84_NAD83.rb](./UI-WGS84_NAD83.rb)

Converts the `x` (longitude) and `y` (latitude) coordinate values of all **selected General Maintenance** (`cams_general_maintenance`) objects in the current network from WGS84 decimal degrees to UTM easting/northing (NAD 83, Zone 17).

The UTM zone is calculated automatically from the longitude of each object, and a false northing of 10,000,000 m is applied for objects in the southern hemisphere.

### [UI-WGS84_NAD83_PromptObjectType.rb](./UI-WGS84_NAD83_PromptObjectType.rb)

Extends the behaviour of `UI-WGS84_NAD83.rb` by prompting the user at runtime to choose which object type to convert. All table names present in the open network are discovered dynamically and presented in a dropdown list — no hardcoded object type is assumed.

Selecting Cancel in the prompt dialog exits the script without making any changes.

## Usage

1. Open the target network in InfoAsset Manager.
2. Select the objects whose coordinates you want to convert on the GeoPlan.
3. Run the relevant script via the InfoAsset Manager script runner.
   - To convert General Maintenance objects directly, run `UI-WGS84_NAD83.rb`.
   - To choose the object type at runtime, run `UI-WGS84_NAD83_PromptObjectType.rb` and select the desired type from the prompt dialog.
4. Review the script output log, which lists each object ID alongside its result.

## Output Log

Both scripts print a summary to the script output window on completion:

```
=== Coordinate Conversion: WGS84 -> UTM (NAD83) ===
Object type: cams_general_maintenance

Updated (2):
  [OK]      GM-001
  [OK]      GM-002

Skipped - nil coordinates (1):
  [SKIP]    GM-003

Skipped - coordinates not in WGS84 range (1):
  [INVALID] GM-004 (x=612345.0, y=4823456.0)

Complete. 2 updated, 2 skipped.
```

| Status | Meaning |
|---|---|
| `[OK]` | Object coordinates successfully converted and written. |
| `[SKIP]` | Object was skipped because one or both coordinate values were `nil`. |
| `[INVALID]` | Object was skipped because the coordinate values fall outside the valid WGS84 range — the current values are logged alongside the ID. |

## Conversion Reference

| Property | Value |
|---|---|
| Source CRS | WGS84 (decimal degrees) |
| Target CRS | NAD 83 / UTM Zone 17N (EPSG 26917) |
| Ellipsoid | GRS 80 (WGS84 constants used) |
| Scale factor | 0.9996 |
| False easting | 500,000 m |
| False northing | 10,000,000 m (southern hemisphere only) |
