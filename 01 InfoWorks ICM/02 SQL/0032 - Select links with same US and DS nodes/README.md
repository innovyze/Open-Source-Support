# Select all links with same upstream and downstream nodes
This query finds all links in a network which share the same downstream and upstream nodes. 

It works by:
Compiling the upstream/downstream node id combinations from the network's links.

    SET $usds = us_node_id + ds_node_id;

And looping through that list to:

* Detect how many times the same US/DS node id combination occurs.

        SELECT count($usds=AREF($index,$list)) INTO $count;

* Select only the links whose US/DS node id combination occurs more than once.

        IIF($count>1,$usds=AREF($index,$list),'');

## SQL Dialog
![](img001.png)
