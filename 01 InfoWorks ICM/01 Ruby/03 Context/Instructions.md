# InfoWorks ICM Ruby Context Files - LLM Loading Instructions

**Last Updated:** July 7, 2026

## Quick Start

**CRITICAL:** Always load `Lessons_Learned.md` FIRST before generating ANY code.

**Filename Convention:** Short names map to `InfoWorks_ICM_Ruby_` prefix (e.g., `Lessons_Learned.md` → `InfoWorks_ICM_Ruby_Lessons_Learned.md`)

**WARNING:** `00 Reference/` folder is for humans only - do NOT load for LLM queries

**Official Help (latest):** When an API method or field is not in curated context files, see **Autodesk Product Help MCP** below. Field lookup: `InfoWorks_ICM_Ruby_Database_Fields_Guide.md` Step 2.

---

## Files & Loading Guide

| File | Purpose | Load When |
|------|---------|-----------|
| **Lessons_Learned** | Anti-patterns, gotchas, critical warnings | **ALWAYS first** |
| **API_Reference** | Method signatures, parameters, return types | Exchange scripts, method questions |
| **Pattern_Reference** | 61 code templates (PAT_XXX_NNN, gap at 045) | Implementing any functionality |
| **Database_Reference** | Table names (hw_*, sw_*), Model Object Types; load **network section only** | Using row_objects(), table names |
| **Database_Fields_Guide** | MCP Help lookup for field names; UI label vs database field | When field name is unknown or need to verify UI label vs database column |
| **Tutorial_Context** | Complete workflow examples | "How to" questions, complex tasks |
| **Error_Reference** | Error messages → causes → solutions | Debugging, user reports errors |
| **Glossary** | Terminology definitions | Unfamiliar terms |

---

## Load by Query Type

| Query Type | Files to Load |
|------------|---------------|
| Exchange script (database/automation) | Lessons_Learned + API + Pattern + Database (network section) |
| UI script (current_network/editing) | Lessons_Learned + Pattern + Database (network section) |
| Debugging errors | Lessons_Learned + Error + Pattern + Database (network section) |
| "How to..." / complete example | Lessons_Learned + Tutorial_Context + Pattern |
| InfoWorks field name lookup | Database (hw section) + Database_Fields_Guide |
| SWMM field name lookup | Database (sw section) + Database_Fields_Guide |
| Table / Model Object Type lookup | Database (network section or Model Object Types) |
| Terminology questions | Glossary |
| Unknown API method | Lessons_Learned + API + Help MCP (see below) |
| Unknown field name | Lessons_Learned + Database_Fields_Guide + Help MCP (see below) |

---

## Token Budget

| Tier | Always load | Load when needed | Avoid unless asked |
|------|-------------|------------------|-------------------|
| 1 | Lessons_Learned | — | — |
| 2 | Pattern_Reference | Database (scoped network section), API (Exchange only) | — |
| 3 | — | Tutorial, Error, Glossary, Database_Fields_Guide | Full Database_Reference both network sections |
| — | — | Help MCP for unknown fields/API | `00 Reference/` |

---

## Network Type Scope — CRITICAL

This context folder covers **both InfoWorks (`hw_*`) and SWMM (`sw_*`) networks**.

**Step 1 — Determine network type before generating any code:**
- If the user has not specified InfoWorks vs SWMM, **assume InfoWorks** (`hw_*`) and proceed.
- If the query context clearly indicates SWMM (e.g. `sw_*` tables/fields, SWMM object names, or explicit "(SWMM)" references), use SWMM without asking.
- If signals conflict (mixed hw/sw hints), ask once to confirm before generating code.

**Step 2 — Stay within the correct scope once determined:**
- InfoWorks network → use `hw_*` table names; load `### InfoWorks Network` section of Database_Reference only; examples from `../01 InfoWorks/` only.
- SWMM network → use `sw_*` table names; load `### SWMM Network` and `### SWMM WSStructure (Blob / Nested) Fields` sections only; examples from `../02 SWMM/` only.
- Shared sections safe for both: Model Object Types, Universal Fields, Results Field Codes.
- **Never mix `hw_*` and `sw_*` table names in the same script.**
- If information cannot be found for the determined network type, state that it is unknown — do NOT fall back to the other network type's data.

---

## Cross-Reference Navigation

Files use **PAT_XXX_NNN** pattern IDs for cross-linking:
- `Lessons_Learned` → references patterns and API methods
- `API_Reference` → "Pattern Ref" column links to Pattern_Reference
- `Error_Reference` → "Solution: See PAT_XXX_NNN" links to fixes
- `Pattern_Reference` → uses table names from Database_Reference
- `Database_Fields_Guide` → uses Data Fields Topic from Database_Reference for MCP queries
- `Tutorial_Context` → combines multiple patterns into complete workflows

---

## Autodesk Product Help MCP (optional)

Agents with the [Autodesk Product Help MCP server](https://help.autodesk.com/view/ADSKMCP/ENU/?guid=ADSKMCP_KnowledgeMcp_autodesk_product_help_mcp_server_html) can call `search_help_content` for official documentation not indexed in these context files. Use `get_available_products` to validate `release_code` when unsure.

**InfoWorks ICM:** `product_code=IWICMS`, `locale=en_US` unless the user specifies another locale.

**Release:** Use the user's ICM version when given. Otherwise use the latest release — on or after April 1 use `current_year + 1`, before April 1 use `current_year`. If unavailable, fall back to `current_year`.

**If MCP is not available:** Use curated context files only. Do not load `00 Reference/` or browse Help URLs. State unknown when a fact is not indexed locally.
