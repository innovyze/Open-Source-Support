# InfoWorks ICM SQL Context Files

This folder contains LLM-optimized context files for InfoWorks ICM SQL scripting, designed for Retrieval-Augmented Generation (RAG) systems and AI code assistants.

## For LLMs/AI Systems

**Start with:** `Instructions.md` - Contains file loading priorities, decision trees, and token budget guidance.

## For Human Developers

**Learning SQL for InfoWorks ICM?** See `00 Reference/SQL Combined.md` for the full official SQL language reference.

**Need fields for an InfoWorks network?** Load `InfoWorks_ICM_SQL_Schema_InfoWorks.md` + `InfoWorks_ICM_SQL_Schema_Common.md` for all `hw_*` field tables, manifests, results schema, and the Autodesk Help workflow.

**Need fields for a SWMM network?** Load `InfoWorks_ICM_SQL_Schema_SWMM.md` + `InfoWorks_ICM_SQL_Schema_Common.md` for all `sw_*` field tables, manifests, and key InfoWorks vs SWMM differences.

**Looking for working examples?** Browse the example scripts in:
- `../01 InfoWorks/` - 49 InfoWorks network SQL scripts
- `../02 SWMM/` - 10 SWMM network SQL scripts

## File Overview

| File | Purpose |
|------|---------|
| `Instructions.md` | LLM loading guide, token budgets, decision trees |
| `InfoWorks_ICM_SQL_Lessons_Learned.md` | Critical anti-patterns, gotchas, NOT-standard-SQL warnings |
| `InfoWorks_ICM_SQL_Function_Reference.md` | Function signatures, parameters, return types |
| `InfoWorks_ICM_SQL_Pattern_Reference.md` | Reusable code templates with PAT_SQL_NNN IDs |
| `InfoWorks_ICM_SQL_Syntax_Reference.md` | Language syntax, operators, data types, implicit joins |
| `InfoWorks_ICM_SQL_Schema_InfoWorks.md` | InfoWorks network object manifest and all `hw_*` field tables |
| `InfoWorks_ICM_SQL_Schema_SWMM.md` | SWMM network object manifest and all `sw_*` field tables |
| `InfoWorks_ICM_SQL_Schema_Common.md` | Common data fields, results schema, relationship paths, IW vs SWMM differences |
| `InfoWorks_ICM_SQL_Tutorial_Context.md` | Complete workflow examples |
| `InfoWorks_ICM_SQL_Error_Reference.md` | Error diagnosis and solutions |
| `InfoWorks_ICM_SQL_Glossary.md` | InfoWorks SQL terminology definitions |
| `InfoWorks_ICM_Database_Fields_Guide.md` | Workflow for locating Database field names via Autodesk Help; InfoWorks vs SWMM field distinctions |
| `00 Reference/` | Human reference materials (not for LLM loading) |

---

## Purpose & Evolution

This context file set is being **organically evolved and trialed** to improve the effectiveness of AI models (LLMs) in generating InfoWorks ICM-specific SQL queries. The syntax, patterns, and guidance contained herein have been extracted from the official InfoWorks ICM SQL documentation and validated against real-world scripts in the Open-Source-Support repository.

**Development Goals:**
- **Primary Goal**: Enable AI models to generate accurate, idiomatic InfoWorks ICM SQL queries
- **Development Approach**: Iterative enhancement based on official documentation and user feedback
- **Validation Method**: All patterns tested against actual repository examples
- **Scope**: Covers InfoWorks ICM SQL (InfoWorks networks, SWMM networks), with notes on InfoAsset Manager extensions

**Key Distinction:** InfoWorks ICM SQL is a **proprietary subset** of SQL, NOT standard ANSI SQL. It has unique syntax, operators, and capabilities tailored for spatial network operations, simulation results, and hydraulic modeling workflows.

---

## Contributing

When editing context files:

- Maintain consistent metadata headers (Load Priority, Last Updated, etc.)
- Avoid decorative formatting (emojis, excessive bold/italic)
- Keep code examples concise with clear CORRECT/WRONG labels
- Pattern IDs use format `PAT_SQL_XXX_NNN` for cross-file navigation

**Contact:** Alex Grist (Squark89) for suggestions, improvements, or new patterns.

---

**Last Updated:** March 19, 2026
