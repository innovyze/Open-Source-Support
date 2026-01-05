"""
Pressure Zone Water Balance Script
===================================
Analyzes water balance for a selected pressure zone with 2 interactive panels:
- Panel 1: Storage & Pressure (Tank Levels + Min/Max Zone Pressure on secondary axis)
- Panel 2: Net Flow (Inflows positive, Outflows negative, Total Demand)

Total Demand = Total Inflow - Total Outflow - Tank Flow (storage change)

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
# SECTION 2: Read Pressure Zone DBF data (using arcpy - no external dependencies)
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

def read_pzm_elements(dbf_name, zone_id):
    """Read elements for a specific zone from a PZM DBF file."""
    inflows = []
    outflows = []
    dbf_file = pzm_path / dbf_name
    
    if not dbf_file.exists():
        return {'inflow': inflows, 'outflow': outflows}
    
    for rec in read_dbf_to_list(dbf_file, ['ID', 'ELMID', 'INOUT']):
        if rec.get('ID') == zone_id:
            elm_id = rec.get('ELMID', '')
            inout = rec.get('INOUT', 0) or 0
            if inout == 1:
                inflows.append(elm_id)
            elif inout == 2:
                outflows.append(elm_id)
    
    return {'inflow': inflows, 'outflow': outflows}

def get_zone_element_counts(zone_id):
    """Get counts of each element type for a zone."""
    tanks = read_pzm_elements('PZMTANK.DBF', zone_id)
    reservoirs = read_pzm_elements('PZMRES.DBF', zone_id)
    pumps = read_pzm_elements('PZMPUMP.DBF', zone_id)
    valves = read_pzm_elements('PZMVALVE.DBF', zone_id)
    pipes = read_pzm_elements('PZMPIPE.DBF', zone_id)
    
    return {
        'tanks': len(set(tanks['inflow'] + tanks['outflow'])),
        'reservoirs': len(set(reservoirs['inflow'] + reservoirs['outflow'])),
        'pumps': len(set(pumps['inflow'] + pumps['outflow'])),
        'valves': len(set(valves['inflow'] + valves['outflow'])),
        'pipes': len(set(pipes['inflow'] + pipes['outflow']))
    }

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

# Read zones and their element counts
pzm_zones = read_pzm_zones()
print(f"Found {len(pzm_zones)} pressure zones")

for zone in pzm_zones:
    zone['elements'] = get_zone_element_counts(zone['id'])
    # Add junction count from JUNCTION.DBF
    zone['elements']['junctions'] = len(junction_zones.get(zone['id'], []))
print("Loaded element counts for all zones")

# =============================================================================
# SECTION 3: Selection Dialog
# =============================================================================
selected_zone = None
selected_scenario = None
output_options = {
    'tank_output': 'Level',
    'flow_unit': 'GPM',
    'show_storage': True,
    'show_pressure': True,
    'show_net_flow': True,
    'show_totals': True,
    'omit_zero_flow': True  # New option: filter out zero-flow boundary links
}

def open_selection_dialog():
    global selected_zone, selected_scenario, output_options
    
    root = tk.Tk()
    root.title("Pressure Zone Water Balance")
    root.geometry("700x700")
    root.lift()
    root.attributes('-topmost', True)
    root.after(100, lambda: root.attributes('-topmost', False))
    root.focus_force()
    
    # === Zone Selection ===
    zone_frame = ttk.LabelFrame(root, text="Select Pressure Zone")
    zone_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
    
    ttk.Label(zone_frame, text="Click to select a pressure zone to analyze:", 
              font=('Segoe UI', 9)).pack(anchor='w', padx=5, pady=2)
    
    columns = ('zone', 'jcts', 'tanks', 'res', 'pumps', 'valves', 'pipes')
    zone_tree = ttk.Treeview(zone_frame, columns=columns, show='headings', height=8, selectmode='browse')
    
    zone_tree.heading('zone', text='Pressure Zone')
    zone_tree.heading('jcts', text='Junctions')
    zone_tree.heading('tanks', text='Tanks')
    zone_tree.heading('res', text='Reservoirs')
    zone_tree.heading('pumps', text='Pumps')
    zone_tree.heading('valves', text='Valves')
    zone_tree.heading('pipes', text='Pipes')
    
    zone_tree.column('zone', width=150, anchor='w')
    zone_tree.column('jcts', width=65, anchor='center')
    zone_tree.column('tanks', width=50, anchor='center')
    zone_tree.column('res', width=65, anchor='center')
    zone_tree.column('pumps', width=50, anchor='center')
    zone_tree.column('valves', width=50, anchor='center')
    zone_tree.column('pipes', width=50, anchor='center')
    
    for z in pzm_zones:
        desc = f" - {z['description']}" if z['description'] else ""
        zone_name = f"{z['id']}{desc}"
        elems = z.get('elements', {})
        zone_tree.insert('', tk.END, values=(
            zone_name,
            elems.get('junctions', 0),
            elems.get('tanks', 0),
            elems.get('reservoirs', 0),
            elems.get('pumps', 0),
            elems.get('valves', 0),
            elems.get('pipes', 0)
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
    
    # Tank output type
    tank_row = ttk.Frame(options_frame)
    tank_row.pack(fill=tk.X, padx=5, pady=3)
    ttk.Label(tank_row, text="Tank Output:").pack(side=tk.LEFT, padx=5)
    tank_output_var = tk.StringVar(value="Level")
    ttk.Radiobutton(tank_row, text="Level (ft)", variable=tank_output_var, value="Level").pack(side=tk.LEFT, padx=5)
    ttk.Radiobutton(tank_row, text="% Volume", variable=tank_output_var, value="% Volume").pack(side=tk.LEFT, padx=5)
    
    # Flow units
    unit_row = ttk.Frame(options_frame)
    unit_row.pack(fill=tk.X, padx=5, pady=3)
    ttk.Label(unit_row, text="Flow Units:").pack(side=tk.LEFT, padx=5)
    flow_unit_var = tk.StringVar(value="GPM")
    for unit in ["CFS", "GPM", "MGD", "GPD"]:
        ttk.Radiobutton(unit_row, text=unit, variable=flow_unit_var, value=unit).pack(side=tk.LEFT, padx=3)
    
    # === Data Filtering ===
    filter_frame = ttk.LabelFrame(root, text="Data Filtering")
    filter_frame.pack(fill=tk.X, padx=10, pady=5)
    
    omit_zero_var = tk.BooleanVar(value=True)
    ttk.Checkbutton(filter_frame, text="Omit zero-flow boundary links (closed pipes/valves)", 
                    variable=omit_zero_var).pack(anchor='w', padx=10, pady=5)
    
    # === Panel Visibility ===
    panel_frame = ttk.LabelFrame(root, text="Panel Visibility")
    panel_frame.pack(fill=tk.X, padx=10, pady=5)
    
    show_storage_var = tk.BooleanVar(value=True)
    show_pressure_var = tk.BooleanVar(value=True)
    show_net_flow_var = tk.BooleanVar(value=True)
    show_totals_var = tk.BooleanVar(value=True)
    
    ttk.Checkbutton(panel_frame, text="Storage (Tank Levels)", variable=show_storage_var).pack(anchor='w', padx=10, pady=2)
    ttk.Checkbutton(panel_frame, text="Zone Pressure (Min/Max junction pressure on storage panel)", variable=show_pressure_var).pack(anchor='w', padx=10, pady=2)
    ttk.Checkbutton(panel_frame, text="Net Flow (Inflows/Outflows combined)", variable=show_net_flow_var).pack(anchor='w', padx=10, pady=2)
    ttk.Checkbutton(panel_frame, text="Show Total Inflow, Total Outflow, and Total Demand lines", variable=show_totals_var).pack(anchor='w', padx=10, pady=2)
    
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
            'tank_output': tank_output_var.get(),
            'flow_unit': flow_unit_var.get(),
            'show_storage': show_storage_var.get(),
            'show_pressure': show_pressure_var.get(),
            'show_net_flow': show_net_flow_var.get(),
            'show_totals': show_totals_var.get(),
            'omit_zero_flow': omit_zero_var.get()
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
# SECTION 4: Load simulation results and zone elements
# =============================================================================
output_path = str(out_folder / selected_scenario / "HYDQUA.OUT")
print(f"Loading results from: {output_path}")
outman = OutMan(output_path)
times = outman.get_time_list()

# Read zone elements
zone_tanks = read_pzm_elements('PZMTANK.DBF', selected_zone)
zone_reservoirs = read_pzm_elements('PZMRES.DBF', selected_zone)
zone_pumps = read_pzm_elements('PZMPUMP.DBF', selected_zone)
zone_valves = read_pzm_elements('PZMVALVE.DBF', selected_zone)
zone_pipes = read_pzm_elements('PZMPIPE.DBF', selected_zone)

print(f"\nZone {selected_zone} elements:")
print(f"  Tanks: {len(set(zone_tanks['inflow'] + zone_tanks['outflow']))} total")
print(f"  Reservoirs: Inflow={len(zone_reservoirs['inflow'])}, Outflow={len(zone_reservoirs['outflow'])}")
print(f"  Pumps: Inflow={len(zone_pumps['inflow'])}, Outflow={len(zone_pumps['outflow'])}")
print(f"  Valves: Inflow={len(zone_valves['inflow'])}, Outflow={len(zone_valves['outflow'])}")
print(f"  Pipes: Inflow={len(zone_pipes['inflow'])}, Outflow={len(zone_pipes['outflow'])}")

# Get junctions in this zone
zone_junction_ids = junction_zones.get(selected_zone, [])
print(f"  Junctions: {len(zone_junction_ids)} total")

# Flow unit conversion
flow_conversions = {
    'CFS': 1.0,
    'GPM': 448.831,
    'MGD': 0.6463168,
    'GPD': 646316.8
}
flow_factor = flow_conversions.get(output_options['flow_unit'], 1.0)
flow_unit = output_options['flow_unit']
tank_output = output_options['tank_output']
omit_zero_flow = output_options['omit_zero_flow']

# =============================================================================
# SECTION 5: Helper functions for data retrieval and filtering
# =============================================================================
def get_element_flow_data(element_type, element_id, field="Flow"):
    """Get time series flow data for an element, with unit conversion."""
    try:
        data = outman.get_time_data(element_type, element_id, field)
        if data is None:
            return None
        return [v * flow_factor for v in data]
    except Exception as e:
        print(f"  Warning: Could not get {field} for {element_type} {element_id}: {e}")
        return None

def get_tank_data(tank_id, field="Level"):
    """Get tank level or % volume data."""
    try:
        data = outman.get_time_data("Tank", tank_id, field)
        return data
    except Exception as e:
        print(f"  Warning: Could not get {field} for Tank {tank_id}: {e}")
        return None

def get_tank_flow_data(tank_id):
    """Get tank flow data (for water balance calculation)."""
    try:
        data = outman.get_time_data("Tank", tank_id, "Flow")
        if data is None:
            return None
        return [v * flow_factor for v in data]
    except Exception as e:
        print(f"  Warning: Could not get Flow for Tank {tank_id}: {e}")
        return None

def has_nonzero_flow(data, threshold=0.001):
    """Check if data has any non-zero values."""
    if data is None:
        return False
    return any(abs(v) > threshold for v in data)

def collect_flow_elements(element_type, element_ids, direction_label, filter_zero=True):
    """Collect flow data for a list of elements, optionally filtering zero-flow."""
    elements = []
    for elm_id in element_ids:
        data = get_element_flow_data(element_type, elm_id)
        if data is None:
            print(f"  Skipping {element_type} {elm_id} (no data)")
            continue
        
        if filter_zero and not has_nonzero_flow(data):
            print(f"  Skipping {element_type} {elm_id} (zero flow throughout)")
            continue
        
        elements.append({
            'id': elm_id,
            'type': element_type,
            'direction': direction_label,
            'data': data
        })
    return elements

# =============================================================================
# SECTION 5b: Find Min/Max pressure junctions in zone
# =============================================================================
def find_zone_pressure_extremes():
    """Find the junctions with min and max pressure in the zone.
    
    Returns dict with:
        - min_jct_id: Junction ID with overall minimum pressure
        - max_jct_id: Junction ID with overall maximum pressure  
        - min_pressure_data: Time series for min pressure junction
        - max_pressure_data: Time series for max pressure junction
    """
    if not zone_junction_ids:
        print("  No junctions in zone - cannot calculate pressure extremes")
        return None
    
    # Get all junction IDs from output manager
    all_junctions = outman.get_element_list("Junction")
    
    # Get range data for all junctions
    # Format: [max_values, max_times, min_values, min_times, avg_values, ...]
    range_data = outman.get_all_range_data("Junction", "Pressure")
    max_pressures = range_data[0]  # Max pressure for each junction
    min_pressures = range_data[2]  # Min pressure for each junction
    
    # Build lookup dict: junction_id -> (max_pressure, min_pressure, index)
    jct_pressure_lookup = {}
    for i, jct_id in enumerate(all_junctions):
        jct_pressure_lookup[jct_id] = {
            'max': max_pressures[i],
            'min': min_pressures[i],
            'index': i
        }
    
    # Find zone junctions with extreme pressures
    zone_min_pressure = float('inf')
    zone_max_pressure = float('-inf')
    min_jct_id = None
    max_jct_id = None
    
    for jct_id in zone_junction_ids:
        if jct_id in jct_pressure_lookup:
            jct_data = jct_pressure_lookup[jct_id]
            
            # Check for overall minimum
            if jct_data['min'] < zone_min_pressure:
                zone_min_pressure = jct_data['min']
                min_jct_id = jct_id
            
            # Check for overall maximum
            if jct_data['max'] > zone_max_pressure:
                zone_max_pressure = jct_data['max']
                max_jct_id = jct_id
    
    if min_jct_id is None or max_jct_id is None:
        print("  Could not find pressure extremes in zone")
        return None
    
    print(f"  Min pressure junction: {min_jct_id} (min={zone_min_pressure:.1f} psi)")
    print(f"  Max pressure junction: {max_jct_id} (max={zone_max_pressure:.1f} psi)")
    
    # Get time series data for these junctions
    min_pressure_data = outman.get_time_data("Junction", min_jct_id, "Pressure")
    max_pressure_data = outman.get_time_data("Junction", max_jct_id, "Pressure")
    
    return {
        'min_jct_id': min_jct_id,
        'max_jct_id': max_jct_id,
        'min_pressure_data': min_pressure_data,
        'max_pressure_data': max_pressure_data,
        'zone_min_pressure': zone_min_pressure,
        'zone_max_pressure': zone_max_pressure
    }

# =============================================================================
# SECTION 6: Collect all data for plotting
# =============================================================================
print("\nCollecting data...")

# Storage (Tanks) - for level display
tank_ids = list(set(zone_tanks['inflow'] + zone_tanks['outflow']))
storage_data = []
tank_flow_data = []  # For water balance calculation

for tank_id in tank_ids:
    # Level/Volume data for display
    data = get_tank_data(tank_id, tank_output)
    if data is not None:
        storage_data.append({
            'id': tank_id,
            'type': 'Tank',
            'data': data
        })
        print(f"  Tank {tank_id} ({tank_output}): {len(data)} data points")
    
    # Flow data for water balance (positive = flow INTO tank = OUT of zone demand)
    flow_data = get_tank_flow_data(tank_id)
    if flow_data is not None:
        tank_flow_data.append({
            'id': tank_id,
            'type': 'Tank',
            'data': flow_data
        })
        print(f"  Tank {tank_id} (Flow): min={min(flow_data):.2f}, max={max(flow_data):.2f}")

# Inflows (with optional zero-flow filtering)
inflow_data = []
inflow_data.extend(collect_flow_elements("Reservoir", zone_reservoirs['inflow'], "Inflow", omit_zero_flow))
inflow_data.extend(collect_flow_elements("Pump", zone_pumps['inflow'], "Inflow", omit_zero_flow))
inflow_data.extend(collect_flow_elements("Valve", zone_valves['inflow'], "Inflow", omit_zero_flow))
inflow_data.extend(collect_flow_elements("Pipe", zone_pipes['inflow'], "Inflow", omit_zero_flow))

# Outflows (with optional zero-flow filtering)
outflow_data = []
outflow_data.extend(collect_flow_elements("Reservoir", zone_reservoirs['outflow'], "Outflow", omit_zero_flow))
outflow_data.extend(collect_flow_elements("Pump", zone_pumps['outflow'], "Outflow", omit_zero_flow))
outflow_data.extend(collect_flow_elements("Valve", zone_valves['outflow'], "Outflow", omit_zero_flow))
outflow_data.extend(collect_flow_elements("Pipe", zone_pipes['outflow'], "Outflow", omit_zero_flow))

# Find pressure extremes if enabled
pressure_extremes = None
if output_options['show_pressure']:
    print("\nFinding zone pressure extremes...")
    pressure_extremes = find_zone_pressure_extremes()

print(f"\nData summary:")
print(f"  Storage elements (tanks): {len(storage_data)}")
print(f"  Inflow elements: {len(inflow_data)}")
print(f"  Outflow elements: {len(outflow_data)}")
print(f"  Tank flow data (for demand calc): {len(tank_flow_data)}")
if pressure_extremes:
    print(f"  Pressure extremes: Min @ {pressure_extremes['min_jct_id']}, Max @ {pressure_extremes['max_jct_id']}")

# =============================================================================
# SECTION 7: Calculate totals and Total Demand
# =============================================================================
def calculate_total(elements_data):
    """Sum all element flows at each timestep."""
    if not elements_data:
        return [0.0] * len(times)
    total = [0.0] * len(times)
    for elem in elements_data:
        for i, v in enumerate(elem['data']):
            total[i] += v
    return total

# Calculate totals
total_inflow = calculate_total(inflow_data)
total_outflow = calculate_total(outflow_data)
total_tank_flow = calculate_total(tank_flow_data)  # Positive = flow into tanks

# Total Demand = Inflow - Outflow - Tank Flow
# (Tank flow positive means water going INTO storage, so subtract it from available supply)
total_demand = [
    total_inflow[i] - total_outflow[i] - total_tank_flow[i] 
    for i in range(len(times))
]

print(f"\nCalculated totals:")
print(f"  Total Inflow: avg={np.mean(total_inflow):.2f} {flow_unit}")
print(f"  Total Outflow: avg={np.mean(total_outflow):.2f} {flow_unit}")
print(f"  Total Tank Flow: avg={np.mean(total_tank_flow):.2f} {flow_unit}")
print(f"  Total Demand: avg={np.mean(total_demand):.2f} {flow_unit}")

# =============================================================================
# SECTION 8: Create Interactive 2-Panel Plot
# =============================================================================
show_storage = output_options['show_storage'] and len(storage_data) > 0
show_net_flow = output_options['show_net_flow'] and (len(inflow_data) > 0 or len(outflow_data) > 0)

active_panels = sum([show_storage, show_net_flow])

if active_panels == 0:
    print("\n⚠️ No data to display for this pressure zone!")
    raise SystemExit("No data available for the selected zone.")

print(f"\nCreating plot with {active_panels} panel(s)...")

# Create main window
plot_window = tk.Tk()
plot_window.title(f"Water Balance: {selected_zone} - {selected_scenario}")

screen_width = plot_window.winfo_screenwidth()
screen_height = plot_window.winfo_screenheight()
window_width = min(1400, int(screen_width * 0.8))
window_height = int(screen_height * 0.85)
x_pos = (screen_width - window_width) // 2
y_pos = (screen_height - window_height) // 2 - 30
plot_window.geometry(f"{window_width}x{window_height}+{x_pos}+{y_pos}")
plot_window.minsize(900, 600)
plot_window.lift()
plot_window.attributes('-topmost', True)
plot_window.after(100, lambda: plot_window.attributes('-topmost', False))

# Panel visibility variables
panel_vars = {
    'storage': tk.BooleanVar(value=show_storage),
    'net_flow': tk.BooleanVar(value=show_net_flow)
}

all_line_info = []

def create_plot():
    """Create or recreate the matplotlib figure."""
    global all_line_info
    all_line_info = []
    
    panels_to_show = []
    if panel_vars['storage'].get() and len(storage_data) > 0:
        panels_to_show.append('storage')
    if panel_vars['net_flow'].get() and (len(inflow_data) > 0 or len(outflow_data) > 0):
        panels_to_show.append('net_flow')
    
    if not panels_to_show:
        return None, None
    
    num_panels = len(panels_to_show)
    fig, axes = plt.subplots(num_panels, 1, figsize=(12, 2.8 * num_panels), sharex=True)
    
    if num_panels == 1:
        axes = [axes]
    
    ax_idx = 0
    
    # Color schemes
    tank_colors = plt.cm.Blues(np.linspace(0.4, 0.9, max(len(storage_data), 1)))
    reservoir_colors = plt.cm.Reds(np.linspace(0.5, 0.9, max(len([e for e in inflow_data + outflow_data if e['type'] == 'Reservoir']), 1)))
    pump_colors = plt.cm.Greens(np.linspace(0.4, 0.9, max(len([e for e in inflow_data + outflow_data if e['type'] == 'Pump']), 1)))
    valve_colors = plt.cm.Oranges(np.linspace(0.4, 0.9, max(len([e for e in inflow_data + outflow_data if e['type'] == 'Valve']), 1)))
    pipe_colors = plt.cm.Purples(np.linspace(0.4, 0.9, max(len([e for e in inflow_data + outflow_data if e['type'] == 'Pipe']), 1)))
    
    # === Panel 1: Storage & Pressure ===
    if 'storage' in panels_to_show:
        ax = axes[ax_idx]
        ax_idx += 1
        
        # Plot tank levels (left y-axis)
        for i, elem in enumerate(storage_data):
            line, = ax.plot(times, elem['data'], color=tank_colors[i], linewidth=2, label=f"Tank {elem['id']}")
            
            stats = {
                'min': f"{min(elem['data']):.2f}",
                'max': f"{max(elem['data']):.2f}",
                'avg': f"{np.mean(elem['data']):.2f}"
            }
            all_line_info.append({
                'line': line,
                'element': f"Tank {elem['id']}",
                'type': tank_output,
                'panel': 'Storage',
                'color': to_hex(tank_colors[i]),
                'style': 'solid',
                'stats': stats
            })
        
        tank_label = 'Level (ft)' if tank_output == 'Level' else '% Volume'
        ax.set_ylabel(f'Tank {tank_label}', fontsize=10, color='blue')
        ax.tick_params(axis='y', labelcolor='blue')
        
        # Plot pressure extremes on secondary axis (right y-axis)
        if pressure_extremes and output_options['show_pressure']:
            ax2 = ax.twinx()
            
            # Min pressure junction (dashed red)
            min_data = pressure_extremes['min_pressure_data']
            if min_data:
                line_min, = ax2.plot(times, min_data, color='darkred', linewidth=2, linestyle='--',
                                     label=f"Min Press @ {pressure_extremes['min_jct_id']}")
                stats = {
                    'min': f"{min(min_data):.1f}",
                    'max': f"{max(min_data):.1f}",
                    'avg': f"{np.mean(min_data):.1f}"
                }
                all_line_info.append({
                    'line': line_min,
                    'element': f"Min Press @ {pressure_extremes['min_jct_id']}",
                    'type': 'Pressure',
                    'panel': 'Storage',
                    'color': 'darkred',
                    'style': '--',
                    'stats': stats
                })
            
            # Max pressure junction (solid red)
            max_data = pressure_extremes['max_pressure_data']
            if max_data:
                line_max, = ax2.plot(times, max_data, color='crimson', linewidth=2, linestyle='-',
                                     label=f"Max Press @ {pressure_extremes['max_jct_id']}")
                stats = {
                    'min': f"{min(max_data):.1f}",
                    'max': f"{max(max_data):.1f}",
                    'avg': f"{np.mean(max_data):.1f}"
                }
                all_line_info.append({
                    'line': line_max,
                    'element': f"Max Press @ {pressure_extremes['max_jct_id']}",
                    'type': 'Pressure',
                    'panel': 'Storage',
                    'color': 'crimson',
                    'style': 'solid',
                    'stats': stats
                })
            
            ax2.set_ylabel('Pressure (psi)', fontsize=10, color='red')
            ax2.tick_params(axis='y', labelcolor='red')
            ax2.legend(loc='upper left', fontsize=8)
        
        ax.set_title(f'Storage & Pressure - Tank {tank_label} + Zone Pressure Extremes', fontsize=11, fontweight='bold')
        ax.grid(True, alpha=0.3)
        ax.legend(loc='upper right', fontsize=8)
    
    # === Panel 2: Net Flow (Inflows positive, Outflows negative) ===
    if 'net_flow' in panels_to_show:
        ax = axes[ax_idx]
        ax_idx += 1
        
        reservoir_idx = pump_idx = valve_idx = pipe_idx = 0
        
        # Plot inflows (positive)
        for elem in inflow_data:
            if elem['type'] == 'Reservoir':
                color = reservoir_colors[reservoir_idx % len(reservoir_colors)]
                reservoir_idx += 1
                style = '-'
                lw = 2.5
            elif elem['type'] == 'Pump':
                color = pump_colors[pump_idx % len(pump_colors)]
                pump_idx += 1
                style = '-'
                lw = 2
            elif elem['type'] == 'Valve':
                color = valve_colors[valve_idx % len(valve_colors)]
                valve_idx += 1
                style = '--'
                lw = 2
            else:  # Pipe
                color = pipe_colors[pipe_idx % len(pipe_colors)]
                pipe_idx += 1
                style = ':'
                lw = 1.5
            
            line, = ax.plot(times, elem['data'], color=color, linewidth=lw, linestyle=style,
                           label=f"{elem['type']} {elem['id']} (In)")
            
            stats = {
                'min': f"{min(elem['data']):.2f}",
                'max': f"{max(elem['data']):.2f}",
                'avg': f"{np.mean(elem['data']):.2f}"
            }
            all_line_info.append({
                'line': line,
                'element': f"{elem['type']} {elem['id']}",
                'type': 'Inflow',
                'panel': 'Net Flow',
                'color': to_hex(color),
                'style': style,
                'stats': stats
            })
        
        # Plot outflows (NEGATIVE orientation)
        for elem in outflow_data:
            if elem['type'] == 'Reservoir':
                color = reservoir_colors[reservoir_idx % len(reservoir_colors)]
                reservoir_idx += 1
                style = '-'
                lw = 2.5
            elif elem['type'] == 'Pump':
                color = pump_colors[pump_idx % len(pump_colors)]
                pump_idx += 1
                style = '-'
                lw = 2
            elif elem['type'] == 'Valve':
                color = valve_colors[valve_idx % len(valve_colors)]
                valve_idx += 1
                style = '--'
                lw = 2
            else:  # Pipe
                color = pipe_colors[pipe_idx % len(pipe_colors)]
                pipe_idx += 1
                style = ':'
                lw = 1.5
            
            # Negate outflow values for display
            neg_data = [-v for v in elem['data']]
            
            line, = ax.plot(times, neg_data, color=color, linewidth=lw, linestyle=style,
                           label=f"{elem['type']} {elem['id']} (Out)")
            
            stats = {
                'min': f"{min(neg_data):.2f}",
                'max': f"{max(neg_data):.2f}",
                'avg': f"{np.mean(neg_data):.2f}"
            }
            all_line_info.append({
                'line': line,
                'element': f"{elem['type']} {elem['id']}",
                'type': 'Outflow',
                'panel': 'Net Flow',
                'color': to_hex(color),
                'style': style,
                'stats': stats
            })
        
        # Plot totals if enabled
        if output_options['show_totals']:
            # Total Inflow (positive)
            line, = ax.plot(times, total_inflow, color='green', linewidth=3, linestyle='-',
                           label='TOTAL Inflow', alpha=0.8)
            stats = {
                'min': f"{min(total_inflow):.2f}",
                'max': f"{max(total_inflow):.2f}",
                'avg': f"{np.mean(total_inflow):.2f}"
            }
            all_line_info.append({
                'line': line,
                'element': 'TOTAL Inflow',
                'type': 'Total',
                'panel': 'Net Flow',
                'color': 'green',
                'style': 'solid',
                'stats': stats
            })
            
            # Total Outflow (negative)
            neg_total_outflow = [-v for v in total_outflow]
            line, = ax.plot(times, neg_total_outflow, color='red', linewidth=3, linestyle='-',
                           label='TOTAL Outflow', alpha=0.8)
            stats = {
                'min': f"{min(neg_total_outflow):.2f}",
                'max': f"{max(neg_total_outflow):.2f}",
                'avg': f"{np.mean(neg_total_outflow):.2f}"
            }
            all_line_info.append({
                'line': line,
                'element': 'TOTAL Outflow',
                'type': 'Total',
                'panel': 'Net Flow',
                'color': 'red',
                'style': 'solid',
                'stats': stats
            })
            
            # Total Demand (black dashed)
            line, = ax.plot(times, total_demand, color='black', linewidth=2.5, linestyle='--',
                           label='Total Demand', alpha=0.9)
            stats = {
                'min': f"{min(total_demand):.2f}",
                'max': f"{max(total_demand):.2f}",
                'avg': f"{np.mean(total_demand):.2f}"
            }
            all_line_info.append({
                'line': line,
                'element': 'Total Demand',
                'type': 'Demand',
                'panel': 'Net Flow',
                'color': 'black',
                'style': '--',
                'stats': stats
            })
        
        ax.set_ylabel(f'Flow ({flow_unit})', fontsize=10)
        ax.set_title('Net Flow (Inflows ↑ positive, Outflows ↓ negative)', fontsize=11, fontweight='bold')
        ax.axhline(y=0, color='gray', linestyle='-', linewidth=1, alpha=0.7)
        ax.grid(True, alpha=0.3)
        ax.legend(loc='upper right', fontsize=7, ncol=3)
    
    axes[-1].set_xlabel('Time (hrs)', fontsize=10)
    
    fig.suptitle(f'Pressure Zone Water Balance: {selected_zone}', fontsize=13, fontweight='bold', y=0.99)
    plt.tight_layout()
    
    return fig, axes

# Create initial plot
fig, axes = create_plot()

# === Main layout ===
main_frame = ttk.Frame(plot_window)
main_frame.pack(fill=tk.BOTH, expand=True)

toggle_frame = ttk.LabelFrame(main_frame, text="Panel Visibility (toggle to show/hide)")
toggle_frame.pack(fill=tk.X, padx=10, pady=5)

canvas_widget = None
canvas_agg = None
toolbar = None
canvas_frame = ttk.Frame(main_frame)
canvas_frame.pack(fill=tk.BOTH, expand=True)

def refresh_plot():
    global fig, axes, canvas_widget, canvas_agg, toolbar, all_line_info
    
    for widget in canvas_frame.winfo_children():
        widget.destroy()
    
    if fig is not None:
        plt.close(fig)
    
    fig, axes = create_plot()
    
    if fig is None:
        ttk.Label(canvas_frame, text="No panels selected or no data available.", 
                  font=('Segoe UI', 12)).pack(pady=50)
        refresh_legend_table()
        return
    
    canvas_agg = FigureCanvasTkAgg(fig, master=canvas_frame)
    canvas_agg.draw()
    canvas_widget = canvas_agg.get_tk_widget()
    canvas_widget.pack(side=tk.TOP, fill=tk.BOTH, expand=True)
    
    toolbar = NavigationToolbar2Tk(canvas_agg, canvas_frame)
    toolbar.update()
    
    refresh_legend_table()

def make_toggle_callback():
    def callback():
        refresh_plot()
    return callback

toggle_callback = make_toggle_callback()

storage_check = ttk.Checkbutton(toggle_frame, text=f"Storage ({len(storage_data)} tanks)", 
                                 variable=panel_vars['storage'], command=toggle_callback)
storage_check.pack(side=tk.LEFT, padx=15, pady=5)
if len(storage_data) == 0:
    storage_check.configure(state='disabled')

net_flow_check = ttk.Checkbutton(toggle_frame, text=f"Net Flow ({len(inflow_data)} in, {len(outflow_data)} out)", 
                                  variable=panel_vars['net_flow'], command=toggle_callback)
net_flow_check.pack(side=tk.LEFT, padx=15, pady=5)
if len(inflow_data) == 0 and len(outflow_data) == 0:
    net_flow_check.configure(state='disabled')

# === Legend/Stats Tables (side by side) ===
tables_container = ttk.Frame(main_frame)
tables_container.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)

# Left table: Storage & Pressure
storage_table_frame = ttk.LabelFrame(tables_container, text="Storage & Pressure")
storage_table_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0, 5))

storage_canvas = tk.Canvas(storage_table_frame, height=150)
storage_scrollbar = ttk.Scrollbar(storage_table_frame, orient="vertical", command=storage_canvas.yview)
storage_inner_frame = ttk.Frame(storage_canvas)

storage_inner_frame.bind("<Configure>", lambda e: storage_canvas.configure(scrollregion=storage_canvas.bbox("all")))
storage_canvas.create_window((0, 0), window=storage_inner_frame, anchor="nw")
storage_canvas.configure(yscrollcommand=storage_scrollbar.set)

storage_canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
storage_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

# Right table: Net Flow
flow_table_frame = ttk.LabelFrame(tables_container, text="Net Flow Balance")
flow_table_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(5, 0))

flow_canvas = tk.Canvas(flow_table_frame, height=150)
flow_scrollbar = ttk.Scrollbar(flow_table_frame, orient="vertical", command=flow_canvas.yview)
flow_inner_frame = ttk.Frame(flow_canvas)

flow_inner_frame.bind("<Configure>", lambda e: flow_canvas.configure(scrollregion=flow_canvas.bbox("all")))
flow_canvas.create_window((0, 0), window=flow_inner_frame, anchor="nw")
flow_canvas.configure(yscrollcommand=flow_scrollbar.set)

flow_canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
flow_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

visibility_vars = []

def build_table_content(inner_frame, items, col_widths):
    """Build table content for a set of items."""
    if not items:
        ttk.Label(inner_frame, text="No data").pack(pady=10)
        return []
    
    vars_list = []
    
    # Header row
    header_frame = ttk.Frame(inner_frame)
    header_frame.pack(fill=tk.X, padx=3, pady=2)
    
    headers = ['👁', 'Line', 'Element', 'Type', 'Min', 'Max', 'Avg']
    header_widths = [col_widths['visible'], col_widths['line_style'], col_widths['element'], 
                     col_widths['type'], col_widths['min'], col_widths['max'], col_widths['avg']]
    
    for header, width in zip(headers, header_widths):
        lbl = ttk.Label(header_frame, text=header, width=width, anchor='center', font=('Segoe UI', 8, 'bold'))
        lbl.pack(side=tk.LEFT, padx=1)
    
    ttk.Separator(inner_frame, orient='horizontal').pack(fill=tk.X, padx=3)
    
    def create_toggle_callback(line_obj, var):
        def toggle():
            visible = var.get()
            line_obj.set_visible(visible)
            if canvas_agg is not None:
                canvas_agg.draw()
        return toggle
    
    # Data rows
    for info in items:
        row_frame = ttk.Frame(inner_frame)
        row_frame.pack(fill=tk.X, padx=3, pady=1)
        
        var = tk.BooleanVar(value=True)
        vars_list.append((var, info))
        cb = ttk.Checkbutton(row_frame, variable=var, command=create_toggle_callback(info['line'], var), width=col_widths['visible'])
        cb.pack(side=tk.LEFT, padx=1)
        
        # Line style preview
        line_canvas_widget = tk.Canvas(row_frame, width=40, height=14, bg='white', highlightthickness=1, highlightbackground='gray')
        line_canvas_widget.pack(side=tk.LEFT, padx=1)
        
        if info['style'] == 'solid' or info['style'] == '-':
            line_canvas_widget.create_line(4, 7, 36, 7, fill=info['color'], width=2)
        elif info['style'] == '--':
            line_canvas_widget.create_line(4, 7, 12, 7, fill=info['color'], width=2)
            line_canvas_widget.create_line(16, 7, 24, 7, fill=info['color'], width=2)
            line_canvas_widget.create_line(28, 7, 36, 7, fill=info['color'], width=2)
        else:
            for x in range(4, 37, 6):
                line_canvas_widget.create_oval(x, 5, x+3, 9, fill=info['color'], outline=info['color'])
        
        ttk.Label(row_frame, text=info['element'], width=col_widths['element'], anchor='w', font=('Segoe UI', 8)).pack(side=tk.LEFT, padx=1)
        ttk.Label(row_frame, text=info['type'], width=col_widths['type'], anchor='w', font=('Segoe UI', 8)).pack(side=tk.LEFT, padx=1)
        
        for stat_key in ['min', 'max', 'avg']:
            ttk.Label(row_frame, text=info['stats'].get(stat_key, ''), width=col_widths[stat_key], 
                      anchor='center', font=('Segoe UI', 8)).pack(side=tk.LEFT, padx=1)
    
    return vars_list

def refresh_legend_table():
    global visibility_vars
    
    # Clear existing content
    for widget in storage_inner_frame.winfo_children():
        widget.destroy()
    for widget in flow_inner_frame.winfo_children():
        widget.destroy()
    visibility_vars = []
    
    if not all_line_info:
        ttk.Label(storage_inner_frame, text="No data to display").pack()
        ttk.Label(flow_inner_frame, text="No data to display").pack()
        return
    
    # Split items by panel
    storage_items = [info for info in all_line_info if info['panel'] == 'Storage']
    flow_items = [info for info in all_line_info if info['panel'] == 'Net Flow']
    
    # Column widths (slightly narrower for side-by-side layout)
    col_widths = {'visible': 2, 'line_style': 5, 'element': 16, 'type': 7, 'min': 8, 'max': 8, 'avg': 8}
    
    # Build both tables
    storage_vars = build_table_content(storage_inner_frame, storage_items, col_widths)
    flow_vars = build_table_content(flow_inner_frame, flow_items, col_widths)
    
    # Combine visibility vars
    visibility_vars = storage_vars + flow_vars

refresh_plot()

# === Button frame ===
button_frame = ttk.Frame(main_frame)
button_frame.pack(fill=tk.X, pady=5)

def show_all_lines():
    for var, info in visibility_vars:
        var.set(True)
        info['line'].set_visible(True)
    if canvas_agg is not None:
        canvas_agg.draw()

def hide_all_lines():
    for var, info in visibility_vars:
        var.set(False)
        info['line'].set_visible(False)
    if canvas_agg is not None:
        canvas_agg.draw()

ttk.Button(button_frame, text="Show All Lines", command=show_all_lines).pack(side=tk.LEFT, padx=10)
ttk.Button(button_frame, text="Hide All Lines", command=hide_all_lines).pack(side=tk.LEFT, padx=5)

def export_to_csv():
    """Export all graph data to a CSV file."""
    from tkinter import filedialog
    import csv
    
    # Prompt for save location
    default_filename = f"PZ_{selected_zone}_{selected_scenario}_WaterBalance.csv"
    filepath = filedialog.asksaveasfilename(
        title="Export Water Balance Data to CSV",
        defaultextension=".csv",
        filetypes=[("CSV files", "*.csv"), ("All files", "*.*")],
        initialfile=default_filename,
        initialdir=str(project_path)
    )
    
    if not filepath:
        return  # User cancelled
    
    try:
        with open(filepath, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            
            # Header info
            writer.writerow([f"Pressure Zone Water Balance Export"])
            writer.writerow([f"Zone: {selected_zone}"])
            writer.writerow([f"Scenario: {selected_scenario}"])
            writer.writerow([f"Flow Units: {flow_unit}"])
            writer.writerow([f"Tank Output: {tank_output}"])
            writer.writerow([])
            
            # Build header row with all data series
            header = ['Time (hrs)']
            data_series = []
            
            # Storage data (tank levels)
            for elem in storage_data:
                header.append(f"Tank {elem['id']} ({tank_output})")
                data_series.append(elem['data'])
            
            # Pressure extremes
            if pressure_extremes:
                if pressure_extremes['min_pressure_data']:
                    header.append(f"Min Pressure @ {pressure_extremes['min_jct_id']} (psi)")
                    data_series.append(pressure_extremes['min_pressure_data'])
                if pressure_extremes['max_pressure_data']:
                    header.append(f"Max Pressure @ {pressure_extremes['max_jct_id']} (psi)")
                    data_series.append(pressure_extremes['max_pressure_data'])
            
            # Inflow data
            for elem in inflow_data:
                header.append(f"{elem['type']} {elem['id']} Inflow ({flow_unit})")
                data_series.append(elem['data'])
            
            # Outflow data (as negative values for consistency with graph)
            for elem in outflow_data:
                header.append(f"{elem['type']} {elem['id']} Outflow ({flow_unit})")
                neg_data = [-v for v in elem['data']]
                data_series.append(neg_data)
            
            # Total Inflow
            header.append(f"TOTAL Inflow ({flow_unit})")
            data_series.append(total_inflow)
            
            # Total Outflow (negative)
            header.append(f"TOTAL Outflow ({flow_unit})")
            neg_total_outflow = [-v for v in total_outflow]
            data_series.append(neg_total_outflow)
            
            # Total Tank Flow
            header.append(f"Total Tank Flow ({flow_unit})")
            data_series.append(total_tank_flow)
            
            # Total Demand
            header.append(f"Total Demand ({flow_unit})")
            data_series.append(total_demand)
            
            # Write header
            writer.writerow(header)
            
            # Write data rows
            for i, time_val in enumerate(times):
                row = [f"{time_val:.2f}"]
                for series in data_series:
                    if series and i < len(series):
                        row.append(f"{series[i]:.4f}")
                    else:
                        row.append("")
                writer.writerow(row)
            
            # Summary statistics section
            writer.writerow([])
            writer.writerow(["Summary Statistics"])
            writer.writerow(["Element", "Type", "Min", "Max", "Avg"])
            
            for info in all_line_info:
                writer.writerow([
                    info['element'],
                    info['type'],
                    info['stats'].get('min', ''),
                    info['stats'].get('max', ''),
                    info['stats'].get('avg', '')
                ])
        
        # Show success message
        tk.messagebox.showinfo("Export Successful", f"Data exported to:\n{filepath}")
        print(f"✅ Data exported to: {filepath}")
        
    except Exception as e:
        tk.messagebox.showerror("Export Error", f"Failed to export data:\n{str(e)}")
        print(f"❌ Export failed: {e}")

ttk.Button(button_frame, text="📊 Export to CSV", command=export_to_csv).pack(side=tk.LEFT, padx=15)

instructions = ttk.Label(button_frame, 
                         text="💡 Inflows ↑ • Outflows ↓ • Demand = In - Out - Tank", 
                         font=('Segoe UI', 9))
instructions.pack(side=tk.LEFT, padx=10)

ttk.Button(button_frame, text="Close", command=plot_window.destroy).pack(side=tk.RIGHT, padx=10)

print("\n✅ Plot window opened!")
print("Interactive features:")
print("  - Panel visibility toggles (Storage, Net Flow)")
print("  - Zone pressure extremes (min/max pressure junctions)")
print("  - Individual line visibility checkboxes")
print("  - Total Demand = Inflow - Outflow - Tank Flow")
print("  - Show All / Hide All buttons")
print("  - Export to CSV")
print("  - Zoom/pan toolbar")

plot_window.mainloop()
plt.close('all')


