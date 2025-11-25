# InfoWorks ICM Ruby Context Files

**Last Updated:** November 25, 2025

## Core RAG Files

1. **Database_Reference.md** (~350 lines) - Table names, Model Object Types
2. **Pattern_Reference.md** (~750 lines) - 50+ code patterns (PAT_XXX_NNN)
3. **Tutorial_Context.md** (~700 lines) - Examples and workflows
4. **Error_Reference.md** (~500 lines) - Common errors and fixes
5. **Glossary.md** (~400 lines) - InfoWorks terminology

⚠️ **Archive folder**: Human reference only - do NOT load for LLM queries

## Loading Strategy

**Minimum** (fast): Database + Pattern  
**Standard** (most queries): + Tutorial  
**Debugging**: + Error  
**Full** (complex): + Glossary

### Load When Keywords Appear

- **Tutorial**: "example", "how to", "complete script", "learn"
- **Error**: "error", "exception", "fails", "debugging"
- **Glossary**: "what is", "definition", "terminology"

## Performance

- All 5 RAG files: ~2,700 lines (70-90k tokens)
- Archive alone: ~6,000 lines (150-200k tokens)
- Never load archive with RAG files

---
