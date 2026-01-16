# InfoWorks ICM Ruby Context Files

This folder contains LLM-optimized context files for InfoWorks ICM Ruby scripting, designed for Retrieval-Augmented Generation (RAG) systems and AI code assistants.

## For LLMs/AI Systems

**Start with:** `Instructions.md` - Contains file loading priorities, decision trees, and token budget guidance.

## For Human Developers

**Learning Ruby for InfoWorks?** See `00 Reference/Ruby_Fundamentals.md` for Ruby basics.

**Need full API documentation?** See `00 Reference/Exchange.pdf` for complete reference.

## File Overview

| File | Purpose |
|------|---------|
| `Instructions.md` | LLM loading guide, token budgets, decision trees |
| `InfoWorks_ICM_Ruby_Lessons_Learned.md` | Critical anti-patterns and gotchas |
| `InfoWorks_ICM_Ruby_API_Reference.md` | Method signatures and parameters |
| `InfoWorks_ICM_Ruby_Pattern_Reference.md` | 57 reusable code templates |
| `InfoWorks_ICM_Ruby_Database_Reference.md` | Table names and Model Object Types |
| `InfoWorks_ICM_Ruby_Tutorial_Context.md` | Complete workflow examples |
| `InfoWorks_ICM_Ruby_Error_Reference.md` | Error diagnosis and solutions |
| `InfoWorks_ICM_Ruby_Glossary.md` | InfoWorks terminology definitions |
| `00 Reference/` | Human reference materials (not for LLM loading) |

---

## Purpose & Evolution

This context file set is being **organically evolved and trialed** to improve the effectiveness of AI models (LLMs) in generating InfoWorks ICM-specific Ruby scripts. The patterns, examples, and guidance contained herein have been extracted from real-world scripts in the Open-Source-Support repository and validated against actual InfoWorks ICM implementations.

**Development Goals:**
- **Primary Goal**: Enable AI models to generate accurate, idiomatic InfoWorks ICM Ruby code
- **Development Approach**: Iterative enhancement based on practical examples and user feedback
- **Validation Method**: All patterns tested against actual repository examples
- **Scope**: Covers both UI and Exchange scripting environments

---

## Contributing

When editing RAG files:

- Maintain consistent metadata headers (Load Priority, Last Updated, etc.)
- Avoid decorative formatting (emojis, excessive bold/italic)
- Keep code examples concise with clear CORRECT/WRONG labels
- Pattern IDs use format `PAT_XXX_NNN` for cross-file navigation

**Contact:** Alex Grist (Squark89) for suggestions, improvements, or new patterns.

---

## Standing on the Shoulders of Penguins

This documentation exists because **John Styles** and team built something remarkable - a Ruby implementation for InfoWorks ICM that is both architecturally elegant and genuinely fun to use. His memorable example naming conventions (penguins and badgers) proved that technical documentation doesn't have to be dry.

Every script you write using `WSApplication`, `WSStructure`, or row object iteration stands on that foundation. If the examples make you smile, that's John's legacy.

**Last Updated:** January 16, 2026
