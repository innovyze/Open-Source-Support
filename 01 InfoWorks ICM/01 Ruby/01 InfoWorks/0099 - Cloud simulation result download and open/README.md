# Cloud simulation result download and open (ICM Exchange)

Two-phase ICMExchange workflow to download cloud simulation results and open them for QA. Use a separate Exchange process for each phase.

**IMPORTANT:** Run both scripts from **ICMExchange**, not the InfoWorks ICM UI.

## Scripts

| Script | Phase | Purpose |
|--------|-------|---------|
| [cloud_download.rb](cloud_download.rb) | 1 | Queue cloud result download via `launch_sims_ex` |
| [cloud_open.rb](cloud_open.rb) | 2 | Open local results and print QA fields |
| [exchange.bat](exchange.bat) | — | Run both phases in sequence (two Exchange processes) |

## Configuration

Edit constants at the top of each Ruby script, or pass values on the command line.

| Constant / argument | Purpose |
|---------------------|---------|
| `CLOUD_DB` / `ARGV[1]` | Cloud database path (required) |
| `SIM_ID` / `ARGV[2]` | Simulation object ID (required) |
| `DOWNLOAD_SELECTION` | `NO_RESULTS`, `SUMMARY_RESULTS`, or `ALL_RESULTS` (phase 1 only; default `ALL_RESULTS`) |

### Cloud database path

Connect to the cloud database in ICM, then copy the path from:

**Help > About InfoWorks > Additional Information > Database**

Format: `cloud://DatabaseName@orgId/region`

Example:

```ruby
CLOUD_DB = 'cloud://My Database ICM@abc123def456/emea'
SIM_ID = 19108
```

> ICMExchange automatically injects `ARGV[0]="ADSK"` before your arguments, so your first argument is `ARGV[1]`.

## Usage

Phase 1:

```text
ICMExchange.exe cloud_download.rb "cloud://My Database@orgId/region" 19108
```

Phase 2 (new Exchange process):

```text
ICMExchange.exe cloud_open.rb "cloud://My Database@orgId/region" 19108
```

Or run [exchange.bat](exchange.bat). Edit `ExchangePath` in the batch file if needed; set `CLOUD_DB` and `SIM_ID` in the Ruby scripts or as variables in the batch file.

## Prerequisites

- InfoWorks Agent running locally (phase 1).
- Cloud simulation already complete.

## Limitations

- Cloud databases only (`DownloadSelection` applies to cloud).
- Phase 2 opens results only; no export or post-processing included.
