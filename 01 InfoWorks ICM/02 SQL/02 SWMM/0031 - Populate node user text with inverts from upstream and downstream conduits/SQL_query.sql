UPDATE SELECTED [All Nodes] SET $selected=1;
UPDATE Node SET user_text_8 = '' WHERE $selected=1;
UPDATE Node SET user_text_9 = '' WHERE $selected=1;
SET ds_node.user_text_8 = IIF(
        ds_node.user_text_8 = NULL,
        FIXED(ds_invert,2) + FIXED(crest,2),
        ds_node.user_text_8 + ', ' + FIXED(ds_invert,2) + FIXED(crest,2)
    )
    WHERE ds_node.$selected = 1;
SET us_node.user_text_9 = IIF(
        us_node.user_text_9 = NULL,
        FIXED(us_invert,2) + FIXED(crest,2),
        us_node.user_text_9 + ', ' + FIXED(us_invert,2) + FIXED(crest,2)
    )
    WHERE us_node.$selected = 1;