# ICM SWMM Network Options

This code selects various options related to the SWMM (Storm Water Management Model) network in InfoWorks ICM. The selected options are:

- `allow_ponding`: Surface ponding option (Yes, No, 1, or 0)
- `force_main_equation`: Force main equation (Hazen-Williams or Darcy-Weisbach)
- `head_tolerance`: Head tolerance used to determine solver convergence
- `inertial_damping`: Inertial damping option (None, Partial, or Full)
- `infiltration`: Infiltration model (Horton, Modified Horton, Green Ampt, Modified Green Ampt, or Curve Number)
- `max_trials`: Maximum number of trials allowed for the solver to converge
- `min_slope`: Minimum conduit slope (%)
- `min_surfarea`: Minimum surface area used for nodes when computing changes in water depth
- `normal_flow_limited`: Normal flow limited option (Slope, Froude, or Both)
- `units`: Units used in the model (CFS, MGD, CMS, LPS, or MLD)

The selected options are stored into corresponding variables using the `INTO` clause.

The code also includes a prompt dialog titled "ICM SWMM Network Options" with various prompt lines displaying information about each option. The prompt lines are assigned using `LET` statements and displayed using the `PROMPT LINE` command.

Finally, the `PROMPT DISPLAY` command is used to display the prompt dialog to the user.
