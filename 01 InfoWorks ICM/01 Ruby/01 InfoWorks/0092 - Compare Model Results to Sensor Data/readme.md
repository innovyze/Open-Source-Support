# Compare Model Results to Sensor Data

This script compares InfoWorks ICM modelled results against measured sensor data for a set of pipe locations, displaying the variance and generating graphs within the ICM UI.

Original source: https://github.com/ngerdts7/ICM_Tools123

## How it Works

1. The script prompts the user to select a folder containing the sensor data text files.

2. A `locations` hash defines the mapping between pipe IDs in the model and their corresponding sensor files. Each entry also specifies the result field to compare (`us_flow`), a marker symbol, and a colour for the scatter plot.

3. For each location, the script:
   - Reads the sensor data from the text file, trimmed to match the number of model timesteps.
   - Fetches the modelled result from the corresponding conduit (`hw_conduit`).
   - Computes the mean squared difference (variance) between the modelled and measured values.
   - Generates a line graph overlaying the modelled and measured time series, with the variance shown in the title.

4. After all locations are processed, a single scatter plot is generated showing modelled vs measured flow across all locations, with each location rendered in a distinct colour and marker symbol.

## Usage

1. Open a network in InfoWorks ICM with simulation results loaded.
2. Edit the `locations` hash in the script to match your pipe IDs, sensor filenames, and preferred colours/symbols.
3. Ensure all sensor text files are present in the same folder and contain one numeric value per line corresponding to each model timestep.
4. Run the script from the ICM UI. A folder selection dialog will appear, followed by one line graph per location and a final scatter plot.

## Notes

- This script uses the `hw_conduit` table, which is specific to InfoWorks networks. It will not work on SWMM networks without substituting `sw_conduit`.
- Sensor files are expected to be plain text with one value per line. The script slices the sensor array to match the model timestep count if the files are longer.
- The variance reported is the mean squared difference, not the root mean squared error (RMSE). Divide by the number of timesteps and take the square root if RMSE is needed.
