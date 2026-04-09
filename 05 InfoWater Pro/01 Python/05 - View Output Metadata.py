import json
from infowater.output.manager import Manager as iwp_output
import arcpy
from pathlib import Path

SCENARIO_NAME = "BASERUN"
aprx = arcpy.mp.ArcGISProject("CURRENT")
raw_output = Path(aprx.filePath).parent / f"{Path(aprx.filePath).stem}.OUT" / "SCENARIO" / SCENARIO_NAME / "HYDQUA.OUT"

def print_metadata_readable(metadata):
    """Print metadata in a clean, readable format"""
    
    print("=" * 80)
    print("INFOWATER PRO OUTPUT METADATA")
    print("=" * 80)
    
    # Network Info
    if 'Network' in metadata:
        print()
        print("📊 NETWORK INFORMATION:")
        print("-" * 80)
        network = metadata['Network']
        for key, value in network.items():
            if key != 'Titles':
                print(f"  {key:.<30} {value}")
    
    # Hydraulic Info
    if 'Hydraulic' in metadata:
        print()
        print("⚙️ HYDRAULIC SIMULATION:")
        print("-" * 80)
        hyd = metadata['Hydraulic']
        print(f"  Time Steps: {hyd.get('Time Count', 'N/A')}")
        print(f"  Duration: {hyd.get('Simulation Duration', 'N/A')} seconds")
        
        print()
        print("  📋 AVAILABLE FIELDS BY ELEMENT TYPE:")
        print("  " + "-" * 76)
        
        if 'Fields' in hyd:
            for element_type, fields in hyd['Fields'].items():
                # Get the string name of the element type
                element_name = element_type.value if hasattr(element_type, 'value') else str(element_type)
                print()
                print(f"  🔹 {element_name.upper()}:")
                
                for field_name, field_info in fields.items():
                    if isinstance(field_info, tuple) and len(field_info) > 0:
                        unit = field_info[0]
                        print(f"      • {field_name:.<35} [{unit}]")
    
    # Pump Cost Info
    if 'Pump Cost' in metadata:
        print()
        print("💰 PUMP COST ANALYSIS:")
        print("-" * 80)
        cost = metadata['Pump Cost']
        print(f"  Pump Count: {cost.get('Pump Count', 'N/A')}")
        print(f"  Demand Count: {cost.get('Demand Count', 'N/A')}")
        print(f"  Time Count: {cost.get('Time Count', 'N/A')}")
        
        if 'Fields' in cost:
            print()
            print("  📋 AVAILABLE COST FIELDS:")
            print("  " + "-" * 76)
            
            for cost_type, fields in cost['Fields'].items():
                cost_name = cost_type.value if hasattr(cost_type, 'value') else str(cost_type)
                print()
                print(f"  🔹 {cost_name.upper()}:")
                
                for field_name, field_info in fields.items():
                    if isinstance(field_info, tuple) and len(field_info) > 0:
                        unit = field_info[0]
                        print(f"      • {field_name:.<35} [{unit}]")
    
    print()
    print("=" * 80)

# Usage:
metadata = outman.get_metadata()
print_metadata_readable(metadata)
