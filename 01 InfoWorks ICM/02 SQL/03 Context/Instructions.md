# InfoWorks ICM SQL Context Files - LLM Loading Instructions

**Last Updated:** July 7, 2026

## Quick Start

**CRITICAL:** Always load `InfoWorks_ICM_SQL_Lessons_Learned.md` FIRST before generating ANY SQL query.

**Schema pairs:** For any query touching field names, results, or navigation, always load both files in the pair:
- InfoWorks: `InfoWorks_ICM_SQL_Schema_InfoWorks.md` + `InfoWorks_ICM_SQL_Schema_Common.md`
- SWMM: `InfoWorks_ICM_SQL_Schema_SWMM.md` + `InfoWorks_ICM_SQL_Schema_Common.md`

**WARNING:** `00 Reference/` folder is for humans only - do NOT load for LLM queries

**Official Help (latest):** When a field or fact is not in curated context files, see **Autodesk Product Help MCP** below. Field lookup: `InfoWorks_ICM_Database_Fields_Guide.md` Step 2.

---

## Files & Loading Guide

| File | Purpose | Load When |
|------|---------|-----------|
| **InfoWorks_ICM_SQL_Lessons_Learned.md** | Anti-patterns, gotchas, NOT-standard-SQL warnings | **ALWAYS first** |
| **InfoWorks_ICM_SQL_Function_Reference.md** | Function signatures, parameters, return types, aggregates | Writing queries with functions, time-series results |
| **InfoWorks_ICM_SQL_Pattern_Reference.md** | Code templates (PAT_SQL_XXX_NNN) | Implementing any functionality |
| **InfoWorks_ICM_SQL_Syntax_Reference.md** | Language syntax, operators, data types, implicit joins | Syntax questions, data type behavior, join navigation |
| **InfoWorks_ICM_SQL_Schema_InfoWorks.md** | InfoWorks network object manifest and all `hw_*` field tables | InfoWorks field lookup, object inventory for InfoWorks networks — always with **InfoWorks_ICM_SQL_Schema_Common.md** |
| **InfoWorks_ICM_SQL_Schema_SWMM.md** | SWMM network object manifest and all `sw_*` field tables | SWMM field lookup, object inventory for SWMM networks — always with **InfoWorks_ICM_SQL_Schema_Common.md** |
| **InfoWorks_ICM_SQL_Schema_Common.md** | Common data fields, `tsr.*` metadata/aggregate rules, relationship paths, IW vs SWMM differences | Always paired with `InfoWorks_ICM_SQL_Schema_InfoWorks.md` or `InfoWorks_ICM_SQL_Schema_SWMM.md`; object-specific `sim.*`/`tsr.*` fields are in the network schema file |
| **InfoWorks_ICM_SQL_Tutorial_Context.md** | Complete workflow examples | "How to" questions, complex multi-step tasks |
| **InfoWorks_ICM_SQL_Error_Reference.md** | Error messages → causes → solutions | Debugging, user reports errors |
| **InfoWorks_ICM_SQL_Glossary.md** | Terminology definitions | Unfamiliar terms |
| **InfoWorks_ICM_Database_Fields_Guide.md** | MCP Help lookup when field not in schema files; InfoWorks vs SWMM field distinctions | When field name is unknown or need to verify UI label vs database column name |

---

## Load by Query Type

| Query Type | Files to Load |
|------------|---------------|
| Simple selection query | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` + InfoWorks or SWMM schema pair |
| Data modification (SET/UPDATE/INSERT) | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` + `InfoWorks_ICM_SQL_Syntax_Reference.md` + InfoWorks or SWMM schema pair |
| Simulation results query (tsr.*, sim.*) | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Function_Reference.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` + `InfoWorks_ICM_SQL_Syntax_Reference.md` + InfoWorks or SWMM schema pair |
| Network tracing (upstream/downstream) | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` + `InfoWorks_ICM_SQL_Syntax_Reference.md` + InfoWorks or SWMM schema pair |
| Blob table / array field operations | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Function_Reference.md` + `InfoWorks_ICM_SQL_Syntax_Reference.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` + InfoWorks or SWMM schema pair |
| User interaction (PROMPT dialogs) | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` |
| GROUP BY reporting / CSV export | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` + `InfoWorks_ICM_SQL_Syntax_Reference.md` + InfoWorks or SWMM schema pair |
| Spatial queries | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` + `InfoWorks_ICM_SQL_Syntax_Reference.md` + InfoWorks or SWMM schema pair |
| Scenario operations | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` + `InfoWorks_ICM_SQL_Syntax_Reference.md` + InfoWorks or SWMM schema pair |
| Debugging errors | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Error_Reference.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` + InfoWorks or SWMM schema pair |
| "How to..." / complete example | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Tutorial_Context.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` + InfoWorks or SWMM schema pair |
| InfoWorks field name lookup | `InfoWorks_ICM_SQL_Schema_InfoWorks.md` + `InfoWorks_ICM_SQL_Schema_Common.md` |
| SWMM field name lookup | `InfoWorks_ICM_SQL_Schema_SWMM.md` + `InfoWorks_ICM_SQL_Schema_Common.md` |
| Unknown field / UI label vs database column | `InfoWorks_ICM_SQL_Lessons_Learned.md` + InfoWorks or SWMM schema pair + `InfoWorks_ICM_Database_Fields_Guide.md` |
| Schema dump / object inventory | `InfoWorks_ICM_SQL_Schema_InfoWorks.md` + `InfoWorks_ICM_SQL_Schema_SWMM.md` + `InfoWorks_ICM_SQL_Schema_Common.md` |
| Terminology questions | `InfoWorks_ICM_SQL_Glossary.md` |

InfoWorks schema pair = `InfoWorks_ICM_SQL_Schema_InfoWorks.md` + `InfoWorks_ICM_SQL_Schema_Common.md`. SWMM schema pair = `InfoWorks_ICM_SQL_Schema_SWMM.md` + `InfoWorks_ICM_SQL_Schema_Common.md`.

---

## Token Budget

Load the minimum tier needed. Large schema files dominate context cost. Tiers are cumulative — the Syntax tier includes Minimal files plus `InfoWorks_ICM_SQL_Syntax_Reference.md`.

| Tier | Files | When |
|------|-------|------|
| Minimal | `InfoWorks_ICM_SQL_Lessons_Learned.md` + `InfoWorks_ICM_SQL_Pattern_Reference.md` + network schema pair | Simple selection queries |
| Syntax | + `InfoWorks_ICM_SQL_Syntax_Reference.md` | Data modification, GROUP BY, spatial, tracing, clause structure, implicit joins |
| Results | + `InfoWorks_ICM_SQL_Function_Reference.md` | `tsr.*`, `sim.*`, aggregates, WHEN clauses |
| Debug | + `InfoWorks_ICM_SQL_Error_Reference.md` | User-reported failures |
| Full inventory | `InfoWorks_ICM_SQL_Schema_InfoWorks.md` + `InfoWorks_ICM_SQL_Schema_SWMM.md` + `InfoWorks_ICM_SQL_Schema_Common.md` | Schema dump or cross-network comparison only — avoid for routine queries |

Loading both network schemas is expensive — reserve for inventory / cross-network comparison only.

**Simulation results split:** `InfoWorks_ICM_SQL_Schema_Common.md` holds `tsr.*` metadata, aggregate rules, navigation paths, and the IW vs SWMM difference table. `InfoWorks_ICM_SQL_Schema_InfoWorks.md` or `InfoWorks_ICM_SQL_Schema_SWMM.md` holds object-specific `sim.*` and `tsr.*` field tables.

---

## Network Type Scope — CRITICAL

This context folder covers **both InfoWorks (`hw_*`) and SWMM (`sw_*`) networks**.

**Step 1 — Determine network type before generating any SQL:**
- If the user has not specified InfoWorks vs SWMM, **assume InfoWorks** (`hw_*`) and proceed.
- If the query context clearly indicates SWMM (e.g. `sw_*` fields, SWMM object names, or explicit "(SWMM)" references), use SWMM without asking.
- If signals conflict (mixed hw/sw hints), ask once to confirm before generating SQL.

**Step 2 — Stay within the correct scope once determined:**
- InfoWorks network → use `hw_*` field names; load `InfoWorks_ICM_SQL_Schema_InfoWorks.md` + `InfoWorks_ICM_SQL_Schema_Common.md`; use examples from the `01 InfoWorks/` folder only.
- SWMM network → use `sw_*` field names; load `InfoWorks_ICM_SQL_Schema_SWMM.md` + `InfoWorks_ICM_SQL_Schema_Common.md`; use examples from the `02 SWMM/` folder only.
- **Never mix `hw_*` and `sw_*` field names in the same query.**
- If a field or table cannot be found for the determined network type, state that it is unknown — do NOT fall back to the other network type's schema.

---

## Cross-Reference Navigation

Files use **PAT_SQL_XXX_NNN** pattern IDs for cross-linking:
- `InfoWorks_ICM_SQL_Lessons_Learned.md` → references patterns and function names
- `InfoWorks_ICM_SQL_Function_Reference.md` → "Pattern Ref" column links to `InfoWorks_ICM_SQL_Pattern_Reference.md`
- `InfoWorks_ICM_SQL_Error_Reference.md` → links to PAT_SQL patterns where a template is the canonical fix
- `InfoWorks_ICM_SQL_Pattern_Reference.md` → uses field names from `InfoWorks_ICM_SQL_Schema_InfoWorks.md` or `InfoWorks_ICM_SQL_Schema_SWMM.md`
- `InfoWorks_ICM_SQL_Tutorial_Context.md` → combines multiple patterns into complete workflows

---

## Autodesk Product Help MCP (optional)

Agents with the [Autodesk Product Help MCP server](https://help.autodesk.com/view/ADSKMCP/ENU/?guid=ADSKMCP_KnowledgeMcp_autodesk_product_help_mcp_server_html) can call `search_help_content` for official documentation not indexed in these context files. Use `get_available_products` to validate `release_code` when unsure.

**InfoWorks ICM:** `product_code=IWICMS`, `locale=en_US` unless the user specifies another locale.

**Release:** Use the user's ICM version when given. Otherwise use the latest release — on or after April 1 use `current_year + 1`, before April 1 use `current_year`. If unavailable, fall back to `current_year`.

**If MCP is not available:** Use curated context files only. Do not load `00 Reference/` or browse Help URLs. State unknown when a fact is not indexed locally.
