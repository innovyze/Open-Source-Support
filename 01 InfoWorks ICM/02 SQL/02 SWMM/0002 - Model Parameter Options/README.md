# ICM SWMM Model Parameter Options

This SQL script displays the simulation options for a SWMM network in InfoWorks ICM. It reads the current option values into variables and presents them in a prompt dialog for quick reference.

> **Object type:** Run this script with **Options** selected as the object type in the SQL editor.

## Options Displayed

| Field | Description | Valid Values |
|---|---|---|
| `allow_ponding` | Whether surface ponding is enabled | Yes / No |
| `force_main_equation` | Equation used for pressurised flow | Hazen-Williams, Darcy-Weisbach |
| `head_tolerance` | Convergence tolerance for the solver | Numeric |
| `inertial_damping` | Inertial damping applied during dynamic wave routing | None, Partial, Full |
| `infiltration` | Infiltration model | Horton, Modified Horton, Green Ampt, Modified Green Ampt, Curve Number |
| `max_trials` | Maximum solver iterations per timestep | Numeric |
| `min_slope` | Minimum allowable conduit slope (%) | Numeric |
| `min_surfarea` | Minimum node surface area for depth calculations | Numeric |
| `normal_flow_limited` | Criterion used to limit normal flow | Slope, Froude, Both |
| `units` | Flow units for the model | CFS, MGD, CMS, LPS, MLD |
