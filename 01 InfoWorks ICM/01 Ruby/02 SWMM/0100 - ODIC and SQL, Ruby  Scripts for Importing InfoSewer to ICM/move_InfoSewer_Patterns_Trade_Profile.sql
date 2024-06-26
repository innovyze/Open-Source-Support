// Variables for trade profile number and unique profile names first time around
// Subcatchment Layer in ICM InfoWorks
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////

// List for unique profile names - updated to exclude blank values 2nd time around
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////

// List for unique profile names - updated to exclude blank values 3rd time around

// Variables for trade profile number and unique profile names
LET $trade_profile = 0;

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

    // Ask user for trade profile number for the first time
    IF $i = 1 THEN
        PROMPT TITLE "Define Trade Profile Number for each Profile Name";
        PROMPT LINE $user_text "Trade Profile Name (User_text_1)";
        PROMPT LINE $trade_profile "Trade Profile Number";
        PROMPT DISPLAY;
    ELSE
        // Automatically assign trade profile number for the second time
        LET $trade_profile = $i;
    ENDIF;

    // Update trade profile number with user input or automatic assignment
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