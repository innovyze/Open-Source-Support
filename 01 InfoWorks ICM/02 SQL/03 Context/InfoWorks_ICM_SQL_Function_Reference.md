# InfoWorks ICM SQL Function Reference for LLM Agents

**Source:** SQL Combined Help Documentation and ICM Time Varying SQL Documentation
**Last Updated:** March 17, 2026

**Load Priority:** CORE - Load for function lookup and time-series results queries
**Load Condition:** ALWAYS when writing queries with functions or simulation results

## Purpose

This guide provides **function reference** for InfoWorks ICM SQL scripting.

**For LLMs:** Use this file to:
- Look up function signatures, parameters, and return types
- Verify correct parameter count to avoid "Too many/few function parameters" errors
- Find aggregate function behavior in different contexts (arrays, GROUP BY, time series)
- Understand WHEN clause usage for time-varying results

**Prerequisite:** Read `Lessons_Learned.md` FIRST to avoid critical mistakes

**Related Files:**
- `InfoWorks_ICM_SQL_Lessons_Learned.md` - Read FIRST - Critical gotchas and anti-patterns
- `InfoWorks_ICM_SQL_Pattern_Reference.md` - Working code templates using these functions
- `InfoWorks_ICM_SQL_Syntax_Reference.md` - Language syntax, data types, operators
- `InfoWorks_ICM_SQL_Error_Reference.md` - Debugging function-related errors

---

## Function Quick Reference

| Function | Params | Returns | Category | Pattern Ref |
|----------|--------|---------|----------|-------------|
| **Conditional** |
| IIF | 3 | varies | Conditional | PAT_SQL_MOD_009 |
| **Numeric** |
| ABS | 1 | number | Numeric | - |
| INT | 1 | number | Numeric | - |
| FLOOR | 1 | number | Numeric | - |
| CEIL | 1 | number | Numeric | - |
| **String** |
| LEN | 1 | number | String | PAT_SQL_LOOP_040 |
| LEFT | 2 | string | String | - |
| RIGHT | 2 | string | String | - |
| MID | 3 | string | String | - |
| SUBST | 3 | string | String | - |
| GSUBST | 3 | string | String | - |
| GENSUBST | 3 | string | String | - |
| NL | 0 | string | String | - |
| FIXED | 2 | string | Formatting | - |
| **Date** |
| YEARPART | 1 | number | Date | - |
| MONTHPART | 1 | number | Date | - |
| DAYPART | 1 | number | Date | - |
| DATEPART | 1 | date | Date | - |
| TIMEPART | 1 | number | Date | - |
| NOW | 0 | date | Date | - |
| YEARSDIFF | 2 | number | Date | - |
| MONTHSDIFF | 2 | number | Date | - |
| DAYSDIFF | 2 | number | Date | - |
| INYEAR | 2 | boolean | Date | - |
| INMONTH | 3 | boolean | Date | - |
| INYEARS | 3 | boolean | Date | - |
| INMONTHS | 5 | boolean | Date | - |
| ISDATE | 1 | boolean | Date | - |
| MONTHYEARPART | 1 | string | Date | - |
| YEARMONTHPART | 1 | string | Date | - |
| MONTHNAME | 1 | string | Date | - |
| SHORTMONTHNAME | 1 | string | Date | - |
| DAYNAME | 1 | string | Date | - |
| SHORTDAYNAME | 1 | string | Date | - |
| NUMTOMONTHNAME | 1 | string | Date | - |
| NUMTOSHORTMONTHNAME | 1 | string | Date | - |
| TODATE | 3 | date | Date | - |
| TODATETIME | 5 | date | Date | - |
| DATEFORMAT | 2 | string | Date | - |
| TIMEFORMAT | 2 | string | Date | - |
| DATETIMEFORMAT | 3 | string | Date | - |
| DAYOFWEEK | 1 | number | Date | - |
| DAYOFYEAR | 1 | number | Date | - |
| DAYSINYEAR | 1 | number | Date | - |
| **Math** |
| LOG | 1 | number | Math | - |
| LOGE | 1 | number | Math | - |
| EXP | 1 | number | Math | - |
| SIN | 1 | number | Math | - |
| COS | 1 | number | Math | - |
| TAN | 1 | number | Math | - |
| ASIN | 1 | number | Math | - |
| ACOS | 1 | number | Math | - |
| ATAN | 1 | number | Math | - |
| ATAN2 | 2 | number | Math | - |
| GAMMALN | 1 | number | Math | - |
| **List** |
| LEN | 1 | number | List | PAT_SQL_LOOP_040 |
| AREF | 2 | varies | List | PAT_SQL_LOOP_040 |
| RINDEX | 2 | number | List | PAT_SQL_REPORT_048 |
| LOOKUP | 2 | varies | List | - |
| MEMBER | 2 | boolean | List | PAT_SQL_SEL_007 |
| INDEX | 2 | number | List | - |
| TITLE | 2 | string | List | - |
| **Standard Aggregates** (arrays, one-to-many, GROUP BY) |
| COUNT | 1 | number | Aggregate | PAT_SQL_BLOB_024 |
| MAX | 1 | varies | Aggregate | PAT_SQL_RES_028 |
| MIN | 1 | varies | Aggregate | PAT_SQL_RES_028 |
| AVG | 1 | number | Aggregate | - |
| SUM | 1 | number | Aggregate | - |
| ANY | 1 | boolean | Aggregate | PAT_SQL_BLOB_024 |
| ALL | 1 | boolean | Aggregate | - |
| FIRST | 1 | varies | Aggregate | - |
| LAST | 1 | varies | Aggregate | - |
| **Time-Varying Aggregates** (tsr.* only) |
| DURATION | 1 | number | TSR Aggregate | PAT_SQL_RES_030 |
| INTEGRAL | 1 | number | TSR Aggregate | - |
| EARLIEST | 1 | varies | TSR Aggregate | PAT_SQL_RES_031 |
| LATEST | 1 | varies | TSR Aggregate | - |
| WHENEARLIEST | 1 | date/number | TSR Aggregate | - |
| WHENLATEST | 1 | date/number | TSR Aggregate | - |
| WHENMAX | 1 | date/number | TSR Aggregate | PAT_SQL_RES_029 |
| WHENMIN | 1 | date/number | TSR Aggregate | - |

---

## Conditional Functions

### IIF(condition, true_value, false_value)

Returns `true_value` if condition evaluates to true, otherwise `false_value`.

```sql
// Simple conditional
SET user_text_1 = IIF(conduit_width >= 600, 'Large', 'Small');

// Nested IIF for multiple conditions
SET user_text_1 = IIF(conduit_width >= 600, 'Large',
                  IIF(conduit_width >= 300, 'Medium', 'Small'));

// Conditional string concatenation
SET user_text_1 = user_text_1 + IIF(LEN(user_text_1) = 0, '', ',') + oid;

// With aggregation
SUM(IIF(area_measurement_type = 'Percent',
    (area_percent_1 / 100.0) * contributing_area,
    area_absolute_1)) AS Runoff_Area_1;
```

---

## Numeric Functions

### ABS(number)
Returns the absolute value. `ABS(-3)` = 3.

### INT(number)
Returns the integer part by removing the fractional part. `INT(3.7)` = 3, `INT(-3.7)` = -3.

### FLOOR(number)
Returns the largest integer less than or equal to the number. `FLOOR(3.7)` = 3, `FLOOR(-3.7)` = -4.
**Note:** Differs from INT for negative numbers.

### CEIL(number)
Returns the smallest integer greater than or equal to the number. `CEIL(3.2)` = 4, `CEIL(-3.7)` = -3.

---

## String Functions

### LEN(string) / LEN(list_variable)
Returns the length of a string (character count) or the number of items in a list.
```sql
LEN('MYNODEID')    // Returns 8
LEN($my_list)      // Returns number of items in list
```

### LEFT(string, n)
Returns the first `n` characters. Returns empty string if `n` <= 0.
```sql
LEFT('MX11112222', 2)   // Returns 'MX'
```

### RIGHT(string, n)
Returns the last `n` characters. Returns empty string if `n` <= 0.
```sql
RIGHT('MX11112222', 8)  // Returns '11112222'
```

### MID(string, start, count)
Returns `count` characters starting at position `start` (1-based).
```sql
MID('MX11112222', 1, 2)  // Returns 'MX'
MID('MX11112222', 3, 4)  // Returns '1111'
MID('MX11112222', 7, 4)  // Returns '2222'
```

### SUBST(string, find, replace)
Replaces the **first** instance of `find` with `replace`.
```sql
SUBST('01880132', '01', 'ND')  // Returns 'ND880132'
```

### GSUBST(string, find, replace)
Replaces **all** instances of `find` with `replace`.
```sql
GSUBST('01880132', '01', 'ND')  // Returns 'ND88ND32'
```

### GENSUBST(string, regexp, format)
Replaces the string using a regular expression match. Uses `\1`, `\2` etc. for captured groups. Returns the string unchanged if no match.
```sql
// Replace 'SK' prefix with '99' in node IDs
SET user_text_1 = GENSUBST(node_id, 'SK([0-9]*)', '99\1');
// SK12345678 → 9912345678
```

### NL()
Returns a newline character for multi-line text fields.
```sql
SET notes = 'Line 1' + NL() + 'Line 2' + NL() + 'Line 3';
```

### FIXED(number, decimal_places)
Converts a number to a string with specified decimal places (0 to 8).
```sql
FIXED(1.9, 3)     // Returns "1.900"
FIXED(1.9991, 3)  // Returns "1.999"
FIXED(1.9999, 3)  // Returns "2.000"
FIXED(123.0, 0)   // Returns "123"
```

---

## Date Functions

### YEARPART(date), MONTHPART(date), DAYPART(date)
Extract year, month, or day as a number.

### DATEPART(date)
Returns only the date portion (midnight), stripping the time component.

### TIMEPART(date)
Returns the time portion as a number of minutes after midnight.
```sql
// For 01/02/2008 12:34 → returns 754.0 (12*60 + 34)
```

### NOW()
Returns the current date and time. This is the only zero-parameter function.

### YEARSDIFF(from, to), MONTHSDIFF(from, to), DAYSDIFF(from, to)
Returns the number of **complete** years/months/days between two dates (based on midnight).
```sql
YEARSDIFF(#01/05/2008#, #01/05/2009#)  // Returns 1
```

### INYEAR(date, year)
Returns true if the date is in the specified year.
```sql
SELECT WHERE INYEAR(when_surveyed, 2023);
```

### INMONTH(date, month, year)
Returns true if the date is in the specified month and year.

### INYEARS(date, start_year, end_year)
Returns true if the date is in a year between start and end (inclusive).

### INMONTHS(date, start_month, start_year, end_month, end_year)
Returns true if the date is between the start month/year and end month/year (inclusive).

### ISDATE(value)
Returns true if the value is a date (from database) or a string convertible to a date.

### MONTHYEARPART(date)
Returns string `"MM/YYYY"` (e.g., `"01/2010"`).

### YEARMONTHPART(date)
Returns string `"YYYY/MM"` (e.g., `"2010/01"`). Useful for sortable date strings.

### MONTHNAME(date), SHORTMONTHNAME(date)
Returns full or abbreviated month name (locale-dependent).

### DAYNAME(date), SHORTDAYNAME(date)
Returns full or abbreviated day name (locale-dependent).

### NUMTOMONTHNAME(n), NUMTOSHORTMONTHNAME(n)
Returns month name given an integer 1-12.

### TODATE(year, month, day)
Returns a date value from integer components.

### TODATETIME(year, month, day, hours, minutes)
Returns a date/time value from integer components.

### DATEFORMAT(date, format_string)
Formats the date part using Win32 GetDateFormat patterns:
- `d` / `dd` — day without/with leading zero
- `ddd` / `dddd` — short/full day name
- `M` / `MM` — month without/with leading zero
- `MMM` / `MMMM` — short/full month name
- `yy` / `yyyy` — 2-digit/4-digit year

```sql
SET user_text_1 = DATEFORMAT(when_surveyed, 'dd/MM/yyyy');
```

### TIMEFORMAT(date, format_string)
Formats the time part using Win32 GetTimeFormat patterns:
- `h` / `hh` — 12-hour without/with leading zero
- `H` / `HH` — 24-hour without/with leading zero
- `m` / `mm` — minutes without/with leading zero
- `s` / `ss` — seconds without/with leading zero
- `t` / `tt` — A/P or AM/PM

### DATETIMEFORMAT(date, date_format, time_format)
Returns `DATEFORMAT(date, date_format) + ' ' + TIMEFORMAT(date, time_format)`.

### DAYOFWEEK(date)
Returns 1 (Monday) to 7 (Sunday) per ISO 8601.

### DAYOFYEAR(date)
Returns 1-366 (day number in the year).

### DAYSINYEAR(date)
Returns number of days in the year of the date (365 or 366).

---

## Mathematical Functions

All angles are in **degrees** (not radians). All return NULL if parameters cannot be converted to numbers.

### LOG(x)
Log base 10. Returns NULL if x <= 0.

### LOGE(x)
Natural logarithm (base e). Returns NULL if x <= 0.

### EXP(x)
Returns e^x.

### SIN(x), COS(x), TAN(x)
Trigonometric functions. TAN returns NULL if cos(x) = 0.

### ASIN(x), ACOS(x), ATAN(x)
Inverse trigonometric functions. ASIN/ACOS return NULL if |x| > 1.
- ASIN returns -90 to 90 degrees
- ACOS returns 0 to 180 degrees
- ATAN returns -90 to 90 degrees

### ATAN2(y, x)
Two-argument inverse tangent. Returns -180 to 180 degrees.
**Note:** Parameters are (y, x) — consistent with most programming languages but NOT Excel.

### GAMMALN(x)
Returns log_e of the Gamma function of x.

---

## List Functions

List variables must be defined with `LIST` before use. The list variable is always the **last** parameter.

### AREF(n, list)
Returns the nth element from a list (1-based indexing).
```sql
LIST $codes = 'AB', 'CD', 'EF';
LET $second = AREF(2, $codes);  // Returns 'CD'
```
**Note:** Parameter order is (index, list) — the list is last for consistency with other list functions.

### LEN(list)
Returns the number of elements in the list.
```sql
LIST $widths = 100, 300, 500;
// LEN($widths) returns 3
```

### MEMBER(expression, list)
Returns true if the expression value is found in the list.
```sql
LIST $defects = 'CC', 'CCJ', 'CL', 'CLJ';
SELECT WHERE MEMBER(details.code, $defects);
```

### INDEX(expression, list)
Returns the 1-based position of the value in the list, or 0 if not found.

### RINDEX(expression, list)
**Requires sorted list (strictly increasing).** Partitions values into buckets:
- Returns 0 if value < first list element
- Returns 1 if value >= first but < second
- Returns n if value >= nth (last) element

```sql
LIST $breaks = 0, 0.3, 0.5, 1.0;
SET user_number_1 = RINDEX(sim.max_Surcharge, $breaks);
// 0 → <0, 1 → 0-0.3, 2 → 0.3-0.5, 3 → 0.5-1.0, 4 → >=1.0
```

### LOOKUP(expression, list)
Returns the nth element from the list where n is the expression value (1-based). Returns NULL if out of range.

### TITLE(n, list)
Provides titles for RINDEX buckets. Used in conjunction with RINDEX for labeling ranges.

---

## Standard Aggregate Functions

These work on **array/blob fields**, **one-to-many links**, and in **GROUP BY** clauses.

### COUNT(expression) / COUNT(*)
- **Array context:** Number of array rows where expression is true. `COUNT(details.*)` = total row count.
- **One-to-many:** Number of linked objects where expression is true. `COUNT(us_links.*)` = count of upstream links.
- **GROUP BY:** Number of objects in the group. `COUNT(*)` = group size.

```sql
// Count CCTV defects with code 'GP'
COUNT(details.code = 'GP')

// Count upstream links
COUNT(us_links.*)

// Count per system type
SELECT COUNT(*) GROUP BY system_type;
```

### MAX(expression), MIN(expression)
Maximum/minimum value. Works on numbers, dates, and strings. Only non-NULL values considered.

### AVG(expression)
Average of non-NULL values. Returns NULL if no non-NULL values.
**Warning:** In time-series context, AVG is time-weighted (see Time-Varying section).

### SUM(expression)
Sum of values across array rows, linked objects, or group members.

### ANY(expression)
Returns true if expression is true for **any** row/object.
```sql
// Any detail with code 'GP'?
ANY(details.code = 'GP')

// Any upstream links?
ANY(us_links.*)
```

### ALL(expression)
Returns true if expression is true for **all** rows/objects.

### FIRST(expression), LAST(expression)
Value of expression for the first/last row in an array. **Not available in GROUP BY context.**

---

## Time-Varying Aggregate Functions

These operate on time series results (`tsr.*` prefix) across simulation timesteps. All require an aggregate function wrapper.

**WHEN Clause:** All time-varying aggregates support WHEN clauses to limit timesteps:
```sql
SELECT MAX(tsr.ds_depth) WHEN tsr.timestep_no > 20;
SELECT MAX(tsr.ds_depth) WHEN tsr.timestep_start = #01/01/2013 12:30#;
SELECT MAX(tsr.ds_depth) WHEN tsr.timestep_no = tsr.timesteps;  // Last timestep only
```

**WHEN clause fields:**
| Field | Type | Description |
|-------|------|-------------|
| `tsr.timestep_no` | integer | Timestep number (1 = first) |
| `tsr.timestep_start` | date/number | Start time of timestep (date for absolute, minutes for relative) |
| `tsr.timesteps` | integer | Total number of timesteps |
| `tsr.timestep_duration` | number | Duration of timestep in minutes |
| `tsr.sim_start` | date/number | Simulation start time |
| `tsr.sim_end` | date/number | Simulation end time |

### MAX(tsr.field), MIN(tsr.field)
Maximum/minimum value across timesteps.
```sql
SELECT MAX(tsr.ds_depth), MIN(tsr.ds_depth);
```

### WHENMAX(tsr.field), WHENMIN(tsr.field)
Returns the **time** at which max/min occurred. If tied, returns the earliest time.
Returns a date (absolute times) or number of minutes (relative times).
```sql
SELECT WHENMAX(tsr.ds_depth);
// e.g. returns #16/01/1999 05:35:00#
```

### AVG(tsr.field)
**TIME-WEIGHTED average** — not a simple arithmetic mean. Calculated as: sum of (value × timestep duration) for all timesteps except the last, divided by total duration. Results treated as step functions.

### SUM(tsr.field)
Simple sum of values at all timesteps. **Only meaningful if all timesteps are the same length.**

### COUNT(tsr.expression)
Number of timesteps where expression is true.
```sql
COUNT(tsr.ds_depth > 1.0)  // How many timesteps with depth > 1m
```

### DURATION(tsr.expression)
Total time **in minutes** for which expression is true (not necessarily contiguous). Always returns a number, never a date.
```sql
DURATION(tsr.ds_depth > 1.0) > 30  // Depth > 1m for more than 30 minutes
```

### INTEGRAL(tsr.field)
Sum of (value × timestep duration in minutes) for each timestep. Effectively a step-function integral. **User is responsible for unit conversion.**

### ANY(tsr.expression)
True if expression is true for at least one timestep.

### ALL(tsr.expression)
True if expression is true for all timesteps under consideration.
```sql
ALL(tsr.depth2d > 1.0)  // Depth > 1m for ALL timesteps?
```

### FIRST(tsr.field), LAST(tsr.field)
Value at the first/last timestep under consideration.

### EARLIEST(tsr.expression)
Returns the first non-null value. Best used with IIF to find the first occurrence meeting a condition:
```sql
SELECT EARLIEST(IIF(tsr.surcharge > 0.5, tsr.surcharge, NULL));
```

### LATEST(tsr.expression)
Returns the latest time for which expression is true.

### WHENEARLIEST(tsr.expression)
Returns the earliest **time** for which expression is true.
```sql
WHENEARLIEST(tsr.head < 150)  // First time head drops below 150
```

### WHENLATEST(tsr.expression)
Returns the last non-null value. Best used with IIF (like EARLIEST).

### Key Notes for Time-Varying Functions

1. **AVG, INTEGRAL, and SUM skip the final simulation timestep** (unknown duration). This only applies to the final timestep of the simulation, not the final timestep selected by a WHEN clause.
2. **EARLIEST, LATEST, WHENEARLIEST, WHENLATEST, WHENMAX, WHENMIN** return dates for absolute-time simulations, or minutes (number) for relative-time simulations.
3. **MAX, MIN, WHENMAX, WHENMIN work on signed values.** Use `ABS()` to ignore sign.
4. Results from tsr.* come from **results files**, not computational timesteps. MAX(tsr.depth2d) may differ from the stored maximum.
5. When using **relative times** with non-integer minutes: `WHEN tsr.timestep_start = 746 + (1/60)` for 746 minutes and 1 second.

---

## GIS Export with Time-Varying Expressions

Time-varying expressions (with optional WHEN clauses) can be used in 2D GIS export. If all expressions have WHEN clauses, only matching timesteps are processed. If any expression lacks a WHEN clause, all timesteps are processed.

**Not available for themes** due to computation time.

---

## DP (Decimal Places) Formatting

Not a function, but a display modifier for numeric fields in SELECT output:

```sql
SELECT MIN(sections.z) DP 3 GROUP BY oid;
SELECT ground_level DP 2, x DP 1, y DP 1;
```

---

## RANK Keyword

Not a function, but a special keyword available when ORDER BY is used in SET clauses:

```sql
// Assign rank based on ground level
SET $r = rank ORDER BY ground_level DESC;

// Tied values get equal rank (1, 2, 2, 4, 5, 5, 5, 8...)
```

**Note:** RANK can only appear on the right-hand side of a SET assignment, not in SELECT expressions. To display rank, assign to a variable first:
```sql
SET $r = rank ORDER BY ground_level DESC;
SELECT node_id, ground_level, $r ORDER BY $r ASC;
```
