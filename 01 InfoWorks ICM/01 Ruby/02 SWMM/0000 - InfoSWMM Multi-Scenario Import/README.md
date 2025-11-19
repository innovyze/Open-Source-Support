# InfoSWMM Multi-Scenario Import for InfoWorks ICM

**InfoSWMM multi-scenario import with partially automated SWMM run configuration**

---

## Quick Start

1. **Open InfoWorks ICM**
2. **Create a new model group**
3. **Create a new SWMM network**
4. **Open the SWMM network**
5. **Network → Run Ruby Script**
6. **Select:** `InfoSWMM_Import_UI.rb`
7. **Follow the dialogs:**
   - Choose your `.mxd` file
   - Select scenarios to import
   - Configure options
8. **Wait for completion**
9. **Manually configure** (see Results & Setup below)

---

## What It Does

### Automated ✅
- Imports all scenarios at once
- Deduplicates Rainfall & Inflow Events by actual content
- Creates merged network with all scenarios
- Creates SWMM runs with network, scenario, and rainfall pre-configured
- Cleans up empty label lists

### Requires Manual Setup ⚠️
- Timestep controls
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
1. Timestep controls (copy from original run)
2. Climatology (drag from individual model group)
3. Time Patterns (drag from individual model group)
4. Inflow Events (check Description field to find correct one)

**Tip:** Open original and new runs side-by-side to copy settings.

---

## Files

- `InfoSWMM_Import_UI.rb` - **Run this** (user interface)
- `InfoSWMM_Import_Exchange.rb` - Core logic (launched automatically)
- `README.md` - This guide

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No scenarios detected | Check that `.ISDB/SCENARIO.DBF` exists next to .mxd file |
| "Model group already exists" | Delete or rename existing groups before running |
| Import fails for one scenario | Script continues with others - check log file |
| Run missing configuration | Expected - see Post-Import Setup (API limitations) |
| Where are logs? | `[YourModel]/ICM Import Log Files/Import_Runs_*.log` |

---

## API Limitations

These features **cannot** be automated via InfoWorks ICM Ruby API:

1. Timestep Controls - Cannot be reliably copied
2. Climatology Assignment - No API parameter exists
3. Time Pattern Assignment - No API parameter exists
4. Inflow Linking - API rejects valid object IDs
5. Time Pattern/Climatology Export - Cannot be exported for deduplication

---

*Note: This documentation was AI-generated and reviewed by the script author.*
