/* Full solution for forcemains
// Object Type: All Links
// Spatial Search: blank
*/

SET solution_model = 'Full', roughness_type = 'N', bottom_roughness_N = 0.014, top_roughness_N = 0.014 WHERE user_text_10 = 'Forcemain';

SET ds_node.node_type = 'Manhole', ds_node.flood_type = 'Sealed' WHERE (link_type = 'FIXPMP' OR link_type = 'ROTPMP')