Within the InfoAsset Manager & InfoWorks ICM interface, under the Selection menu there is a tool called 'Select Isolated Nodes'.  
According to the Help, the tool "Selects all nodes that are not connected to a link. (The current selection will be cleared prior to selection of isolated nodes.)"  

There is no equivalent method in the Ruby interface, the syntax of this script should action the same as the interface tool.  
It runs through All Nodes on the Network/Model and selects those which have a count of US/DS Links of zero, as well as a Lateral Pipe count of zero.  