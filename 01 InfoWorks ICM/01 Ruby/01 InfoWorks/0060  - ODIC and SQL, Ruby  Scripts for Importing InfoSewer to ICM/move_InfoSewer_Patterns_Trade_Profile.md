# SQL Script: Update Trade Profile Numbers for Subcatchments

This script is used to update the 'trade_profile' field for each unique 'user_text_1' in the 'subcatchment' table in an InfoWorks ICM database.

## Steps

1. The script initializes a variable for the trade profile number and a list for unique profile names.

2. It fetches unique 'user_text_1' values from the 'subcatchment' table and stores them in the list.

3. The script then starts a loop that goes through each unique profile name.

4. For each unique profile name, it does the following:
   - Prompts the user to enter a trade profile number for the current profile name.
   - Updates the 'trade_profile' field in the 'subcatchment' table with the user's input for all records where 'user_text_1' matches the current profile name.

5. The loop continues until it has processed all unique profile names.

## SQL Code

```sql
// ... (code omitted for brevity)

// Go through all unique profile names
WHILE $i <= LEN($trade_profile_names);
    // ... (code omitted for brevity)
 
    // Update trade profile number with user input
    UPDATE [subcatchment]
    SET trade_profile = $trade_profile
    WHERE user_text_1 = $user_text;
 
    // Go to next unique profile name
    LET $i = $i + 1;
WEND; // End of loop