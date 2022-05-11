# Prompt Dialog Examples
## [PIPE_SelectByMaterial.sql](./PIPE_SelectByMaterial.sql)
Select Pipes with the pipe_material as selected in the prompt dialog, the prompt dialog is populated with the distinct pipe_material values on the Network.  

## [NODE_SelectManhole.sql](./NODE_SelectManhole.sql)
Select a Node with the Node ID entered into the prompt.  

## [CCTV-MHS_PartFieldValueSelection.sql](./CCTV-MHS_PartFieldValueSelection.sql)
Select surveys where the value entered into the prompt matches part of the surveyed_by field - so entering 'Steve' will select surveys with 'Steve', 'Steve Baker', 'Mr Steve' etc. in the surveyed_by field.  
This example helps to expand on selecting objects you are looking for if the value might vary slightly but you know at least part of the value you are looking for is consistent.  

## [PIPE_SelectPipesBetweenNodes.sql](./PIPE_SelectPipesBetweenNodes.sql)
Select Pipes between the two Nodes as entered into the prompt - a follow up prompt will state the selected Pipe count or state no pipes selected if there is no link between the Nodes.  

## [PIPE_SelectPipesBetweenUSNode-DSNode.sql](./PIPE_SelectPipesBetweenUSNode-DSNode.sql)
Select Pipes between the Upstream Node as selected/entered into the first prompt (which contains a drop-down list of all Node IDs on the Network) and the Downstream Node selected/entered into the second prompt (which contains a drop-down list of all Node IDs on the Network downstream of the selected US Node), then expand the selection to include the Nodes connected to the selected Links.  

