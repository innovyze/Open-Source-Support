/* 
// Object Type: Subcatchment
// Spatial Search: blank
*/

// Variables
LET $trade_profile = 0;

// List for unique profile names
LIST $trade_profile_names String;

// Get unique profile names
SELECT DISTINCT user_text_1 INTO $trade_profile_names FROM [subcatchment];

// Start with first unique profile name
LET $i = 1;

// Go through all unique profile names
WHILE $i <= LEN($trade_profile_names);
    // Current profile name
    LET $user_text = AREF($i, $trade_profile_names);

    // Ask user for trade profile number
    PROMPT TITLE "Define Trade Profile Number for each Profile Name";
    PROMPT LINE $user_text "Trade Profile Name (User_text_1)";
    PROMPT LINE $trade_profile "Trade Profile Number";
    PROMPT DISPLAY;

    // Update trade profile number with user input
    UPDATE [subcatchment]
    SET trade_profile = $trade_profile
    WHERE user_text_1 = $user_text;

    // Go to next unique profile name
    LET $i = $i + 1;
WEND; // End of loop

// Output a table mapping the trade profile number to the trade profile name
SELECT MIN(trade_profile) DP 0 AS "Trade Profile Number" GROUP BY user_text_1;