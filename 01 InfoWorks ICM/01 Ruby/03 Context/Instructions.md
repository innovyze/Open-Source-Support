# InfoWorks ICM Ruby Context Files - LLM Loading Instructions

**Last Updated:** January 16, 2026

## Quick Start

**CRITICAL:** Always load `Lessons_Learned.md` FIRST before generating ANY code.

**Filename Convention:** Short names map to `InfoWorks_ICM_Ruby_` prefix (e.g., `Lessons_Learned.md` → `InfoWorks_ICM_Ruby_Lessons_Learned.md`)

**WARNING:** `00 Reference/` folder is for humans only - do NOT load for LLM queries

---

## Files & Loading Guide

| File | Purpose | Load When |
|------|---------|-----------|
| **Lessons_Learned** | Anti-patterns, gotchas, critical warnings | **ALWAYS first** |
| **API_Reference** | Method signatures, parameters, return types | Exchange scripts, method questions |
| **Pattern_Reference** | 57 code templates (PAT_XXX_NNN) | Implementing any functionality |
| **Database_Reference** | Table names (hw_*, sw_*), Model Object Types | Using row_objects(), table names |
| **Tutorial_Context** | Complete workflow examples | "How to" questions, complex tasks |
| **Error_Reference** | Error messages → causes → solutions | Debugging, user reports errors |
| **Glossary** | Terminology definitions | Unfamiliar terms |

---

## Load by Query Type

| Query Type | Files to Load |
|------------|---------------|
| Exchange script (database/automation) | Lessons_Learned + API + Pattern + Database |
| UI script (current_network/editing) | Lessons_Learned + Pattern + Database |
| Debugging errors | Lessons_Learned + Error + Pattern |
| "How to..." / complete example | Lessons_Learned + Tutorial_Context + Pattern |
| Terminology questions | Glossary |

---

## Cross-Reference Navigation

Files use **PAT_XXX_NNN** pattern IDs for cross-linking:
- `Lessons_Learned` → references patterns and API methods
- `API_Reference` → "Pattern Ref" column links to Pattern_Reference
- `Error_Reference` → "Solution: See PAT_XXX_NNN" links to fixes
- `Pattern_Reference` → uses table names from Database_Reference
