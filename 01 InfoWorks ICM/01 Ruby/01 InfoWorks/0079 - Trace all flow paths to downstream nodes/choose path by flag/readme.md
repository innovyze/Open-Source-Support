# Choose Path by Flag

Finds the downstream routes between two nodes, ranks them by the number of links that carry a user flag, and selects the route you choose. Routes can be saved as Selection Lists.

**Script:** `Choose Path by Flag.rb`

## Credit

This script is inspired by the path tracing scripts of **Marcos Perez**. His script is the base that this one builds on. Thank you, Marcos.

## Why

Master plans document each proposed measure with a screenshot and a longitudinal profile, usually along the longest route. Links in a measure carry a flag (for example `OP`). The route with the most flagged links normally matches the measure, and the other routes are listed in case a different one is better to plot.

It is also a quick way to select the route between two nodes and save it as a Selection List. This saves making many selections by hand in the long section profile tool. Leave the flag blank and the routes are simply ranked by length.

## Usage

1. Select the two end nodes in GeoPlan (order does not matter). If you do not select exactly two, the script asks for the node IDs.
2. Run the script and enter the flag value (for example `OP`), or leave it blank to ignore flags.
3. Review the table and enter the number of the route you want. It is selected in GeoPlan.
4. Choose whether to save it as a Selection List: **Chosen route** or **All routes**. Cancel skips.

Routes follow flow direction only. The script works out which node is upstream, and asks you if routes exist in both directions.

### Table columns

| Column | Meaning |
|--------|---------|
| Route | Rank. Route 1 has the most flagged links |
| Flagged | Flagged links / total links, for example `6/8`. A gap can mean a link was not flagged, or does not need to change |
| Length (m) | Total route length |
| Link types | Count of each link type on the route |

A tie note appears when a route ties with a higher-ranked one. The Ruby console also lists each route's nodes (upstream to downstream) and the unflagged links on the best and chosen routes.

### Ranking

1. Most flagged links
2. Shortest length (differences under 0.1 m are ignored)
3. Fewest links
4. Link ID order, so the ranking is repeatable

Routes that still tie are shown as separate rows and the script does not choose between them. This happens when routes pass through different ancillary links, such as a weir and an orifice.

### Selection Lists

- **Chosen route** saves one list. **All routes** saves one list per route in the table.
- Saved in the same Model Group as the network, named `Route_<upstream_id>_to_<downstream_id>_<route number>` (a numeric suffix is added if the name exists).
- The GeoPlan selection returns to your chosen route afterwards. Refresh the database tree to see the lists.
- If drop-downs are not available in your ICM version, the prompt falls back to a text box where you type `chosen` or `all`.

## Flag Fields

Flags are stored per field. By default only conduit flags are checked:

```ruby
FLAG_FIELDS = {
  'cond' => ['conduit_width_flag', 'conduit_height_flag']
}
```

To count flags on other link types, add an entry. The key is the link type in lower case, and the value is the list of flag fields to check:

```ruby
FLAG_FIELDS = {
  'cond'    => ['conduit_width_flag', 'conduit_height_flag'],
  'orifice' => ['diameter_flag']
}
```

The `orifice` / `diameter_flag` entry has been checked in a model. For other link types, confirm the link type and field names yourself. Links of a type with no entry never count as flagged, so a weir route and an orifice route tie on conduit flags and both are listed.

## Search Limits

```ruby
MAX_ROUTES = 10     # Routes listed in the table
MAX_STEPS = 20000  # Search steps allowed when listing alternative routes
MAX_DEPTH = 100    # Longest route (in nodes) the search will follow
```

- With no loops between the nodes, the best route is exact and the table reports how many routes exist in total.
- The other listed routes are the first ones found, not necessarily the next best. In a network with many routes, tied routes can fall outside the list. Raise `MAX_ROUTES` and `MAX_STEPS` if needed, at the cost of run time.
- With a loop between the nodes, the best route is the best one found within the limits. The table says so.

## Limitations

1. Only the fields in `FLAG_FIELDS` are checked.
2. Ranking is by flagged link count, not flagged length or continuity.
3. Downstream only. It will not find a route against link direction.
4. Length uses `conduit_length` where it exists, otherwise the straight-line distance between node coordinates.
5. It is not confirmed that the long section tool accepts a route containing non-conduit links. Test this in your own model.
6. Prompts block GeoPlan, so routes cannot be previewed while the table is open. Use the table and console, or save the routes and view them in the database tree.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No downstream route found | Check link directions and that both nodes are in the same network |
| Table note says no route carries the flag | Check the flag value and that the flag is in a field listed in `FLAG_FIELDS` |
| Selection Lists not saved | The network must be opened from a database. Check the console for the error |

## See Also

- `0052 - Select flow path between two nodes` for a single shortest path between two nodes
- The parent `0079` folder for tracing paths from every upstream terminal node to selected nodes
- `networks with loops` for all contributing paths in networks with loops

Generated using AI
