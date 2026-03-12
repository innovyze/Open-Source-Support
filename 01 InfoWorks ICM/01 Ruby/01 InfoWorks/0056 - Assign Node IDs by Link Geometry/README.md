# Assign Node IDs by Link Geometry

Automatically assigns upstream and downstream node IDs to links by finding the nearest node to each link endpoint using geometry data.

## Usage
1. Open your InfoWorks or SWMM network
2. Run the script from **Network > Run Ruby Script**
3. Configure options in the dialog:
   - **Which links to update:** Process only invalid links or re-snap all
   - **Model units:** Meters or feet
   - **Max search radius:** How far to search for nearest nodes
   - **Set node ID flag:** Optional flag to mark auto-assigned values (up to 4 characters)
4. Review results in Output window

## How It Works
- Reads `point_array` geometry from each link
- Uses first vertex to find nearest node for upstream
- Uses last vertex to find nearest node for downstream
- Expands search radius gradually (0.1 to max) for precision
- For InfoWorks networks: automatically resolves link ID conflicts by adjusting suffix
- Sets data flags (`us_node_id_flag`, `ds_node_id_flag`, `link_suffix_flag`) on updated links

## Use Cases
- Fixing links with missing or invalid node IDs
- Re-connecting links after node ID changes
- Setting up connectivity for imported link geometry
- Quality control: re-snapping all links to verify proper connections
- Tracking auto-assigned values with data flags for audit purposes

## Supported Networks
- **InfoWorks** networks (hw_conduit, hw_pump, hw_orifice, hw_weir)
- **SWMM** networks (sw_conduit, sw_pump, sw_orifice, sw_weir, sw_outlet)

## Link ID Conflict Resolution (InfoWorks Only)
InfoWorks link IDs follow the pattern `us_node_id.link_suffix`. When changing an upstream node ID would create a duplicate link ID, the script automatically finds a unique 1-character suffix (tries 1-9, then A-Z) and sets `link_suffix_flag` to track the change.

## See Also
For connecting **subcatchments** to nearest nodes, see folder **0004 - Connect subcatchment to nearest node**.
