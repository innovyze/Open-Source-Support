# Maintain only first and last river reach sections

This script is designed to modify the sections of selected river reaches in a network, specifically focusing on the first and last sections of each reach.

## How it Works

1. The script first accesses the current network of river reaches.
2. It then goes through each river reach in the network. If a river reach is selected:
    - It retrieves the sections of the river reach.
    - It identifies the keys (identifiers) of the first and last sections.
    - It creates a new array, `values_array`, to hold the data from the first and last sections.
    - It then goes through each section in the river reach. If the section is the first or last section, it adds the data of the section to the `values_array`.
    - After all sections have been processed, it resizes the sections to the number of entries in `values_array` divided by 6 (since each section has 6 fields: key, X, Y, Z, roughnessN, and newpanel).
    - It then goes through each section again, this time setting the data of the section to the corresponding data in `values_array`.
3. Once all selected river reaches have been processed, it writes the changes to the sections and the river reach.