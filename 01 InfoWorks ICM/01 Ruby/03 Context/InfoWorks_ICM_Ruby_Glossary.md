# InfoWorks ICM Ruby Scripting - Glossary

**Purpose:** Define all project-specific terms, acronyms, class names, and technical jargon used in InfoWorks ICM Ruby scripting to enable accurate LLM code generation and prevent terminology confusion.

**Last Updated:** October 21, 2025

---

## General Terms

### InfoWorks ICM
Integrated Catchment Modeling software by Innovyze (Autodesk) for hydraulic and hydrological simulation of urban drainage, wastewater, and water distribution systems.

### ICMExchange
Command-line application for running Ruby scripts with full database access outside the user interface.

### UI Script
Ruby script executed from within the InfoWorks ICM graphical user interface with access to the current network and UI features.

### Exchange Script
Ruby script executed via ICMExchange command line with full database access but no UI capabilities.

### Agent
Background service that manages and executes simulation runs, typically running on local or remote compute resources.

### Workgroup Database
Multi-user database hosted on a server allowing concurrent access and version control.

### Standalone Database
Single-user database stored as a file on the local filesystem (typically .icmm extension).

### Transportable Database
Compact, portable database format for sharing data without the full database infrastructure.

## Core API Classes

### WSApplication
Static class providing top-level application functionality including database operations, UI dialogs, and global settings. Entry point for most scripts.

### WSDatabase
Represents an open database connection providing access to model objects and database-level operations.

### WSModelObject
Any object in the database tree including model groups, networks, scenarios, runs, selection lists, and stored queries.

### WSOpenNetwork
An opened network instance that allows access to row objects and network data. Required for reading/writing network elements.

### WSRowObject
Individual object within a network such as a node, link, subcatchment, or other network element.

### WSNode
Specialized WSRowObject representing network nodes (manholes, junctions, outfalls, etc.).

### WSLink
Specialized WSRowObject representing network links (conduits, channels, pumps, weirs, etc.).

### WSStructure
Represents structured blob data fields containing multiple rows and columns (e.g., river reach sections, pump curves).

### WSStructureRow
Individual row within a WSStructure object.

### WSRun
Model object representing a simulation run configuration.

### WSSimObject
Model object representing an individual simulation within a run.

### WSModelObjectCollection
Collection of WSModelObject instances returned by queries and searches.

### WSRowObjectCollection
Collection of WSRowObject instances for iterating over network elements.

### WSCommit
Represents a commit in version control history.

### WSValidation
Represents network validation results.

### WSBaseline
Represents a baseline (snapshot) of network data.

## Network Concepts

### Network
In InfoWorks ICM context, a database object containing tables of interconnected hydraulic/hydrological elements (not to be confused with computer networks).

### Model Network
Primary network type containing the complete hydraulic model (InfoWorks terminology).

### Geometry
Network type in InfoWorks WS Pro (equivalent to Model Network in ICM).

### Row Object
Individual element within a network (node, link, subcatchment, etc.) stored as a row in a database table.

### Category
Grouping of multiple table types for iteration (e.g., `_nodes` includes all node types, `_links` includes all link types).

### Scenario
Named variant of network data allowing comparison of different design or operational conditions within the same network.

### Selection List
Named collection of selected network objects for filtering and batch operations.

### Model Group
Container in the database tree for organizing related model objects.

## Network Element Types

### Node
Point object in the network representing manholes, junctions, outfalls, storage areas, etc.

### Link
Linear object connecting nodes representing conduits, channels, pumps, weirs, orifices, etc.

### Subcatchment
Area object representing a drainage catchment that contributes runoff to the network.

### Conduit
Closed pipe or culvert link.

### Channel
Open channel link.

### River Reach
Natural or artificial watercourse with variable cross-sections.

### 2D Zone
Area representing two-dimensional overland flow simulation domain.

### RTC (Real-Time Control)
Logic rules for controlling hydraulic structures during simulation.

## Table Names

### Table Prefixes
- `hw_` - InfoWorks (Hydrologic/Hydraulic Works) table prefix for model networks
- `cams_` - Collection network (asset management) table prefix
- `sw_` - SWMM (Storm Water Management Model) table prefix

### Common Tables
- `hw_node` - Manhole and junction nodes
- `hw_conduit` - Pipe and culvert conduits
- `hw_subcatchment` - Drainage subcatchments
- `hw_river_reach` - River reach sections
- `hw_pump` - Pump structures
- `hw_weir` - Weir structures
- `hw_2d_zone` - 2D modeling zones

### Special Categories
- `_nodes` - All node types across multiple tables
- `_links` - All link types across multiple tables
- `_subcatchments` - All subcatchment types
- `_other` - Other objects not classified as nodes, links, or subcatchments

## Data Structures

### Structure Blob
Complex field containing tabular data (rows and columns) accessed via WSStructure class.

### Tag
User-defined temporary attribute attached to an object during script execution (e.g., `node._seen = true`).

### Flag
Additional text field associated with most data fields for annotations (e.g., `diameter_flag`).

### GUID
Globally Unique Identifier - a long string uniquely identifying any model object in the database.

### Model ID
Integer identifier for model objects, simpler than GUID but only unique within a database.

### Scripting Path
String identifying a model object's location in the database tree (e.g., `>MODG~Group>NNET~Network`).

## Scripting Operations

### Transaction
Grouped set of database changes that execute atomically (all succeed or all fail). Begin with `transaction_begin`, end with `transaction_commit`.

### Commit
Save changes to the network with version control metadata (message, timestamp, author).

### Write
Save changes to a row object or structure after modification. Must be called explicitly.

### Trace
Algorithm for traversing network connectivity following links and nodes upstream or downstream.

### ODIC
Open Data Import Centre - framework for importing data from external formats.

### ODEC
Open Data Export Centre - framework for exporting data to external formats.

## Simulation Concepts

### Run
Configuration for one or more simulations including network, parameters, and rainfall data.

### Simulation (Sim)
Individual simulation instance within a run representing specific conditions or parameters.

### Results
Output data from completed simulations stored in binary format.

### Timestep
Interval of time in simulation calculations.

### IWR File
InfoWorks Results file format containing simulation output data.

### LOG File
Text file containing detailed simulation debugging information.

### PRN File
Text file containing simulation summary information.

## Field Types

### Native Units
Internal units used by InfoWorks ICM for data storage.

### User Units
Display units configured by the user in the interface.

### Read-only Field
Field that cannot be modified via the API (calculated or system-managed).

### Blob Field
Field containing structured tabular data requiring special access methods.

## Ruby-Specific Terms

### Method Chaining
Calling multiple methods in sequence on the same object (e.g., `net.row_objects('_nodes').first.delete`).

### Safe Navigation
Using `&.` to call methods only if the object is not nil (e.g., `node&.us_links`).

### Ternary Operator
Inline conditional expression: `condition ? true_value : false_value`.

### Symbol
Ruby object representing an identifier, prefixed with colon (`:symbol`). Not commonly used in InfoWorks API.

### Hash
Ruby dictionary/associative array using key-value pairs.

### Array
Ruby ordered collection of objects.

### Block
Ruby code block passed to methods, typically used with iterators (e.g., `each do |item|`).

### Proc/Lambda
Ruby objects encapsulating executable code blocks.

## Naming Conventions

### PascalCase
Capitalized words concatenated without separators (e.g., `WSApplication`, `ModelObject`). Used for classes and modules.

### snake_case
Lowercase words separated by underscores (e.g., `current_network`, `row_objects`). Used for methods and variables.

### SCREAMING_SNAKE_CASE
Uppercase words separated by underscores (e.g., `MAX_DIAMETER`, `DEBUG_MODE`). Used for constants.

## Common Abbreviations

### API
Application Programming Interface - methods and classes for programmatic access.

### CSV
Comma-Separated Values file format.

### DLL
Dynamic Link Library - Windows binary library file.

### DSN
Data Source Name - connection string for databases.

### GIS
Geographic Information System.

### GUID
Globally Unique Identifier.

### ID
Identifier - unique reference for an object.

### JSON
JavaScript Object Notation data format.

### MIF
MapInfo Interchange Format for GIS data.

### ODBC
Open Database Connectivity standard.

### RTC
Real-Time Control logic system.

### SQL
Structured Query Language for database queries.

### SWMM
Storm Water Management Model (EPA model engine).

### UI
User Interface.

### UUID
Universally Unique Identifier (synonym for GUID).

### XML
eXtensible Markup Language data format.

## Method Return Type Notation

### void
Method returns no value.

### Type?
Return type may be nil/null (e.g., `String?` means might return String or nil).

### Array<Type>
Array containing elements of specified type (e.g., `Array<WSNode>`).

### Boolean
True or false value.

### Integer
Whole number.

### Float/Numeric
Decimal number.

### String
Text value.

### Hash
Key-value dictionary.

### Any
Can return various types depending on context.

## Special Syntax

### ⇒
Arrow indicating return type in method documentation (e.g., `#current_network ⇒ WSOpenNetwork`).

### #method_name
Documentation convention for instance methods.

### .method_name
Documentation convention for class methods (static methods).

### ||
Ruby syntax for block parameters (e.g., `each do |item|`).

### =>
Ruby hash syntax for key-value pairs (e.g., `{key => value}`).

### @variable
Ruby instance variable (not commonly used in InfoWorks scripts).

### $variable
Ruby global variable (rarely used, may appear in examples).

## Version Control Terms

### Commit ID
Unique identifier for a specific version in the commit history.

### Branch
Separate line of development (not typically used in InfoWorks ICM).

### Revert
Undo changes and return to a previous committed state.

### Baseline
Snapshot of network data at a specific point in time.

## Error Handling

### Exception
Error condition raised during script execution.

### rescue
Ruby keyword for catching and handling exceptions.

### raise
Ruby keyword for throwing exceptions.

### ensure
Ruby keyword for code that runs regardless of success or failure.

## Performance Terms

### Batch Operation
Processing multiple items together for efficiency.

### Lazy Evaluation
Computing values only when needed.

### Memoization
Caching computed values to avoid recalculation.

---

## Cross-References

For usage examples of these terms, see:
- **InfoWorks_ICM_Ruby_Pattern_Reference.md** - Code patterns using these APIs
- **InfoWorks_ICM_Ruby_Tutorial_Context.md** - Complete working examples
- **InfoWorks_ICM_Ruby_Database_Reference.md** - Table and type lookups

---

**Note:** This glossary is designed for LLM context to prevent terminology confusion and ensure accurate code generation. All class names, table names, and method names are case-sensitive.
