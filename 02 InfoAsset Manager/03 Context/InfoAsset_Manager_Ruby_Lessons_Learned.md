# InfoAsset Manager Ruby - Lessons Learned

**Purpose:** High-priority IAM Ruby pitfalls, anti-patterns, and routing corrections.

**Load Priority:** HIGH - Load after `InfoAsset_Manager_Ruby_Boundary_Guard.md`
**Last Updated:** May 29, 2026

## CRITICAL: UI and Exchange Are the Main Failure Boundary

See `InfoAsset_Manager_Ruby_Boundary_Guard.md` → **Runtime Guard** for the full signal lists, wrong/right examples, and filename conventions.

**Key takeaway:** If a script fails at startup, the first check is always whether the entry pattern matches the runtime mode.

## CRITICAL: Do Not Reuse Example Paths or IDs As Real Defaults

Many IAM Exchange examples contain placeholder values such as:

- `localhost:40000/database`
- `//localhost:40000/IA_NEW`
- hard-coded network IDs such as `4`, `20`, or similar
- temp file paths such as `C:\Temp\...`

Treat these as examples only. They are not reusable production defaults.

## CRITICAL: Keep SQL Out of Ruby Guidance

See `InfoAsset_Manager_Ruby_Boundary_Guard.md` → **Cross-Language Guard** for the full rejection list.

**Key takeaway:** IAM SQL examples are valid style references for IAM SQL only — never use them as templates for Ruby output.

## CRITICAL: Quarantine Mixed-Product Examples

The folder `0003 Import an InfoWorks ICM Model into InfoAsset Manager` is not a normal IAM Ruby source.

Use it only when the task is explicitly about cross-product import/export. Do not use it as the template for ordinary IAM export, import, or network-editing work.

## Version-Gated IAM Methods Need Verification

The PACP and MACP workflows are documented in the repo as version-gated, and the examples show version notes that are close but not perfectly consistent.

Implication:

- Do not state an exact minimum version from memory.
- Verify PACP and MACP method availability against official Help before treating the method as broadly available.

## ODEC and ODIC Usually Depend On Config Files

IAM export/import examples frequently rely on:

- a config file path
- an options hash
- a target table or source class name
- optional callback classes

Do not reduce these workflows to a made-up single-call shortcut unless the example or Help explicitly shows one.

## Callback Classes Are Shared, But Context Still Matters

ODEC callback classes can be used from the UI and from Exchange, but the surrounding script flow still changes by runtime.

Do not confuse:

- shared callback class behavior, with
- a fully shared script entry pattern

## Reporting Is Not A General Exchange Pattern

The repo documents `generate_report` as a UI-driven workflow.

Do not generalize it into an Exchange pattern unless verified by Help.

## Use The Smallest Matching Example Set

Before opening scripts, ask:

1. Is this UI, Exchange, or dual-mode?
2. Is this IAM-only, or explicitly cross-product?
3. Is this import/export, reporting, attachment/blob handling, or object inventory?

Then choose the matching example index first instead of scanning the whole Ruby tree.