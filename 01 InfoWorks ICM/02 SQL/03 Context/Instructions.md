# InfoWorks ICM SQL Context Files - LLM Loading Instructions

**Last Updated:** March 20, 2026

## Quick Start

**CRITICAL:** Always load `Lessons_Learned.md` FIRST before generating ANY SQL query.

**Filename Convention:** Short names map to `InfoWorks_ICM_SQL_` prefix (e.g., `Lessons_Learned.md` → `InfoWorks_ICM_SQL_Lessons_Learned.md`)

**WARNING:** `00 Reference/` folder is for humans only - do NOT load for LLM queries

---

## Files & Loading Guide

| File | Purpose | Load When |
|------|---------|-----------|
| **Lessons_Learned** | Anti-patterns, gotchas, NOT-standard-SQL warnings | **ALWAYS first** |
| **Function_Reference** | Function signatures, parameters, return types, aggregates | Writing queries with functions, time-series results |
| **Pattern_Reference** | Code templates (PAT_SQL_XXX_NNN) | Implementing any functionality |
| **Syntax_Reference** | Language syntax, operators, data types, implicit joins | Syntax questions, data type behavior, join navigation |
| **Schema_InfoWorks** | InfoWorks network object manifest and all `hw_*` field tables | InfoWorks field lookup, object inventory for InfoWorks networks |
| **Schema_SWMM** | SWMM network object manifest and all `sw_*` field tables | SWMM field lookup, object inventory for SWMM networks |
| **Schema_Common** | Common data fields, results (`sim.*`/`tsr.*`), relationship paths, IW vs SWMM differences, Autodesk Help workflow | Results queries, field differences, navigation paths, fallback lookup |
| **Tutorial_Context** | Complete workflow examples | "How to" questions, complex multi-step tasks |
| **Error_Reference** | Error messages → causes → solutions | Debugging, user reports errors |
| **Glossary** | Terminology definitions | Unfamiliar terms |
| **Database_Fields_Guide** | Autodesk Help workflow for locating exact Database field names; InfoWorks vs SWMM field distinctions | When field name is unknown or need to verify UI label vs database column name |

---

## Load by Query Type

| Query Type | Files to Load |
|------------|---------------|
| Simple selection query | Lessons_Learned + Pattern + Schema_InfoWorks or Schema_SWMM |
| Data modification (SET/UPDATE/INSERT) | Lessons_Learned + Pattern + Syntax + Schema_InfoWorks or Schema_SWMM |
| Simulation results query (tsr.*, sim.*) | Lessons_Learned + Function + Pattern + Syntax + Schema_InfoWorks or Schema_SWMM |
| Network tracing (upstream/downstream) | Lessons_Learned + Pattern + Syntax + Schema_InfoWorks or Schema_SWMM |
| Blob table / array field operations | Lessons_Learned + Function + Syntax + Pattern + Schema_InfoWorks or Schema_SWMM |
| User interaction (PROMPT dialogs) | Lessons_Learned + Pattern |
| GROUP BY reporting / CSV export | Lessons_Learned + Pattern + Syntax + Schema_InfoWorks or Schema_SWMM |
| Spatial queries | Lessons_Learned + Pattern + Syntax + Schema_InfoWorks or Schema_SWMM |
| Scenario operations | Lessons_Learned + Pattern + Syntax + Schema_InfoWorks or Schema_SWMM |
| Debugging errors | Lessons_Learned + Error + Pattern + Schema_InfoWorks or Schema_SWMM |
| "How to..." / complete example | Lessons_Learned + Tutorial + Pattern + Schema_InfoWorks or Schema_SWMM |
| InfoWorks field name lookup | Schema_InfoWorks + Schema_Common |
| SWMM field name lookup | Schema_SWMM + Schema_Common |
| Schema dump / object inventory | Schema_InfoWorks + Schema_SWMM + Schema_Common |
| Terminology questions | Glossary |

---

## Network Type Scope — CRITICAL

This context folder covers **both InfoWorks (`hw_*`) and SWMM (`sw_*`) networks**.

**Step 1 — Identify the network type before generating any SQL:**
- If the user has not specified whether the network is InfoWorks or SWMM, **ask before proceeding**.
- Do not assume a network type based on the question alone.

**Step 2 — Stay within the correct scope once confirmed:**
- InfoWorks network → use `hw_*` field names and load `Schema_InfoWorks` only.
- InfoWorks network → use `hw_*` table names and examples from the `01 InfoWorks/` folder only.
- SWMM network → use `sw_*` field names and load `Schema_SWMM` only.
- SWMM network → use `sw_*` table names and examples from the `02 SWMM/` folder only.
- **Never mix `hw_*` and `sw_*` field names in the same query.**
- If a field or table cannot be found for the confirmed network type, state that it is unknown — do NOT fall back to the other network type's schema.

---

## Cross-Reference Navigation

Files use **PAT_SQL_XXX_NNN** pattern IDs for cross-linking:
- `Lessons_Learned` → references patterns and function names
- `Function_Reference` → "Pattern Ref" column links to Pattern_Reference
- `Error_Reference` → "Solution: See PAT_SQL_XXX_NNN" links to fixes
- `Pattern_Reference` → uses field names from Schema_InfoWorks or Schema_SWMM
- `Tutorial_Context` → combines multiple patterns into complete workflows
