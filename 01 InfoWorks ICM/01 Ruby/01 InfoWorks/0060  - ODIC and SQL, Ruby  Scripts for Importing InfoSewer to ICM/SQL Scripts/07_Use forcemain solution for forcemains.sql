/* Forcemain solution for forcemains
// Object Type: All Links
// Spatial Search: blank
*/

SET solution_model = 'Forcemain', roughness_type = 'HW', us_headloss_type = 'NONE', ds_headloss_type = 'NONE' WHERE user_text_10 = 'Forcemain';

SET ds_node.node_type = 'Break' WHERE link_type = 'FIXPMP'