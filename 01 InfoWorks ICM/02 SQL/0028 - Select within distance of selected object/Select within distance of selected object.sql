//Object: All Nodes
//Spatial Search: blank

//selects all nodes while maintaining the selected river reaches
SPATIAL NONE;
SELECT ALL FROM [All Nodes];
//update the selected river reaches with a reference value
UPDATE [River reach] SET user_number_1 = 1;
//runs the spatial query
SPATIAL Distance Network [River reach] 100;
SELECT FROM [All Nodes] WHERE spatial.user_number_1 = 1;
//cleans up the user_number data
SPATIAL NONE;
UPDATE [River reach] SET user_number_1 = "";

//Apply Filter to Current Selection = active