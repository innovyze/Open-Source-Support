CLEAR SELECTION;
COUNT(ds_links.*)=1 AND link_suffix>1;

//this part selects the links with suffix > 1 and a downstream pipe

SELECT COUNT(count(ds_links.*)=1 AND link_suffix>1) INTO $n;
PROMPT TITLE " Press OK to continue and change these link suffix or press Cancel to review";
PROMPT LINE $n "Number of selected suffix > 1";
PROMPT DISPLAY READONLY;

//this is the point where the user can cancel and review or select OK and continue

UPDATE
Conduit
SET  
(link_suffix = '1')
WHERE
link_suffix <> '1';
