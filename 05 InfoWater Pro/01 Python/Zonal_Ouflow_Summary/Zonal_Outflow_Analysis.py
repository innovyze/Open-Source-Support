"""
Zonal Outflow Analysis Script
==============================
Analyzes junction-level outflow components for a selected pressure zone:
- Total Zone Outflow (sum of all junction demands)
- Actual Demand
- Adjacent Pipe Leakage (if enabled in simulation)
- Unsatisfied Demand (if enabled in simulation)

Includes summary metrics:
- Total volumes (integrated over time)
- Junction with highest Leakage
- Junction with highest Unsatisfied Demand

Run from: ArcGIS Pro Python window or notebook
"""

# =============================================================================
# USER CONFIGURATION - Modify this field name if your zone field differs
# =============================================================================
ZONE_FIELD_NAME = "ZONEID"  # Field in JUNCTION.DBF that contains zone assignment

import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2Tk
from matplotlib.colors import to_hex
from infowater.output.manager import Manager as OutMan
import arcpy
from pathlib import Path
import os
import tkinter as tk
from tkinter import ttk
import numpy as np

# =============================================================================
# SECTION 1: Auto-detect project and load paths
# =============================================================================
aprx = arcpy.mp.ArcGISProject("CURRENT")
project_path = Path(aprx.filePath).parent
project_name = Path(aprx.filePath).stem

# Build paths
iwdb_path = project_path / f"{project_name}.IWDB"
pzm_path = iwdb_path / "Module" / "PZM"
out_folder = project_path / f"{project_name}.OUT" / "SCENARIO"

print(f"Project: {project_name}")
print(f"IWDB Path: {iwdb_path}")
print(f"PZM Path: {pzm_path}")

# Check if PZM data exists
if not pzm_path.exists():
    raise FileNotFoundError(f"Pressure Zone Manager data not found at: {pzm_path}")

# Get available scenarios
if out_folder.exists():
    scenarios = [d for d in os.listdir(out_folder) 
                 if os.path.isdir(out_folder / d) and (out_folder / d / "HYDQUA.OUT").exists()]
    print(f"Available scenarios with results: {scenarios}")
else:
    scenarios = []
    print(f"Warning: Output folder not found at {out_folder}")

if not scenarios:
    raise FileNotFoundError("No scenarios with HYDQUA.OUT results found!")

# =============================================================================
# SECTION 2: Read Pressure Zone DBF data
# =============================================================================
def read_dbf_to_list(dbf_path, fields=None):
    """Read a DBF file using arcpy.da.SearchCursor and return list of dicts."""
    dbf_str = str(dbf_path)
    if not os.path.exists(dbf_str):
        return []
    
    if fields is None:
        fields = [f.name for f in arcpy.ListFields(dbf_str) if f.type != 'OID']
    
    rows = []
    with arcpy.da.SearchCursor(dbf_str, fields) as cursor:
        for row in cursor:
            rows.append(dict(zip(fields, row)))
    return rows

def read_pzm_zones():
    """Read pressure zone definitions from PZMZONE.DBF"""
    zones = []
    dbf_path = pzm_path / 'PZMZONE.DBF'
    
    for rec in read_dbf_to_list(dbf_path, ['ID', 'DESCRIPT', 'COUNT_NODE', 'COUNT_LINK']):
        zones.append({
            'id': rec.get('ID', ''),
            'description': rec.get('DESCRIPT', '') or '',
            'node_count': rec.get('COUNT_NODE', 0) or 0,
            'link_count': rec.get('COUNT_LINK', 0) or 0
        })
    return zones

def read_junction_zone_assignments():
    """Read junction zone assignments from JUNCTION.DBF.
    
    Returns dict mapping zone_id -> list of junction IDs
    """
    junction_dbf = iwdb_path / 'JUNCTION.DBF'
    zone_junctions = {}
    
    if not junction_dbf.exists():
        print(f"Warning: JUNCTION.DBF not found at {junction_dbf}")
        return zone_junctions
    
    for rec in read_dbf_to_list(junction_dbf, ['ID', ZONE_FIELD_NAME]):
        jct_id = rec.get('ID', '')
        zone_id = rec.get(ZONE_FIELD_NAME, '')
        if jct_id and zone_id:
            if zone_id not in zone_junctions:
                zone_junctions[zone_id] = []
            zone_junctions[zone_id].append(jct_id)
    
    return zone_junctions

# Read junction zone assignments
print(f"Reading junction zone assignments from JUNCTION.DBF (field: {ZONE_FIELD_NAME})...")
junction_zones = read_junction_zone_assignments()
print(f"Found {len(junction_zones)} zones with junctions")

# Read zones
pzm_zones = read_pzm_zones()
print(f"Found {len(pzm_zones)} pressure zones")

# Add junction counts to zones
for zone in pzm_zones:
    zone['junction_count'] = len(junction_zones.get(zone['id'], []))

print("Loaded junction counts for all zones")

# =============================================================================
# SECTION 3: Selection Dialog
# =============================================================================
selected_zone = None
selected_scenario = None
output_options = {
    'flow_unit': 'GPM',
    'show_leakage': True,
    'show_unsatisfied': True
}

def open_selection_dialog():
    global selected_zone, selected_scenario, output_options
    
    root = tk.Tk()
    root.title("Zonal Outflow Analysis")
    root.geometry("650x550")
    root.lift()
    root.attributes('-topmost', True)
    root.after(100, lambda: root.attributes('-topmost', False))
    root.focus_force()
    
    # === Zone Selection ===
    zone_frame = ttk.LabelFrame(root, text="Select Pressure Zone")
    zone_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
    
    ttk.Label(zone_frame, text="Click to select a pressure zone to analyze:", 
              font=('Segoe UI', 9)).pack(anchor='w', padx=5, pady=2)
    
    columns = ('zone', 'junctions', 'description')
    zone_tree = ttk.Treeview(zone_frame, columns=columns, show='headings', height=8, selectmode='browse')
    
    zone_tree.heading('zone', text='Zone ID')
    zone_tree.heading('junctions', text='Junctions')
    zone_tree.heading('description', text='Description')
    
    zone_tree.column('zone', width=100, anchor='w')
    zone_tree.column('junctions', width=80, anchor='center')
    zone_tree.column('description', width=300, anchor='w')
    
    for z in pzm_zones:
        zone_tree.insert('', tk.END, values=(
            z['id'],
            z.get('junction_count', 0),
            z['description']
        ))
    
    zone_scroll = ttk.Scrollbar(zone_frame, orient="vertical", command=zone_tree.yview)
    zone_tree.configure(yscrollcommand=zone_scroll.set)
    zone_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5, pady=5)
    zone_scroll.pack(side=tk.RIGHT, fill=tk.Y, pady=5)
    
    if pzm_zones:
        first_item = zone_tree.get_children()[0]
        zone_tree.selection_set(first_item)
    
    # === Scenario Selection ===
    scenario_frame = ttk.LabelFrame(root, text="Select Scenario")
    scenario_frame.pack(fill=tk.X, padx=10, pady=5)
    
    scenario_var = tk.StringVar(value=scenarios[0] if scenarios else "")
    scenario_combo = ttk.Combobox(scenario_frame, textvariable=scenario_var, values=scenarios, state='readonly')
    scenario_combo.pack(fill=tk.X, padx=5, pady=5)
    
    # === Output Options ===
    options_frame = ttk.LabelFrame(root, text="Output Options")
    options_frame.pack(fill=tk.X, padx=10, pady=5)
    
    # Flow units
    unit_row = ttk.Frame(options_frame)
    unit_row.pack(fill=tk.X, padx=5, pady=3)
    ttk.Label(unit_row, text="Flow Units:").pack(side=tk.LEFT, padx=5)
    flow_unit_var = tk.StringVar(value="GPM")
    for unit in ["CFS", "GPM", "MGD", "GPD"]:
        ttk.Radiobutton(unit_row, text=unit, variable=flow_unit_var, value=unit).pack(side=tk.LEFT, padx=3)
    
    # === Optional Data Fields ===
    fields_frame = ttk.LabelFrame(root, text="Optional Analysis Fields (requires simulation options enabled)")
    fields_frame.pack(fill=tk.X, padx=10, pady=5)
    
    show_leakage_var = tk.BooleanVar(value=True)
    show_unsatisfied_var = tk.BooleanVar(value=True)
    
    ttk.Checkbutton(fields_frame, text="Adjacent Pipe Leakage (requires Emitter/Leakage enabled)", 
                    variable=show_leakage_var).pack(anchor='w', padx=10, pady=3)
    ttk.Checkbutton(fields_frame, text="Unsatisfied Demand (requires Pressure-Dependent Demand enabled)", 
                    variable=show_unsatisfied_var).pack(anchor='w', padx=10, pady=3)
    
    # Info label
    info_label = ttk.Label(fields_frame, 
                           text="Note: These fields are only available if the corresponding simulation options were enabled.",
                           font=('Segoe UI', 8, 'italic'), foreground='gray')
    info_label.pack(anchor='w', padx=10, pady=5)
    
    def on_analyze():
        global selected_zone, selected_scenario, output_options
        
        sel_items = zone_tree.selection()
        if not sel_items:
            tk.messagebox.showwarning("Selection Required", "Please select a pressure zone.")
            return
        
        sel_idx = zone_tree.index(sel_items[0])
        selected_zone = pzm_zones[sel_idx]['id']
        selected_scenario = scenario_var.get()
        output_options = {
            'flow_unit': flow_unit_var.get(),
            'show_leakage': show_leakage_var.get(),
            'show_unsatisfied': show_unsatisfied_var.get()
        }
        root.destroy()
    
    btn_frame = ttk.Frame(root)
    btn_frame.pack(fill=tk.X, pady=10)
    
    ttk.Button(btn_frame, text="Analyze", command=on_analyze).pack(side=tk.LEFT, padx=20)
    ttk.Button(btn_frame, text="Cancel", command=root.destroy).pack(side=tk.RIGHT, padx=20)
    
    root.mainloop()
    return selected_zone, selected_scenario, output_options

selected_zone, selected_scenario, output_options = open_selection_dialog()

if not selected_zone or not selected_scenario:
    print("Analysis cancelled.")
    raise SystemExit("No zone or scenario selected.")

print(f"\nSelected Zone: {selected_zone}")
print(f"Selected Scenario: {selected_scenario}")
print(f"Options: {output_options}")

# =============================================================================
# SECTION 4: Load simulation results and get available fields
# =============================================================================
output_path = str(out_folder / selected_scenario / "HYDQUA.OUT")
print(f"Loading results from: {output_path}")
outman = OutMan(output_path)
times = outman.get_time_list()

# Get available Junction fields from metadata
metadata = outman.get_metadata()
junction_fields = list(metadata.fields.get("Junction", {}).keys()) if hasattr(metadata, 'fields') else []
print(f"Available Junction fields: {junction_fields}")

# Check for expected fields and warn if missing
# Note: Unsatisfied Demand will be CALCULATED from Required - Actual (no time series available)
expected_fields = ["Outflow", "Actual Demand", "Required Demand", "Adjacent Pipe Leakage"]
for field in expected_fields:
    if field in junction_fields:
        print(f"  ✓ '{field}' available")
    else:
        print(f"  ✗ '{field}' NOT found in output")
print(f"  ℹ 'Unsatisfied Demand' will be calculated as (Required - Actual)")

# Get junctions in the selected zone
zone_junction_ids = junction_zones.get(selected_zone, [])
print(f"\nZone {selected_zone} has {len(zone_junction_ids)} junctions")

if not zone_junction_ids:
    print(f"Error: No junctions found in zone {selected_zone}")
    raise SystemExit("No junctions in selected zone.")

# Flow unit conversion
flow_conversions = {
    'CFS': 1.0,
    'GPM': 448.831,
    'MGD': 0.6463168,
    'GPD': 646316.8
}
flow_factor = flow_conversions.get(output_options['flow_unit'], 1.0)
flow_unit = output_options['flow_unit']

# Volume unit labels (flow × time integration)
# CFS × hrs = ft³/s × hrs × 3600 s/hr = ft³
# GPM × hrs = gal/min × hrs × 60 min/hr = gallons
# MGD × hrs = MG/day × hrs / 24 hr/day = MG
# GPD × hrs = gal/day × hrs / 24 hr/day = gallons
volume_unit_labels = {
    'CFS': 'ft³',
    'GPM': 'gallons',
    'MGD': 'MG',
    'GPD': 'gallons'
}
volume_unit = volume_unit_labels.get(flow_unit, f'{flow_unit}-hrs')

# Volume conversion factors (to convert from flow-unit × hours to actual volume)
volume_conversions = {
    'CFS': 3600.0,      # CFS × hrs × 3600 s/hr = ft³
    'GPM': 60.0,        # GPM × hrs × 60 min/hr = gallons
    'MGD': 1.0 / 24.0,  # MGD × hrs / 24 hr/day = MG
    'GPD': 1.0 / 24.0   # GPD × hrs / 24 hr/day = gallons
}
volume_factor = volume_conversions.get(flow_unit, 1.0)

# =============================================================================
# SECTION 5: Collect junction outflow data (with progress bar)
# =============================================================================
print("\nCollecting junction data...")

# Known InfoWater Pro junction output field names:
# - "Outflow" - total outflow from the junction
# - "Actual Demand" - the actual demand portion of flow satisfied
# - "Required Demand" - the requested/base demand
# - "Adjacent Pipe Leakage" - leakage outflow from adjacent pipes (if enabled)
# 
# NOTE: "Unsatisfied Demand" is RANGE DATA ONLY (no time series available)
# We calculate it as: Unsatisfied = Required Demand - Actual Demand

# Data structures for each junction
junction_data = {
    'outflow': {},           # Total outflow from junction
    'actual_demand': {},     # Actual demand satisfied
    'required_demand': {},   # Required/base demand
    'leakage': {},           # Adjacent pipe leakage
    'unsatisfied': {}        # Calculated: Required - Actual
}

# Track junctions with data
junctions_processed = 0
junctions_with_outflow = 0
junctions_with_actual_demand = 0
junctions_with_required_demand = 0
junctions_with_leakage = 0
junctions_with_unsatisfied = 0

def get_junction_data(jct_id, field_name):
    """Get time series data for a junction field, with unit conversion for flow fields."""
    try:
        data = outman.get_time_data("Junction", jct_id, field_name)
        if data is None:
            return None
        # Apply flow conversion
        return [v * flow_factor for v in data]
    except Exception:
        return None

# Create progress dialog
progress_window = tk.Tk()
progress_window.title("Processing Results...")
progress_window.geometry("400x120")
progress_window.resizable(False, False)

# Center on screen
pw_width = 400
pw_height = 120
pw_x = (progress_window.winfo_screenwidth() - pw_width) // 2
pw_y = (progress_window.winfo_screenheight() - pw_height) // 2
progress_window.geometry(f"{pw_width}x{pw_height}+{pw_x}+{pw_y}")
progress_window.lift()
progress_window.attributes('-topmost', True)

ttk.Label(progress_window, text=f"Processing {len(zone_junction_ids)} junctions in Zone {selected_zone}...", 
          font=('Segoe UI', 10)).pack(pady=(15, 5))

progress_var = tk.DoubleVar(value=0)
progress_bar = ttk.Progressbar(progress_window, variable=progress_var, maximum=100, length=350)
progress_bar.pack(pady=10)

progress_label = ttk.Label(progress_window, text="0%", font=('Segoe UI', 9))
progress_label.pack()

progress_window.update()

# Collect data for each junction
total_junctions = len(zone_junction_ids)
for idx, jct_id in enumerate(zone_junction_ids):
    junctions_processed += 1
    
    # Get Outflow (total outflow from junction)
    outflow_data = get_junction_data(jct_id, "Outflow")
    if outflow_data is not None:
        junction_data['outflow'][jct_id] = outflow_data
        junctions_with_outflow += 1
    
    # Get Actual Demand
    actual_demand_data = get_junction_data(jct_id, "Actual Demand")
    if actual_demand_data is not None:
        junction_data['actual_demand'][jct_id] = actual_demand_data
        junctions_with_actual_demand += 1
    
    # Get Required Demand (needed for unsatisfied demand calculation)
    required_demand_data = get_junction_data(jct_id, "Required Demand")
    if required_demand_data is not None:
        junction_data['required_demand'][jct_id] = required_demand_data
        junctions_with_required_demand += 1
    
    # Get Adjacent Pipe Leakage (if requested)
    if output_options['show_leakage']:
        leakage_data = get_junction_data(jct_id, "Adjacent Pipe Leakage")
        if leakage_data is not None:
            junction_data['leakage'][jct_id] = leakage_data
            junctions_with_leakage += 1
    
    # Calculate Unsatisfied Demand (if requested)
    # Unsatisfied = Required Demand - Actual Demand
    if output_options['show_unsatisfied']:
        if required_demand_data is not None and actual_demand_data is not None:
            unsatisfied_data = [max(0, req - act) for req, act in zip(required_demand_data, actual_demand_data)]
            # Only store if there's any unsatisfied demand
            if any(v > 0.0001 for v in unsatisfied_data):
                junction_data['unsatisfied'][jct_id] = unsatisfied_data
                junctions_with_unsatisfied += 1
    
    # Update progress bar every 10 junctions or at the end
    if idx % 10 == 0 or idx == total_junctions - 1:
        progress_pct = ((idx + 1) / total_junctions) * 100
        progress_var.set(progress_pct)
        progress_label.config(text=f"{progress_pct:.0f}% ({idx + 1}/{total_junctions} junctions)")
        progress_window.update()

# Close progress window
progress_window.destroy()

print(f"Processed {junctions_processed} junctions:")
print(f"  With Outflow data: {junctions_with_outflow}")
print(f"  With Actual Demand data: {junctions_with_actual_demand}")
print(f"  With Required Demand data: {junctions_with_required_demand}")
print(f"  With Adjacent Pipe Leakage data: {junctions_with_leakage}")
print(f"  With Unsatisfied Demand (calculated): {junctions_with_unsatisfied}")

# =============================================================================
# SECTION 6: Calculate zone totals and find extremes
# =============================================================================
def sum_junction_data(data_dict):
    """Sum all junction time series into a total."""
    if not data_dict:
        return [0.0] * len(times)
    
    total = [0.0] * len(times)
    for jct_id, data in data_dict.items():
        for i, v in enumerate(data):
            if i < len(total):
                total[i] += v
    return total

def integrate_volume(flow_data, times_hrs):
    """Calculate total volume by integrating flow over time (trapezoidal rule)."""
    if not flow_data or len(flow_data) < 2:
        return 0.0
    
    total_volume = 0.0
    for i in range(1, len(flow_data)):
        dt = times_hrs[i] - times_hrs[i-1]  # hours
        avg_flow = (flow_data[i] + flow_data[i-1]) / 2.0
        total_volume += avg_flow * dt  # flow-units * hours
    
    return total_volume

def find_max_junction(data_dict):
    """Find junction with maximum total (integrated) value in proper volume units."""
    max_jct = None
    max_value = 0.0
    
    for jct_id, data in data_dict.items():
        total = integrate_volume(data, times) * volume_factor
        if total > max_value:
            max_value = total
            max_jct = jct_id
    
    return max_jct, max_value

# Calculate totals from the direct output fields
total_outflow = sum_junction_data(junction_data['outflow'])
total_actual_demand = sum_junction_data(junction_data['actual_demand'])
total_required_demand = sum_junction_data(junction_data['required_demand'])
total_leakage = sum_junction_data(junction_data['leakage'])
total_unsatisfied = sum_junction_data(junction_data['unsatisfied'])

# Calculate volumes (integrated over simulation, converted to proper volume units)
outflow_volume = integrate_volume(total_outflow, times) * volume_factor
actual_demand_volume = integrate_volume(total_actual_demand, times) * volume_factor
required_demand_volume = integrate_volume(total_required_demand, times) * volume_factor
leakage_volume = integrate_volume(total_leakage, times) * volume_factor
unsatisfied_volume = integrate_volume(total_unsatisfied, times) * volume_factor

# Find junctions with maximum values for each output type
max_outflow_jct, max_outflow_jct_value = find_max_junction(junction_data['outflow'])
max_required_jct, max_required_jct_value = find_max_junction(junction_data['required_demand'])
max_actual_jct, max_actual_jct_value = find_max_junction(junction_data['actual_demand'])
max_leakage_jct, max_leakage_value = find_max_junction(junction_data['leakage'])
max_unsatisfied_jct, max_unsatisfied_value = find_max_junction(junction_data['unsatisfied'])

# Also find junction with max instantaneous values
def find_max_instantaneous(data_dict):
    """Find junction with maximum instantaneous value and when it occurred."""
    max_jct = None
    max_value = 0.0
    max_time = 0.0
    
    for jct_id, data in data_dict.items():
        for i, v in enumerate(data):
            if v > max_value:
                max_value = v
                max_jct = jct_id
                max_time = times[i]
    
    return max_jct, max_value, max_time

max_inst_leakage = find_max_instantaneous(junction_data['leakage'])
max_inst_unsatisfied = find_max_instantaneous(junction_data['unsatisfied'])

print(f"\n=== Summary Metrics ===")
print(f"Total Outflow Volume: {outflow_volume:.2f} {volume_unit}")
print(f"Total Required Demand Volume: {required_demand_volume:.2f} {volume_unit}")
print(f"Total Actual Demand Volume: {actual_demand_volume:.2f} {volume_unit}")
if junctions_with_leakage > 0:
    print(f"Total Leakage Volume: {leakage_volume:.2f} {volume_unit}")
    if max_leakage_jct:
        print(f"  Highest Leakage Junction: {max_leakage_jct} ({max_leakage_value:.2f} {volume_unit} total)")
        print(f"  Max Instantaneous: {max_inst_leakage[1]:.2f} {flow_unit} at {max_inst_leakage[2]:.2f} hrs @ Jct {max_inst_leakage[0]}")
if junctions_with_unsatisfied > 0:
    print(f"Total Unsatisfied Demand Volume (calculated): {unsatisfied_volume:.2f} {volume_unit}")
    if max_unsatisfied_jct:
        print(f"  Highest Unsatisfied Junction: {max_unsatisfied_jct} ({max_unsatisfied_value:.2f} {volume_unit} total)")
        print(f"  Max Instantaneous: {max_inst_unsatisfied[1]:.2f} {flow_unit} at {max_inst_unsatisfied[2]:.2f} hrs @ Jct {max_inst_unsatisfied[0]}")

# =============================================================================
# SECTION 7: Create Interactive Plot
# =============================================================================
print("\nCreating plot...")

# Create main window
plot_window = tk.Tk()
plot_window.title(f"Zonal Outflow Analysis: {selected_zone} - {selected_scenario}")

screen_width = plot_window.winfo_screenwidth()
screen_height = plot_window.winfo_screenheight()
window_width = min(1200, int(screen_width * 0.75))
window_height = int(screen_height * 0.75)
x_pos = (screen_width - window_width) // 2
y_pos = (screen_height - window_height) // 2 - 30
plot_window.geometry(f"{window_width}x{window_height}+{x_pos}+{y_pos}")
plot_window.minsize(800, 600)
plot_window.lift()
plot_window.attributes('-topmost', True)
plot_window.after(100, lambda: plot_window.attributes('-topmost', False))

# Line info for legend table
all_line_info = []

# Create figure
fig, ax = plt.subplots(figsize=(11, 5))

# Plot Total Outflow (main line - thick)
if junctions_with_outflow > 0 and any(v > 0 for v in total_outflow):
    line_outflow, = ax.plot(times, total_outflow, color='navy', linewidth=3, 
                            label='Outflow', alpha=0.9)
    all_line_info.append({
        'line': line_outflow,
        'element': 'Outflow',
        'type': 'Outflow',
        'color': 'navy',
        'style': 'solid',
        'stats': {
            'min': f"{min(total_outflow):.2f}",
            'max': f"{max(total_outflow):.2f}",
            'avg': f"{np.mean(total_outflow):.2f}",
            'volume': f"{outflow_volume:,.0f}",
            'max_jct': max_outflow_jct or '-'
        }
    })

# Plot Required Demand (dashed line to show what was requested)
if junctions_with_required_demand > 0 and any(v > 0 for v in total_required_demand):
    line_required, = ax.plot(times, total_required_demand, color='purple', linewidth=2, 
                             linestyle='--', label='Required Demand', alpha=0.7)
    all_line_info.append({
        'line': line_required,
        'element': 'Required Demand',
        'type': 'Demand',
        'color': 'purple',
        'style': '--',
        'stats': {
            'min': f"{min(total_required_demand):.2f}",
            'max': f"{max(total_required_demand):.2f}",
            'avg': f"{np.mean(total_required_demand):.2f}",
            'volume': f"{required_demand_volume:,.0f}",
            'max_jct': max_required_jct or '-'
        }
    })

# Plot Actual Demand
if junctions_with_actual_demand > 0 and any(v > 0 for v in total_actual_demand):
    line_demand, = ax.plot(times, total_actual_demand, color='green', linewidth=2.5, 
                           linestyle='-', label='Actual Demand', alpha=0.85)
    all_line_info.append({
        'line': line_demand,
        'element': 'Actual Demand',
        'type': 'Demand',
        'color': 'green',
        'style': 'solid',
        'stats': {
            'min': f"{min(total_actual_demand):.2f}",
            'max': f"{max(total_actual_demand):.2f}",
            'avg': f"{np.mean(total_actual_demand):.2f}",
            'volume': f"{actual_demand_volume:,.0f}",
            'max_jct': max_actual_jct or '-'
        }
    })

# Plot Adjacent Pipe Leakage (if available - check for any non-zero values)
if junctions_with_leakage > 0 and any(abs(v) > 0.0001 for v in total_leakage):
    line_leakage, = ax.plot(times, total_leakage, color='red', linewidth=2, 
                            linestyle='--', label='Adjacent Pipe Leakage', alpha=0.85)
    all_line_info.append({
        'line': line_leakage,
        'element': 'Adjacent Pipe Leakage',
        'type': 'Leakage',
        'color': 'red',
        'style': '--',
        'stats': {
            'min': f"{min(total_leakage):.2f}",
            'max': f"{max(total_leakage):.2f}",
            'avg': f"{np.mean(total_leakage):.2f}",
            'volume': f"{leakage_volume:,.0f}",
            'max_jct': max_leakage_jct or '-'
        }
    })

# Plot Unsatisfied Demand (if available - check for any non-zero values)
if junctions_with_unsatisfied > 0 and any(abs(v) > 0.0001 for v in total_unsatisfied):
    line_unsatisfied, = ax.plot(times, total_unsatisfied, color='orange', linewidth=2.5, 
                                linestyle='-', label='Unsatisfied Demand', alpha=0.9)
    all_line_info.append({
        'line': line_unsatisfied,
        'element': 'Unsatisfied Demand',
        'type': 'Unsatisfied',
        'color': 'orange',
        'style': ':',
        'stats': {
            'min': f"{min(total_unsatisfied):.2f}",
            'max': f"{max(total_unsatisfied):.2f}",
            'avg': f"{np.mean(total_unsatisfied):.2f}",
            'volume': f"{unsatisfied_volume:,.0f}",
            'max_jct': max_unsatisfied_jct or '-'
        }
    })

ax.set_xlabel('Time (hrs)', fontsize=10)
ax.set_ylabel(f'Flow ({flow_unit})', fontsize=10)
ax.set_title(f'Zonal Outflow Analysis - Zone: {selected_zone}', fontsize=12, fontweight='bold')
ax.grid(True, alpha=0.3)
ax.legend(loc='upper right', fontsize=9)

plt.tight_layout()

# === Main layout ===
main_frame = ttk.Frame(plot_window)
main_frame.pack(fill=tk.BOTH, expand=True)

# Canvas for plot
canvas_frame = ttk.Frame(main_frame)
canvas_frame.pack(fill=tk.BOTH, expand=True)

canvas_agg = FigureCanvasTkAgg(fig, master=canvas_frame)
canvas_agg.draw()
canvas_widget = canvas_agg.get_tk_widget()
canvas_widget.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

toolbar = NavigationToolbar2Tk(canvas_agg, canvas_frame)
toolbar.update()

# === Legend/Stats Table (using grid for proper alignment) ===
table_frame = ttk.LabelFrame(main_frame, text=f"Legend & Statistics (Flow: {flow_unit}, Volume: {volume_unit})")
table_frame.pack(fill=tk.X, padx=10, pady=5)

# Create inner frame for grid layout
table_inner = ttk.Frame(table_frame)
table_inner.pack(fill=tk.X, padx=5, pady=5)

# Column configuration: (header, width_pixels, anchor)
columns = [
    ('', 25, 'center'),           # Checkbox
    ('Line', 55, 'center'),       # Line style preview
    ('Element', 160, 'w'),        # Element name
    ('Type', 70, 'w'),            # Type
    (f'Min ({flow_unit})', 85, 'e'),    # Min
    (f'Max ({flow_unit})', 85, 'e'),    # Max
    (f'Avg ({flow_unit})', 85, 'e'),    # Avg
    (f'Volume ({volume_unit})', 110, 'e'),  # Volume
    ('Max Jct', 80, 'center')     # Junction with highest value
]

# Configure column weights for proper sizing
for col_idx in range(len(columns)):
    table_inner.columnconfigure(col_idx, weight=0)

# Header row
for col_idx, (header, width, anchor) in enumerate(columns):
    if col_idx == 0:  # Checkbox column - use emoji
        lbl = ttk.Label(table_inner, text='👁', font=('Segoe UI', 9), anchor='center')
    else:
        lbl = ttk.Label(table_inner, text=header, font=('Segoe UI', 8, 'bold'), anchor=anchor)
    lbl.grid(row=0, column=col_idx, sticky='ew', padx=2, pady=2)

# Separator
sep = ttk.Separator(table_inner, orient='horizontal')
sep.grid(row=1, column=0, columnspan=len(columns), sticky='ew', pady=2)

visibility_vars = []

def create_toggle_callback(line_obj, var):
    def toggle():
        visible = var.get()
        line_obj.set_visible(visible)
        canvas_agg.draw()
    return toggle

# Data rows
for row_idx, info in enumerate(all_line_info, start=2):
    col = 0
    
    # Checkbox
    var = tk.BooleanVar(value=True)
    visibility_vars.append((var, info))
    cb = ttk.Checkbutton(table_inner, variable=var, command=create_toggle_callback(info['line'], var))
    cb.grid(row=row_idx, column=col, padx=2, pady=1)
    col += 1
    
    # Line style preview canvas
    line_canvas = tk.Canvas(table_inner, width=50, height=16, bg='white', 
                            highlightthickness=1, highlightbackground='gray')
    line_canvas.grid(row=row_idx, column=col, padx=2, pady=1)
    
    if info['style'] == 'solid' or info['style'] == '-':
        line_canvas.create_line(5, 8, 45, 8, fill=info['color'], width=3)
    elif info['style'] == '--':
        line_canvas.create_line(5, 8, 15, 8, fill=info['color'], width=3)
        line_canvas.create_line(22, 8, 32, 8, fill=info['color'], width=3)
        line_canvas.create_line(39, 8, 45, 8, fill=info['color'], width=3)
    else:  # dotted
        for x in range(5, 46, 10):
            line_canvas.create_oval(x, 5, x+6, 11, fill=info['color'], outline=info['color'])
    col += 1
    
    # Element name
    ttk.Label(table_inner, text=info['element'], font=('Segoe UI', 9), 
              anchor='w').grid(row=row_idx, column=col, sticky='w', padx=4, pady=1)
    col += 1
    
    # Type
    ttk.Label(table_inner, text=info['type'], font=('Segoe UI', 9), 
              anchor='w').grid(row=row_idx, column=col, sticky='w', padx=4, pady=1)
    col += 1
    
    # Stats (right-aligned for numbers)
    for stat_key in ['min', 'max', 'avg', 'volume']:
        val = info['stats'].get(stat_key, '')
        ttk.Label(table_inner, text=val, font=('Segoe UI', 9), 
                  anchor='e').grid(row=row_idx, column=col, sticky='e', padx=4, pady=1)
        col += 1
    
    # Max Junction (center-aligned)
    max_jct_val = info['stats'].get('max_jct', '-')
    ttk.Label(table_inner, text=max_jct_val, font=('Segoe UI', 9), 
              anchor='center').grid(row=row_idx, column=col, sticky='ew', padx=4, pady=1)

# === Button Frame ===
button_frame = ttk.Frame(main_frame)
button_frame.pack(fill=tk.X, pady=5)

def show_all_lines():
    for var, info in visibility_vars:
        var.set(True)
        info['line'].set_visible(True)
    canvas_agg.draw()

def hide_all_lines():
    for var, info in visibility_vars:
        var.set(False)
        info['line'].set_visible(False)
    canvas_agg.draw()

ttk.Button(button_frame, text="Show All", command=show_all_lines).pack(side=tk.LEFT, padx=10)
ttk.Button(button_frame, text="Hide All", command=hide_all_lines).pack(side=tk.LEFT, padx=5)

def export_to_csv():
    """Export all data to CSV."""
    from tkinter import filedialog
    import csv
    
    default_filename = f"ZonalOutflow_{selected_zone}_{selected_scenario}.csv"
    filepath = filedialog.asksaveasfilename(
        title="Export Zonal Outflow Data to CSV",
        defaultextension=".csv",
        filetypes=[("CSV files", "*.csv"), ("All files", "*.*")],
        initialfile=default_filename,
        initialdir=str(project_path)
    )
    
    if not filepath:
        return
    
    try:
        with open(filepath, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            
            # Header info
            writer.writerow(["Zonal Outflow Analysis Export"])
            writer.writerow([f"Zone: {selected_zone}"])
            writer.writerow([f"Scenario: {selected_scenario}"])
            writer.writerow([f"Flow Units: {flow_unit}"])
            writer.writerow([f"Junctions in Zone: {len(zone_junction_ids)}"])
            writer.writerow([])
            
            # Summary metrics
            writer.writerow(["Summary Metrics"])
            writer.writerow(["Metric", "Value", "Units"])
            writer.writerow(["Outflow Volume", f"{outflow_volume:.2f}", volume_unit])
            writer.writerow(["Required Demand Volume", f"{required_demand_volume:.2f}", volume_unit])
            writer.writerow(["Actual Demand Volume", f"{actual_demand_volume:.2f}", volume_unit])
            if junctions_with_leakage > 0:
                writer.writerow(["Adjacent Pipe Leakage Volume", f"{leakage_volume:.2f}", volume_unit])
                if max_leakage_jct:
                    writer.writerow(["Highest Leakage Junction", max_leakage_jct, f"{max_leakage_value:.2f} {volume_unit}"])
            if junctions_with_unsatisfied > 0:
                writer.writerow(["Unsatisfied Demand Volume (calculated)", f"{unsatisfied_volume:.2f}", volume_unit])
                if max_unsatisfied_jct:
                    writer.writerow(["Highest Unsatisfied Junction", max_unsatisfied_jct, f"{max_unsatisfied_value:.2f} {volume_unit}"])
            writer.writerow([])
            
            # Time series data
            writer.writerow(["Time Series Data"])
            header = ['Time (hrs)', f'Outflow ({flow_unit})', f'Required Demand ({flow_unit})', f'Actual Demand ({flow_unit})']
            if junctions_with_leakage > 0:
                header.append(f'Adjacent Pipe Leakage ({flow_unit})')
            if junctions_with_unsatisfied > 0:
                header.append(f'Unsatisfied Demand ({flow_unit})')
            writer.writerow(header)
            
            for i, t in enumerate(times):
                row = [f"{t:.4f}", f"{total_outflow[i]:.4f}", f"{total_required_demand[i]:.4f}", f"{total_actual_demand[i]:.4f}"]
                if junctions_with_leakage > 0:
                    row.append(f"{total_leakage[i]:.4f}")
                if junctions_with_unsatisfied > 0:
                    row.append(f"{total_unsatisfied[i]:.4f}")
                writer.writerow(row)
        
        tk.messagebox.showinfo("Export Successful", f"Data exported to:\n{filepath}")
        print(f"✅ Data exported to: {filepath}")
        
    except Exception as e:
        tk.messagebox.showerror("Export Error", f"Failed to export data:\n{str(e)}")
        print(f"❌ Export failed: {e}")

ttk.Button(button_frame, text="📊 Export to CSV", command=export_to_csv).pack(side=tk.LEFT, padx=15)

# Info label - build warning messages for missing data
warnings = []
if junctions_with_outflow == 0:
    warnings.append("No Outflow data")
if junctions_with_actual_demand == 0:
    warnings.append("No Actual Demand data")
if junctions_with_leakage == 0 and output_options['show_leakage']:
    warnings.append("No Leakage data")
if junctions_with_unsatisfied == 0 and output_options['show_unsatisfied']:
    warnings.append("No Unsatisfied Demand data")

if warnings:
    info_text = f"⚠️ {', '.join(warnings)} - check simulation output options"
else:
    info_text = f"💡 Zone {selected_zone}: {len(zone_junction_ids)} junctions analyzed"

instructions = ttk.Label(button_frame, text=info_text, font=('Segoe UI', 9))
instructions.pack(side=tk.LEFT, padx=10)

ttk.Button(button_frame, text="Close", command=plot_window.destroy).pack(side=tk.RIGHT, padx=10)

print("\n✅ Plot window opened!")
print("Interactive features:")
print("  - Line visibility toggles")
print("  - Summary metrics (volumes, highest junctions)")
print("  - Export to CSV")
print("  - Zoom/pan toolbar")

plot_window.mainloop()
plt.close('all')






