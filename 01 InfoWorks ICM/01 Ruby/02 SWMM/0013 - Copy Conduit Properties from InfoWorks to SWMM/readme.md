# Copy Conduit Properties from InfoWorks to SWMM

**Scripts by Bob Dickinson.**
*This readme was AI-generated based on the contents of the scripts.*

---

These two scripts work together as a workflow to transfer conduit hydraulic properties (capacity and gradient) from an open InfoWorks network into a SWMM network, and then analyse the hydraulic performance of selected SWMM links using those values.

## Scripts

### Step 1 — `sw_hw_UI_Set_Script_CN_BN.rb` (Set)

Run this script first. It requires two networks to be open simultaneously in ICM:

- **Background network (BN):** an ICM InfoWorks network containing conduits with populated `capacity` and `gradient` fields.
- **Current network (CN):** an ICM SWMM network whose conduits share the same IDs as the InfoWorks conduits (matched by `asset_id`).

The script reads `capacity` and `gradient` from each InfoWorks conduit and writes them into the matching SWMM conduit as:
- `user_number_9` — gradient
- `user_number_10` — full flow capacity

It prints the number of SWMM conduits updated.

### Step 2 — `sw_UI_Get_script_CN_BN.rb` (Get)

Run this script after the Set script, with one or more SWMM conduits selected and simulation results loaded. For each selected link it reports:

- Diameter and full flow capacity (from `user_number_10`)
- Per-timestep statistics (sum, mean, max, min) for the following result fields: `FLOW`, `MAX_FLOW`, `DEPTH`, `VELOCITY`, `MAX_VELOCITY`, `HGL`, `FLOW_VOLUME`, `FLOW_CLASS`, `CAPACITY`, `MAX_CAPACITY`, `SURCHARGED`, `ENTRY_LOSS`, `EXIT_LOSS`
- Normalised ratios where applicable:
  - **d/D** — depth relative to conduit diameter
  - **q/Q** — flow relative to full flow capacity

## Usage

1. Open the InfoWorks network as the background network and the SWMM network as the current network in ICM.
2. Run `sw_hw_UI_Set_Script_CN_BN.rb` to populate the SWMM conduit user fields with InfoWorks capacity and gradient data.
3. Run a simulation on the SWMM network and load the results.
4. Select the conduits of interest in the SWMM network.
5. Run `sw_UI_Get_script_CN_BN.rb` to print hydraulic performance statistics to the ICM output window.

## Notes

- The scripts match conduits between the two networks using `asset_id` (InfoWorks) and `id` (SWMM). These must be consistent across both networks for the transfer to work.
- `user_number_9` and `user_number_10` are generic user-defined fields. Ensure these fields are not already in use for other purposes in your SWMM network before running the Set script.
- The Get script skips result fields that do not exist for a given link rather than raising an error.
