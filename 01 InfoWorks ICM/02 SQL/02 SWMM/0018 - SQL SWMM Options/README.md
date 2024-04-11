# SWMM Options Query for InfoWorks ICM

This SQL script queries various options related to the Storm Water Management Model (SWMM) in an InfoWorks ICM model network.

## How it Works

The script selects the following options:

1. `allow_ponding`: Determines whether ponding is allowed in the model.
2. `force_main_equation`: Specifies the equation used for force main calculations.
3. `head_tolerance`: Specifies the head tolerance for the model.
4. `inertial_damping`: Specifies the inertial damping factor for the model.
5. `infiltration`: Specifies the infiltration method used in the model.
6. `max_trials`: Specifies the maximum number of trials for the model.
7. `min_slope`: Specifies the minimum slope for the model.
8. `min_surfarea`: Specifies the minimum surface area for the model.
9. `normal_flow_limited`: Specifies the normal flow limit for the model.
10. `otype`: Specifies the object type for the model.
11. `units`: Specifies the units used in the model.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically query the specified SWMM options and return their values.

![Alt text](image.png)