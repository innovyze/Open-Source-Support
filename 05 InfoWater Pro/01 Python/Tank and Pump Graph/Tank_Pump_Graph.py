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
# SECTION 1: Auto-detect project and load output data
# =============================================================================
aprx = arcpy.mp.ArcGISProject("CURRENT")
project_path = Path(aprx.filePath).parent
project_name = Path(aprx.filePath).stem

out_folder = project_path / f"{project_name}.OUT" / "SCENARIO"

if out_folder.exists():
    scenarios = [d for d in os.listdir(out_folder) if os.path.isdir(out_folder / d)]
    print(f"Available scenarios: {scenarios}")
    scenario = scenarios[0] if scenarios else "Base"
else:
    print(f"Warning: Output folder not found at {out_folder}")
    scenario = "Base"

path = str(project_path / f"{project_name}.OUT" / "SCENARIO" / scenario / "HYDQUA.OUT")
print(f"Project: {project_name}")
print(f"Scenario: {scenario}")
print(f"Output path: {path}")

outman = OutMan(path)

# =============================================================================
# SECTION 2: Selection dialog for Tanks and Pumps
# =============================================================================
tanks = outman.get_element_list("Tank")
pumps = outman.get_element_list("Pump")
times = outman.get_time_list()

selected_tanks = []
selected_pumps = []
summary_options = {'min': True, 'max': True, 'avg': True, 'range': False}
output_options = {'tank_output': 'Level', 'pump_output': 'Flow', 'flow_unit': 'CFS'}  # Output type and unit options

def open_selection_dialog():
    global selected_tanks, selected_pumps, summary_options, output_options
    
    root = tk.Tk()
    root.title("Select Tanks and Pumps")
    root.geometry("800x620")
    root.lift()
    root.attributes('-topmost', True)
    root.after(100, lambda: root.attributes('-topmost', False))
    root.focus_force()
    
    lists_frame = ttk.Frame(root)
    lists_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
    
    # === Tank selection frame ===
    tank_frame = ttk.Frame(lists_frame)
    tank_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5, pady=5)
    
    # Tank header with title and subtitle
    tank_header = ttk.Frame(tank_frame)
    tank_header.pack(fill=tk.X)
    ttk.Label(tank_header, text="Tanks", font=('Segoe UI', 11, 'bold')).pack(anchor='w')
    ttk.Label(tank_header, text="Click to select tanks to include in graph", font=('Segoe UI', 8)).pack(anchor='w')
    
    tank_listbox = tk.Listbox(tank_frame, selectmode=tk.MULTIPLE, exportselection=False)
    for t in tanks:
        tank_listbox.insert(tk.END, t)
    tank_listbox.pack(fill=tk.BOTH, expand=True, pady=(5, 0))
    
    # Tank output type selection
    # Note: Field names must match InfoWater output fields exactly
    tank_output_frame = ttk.Frame(tank_frame)
    tank_output_frame.pack(fill=tk.X, pady=5)
    ttk.Label(tank_output_frame, text="Output:").pack(side=tk.LEFT, padx=5)
    tank_output_var = tk.StringVar(value="Level")
    ttk.Radiobutton(tank_output_frame, text="Level (ft)", variable=tank_output_var, value="Level").pack(side=tk.LEFT, padx=5)
    ttk.Radiobutton(tank_output_frame, text="% Volume", variable=tank_output_var, value="% Volume").pack(side=tk.LEFT, padx=5)
    
    # === Pump selection frame ===
    pump_frame = ttk.Frame(lists_frame)
    pump_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5, pady=5)
    
    # Pump header with title and subtitle
    pump_header = ttk.Frame(pump_frame)
    pump_header.pack(fill=tk.X)
    ttk.Label(pump_header, text="Pumps", font=('Segoe UI', 11, 'bold')).pack(anchor='w')
    ttk.Label(pump_header, text="Click to select pumps to include in graph", font=('Segoe UI', 8)).pack(anchor='w')
    
    pump_listbox = tk.Listbox(pump_frame, selectmode=tk.MULTIPLE, exportselection=False)
    for p in pumps:
        pump_listbox.insert(tk.END, p)
    pump_listbox.pack(fill=tk.BOTH, expand=True, pady=(5, 0))
    
    # Pump output type selection
    pump_output_frame = ttk.Frame(pump_frame)
    pump_output_frame.pack(fill=tk.X, pady=5)
    ttk.Label(pump_output_frame, text="Output:").pack(side=tk.LEFT, padx=5)
    pump_output_var = tk.StringVar(value="Flow")
    ttk.Radiobutton(pump_output_frame, text="Flow", variable=pump_output_var, value="Flow").pack(side=tk.LEFT, padx=5)
    ttk.Radiobutton(pump_output_frame, text="Status (0/1)", variable=pump_output_var, value="Status").pack(side=tk.LEFT, padx=5)
    
    # Pump flow unit selection (only visible when Flow is selected)
    pump_unit_frame = ttk.Frame(pump_frame)
    pump_unit_frame.pack(fill=tk.X, pady=2)
    ttk.Label(pump_unit_frame, text="Flow Units:").pack(side=tk.LEFT, padx=5)
    pump_unit_var = tk.StringVar(value="CFS")
    ttk.Radiobutton(pump_unit_frame, text="CFS", variable=pump_unit_var, value="CFS").pack(side=tk.LEFT, padx=3)
    ttk.Radiobutton(pump_unit_frame, text="GPM", variable=pump_unit_var, value="GPM").pack(side=tk.LEFT, padx=3)
    ttk.Radiobutton(pump_unit_frame, text="MGD", variable=pump_unit_var, value="MGD").pack(side=tk.LEFT, padx=3)
    ttk.Radiobutton(pump_unit_frame, text="Gal/day", variable=pump_unit_var, value="GPD").pack(side=tk.LEFT, padx=3)
    
    # === Summary statistics frame ===
    summary_frame = ttk.LabelFrame(root, text="Summary Statistics (show in table)")
    summary_frame.pack(fill=tk.X, padx=10, pady=5)
    
    show_min = tk.BooleanVar(value=True)
    show_max = tk.BooleanVar(value=True)
    show_avg = tk.BooleanVar(value=True)
    show_range = tk.BooleanVar(value=False)
    
    ttk.Checkbutton(summary_frame, text="Min", variable=show_min).pack(side=tk.LEFT, padx=20, pady=8)
    ttk.Checkbutton(summary_frame, text="Max", variable=show_max).pack(side=tk.LEFT, padx=20, pady=8)
    ttk.Checkbutton(summary_frame, text="Average", variable=show_avg).pack(side=tk.LEFT, padx=20, pady=8)
    ttk.Checkbutton(summary_frame, text="Range", variable=show_range).pack(side=tk.LEFT, padx=20, pady=8)
    
    def on_ok():
        global selected_tanks, selected_pumps, summary_options, output_options
        selected_tanks = [tanks[i] for i in tank_listbox.curselection()]
        selected_pumps = [pumps[i] for i in pump_listbox.curselection()]
        summary_options = {
            'min': show_min.get(),
            'max': show_max.get(),
            'avg': show_avg.get(),
            'range': show_range.get()
        }
        output_options = {
            'tank_output': tank_output_var.get(),
            'pump_output': pump_output_var.get(),
            'flow_unit': pump_unit_var.get()
        }
        root.destroy()
    
    ok_button = ttk.Button(root, text="Generate Plot", command=on_ok)
    ok_button.pack(pady=10)
    
    root.mainloop()
    return selected_tanks, selected_pumps, summary_options, output_options

selected_tanks, selected_pumps, summary_options, output_options = open_selection_dialog()
print(f"Selected Tanks: {selected_tanks}")
print(f"Selected Pumps: {selected_pumps}")
print(f"Output Options: {output_options}")
print(f"Summary Options: {summary_options}")

# =============================================================================
# SECTION 3: Generate interactive plot with integrated legend table
# =============================================================================
print(f"Plotting - Tanks: {selected_tanks}, Pumps: {selected_pumps}")
print(f"Output Options: {output_options}")
print(f"Summary: {summary_options}")

if not selected_tanks and not selected_pumps:
    print("No tanks or pumps selected!")
else:
    # Determine labels based on output options
    tank_output = output_options.get('tank_output', 'Level')
    pump_output = output_options.get('pump_output', 'Flow')
    flow_unit = output_options.get('flow_unit', 'CFS')
    
    # Flow unit conversion factors (from CFS)
    flow_conversions = {
        'CFS': 1.0,           # cubic feet per second (native)
        'GPM': 448.831,       # gallons per minute
        'MGD': 0.6463168,     # million gallons per day
        'GPD': 646316.8       # gallons per day
    }
    flow_factor = flow_conversions.get(flow_unit, 1.0)
    
    tank_label = 'Level (ft)' if tank_output == 'Level' else '% Volume'
    pump_label = f'Flow ({flow_unit})' if pump_output == 'Flow' else 'Status'
    
    # Build dynamic title
    tank_title_part = tank_label if selected_tanks else ''
    pump_title_part = pump_label if selected_pumps else ''
    if tank_title_part and pump_title_part:
        plot_title = f"Tank {tank_title_part} and Pump {pump_title_part}"
    elif tank_title_part:
        plot_title = f"Tank {tank_title_part}"
    else:
        plot_title = f"Pump {pump_title_part}"
    
    plot_window = tk.Tk()
    plot_window.title(plot_title)
    
    # Calculate window size: 60% of screen height, reasonable width
    screen_width = plot_window.winfo_screenwidth()
    screen_height = plot_window.winfo_screenheight()
    window_width = min(1200, int(screen_width * 0.7))
    window_height = int(screen_height * 0.6)
    
    # Center the window on screen
    x_pos = (screen_width - window_width) // 2
    y_pos = (screen_height - window_height) // 2
    plot_window.geometry(f"{window_width}x{window_height}+{x_pos}+{y_pos}")
    
    # Set minimum size to ensure table is visible
    plot_window.minsize(800, 500)
    
    plot_window.lift()
    plot_window.attributes('-topmost', True)
    plot_window.after(100, lambda: plot_window.attributes('-topmost', False))
    
    # Create figure - smaller default size to leave room for table
    fig, ax1 = plt.subplots(figsize=(10, 3.5))
    
    # Store line info for the interactive table
    line_info = []  # List of dicts: {line, element, type, color, style, stats}
    
    # Plot tanks (left y-axis) - blue shades
    skipped_elements = []
    if selected_tanks:
        colors_tank = plt.cm.Blues([(i+3)/(len(selected_tanks)+3) for i in range(len(selected_tanks))])
        for i, tank_id in enumerate(selected_tanks):
            try:
                tank_data = outman.get_time_data("Tank", tank_id, tank_output)
                if tank_data is None:
                    print(f"WARNING: Tank {tank_id} - No data for '{tank_output}'. Skipping.")
                    skipped_elements.append(f"Tank {tank_id}")
                    continue
                print(f"Tank {tank_id} ({tank_output}): {len(tank_data)} data points")
                line, = ax1.plot(times, tank_data, color=colors_tank[i], linewidth=2)
                
                stats = {}
                if summary_options.get('min'): stats['min'] = f'{min(tank_data):.2f}'
                if summary_options.get('max'): stats['max'] = f'{max(tank_data):.2f}'
                if summary_options.get('avg'): stats['avg'] = f'{np.mean(tank_data):.2f}'
                if summary_options.get('range'): stats['range'] = f'{max(tank_data)-min(tank_data):.2f}'
                
                line_info.append({
                    'line': line,
                    'element': f'Tank {tank_id}',
                    'type': tank_label,
                    'color': to_hex(colors_tank[i]),
                    'style': 'solid',
                    'stats': stats
                })
            except Exception as e:
                print(f"ERROR: Tank {tank_id} - {e}. Skipping.")
                skipped_elements.append(f"Tank {tank_id}")
                continue
        ax1.set_ylabel(f'Tank {tank_label}', color='blue')
        ax1.tick_params(axis='y', labelcolor='blue')
    
    ax1.set_xlabel('Time (hrs)')
    
    # Plot pumps (right y-axis) - red shades
    ax2 = None
    if selected_pumps:
        ax2 = ax1.twinx()
        colors_pump = plt.cm.Reds([(i+3)/(len(selected_pumps)+3) for i in range(len(selected_pumps))])
        for i, pump_id in enumerate(selected_pumps):
            try:
                pump_data_raw = outman.get_time_data("Pump", pump_id, pump_output)
                if pump_data_raw is None:
                    print(f"WARNING: Pump {pump_id} - No data for '{pump_output}'. Skipping.")
                    skipped_elements.append(f"Pump {pump_id}")
                    continue
                
                # Apply unit conversion for Flow data
                if pump_output == 'Flow':
                    pump_data = [v * flow_factor for v in pump_data_raw]
                    print(f"Pump {pump_id} ({pump_output} in {flow_unit}): {len(pump_data)} data points")
                else:
                    pump_data = pump_data_raw
                    print(f"Pump {pump_id} ({pump_output}): {len(pump_data)} data points")
                
                line, = ax2.plot(times, pump_data, color=colors_pump[i], linewidth=2, linestyle='--')
                
                stats = {}
                if summary_options.get('min'): stats['min'] = f'{min(pump_data):.2f}'
                if summary_options.get('max'): stats['max'] = f'{max(pump_data):.2f}'
                if summary_options.get('avg'): stats['avg'] = f'{np.mean(pump_data):.2f}'
                if summary_options.get('range'): stats['range'] = f'{max(pump_data)-min(pump_data):.2f}'
                
                line_info.append({
                    'line': line,
                    'element': f'Pump {pump_id}',
                    'type': pump_label,
                    'color': to_hex(colors_pump[i]),
                    'style': 'dashed',
                    'stats': stats
                })
            except Exception as e:
                print(f"ERROR: Pump {pump_id} - {e}. Skipping.")
                skipped_elements.append(f"Pump {pump_id}")
                continue
        ax2.set_ylabel(f'Pump {pump_label}', color='red')
        ax2.tick_params(axis='y', labelcolor='red')
    
    if skipped_elements:
        print(f"\n⚠️ Skipped elements (no data available): {', '.join(skipped_elements)}")
    
    ax1.set_title(plot_title)
    plt.tight_layout()
    
    # === Main layout frames ===
    canvas_frame = ttk.Frame(plot_window)
    canvas_frame.pack(fill=tk.BOTH, expand=True)
    
    canvas = FigureCanvasTkAgg(fig, master=canvas_frame)
    canvas.draw()
    canvas.get_tk_widget().pack(side=tk.TOP, fill=tk.BOTH, expand=True)
    
    toolbar = NavigationToolbar2Tk(canvas, canvas_frame)
    toolbar.update()
    
    # === Interactive Legend/Stats Table ===
    table_frame = ttk.LabelFrame(plot_window, text="Legend & Statistics (click checkboxes to toggle visibility)")
    table_frame.pack(fill=tk.X, padx=10, pady=5)
    
    # Build column headers
    columns = ['visible', 'line_style', 'element', 'type']
    col_headings = {'visible': '👁', 'line_style': 'Line', 'element': 'Element', 'type': 'Type'}
    if summary_options.get('min'): 
        columns.append('min')
        col_headings['min'] = 'Min'
    if summary_options.get('max'): 
        columns.append('max')
        col_headings['max'] = 'Max'
    if summary_options.get('avg'): 
        columns.append('avg')
        col_headings['avg'] = 'Avg'
    if summary_options.get('range'): 
        columns.append('range')
        col_headings['range'] = 'Range'
    
    # Create a frame for each row (checkbox + canvas + labels)
    visibility_vars = []  # Store BooleanVars for checkboxes
    
    # Header row
    header_frame = ttk.Frame(table_frame)
    header_frame.pack(fill=tk.X, padx=5, pady=2)
    
    col_widths = {'visible': 3, 'line_style': 6, 'element': 12, 'type': 10, 'min': 8, 'max': 8, 'avg': 8, 'range': 8}
    
    for col in columns:
        if col == 'visible':
            lbl = ttk.Label(header_frame, text=col_headings[col], width=col_widths[col], anchor='center', font=('Segoe UI', 9, 'bold'))
        elif col == 'line_style':
            lbl = ttk.Label(header_frame, text=col_headings[col], width=col_widths[col], anchor='center', font=('Segoe UI', 9, 'bold'))
        else:
            lbl = ttk.Label(header_frame, text=col_headings[col], width=col_widths[col], anchor='center', font=('Segoe UI', 9, 'bold'))
        lbl.pack(side=tk.LEFT, padx=2)
    
    ttk.Separator(table_frame, orient='horizontal').pack(fill=tk.X, padx=5)
    
    # Data rows
    def create_toggle_callback(line_obj, var):
        def toggle():
            visible = var.get()
            line_obj.set_visible(visible)
            canvas.draw()
        return toggle
    
    for info in line_info:
        row_frame = ttk.Frame(table_frame)
        row_frame.pack(fill=tk.X, padx=5, pady=1)
        
        # Visibility checkbox
        var = tk.BooleanVar(value=True)
        visibility_vars.append(var)
        cb = ttk.Checkbutton(row_frame, variable=var, command=create_toggle_callback(info['line'], var), width=col_widths['visible'])
        cb.pack(side=tk.LEFT, padx=2)
        
        # Line style preview (small canvas)
        line_canvas = tk.Canvas(row_frame, width=50, height=16, bg='white', highlightthickness=1, highlightbackground='gray')
        line_canvas.pack(side=tk.LEFT, padx=2)
        
        # Draw line preview
        if info['style'] == 'solid':
            line_canvas.create_line(5, 8, 45, 8, fill=info['color'], width=2)
        else:  # dashed
            line_canvas.create_line(5, 8, 15, 8, fill=info['color'], width=2)
            line_canvas.create_line(20, 8, 30, 8, fill=info['color'], width=2)
            line_canvas.create_line(35, 8, 45, 8, fill=info['color'], width=2)
        
        # Element name
        ttk.Label(row_frame, text=info['element'], width=col_widths['element'], anchor='w').pack(side=tk.LEFT, padx=2)
        
        # Type
        ttk.Label(row_frame, text=info['type'], width=col_widths['type'], anchor='w').pack(side=tk.LEFT, padx=2)
        
        # Stats columns
        for stat_key in ['min', 'max', 'avg', 'range']:
            if stat_key in info['stats']:
                ttk.Label(row_frame, text=info['stats'][stat_key], width=col_widths[stat_key], anchor='center').pack(side=tk.LEFT, padx=2)
    
    # === Button frame ===
    button_frame = ttk.Frame(plot_window)
    button_frame.pack(fill=tk.X, pady=5)
    
    # Show All / Hide All buttons
    def show_all():
        for var, info in zip(visibility_vars, line_info):
            var.set(True)
            info['line'].set_visible(True)
        canvas.draw()
    
    def hide_all():
        for var, info in zip(visibility_vars, line_info):
            var.set(False)
            info['line'].set_visible(False)
        canvas.draw()
    
    ttk.Button(button_frame, text="Show All", command=show_all).pack(side=tk.LEFT, padx=10)
    ttk.Button(button_frame, text="Hide All", command=hide_all).pack(side=tk.LEFT, padx=5)
    
    instructions = ttk.Label(button_frame, text="💡 Use toolbar to zoom/pan • Toggle checkboxes to show/hide lines", font=('Segoe UI', 9))
    instructions.pack(side=tk.LEFT, padx=20)
    
    close_btn = ttk.Button(button_frame, text="Close", command=plot_window.destroy)
    close_btn.pack(side=tk.RIGHT, padx=10)
    
    print("Plot window opened!")
    print("Interactive features: Checkbox toggles, Show All/Hide All, zoom/pan toolbar")
    plot_window.mainloop()
    plt.close(fig)


