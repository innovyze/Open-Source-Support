# InfoAsset Manager Ruby Context Files

This folder contains LLM-oriented context files for InfoAsset Manager Ruby scripting.

The goal is to provide a product-pure, mode-aware entry point for IAM Ruby work without pulling in InfoWorks ICM, InfoWorks WS Pro, or SQL content by mistake.

## Start Here

Read `Instructions.md` first.

## Current Files (10)

| File | Purpose |
|------|---------|
| `Instructions.md` | Load order, runtime routing, retrieval rules |
| `InfoAsset_Manager_Ruby_Boundary_Guard.md` | Product, runtime, and language guardrails |
| `InfoAsset_Manager_Ruby_Lessons_Learned.md` | High-priority IAM Ruby pitfalls and anti-patterns |
| `InfoAsset_Manager_Ruby_API_Full.md` | Complete WS* class reference — method signatures, parameters, evidence citations |
| `InfoAsset_Manager_Ruby_Schema.md` | Complete `cams_`/`wams_` table manifest, navigate types, report pairings, evidence |
| `InfoAsset_Manager_Ruby_Patterns.md` | 20+ production-quality patterns — UI, Exchange, Dual-Mode, BLOB, callbacks, navigation |
| `InfoAsset_Manager_Ruby_Example_Index.md` | Route tasks to repository example folders (UI, Exchange, Dual-Mode sections) |
| `InfoAsset_Manager_Ruby_Error_Reference.md` | Common IAM Ruby failure modes and recovery guidance |
| `InfoAsset_Manager_Ruby_Tutorial_Context.md` | 4 complete multi-step workflow tutorials |
| `README.md` | This file — orientation and design rules |

## Design Rules

- Product scope is InfoAsset Manager only.
- Ruby and SQL context stay separate.
- UI, Exchange, and dual-mode examples are routed through a single Example Index with mode sections.
- Cross-product examples are quarantined unless the task is explicitly interoperability work.
- Official Help is directly available and should be used to verify IAM methods and terminology.

## Official Help Target

- Product code: `INFOAMAN`
- Preferred release for new context work: `2027`
- Locale: `en_US`
