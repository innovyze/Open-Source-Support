# Summary of Step25_User_123_ICM_Scenario_csv.rb

This script imports a CSV file containing scenarios for an InfoSewer or InfoSWMM network, deletes all existing scenarios in the current network (except the 'Base' scenario), and adds the scenarios from the CSV file to the network.

## Steps

1. **Prompt for folder**: The script prompts the user to select a folder containing the CSV file.

2. **Read CSV file**: The script reads the CSV file named 'scenario.csv' in the selected folder. It excludes certain headers and stores each row as a hash in an array.

3. **Delete existing scenarios**: The script deletes all scenarios in the current network, except for the 'Base' scenario.

4. **Add new scenarios**: The script iterates over the array of hashes (each representing a row in the CSV file). For each hash, it checks if the 'ID' value is not 'BASE'. If it's not, it adds a new scenario to the network with the 'ID' value as the scenario name.

5. **Print results**: The script prints the total number of scenarios added to the network.

This script is useful for updating the scenarios in an InfoSewer or InfoSWMM network based on a CSV file. It allows for easy bulk addition of scenarios.
|--------------|------------|----------------|---------------|--------------|---------------|
| Release Date | Versions   | Developers     | FEMA Approval | LID Controls | Major Release |
|--------------|------------|----------------|---------------|--------------|---------------|
| 08/07/2023   | SWMM 5.2.4 | EPA            | Yes           | Yes          |               |
| 03/03/2023   | SWMM 5.2.3 | EPA            | Yes           | Yes          |               |
| 12/01/2022   | SWMM 5.2.2 | EPA            | Yes           | Yes          |               |
| 08/11/2022   | SWMM 5.2.1 | EPA            | Yes           | Yes          |               |
| 02/01/2022   | SWMM 5.2   | EPA            | Yes           | Yes          | Yes           |
| 07/20/2020   | SWMM 5.1.015 | EPA          | Yes           | Yes          |               |
| 02/18/2020   | SWMM 5.1.014 | EPA          | Yes           | Yes          | Yes           |
| 08/09/2018   | SWMM 5.1.013 | EPA          | Yes           | Yes          | Yes           |
| 03/14/2017   | SWMM 5.1.012 | EPA          | Yes           | Yes          | Yes           |
| 08/22/2016   | SWMM 5.1.011 | EPA          | Yes           | Yes          | Yes           |
| 08/20/2015   | SWMM 5.1.010 | EPA          | Yes           | Yes          | Yes           |
| 04/30/2015   | SWMM 5.1.009 | EPA          | Yes           | Yes          | Yes           |
| 04/17/2015   | SWMM 5.1.008 | EPA          | Yes           | Yes          |               |
| 10/09/2014   | SWMM 5.1.007 | EPA          | Yes           | Yes          |               |
| 06/02/2014   | SWMM 5.1.006 | EPA          | Yes           | Yes          |               |
| 03/27/2014   | SWMM 5.1.001 | EPA          | Yes           | Yes          |               |
| 04/21/2011   | SWMM 5.0.022 | EPA          | Yes           | Yes          |               |
| 08/20/2010   | SWMM 5.0.019 | EPA          | Yes           | Yes          |               |
| 03/19/2008   | SWMM 5.0.013 | EPA          | Yes           | Yes          |               |
| 08/17/2005   | SWMM 5.0.005 | EPA, CDM     | Yes           | No           |               |
| 11/30/2004   | SWMM 5.0.004 | EPA, CDM     | No            | No           |               |
| 11/25/2004   | SWMM 5.0.003 | EPA, CDM     | No            | No           |               |
| 10/26/2004   | SWMM 5.0.001 | EPA, CDM     | No            | No           |               |
| 2001–2004    | SWMM5        | EPA, CDM     | No            | No           |               |
| 1988–2004    | SWMM4        | UF, OSU, CDM | No            | No           |               |
| 1981–1988    | SWMM3        | UF, CDM      | No            | No           |               |
| 1975–1981    | SWMM2        | UF           | No            | No           |               |
| 1969–1971    | SWMM1        | UF, CDM, M&E | No            | No           |               |
|--------------|------------|----------------|---------------|--------------|---------------|