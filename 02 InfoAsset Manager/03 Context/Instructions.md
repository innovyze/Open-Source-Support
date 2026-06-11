# InfoAsset Manager Ruby Context Files - Loading Instructions

**Last Updated:** May 2026

## Quick Start

**CRITICAL:** Always load `InfoAsset_Manager_Ruby_Boundary_Guard.md` first before generating any IAM Ruby.

Load `InfoAsset_Manager_Ruby_Lessons_Learned.md` immediately after the boundary guard when generating code, adapting examples, or troubleshooting runtime failures.

Do not search the full `01 Ruby` tree first. Route through the Example Index after confirming runtime mode.

## Step 0 - Verify Product

This folder is for **InfoAsset Manager** Ruby only.

- Use this folder when the target product is InfoAsset Manager.
- Do not use this folder for InfoWorks ICM.
- Do not use this folder for InfoWorks WS Pro.
- If the task is mixed-product interoperability, treat that as a special case and do not use default IAM examples blindly.

## Step 1 - Verify Runtime Mode

Identify the script mode before loading examples: UI, Exchange, or Dual-mode.

See `InfoAsset_Manager_Ruby_Boundary_Guard.md` → **Runtime Guard** for the authoritative signal lists, wrong/right examples, and filename conventions.

## Step 2 - Load the Smallest Valid Source Set

| Query Type | Files to Load |
|------------|---------------|
| IAM UI script | Boundary_Guard + Lessons_Learned + Example_Index + Patterns |
| IAM Exchange script | Boundary_Guard + Lessons_Learned + Example_Index + Patterns |
| IAM dual-mode script | Boundary_Guard + Lessons_Learned + Example_Index + Patterns |
| API method lookup | Boundary_Guard + API_Full |
| Table or object name lookup | Boundary_Guard + Schema |
| Unsure about runtime | Boundary_Guard only, then determine mode |
| Method or terminology verification | Boundary_Guard + Lessons_Learned + official Help for `INFOAMAN` 2027 |
| Debugging runtime/setup failures | Boundary_Guard + Lessons_Learned + Error_Reference |
| Worked example of full task | Boundary_Guard + Tutorial_Context + Patterns |

## File Inventory (10 files)

| File | Purpose | Load Priority |
|------|---------|---------------|
| `Instructions.md` | This file — load order and routing | Always first |
| `InfoAsset_Manager_Ruby_Boundary_Guard.md` | Product, runtime, and language guardrails | Always |
| `InfoAsset_Manager_Ruby_Lessons_Learned.md` | High-priority IAM Ruby pitfalls | Code generation |
| `InfoAsset_Manager_Ruby_API_Full.md` | Complete WS* class reference with method signatures and evidence | API lookup |
| `InfoAsset_Manager_Ruby_Schema.md` | Complete table manifest, navigate types, report pairings, evidence | Table/object lookup |
| `InfoAsset_Manager_Ruby_Patterns.md` | 20+ production-quality patterns (UI, Exchange, Dual) | Code generation |
| `InfoAsset_Manager_Ruby_Example_Index.md` | Route tasks to repository example folders by mode | Task routing |
| `InfoAsset_Manager_Ruby_Error_Reference.md` | Common failure modes and recovery guidance | Debugging |
| `InfoAsset_Manager_Ruby_Tutorial_Context.md` | 4 complete multi-step workflow tutorials | Complex tasks |
| `README.md` | File listing and design rules | Orientation |

## Retrieval Rules

1. Confirm product is InfoAsset Manager.
2. Confirm runtime mode.
3. Load the Example Index (single file covers all modes).
4. Read only the nearest relevant example folder README or script.
5. Verify unfamiliar methods against official Help when possible.

## Official Help Workflow

Use official Help as the authority for method names, product terminology, and Exchange behavior.

- Product code: `INFOAMAN`
- Release: `2027`
- Locale: `en_US`

Useful Help entry points include:

- InfoAsset Exchange
- Introduction to iExchange
- Introduction to Ruby Scripting
- Product-specific task pages for report generation, import/export, and database items
