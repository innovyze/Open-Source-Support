# InfoWorks SWMM Networks
These SQLs are intended to work with the InfoWorks SWMM networks

![Alt text](image.png)

# Manhole Area Calculation Script for InfoSewer

This SQL script calculates the area of manholes in an InfoSewer model network.

## How it Works

The script operates in two parts, each targeting a different component of a manhole:

1. **Chamber Area Calculation**: The script sets the `chamber_area` to the area of a circle with a diameter of 4 units (presumably feet or meters, depending on your model's units). It then selects all nodes where `user_text_10` is 'Manhole', effectively applying this area to all manholes in the network.

2. **Shaft Area Calculation**: Similarly, the script sets the `shaft_area` to the area of a circle with a diameter of 4 units. It then selects all nodes where `user_text_10` is 'Manhole', applying this shaft area to all manholes in the network.

## Usage

To use this script, simply run it in the context of an open network in InfoSewer. The script will automatically calculate and assign the chamber and shaft areas for all manholes in the network.