UPDATE Node set user_text_1 = '';
UPDATE Node set user_text_2 = '';
UPDATE Node set user_text_3 = '';
SET ds_node.user_text_1=ds_node.user_text_1+IIF(LEN(ds_node.user_text_1)=0,'',',')+oid;
SET us_node.user_text_2=us_node.user_text_2+IIF(LEN(us_node.user_text_2)=0,'',',')+oid;
SET ds_node.user_text_3=ds_node.user_text_3+IIF(LEN(ds_node.user_text_3)=0,'',',')+IIF(otype="Weir",oid,"");
SET us_node.user_text_3=us_node.user_text_3+IIF(LEN(us_node.user_text_3)=0,'',',')+IIF(otype="Weir",oid,"");