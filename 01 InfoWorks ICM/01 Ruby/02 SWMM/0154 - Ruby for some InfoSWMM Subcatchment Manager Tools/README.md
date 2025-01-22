# Subcatchment Dimension Calculator

This Ruby script calculates the dimensions of subcatchments based on their boundary points. It computes the perimeter, maximum width, and maximum height for each subcatchment and updates the catchment dimension using a specified constant `K`. The script is designed to work with a specific data structure that includes subcatchment information and boundary points.

## Features

- **Perimeter Calculation**: Computes the perimeter of each subcatchment by summing the distances between consecutive boundary points.
- **Dimension Calculation**: Determines the maximum width and maximum height from the boundary points.
- **Dimension Update**: Updates the catchment dimension using the formula `K * max(max_width, max_height)` or `K * perimeter`, depending on the configuration.
- **Flexible `K` Value**: Supports `K` as a decimal value, allowing for more precise dimension calculations.

## Configuration

Before running the script, ensure that the following variables are configured according to your data and requirements:

- `SQRT_Area`: Set to `true` if the catchment dimension should be calculated using the square root of the area. Otherwise, set to `false`.
- `Width_Perimeter`: Set to `true` if the catchment dimension should be calculated using the perimeter. Otherwise, set to `false`.
- `K`: A constant used in the dimension calculation. Can be a decimal value.

## Usage

1. Ensure your Ruby environment is set up and that you have access to the data structure containing the subcatchment information.
2. Configure the script variables (`SQRT_Area`, `Width_Perimeter`, and `K`) as needed.
3. Run the script in your Ruby environment. The script will iterate over each subcatchment, calculate the necessary dimensions, and update the catchment dimension accordingly.

## Output

The script outputs the following information for each subcatchment:

- Subcatchment ID
- Calculated perimeter
- Maximum width
- Maximum height
- Updated catchment dimension

Additionally, it prints the total dimension changes before and after the update for all subcatchments.

## Note

This script is designed to work with a specific data structure and may require adjustments to fit your particular data setup. Ensure that the `boundary_array` and `subcatchment_id` are correctly defined and accessible within your data structure.


# SWMM5 Subcatchment Width Calculation Script

This script calculates the width of subcatchments in an InfoWorks ICM network for use in SWMM5 simulations. It offers multiple calculation methods and supports both USA and SI units.

## Script Functionality

1.  **User Input:**
    *   Prompts the user to select the unit system (USA or SI).
    *   Asks the user to choose a width calculation method from the following options:
        *   `Width = 1.7 * Max(Height, Width)`
        *   `Width = K * SQRT(Area)`
        *   `Width = K * Perimeter`
        *   `Width = Area / Flow Length`
    *   Allows the user to specify a value for the constant `K` (default is 1) for methods involving `K`.

2.  **Subcatchment Geometry Calculation:**
    *   Iterates through each subcatchment polygon in the network.
    *   Calculates the following geometric properties:
        *   `Perimeter`
        *   `Max Height` (maximum Y-dimension extent)
        *   `Max Width` (maximum X-dimension extent)
    *   Stores these values in a hash, keyed by the subcatchment ID.
    *   Outputs each subcatchment's ID, perimeter, max height, and max width to the console.

3.  **SWMM5 Width Calculation and Update:**
    *   Iterates through each subcatchment object.
    *   Calculates the `catchment_dimension` (representing SWMM5 width) based on the chosen method and user input.
        *   Applies unit conversion factors (43560 for USA, 10000 for SI) when necessary.
    *   Updates the `catchment_dimension` field of each subcatchment.
    *   Keeps track of the total `catchment_dimension` before and after the update.

4.  **Output and Summary:**
    *   Prints the total `catchment_dimension` (SWMM5 width) before and after the update, along with the difference.
    *   If a method involving `K` was used, outputs the formula used and the value of `K`.
    *   Commits the changes to the network.

## Key Variables

*   **`cn`:** The current network object.
*   **`USA`:** Boolean indicating whether USA units are selected.
*   **`SI`:** Boolean indicating whether SI units are selected.
*   **`K`:** User-defined constant (default 1) used in some calculation methods.
*   **`MaxHeight`, `SQRT_Area`, `Width_Perimeter`, `Flow_Length`:** Booleans representing the selected calculation method.
*   **`subcatchment_measurements`:** Hash storing the perimeter, max\_height, and max\_width of each subcatchment.
*   **`total_before`:** Total `catchment_dimension` before the update.
*   **`total_after`:** Total `catchment_dimension` after the update.

## Notes

*   The script assumes that the `hw_subcatchment` row objects have `total_area` and `boundary_array` (for polygons) populated.
*   The SWMM5 width is represented by the `catchment_dimension` field in the `hw_subcatchment` table.
*   The script uses InfoWorks ICM's Ruby API for network interaction.
*   Error handling is minimal; the script assumes valid input and network structure.
*   The script includes basic logging of its actions.
*   The script demonstrates transaction management (`transaction_begin` and `transaction_commit`).
