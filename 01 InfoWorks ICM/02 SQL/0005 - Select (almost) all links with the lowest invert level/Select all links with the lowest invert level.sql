//Object: All Nodes
//Spatial Search: blank

//nvl is used to ensure a null value doesnt return 0
set $min_crest = nvl(min (ds_links.crest), 999999);
set $min_us_invert = nvl(min (ds_links.us_invert), 999999);
set $min_invert = nvl(min (ds_links.invert) , 999999);

//iif is used to select the largest value
set $min_min = iif($min_crest < $min_us_invert, $min_crest, $min_us_invert);
set $min_min = iif($min_min < $min_invert, $min_min, $min_invert);

set ds_links.user_number_10=1 where (
  ds_links.crest = $min_min OR
  ds_links.invert = $min_min OR
  ds_links.us_invert = $min_min
);

SELECT FROM [ALL LINKS] WHERE user_number_10 = 1;