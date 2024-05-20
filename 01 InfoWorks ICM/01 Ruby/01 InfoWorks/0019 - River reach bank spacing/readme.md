# River reach bank spacing

This script is designed to analyze a set of river reaches in a network and identify any that have segments shorter than a specified threshold.

## How it Works

1. It first accesses the current network of river reaches.
2. It sets a threshold distance (in this case, 5.0 units).
3. It then goes through each river reach in the network.
4. For each river reach, it looks at the left or right bank and calculates the distance between each pair of consecutive points.
5. If it finds a segment of the river reach that is shorter than the threshold distance, it flags that river reach for review, marking it as "selected", and prints out a message with the details of the river reach and the short segment.