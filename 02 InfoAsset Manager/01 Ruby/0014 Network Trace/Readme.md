# Network Trace

Ruby examples for upstream and downstream tracing on InfoAsset Manager collection networks.

SQL tracing examples: [02 SQL/0001 Network Tracing](../../02%20SQL/0001%20Network%20Tracing/readme.md)

## Export Node Connectivity CSV

**Script:** [UIIE-ExportNodeConnectivity_CSV.rb](./Export%20Node%20Connectivity%20CSV/UIIE-ExportNodeConnectivity_CSV.rb)

For each seed node, trace upstream and downstream and export connected nodes (configurable `node_type` list) to CSV. Read-only against the network; field names and filters are set in the script header.

Full details: [Export Node Connectivity CSV/Readme.md](./Export%20Node%20Connectivity%20CSV/Readme.md)

## Trace scripts (GeoPlan selection)

| Script | Description |
|--------|-------------|
| [UI-NodeTraceUpstream.rb](./UI-NodeTraceUpstream.rb) | Upstream trace from one selected manhole; selects pipes and nodes |
| [UI-NodeTraceUpDownstream_ExcludeBy_PipeStatus.rb](./UI-NodeTraceUpDownstream_ExcludeBy_PipeStatus.rb) | Upstream or downstream; excludes pipes with status AB |
| [UI-NodeTraceUpDownstream_ExcludeBy_InvertLevel.rb](./UI-NodeTraceUpDownstream_ExcludeBy_InvertLevel.rb) | Up/down trace with invert-level exclusion |
| [UI-NodeTraceUpDownstream_ExcludeBy_SumPipeLength.rb](./UI-NodeTraceUpDownstream_ExcludeBy_SumPipeLength.rb) | Up/down trace stopping when summed pipe length exceeds a limit |
| [UI-NodeTraceUpstream_FindNode_WriteToField.rb](./UI-NodeTraceUpstream_FindNode_WriteToField.rb) | Trace upstream, find a matching node, write its ID to a field |
| [UI-PipesTraceUpstream_SumPipeLengths.rb](./UI-PipesTraceUpstream_SumPipeLengths.rb) | Sum upstream pipe lengths from selected pipe(s) |
| [UI-PipesTraceUpstream_SumPipeLengths_WriteToField.rb](./UI-PipesTraceUpstream_SumPipeLengths_WriteToField.rb) | Same; writes total length to a field |
| [UI-PipeTraceUpstream_SaveToSelectionList.rb](./UI-PipeTraceUpstream_SaveToSelectionList.rb) | Upstream trace from pipe(s) → Selection List |
| [UI-IncidentTraceUpstream-Incident.rb](./UI-IncidentTraceUpstream-Incident.rb) | Upstream trace from incident selection |
