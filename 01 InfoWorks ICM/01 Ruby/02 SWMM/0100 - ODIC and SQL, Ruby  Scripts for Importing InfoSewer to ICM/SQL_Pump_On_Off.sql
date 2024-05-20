/* All Pumps
// Object Type: All Pumps and Nodes
// Spatial Search: Yes
*/

/*  Update the switch_on_level and switch_off_level based on the chamber floor elevation
-- We're adding the chamber_floor value from the 'spatial' table to both switch levels */
SET switch_on_level = switch_on_level + spatial.chamber_floor, /*Update the switch_on_level by adding the chamber floor elevation */
    switch_off_level = switch_off_level + spatial.chamber_floor  /* Update the switch_off_level by adding the chamber floor elevation 
    
    
    -- Prompt user for input PROMPT TITLE "Define Text to Profile Mapping"; LET $user_text = ""; LET $trade_profile = 0; LET $count = 0; -- Loop for user inputWHILE $count < MAX([All Objects].$id) DO     PROMPT LINE $user_text "Enter a user text for object " + $count;     PROMPT LINE $trade_profile "Enter a profile number for object " + $count;     PROMPT DISPLAY;     -- Update trade_profile based on user input     UPDATE [All Objects]     SET trade_profile = $trade_profile    WHERE user_text_1 = $user_text;     LET $count = $count + 1; WEND;/

