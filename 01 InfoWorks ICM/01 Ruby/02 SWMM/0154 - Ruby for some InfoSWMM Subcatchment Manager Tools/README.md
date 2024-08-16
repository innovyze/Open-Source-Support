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