# Find and Replace Flags

InfoAsset Manager **UI** Ruby scripts that replicate **Tools › Find and Replace Flags**: replace one or more data flag codes on every `*_flag` field in the open network (or on GeoPlan-selected objects only).

Works on Collection (CAMS), Distribution (WAMS), and Asset (AMS) networks.

Related example (InfoWorks ICM): [0031 - Replace flag in all objects in a model network](../../../01%20InfoWorks%20ICM/01%20Ruby/01%20InfoWorks/0031%20-%20Replace%20flag%20in%20all%20objects%20in%20a%20model%20network/).

---

## [UI-FindReplaceFlags.rb](./UI-FindReplaceFlags.rb)

General-purpose script with runtime prompts (up to 10 old/new pairs), matching the built-in tool when `FLAG_REPLACEMENTS` at the top of the file is left empty.

### Run from

**Network › Run Ruby Script…** with the target network open.

### Prompts

| Step | Purpose |
|------|---------|
| 1 | Number of flag codes to replace (1–10) |
| 2 | Old flag / new flag pairs |
| 3 | **Process whole network?** — when cleared, only objects in the current GeoPlan selection are updated (per table) |

### Configuration (optional)

Edit constants at the top of the script to skip prompts:

| Constant | Purpose |
|----------|---------|
| `FLAG_REPLACEMENTS` | Hash of `'old_code' => 'new_code'`. When non-empty, prompts for mappings are skipped. |
| `PROCESS_WHOLE_NETWORK` | `true` / `false` to fix scope without prompting. When `nil` (default), the scope prompt is shown. |

### Embedding in another script

Copy the `replace_flags_in_network` method (and `rows_for_table` if you use selection scope) into your migration script and call it inside your existing transaction:

```ruby
mapping = { '01' => '#A', '02' => '#A', '07' => 'AS' }
rows_written, flags_replaced = replace_flags_in_network(net, mapping, whole_network: true)
```

Only rows with at least one changed flag call `row.write`.

---

## [UI-FindReplaceFlags-Configured.rb](./UI-FindReplaceFlags-Configured.rb)

Example for bulk migration (for example reverse-engineering a collection network to an earlier flag scheme):

| Old flag | New flag |
|----------|----------|
| `01` | `#A` |
| `02` | `#A` |
| `07` | `AS` |

No prompts; always processes the **whole** open network. Edit `FLAG_REPLACEMENTS` for other projects.

---

## Notes

- Replacement is by **exact** flag code match on fields whose names match `/_flag/`. Blank flags are unchanged.
- New flag codes must be valid in your database flag list (same requirement as the UI tool).
- Run flag replacement **after** import or conversion steps that set flags you still intend to remap.
- Test on a copy of the network before running on production data, especially when processing the whole network.
