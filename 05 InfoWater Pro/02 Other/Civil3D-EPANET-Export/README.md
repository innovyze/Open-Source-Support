# Civil3D → EPANET Export (Pressure Pipes)

This add-in exports Civil 3D pressure pipe networks to an EPANET `.inp` file.

## How to use
1. Build the DLL with `build_release_clean.cmd`.
2. In Civil 3D, run `NETLOAD` and select `Civil3dEpanetExport.dll`.
3. Run the command `C3D_EXPORT_EPANET`.
4. Pick the output `.inp` file location.
5. Choose units: `LPS` (SI) or `GPM` (US).
6. Enter Hazen-Williams roughness (default 140).

Optional diagnostics:
- Run `C3D_EXPORT_EPANET_DIAG` to enable detailed property logging for troubleshooting.

## What gets exported
- **Junctions** for pipe endpoints, fittings, and valves.
- **Pipes** with length, diameter, and roughness.
- **Valves** (appurtenances with Valve style/type), inserted as EPANET links with upstream/downstream nodes.
- **Coordinates** for all exported junctions.

## Output notes
- **IDs are sanitized** (letters and numbers only). Original Civil 3D IDs are added as comments where available.
- **Valve rows include Description** as a comment (e.g., `; 200mm Gate Valve`).
- **Pipe lengths** use Civil 3D 3D length (center-to-center) when available.
- **Pipe curvature is not exported**. Pipes are written as straight lines between nodes, but with the correct 3D length.

## Assumptions and defaults
- **Demand is set to zero** for all junctions (MVP export).
- **Hazen-Williams headloss** is used.
- **Roughness** is a global default unless a pipe overrides it.
- **Valves** default to EPANET `TCV` if no explicit valve type is detected.
- **Units conversion**:
  - `LPS`: length/elevation in meters, diameter in millimeters.
  - `GPM`: length/elevation in feet, diameter in inches.

## Known limitations
- Pumps and controls are not exported.
- Pipe curvature/shape geometry is not exported (straight-line links only).

## Files
- `Civil3dEpanetExport.dll`: Add-in to load via `NETLOAD`.
- `*.inp`: EPANET model output.
- `*.inp.log`: Export log file (created next to the output).
