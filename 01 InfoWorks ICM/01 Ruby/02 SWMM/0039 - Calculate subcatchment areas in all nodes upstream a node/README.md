# Calculate all subcatchment areas to nodes upstream of a node
This script takes a hard coded node `id` and calculates the total subcatchment areas contributing to each node upstream that node (including itself). It outputs results as a window in the UI.
## Limitations
This script only calculates areas for subcatchments discharging either to a node or a link. It does not calculate areas from subcatchments discharging to other types, such as multiple links, etc.

The algorythm behynd this script isn't particularly efficient, but it works surprisingly well even in long branches. Suggestions for refactoring the code or changes to the algorythm are welcome.

![](gif001.gif)
