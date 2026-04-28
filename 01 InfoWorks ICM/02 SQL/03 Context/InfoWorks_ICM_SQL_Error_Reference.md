# InfoWorks ICM SQL Error Reference

**Purpose:** Quick diagnostic reference mapping common error messages to solutions and pattern IDs. Load conditionally when debugging issues.

**Load Priority:** DEBUGGING - Load when errors occur
**Load Condition:** CONDITIONAL - When query contains error/debugging keywords
**Keywords:** error, exception, fails, broken, debugging, invalid, unrecognised, cannot

**Last Updated:** March 18, 2026

## How to Use This File

**For LLMs:** Use this file to:
- Diagnose error messages by matching symptom to cause
- Find quick fixes for common errors
- Identify which pattern (PAT_SQL_XXX_NNN) provides correct solution
- Understand root causes to prevent similar errors

**Prerequisite:** Many errors are prevented by reading `Lessons_Learned.md` FIRST

**Related Files:**
- `InfoWorks_ICM_SQL_Lessons_Learned.md` - PREVENTS most errors listed here
- `InfoWorks_ICM_SQL_Function_Reference.md` - Function signatures to verify correct usage
- `InfoWorks_ICM_SQL_Pattern_Reference.md` - Pattern IDs referenced in solutions
- `InfoWorks_ICM_SQL_Syntax_Reference.md` - Correct syntax for all clause types

---

## Error Processing Phases

InfoWorks ICM SQL processes queries in 4 phases. Errors in earlier phases prevent later phases from running:

1. **Phase 1 - Parsing:** Splitting text into keywords, field names, variables, constants
2. **Phase 2 - Clause identification:** Identifying clause types and splitting into sub-clauses
3. **Phase 3 - Clause handling:** Processing individual clauses
4. **Phase 4 - Validation:** Checking variable and field names are valid

---

## Phase 1: Parse Errors

### "error parsing query: invalid character at start of token"

**Symptom:** Error mentions an invalid character (e.g., `:`)
**Cause:** Using a character not valid in keywords, variable names, or field names
**Solution:** Remove invalid characters. Common culprits: `:`, `@`, `#` (outside date literals), `!`

**Quick Fix:**
```sql
// WRONG - colon is invalid
SELECT node_id: ground_level;

// CORRECT
SELECT node_id, ground_level;
```

---

### "error parsing query: invalid character after field separator"

**Symptom:** Error after the `.` in a field reference
**Cause:** Invalid character after the dot separating parts of a field or variable name
**Solution:** Ensure only valid identifier characters follow the `.`

**Quick Fix:**
```sql
// WRONG
SELECT us_node.!ground_level;

// CORRECT
SELECT us_node.ground_level;
```

---

## Phase 2: Clause Structure Errors

### "Keyword '<keyword>' found more than once in clause"

**Symptom:** Duplicate keyword error
**Cause:** Using the same keyword twice in one clause
**Solution:** Split into separate clauses or fix the keyword

**Quick Fix:**
```sql
// WRONG - SELECT used twice
SELECT ALL FROM Node SELECT x > 0;

// CORRECT - Second SELECT should be WHERE
SELECT ALL FROM Node WHERE x > 0;
```

---

### "Only one of the keywords SELECT, DESELECT and DELETE can be used within a clause"

**Symptom:** Multiple action keywords in one clause
**Cause:** Trying to combine incompatible actions
**Solution:** Split into separate clauses separated by semicolons

---

### "Keyword SET cannot be used with SELECT, DESELECT, DELETE or GROUP BY"

**Symptom:** SET mixed with selection or grouping keywords
**Cause:** Trying to combine assignment with selection in one clause
**Solution:** Use separate clauses

**Quick Fix:**
```sql
// WRONG - SET with SELECT
SET user_number_1 = 1 SELECT WHERE x > 100;

// CORRECT - Separate clauses
SET user_number_1 = 1 WHERE x > 100;
SELECT WHERE user_number_1 = 1;
```

---

### "Keyword GROUP BY cannot be used without the keyword SELECT"

**Symptom:** GROUP BY without SELECT
**Cause:** Missing SELECT keyword before GROUP BY
**Solution:** Add SELECT with the expressions to aggregate

---

### "The GROUP BY sub-clause cannot be placed before the WHERE sub-clause"

**Symptom:** Ordering error in GROUP BY query
**Cause:** WHERE must come before GROUP BY
**Solution:** Reorder: `SELECT ... WHERE ... GROUP BY ... HAVING ... ORDER BY ...`

**Quick Fix:**
```sql
// WRONG - Wrong order
SELECT COUNT(*) GROUP BY system_type WHERE node_type = 'manhole';

// CORRECT - WHERE before GROUP BY
SELECT COUNT(*) WHERE node_type = 'manhole' GROUP BY system_type;
```

---

### "The HAVING sub-clause cannot be placed before the GROUP BY sub-clause"

**Symptom:** HAVING before GROUP BY
**Cause:** HAVING must come after GROUP BY
**Solution:** Reorder clauses

---

### "Invalid table name '<tablename>'"

**Symptom:** Unrecognised table name after FROM or UPDATE
**Cause:** Misspelled table name or missing square brackets for multi-word names
**Solution:** Check spelling. Use `[Square Brackets]` for names with spaces.

**Quick Fix:**
```sql
// WRONG - Missing brackets
SELECT FROM All Nodes WHERE x > 100;
UPDATE River Reach SET user_number_1 = 1;

// CORRECT
SELECT FROM [All Nodes] WHERE x > 100;
UPDATE [River Reach] SET user_number_1 = 1;
```

---

### "Invalid syntax for SET clause - must be UPDATE (ALL | SELECTED) (table name) SET"

**Symptom:** Malformed UPDATE clause
**Cause:** Extra tokens between UPDATE and SET
**Solution:** Fix syntax: `UPDATE [table] SET` or `UPDATE ALL [table] SET` or `UPDATE SELECTED [table] SET`

**Quick Fix:**
```sql
// WRONG - Extra token
UPDATE x x SET user_number_1 = ground_level;

// CORRECT
UPDATE Node SET user_number_1 = ground_level;
```

---

### "Queries cannot access more than one array field"

**Symptom:** Query fails when one clause references two different array/blob fields such as `left_bank.*` and `right_bank.*`
**Cause:** Bare array field expressions can only access one array field per expression
**Solution:** Split the work into separate clauses, one per array field

**Quick Fix:**
```sql
// WRONG - two array fields in one expression
UPDATE SELECTED [River Reach]
SET left_bank.modular_ratio = 0.67,
	right_bank.modular_ratio = 0.67;

// CORRECT - separate clauses
UPDATE SELECTED [River Reach] SET $selected = 1;
SET left_bank.modular_ratio = 0.67, left_bank.discharge_coeff = 0.8 WHERE $selected = 1;
SET right_bank.modular_ratio = 0.67, right_bank.discharge_coeff = 0.8 WHERE $selected = 1;
```

---

### "Variable <name> has already been defined"

**Symptom:** Duplicate variable definition
**Cause:** Defining the same variable twice with LET or LIST
**Solution:** Remove the duplicate. To reassign a scalar, just use `LET $var = new_value;` after initial definition (but not two LIST or two LET definition clauses).

---

### "Variable <name> is not a valid list of comma separated values"

**Symptom:** LIST definition rejected
**Cause:** Missing commas between values, trailing comma, or no separator

**Quick Fix:**
```sql
// WRONG - Missing commas
LIST $widths = 200 300 400;

// WRONG - Trailing comma
LIST $widths = 200, 300, ;

// CORRECT
LIST $widths = 200, 300, 400;
```

---

### "Variable <name>: lists must be lists of numbers, strings or dates"

**Symptom:** Invalid values in LIST
**Cause:** Unquoted strings in a list

**Quick Fix:**
```sql
// WRONG - Unquoted strings
LIST $directions = D, U;

// CORRECT - Quoted strings
LIST $directions = 'D', 'U';
```

---

### "Variable <name>: all values in the list must be of the same type"

**Symptom:** Mixed types in LIST
**Cause:** Mixing numbers, strings, and/or dates in one list

**Quick Fix:**
```sql
// WRONG - Mixed types
LIST $mixed = 1, 'two', 3;

// CORRECT - All same type
LIST $numbers = 1, 2, 3;
LIST $strings = '1', '2', '3';
```

---

### "LET clause is too long"

**Symptom:** LET clause rejected
**Cause:** Trying to assign an expression involving field values or complex calculations in a LET clause
**Solution:** LET can only assign scalar expressions (constants, other scalars). For field-based calculations, use SET or SELECT INTO.

**Quick Fix:**
```sql
// WRONG - LET cannot use field values
LET $area = $diameter * $pi;  // This works only if $diameter and $pi are already scalars

// WRONG - LET with field calculation
LET $area = contributing_area * 2;  // Cannot reference fields in LET

// CORRECT - Use SET for field-based calculations
SET $area = contributing_area * 2;

// CORRECT - Use SELECT INTO for aggregate results
SELECT SUM(contributing_area) INTO $total_area;
```

---

## Phase 3: Clause Handling Errors

### "Expected = after name of field to assign to"

**Symptom:** Assignment syntax error in SET
**Cause:** Using wrong operator after field name

**Quick Fix:**
```sql
// WRONG
SET user_number_1 > 23;

// CORRECT
SET user_number_1 = 23;
```

---

### "Too many function parameters" / "Too few function parameters"

**Symptom:** Wrong number of arguments to a function
**Cause:** Passing incorrect number of parameters
**Solution:** Check `Function_Reference.md` for correct parameter count

**Quick Fix:**
```sql
// WRONG - LEFT takes 2 parameters
SET user_text_1 = LEFT(node_id);

// CORRECT
SET user_text_1 = LEFT(node_id, 2);
```

---

### "More than one parameter for aggregate function"

**Symptom:** Aggregate function has multiple parameters
**Cause:** Passing comma-separated expressions to COUNT, MIN, MAX, etc.
**Solution:** Aggregate functions take exactly one expression

**Quick Fix:**
```sql
// WRONG
SET user_number_1 = COUNT(x, y);

// CORRECT
SET user_number_1 = COUNT(x > 0);
```

---

### "Too many levels of aggregate functions"

**Symptom:** Nested aggregate error
**Cause:** More than two levels of aggregate nesting, or nesting outside GROUP BY context
**Solution:** Only one level of nesting is valid, and only in GROUP BY clauses

**Quick Fix:**
```sql
// WRONG - Too many levels
SELECT COUNT(COUNT(COUNT(details.*))) GROUP BY direction;

// WRONG - Nesting outside GROUP BY
SELECT COUNT(COUNT(details.*));

// CORRECT - One level of nesting in GROUP BY
SELECT SUM(COUNT(details.*)) GROUP BY direction;
```

---

### "Unrecognised function - <functionname>"

**Symptom:** Function name not found
**Cause:** Misspelled function or using a function that doesn't exist
**Solution:** Check `Function_Reference.md` for available functions. Common mistakes: `LENGTH` (should be `LEN`), `SUBSTR` (should be `MID`), `CONCAT` (use `+`)

---

### "Functions cannot be assigned to" / "Aggregate functions cannot be assigned to"

**Symptom:** Trying to SET a function result
**Cause:** Putting a function on the left side of an assignment

**Quick Fix:**
```sql
// WRONG
SET LEN(node_id) = 10;
SET COUNT(details.*) = 10;

// CORRECT - Functions are read-only; assign to fields
SET user_number_1 = LEN(node_id);
SET user_number_1 = COUNT(details.*);
```

---

### "AS cannot appear at the end of a SELECT sub-clause"

**Symptom:** Missing alias after AS
**Cause:** AS keyword without a following alias name

**Quick Fix:**
```sql
// WRONG
SELECT COUNT(*) AS GROUP BY status;

// CORRECT
SELECT COUNT(*) AS [Total Count] GROUP BY status;
```

---

### "'<text>': invalid name for alias after AS keyword"

**Symptom:** Invalid alias after AS
**Cause:** Using a number or invalid token as alias

**Quick Fix:**
```sql
// WRONG
SELECT COUNT(*) AS 23 GROUP BY status;

// CORRECT
SELECT COUNT(*) AS [Count] GROUP BY status;
```

---

## Phase 4: Field and Variable Validation Errors

### "<fieldname> is not a recognized field name"

**Symptom:** Field name not found
**Cause:** Wrong field name for the current table, or using a display name instead of database field name
**Solution:** See `InfoWorks_ICM_SQL_Schema_Common.md` for the Autodesk Help workflow. Ensure you use the correct **database field name**, not the UI display name.

**Quick Fix:**
```sql
// WRONG - Using display name
SELECT Width FROM Conduit;

// CORRECT - Using database field name
SELECT conduit_width FROM Conduit;
```

---

### "<fieldname> - * used in an invalid context"

**Symptom:** Asterisk used incorrectly
**Cause:** Using `*` outside the valid aggregate contexts
**Solution:** `*` is only valid in: `COUNT(*)`, `ANY(something.*)`, `COUNT(something.*)`

**Quick Fix:**
```sql
// WRONG
SELECT * FROM Node;

// CORRECT
SELECT node_id, x, y, ground_level FROM Node;
SELECT COUNT(*) GROUP BY system_type;
SELECT COUNT(details.*) FROM [CCTV Survey];
```

---

### "variable <name> is not a list variable but is being used in a list context"

**Symptom:** Non-list variable used where list expected
**Cause:** Passing a scalar variable to AREF, MEMBER, RINDEX, etc.
**Solution:** Define the variable with LIST, not LET

**Quick Fix:**
```sql
// WRONG - $codes is a scalar
LET $codes = 'AB';
SELECT WHERE MEMBER(details.code, $codes);

// CORRECT - $codes is a list
LIST $codes = 'AB', 'CD', 'EF';
SELECT WHERE MEMBER(details.code, $codes);
```

---

### "variable <name> has already been used in a different context"

**Symptom:** Variable type conflict
**Cause:** Using a variable that was set for nodes in a links context, or vice versa
**Solution:** Use different variable names for different object types, or use the variable in a compatible context (e.g., set for Conduit, use for [All Links])

---

## Common Runtime Mistakes (No Error Message)

### Query Runs But Selects Nothing

**Symptom:** Query executes without error but no objects are selected
**Possible Causes:**
1. Wrong field name (field doesn't exist for this object type → evaluates to NULL → not selected)
2. The "Apply to current selection" checkbox is checked but nothing is currently selected
3. Wrong object type specified in header comment
4. String comparison expecting case sensitivity (all comparisons are case insensitive)

**Solution:** See PAT_SQL_SEL_004. Verify field names, selection state, and object type.

---

### SET Changes Not Visible

**Symptom:** SET clause executes without error but values appear unchanged
**Possible Causes:**
1. Setting object variables (`$var`) instead of actual fields — object variables are temporary
2. "Apply to current selection" is checked but target objects aren't selected
3. Setting values in wrong scenario (add `IN CURRENT SCENARIO` or `IN BASE SCENARIO`)

---

### Wrong Results from AVG on Time Series

**Symptom:** AVG of tsr.* results doesn't match expected simple average
**Cause:** AVG for time series is **time-weighted**, not a simple arithmetic mean. It accounts for varying timestep lengths.
**Solution:** This is correct behavior. If you want a simple average, use `SUM(tsr.value) / COUNT(tsr.value > -999999)` (but this is rarely what you actually want).

---

### LIKE Pattern Doesn't Match Expected Objects

**Symptom:** LIKE query returns unexpected results
**Cause:** Using `%` (standard SQL) instead of `*` (InfoWorks), or trying to use `*` at the beginning
**Solution:** See Lessons_Learned. Use `?` for single char, `*` only at the end.

**Quick Fix:**
```sql
// WRONG - Standard SQL wildcards
SELECT WHERE node_id LIKE '%MH%';

// CORRECT - But limited: can only match start
SELECT WHERE node_id LIKE 'MH*';

// CORRECT - For complex matching, use MATCHES with regex
SELECT WHERE node_id MATCHES '.*MH.*';
```

---

### "The following scenarios are used in this SQL query but are currently invalid: &lt;name&gt;"

**Symptom:** Dialog box appears at runtime: *"The following scenarios are used in this SQL query but are currently invalid: &lt;scenario_name&gt;"*
**Cause:** `ADD SCENARIO` and `IN SCENARIO 'name'` (for the same name) are in the **same SQL block**. ICM validates all scenario references before executing any statements, so the new scenario is not yet recognised.
**Solution:** Split into separate, ordered SQL scripts. See PAT_SQL_SCENARIO_047 and Lessons_Learned.

---

**Cross-References:**
- `InfoWorks_ICM_SQL_Lessons_Learned.md` - Prevents most errors in this file
- `InfoWorks_ICM_SQL_Function_Reference.md` - Correct function signatures
- `InfoWorks_ICM_SQL_Pattern_Reference.md` - Working code templates
- `InfoWorks_ICM_SQL_Syntax_Reference.md` - Complete syntax rules
