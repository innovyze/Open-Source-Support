/* 
// Object Type: Subcatchment
// Spatial Search: blank
*/

// List for unique profile names
LIST $trade_profile_names String;

// Get unique profile names, excluding blank values
SELECT DISTINCT user_text_1 INTO $trade_profile_names FROM [subcatchment] WHERE user_text_1 <> NULL;

// Start with first unique profile name
LET $i = 1;

// Go through all unique profile names
WHILE $i <= LEN($trade_profile_names);
    // Current profile name
    LET $user_text = AREF($i, $trade_profile_names);

    // Automatically assign trade profile number
    LET $trade_profile = $i;

    // Update trade profile number
    UPDATE [subcatchment]
    SET trade_profile = $trade_profile
    WHERE user_text_1 = $user_text;

    // Go to next unique profile name
    LET $i = $i + 1;
WEND; // End of loop

// Assign a trade_profile of '0' for blank user_text_1
UPDATE [subcatchment]
SET trade_profile = 0
WHERE user_text_1 = NULL;

// Output a table mapping the trade profile number to the trade profile name
SELECT MIN(trade_profile) DP 0 AS "Trade Profile Number" GROUP BY user_text_1;