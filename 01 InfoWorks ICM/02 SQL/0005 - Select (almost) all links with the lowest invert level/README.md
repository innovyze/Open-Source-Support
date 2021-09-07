# Select (almost) all links with the lowest invert level
This SQL demonstrates how to select between different link types based on a fields value. In this case we are interested in the invert level of different links. This is not straightforward as different link types have this information stored in different fields (i.e. weir = crest level, conduit = invert level). The SQL is not exhaustive for this reason but shows the workflow and syntax for achieving this using the "nvl" and "iif" functions. The "nvl" function ensures that we dont get false 0 values when null is return. The "iif" function is used to select which level is larger, as such and because its limited to comparing only two values, this will need to be used multiple times to cycle through all the possibilities.

### NVL
NVL(expr1,expr2)
The NVL function returns the value of expr2 if expr1 is null. If expr1 is not null, then NVL returns expr1.

### IIF 
IIF(condition,first alternative, second alternative) 
The IIF function returns the value of the second parameter if the first expression evaluates as true, otherwise returns the third. 

## Animation
![](gif001.gif)

## SQL Dialog
![](img001.png)
