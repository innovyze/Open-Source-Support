# InfoWorks ICM Ruby Scripting - Glossary

**Purpose:** Define InfoWorks-specific terms, acronyms, and API classes. Standard Ruby terms are NOT included.

**Load Priority:** REFERENCE - Load for terminology clarification  
**Last Updated:** January 16, 2026

---

## Product & Environment

| Term | Definition |
|------|------------|
| **InfoWorks ICM** | Integrated Catchment Modeling software for hydraulic/hydrological simulation |
| **ICMExchange** | Command-line application for running Ruby scripts with full database access |
| **UI Script** | Script run inside ICM GUI with `current_network` and dialog access |
| **Exchange Script** | Script run via ICMExchange with database access but no UI |
| **Agent** | Background service executing simulation runs on local/remote resources |
| **Workgroup Database** | Multi-user database on server with version control |
| **Standalone Database** | Single-user local file (.icmm) |
| **Transportable Database** | Compact portable format for sharing |

---

## API Classes

| Class | Purpose |
|-------|---------|
| **WSApplication** | Static entry point - database operations, UI dialogs, global settings |
| **WSDatabase** | Open database connection for model object access |
| **WSModelObject** | Database tree object (groups, networks, runs, selections) |
| **WSOpenNetwork** | Opened network for row object access |
| **WSRowObject** | Network element (node, link, subcatchment) |
| **WSNode** | Specialized row object for nodes |
| **WSLink** | Specialized row object for links |
| **WSStructure** | Blob field containing tabular data |
| **WSRun** | Simulation run configuration |
| **WSSimObject** | Individual simulation within a run |
| **WSCommit** | Version control commit entry |
| **WSModelObjectCollection** | Collection from queries (use `.each` only) |
| **WSRowObjectCollection** | Collection of row objects (use `.each` only) |

---

## Network Concepts

| Term | Definition |
|------|------------|
| **Network** | Database object with interconnected hydraulic elements |
| **Model Network** | Primary network type (InfoWorks terminology) |
| **Row Object** | Element in network (node, link, subcatchment) = table row |
| **Scenario** | Named variant for comparing designs within one network |
| **Selection List** | Named collection of objects for filtering/batch ops |
| **Model Group** | Container for organizing model objects in tree |
| **Category** | Group of tables: `_nodes`, `_links`, `_subcatchments`, `_other` |

---

## Table Prefixes

| Prefix | Engine |
|--------|--------|
| `hw_` | InfoWorks tables |
| `sw_` | SWMM tables |
| `cams_` | Asset management tables |

---

## Data & Fields

| Term | Definition |
|------|------------|
| **Structure Blob** | Complex field with tabular data (via WSStructure) |
| **Tag** | Temporary attribute during script (e.g., `node._seen = true`) |
| **Flag** | Annotation field (e.g., `diameter_flag`) |
| **GUID** | Globally unique identifier for any model object |
| **Model ID** | Integer ID (unique within database only) |
| **Scripting Path** | Tree location string: `>MODG~Group>NNET~Network` |

---

## Operations

| Term | Definition |
|------|------------|
| **Transaction** | Atomic group of changes: `transaction_begin`...`transaction_commit` |
| **Commit** | Save with version control (message, timestamp, author) |
| **Write** | Save row object changes (must call explicitly) |
| **Trace** | Traverse network connectivity upstream/downstream |
| **ODIC** | Open Data Import Centre |
| **ODEC** | Open Data Export Centre |

---

## Simulation

| Term | Definition |
|------|------------|
| **Run** | Configuration for simulations (network, parameters, rainfall) |
| **Simulation (Sim)** | Individual sim instance within a run |
| **Results Field Code** | String for result data: `depnod` (depth), `qlink` (flow) |
| **Job ID** | Identifier for tracking launched simulations |
| **Working Directory** | Path for results and temp files |

---

## File Formats

| Extension | Purpose |
|-----------|---------|
| **.icmm** | Standalone database file |
| **.IWR** | Results file |
| **.LOG** | Simulation log report which may contain debug output |
| **.PRN** | Simulation summary |

---

## Abbreviations

| Abbrev | Meaning |
|--------|---------|
| **RTC** | Real-Time Control |
| **SWMM** | Storm Water Management Model (EPA) |
| **2D** | Two-dimensional overland flow |

---

**Cross-References:**
- `Pattern_Reference.md` - Code using these APIs
- `Database_Reference.md` - Table and type lookups
- `API_Reference.md` - Method signatures
