# SQL Script: Set Outfall Nodes

This SQL script is used to update certain nodes in a database to be 'Outfall' nodes.

## Steps

1. The script targets all nodes in the database. There is no spatial search condition, meaning it applies to all nodes regardless of their location.

2. It sets the `node_type` to 'Outfall' for all nodes where `user_text_3` is '2'. This means that any node with '2' in the `user_text_3` field will be classified as an 'Outfall' node.  This was set during the ODIC import process

3. It also sets `user_text_10` to 'Outfall' for all nodes where `user_text_3` is '2'. This provides an additional way to identify 'Outfall' nodes.  It is a record of what the node was in InfoSewer

## SQL Code

```sql
/* Set Outfall Nodes
//Object Type: All Nodes
//Spatial Search: blank
*/

SET node_type = 'Outfall'
WHERE user_text_3 = '2';
Set user_text_10='Outfall'
WHERE user_text_3 = '2';