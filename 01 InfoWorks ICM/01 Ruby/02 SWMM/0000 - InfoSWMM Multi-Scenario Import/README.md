# InfoSWMM Multi-Scenario Import for InfoWorks ICM

**InfoSWMM multi-scenario import with partially automated SWMM run configuration**

**⚠️ IMPORTANT: An InfoWorks ICM Ultimate license is required to run this script.**

---

## Quick Start

1. **Download both scripts** (`InfoSWMM_Import_UI.rb` and `InfoSWMM_Import_Exchange.rb`) and save them to the same folder
2. **Open InfoWorks ICM**
3. **Create a new model group**
4. **Create a new SWMM network**
5. **Open the SWMM network**
6. **Network → Run Ruby Script**
7. **Select:** `InfoSWMM_Import_UI.rb`
8. **Follow the dialogs:**
   - Choose your `.mxd` file
   - Select scenarios to import
9. **Manually verify and finalize run configuration** (see Results & Setup below)

---

## What It Does

### Automated ✅
- Imports all scenarios at once
- Deduplicates Rainfall & Inflow Events by actual content
- Creates merged network with all scenarios
- Creates SWMM runs with network, scenario, and rainfall pre-configured
- Cleans up empty label lists

### Requires Manual Setup ⚠️
- Run parameters including timestep controls
- Climatology
- Time Patterns
- Inflow Events (use Description field to find correct one)

---

## Results & Setup

**Individual Model Groups** - One per scenario with original imported data. Keep these for reference!

**Merged Model Group** - Contains:
- Network with all scenarios combined
- Deduplicated Rainfall Events and Inflows (Description shows which scenarios use each)
- SWMM runs (partially configured)

**Post-Import:** For each run in the merged group, manually configure:
1. Run parameters including timestep controls (copy from original run)
2. Climatology (drag from individual model group)
3. Time Patterns (drag from individual model group)
4. Inflow Events (check Description field to find correct one)

**Tip:** Open original and new runs side-by-side to copy settings.

---

## Files

- `InfoSWMM_Import_UI.rb` - **Run this** (user interface)
- `InfoSWMM_Import_Exchange.rb` - Core logic (launched automatically)
- `InfoSWMM_DWF_Supplement_UI.rb` - Optional follow-up **Run this** (user interface) — fixes Dry Weather Flow data that the built-in InfoSWMM import doesn't correctly populate
- `InfoSWMM_DWF_Supplement_Exchange.rb` - DWF supplement core logic (launched automatically)
- `README.md` - This guide

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No scenarios detected | Check that `.ISDB/SCENARIO.DBF` exists next to .mxd file |
| "Model group already exists" | Delete or rename existing groups before running |
| "Connected to Wrong Database" error | Script automatically detects and reports database mismatches - follow on-screen instructions |
| Import fails for one scenario | Script continues with others - check log file |
| Run missing configuration | Expected - see Post-Import Setup (API limitations) |
| Where are logs? | `[YourModel]/ICM Import Log Files/Import_Runs_*.log` |
| Temporary screen resize during import | Normal behavior - ICMExchange process temporarily takes focus |

---

## API Limitations

These features **cannot** be automated via InfoWorks ICM Ruby API:

1. Timestep Controls - Cannot be reliably copied
2. Climatology Assignment - No API parameter exists
3. Time Pattern Assignment - No API parameter exists
4. Inflow Linking - API rejects valid object IDs
5. Time Pattern/Climatology Export - Cannot be exported for deduplication

---

## ICM Version Compatibility

**Confirmed working on:** InfoWorks ICM 2027.1.0 (embedded Ruby 3.4.6) and InfoWorks ICM 2026.3 and earlier (embedded Ruby 2.4).

All four scripts in this folder use a single, shared codebase across ICM versions — there is no separate branch or version to maintain for older installs. This is intentional: every workaround below relies only on long-standing, version-independent Ruby features (plain `while` loops, `String#getbyte`/`#[offset,len]` for binary parsing, `Process.clock_gettime` for timestamps, backtick subprocess calls), none of which were introduced by or depend on Ruby 3.x. They should run unchanged on any ICM version back to at least 2024.2 (the oldest version this script's `ICMExchange.exe` path list targets). If you have access to an older ICM install, a quick smoke test is still recommended before relying on it in production, but no code changes are expected to be needed.

### Known ICM 2027.0+ embedded Ruby bugs (worked around in these scripts)

ICM 2027.0 upgraded its embedded Ruby engine from 2.4 to 3.4.6. On the `x64-mswin64` Ruby 3.4.6 build shipped with ICM 2027.1.0, several individual core methods were found to be non-functional — confirmed by direct reproduction, not a Ruby 3.4 language change (none of the methods below were altered or removed in real Ruby 3.4):

| Method / Class | Symptom |
|---|---|
| `Symbol#to_s` / `Symbol#name` | Returns garbled `#<Symbol:0xADDRESS>` text or raises `NoMethodError` — this is also why unrelated `NoMethodError` messages appeared corrupted, since Ruby's own error formatter uses `Symbol#to_s` internally |
| `String#unpack` (all formats tested) | Raises `NoMethodError` |
| Bare `Kernel#loop` (`loop do...end`) | Raises `NoMethodError` |
| `Integer#times` | Raises `NoMethodError` |
| Entire `Time` class (`.now`, `#to_s`, `#strftime`, `#year`) | Raises `NoMethodError` / `TypeError` |
| `Open3.capture2` | Raises `NoMethodError` **inside Autodesk's own shipped `open3.rb`** |

Confirmed **not** affected (safe, used as-is): `String#strip`/`#getbyte`/`#[offset,len]`/`#upcase`/`#downcase`/`#casecmp`, `Symbol#inspect`, `Array#each`/`#find`/`#reject`/`#map`/`#any?`/`#max_by`, `JSON.parse`/`#pretty_generate`, `Digest::SHA256.hexdigest`.

These scripts avoid every broken method above entirely: manual byte-level DBF parsing instead of `unpack`, plain `while` loops instead of `loop`/`times`, epoch-based timestamp math via `Process.clock_gettime` instead of `Time`, and backticks instead of `Open3`. If a future ICM version surfaces a new broken method, the fatal-error dialog includes the exact file/line ("Location:" section) to make it fast to diagnose — please report it so the script can be updated.

### Note: these are compatibility workarounds, not upgrades

The original code (using `unpack`, `loop`, `times`, `Time`, `Open3`) was standard, idiomatic Ruby — it was not inferior code. These workarounds trade idiom quality for compatibility with a broken runtime. If Autodesk ships a fixed embedded Ruby build in a future ICM version, the `Time`-based and `Open3`-based workarounds in particular are worth reverting back to the original approach (see the developer findings table for why). The `unpack`/`loop`/`times` workarounds are lower-priority to revert since they're functionally equivalent, just more verbose.

---

*Note: This documentation was AI-generated and reviewed by the script author.*
