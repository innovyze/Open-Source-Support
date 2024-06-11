# read_swmm5_rpt.rb

# InfoSWMM, SWMM5, or ICM SWMM RPT File Processing Script

This Ruby script processes an InfoSWMM, SWMM5, or ICM SWMM RPT file and extracts various summary information. The script performs the following tasks:

1. Prompts the user to select an RPT file.
2. Reads the file line by line and stores each line in a hash with the line number as the key.
3. Extracts information from different sections of the RPT file:
   - Cross Section Summary
   - Link Summary
   - Link Flow Summary
   - Conduit Surcharge Summary
   - Flow Classification Summary
4. Stores the extracted information in separate hashes for each section.
5. Updates the corresponding row objects in the current network with the extracted information.
6. Prints the extracted summary lines for each section.
7. Filters the lines to only include those that contain the word "Summary" and prints the first 80 characters of each summary line.

## Dependencies

The script requires the following dependencies:
- `csv`
- `pathname`

## Usage

1. Load the script in the desired environment (e.g., WSApplication).
2. Call the `select_file` method to start the RPT file processing.
3. Select the desired RPT file when prompted.
4. The script will process the file, extract the summary information, update the corresponding row objects, and print the summary lines.

## Code Structure

The script is structured into several methods and sections:

- `select_file`: The main method that orchestrates the RPT file processing.
- RPT file reading and line storage in a hash.
- Extraction of information from different sections of the RPT file:
  - Cross Section Summary
  - Link Summary
  - Link Flow Summary
  - Conduit Surcharge Summary
  - Flow Classification Summary
- Updating the corresponding row objects with the extracted information.
- Printing the extracted summary lines for each section.
- Filtering and printing the summary lines.

## Notes

- The script assumes the existence of a `WSApplication` object and a `current_network` method to retrieve the current network.
- The script uses the `user_number_*` and `user_text_*` properties of the row objects to store the extracted information.
- The script commits the changes to the network after processing the RPT file.

Feel free to modify and enhance the script according to your specific requirements.