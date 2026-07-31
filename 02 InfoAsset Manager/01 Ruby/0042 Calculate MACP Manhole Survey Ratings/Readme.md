# Calculate MACP Manhole Survey Ratings

## Script

[UI-MACPManholeSurvey-CalculateRatings.rb](./UI-MACPManholeSurvey-CalculateRatings.rb)

## Purpose

Calculates NASSCO MACP composite ratings for each manhole survey in `cams_manhole_survey` and writes the nine summary fields back to the survey object. Ratings are derived from two sources:

1. **Header-level component condition fields** on the survey object (Cover, Frame, Seal, Chimney, pipe connections) — scored per the NASSCO MACP Condition Grade Matrix (v7.0.3, Appendix C, pp. 32–34).
2. **Detail-blob defect observations** in the `details` sub-table, graded by code-based lookup tables. Continuous defect S##/F## pair support is included.

Both sources contribute occurrences to the same grade-count tallies before the ratings are calculated.

## Usage

1. Open the relevant Collection Network in InfoAsset Manager.
2. Optionally select one or more manhole surveys on the GeoPlan or in a selection list.
3. Run the script via **Network → Run Ruby Script…** and select `UI-MACPManholeSurvey-CalculateRatings.rb`.
4. When prompted, configure the following options:

| Option | Default | Description |
|--------|---------|-------------|
| Process SELECTION only? | Yes | Process only selected surveys, or all surveys in the network |
| Distance units are Imperial (feet)? | Yes | Affects continuous defect divisor and Frame Offset Distance thresholds |
| Index rating decimal places | 1 | Number of decimal places for index ratings stored and displayed (1–3) |
| Write equiv. point count to characterisation3? | No | Writes `x2`, `x3` etc. to `characterisation3` on continuous defect start rows |
| Full calculation output? | No | Show per-observation breakdown, detail table and grade tally; uncheck for results-only output |

6. A warning message will show if warnings for continious defects are found.
5. Review the Ruby console output for a per-survey summary, final counts and warnings.

## Traffic vs No-Traffic grades

Several component conditions have different structural grades depending on whether the manhole is in a vehicular-traffic location. The script reads `location_code` (MACP Field 25) to determine this:

| Category | Location codes |
|----------|----------------|
| Traffic (T) | A, B, C, D, G, H, M |
| No-Traffic (NT) | E, F, I, J, K, L, Y, Z |

## Header-level Component Scoring

The following fields on `cams_manhole_survey` are evaluated for each survey. Each checked Boolean or matched String value contributes **one occurrence** at the listed grade to the overall tally.

### Field 52 — Hole Number + Field 27 — Potential for Runoff

| Condition | O&M grade |
|-----------|-----------|
| `hole_number > 0` AND `potential_for_runoff` = S | 3 |
| `hole_number > 0` AND `potential_for_runoff` = P | 4 |
| `hole_number > 0` AND `potential_for_runoff` = I | 5 |

### Field 55 — Cover/Frame Fit (`cover_frame_fit`)

| Value | Structural | O&M |
|-------|-----------|-----|
| G (Good) | — | 1 |
| R (Rocking) / U (Unstable) | 4 NT / 5 T | 4 NT / 5 T |
| O (Open) | 5 | 5 |

### Field 56 — Cover Condition

| Field | Structural | O&M |
|-------|-----------|-----|
| `cover_condition_sound` | 1 | — |
| `cover_condition_cracked` | 3 NT / 4 T | — |
| `cover_condition_corroded` | 4 | — |
| `cover_condition_broken` | 5 | — |
| `cover_condition_missing` | 5 | — |
| `cover_condition_boltsmissing` | — | 2 |
| `cover_condition_restraint_defect` | 2 | 2 |
| `cover_condition_restraint_miss` | — | 3 |

### Field 58 — Cover Insert Condition

Only `insert_condition_corroded` scores Structural. All other conditions score O&M only.

| Field | Structural | O&M |
|-------|-----------|-----|
| `insert_condition_sound` | — | 1 |
| `insert_condition_poorlyfitting` | — | 3 |
| `insert_condition_cracked` | — | 3 |
| `insert_condition_corroded` | 3 | — |
| `insert_condition_insertfell` | — | 5 |
| `insert_condition_leaking` | — | 5 |

### Field 61 — Adjustment Ring Condition

`ring_condition_leaking` scores O&M only; all other conditions score Structural only.

| Field | Structural | O&M |
|-------|-----------|-----|
| `ring_condition_sound` | 1 | — |
| `ring_condition_corroded` | 3 | — |
| `ring_condition_cracked` | 3 | — |
| `ring_condition_poorinstall` | 3 | — |
| `ring_condition_broken` | 5 | — |
| `ring_condition_leaking` | — | 5 |

### Field 68 — Frame Condition (Structural only)

| Field | Structural |
|-------|-----------|
| `frame_condition_sound` | 1 |
| `frame_condition_corroded` | 1 |
| `frame_condition_cracked` | 4 NT / 5 T |
| `frame_condition_broken` | 5 |
| `frame_condition_missing` | 5 |

### Field 69 — Seal Condition

| Field | Structural | O&M |
|-------|-----------|-----|
| `seal_condition_sound` | 1 | 1 |
| `seal_condition_cracked` | 3 NT / 4 T | 3 |
| `seal_condition_loose` | 3 NT / 4 T | 3 |
| `seal_condition_offset` | 3 | 3 |
| `seal_condition_missing` | 3 | 3 |

### Field 70 — Frame Offset Distance (`frame_offset_distance`, Structural only)

| Distance | Structural |
|----------|-----------|
| ≤ 1 in / ≤ 25 mm | 1 |
| > 1–4 in / > 25–102 mm | 3 |
| > 4 in / > 102 mm | 5 |

The Imperial/Metric threshold is selected by the prompt option. The field is only scored when `frame_offset_distance` is not nil (including a recorded value of 0, which scores grade 1).

### Fields 71 & 76 — Frame Seal Inflow (`frame_seal_inflow`) & Chimney Inflow and Infiltration (`chimney_ini`)

Both fields use the same infiltration code → grade mapping and contribute to **O&M only** (Structural grade is blank per MACP grade matrix). Values are matched case-insensitively:

| Value | O&M |
|-------|-----|
| None / N | 1 |
| IS | 2 |
| IW | 3 |
| ID | 4 |
| IR | 5 |
| IG | 5 |

### Field 115 — Pipe Connections (`pipes_in`, `pipes_out`, O&M only)

Each row in the `pipes_in` and `pipes_out` sub-tables is evaluated. Structural grade is blank per the MACP grade matrix:

| `condition_code` | O&M |
|-----------------|-----|
| S / Sound | 1 |
| D / Defective | 3 |

## Detail-blob Scoring

After the header fields are scored, the script iterates the `details` sub-table. For each record the script determines the Structural and O&M grade using **code-based lookup tables** derived from the NASSCO MACP Condition Grade Matrix. Grades depend on the defect code and the `descriptive_location` field value:

| `descriptive_location` value | Meaning | Grade array index |
|------------------------------|---------|-------------------|
| `CME` | Chimney Exterior | Chimney |
| `CMI` | Chimney Interior | Chimney |
| `COE` | Cone Exterior | Cone and Wall |
| `COI` | Cone Interior | Cone and Wall |
| `WE` | Wall Exterior | Cone and Wall |
| `WI` | Wall Interior | Cone and Wall |
| `B` | Bench | Bench |
| `C` | Channel | Channel |

### Grade source priority

| Priority | Condition | Source |
|----------|-----------|--------|
| 1 | Code found in Structural lookup table | Structural grade from table; O&M = nil |
| 2 | Code found in O&M fixed lookup table | O&M grade from table; Structural = nil |
| 3 | Code found in O&M percentage table | O&M grade calculated from `percentage` field |
| 4 | Code not in any lookup table | Both fields cleared to nil; `not found` noted in log |

The console log shows the grade source for each detail row (`lookup`, `lookup(loc?)`, `lookup(pct)`, or `not found`).

**Suffix-stripping rule:** if a code is not found in any lookup table, the script strips trailing characters one at a time and retries until a match is found or the code is exhausted. This handles all location/size suffix variants — for example `IWB`, `IWC`, `IWJ`, `IWL` all resolve to `IW`. Codes that have their own direct table entries (e.g. `ISSR`, `ISGT`, `ISZ`) are matched on the first lookup and are never stripped. The console log shows `lookup(sfx->IW)` when suffix stripping applies.

### Structural detail grades

| Group | Codes | Chimney | Cone/Wall | Bench | Channel |
|-------|-------|---------|-----------|-------|---------|
| Crack (C) | CC CL CS | 2 | 2 | 2 | 2 |
| Crack (C) | CM | 3 | 3 | 3 | 3 |
| Fracture (F) | FC FL FS | 3 | 3 | 3 | 3 |
| Fracture (F) | FM | 4 | 4 | 4 | 4 |
| Broken (B) | B BSV BVV | 5 | 5 | 5 | 5 |
| Hole (H) | H | 2 | 2 | 2 | 4 or 5 * |
| Hole (H) | HSV HVV | 5 | 5 | 5 | 5 |
| Collapse (X) | X | 5 | 5 | 5 | 5 |
| Joint (J) | JOM JOL JSM JSL JAM JAL | 5 | 5 | 5 | 5 |
| Surface Damage | SRI | 1 | 1 | 1 | 1 |
| Surface Damage | SSS SSC SAV | 2 | 2 | 2 | 2 |
| Surface Damage | SAP | 3 | 3 | 3 | 3 |
| Surface Damage (Silent) | SAM | 4 | 4 | 4 | 4 |
| Surface Damage (Silent) | SRV SRP SRC SMW | 5 | 5 | 5 | 5 |
| Surface Damage (Metal) | SCP | 3 | 3 | 3 | 3 |
| Lining Features | LFD | 4 | 4 | 3 | 3 |
| Lining Features | LFOC LFUC LFW | 2 | 2 | 2 | 2 |
| Lining Features | LFDE LFB LFCS LFBK LFAS LFBU LFRS | 3 | 3 | 3 | 3 |
| Lining Features | LFDC | 3 | 2 | 3 | 3 |
| Lining Features | LFDL LFPH | 4 | 4 | 4 | 4 |
| Weld Failure (WF) | WFC WFL WFS | 2 | 2 | 2 | 2 |
| Weld Failure (WF) | WFM | 3 | 3 | 3 | 3 |
| Point Repair (RP) | RPLD RPPD | 4 | 4 | 4 | 4 |
| Point Repair (RP) | RPRD | 4 | 4 | N/A | N/A |
| Brickwork (Silent) | DB | 3 | 3 | 3 | 3 |
| Brickwork (Silent) | MB | 4 | 4 | 4 | 4 |
| Brickwork (Silent) | MMS | 2 | 2 | 2 | 2 |
| Brickwork (Silent) | MMM | 3 | 3 | 3 | 3 |
| Brickwork (Silent) | MML | 4 | 4 | 4 | 4 |

\* `H` at Channel: grade **4** if `clock_at` only (or `clock_at == clock_to`); grade **5** if `clock_at` and `clock_to` differ (2+ clock positions).

Codes `SZ`, `LFAC`, `LFZ`, `RPZD` are recorded as observations only (N/A grade).

### O&M detail grades — fixed codes

Root codes use the convention `R[type][location]` where type = F(Fine)/T(Tap)/M(Medium)/B(Blocking) and location = B(Both)/L(Lateral)/C(Connection)/J(Joint). Channel grades are more sensitive for all root types.

| Group | Codes | Chimney | Cone/Wall | Bench | Channel |
|-------|-------|---------|-----------|-------|---------|
| Roots – Fine (RF) | RFB | 1 | 1 | 1 | 2 |
| Roots – Fine (RF) | RFL RFC RFJ | 1 | 1 | 1 | 1 |
| Roots – Tap (RT) | RTB | 1 | 1 | 1 | 3 |
| Roots – Tap (RT) | RTL RTC RTJ | 1 | 1 | 1 | 2 |
| Roots – Medium (RM) | RMB | 1 | 1 | 1 | 4 |
| Roots – Medium (RM) | RML RMC RMJ | 1 | 1 | 1 | 3 |
| Roots – Blocking (RB) | RBB | 2 | 2 | 2 | 5 |
| Roots – Blocking (RB) | RBL RBC RBJ | 2 | 2 | 2 | 4 |
| Infiltration (I) | IS | 1 | 1 | 1 | 1 |
| Infiltration (I) | IW | 2 | 2 | 2 | 2 |
| Infiltration (I) | ID | 3 | 3 | 3 | 3 |
| Infiltration (I) | IR | 4 | 4 | 4 | 4 |
| Infiltration (I) | IG | 5 | 5 | 5 | 5 |
| Vermin (V) | VR | 2 | 2 | 2 | 2 |
| Vermin (V) | VC VZ | 1 | 1 | 1 | 1 |
| Construction Features / IS | ISSR ISSRH ISSRB ISSRL ISGT ISZ | 1 | 1 | 1 | 1 |

### O&M detail grades — percentage-based codes

These codes score based on the `percentage` field value.

**Deposit thresholds:**

| Code | Chimney / Cone/Wall | Bench | Channel |
|------|---------------------|-------|---------|
| DAE DAGS DAR | <30%→1; ≥30%→2 | <30%→1; ≥30%→2 | ≤10%→1; >10–≤20%→2; >20–≤30%→3; >30%→4 |
| DAZ | <30%→1; ≥30%→2 | <30%→1; ≥30%→2 | ≤10%→1; >10–≤20%→2; >20–≤30%→3; >30%→4 |
| DSC DSF DSGV DSZ | N/A | <30%→1; ≥30%→2 | ≤10%→1; >10–≤20%→2; >20–≤30%→3; >30%→4 |
| DNF DNGV DNZ | N/A | <30%→1; ≥30%→2 | ≤10%→1; >10–≤20%→2; >20–≤30%→3; >30%→4 |

**Obstacle thresholds:**

| Code | Chimney / Cone/Wall / Bench | Channel |
|------|-----------------------------|---------|
| OBB | flat 1 | flat 2 |
| OBM OBI OBJ OBC OBP OBS OBN OBR OBZ | <30%→1; ≥30%→2 | ≤10%→2; >10–≤20%→3; >20–≤30%→4; >30%→5 |

Codes not in any lookup table have both `structural_score` and `service_score` cleared to nil.

## Continuous Defects

Continuous defect `S##`/`F##` marker pairs are converted to equivalent point defects using the NASSCO MACP divisor: **1 ft** (Imperial) or **0.3 m** (Metric). The equivalent count is calculated as `(length / divisor).round`, minimum 1.

If the option **Write equiv. point count to characterisation3?** is enabled (default on), the calculated count is written to the `characterisation3` field of the start row in the format `x2`, `x3`, etc.

### Duplicate S/F codes

If the same pairing id appears more than once (e.g. two rows with `cd = S09`), the script uses the **first start** and **last finish** for each id. All other start/finish rows for that id are excluded from scoring (their `structural_score` and `service_score` are cleared to nil) and a per-survey warning is printed to the console regardless of the verbose output setting. A summary of affected surveys is printed at the end of the run, and a message box is shown to alert the user.

## Calculated Metrics

| Metric | Description |
|--------|-------------|
| **Structural Rating** | Sum of `grade × occurrences` for all structural observations |
| **O&M Rating** | Sum of `grade × occurrences` for all O&M observations |
| **Overall Rating** | Structural Rating + O&M Rating |
| **Structural Quick Rating** | NASSCO 4-char code, e.g. `5132`, `4200`, `0000` |
| **O&M Quick Rating** | Same format, O&M observations only |
| **Overall Quick Rating** | Same format, all observations combined |
| **Structural Index Rating** | Structural Rating ÷ total structural occurrences |
| **O&M Index Rating** | O&M Rating ÷ total O&M occurrences |
| **Overall Index Rating** | Overall Rating ÷ total occurrences |

Index ratings are rounded to the number of decimal places chosen in the prompt (1–3, default 2).

### Quick Rating format

Per NASSCO MACP v7.0.3: `[highest grade][count][second highest grade][count]`

| Count | Character |
|-------|-----------|
| 1–9 | `'1'`–`'9'` |
| 10–14 | `'A'` |
| 15–19 | `'B'` |
| 20–24 | `'C'` |
| … | … (bands of 5 per letter) |

Single-grade only → `'4200'`; no defects → `'0000'`.

## Output Fields

All nine MACP rating fields are confirmed present on `cams_manhole_survey`. The script checks availability dynamically; absent fields are reported in the Ruby console and skipped.

| Field name | Type | Content |
|------------|------|---------|
| `macp_struct_rating` | Long | Structural Rating |
| `macp_oandm_rating` | Long | O&M Rating |
| `macp_overall_rating` | Long | Overall Rating |
| `macp_struct_quick_rating` | String | Structural Quick Rating |
| `macp_oandm_quick_rating` | String | O&M Quick Rating |
| `macp_overall_quick_rating` | String | Overall Quick Rating |
| `macp_struct_index_rating` | Double | Structural Index Rating |
| `macp_oandm_index_rating` | Double | O&M Index Rating |
| `macp_overall_index_rating` | Double | Overall Index Rating |

For each detail row, the calculated `structural_score` and `service_score` are also written back to the `details` blob, overwriting any previously stored values. Rows with no matching lookup (or duplicate cd rows) have these fields cleared to nil.

## Notes

- The script wraps all writes in a single transaction for performance.
- Surveys with no scored observations from either source are skipped and reported in the console.
- For MACP import options see [0009 Import-Export MACP-PACP Survey Data](../0009%20Import-Export%20MACP-PACP%20Survey%20Data/ReadMe.md).
- Requires InfoAsset Manager 2023.0 or later (MACP support).
- Reference: NASSCO PACP/MACP Condition Grading System, Version 7.0.3, January 2018, Appendix C.
