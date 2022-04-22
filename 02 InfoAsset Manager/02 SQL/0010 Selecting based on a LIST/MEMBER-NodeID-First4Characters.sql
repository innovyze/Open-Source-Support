/*Select Nodes where the Node ID's first 4 characters are in the list
//Object Type: All Nodes
//Spatial Search: blank
*/


LIST $Mylist = 'SS43','SS44','SS45','SS46','SS47','SS48';
SELECT WHERE MEMBER(LEFT(node_id,4),$Mylist);