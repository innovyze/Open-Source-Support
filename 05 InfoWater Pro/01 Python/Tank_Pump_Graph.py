import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from infowater.output.manager import Manager as OutMan
import arcpy
from pathlib import Path
import os

# Auto-detect project name and path from current ArcGIS Pro project
aprx = arcpy.mp.ArcGISProject("CURRENT")
project_path = Path(aprx.filePath).parent
project_name = Path(aprx.filePath).stem  # Gets filename without extension

# Find .OUT folder
out_folder = project_path / f"{project_name}.OUT" / "SCENARIO"

# List available scenarios
if out_folder.exists():
    scenarios = [d for d in os.listdir(out_folder) if os.path.isdir(out_folder / d)]
    print(f"Available scenarios: {scenarios}")
    scenario = scenarios[0] if scenarios else "Base"
else:
    print(f"Warning: Output folder not found at {out_folder}")
    scenario = "Base"

# Build path to output file
path = str(project_path / f"{project_name}.OUT" / "SCENARIO" / scenario / "HYDQUA.OUT")
print(f"Project: {project_name}")
print(f"Scenario: {scenario}")
print(f"Output path: {path}")

outman = OutMan(path)


# Popup dialog for selecting Tanks and Pumps
import tkinter as tk
from tkinter import ttk

# Get available tanks and pumps
tanks = outman.get_element_list("Tank")
pumps = outman.get_element_list("Pump")
times = outman.get_time_list()

# Store selections
selected_tanks = []
selected_pumps = []
summary_options = {'min': True, 'max': True, 'avg': True, 'range': False}

def open_selection_dialog():
    global selected_tanks, selected_pumps, summary_options
    
    # Create popup window
    root = tk.Tk()
    root.title("Select Tanks and Pumps")
    root.geometry("750x550")
    
    # Bring window to front
    root.lift()
    root.attributes('-topmost', True)
    root.after(100, lambda: root.attributes('-topmost', False))
    root.focus_force()
    
    # Lists frame
    lists_frame = ttk.Frame(root)
    lists_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
    
    # Tank selection frame
    tank_frame = ttk.LabelFrame(lists_frame, text="Tanks (Ctrl+Click for multiple)")
    tank_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5, pady=5)
    
    tank_listbox = tk.Listbox(tank_frame, selectmode=tk.MULTIPLE, exportselection=False)
    for t in tanks:
        tank_listbox.insert(tk.END, t)
    tank_listbox.pack(fill=tk.BOTH, expand=True)
    
    # Pump selection frame
    pump_frame = ttk.LabelFrame(lists_frame, text="Pumps (Ctrl+Click for multiple)")
    pump_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5, pady=5)
    
    pump_listbox = tk.Listbox(pump_frame, selectmode=tk.MULTIPLE, exportselection=False)
    for p in pumps:
        pump_listbox.insert(tk.END, p)
    pump_listbox.pack(fill=tk.BOTH, expand=True)
    
    # Summary options frame
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
        global selected_tanks, selected_pumps, summary_options
        selected_tanks = [tanks[i] for i in tank_listbox.curselection()]
        selected_pumps = [pumps[i] for i in pump_listbox.curselection()]
        summary_options = {
            'min': show_min.get(),
            'max': show_max.get(),
            'avg': show_avg.get(),
            'range': show_range.get()
        }
        root.destroy()
    
    # OK button
    ok_button = ttk.Button(root, text="Generate Plot", command=on_ok)
    ok_button.pack(pady=10)
    
    root.mainloop()
    return selected_tanks, selected_pumps, summary_options

# Open the popup
selected_tanks, selected_pumps, summary_options = open_selection_dialog()
print(f"Selected Tanks: {selected_tanks}")
print(f"Selected Pumps: {selected_pumps}")
print(f"Summary Options: {summary_options}")


# Generate the plot in a popup window
import tkinter as tk
from tkinter import ttk
import numpy as np
from matplotlib.backends.backend_tkagg import NavigationToolbar2Tk

print(f"Plotting - Tanks: {selected_tanks}, Pumps: {selected_pumps}")
print(f"Summary: {summary_options}")

if not selected_tanks and not selected_pumps:
    print("No tanks or pumps selected!")
else:
    # Create popup window for plot
    plot_window = tk.Tk()
    plot_window.title("Tank Levels and Pump Flows")
    plot_window.geometry("1100x750")
    plot_window.lift()
    plot_window.attributes('-topmost', True)
    plot_window.after(100, lambda: plot_window.attributes('-topmost', False))
    
    # Create matplotlib figure with space for table
    any_summary = any(summary_options.values())
    if any_summary:
        fig, (ax1, ax_table) = plt.subplots(2, 1, figsize=(12, 8), gridspec_kw={'height_ratios': [3, 1]})
        ax_table.axis('off')
    else:
        fig, ax1 = plt.subplots(figsize=(12, 6))
    
    # Store data for summary table
    table_data = []
    table_headers = ['Element', 'Type']
    if summary_options.get('min'): table_headers.append('Min')
    if summary_options.get('max'): table_headers.append('Max')
    if summary_options.get('avg'): table_headers.append('Avg')
    if summary_options.get('range'): table_headers.append('Range')
    
    # Store all lines for interactive toggling
    all_lines = []
    
    # Plot tanks (left y-axis) - blue shades
    if selected_tanks:
        colors_tank = plt.cm.Blues([(i+3)/(len(selected_tanks)+3) for i in range(len(selected_tanks))])
        for i, tank_id in enumerate(selected_tanks):
            tank_level = outman.get_time_data("Tank", tank_id, "Level")
            print(f"Tank {tank_id}: {len(tank_level)} data points")
            line, = ax1.plot(times, tank_level, color=colors_tank[i], linewidth=2, label=f'Tank {tank_id}')
            all_lines.append(line)
            # Collect summary data
            row = [f'Tank {tank_id}', 'Level (ft)']
            if summary_options.get('min'): row.append(f'{min(tank_level):.2f}')
            if summary_options.get('max'): row.append(f'{max(tank_level):.2f}')
            if summary_options.get('avg'): row.append(f'{np.mean(tank_level):.2f}')
            if summary_options.get('range'): row.append(f'{max(tank_level)-min(tank_level):.2f}')
            table_data.append(row)
        ax1.set_ylabel('Tank Level (ft)', color='blue')
        ax1.tick_params(axis='y', labelcolor='blue')
    
    ax1.set_xlabel('Time (hrs)')
    
    # Plot pumps (right y-axis) - red shades
    ax2 = None
    if selected_pumps:
        ax2 = ax1.twinx()
        colors_pump = plt.cm.Reds([(i+3)/(len(selected_pumps)+3) for i in range(len(selected_pumps))])
        for i, pump_id in enumerate(selected_pumps):
            pump_flow = outman.get_time_data("Pump", pump_id, "Flow")
            print(f"Pump {pump_id}: {len(pump_flow)} data points")
            line, = ax2.plot(times, pump_flow, color=colors_pump[i], linewidth=2, linestyle='--', label=f'Pump {pump_id}')
            all_lines.append(line)
            # Collect summary data
            row = [f'Pump {pump_id}', 'Flow (CFS)']
            if summary_options.get('min'): row.append(f'{min(pump_flow):.2f}')
            if summary_options.get('max'): row.append(f'{max(pump_flow):.2f}')
            if summary_options.get('avg'): row.append(f'{np.mean(pump_flow):.2f}')
            if summary_options.get('range'): row.append(f'{max(pump_flow)-min(pump_flow):.2f}')
            table_data.append(row)
        ax2.set_ylabel('Flowrate (CFS)', color='red')
        ax2.tick_params(axis='y', labelcolor='red')
    
    # Combine legends - make it draggable and outside the plot area initially
    lines1, labels1 = ax1.get_legend_handles_labels()
    if selected_pumps:
        lines2, labels2 = ax2.get_legend_handles_labels()
        legend = ax1.legend(lines1 + lines2, labels1 + labels2, 
                           loc='upper left', 
                           bbox_to_anchor=(1.15, 1.0),
                           framealpha=0.9,
                           edgecolor='gray',
                           fancybox=True,
                           shadow=True)
    elif selected_tanks:
        legend = ax1.legend(loc='upper left', 
                           bbox_to_anchor=(1.15, 1.0),
                           framealpha=0.9,
                           edgecolor='gray',
                           fancybox=True,
                           shadow=True)
    else:
        legend = None
    
    # Make legend draggable
    if legend:
        legend.set_draggable(True)
    
    # Enable click-to-toggle visibility on legend items
    line_map = {}  # Map legend lines to original lines
    if legend:
        for legend_line, orig_line in zip(legend.get_lines(), all_lines):
            legend_line.set_picker(5)  # 5 pts tolerance
            line_map[legend_line] = orig_line
        
        def on_pick(event):
            legend_line = event.artist
            if legend_line in line_map:
                orig_line = line_map[legend_line]
                visible = not orig_line.get_visible()
                orig_line.set_visible(visible)
                # Dim the legend line if hidden
                legend_line.set_alpha(1.0 if visible else 0.2)
                fig.canvas.draw()
        
        fig.canvas.mpl_connect('pick_event', on_pick)
    
    ax1.set_title('Tank Levels and Pump Flows\n(Drag legend to reposition • Click legend items to toggle visibility)')
    
    # Add summary table if any options selected
    if any_summary and table_data:
        table = ax_table.table(
            cellText=table_data,
            colLabels=table_headers,
            loc='center',
            cellLoc='center'
        )
        table.auto_set_font_size(False)
        table.set_fontsize(9)
        table.scale(1.2, 1.5)
        # Color header row
        for j, header in enumerate(table_headers):
            table[(0, j)].set_facecolor('#4472C4')
            table[(0, j)].set_text_props(color='white', fontweight='bold')
    
    # Adjust layout to make room for legend outside plot
    plt.tight_layout()
    fig.subplots_adjust(right=0.85)
    
    # Create frame for canvas and toolbar
    canvas_frame = ttk.Frame(plot_window)
    canvas_frame.pack(fill=tk.BOTH, expand=True)
    
    # Embed figure in tkinter window
    canvas = FigureCanvasTkAgg(fig, master=canvas_frame)
    canvas.draw()
    canvas.get_tk_widget().pack(side=tk.TOP, fill=tk.BOTH, expand=True)
    
    # Add navigation toolbar for zoom, pan, save
    toolbar = NavigationToolbar2Tk(canvas, canvas_frame)
    toolbar.update()
    
    # Instructions and close button frame
    button_frame = ttk.Frame(plot_window)
    button_frame.pack(fill=tk.X, pady=5)
    
    instructions = ttk.Label(button_frame, 
                            text="💡 Tip: Use toolbar to zoom/pan • Drag legend to move it • Click legend items to show/hide lines",
                            font=('Segoe UI', 9))
    instructions.pack(side=tk.LEFT, padx=10)
    
    close_btn = ttk.Button(button_frame, text="Close", command=plot_window.destroy)
    close_btn.pack(side=tk.RIGHT, padx=10)
    
    print("Plot window opened!")
    print("Interactive features: Draggable legend, click legend to toggle lines, zoom/pan toolbar")
    plot_window.mainloop()
    plt.close(fig)

