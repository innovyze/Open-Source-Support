# InfoWorks ICM Ruby Context Files - LLM Usage Guide

**Last Updated:** December 2, 2025

## 🎯 Quick Start for LLMs

**CRITICAL:** Always load `Lessons_Learned.md` FIRST before generating ANY InfoWorks ICM Ruby code.

### File Loading Priority

🔴 **CRITICAL (Always Load First)**
1. **Lessons_Learned.md** (~730 lines) - Anti-patterns, gotchas, critical warnings

🟡 **CORE (Load for Most Code Generation)**
2. **API_Reference.md** (~1,050 lines) - Method signatures, parameters, return types
3. **Pattern_Reference.md** (~1,120 lines) - 56 code templates (PAT_XXX_NNN)

🟢 **LOOKUP/CONDITIONAL (Load As Needed)**
4. **Database_Reference.md** (~390 lines) - Table names, Model Object Types
5. **Tutorial_Context.md** (~1,070 lines) - Complete examples, workflows
6. **Error_Reference.md** (~490 lines) - Error diagnosis and solutions
7. **Glossary.md** (~380 lines) - Terminology definitions

⚠️ **Archive folder**: Human reference only - do NOT load for LLM queries

---

## 📋 Loading Decision Tree

### Step 1: ALWAYS Load First
- ✅ `Lessons_Learned.md` - Prevents 90% of errors

### Step 2: Choose Based on Query Type

**Exchange Script (database/automation)**
- ✅ `API_Reference.md` (method signatures)
- ✅ `Pattern_Reference.md` (code templates)
- ✅ `Database_Reference.md` (table names)
- ⚠️ `Tutorial_Context.md` (if complex workflow)

**UI Script (network editing)**
- ✅ `Pattern_Reference.md` (code templates)
- ✅ `Database_Reference.md` (table names)
- ⚠️ `API_Reference.md` (if using model objects)

**Debugging Existing Code**
- ✅ `Error_Reference.md` (error diagnosis)
- ✅ `API_Reference.md` (verify method usage)
- ⚠️ `Pattern_Reference.md` (correct examples)

**Learning/Complex Tasks**
- ✅ All files (comprehensive context)

**Terminology Questions**
- ✅ `Glossary.md` (definitions)
- ⚠️ `Tutorial_Context.md` (concepts in context)

---

## 🔗 How Files Interlink

### Cross-Reference Flow

```
Lessons_Learned.md (ALWAYS FIRST)
    ↓
    ├─→ API_Reference.md ──→ Pattern_Reference.md (PAT_XXX_NNN IDs)
    │                              ↓
    ├─→ Database_Reference.md ←────┘ (table names, types)
    │         ↓
    └─→ Tutorial_Context.md (uses all of the above)
            ↓
        Error_Reference.md (references patterns & API)
            ↓
        Glossary.md (terminology used everywhere)
```

### Reference Patterns in Files

**Lessons_Learned.md references:**
- API_Reference.md: "See API docs for WSCommits class"
- Pattern_Reference.md: "See PAT_TRANSACTION_010"
- Error_Reference.md: "See Error Reference for NoMethodError solutions"

**API_Reference.md references:**
- Pattern_Reference.md: "Pattern Ref" column has PAT_XXX_NNN IDs
- Lessons_Learned.md: Prerequisite warning

**Pattern_Reference.md references:**
- Database_Reference.md: Table names in code (hw_node, sw_subcatchment)
- API_Reference.md: Method signatures used in patterns
- Tutorial_Context.md: "See Tutorial for complete workflow"

**Database_Reference.md references:**
- Pattern_Reference.md: "See PAT_DATA_ITERATE_005"
- Tutorial_Context.md: "See Tutorial for usage examples"

**Tutorial_Context.md references:**
- All other files for specific details

**Error_Reference.md references:**
- Pattern_Reference.md: "Solution: See PAT_XXX_NNN"
- Lessons_Learned.md: "Prevented by reading Lessons_Learned"

---

## 🎓 LLM Instructions: How to Use These Files

### When User Asks to Generate Code:

**Step 1:** Load `Lessons_Learned.md` in its entirety
- This prevents collection iteration errors (.find vs .each)
- This prevents DateTime class errors
- This provides _seen flag, blob structure, transaction patterns

**Step 2:** Determine script type and load core files:
- Exchange script → Load `API_Reference.md` + `Pattern_Reference.md`
- UI script → Load `Pattern_Reference.md`
- Both types → Load `Database_Reference.md` if accessing row_objects()

**Step 3:** Load conditional files as needed:
- Complex workflow → Add `Tutorial_Context.md`
- Unfamiliar terms → Add `Glossary.md`
- Debugging errors → Add `Error_Reference.md`

### When User Reports an Error:

**Step 1:** Load `Lessons_Learned.md`
- Check if error matches known anti-patterns (collections, DateTime)

**Step 2:** Load `Error_Reference.md`
- Search for exact error message
- Get solution and pattern reference

**Step 3:** Load referenced pattern:
- Load `Pattern_Reference.md` for correct implementation
- Load `API_Reference.md` to verify method signature

### When User Asks "How to..." or "Example of...":

**Step 1:** Load `Lessons_Learned.md` (always)

**Step 2:** Load `Tutorial_Context.md`
- Find complete workflow example
- Identify which patterns are used

**Step 3:** Load supporting files:
- `Pattern_Reference.md` for pattern details
- `Database_Reference.md` for table names
- `API_Reference.md` for method signatures

### Load Triggers by Keywords:

| Keywords in Query | Files to Load |
|------------------|---------------|
| "Exchange", "database", "run", "automation" | Lessons_Learned + API + Pattern + Database |
| "UI script", "current_network", "edit" | Lessons_Learned + Pattern + Database |
| "error", "fails", "broken", "debug" | Lessons_Learned + Error + API + Pattern |
| "how to", "example", "workflow", "complete" | Lessons_Learned + Tutorial + Pattern |
| "what is", "definition", "meaning" | Glossary (+ others as needed) |
| "table name", "row_objects", "hw_*", "sw_*" | Lessons_Learned + Database |
| "method", "signature", "parameters", "returns" | Lessons_Learned + API |
| "pattern", "PAT_", "template", "code sample" | Lessons_Learned + Pattern |

---

## 📊 Performance & Token Budget

### File Sizes (Approximate)
- `Lessons_Learned.md`: ~730 lines (18-20k tokens)
- `API_Reference.md`: ~1,050 lines (26-28k tokens)  
- `Pattern_Reference.md`: ~1,120 lines (28-30k tokens)
- `Database_Reference.md`: ~390 lines (10-12k tokens)
- `Tutorial_Context.md`: ~1,070 lines (27-29k tokens)
- `Error_Reference.md`: ~490 lines (12-14k tokens)
- `Glossary.md`: ~380 lines (9-11k tokens)

**Total if all loaded:** ~5,230 lines (~130-144k tokens)

### Recommended Loading Strategies

**Minimal (Quick queries):** 50-60k tokens
- Lessons_Learned + API + Pattern

**Standard (Most code generation):** 70-80k tokens  
- Lessons_Learned + API + Pattern + Database

**Extended (Complex workflows):** 110-120k tokens
- Lessons_Learned + API + Pattern + Database + Tutorial

**Full (Learning/debugging):** 130-144k tokens
- All 7 files

**⚠️ Archive folder alone:** ~6,000 lines (150-200k tokens) - Do NOT load with RAG files

---

## 📚 File Summaries

### 🔴 Lessons_Learned.md (CRITICAL - Always First)
**Purpose:** Prevent common mistakes by documenting anti-patterns  
**Content:** Collection iteration gotchas (.each vs .find), DateTime unavailability, _seen flag pattern, blob structures, transaction patterns, simulation launching, scenario field flags  
**When to Load:** ALWAYS before generating any code  
**Key Value:** Consolidates scattered warnings into single high-priority document

### 🟡 API_Reference.md (CORE - Method Lookup)
**Purpose:** Quick reference for method signatures and parameters  
**Content:** WSApplication (9 methods), WSDatabase (6 methods), WSModelObject (14 methods), WSNumbatNetworkObject (6 methods), WSOpenNetwork (14 methods), WSSimObject (3 methods), WSRowObject/WSNode/WSLink (13 methods), plus supporting classes  
**When to Load:** Always for Exchange scripts, conditionally for UI scripts  
**Key Value:** Authoritative method signatures with Exchange vs UI availability

### 🟡 Pattern_Reference.md (CORE - Code Templates)
**Purpose:** Reusable code patterns organized by task  
**Content:** 56 patterns across 11 categories (Initialization, Data Access, Selection, Modification, Tracing, Results, Simulation, Import/Export, Spatial, Utilities, Exchange)  
**When to Load:** Always when implementing specific functionality  
**Key Value:** Working code templates with intent, context, and related patterns

### 🟢 Database_Reference.md (LOOKUP - Table Names)
**Purpose:** Database table and object type reference  
**Content:** 90+ Model Object Types with ShortCodes, InfoWorks (hw_*) and SWMM (sw_*) network table names, usage examples, field naming conventions  
**When to Load:** When script calls row_objects() or model_object_from_type_and_id()  
**Key Value:** Correct spelling and case-sensitivity for table/type names

### 🟢 Tutorial_Context.md (LEARNING - Complete Examples)
**Purpose:** Complete workflow examples from start to finish  
**Content:** Network access, iteration, transactions, tracing, results, version control, Exchange workflows (database operations, InfoWorks/SWMM run setup, simulation launch, ODIC/ODEC)  
**When to Load:** When user asks "how to" or requests complete script  
**Key Value:** Shows how multiple patterns combine to solve real problems

### 🟢 Error_Reference.md (DEBUGGING - Error Solutions)
**Purpose:** Quick error diagnosis and solutions  
**Content:** Common error messages mapped to causes and solutions, organized by category with pattern references  
**When to Load:** When debugging errors or user reports problems  
**Key Value:** Fast symptom→solution mapping with pattern IDs

### 🟢 Glossary.md (REFERENCE - Terminology)
**Purpose:** Define InfoWorks-specific terminology  
**Content:** General terms (ICMExchange, Agent, Workgroup), API classes (WSApplication, WSOpenNetwork), object types (Model Object, Row Object), technical jargon  
**When to Load:** When unfamiliar terms appear or user asks definitions  
**Key Value:** Prevents terminology confusion in code generation

---

## ✅ File Validation Checklist

All files now include:
- ✅ Load priority indicator (🔴 CRITICAL, 🟡 CORE, 🟢 CONDITIONAL)
- ✅ "For LLMs: Use this file to..." section
- ✅ "Prerequisite: Read Lessons_Learned.md FIRST" reminder
- ✅ "Related Files:" cross-reference section
- ✅ Last Updated date (December 2, 2025)
- ✅ Consistent formatting and structure

Cross-reference integrity:
- ✅ Lessons_Learned → API, Pattern, Error references
- ✅ API → Pattern references (PAT_XXX_NNN)
- ✅ Pattern → Database, Tutorial references
- ✅ Database → Pattern, Tutorial references  
- ✅ Tutorial → All other files
- ✅ Error → Pattern, Lessons_Learned references
- ✅ Glossary → API, Database, Tutorial references

---

*For human developers: See individual files for detailed content. For LLMs: Follow the loading decision tree above.*
