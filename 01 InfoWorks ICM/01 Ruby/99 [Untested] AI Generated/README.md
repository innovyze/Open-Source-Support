# 50 ICM Ruby Tools

> **⚠️ DISCLAIMER:** This document is AI-generated and can very likely be inaccurate. Please verify all information before use.

---

## 📋 Overview

**Generated:** 2024-10-24  
**Total Scripts:** 50  
**Status:** Scripts adapted to work with real databases *(not fully tested)*

This collection contains **50 Ruby scripts** for InfoWorks ICM hydraulic modelling. Scripts have been adapted from hardcoded test data to connect to real ICM databases. 

> **⚠️ Important:** These scripts have **not been fully tested** and may require adjustments for your specific use case.

---

## 📦 Categories

| Category | Count | Focus Area |
|----------|-------|------------|
| **Category 1** | 16 scripts | Simulation Diagnostics |
| **Category 2** | 18 scripts | Results Visualization |
| **Category 3** | 10 scripts | Batch Operations |
| **Category 4** | 6 scripts | Scenario Comparison |

---

## 📚 Script Catalog

### 🔍 Category 1: Simulation Diagnostics (16 scripts)

**Focus:** Log parsing, convergence analysis, stability detection

| # | Script | Purpose | Outputs |
|---|:------|:--------|:--------|
| **01** | `simulation_log_parser.rb` | Parse log files and categorize errors/warnings | HTML report |
| **02** | `convergence_timeline.rb` | Visualize convergence failures on timeline | HTML + mermaid Gantt |
| **03** | `mass_balance_tracker.rb` | Track mass balance errors by timestep | CSV + HTML chart |
| **04** | `instability_hotspot_finder.rb` | Identify oscillating nodes (instability hotspots) | HTML heatmap |
| **05** | `solver_iteration_analyzer.rb` | Analyze solver iteration counts | CSV + HTML stats |
| **06** | `timestep_reduction_logger.rb` | Log timestep reduction events | HTML timeline |
| **07** | `warning_frequency_counter.rb` | Count and categorize warning messages | HTML bar chart |
| **08** | `flow_reversal_detector.rb` | Detect flow reversals (link instability) | HTML + mermaid map |
| **09** | `hgl_discontinuity_finder.rb` | Find hydraulic grade line discontinuities | CSV + HTML |
| **10** | `simulation_profiler.rb` | Profile simulation performance vs network size | HTML scatterplot |
| **11** | `convergence_pattern_analyzer.rb` | Analyze convergence patterns (failed vs successful) | HTML comparison |
| **12** | `error_cascade_tracker.rb` | Trace error propagation through network | HTML + mermaid flow |
| **13** | `instability_predictor.rb` | Pre-run numerical instability risk assessment | HTML scorecard |
| **14** | `log_file_comparator.rb` | Compare logs from multiple runs | HTML diff viewer |
| **15** | `solver_tuning_advisor.rb` | Suggest solver parameter adjustments | HTML recommendations |
| **16** | `realtime_sim_monitor_ui.rb` | Real-time simulation monitor with metrics *(UI script)* | Console output |

---

### 📊 Category 2: Results Visualization (18 scripts)

**Focus:** Statistical reporting with charts and dashboards

| # | Script | Purpose | Outputs |
|---|:------|:--------|:--------|
| **01** | `exceedance_frequency_plotter.rb` | Plot exceedance frequency curves | CSV + HTML chart |
| **02** | `performance_dashboard.rb` | Multi-metric performance dashboard with gauges | HTML dashboard |
| **03** | `flow_capacity_comparison.rb` | Compare peak flows vs pipe capacity | CSV + HTML table |
| **04** | `surcharge_duration_heatmap.rb` | Surcharge duration heatmap by catchment | HTML heatmap |
| **05** | `cso_spill_aggregator.rb` | Aggregate CSO spill volumes | CSV + HTML bar chart |
| **06** | `lid_performance_reporter.rb` | LID performance metrics (before/after) | HTML comparison |
| **07** | `asset_utilization_heatmap.rb` | Asset utilization heatmap (% capacity) | HTML heatmap |
| **08** | `velocity_distribution.rb` | Velocity distribution histogram | HTML histogram |
| **09** | `network_resilience_scorecard.rb` | Network resilience composite metrics | HTML scorecard |
| **10** | `ensemble_statistics.rb` | Multi-run ensemble statistics (box plots) | CSV + HTML table |
| **11** | `ddf_curves.rb` | Depth-duration-frequency curves | HTML chart |
| **12** | `rainfall_runoff_correlation.rb` | Rainfall-runoff correlation with R² | CSV + HTML scatter |
| **13** | `flood_timeline.rb` | Flood progression timeline animation | HTML + mermaid timeline |
| **14** | `spatial_flood_map.rb` | Spatial flood map (node depths) | HTML map |
| **15** | `flow_profile_plotter.rb` | Longitudinal flow profile section | HTML chart |
| **16** | `energy_loss_breakdown.rb` | Energy loss breakdown pie chart | HTML pie chart |
| **17** | `capacity_bottleneck_ranker.rb` | Network capacity bottleneck ranker (top 20) | CSV + HTML ranked list |
| **18** | `pump_efficiency_plotter.rb` | Pump efficiency curve vs operating point | HTML chart |

---

### 🔧 Category 3: Batch Operations (10 scripts)

**Focus:** Cross-network automation and data management

| # | Script | Purpose | Outputs |
|---|:------|:--------|:--------|
| **01** | `multi_network_parameter_sweeper.rb` | Batch sensitivity analysis across networks | CSV |
| **02** | `batch_property_exporter.rb` | Export network properties to CSV | CSV |
| **03** | `network_metadata_comparator.rb` | Compare network metadata across databases | HTML table |
| **04** | `bulk_roughness_updater.rb` | Bulk roughness coefficient updater with audit | CSV audit log |
| **05** | `duplicate_id_finder.rb` | Cross-database duplicate ID finder | HTML report |
| **06** | `batch_scenario_cloner.rb` | Batch scenario cloner with naming convention | Log file |
| **07** | `multi_network_validator.rb` | Run batch QA checks across networks | CSV |
| **08** | `asset_inventory_aggregator.rb` | Aggregate asset inventory (global register) | CSV |
| **09** | `batch_results_extractor.rb` | Pull same metrics from multiple simulations | CSV |
| **10** | `network_complexity_scorer.rb` | Calculate complexity metrics across portfolio | CSV + HTML scorecard |

---

### 🔀 Category 4: Scenario Comparison (6 scripts)

**Focus:** Visual diff, ranking, and decision support

| # | Script | Purpose | Outputs |
|---|:------|:--------|:--------|
| **01** | `scenario_diff_mapper.rb` | Map scenario differences with flow diagrams | HTML + mermaid |
| **02** | `multi_scenario_ranking.rb` | Multi-scenario performance ranking | HTML + radar chart |
| **03** | `parameter_diff_viewer.rb` | Side-by-side parameter comparison | HTML table |
| **04** | `economic_prioritizer.rb` | Economic scenario prioritizer (NPV/IRR/Payback) | CSV + HTML |
| **05** | `sensitivity_tornado.rb` | Sensitivity tornado chart (variable impact) | HTML chart |
| **06** | `whatif_matrix_generator.rb` | What-if scenario matrix (parameter combinations) | CSV + HTML matrix |

---

## 🚀 Usage

### Exchange Scripts - Basic Usage

Run via **ICMExchange.exe** with PowerShell:

```powershell
$iexPath = "C:\Program Files\Autodesk\InfoWorks ICM Ultimate 2026\ICMExchange.exe"
& $iexPath "path\to\script.rb" [arguments]
```

### Command-Line Arguments

Most scripts follow this pattern:

| Argument | Description | Required |
|----------|-------------|----------|
| **ARGV[0]** | Database path *(optional - use `""` for most recent database)* | No |
| **ARGV[1]** | Simulation name or network name | Yes (most scripts) |
| **ARGV[2+]** | Additional parameters *(varies by script)* | Depends |

> **💡 Tip:** If no arguments are provided, scripts will list available simulations/networks and show usage instructions.

### Examples

```powershell
# Use most recent database
& $iexPath "script.rb" "" "SimulationName"

# Use specific database (server)
& $iexPath "script.rb" "localhost:40000/MyGroup/MyDB" "SimulationName"

# Use local database file
& $iexPath "script.rb" "C:\Path\To\Database.icmm" "SimulationName"
```

### UI Scripts

Only **`16_realtime_sim_monitor_ui.rb`** requires UI context.

**To run:** Use `Network > Run Ruby Script` in ICM interface.

---

## 📂 Output Locations

All scripts generate outputs to the **`outputs/`** subdirectory:

| Output Type | Description |
|------------|-------------|
| **CSV files** | Raw data for external analysis |
| **HTML files** | Styled reports with embedded visualizations |
| **Mermaid diagrams** | Flowcharts, timelines, Gantt charts |

---

## ⚠️ Important Notes

### ✅ What's Included

- ✅ Scripts connect to real ICM databases via `WSApplication.open()`
- ✅ Command-line argument support for flexible database selection
- ✅ Error handling with helpful error messages
- ✅ Output standardization (CSV/HTML to `outputs/` folder)
- ✅ Generic design (works with any ICM database)

### ⚠️ Limitations & Considerations

- ⚠️ **Scripts have not been fully tested** - may require adjustments
- ⚠️ Some scripts assume specific result fields exist (e.g., `'flood_volume'`, `'flow'`)
- ⚠️ Some scripts include placeholder/estimation logic where direct API access is limited
- ⚠️ Requires **InfoWorks ICM Ultimate** license for Exchange scripts
- ⚠️ May require minor customization for specific database structures

---

## 📝 Metadata

| Field | Value |
|-------|-------|
| **Author** | AI-Generated |
| **Date** | 2024-10-24 |
| **Version** | 1.0 |
| **Ruby Version** | 2.4.0 compatible |

---

**Status:** ✅ Scripts adapted *(not fully tested)*
