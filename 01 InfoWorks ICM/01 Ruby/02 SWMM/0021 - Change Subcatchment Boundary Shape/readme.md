# Change Subcatchment Boundary Shape

**Scripts by Bob Dickinson.**
*This readme was AI-generated based on the contents of the scripts.*

---

## `swmm_UI_script_ Change Subcatchment Boundaries.rb`

Reshapes the boundary polygon of each selected subcatchment to a regular n-sided polygon, fitted to the bounding box of its existing geometry. Works on both InfoWorks (`hw_subcatchment`) and SWMM (`sw_subcatchment`) networks.

### How it works

1. Prompts the user to select the network type (SWMM or InfoWorks) and a target polygon shape (3–15 sides).
2. For each selected subcatchment, calculates the bounding box of the current boundary.
3. Generates a regular polygon with the chosen number of sides, centred on and scaled to fit that bounding box.
4. Writes the new boundary and commits all changes in a single transaction.

### Supported shapes

| Sides | Shape |
|---|---|
| 3 | Triangle |
| 4 | Square |
| 5 | Pentagon |
| 6 | Hexagon |
| 7 | Heptagon |
| 8 | Octagon |
| 9 | Nonagon |
| 10 | Decagon |
| 11 | Hendecagon |
| 12 | Dodecagon |
| 13 | Tridecagon |
| 14 | Tetradecagon |
| 15 | Pentadecagon (default) |

### Usage

1. Select the subcatchments you want to reshape in the network.
2. Run the script from the ICM Ruby script runner.
3. In the prompt, toggle **Is this a SWMM network?** on or off as appropriate, then select the desired shape.
4. Only one shape should be selected — if multiple are checked, the script uses the first one selected.

### Note

The generated polygon is a mathematically regular shape scaled to the original subcatchment's bounding box. Width and height are treated independently, so the result is an ellipse-fitted polygon rather than a true regular polygon if the bounding box is not square.
