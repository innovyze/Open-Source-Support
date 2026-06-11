---
applyTo: "**"
---

When using the autodesk-product-help MCP server, use the mapping below to resolve the correct
product_code, release_code, and locale based on the workspace folder or the product the user mentions.

Default locale: en_US (unless the user specifies otherwise).

## Folder-to-product mapping

| Workspace Folder        | Product Name      | product_code | Notes                              |
|-------------------------|-------------------|--------------|------------------------------------|
| `01 InfoWorks ICM/`     | InfoWorks ICM     | IWICMS       |                                    |
| `02 InfoAsset Manager/` | InfoAsset Manager | INFOAMAN     |                                    |
| `03 ICMLive/`           | ICMLive           | —            | Not available in Autodesk Help MCP |
| `04 InfoWorks WS Pro/`  | InfoWorks WS Pro  | IWWSPRO      |                                    |
| `05 InfoWater Pro/`     | InfoWater Pro     | INFWP        |                                    |
| `06 XPSWMM/`            | XPSWMM            | —            | Not available in Autodesk Help     |

Note: XPSWMM has no Autodesk Help documentation. ICMLive has Autodesk Help documentation but it is not available through this MCP server. 10/04/2026.

## Release code logic

The latest release_code follows the Autodesk release calendar:
- If today's date is **on or after April 1** of the current year, the latest release is `current_year + 1`.
- If today's date is **before April 1**, the latest release is `current_year`.
- If the derived release_code is not available for the product (e.g. not listed in the catalog),
  fall back to `current_year`.

Use this rule to determine the default release_code dynamically when no version is specified.

## Rules

1. If the user's active file is inside one of the folders above, default to that product automatically.
2. If the user names a product (e.g. "InfoAsset Manager", "ICMLive", "WS Pro"), match it to the
   table and use the corresponding product_code.
3. Use the release code logic above to determine the latest release unless the user specifies a version.
4. If no folder or product context is available, ask the user which product they mean.
