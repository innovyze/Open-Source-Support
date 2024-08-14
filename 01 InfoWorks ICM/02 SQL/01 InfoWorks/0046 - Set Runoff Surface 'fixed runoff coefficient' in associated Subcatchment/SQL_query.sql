//Object: Subcatchment
//Spatial Search: blank

LIST $luids STRING;
SELECT DISTINCT oid INTO $luids FROM [Land Use];
LET $i=1;
WHILE $i<=LEN($luids);
    LET $luid=AREF($i,$luids);

    // Get the runoff surface id (runoff_index_1) from the land use object
    SELECT MAX(runoff_index_1) INTO $runoff_surface_id FROM [Land Use] WHERE oid=$luid GROUP BY runoff_index_1;

    // Get the fixed runoff coefficient from the runoff surface object
    SELECT MAX(runoff_coefficient) INTO $runoff_coefficient FROM [Runoff Surface] WHERE oid=$runoff_surface_id GROUP BY runoff_coefficient;

    // Update the subcatchment object with the runoff coefficient
    UPDATE Subcatchment SET user_number_1 = $runoff_coefficient WHERE land_use_id = $luid;

    LET $i=$i+1;
WEND;