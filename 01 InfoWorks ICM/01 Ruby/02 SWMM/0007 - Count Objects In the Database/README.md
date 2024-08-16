# Count Objects in the Database Script for InfoWorks ICM

This script counts the number of objects of each type in the current InfoWorks ICM database.

## How it Works

1. The script first retrieves the current user and prints a message indicating that it's starting.

2. It then defines a recursive method `get_child_objects` that counts the number of objects of each type. This method takes a model object, a hash of counts, and a depth as arguments. It increments the count for the model object's type, then calls itself for each of the model object's children.

3. The script initializes a hash of counts with a default value of 0 and a depth of 0.

4. It then retrieves the current database and iterates over each root model object in the database, calling `get_child_objects` for each one.

5. After all model objects have been processed, the script prints the number of objects of each type.

## Usage

To use this script, simply run it in the context of an open database in InfoWorks ICM. The script will automatically count the number of objects of each type in the database and print the counts.

                                0007 - Count Objects In the Database... 
                                Master Group: 7 object(s)
                                Model Group: 122 object(s)
                                Model Network: 67 object(s)
                                Custom Graph: 6 object(s)
                                Flow Survey: 5 object(s)
                                Observed Flow Event: 5 object(s)
                                Rainfall Event: 120 object(s)
                                Run: 62 object(s)
                                Sim: 211 object(s)
                                Selection List: 45 object(s)
                                Inflow: 21 object(s)
                                Waste Water: 6 object(s)
                                SWMM network: 46 object(s)
                                Label List: 28 object(s)
                                IWSW Climatology: 29 object(s)
                                SWMM run: 88 object(s)
                                SWMM sim: 178 object(s)
                                IWSW Time Patterns: 17 object(s)
                                Sim Stats: 12 object(s)
                                Statistics Template: 22 object(s)
                                Stored Query: 158 object(s)
                                Theme: 6 object(s)
                                Gridded Ground Model: 3 object(s)
                                Model Inference: 1 object(s)
                                Ground Infiltration: 11 object(s)
                                Trade Waste: 4 object(s)
                                Level: 5 object(s)
                                Pollutant Graph: 1 object(s)
                                IWSW Sim Stats: 2 object(s)
                                Observed Depth Event: 1 object(s)
                                Observed Velocity Event: 1 object(s)

