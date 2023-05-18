//Object: Subcatchment
//Spatial Search: blank

//Requires a pre-selection of nodes
UPDATE [All Nodes] SET $node = 0;
UPDATE Selected [All Nodes] SET $node = 1;

SELECT FROM subcatchment WHERE node.$node = 1;