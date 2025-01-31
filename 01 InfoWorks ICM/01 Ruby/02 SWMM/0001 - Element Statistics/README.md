# Link Length Analysis Script

This script analyzes the lengths of all links in an InfoWorks ICM model network and selects the smallest 10 percent of link lengths.

## How it Works

1. The script first accesses the current network and clears any existing selection.

2. It then iterates over each link in the network, storing the lengths of the links in an array.

3. The script calculates the threshold length for the smallest 10 percent of link lengths and the median length (50th percentile).

4. It then iterates over each link in the network again. If a link's length is below the threshold or median length, the link is selected and added to a list of selected links.

5. Finally, the script prints the minimum and maximum link lengths, the threshold length for the smallest 10 percent, the median length, the number of links below the threshold, and the total number of links. If no links were selected, it prints a message indicating this.

| ------------------------------------ | ------ |
| Description                          | Value  |
| ------------------------------------ | ------ |
| Minimum link length                  | 30.86  |
| Maximum link length                  | 357.94 |
| Threshold length for lowest 10%      | 63.57  |
| Median link length (50th percentile) | 164.21 |
| Number of links below threshold      | 4      |
| Total number of links                | 9      |
| ------------------------------------ | ------ |


## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically analyze the lengths of all links, select the smallest 10 percent of link lengths, and print the results.
