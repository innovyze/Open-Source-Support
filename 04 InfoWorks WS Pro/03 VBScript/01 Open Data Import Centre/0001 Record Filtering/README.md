# Record Filtering

These scripts can be used with the ODIC to filter which objects are imported into a given model. This can be useful if importing/updating from large GIS data sets and you only want objects that meet a specific criteria to be imported.

There are 2 example types of script in this folder: a very basic object filtering script that filters based on a single field value (script IDs begining with **0**), and a slightly less basic object filtering script that filters based on 2 field values with a conditional (script IDs begining with **1**). These scripts utilise logic for the filtering that equates to double negatives; by this we mean that they aren't written to import objects where a condition (or several)
is true, but rather they're written to **not** import objects where a condtion (or several) **isn't** true, which results in the same effect.

The first scripts of each example type (**00** and **10**) are written in pure example syntax, with the input parameters written in `[SQUARE BRACKETS]` where:

* `[OBJECT TYPE]` is replaced by the WS Pro object table name 
* `[EXTERNAL FIELD NAME]` is replaced by the GIS/external file field name
* `[STRING VALUE]` is replaced by an appropriate string value
* `[NUMBER VALUE]` is replaced by an appropriate number value
* `[DATETIME VALUE]` is replaced by an appropriate datetime value

The additional scripts are generic examples of how the example types could look in a typical script.


| ID | Name                                         | Comment                                                                                                    |
|----|----------------------------------------------|------------------------------------------------------------------------------------------------------------|
|    |                                              |                                                                                                            |
| 00 | Filter [OBJECTS] by [FIELD]                  | Base syntax example. Code lines starting with `REM` are comment lines and aren't executed with the script. |
| 01 | Filter Hydrants by DMA                       | **Note** that string values require double quote marks `" "` around them.                                  |
| 02 | Filter Valves by Install Date                | **Note** that date values need hashes `# #` around them.                                                   |
| 03 | Filter Pipes by Drawing Number               | **Note** that number values **don't** need double quote marks around them.                                 |
|    |                                              |                                                                                                            |
| 10 | Filter [OBJECTS] by [FIELD] and/or [FIELD]   | Base syntax example. Code lines starting with `REM` are comment lines and aren't executed with the script. |
| 11 | Filter Pipes by DMA and Install Date         | See comments above on string and datetime values.                                                          |
| 12 | Filter Reservoirs by Pressure Zone or Volume | See comments above on string and number values.                                                            |