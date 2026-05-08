Overview
This document describes the SQL functionality available in InfoWorks (CS, SD, WS, RS and ICM) and InfoNet. Some of the functionality is only available in certain products as noted e.g. the functionality relating to scenarios is only available in InfoWorks ICM and InfoNet. This is noted in italics.

Introduction
An SQL block set up in InfoWorks ICM and InfoNet consists of one or more 'clauses'. If there is more than one clause then they must be separated by semicolons.
There are a variety of clause types as follows:
1. SELECT - can be used both to select objects in the network, and produce reports of data in grids and CSV files
2. DESELECT - can be used to deselect objects in the network.
3. DELETE - can be used to delete objects in the network.
4. SET / UPDATE - can be used to set values, both of fields in objects in the network and in a number of types of variables (the relationship between SET and UPDATE will be described below). 
5 INSERT - can be used to insert objects into the network.
6. CLEAR SELECTION - can be used to clear the selection in the network.
7 Clauses allowing the addition and deletion of scenarios from networks (ADD SCENARIO, DROP SCENARIO) ICM and InfoNet only. 
8. A number of clause types relating to the use of variables (LET, LIST, SAVE, LOAD, SCALARS)
9. A number of clause types relating to the display of dialogs allowing users to enter data and select values from lists etc. (PROMPT LINE, PROMPT TITLE, PROMPT DISPLAY, SCALARS)
10. A number of clause types that can be used to control the flow of logic in a script (IF, ELSEIF, ELSE, END, WHILE, WEND, BREAK)
In addition to clauses beginning with these keywords, it is possible to enter clauses consisting only of expressions (e.g. x > 10000) which are equivalent to the simplest form of SELECT clause used to select objects in the network.

Basic SELECT
Introduction to basic arithmetic and comparison
In its simplest form, SQL may be used to select objects for which an expression is true. What this means exactly will be handled in a later section, but for now we will confine ourselves to uncontroversial arithmetic and string comparisons.

The available arithmetic operators are:
+ Addition
- Subtraction 
* Multiplication
/ Division
^ Exponent (e.g. width^2, area^0.5)
% Modulus 

It is also possible to use '-' to negate a number, this is known as 'unary minus'. 
These arithmetic operators follow the normal operator precedence, with unary minus having the highest precedence, then exponent, then division and multiplication, then finally addition and subtraction. 
For example a * b + c means multiply a and b, then add c. 
You can use brackets to override these precedence rules e.g. a * (b + c) means add b and c then multiply by a. 
There is nothing to stop you from using brackets where they are not needed in order to clarify your intention. There is no harm in writing (a * b) + c instead of a * b + c.
You can also use the addition operator '+' to join strings. For example, if user text 1 were 'X12' and user text 2 were 'Y34' then user_text_1 + user_text_2 would yield 'X12Y34'.
None of the other operators listed above have any special meaning for strings. The behaviour if you do use one of these operators with two strings, or with a string and a number etc. will be described in detail in a later section.
You can use comparison operators to compare values to see if they are equal, one is greater than the other etc. The available comparison operators are
= Equality
>= Greater than or equal to
> Strictly greater than
<= Less than or equal to
< Strictly less then
<> Not equal to

The comparison operators have a higher precedence than the arithmetic operators. This means that if you say something like a + b * c >= d + e * f , the left and right hand sides of the comparison operator are evaluated, then the comparison is done.
There are three things to note about string comparison:
1. String comparison in InfoWorks and InfoNet is always case insensitive. 
2. When using less than, greater than, greater than or equal to and less than or equal to, the behaviour will depend on the behaviour of the language in which you are using Windows. 
3. In InfoWorks and InfoNet strings are always trimmed so that they have no leading or trailing spaces or 'tab' characters i.e. a string can never start or finish with a string or a tab. 

Having described the arithmetic and comparison operators, the next question that will spring to mind is what can be manipulated with the arithmetic operators and what can be compared.
We will start by considering two things: fields and constants. Other things, including variables, will be explained in a later section.
Fields can be found in the pull down lists on the SQL dialog. The fields fall into a number of categories:
1. Fields in the current table e.g. node_id, us_node_id, x, y, width, height
2. Results fields e.g. sim. (for simulation results in the InfoWorks products)
3. Fields in joined tables
These fall into two distinct categories
a. one-to-one links - links where there can be only one object linked - e.g. the link from a link to its upstream node is a one-to-one link since any given link can only be linked to one (or zero) upstream node.
b. one-to-many links - links where there can be more than one object linked - e.g. the link from a node to links upstream of it is a one-to-many link since any given node can have zero, one, two or more links upstream of it.
4. Fields in 'structure blobs' e.g. details in CCTV surveys in asset networks in ICM / InfoNet and demand_by_category for nodes in InfoWorks WS.
5. OID. The read only field name  OID can be used to obtain the object ID. This can be used to get multi-part IDs for objects that have multi-part IDs, with the parts separated by '.'. The name OID is used to avoid a clash with those objects that have a field named 'id'. 

As well as these main categories, there are some special cases which will be described later in this document. 
The fields in the current table have the meanings you would expect. The others will be explained in later sections. 
You may wonder what happens when you have selected more than one table in the pull-down list of tables e.g. 'All Nodes', 'All Links', and a given object is of a type that does not have a particular field e.g. if the object for which the query is being evaluated is a conduit and the field is specific to a flap valve. This will be explained in the next section once the special value used has been described.

Constants fall into 5 types
1. Numbers - simply put the number in, with or without decimal points and the minus sign e.g. 123, -123, 123.45, -123.45.
InfoWorks and InfoNet do not recognise scientific notation.
2. Strings - strings should begin and end with the single quote character ' e.g. 'mynodeid' or the double quote character e.g. "mynodeid". If you begin a string with one of these you must end it with the same one. 
To include the single quote character within a string, use the double quotes at the beginning and the end of the string. To include the double quote character within a string, use the single quotes at the beginning and the end of the string.
3. Boolean - The Boolean data type and the two constant values will be described later in this document.
4. Dates - Date constants begin and end with the # character. The behaviour of dates is based on the behaviour of the underlying Windows libraries, the behaviour of which is similar to that of dates in Excel. The rules are as follows:
a. Behaviour depends on the 'locale' setting if your PC
b. If you are in the UK or another country using dates of the form dd/mm/yyyy  then dates should be entered #day/month/year# e.g. #31/1/2008#. 
c. If you are in the US or another country using dates of the form mm/dd/yyyy then dates should be entered #month/day/year# e.g. #1/31/2008#
d. If you are in Japan, China or another country using dates of the form yyyy/mm/dd then dates should be entered #2008/31/1#
e. It is possible but not recommended to enter dates without using all 4 digits in the year (e.g. #1/31/08#). The behaviour of 2 digit years is determined by the regional and language options control panel - see http://support.microsoft.com/kb/214391 for details. 
f. It is also possible but also not recommended to enter dates of only two parts e.g. #1/12#. In both of these cases the underlying date library will resolve this as described in the above Microsoft knowledge base article.
g. If you are using dates of the form dd/mm/yyyy or mm/dd/yyyy and you enter a date which is invalid in the form you are using, but valid in the other of these two forms, the date will be interpreted as the other e.g. if you are in the US and enter #31/1/2008#, this is an invalid date since there is no 31st month, however it would be valid as a UK date, so it is treated as being the 31st of January 2008
5. NULL - this is a special value, described in the next section of this document. 

NULL field values and associated operators
In InfoWorks and InfoNet, numerical fields can usually be blank. In SQL this is represented as a special value called 'NULL', and the fields are said to 'be NULL'.
You can see if fields are aren't NULL by using the special constructs 'IS NULL' and 'IS NOT NULL' e.g. ground_level IS NULL, ground_level IS NOT NULL. 
We are now in the position to answer the question posed above, as to what value is returned for objects that do not have a particular field when the query is being evaluated for a number of different types of object e.g. 'All Links'.
The answer is simply that the NULL value is returned for any object that does not have the field in question. 
Note that fields of the Boolean data type, described below, are never treated as NULL from the point of view of the SQL. 

Logical operators
You can combine the expressions built up so far with the logical operators AND, OR and NOT e.g.
x>10000 AND y>20000 will select nodes where the x coordinate is greater than 10000 AND the y coordinate is greater than 20000.
x>10000 AND y>20000 will select nodes where the x coordinate is greater than 10000 AND the y coordinate is greater than 20000. 
As with all implementations of SQL and in common usage for programming languages 'A or B' means A is true, B is true OR both A and B are true. This is often referred to as 'inclusive or', and is slightly different from the way in which the word 'or' is sometimes used in day to day English. 
When the keyword NOT is used it will select objects for which the expression to which the NOT applies is not true.
The keyword AND has higher precedence than the keyword OR, so A OR B AND C OR D means the same thing as (A OR B) AND (C OR D). As with the other operators described above it is possible to override this precedence rule by using brackets, so you can say things like A OR (B AND C) OR D. 

String operators
There are two operators which can be used to perform more sophisticated tests on strings than the tests described above. These operators are LIKE and MATCHES.
LIKE may be used to perform relatively simple tests on strings by testing for prefixes and a match in the number of characters in a string. This is done by using the special characters ? and *.
? matches any character
* matches the rest of the string
Any other character matches only that character itself - in common with the string comparisons described above this matching is case insensitive.
e.g.
node_id LIKE 'MH12345' will match only the string MH12345, since no special characters are included in the string on the right of the LIKE operator.
node_id LIKE '????????' will match any 8 character node ID
node_id LIKE 'MH??????' will match any 8 character string beginning MH
node_id LIKE '??1????' will match any node ID with 1 as the 3rd character
node_id LIKE 'MH*' will match any node ID beginning with MH
node_id LIKE 'MH??*' will match any node ID at least 4 characters long beginning with MH. 

You cannot check for anything after * has been used in the pattern on the right of the LIKE operator, e.g.
node_id LIKE '*01'cannot be used to match any node ID ending in 01. 
Similarly you cannot use * at the beginning and end to match something in the middle, so you cannot say
node_id LIKE '*01*' to match any node ID with 01 somewhere in the middle. 

MATCHES may be used to perform complex tests on strings by seeing if they match regular expressions. 
A full description of regular expressions falls outside the scope of this document.
Please note:
1. The regular expression matching, in common with the string comparisons described above and the LIKE keyword,  is case insensitive. 
2. The regular expression must match the whole of the string i.e. node_id MATCHES '[0-9]*' will only match node_ids containing only digits.
3. For 'notes' fields MATCHES will match multiline notes fields - use \n to match the end of a line (bearing in mind the note may or may not end in a \n). 

Data types and type conversion rules
Data Types
The InfoWorks and InfoNet databases contain data values of a number of types. These types are as follows:
1. A number of numerical types. From the point of view of SQL the differences between these types may largely be ignored as the numerical calculations are all performed using the same numerical data type (double precision floating point numbers). 
2. String.
3. Boolean.
The 'Boolean' data type is named after the British mathematician and philosopher George Boole (which is the reason the word is written with a capital letter at the beginning) and represents something that can either be true or false. In InfoWorks and InfoNet, Boolean values are typically represented by check-boxes which are checked if the variable is true and unchecked if it is false. 
The two constant values for Boolean variables are 'true' and 'false'.
Boolean fields are never treated as NULL from the point of view of SQL, values that are NULL in the database (which is only possible in InfoWorks ICM and InfoNet) are treated as being false for the purposes of SQL.
4. Date. This represents a date and time e.g. 12th January 2003 12:34. The time may or may not be relevant depending on the context in which it is being used.

All numerical calculations within the InfoWorks and InfoNet SQL engine are performed using the currently selected user units. 
The following is a technical description of exactly  how calculations are performed, with particular reference to what happens when you combine data types e.g. add a number to a string and then store the result in a Boolean field. 
Mixing Data Types in Binary Operators
A binary operator is one that takes two values e.g +, -, *, AND, >=. The word binary is used here meaning 'two', in this context it has nothing to do with binary numbers.
When operations are performed with a mixture of data types the following rules are applied in order:
1. If the operator is = and one of the two values being compared is NULL then this will return 'true' only if both of the values being compared is NULL, otherwise it will return 'false'.
2. If the operator is <> and one of the two values being compared is NULL, then this will return true if only one of the values being compared is NULL, if both are NULL then it will return 'false'. 
3. If the operator is + and one of the two values is a string, then the other value will be converted to a string (see below) and the two strings concatenated
4. If the operator is not OR and one of the two values is NULL then the result will be NULL
5. If the operator is OR and one of the two values is NULL, then other value is converted to a Boolean (see below) and that is the value of the expression i.e. if that value is 'false' then the result will be false, otherwise the result will be true.
The above are the only cases where an expression where one of the two values is NULL may not result in a result of NULL. This is in-line with 'normal' SQL behaviour. This is known as '3 valued logic' because in a sense as well as 'true' and 'false' there is a value of NULL. The underlying theory behind this is that NULL represents an absent or unknown value, and therefore if you attempt to perform any operation that combines an absent or unknown value with a known value, the result is still absent or unknown.
The following descriptions assume that neither of rules 4 and 5 have applied and therefore neither of the values is NULL. 
6. If the operator is +, -, /, * or ^, then both values are converted to numbers (see below) and the operation performed
7. If the operator is OR (and neither of the values is NULL) then both values will be converted to Boolean values, the result of the expression will be 'true' if either expression is true.
8. If the operator is AND then both values will be converted to Boolean values, the result of the expression will be 'true' if both of the expressions are true.
9. If the operator is <, >, >=, <=, <> or = (and not covered by one of rules 1, 2 or 4 above) then the two values will be compared according to the following rules in order and the result will be set to the Boolean value true or false depending on the result.
9.1. If either value is a date, then the other value will be converted to a date and a comparison performed.
9.2. If either value is a string, then the other value will be converted to a string (see below) and a comparison performed.
9.3. Otherwise, both values will be converted to numbers and a comparison performed.
10. If the operator is LIKE or MATCHES, the expression will be false unless both values are strings. If they are strings, the expression will be true or false depending on the result of the appropriate test.

Conversion to strings
1. Boolean values will be converted to the string '1' if true, '0' if false
2. Numbers will be converted to strings using the standard method used throughout InfoWorks and InfoNet, with any trailing zeros after the decimal point removed (e.g. if the number is 12.34000 it will have the final 3 zeros removed and the string will therefore be '12.34'). If there are no non-zero values after the decimal point, the decimal point will also be removed e.g. 123.00000 will have the trailing zeros removed, then will have the decimal point removed, therefore the resulting string will be '123'
3. Dates will be converted to strings using the short form which will be dd/mm/yyyy, mm/dd/yyyy or yyyy/mm/dd depending on how Windows is set up on the PC on which the software is being run. 
In InfoWorks, the time in the format hh:mm will be added to the end of the date. The time is not added in InfoNet.

Conversion to Boolean
For this purpose, the following are considered to be true:
1. Any string with one or more characters in it
2. Any date
3. Any number other than zero




The following are considered to be false, and therefore if the expression is evaluated for an object and is found to be one of the following, the object will not be selected.
1. NULL
2. Any string with no characters in it
3. The number zero

Conversion to numbers
1. If you assign a value from a date field into a number then the number given will be a floating point number representing the number of days since the 30th December 1899. This is a representation commonly used in Microsoft software.
2. Strings are converted to numbers if the string contains only a number, otherwise the value 0 will be used.
3. If you convert a Boolean field to a number, the value will be 1 if it is true, 0 if it is false. 

Unary operators
The unary operators behave as follows:
Unary minus will have the result of -1 * the number if it is a number, NULL otherwise.
NOT will convert the value it applies to to a Boolean (see above) and then invert that value (i.e. if the value it applies to is false the resulting value will be true, and vice versa).
IS NULL will have the result 'true' if the value it applies to is NULL, false otherwise.
IS NOT NULL will have the result 'false' if the value it apples to is NULL, true otherwise.

Determining which objects to select based on SQL expressions
When an SQL expression is used to determine which objects to select, all the objects will be selected for which the expression is evaluated and the result considered to be true.
The same criteria will be applied as described in 'conversion to Boolean' above. 

Simulation Results
Within InfoWorks, if you have the results of a simulation loaded into the GeoPlan you are able to run SQL queries incorporating the results of that simulation.
These results will appear in the list box for the object type in the SQL dialog prefixed with sim.
It is also possible to load the results of a second simulation by using the appropriate menu item. The results for this simulation will then also appear int eh list box for the object type in the SQL dialog prefixed with sim2.
These results will the the results at the current timestep, or the maximum results if the time control has been set to show the maximum results.
In InfoWorks WS and InfoWorks ICM only it is also possible to use simulation results for all timesteps by using the prefixes tsr and tsr2, in which tsr stands for time series results. 
In InfoWorks ICM only, it is possible to limit the timesteps used for time varying results by using a WHEN clause. 

One to one links
It is possible to include values for linked objects in SQL expressions. As described above these fall into two categories, at this stage we are only considering links where an object is linked to ONE other object (or possibly no object) of a particular type. 
If you are familiar with SQL in databases such as Microsoft Access, Oracle, MySQL etc. you may be familiar with this concept as being a 'join'. However, whereas in these packages you will have to join the table to the other table by means of a view or the JOIN keyword, in InfoWorks and InfoNet the joining is done for you automatically, taking advantage of the software's knowledge of its own data structures. These are sometimes referred to as 'implicit joins'.
The implicit one-to-one joins fall into two main categories:
1. In InfoWorks WS and RS only, joins between objects in the Network and associated objects in the Control (WS) or Event (RS).
2. Joins between related objects in the same Network.

The implicit joins are as follows:

ICM Modelling Network / CS Network / SD Network
From
To
Name
CCTV Conduit
Conduit
joined
Link
Node
us_node
Link
Node
ds_node
Subcatchment
Node
node
The link from CCTV conduit to conduit does not occur in ICM modelling networks.

ICM / InfoNet Collection Asset Network
CCTV Survey
Pipe
joined
Manhole Survey
Manhole
joined
GPS Survey
Manhole
joined
Monitoring Survey
Pipe
joined
Pipe Repair
Pipe
joined
Manhole Repair
Manhole
joined
Dye Test
Pipe
joined
Smoke Test
Pipe
joined
Smoke Defect
Smoke Test
joined
General Incident
Pipe
joined
Blockage Incident
Pipe
joined
Pollution Incident
Pipe
joined
Collapse Incident
Pipe
joined
Flooding Incident
Pipe
joined
Complaint Incident
Pipe
joined
Odor Incident
Pipe
joined
Pipe Clean
Pipe
joined
Link
Node
us_node
Link
Node
ds_node
Node
Pipe
lateral_pipe
Monitoring Survey
Node
node
General Incident
Node
node
Blockage Incident
Node
node
Pollution Incident
Node
node
Collapse Incident
Node
node
Flooding Incident
Node
node
Complaint Incident
Node
node
Odor Incident
Node
node
General Incident
Property
property
Blockage Incident
Property
property
Pollution Incident
Property
property
Collapse Incident
Property
property
Flooding Incident
Property
property
Complaint Incident
Property
property
Odor Incident
Property
property
Drain Test
Sanitary Manhole
sanitary_manhole
Drain Test
Storm Manhole
storm_manhole
Property
Sanitary Pipe
sanitary_pipe
Property
Storm Pipe
storm_pipe
Drain Test
Property
property
Monitoring Survey
Data Logger
data_logger


ICM / InfoNet Distribution Asset Network
GPS Survey
Node
joined
Monitoring Survey
Node
joined
Manhole Survey
Manhole
joined
Pipe Repair
Pipe
joined
Manhole Repair
Manhole
joined
Pipe Sample
Pipe
joined
General Incident
Pipe
joined
Burst Incident
Pipe
joined
Water Quality Incident
Pipe
joined
Complaint Incident
Pipe
joined
Link
Node
us_node
Link
Node
ds_node
Node
Pipe
lateral_pipe
General Incident
Node
node
Burst Incident
Node
node
Water Quality Incident
Node
node
Complaint Incident
Node
node


InfoWorks WS
Customer Point
Link
pipe
Incident Report
Link
pipe
Link
Node
us_node
Link
Node
ds_node
Demand Polygon
Node
node


InfoWorks RS
Link
Node
us_node
Link
Node
ds_node

As you can see, the 'joined' prefix has a number of different meanings depending on what is being joined. The 'joined' prefix is used in exactly those circumstances where the fields of the joined object appear in the grids in the software to the right of the object and in italics. 
In InfoWorks ICM and InfoNet, when the joined prefix is used there is always an alternative name reflecting the type that is joined.
Advanced Topics In Selection
This section considers the first group of more advanced features available within SQL in InfoWorks and InfoNet. 
The following are considered:
1. Selection by using more than one clause
2. Overriding the table name
3. Overriding selection behaviour
4. Deselection
5. Clearing the selection
6. Scenarios (InfoWorks ICM and InfoNet only)
7. Limiting the number of objects selected or deselected
8. A summary of special cases of selecting or deselecting all objects from a table etc.


Selection in multiple clauses
It is possible to select objects in a number of clauses which are evaluated one after another. The clauses should be separated with a semi-colon e.g.
x>10000; y>20000; ground_level > 15.5
Once you have more than one clause, the 'test' button on the SQL dialog will no longer tell you how many objects will be selected. Instead, the 'test' button will confirm that the query has the correct syntax.
Each clause will be executed in turn, and the objects for which the expression in the clause is true will be added to the selection. 
In this case it would be possible to write the query equivalently as 
x>10000 OR y>20000 OR ground_level > 15.5
As you will see later, however, there are more complex tasks that can be done with multiple clauses that cannot be reframed as a single query.

Overriding the table name
The first example of something that can be done with multiple clauses that cannot be done with a single query is the selection of objects in multiple tables.
Whilst an SQL query is for a particular table or group of tables e.g. Node, Pipe, All Nodes, All Links. This is referred to as the 'default' table, and this document will refer to it as A table, even though it is possible to select things from more than one tables using 'All Nodes','All Links' etc. 
It is possible to override that table by explicitly naming the table or tables in the clause. This is done by using the 'SELECT FROM' keyword e.g. if the default table is Node and you want to select all conduits with width greater than 100 mm you should say SELECT FROM Conduit WHERE width > 100. 
In the unlikely event that you wish to select all conduits you can omit the keyword WHERE and the expression after it and simply say SELECT FROM Conduit. 
If the table name you wish to use contains spaces in it, it is necessary to put square brackets before and after the name e.g. SELECT FROM [All Links] WHERE width > 100. It is in fact possible to enclose any table name within square brackets, even if this is not necessarly, so you can in fact say SELECT FROM [Conduit] WHERE width > 100.

Overriding the default selection behaviour
The check-box on the SQL dialog determines whether the query is applied to all objects or to the currently selected objects. 
If the check box is unchecked then the query will be applied to all objects of the appropriate type, if it is checked then the query will only be applied to the currently selected objects of that type. This is referred to as the 'default selection behaviour'.
This behaviour can be overridden by using the keywords ALL or SELECTED.
ALL will override the behaviour of the check-box to make the query be run for all objects of the appropriate type, whereas SELECTED will override the behaviour of the check-box to make the query be run for only the selected objects of the appropriate type.
If you are using the default table then you can override the behaviour by saying SELECT ALL WHERE followed by the expression or SELECT SELECTED WHERE followed by the expression e.g. SELECT ALL WHERE x > 10000, SELECT SELECTED WHERE y > 20000.
If you are overriding the table name as described above, you should add the keyword ALL or SELECTED between the keywords SELECT and FROM e.g. SELECT ALL FROM [All Nodes] WHERE x > 20000, SELECT SELECTED FROM Conduit WHERE width > 200.
In the unlikely event you wish to select all objects in the default table you can say SELECT ALL. Similarly if you want to select all objects of another type you can say SELECT ALL FROM followed by the table name e.g. SELECT ALL FROM Conduit. 

DESELECT
In addition to selecting objects, it is possible to deselect objects i.e. make objects that were selected unselected. This is done by using the keyword DESELECT, usually followed by the keyword WHERE followed by an expression e.g. DESELECT WHERE x > 10000. Any expression that can be used to select objects can be used to deselect objects.
It is possible to override the default table as described above by saying DESELECT FROM followed by the table name, usually followed by the keyword WHERE followed by an expression e.g. DESELECT FROM [All Links] WHERE width > 200.
If you wish to deselect all objects from the default table you can say DESELECT. Similarly if you want to deselect all objects from another table you can say DESELECT FROM followed by the table name e.g. DESELECT ALL FROM Conduit. 
It is in fact possible to use the extra keywords ALL and SELECTED as described above but in practice they are not required, since deselecting all objects and deselecting selected objects have the same effect.

CLEAR SELECTION
As well as selecting and deselecting objects it is possible to clear the entire selection. This is done using the keywords CLEAR SELECTION on their own as a separate clause. This has a different effect from saying DESELECT or DESELECT FROM followed by a table name as described above, since they remove objects of a particular type or types from the selection whereas CLEAR SELECTION clears the selection completely.

Scenarios
This section applies to InfoWorks ICM and InfoNet only.
Queries normally work on the current scenario, this can be overridden by using the keywords 
IN BASE SCENARIO
IN SCENARIO 'name'
IN SCENARIO $scalarvariable
(scalar variables are described below)

It is also possible to say
IN CURRENT SCENARIO
although this is the default behaviour

The expression can be omitted in which case everything in that scenario is selected e.g.
SELECT IN SCENARIO 'bert' 

This can be combined with the existing SELECTED and ALL keywords and the overriding of table names e.g.
SELECT SELECTED FROM [All Nodes] IN BASE SCENARIO WHERE x > 644000

The current scenario can be overridden in the same way for deselection e.g.
DESELECT ALL FROM [All Nodes] IN SCENARIO 'east' WHERE x < 644000
In these cases the meaning in which IN SCENARIO is used that the objects are in the scenario, not the selection.

Limiting the number of objects selected or deselected
In order to limit the number of objects selected or deselected it is necessary to specify the criteria by which you are limiting the number of objects. This is done using an ORDER BY sub-clause in conjunction with the keywords TOP and BOTTOM.
This is described in a separate section below. 

Selecting or deselecting all objects in a table
It is possible to select all objects in the default table by saying SELECT. This also works on multiple tables if the default table is something like 'all nodes' or 'all links'. There are numerous other ways of selecting all objects which rely on the fact that when the expression is run, all objects for which the expression is true will be selected e.g.
1, true, 'anystring'. 
As described above it is possible to select all objects in a table other than the default table by saying SELECT FROM  followed by the table name e.g. SELECT FROM [All Nodes]. 
These queries will only change the selection if the default selection behaviour is to select all objects rather than to apply the query to the current selection, otherwise you are simply selecting all the objects that are already selected.
If you want to explicitly override the default selection behaviour you should say SELECT ALL or SELECT ALL followed by the table name.
As described above it is also possible to deselect all objects in the default table or another table. 

DELETE
It is possible to delete objects using SQL by using the DELETE keyword. In general the way that objects are deleted is very similar to the way in which they can be selected or deselected.
To delete objects from the default table for which a given expression is true, the keywords DELETE WHERE should be used, followed by the appropriate expression e.g. DELETE WHERE x > 10000. 
This will use the default table and the default selection behaviour. To override the default table the keywords DELETE FROM followed by the table name followed by WHERE followed by the expression should be used e.g. DELETE FROM [All Links] WHERE width > 100.
As with selection and deselection it is possible to override the default selection behaviour by using the keywords ALL and SELECTED e.g. DELETE ALL WHERE x > 10000, DELETE SELECTED WHERE y > 20000. 
It is possible to override the default selection behaviour and the default table e.g. DELETE ALL FROM [All Links] WHERE width > 100.
In the unlikely event you wish to delete all objects from the current table you can say DELETE ALL. DELETE SELECTED will delete all selected objects from the current table. The keyword DELETE on its own will follow the default selection behaviour and either delete all objects or delete all selected objects depending on whether or not the check-box is checked. 
Similarly, it is possible to delete all or selected objects from another table by using the syntax described above for deleting some objects from a table but omitting the keyword WHERE and the expression following it e.g.
DELETE ALL FROM [All Links], DELETE SELECTED FROM [CCTV Survey], DELETE FROM Node. 
The final one of these examples will follow the default selection behaviour and either delete all objects or all selected objects from the nodes table depending on whether or not the check-box is checked.

(InfoWorks ICM and InfoNet only)
As with selection and deselection it is possible to delete objects in scenarios e.g.
DELETE ALL FROM [All Nodes] IN SCENARIO 'west' WHERE x < 644000. It is also possible to restrict the number of objects deleted with a GROUP BY clause in conjunction with the TOP and BOTTOM keywords as described below.  

(InfoWorks ICM and InfoNet only)
It is possible to delete from structure blobs by saying
DELETE FROM [Table Name].blob_name WHERE condition
This deletes the contents of the blobs but not the object in the table. The condition may be omitted. The condition may include fields in the blob and fields in the object i.e. you can selectively delete rows in the blobs based on a combination of conditions for the blob and the object.

Updating data with SET and UPDATE
As well as selecting, deselecting and deleting objects, it is possible to use SQL to set values for fields in objects in the InfoWorks and InfoNet networks.
If you wish to set values for fields for objects in the default table, this may be done with the SET keyword. 
It is possible but not necessary to have a WHERE sub-clause.
As with selection, deselection and deletion, values will either be set for all objects or only for selected objects depending on the setting of the check-box. 
If you do not have a WHERE sub-clause then the assignment will be done for all objects or all selected objects, otherwise it will only be performed for the objects for which the WHERE sub-clause is true.
It is possible to perform more than one assignment at once by separating them with commas. 
Examples:
SET user_number_1 = 123
SET user_number_2 = user_number_1 / width
SET user_number_1 = 123 WHERE x > 10000 AND y > 12000
SET user_number_1 = x, user_number_2 = y 
SET user_text_1 = 'XXX'+node_id, user_text_2 = asset_id WHERE width > 200

When you have more than one assignment in a clause separated by commas they are performed from left to right, so it is safe to assume that the value of a field in one assignment will be the value that it would be after performing all the assignments to its left in the clause.
It is possible to override the default table and the default selection behaviour. In both cases this is achieved by using the UPDATE keyword.
To override the default table, the clause should begin with UPDATE followed by the table name followed by the keyword SET and the rest of the clause as above e.g.
UPDATE [All Links] SET asset_id = ''
UPDATE [All Links] SET asset_id = '', user_number_1 = 0.0 WHERE width > 200
To override the default selection behaviour, begin the clause with UPDATE ALL or UPDATE SELECTED as appropriate.

To override both these two mechanisms should be combined e.g.
UPDATE SELECTED Node SET user_number_1 = 123.45
It is possible to set fields to the NULL value described above e.g. SET ground_level = NULL.
(InfoWorks ICM and InfoNet only)
It is also possible to override the scenario in which data is updated with the same modifiers in conjunction with the existing SELECTED and ALL keywords and the overriding of table names e.g.

UPDATE  IN SCENARIO 'east' set user_number_1 = 123
UPDATE  [All Links] IN SCENARIO 'newwest' set user_number_1 = 123
UPDATE  SELECTED [All Links] IN SCENARIO 'newnorth' set user_number_1 = 123

It is possible to limit the number of objects modified by use of the GROUP BY sub-clause in conjunction with the TOP and BOTTOM keywords as described below.

Adding New Data with INSERT
It is possible to insert objects into the network and insert rows into blobs. As with  SQL in relational databases such as Access, Oracle etc. it is possible to 
a) Insert individual objects (and rows in arrays) with the values supplied
b) Insert multiple objects based on selections from another table
The former of these is likely to be most use in conjunction with prompts and loops as described later in the document.
To add individual objects the syntax is:
INSERT INTO <table name> (field1,field2,... fieldn) VALUES (val1,val2,val3...,valn)

e.g.
INSERT INTO node (node_id,x,y) VALUES ('bert',123,456)
The number of values must match the number of values. All the values can be scalar expressions e.g. scalar variables, expressions including scalar variables e.g. bert+$i etc. (see below)

To insert values into a table from a SELECT statement the syntax is
INSERT INTO <table Name> (field1,field2,... fieldn) SELECT <select statement>

To add individual rows into an array field the syntax is

INSERT INTO <table name>.<blob name> (field1,field2... fieldn) VALUES (val1,val2,val3,... valn)
e.g.

The field names must be either
a) key field name of the table or
b) the array name followed by a . followed by a field in the array

All key field names of the table must be specified and objects into which lines in the array are being inserted must exist.

To insert values into a structure blob from a SELECT statement the syntax is
INSERT INTO <table name>.<array name>  SELECT <select statement>
e.g.
INSERT INTO [CCTV Survey].resource_details
       (id, resource_details.resource_id, resource_details.estimated_hours)
       SELECT id, 'TBD', 5  FROM [CCTV Survey]
       WHERE  COUNT(resource_details.*)=0

The number of items being selected must match the number of fields being set in the INSERT.

The select statement can include WHERE and ORDER BY but not GROUP BY or HAVING and can include selection of scenario, TOP and BOTTOM, and SELECTED etc. (some of these are discussed below for the first time)

(InfoWorks ICM and InfoNet only)
It is possible to add objects to a scenario by adding the scenario details after the list of fields e.g
INSERT INTO node(node_id,x,y) IN BASE SCENARIO...
INSERT INTO node(node_id,x,y) IN CURRENT SCENARIO...
INSERT INTO node(node_id,x,y) IN SCENARIO 'fred'...
INSERT INTO node(node_id,x,y) IN SCENARIO $bert..

Functions
In addition to field values and constants, there are a number of functions that may be used within SQL expressions. Each function requires a fixed number of 'arguments' to be passed to it and returns one value. 
The functions are as follows:

CONDITIONAL EXPRESSION

IIF
IIF(condition,first alternative, second alternative)
The IIF function returns the value of the second parameter if the first expression evaluates as true, otherwise returns the third.
e.g. IIF(service_total_score>total_score,service_total_score,total_score)>20
will select those objects with the maximum of the service_total_score and the total_score being greater than 20

NUMERICAL
Functions relating to conversion of floating point numbers to integers and taking of absolute values

ABS
ABS(number)
Calculates the absolute value of a number i.e. if the number is less than zero returns negative 1 times the number, turning it positive e.g. ABS(-3) = 3. If the number is zero or above it is unchanged.
e.g. SET user_number_1 = ABS(ground_level)

INT
INT(number)
INT takes the integer part of a number. If the number is an integer it will remain unchanged. 

FLOOR
FLOOR(number)
FLOOR returns the closest integer less than or equal to its parameter. Like INT it leaves integers unchanged. The difference between INT and FLOOR is that, whilst they will return the same value for positive numbers, INT will, by removing the fractional part of a number, make negative numbers larger (e.g. INT(-123.45) will be 123). FLOOR, on the other hand will make negative numbers more negative (e.g. FLOOR(-123.45) will be -124. 

CEIL 
CEIL(number)
CEIL returns the closed integer greater than or equal to its parameter. Like INT it leaves integers unchanged.
NUMBER CONVERSION AND FORMATTING
FIXED
FIXED(number_to_convert,number_of_decimal_places)
Given a number and a number of decimal places from 0 to 8, convert the number to a string with that number of decimal places, rounding up or down as appropriate. If the number of decimal places is 0 the string will have no decimal point.
e.g.
FIXED(1.9,3) is "1.900"
FIXED(1.9991,3) is "1.999"
FIXED(1.9999,3) is "2.000"

STRING MANIPULATION
Functions relating to the manipulation of strings.

LEN
LEN(string)
Returns the length of a string i.e. how many characters long the string is, so LEN('MYNODEID') would be 8. This is often used in conjunction with other string manipulation functions described below.
The function LEN may also be used to find the length of a list variable. List variables and the meaning of the LEN function in that context are described later in the document.
LEFT
LEFT(string,number of characters)
Returns a string containing the first n characters in a string, where n is the second parameter passed to the function e.g. LEFT('MX11112222',2) would be 'MX'. 
If the second parameter is zero or less, the empty string '' is returned. On the other hand, if the number is equal to or greater than the number of characters in the string the whole string is returned.

RIGHT
RIGHT(string, number of characters)
Returns a string containing the last n characters in a string, where n is the second parameter passed to the function e.g. RIGHT('MX11112222') would be '11112222'.
If the second parameters is zero or less, the empty string '' is returned. On the other hand, if the number is equal to or greater than the number of characters in the string the whole string is returned.

MID
MID(string,start position, number of characters)
Returns a string containing a number of characters from a string starting at a given position. The positions start from 1 for the first character, with 2 for the second etc. so
MID('MX11112222',1,2) giving 'MX', MID('MX11112222',3,4) giving '1111' and MID('MX11112222',7,4) giving '2222'. 
If the second parameter is 0 or less or greater than the number of characters in the string then the empty string is returned. If the third parameter is 0 or less than the empty string is returned. If the number of characters given in the third parameter is greater than the number of characters remaining starting from the second parameter, then the rest of the string is returned e.g. MID('MX12345678',9,999) would return '78', in this case the rest of the string starting from the 9th character.

SUBST
SUBST(string,thing to replace, thing to replace it with)
Replaces the first instance of the second parameter in the first with the third. E.g. SUBST('01880132','01','ND') returns 'ND880132'
GSUBST
GSUBST(string, thing to replace, thing to replace it with)
Replaces all instances of the second parameter in the first with the third e.g. GSUBST('01880132','01','ND') returns 'ND88ND32'

GENSUBST
GENSUBST(string, regexp, format)
Replaces the string with the format defined if regular expression regxp matches the string, otherwise returns the string unchanged.
e.g. SET user_text_1 = GENSUBST(node_id,'SK([0-9]*)','99\1')
will set user_text_1 to the node_id unless the node_id matches the regular expression 
'SK([0-9]*)', otherwise will set user_text_1 to 99 followed by the numerical part of the node_id following the SK. 
The regular expression may contain a number of bracketed sub-expressions. In this case there is one bracketed sub-expression ([0-9]*). The bracketing does not change what the regular expression will match, so 'SK([0-9]*)' will match the same things as will 'SK[0-9]*', however each sub-expression is given a number, starting with 1, and the text that matches that sub-expression may be used in the format by using that number preceded with a backslash. In this case what is happening is that a node ID consisting of the characters SK followed by a number of digits is replaced in the result of the function with the digits 99 followed by the string of digits from the node_id e.g. SK12345678 becomes 9912345678. 

NL
NL()
The NL function returns a new-line character e.g. to set up a 3 line note field use something like SET notes='THIS'+NL()+'THAT'+NL()+'THE OTHER'

DATE MANIPULATION
Functions relating to the manipulation of dates.

YEARPART
YEARPART(date)
Given a date, returns the year of the date as a number.

MONTHPART
MONTHPART(date)
Given a date, returns the month in the date as a number.

DAYPART
DAYPART(date)
Given a date, returns the day of the date as a number.

DATEPART
DATEPART(date)
Given a date, returns the date part as a date i.e. removes any minutes from the date so the value represents midnight at the beginning of that day.

TIMEPART
TIMEPART(date)
Given a date, returns the time part as a number in minutes e.g. if the date is 01/02/2008 12:34 this returns 754.0 - the number of minutes after midnight

NOW
NOW()
Returns the current date and times as a date.
This is the only function that doesn't take any parameters.

YEARSDIFF
YEARSDIFF(from,to)
Returns the number of complete years between the two dates as a number, which will be an integer. The calculation is based on midnight on the dates involved i.e. if from is 01/05/2008 at 12:34 and 'to' is 01/05/2009 at 12:29, this will count as a full year and therefore return 1. 

MONTHSDIFF
MONTHSDIFF(from,to)
Returns the number of complete months between the two dates as a number, which will be an integer. . The calculation is based on midnight on the dates involved.

DAYSDIFF
DAYSDIFF(from,to)
Returns the number of complete days between the two dates as a number, which will be an integer. . The calculation is based on midnight on the dates involved.

INYEAR(date,number)
Returns true if the date is in the year given as a number e.g.
INYEAR(when_surveyed,1993)

INMONTH(date,month,year)
Returns true if the date is in the year and month given as numbers e.g.
INMONTH(when_surveyed,3,1993)

INYEARS(date,startyear,endyear)
Returns true if the date is in a year between the start and end years inclusive e.g.
INMONTH(when_surveyed,1993,1995)

INMONTHS(date,startmonth,startyear,endmonth,endyear)
Returns true if the date is between the start month in the start year and the end month in the end year inclusive e.g.
INMONTHS(when_surveyed,10,1993,2,1994)

If any of the parameters to these functions are not numbers the function returns false. If the number is not an integer, the number is rounded to the nearest integer. 

ISDATE(putative_date)
If the field is a date because it has come from the database returns true, if it is a string then returns true if it can be converted into a date, otherwise returns false.
MONTHYEARPART(date) 
This function returns the string "<month>/<year>" e.g. "01/2010". As you can see here, if the month is January - September you get a 0 prefix. 

YEARMONTHPART(date) 
This function returns the string "<year>/<date>" e.g. "2001/01". As you can see here, if the month is January - September you get a 0 prefix. The aim here is to have dates that can easily be sorted. 

MONTHNAME(date)
This function returns the name of the month (in the current locale)

SHORTMONTHAME(date) 
This function returns the abbreviated name of the month (as determined by the locale and how Windows abbreviates it)

DAYNAME(date)
This function returns the name of the day (in the current locales)

SHORTDAYNAME(date) 
This function returns the abbreviated day name (as determined by the locale and how Windows abbreviates it)

NUMTOMONTHNAME
NUMTOMONTHNAME(n)
Returns the month name given an integer from 1 to 12.

NUMTOSHORTMONTHNAME
NUMTOSHORTMONTHNAME(n)
Returns the short version of a month name (e.g. Jan) given an integer from 1 to 12.

TODATE
TODATE(year,month,day)
Returns the date given the year month and day as integers.

TODATETIME
TODATETIME(year,month,day,hours,minutes)
Returns the date given the year, month, day, hour and minute as integers.

DATEFORMAT
DATEFORMAT(date,dateformat)
Given a 'date' value, this formats the date part of it according to the second parameter. If the first parameter isn't a date or the second isn't a string then null is returned.
This uses the Win32 API GetDateFormat function, so you can search for more details concerning e.g. the behaviour in other languages.

d
day of the month without leading zeros for single-digit days
dd
day of the month with leading zeros for single-digit days
ddd
short / abbreviated day of the week e.g. 'Mon' in English
dddd
day of the week in full e.g. 'Monday'
M
month as digits without leading zeros for single-digit days
MM
month as digits with leading zeros for single-digit days
MMM
short / abbreviated month e.g. 'Jan' in English
MMMM
month in full e.g. 'January'
y
last digit of year
yy
last two digits of the year with leading zero for single-digit years
yyyy
full year
g / gg
The era e.g. A.D. / B.C. in English

These characters are case sensitive. Any other character is passed through to the output unchanged. If you were to put more than the maximum number of these letters consecutively they are treated as being the same as the maximum number of that letter. 

TIMEFORMAT
TIMEFORMAT(date,timeformat)
Given a 'date' value, this formats the time part of it according to the second parameter. If the first parameter isn't a date or the second isn't a string then null is returned.
This uses the Win32 API GetTimeFormat function, so you can search for more details concerning e.g. the behaviour in other languages.

h
hours with no leading zero for single-digits hours in 12 hour clock
hh
hours with leading zero for single-digits hours in 12 hour clock
H
hours with no leading zero for single-digits hours in 24 hour clock
HH
hours with leading zero for single-digits hours in 24 hour clock
m
minutes with no leading zero for single digit minutes
mm
minutes with leading zero for single digit minutes
s
seconds with no leading zero for single digit minutes
ss
seconds with leading zero for single digit minutes
t
A or P for AM or PM
tt
AM or PM

These characters are case sensitive. Any other character is passed through to the output unchanged. If you were to put more than 2 of these letters consecutively they are treated as being the same as 2 of that letter. 

DATETIMEFORMAT
DATETIMEFORMAT(date,dateformat,timeformat)
Given a date and a date format and a time format, this returns a string consisting of the date part of the 'date' value formatted as it would be by DATEFORMAT, followed by a space, followed by the time part of the 'date' value formatted as it would be by TIMEFORMAT. 
DAYOFWEEK(date) 
Given a date, returns the day-of-the-week of the date as a number according to the ISO8601 standard (from 1=Monday to 7=Sunday)

DAYOFYEAR(date) 
Given a date, returns the day-of-the-year of the date as a number (1=January 1st)

DAYSINYEAR(date)
Given a date, returns the number of days in the year of the date

MATHEMATICAL FUNCTIONS
Trigonometric functions, logs and exponents.
All these functions return NULL if their parameters cannot be converted into numbers. There may be further restrictions on the parameters as described below.
All angles in the trigonometric functions are expressed in degrees.

LOG(x)
Calculates the log (base 10) of x. Returns NULL if x<=0.

LOGE(x)
Calculates the log (base e) of x, otherwise known as a 'natural logarithm'. Returns NULL if x<=0.

EXP(x)
Calculates e^x

SIN(x)
Calculates the sin of x.

COS(x)
Calculates the cosine of x.

TAN(x)
Calculates the tangent of x. Returns NULL if cos(x) = 0 (and therefore tan(x) would be infinite).

ASIN(x)
Calculates the inverse sin of x. Returns NULL if x is less than -1 or greater than 1. Returns a value within the range -90 degrees to 90 degrees.

ACOS(x)
Calculates the inverse cosine of x. Returns NULL if x is less than -1 or greater than 1. Returns a value within the range 0 to 180 degrees.

ATAN(x)
Calculates the inverse tangent of x. Returns a value within the range -90 degrees to 90 degrees.

ATAN2(y,x)
Calculates the inverse tangent of y / x using the signs of y and x to correctly determine the quadrant. Returns a value within the range -180 degrees to 180 degrees.
Note that the parameters are y followed by x in that order - this is consistent with most programming languages, though not Excel macros. 

GAMMALN(x)
Returns the LOG (base e) of the Gamma function of x. 

Object Variables
When writing queries with multiple clauses you will sometimes want to store values temporarily to use in subsequent clauses, but not want to keep them after the query has finished.
In this case you will want to use variables. They have 3 advantages:
1. They are not written to the database so can be quicker.
2. They do not use any user fields which you may want to use for other purposes.
3. They can be used even for networks which you don't have the ability to edit, either because of user permissions or because you are looking at modelling results, which allows them to be used when setting up GROUP BY or SELECT queries which display results in grids or export them to files. 
There are other types of variables which will be described later, this section confines itself to 'normal' variables.
You do not have to explicitly 'declare' variables by saying that you want to use a variable with a particular name, you merely have to use the variable in the query. Variables are distinguished from fields and constants by beginning with the dollar sign $. Apart from the dollar sign letters, digits and the underscore character are valid characters to use in variable names. The first character after the $ must not be a digit. Thus $height, $pipe_height, $_pipe_height and $pipe_height_123 are all valid variable names. 
Variables names are case insensitive, so you could use $HEIGHT, $height, $Height, $hEiGhT etc. but they would all refer to the same variable.
It is possible to use variables in association with one-to-one links, which have been explained above, and with one-to-many links, which will be explained later in this document. 
Variables are automatically associated with a particular object type or types, and an error message will be displayed if you attempt to use a variable associated with one object type with another e.g. if you set a variable for nodes then attempt to use it for conduits. 
If the first clause you use a variable in is for a particular type of node or link e.g. conduits, then it is automatically associated with all nodes or all links rather than the individual node or link type. This means that if you subsequently use it in a context where any node or any link may be used there will not be a problem. If the variable has been initially assigned in a clause for a particular node or link type, then if it is used in another node or link type, or for all node or link types, then the value of the variable will be NULL for any nodes or links of types for which it has not been assigned. 
In the case where you are running multiple queries together by dragging an SQL Query Group onto a GeoPlan, the variables will be preserved between queries i.e. a variable set in one query will be available in a subsequent query. This is the only circumstance in which the variable values outlive the execution of a single query.

Scalar Variables
Scalar variables are variables that have a single value, rather than a value for every object of a particular type, they can be numbers, dates or strings, and are defined using the LET statement e.g.
LET $flag = "XP"
LET $threshold = 123.4
LET $date_threshold = #01-Jan-2003"

As well as setting values, it is possible to set scalar variables to the results of expressions of other scalar variables and constants e.g.
LET $diameter = $area / $pi

As well as these scalar expressions it is possible to set scalars to the results of some queries calculating values for the whole of a network or selection, see below.
Scalar variables may be saved to files and read from files, see below.

List Variables
List variables are used in conjunction with a number of functions, known as 'list variable functions'.
List variables can either be defined with a set of values, or can be defined with the intention of providing the values later.
To define list variables and to provide a set of values the format of the statements are as follows:
LIST variable_name = list of values (separated by commas) e.g.
LIST $widths = 100, 300, 500, 700, 900
LIST $codes = 'AB', 'AF', 'BC', 'BD'

The variable name must be valid as described above, beginning with the dollar sign. The equals sign must be there, as must the commas between the individual values.
As well as numbers and strings it is possible to have lists of dates, which as described above must begin and end with the # character.
To define list variables with the intention of providing values later the format of the statements is as follows:
LIST variablename
LIST variablename STRING
LIST variablename DATE
e.g.
LIST $mynumberlist
LIST $mystringlist STRING
LIST $mydatelist DATE

Values of a particular sort of query may be stored in list variables, see below.
List variables may be saved to files and read from files, see below.
There are four functions associated with list variables. In all cases the final parameter of the function must be a list variable and only a list variable. In addition, the LEN function may be used to find the length of a list variable. There are no other circumstances in which list variables may be used within SQL expressions. 
One of the functions may only be used if the list is sorted, i.e. the values in the list must be strictly increasing, with each value being strictly greater than the previous value. In the case of numbers and dates 'increasing' means what you would expect. In the case of strings, it means that the strings are in alphabetical order, however that is defined for the language in which you are running Windows. 

LEN
LEN(list variable)
The function LEN may be used to find the length of a list variable, that is to say the number of items in the list. e.g. LEN($widths) with $widths as defined above would return 5.

RINDEX
RINDEX(expression,list variable)
RINDEX is the function that may only be used if the list is sorted. The purpose of the RINDEX function is essentially to divide values into 'buckets'. It returns 0 if the result of the expression is less than the first value in the list, 1 if it greater than or equal to the first value in the list but less than the second value in the list, 2 if it is greater than or equal to the second value in the list but less than the third value etc.
If there are n items in the list and the result of the expression is greater than or equal to the final item in the list hen RINDEX will return n.

LOOKUP
LOOKUP(expression,list variable)
If there are n items in the list and the expression is between 1 and n inclusive, LOOKUP will return the appropriate item from the list e.g. if the result of the expression is 1 it will return the first item, if it is 2 it will return the 2nd item, if it is n it will return the nth and final item. If the value is not an integer or an integer not in the range between 1 and n inclusive, it will return NULL. 

MEMBER
MEMBER(expression, list variable)
MEMBER will return the Boolean value true if the result of the expression is one of the values in the list, false otherwise.

INDEX
INDEX(expression, list variable)
If the result of the expression is the first value in the list, INDEX will return 1, if the result is the second value in the list it will return 2 and so on. If the result of the expression is not in the list INDEX returns 0. 

AREF(n,list)
Given a list variable list and a number from 1 to the length of list returns the nth element in the list e.g.
LIST $badger = 'one','two','three';
AREF(2,$badger) will return 'two'

Obviously this is on some level counterintuitive, you might expect $badger,2, but all the other functions that take list variables take the list as the last parameter so the parameters are in this order for the sake of consistency. This function is likely to be most useful in combination with the looping and IF functionality described later in the document.
TITLE(n,list)
The purpose of the title list function is to provide titles for the 'buckets' when RINDEX is used to partition values into a number of ranges (see above). 
Saving and Loading Variables with SAVE and LOAD
Scalar and list variables can be saved to files and read from files as follows:

SAVE $var(,$var,$var...) TO FILE 'filename' 
SAVE $var(,$var,$var...) TO FILE $variable
LOAD $var(,$var,$var...) FROM FILE 'filename'
LOAD $var(,$var,$var..) FROM FILE $variable
SAVE ALL TO FILE 'filename'
SAVE ALL TO FILE $variable

The filename may be a string or a scalar variable containing a string.
It is possible to save all variables, but not load all variables.
All variables must have been defined beforehand e.g.
LET $x = null
to define a scalar variable, or one of the LIST statements described above to define a list variable.

Variables in Scenarios
Variables can be used in scenarios - there is only one copy of each variable, there are no scenario dependent variables. 
To set a variable based on an expression in a scenario the same syntax is used e.g.
UPDATE IN SCENARIO 'bert' SET $x = user_number_1
This provides a mechanism for comparing values in scenarios e.g.
UPDATE IN SCENARIO 'bert' SET $x = user_number_1;
SELECT WHERE $x <> user_number_1 array fields
Array fields are fields such as CCTV survey details, Manhole Survey pipes in and pipes out in InfoNet, river sections in InfoWorks RS and 'demand by category' in InfoWorks WS.  They typically appear in grids on property sheets because they contain a number of rows - corresponding to each detail of the CCTV survey, each pipe in and out of the manhole survey. Each row has a number of named 'fields' in the same way that each object has a number of named fields. 
SQL gives you access to the fields of the arrays in a number of ways.
Detecting if there is any data in the array
You can find if there are any data in the array by using the function ANY with the parameter consisting of the name of the array followed by '.*' e.g. ANY(details.*). This will return true if there are any records in the array, false otherwise. 
The precise nature of the function ANY will be described in a later part of this section.

Counting the number of rows in the array
You can count the number of rows in the array by using the function COUNT with the parameter consisting of the name of the array followed by '.*) e.g. COUNT(details.*). For example, to select any CCTV survey records with more than 10 detail records you can say COUNT(details.*)>10. 
The precise nature of the function COUNT will be described in a later part of this section.

Aggregate functions
There are a number of functions which, when applied to array fields, evaluate an expression for each row in the array field and then perform an action with all the results. The results of these functions can then be used in the same way as any other function when the expression is evaluated for the object with the array field. 
What an aggregate function is will become clearer when they are described below:

ANY
The aggregate function ANY returns true if the expression is true for any row of the array field e.g. ANY(details.code='JDS') will return true if any of the rows of the details array field has the code JDS, false otherwise. 
It is important to release that the expression within the brackets can contain more than one array field, other fields of the object, constants and non-aggregate functions, and these can all be combined in the same ways as before i.e. with arithmetic, comparison and logical operators, so it is possible to say things like ANY(details.code='ST' AND details.distance>0), which would detect objects where the details code is ST and the distance is greater than 0, which we might consider an error as ST is the code for a 'start' detail record and therefore the associated distance should be 0. 
As you can see from this example, the expression within the brackets is evaluated for each record independently so this means 'are there any details records in which the details code is 'ST' and the distance is greater than 0' not 'are there any detail records in which the details code is 'ST' and also detail records where the distance is greater than 0. If this were what was desired this could be achieved by saying ANY(details.code='ST') AND ANY(details.distance>0).

ALL
The aggregate function ALL returns true if the expression is true for all rows of the array field e.g. ALL(details.distance>=0) will return true if all the rows of the details array field have the distance greater than or equal to zero, false otherwise. 

COUNT
The aggregate function COUNT returns the number of records in the array field for which the expression is true e.g. COUNT(details.code='ST') returns the number of records in the array field for which the details code is ST.

MAX
This returns the maximum value for the expression for any of the records in the array field. Only non-NULL values will be considered.
MAX and MIN both work on numerical, date and string fields. In the case of string fields the comparison between strings is performed based on the language in which your Windows installation is set up.

MIN
This returns the minimum value for the expression for any of the records in the array field.
AVG
This returns the average of the value for the expression for all of the records in the array field. The average is calculated by dividing the total of the sum of all non-NULL values by the number of non-NULL values. If there are no non-NULL values AVG will return NULL.

FIRST and LAST
First and last are included here with the aggregate functions but work somewhat differently, they return the value for the expression calculated for the first and last records of the array field respectively. Thus, in calculating the value, one of the records in the array field is considered.
Each aggregate function can contain fields from only one array field, e.g. you can't combine fields from pipes_in and pipes_out within a manhole survey. It is, however, possible to include multiple aggregate functions within an expression, with each aggregate function containing an expression referring to a different aggregate function. e.g. COUNT(pipes_in.*)>0 AND COUNT(pipes_out.*)>0 will select all manhole surveys with both pipes and and pipes out.
There is another use of aggregate functions which will be described later in this document. 

Use of 'bare' array field values in expressions
As well as using the values in array fields within the aggregate functions described above, it is possible to use the array fields outside these functions. 
This is retained for backwards compatibility but it not required thanks to the aggregate function ANY.
When they are used in expressions the expression is evaluated for each record of the array field contained in it. It is only possible to include one array field in any expression although it is possible to include multiple references to the same array field in one.
details.code='GP' will select all CCTV surveys with at least one detail record with the code GP. This is equivalent to ANY(details.code='GP')
It is important to understand exactly what you are asking for in a query, particularly if the query includes tests other than equality e.g. saying details.code<>'GP' will be true if any of the records in the array field have a code other than GP. This will almost certainly not be what you want, and certainly does not mean 'any object where none of the records of the details array field has the value GP', which can be achieved by instead using NOT ANY(details.code='GP').

Use of 'bare' array field values in assignment clauses
It is possible to set values in array fields by using them in an assignment clause outside an aggregate function. 
If there is only a SET sub-clause with no WHERE sub-clause, the SET sub-clause will be run for every record in the array field for every object in the table e.g.
SET pipes_in.width = 123 will set the width for every 'pipe in' record in every manhole survey to 123. 
If there is a WHERE sub-clause that does not include a reference to the array field, the SET sub-clause will be run for every record in the array field for every object for which the WHERE sub-clause is true e.g. 
SET pipes_in.width = 234 WHERE shaft_depth = 1650 will set the width for every 'pipe in' record to 234 in every manhole survey where the shaft depth is 1650.
If there is a WHERE sub-clause that includes a reference to the array field, then the SET sub-clause will be run for every record in the array field for which the WHERE sub-clause is true.

Interaction between 'bare' array fields and aggregate functions
If you use array field values outside aggregate functions in a WHERE sub-clause, and inside aggregate functions in the SET sub-clause, the aggregate functions in the SET sub-clause will only be evaluated for records in the array field for which the WHERE sub-clause is true. 
 This means that if you say
SET user_number_1 = COUNT(details.*) WHERE details.code = 'DES'
this will set user_number_1 to the number of details records for the CCTV survey for which the code is DES. In this case saying SET user_number_1 = COUNT(details.code='DES') would have the same effect. 
A more practical example is that to sum the service score for detail records of type DE could be done with the query
SET user_number_1 = SUM(details.service_score) WHERE details.code='DE'

An alternative way of calculating this without a bare array field would be
SET user_number_1 = SUM(IIF(details.code='DE',details.service_score,0))

If, however, you use an aggregate function IN the WHERE sub-clause, the aggregate function will be run for all records of the array field.

Flags as arrays
The flags for an object can be treated in the same way as array fields 
SELECT oid,COUNT(flags.value='S1') 

The array has 2 fields value and name, name is obviously read only.

As they can be treated like arrays you can do things with aggregate functions e.g. ANY(flags.value='XX')


One-To-Many Links
One to many links allow queries to include linked objects where there may be zero, one or many linked objects. 
The available one to many links are as follows:
ICM Modelling Network
Node
Link
us_links
Node
Link
ds_links
Link
Link
us_links
Link
Link
ds_links
Node
Subcatchment
subcatchments


Collection Network
Node
Link
us_links
Node
Link
ds_links
Link
Link
us_links
Link
Link
ds_links
Property
Incident
incidents
Pipe
Monitoring Survey
monitoring_surveys
Manhole
Monitoring Survey
monitoring_surveys
Pipe
General Incident
incidents
Manhole
General Incident
incidents
Manhole
Drain Test
drain_tests
Manhole
Manhole Survey
manhole_surveys
Manhole
Manhole Repair
manhole_repairs
Manhole 
GPS Survey
gps_surveys
Pipe
Pipe Repair
pipe_repairs
Pipe
Smoke Test
smoke_tests
Pipe
Dye Test
dye_tests
Pipe
CCTV Survey
cctv_surveys
Pipe
Property
properties
Data Logger
Monitoring Survey
monitoring_surveys
Smoke Test
Smoke Defects
smoke_defects


Distribution Network
Node
Link
us_links
Node
Link
ds_links
Link
Link
us_links
Link
Link
ds_links
Property
Incident
incidents
Manhole
Manhole Survey
manhole_surveys
Manhole
Manhole Repair
manhole_repairs
Manhole
GPS Survey
gps_surveys
Node
GPS Survey
gps_surveys
Node
Incident
incidents
Node
Monitoring Survey
monitoring_surveys
Data Logger
Monitoring Survey
monitoring_surveys
Pipe
Pipe Repair
pipe_repairs
Pipe
Pipe Sample
pipe_samples

As well as us_links and ds_links it is possible to use all_us_links and all_ds_links which will provide all the upstream or downstream links by means of a network trace, rather than just the links immediately upstream or downstream of the particular object. 
They may be used in queries in a very similar manner to array fields, as follows:

Determining if there are any linked objects
ANY(linkname.*) may be used to determine if there are any linked objects e.g.
ANY(us_links.*)

Counting the number of linked objects
COUNT(linkname.*) may be used to count the number of linked objects e.g
COUNT(manhole_surveys.*)=0

Aggregate Functions
The aggregate functions listed above for array fields with the exception of FIRST and LAST are available for one-to-many links.

Use of 'bare' one-to-many fields
It is possible to set values in one-to-many fields by using them in an assignment clause outside an aggregate function. 
If there is only a SET sub-clause with no WHERE sub-clause, the SET sub-clause will be run for every object related to every object in the table by the one to many link e.g.
SET us_pipes.width = 123 will set the width for every upstream pipe.
If there is a WHERE sub-clause that does not include a reference to the one-to-many field, the SET sub-clause will be run for every record in the one-to-many for every object for which the WHERE sub-clause is true e.g. 
SET us_links.width = 234 WHERE shaft_depth = 1650 will set the width for every upstream link to 234 where the shaft depth is 1650.
If there is a WHERE sub-clause that includes a reference to the one-to-many field, then the SET sub-clause will be run for every object linked via the one-to-many field for which the WHERE sub-clause is true.

Interaction between 'bare' one-to-many fields and aggregate functions
If you use one-to-many field values outside aggregate functions in a WHERE sub-clause, and inside aggregate functions in the SET sub-clause, the aggregate functions in the SET sub-clause will only be evaluated for objects linked to the current object via the one-to-many field for which the WHERE sub-clause is true. 
If, however, you use an aggregate function IN the WHERE sub-clause, the aggregate function will be run for all objects linked to the current object via the one-to-many link.

SELECT Clauses that generate grids and files
As well as being used to select objects in the networks, SELECT clauses can be used to generate grids of data displayed in the software and CSV files. There are three major types of these clauses:
1. SELECT clauses returning one grid line or line in a file per object in the network or per object satisfying the criteria in the WHERE sub-clause - these are termed 'explicit select clauses'. 
2. SELECT clauses with GROUP BY sub-clauses returning one grid line or line in a file per group of objects containing totals, averages, maxima, minima, counts etc. aggregated over all the members of the group. . The objects can be grouped by one or more fields, variables, expressions or some combination of these.
3. SELECT clauses without a GROUP BY sub-clause which behave as 2 above but with the totals, maxima etc. aggregated over everything in the network, or everything in the network satisfying the criteria in the WHERE sub-clause). These clauses look very similar to explicit select clauses. The means by which the two are distinguished will be described below.

Explicit Select Clauses
An explicit select clause may be used to generate grids or CSV files containing one or more values for each object meeting given criteria. 
The main advantage of using an explicit select clause over other ways of displaying data in the software is that you can display the results of calculations, including calculations on one-to-many links and array fields. 
An explicit select clause consists of the following sub-clauses, most of which are optional.
1. A SELECT sub-clause containing the expressions to be output to file or grids within the software. The SELECT sub-clause is compulsory. There can be one or more expressions separated by commas, these are termed 'sub-expressions'
2. A FROM sub-clause specifying the table from which the data should be extracted. This sub-clause is optional. 
3. An INTO sub-clause specifying the file into which the results should be output. This sub-clause is optional. 
4. A WHERE sub-clause specifying a condition which should be fulfilled before the object will be considered and included in the grid or file.
5. An ORDER BY sub-clause specifying the order the objects should appear in the grid or file.

If no FROM sub-clause is specified, the current table will be used.
If no INTO sub-clause is specified, the results will be displayed in a grid. 
If no WHERE sub-clause is specified, all the relevant objects will be considered

Group By Clauses
The 'Group By' clause consists of the following sub-clauses, most of which are optional.
1. A SELECT sub-clause, as described above. As with the explicit select clause, this is compulsory.
2. A FROM sub-clause, as described above. This sub-clause is optional.
3. An INTO sub-clause, as described above. This sub-clause is optional. 
4. A WHERE sub-clause, as described above. This sub-clause is optional. 
6. A GROUP BY sub-clause listing the fields, expressions, variables etc. used to group the objects. There can be one or more fields, expressions etc. separated by commas, these are termed 'sub-expressions'.
7. A HAVING sub-clause specifying a condition for the group (rather than the object) which should be fulfilled for the data for this group to be output.
8. An ORDER BY sub-clause specifying the order the objects should appear in the grid or file.

If no FROM sub-clause is specified, the current table will be used.
If no INTO sub-clause is specified, the results will be output to a grid within the software.
If no WHERE sub-clause is specified, all the objects will be considered
If no GROUP BY sub-clause is specified, all the objects in the table will be considered as one group (this is known as an 'implicit GROUP BY')
If no HAVING sub-clause is specified, all the groups will be output to the file or grid.
When the result of the GROUP BY clause is output to a file, the values for all the sub-expressions in the GROUP BY sub-clause and the SELECT sub-clause will be output to the file. The records output will be sorted in an order determined by the sub-expressions in the GROUP BY clause unless overridden by an ORDER BY sub-clause.
It is possible to alter the text used in the header of the CSV file or the grid for each expression within the SELECT sub-clause by using the keyword AS
e.g. 
SELECT COUNT(*) AS MyCount, MAX(x) AS MaxX Group BY status
Note that the aliases are not strings, they do not appear in quotation marks. If you want to have spaces in the names you should deal with them as with variables with spaces in the name and use square brackets e.g. [My Title]. 
The aggregate functions described above, with the exception of FIRST and LAST may be used in the sub-expressions in the SELECT sub-clause.
It is also possible to use the special sub-expression COUNT(*), which will return the number of objects in each group.
It is possible to restrict the number of records displayed or written to the file by use of the TOP and BOTTOM keywords. 

Implicit Group By Clause
It is possible to write a query which works like a GROUP BY clause but instead of grouping things by one or more fields or expressions, considers all the objects at once. A simple example of this would be a query that counts the number of objects in the table e.g.
SELECT COUNT(*)
This is different from an explicit select clause e.g.
SELECT node_id
The rule for determining whether a query is an implicit group by or a select acting on individual objects is as follows:
1. If there are no aggregate functions e.g. SELECT node_id,x,y then the query is clearly NOT an implicit GROUP BY
2. If there are aggregate functions acting on the results of aggregate functions e.g. SUM(COUNT(details.*)) then it clearly IS an implicit GROUP BY
3. If neither of the above apply then more detailed analysis has to be performed on each aggregate function as follows:
a. If the aggregate function contains an array field or a one-to-many link followed by an asterisk e.g. SUM(details.*), ANY(us_links.*), then the aggregate function must be intended to work at an object level since this would not be valid at a group level.
b. If the aggregate function contains a field for an array field or a one-to-many link followed by an asterisk e.g. COUNT(details.code='Z'), MAX(us_links.width<150), then the aggregate function must be intended to work at an object level since this would not be valid at a group level.

Since the values returned by these queries are for the whole network or selection, it is possible to assign the values to scalar variables by using the INTO keyword e.g.
SELECT COUNT(*) INTO $mycount

It is possible to assign more than one value into a variable with one clause e.g
SELECT MAX(x) INTO $mymaxx,MIN(y) INTO $myminy

Group By Array Fields
It is possible to use an array field in a GROUP BY query e.g. 
SELECT SUM(COUNT(details.*)) GROUP BY details.code

Array Fields in Explicit Select Clauses
It is possible to use an array field in an explict SELECT clause e.g.
SELECT us_node_id,ds_node_id,link_suffix,details.code,details.remarks WHERE details.code = 'SA' and details.remarks IS NOT NULL
This will generate one report line for each 'record' in the array.

Ordering results
The ORDER BY clause must follow the WHERE, GROUP BY, or HAVING clause, if any. 
e.g.

SELECT COUNT(*) GROUP BY material, network.name HAVING COUNT(*) > 10 ORDER BY Count(*)

SELECT COUNT(*) GROUP BY material, network.name   ORDER BY Count(*)

SELECT node_id,ground_level WHERE node_type = 'F'  ORDER BY ground_level

If there is no WHERE, GROUP BY or HAVING clause it must follow the FROM keyword used to specify a table name, if any. 

SELECT node_id,ground_level FROM [All Nodes] ORDER BY ground_level

If there is no FROM keyword specifying a table, the ORDER BY clause must follow the INTO FILE keywords and the filename

SELECT node_id,ground_level INTO FILE 'd:\temp\badger.csv' ORDER BY ground_level

It is, of course, possible to order the results of a query without any WHERE, GROUP BY, FROM or INTO FILE e.g.

SELECT node_id,ground_level  ORDER BY ground_level 

Sorting Ascending and Descending
It is possible to sort ascending and descending by using the keywords ASC and DESC respectively

SELECT node_id,ground_level  ORDER BY ground_level ASC
SELECT node_id,ground_level  ORDER BY ground_level DESC

If nether keyword is specified then the sorting is ascending by default.

It is possible to sort based on more than one expression e.g.
SELECT node_id,ground_level  ORDER BY ground_level ASC, x ASC

which sorts by ground_level ascending, then if two or more nodes have the same ground level, sorts by the x coordinate ascending.
It should, of course, be borne in mind that this makes most sense for strings and integers, for real numbers the sorting is by the display precision (default 2) e.g.

SELECT node_id,ground_level,x ORDER BY ground_level DP 0 ASC, x ASC

SELECT node_id,ground_level,x ORDER BY ground_level DP 6 ASC, x ASC

SELECT node_id,ground_level,x ORDER BY ground_level ASC, x ASC

Will all potentially give different results. 

Restricting the number of results
It is possible to restrict the number of results by using the keywords TOP and BOTTOM
You can limit the number of results to a given number of items and to a percentage, you can select the top or bottom from the results, and you can use a variable or number.
The percentage is calculated the percentage of the objects to which the query is applied e.g. if you have 100 nodes, but only 10 are selected at the point the query is run, and either the keyword SELECTED is used or the apply to current selection' check box is checked, then SELECT TOP 50 PERCENT will select 5 objects, not 50.
Similarly, if there is a where clause, then the percentage applies to the number of objects for which the WHERE clause is true.  
When using TOP and BOTTOM it is possible to use both sorts of select, the variety where a grid or file is produced and the variety where the objects are selected in the network.

SELECT TOP 5  node_id, ground_level ORDER BY ground_level DESC
SELECT TOP 1.5 PERCENT  node_id, ground_level ORDER BY ground_level DESC
SELECT TOP 3 PERCENT  node_id, ground_level ORDER BY ground_level DESC
SELECT BOTTOM  5  node_id, ground_level ORDER BY ground_level DESC
SELECT BOTTOM  1.5 PERCENT  node_id, ground_level ORDER BY ground_level DESC
SELECT BOTTOM  3 PERCENT  node_id, ground_level ORDER BY ground_level DESC
LET $val = 3; SELECT TOP $val PERCENT node_id,ground_level ORDER BY GROUND_LEVEL desc

You might perhaps think the fact that selecting the objects with the highest five values for a given field requires you to say ORDER BY blah DESC is counter-intuitive, but this particular usage is 'standard' SQL.
It is possible to select any objects with the same values from the fields being 'ordered by' by using the keywords WITH TIES e.g.
SELECT TOP 10 node_id, ground_level WITH TIES ORDER BY ground_level DESC
The essential purpose of this is to avoid the case where a number of objects are selected but actually there are objects with exactly the same characteristics with regard to the sorting criteria which aren't selected e.g. if the ordering is by a 'score' then the selection is extended so that all objects with a score similar to that of the last object originally selected are included in the selection.
The keywords WITHOUT TIES may be used, although they are not necessary as this is the default behaviour.  

Restricting the number of objects used in other contexts
Selecting Objects
If SELECT is used without a list of fields but in conjunction with TOP or BOTTOM and GROUP BY, then that number of objects will be selected e.g.
SELECT TOP 5 ORDER BY ground_level DESC

Deselecting Objects
It is also possible to deselect objects, when DESELECT is used in the same was as SELECT but without a list of fields e.g.
DESELECT TOP 5 ORDER BY ground_level DESC

Deleting Objects
More drastically, it is possible to actually delete objects in this way e.g.
DELETE TOP 5 ORDER BY ground_level DESC

Modifying Values
It is possible to restrict the objects that have values set with a SET clause in the same way e.g.
UPDATE TOP 10 SET user_number_1 = 123 ORDER BY ground_level DESC

It is, of course, possible to use a where clause e.g.
UPDATE TOP 10 SET user_number_1 = 123 WHERE ground_level < 100 ORDER BY ground_level DESC
It is possible to use the 'rank' of an object, that is to say the position it appears in the list e.g.
SET user_number_1 = rank ORDER BY ground_level DESC

Rank can only be used where there is an ORDER BY clause and can only appear on the right hand side in an assignment in a SET clause e.g.
SELECT node_id,rank ORDER BY ground_level DESC 
is not permitted. If you wish to do something like this it is possible to set the rank into a variable and use that in a subsequent clause in the query. e.g.
SET $r = rank ORDER BY ground_level DESC; SELECT node_id,ground_level,$r ORDER BY $r ASC

If there are tied values in the sort order i.e. two objects have the same values in all the sort fields then all objects with the same value will be given equal rank e.g. 
SET $r = rank ORDER BY INT(ground_level)  DESC; SELECT oid,$r,INT(ground_level) DP 0 ORDER BY ground_level DESC
yields
oid
$r
INT(ground_level)
MH354570
1
74
MH354587
2
71
MH359457
2
71
MH354567
4
70
MH554572
5
69
MH374579
5
69
MH354581
5
69
MH633738
8
68
MH324571
9
67
MH394577
9
67
MH364576
9
67
MH754572
9
67
MH354571
13
66
MH364575
13
66
MH354583
15
65
MH334571
15
65
MH394575
15
65
MH354578
15
65
MH354357
19
64
MH354556
19
64
MH384575
19
64
MH354572
19
64
MH374576
19
64
MH384579
19
64
MH354547
19
64
MH344577
26
63

Time Series Results
In InfoWorks WS and InfoWorks ICM it is possible to run queries that analyse the results across all time-steps. This is achieved by running aggregate functions on the results.
It is not possible to mix queries using time series results with bare one-to-many fields or bare array fields. 
When using results in this manner there are a number of additional aggregate functions and one aggregate function has a different meaning.
The aggregate functions 
COUNT
MAX
MIN
ANY
ALL
FIRST
LAST
have the expected meaning e.g.
COUNT(tsr.head>10) will return the number of timesteps in which the head is greater than 10
MAX(tsr.pressure) will return the maximum pressure, MIN(tsr.pressure) will return the minimum pressure
ALL(tsr.head>10) will return true if the head is greater than 10 for all timesteps, whilst ANY(tsr.head<10) will return true if the head is less than 10 for any timestep.
In this context FIRST will return the value for the first timestep, and LAST will return the value for the last timestep. 

AVG
In this context AVG does not simply return an average of the values at all the timesteps. Since the length of timesteps can vary, AVG returns the time weighted average i.e the sum of the values for all timesteps except the last multiplied by the duration of that timestep, divided by the total duration. 
The results are treated as step functions i.e. the results are assumed to remain constant for the duration of each timestep. 

SUM
By contrast, SUM simply sums all the values at all the timesteps. This will almost certainly tell you something useful only if all the timesteps are the same length.
The new aggregate functions for time series results are as follows:

DURATION
Will return the time in minutes for which the parameter is true e.g.
DURATION(tsr.head<110)>30
will select those nodes for which the head drops below 110 for more than 30 minutes (not necessarily contiguous)

INTEGRAL
This returns the sum of the value of the expression at each timestep multiplied by the length of the timestep in minutes. Since the SQL engine is not aware of the units in which values are being reported it is the responsibility of the user to ensure that any required multiplication factor is applied.

WHENEARLIEST
Returns the earliest time for which the expression is true e.g.
WHENEARLIEST(tsr.head<150) will return the first time at which the head is less than 150

EARLIEST
Returns the first non-null value of an expression. This is only likely to give a meaningful answer if used in combination with the IIF function e.g. to find the first time at which the head is less than 150 and to see the value at that time the query

SELECT EARLIEST(IIF(tsr.head<150,tsr.head,NULL)),WHENEARLIEST(tsr.head<150)
could be run.

LATEST
Returns the latest time for which the expression is true.

WHENLATEST
Returns the last non-null value of an expression. As with WHENEARLIEST this is only likely to give a meaningful answer if used in combination with the IIF function.

WHENMIN
Returns the time at which the expression is at its minimum. If there is more than one timestep at which the expression is at the minimum value this will report the earliest time.

WHENMAX
Returns the time at which the expression is at its maximum. If there is more than one timestep at which the expression is at the maximum value this will report the earliest time.

Note that MAX, MIN, WHENMIN and WHENMAX work on signed values, if you want to ignore the sign of values you should use the ABS function.

The functions AVG, INTEGRAL and SUM will not consider the final timestep in the simulation because the final timestep does not a known duration since timestep lengths can vary. This only applies to the final timestep in the simulation, not to the final timestep under consideration if you are using a WHEN clause.

In InfoWorks ICM you should note the following:
a) If the simulation uses relative times, the aggregate functions returning date/times return a number of minutes from the notional time 0.
b) If the query contains a WHEN clause, the aggregate functions perform their calculations only on the time-steps selected by the WHEN clause
c) When using relative times, if you wish to specify a time that is not an exact number of minutes exactly you will need to use calculations on the lines of 'WHEN tsr.timestep_start = 746+(1/60)' to get the timestep at 746 minutes and 1 second into the simulation
d) It is important to realise that the time varying results in SQL operate on the results in the results files. Therefore if you were to evaluate MAX(tsr.depth2d) this may not be the same as the maximum value stored in the results files, which is the maximum at all computational time-steps as opposed to the maximum value at all results time-steps.

WHEN Clauses
It is possible to limit the number of time-steps used in the time varying aggregate functions by use of a WHEN clause e.g.
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_no = 20
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_start = #01/01/2013 12:30#
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_no = tsr.timesteps 
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_no > 20
If you use a WHEN clause then all the above aggregate functions perform their calculations only on the time-steps selected by the WHEN clause. 
Notice that you are still aggregating even if you are only aggregating over one time step as in this case, therefore you still have to use an aggregate function. If you have one time-step then many of the aggregate functions will give the value of the result at that time-step e.g. MAX(tsr.val). 

The field values that can be used in WHEN clauses are as follows:
* tsr.timestep_no - the number of the timestep, with 1 being the first timestep as an integer
* tsr.timestep_start - the time of the start of the timestep as a date or number - see below
* tsr.timesteps - the number of timesteps in the simulation as an integer
* tsr.timestep_duration - the duration of the timestep as a number of minutes
* tsr.sim_start - the time of the start of the simulation as a date or number - see below
* tsr.sim_end - the time of the end of the simulation as a date or number - see below
The expression in the WHEN clause can include the above field values along with scalar and list variables e.g. you can list a number of timesteps you are interested in and then use the list function 
The results will only be processed for timesteps for which the WHEN clause is true. 

Prompts
To allow the user to enter parameters used in queries the statements
PROMPT LINE
PROMPT TITLE
PROMPT DISPLAY
are used. 
The fundamental way this works is as follows:
A number of PROMPT LINE statements define the list of values to be input or displayed and their formats. There will be one line displayed in a grid for each value. 
The variables must be scalars. The variable can either have been defined and set before the PROMPT LINE statement or mentioned for the first time in the prompt line statement.
Valid values used in the prompt line statement are as follows, they will be explained in detail below:
PROMPT LINE <variablename>
PROMPT LINE <variablename> '<description>'
PROMPT LINE <variablename> '<description>' STRING
PROMPT LINE <variablename> '<description>' DATE
PROMPT LINE <variablename> '<description>' DP <numberofplaces>
PROMPT LINE <variablename> <variablename>
PROMPT LINE <variablename> <variablename> STRING
PROMPT LINE <variablename> <variablename> DATE
PROMPT LINE <variablename> <variablename> DP <numberofplaces>

All of these but the first may optionally be followed by
LIST <listvariablename>
FILE
FOLDER
MONTH
RANGE <startvalue> <endvalue>

In general PROMPT LINE is followed by the variable name and the description. If the description is omitted as in the first case, or if the description is the blank string '', the description will be the variable name. 
The description may be a scalar variable. This is evaluated when the dialog is displayed.
If a variable has not been defined at the point of the PROMPT LINE clause
Examples of valid prompt lines
PROMPT LINE $x
This defines a number variable which will have the default of 2 decimal places in the grid and the description '$x'. This takes advantage of the special case where numeric variables can be defined by simply saying PROMPT LINE $x without having to give a description.
PROMPT LINE $s '' STRING
This defines a string variable. Note that because we want to use more than 3 parameters we have to add a description field for the variable, but we can take advantage of the special case where using the blank string '' will cause the variable name to be used as the description. 
PROMPT TITLE '<title>' may be used to change the title of the row displayed from the default, which is 'SQL Prompt Dialog'. The title may also be a scalar variable, which will be evaluated at the point the dialog is displayed. 
If you wish the entire grid to be read-only so that the values can be looked at by the user but not altered, use the keyword READONLY following PROMPT DISPLAY i.e. say 
PROMPT DISPLAY READONLY
This would typically be used to display the results of SELECT queries storing values in scalars and scalar expressions (see below). 
Error messages that may occur with the prompt functionality are as follows:
PROMPT LINE clause too short - the clause is too short e.g. PROMPT LINE
PROMPT LINE clause requires a variable after the LINE keyword e.g. PROMPT LINE 23 - self explanatory
PROMPT LINE clause variable not a scalar - the variable has already been used in another context (currently list or array) e.g. SET $x = x; PROMPT LINE $x;
PROMPT LINE clause description not a string - the description field in the 4th parameter is not a string e.g. PROMPT LINE $x STRING (in this case perhaps you have forgotten to add a description after the variable name). 
Examples
LIST $badgers = 1, 2, 5, 10, 20, 50; PROMPT LINE $badger 'badger badger' DP 0 LIST $badgers;PROMPT DISPLAY; SCALARS $badger
Allows the user to choose from this list of values. As the variable is not defined until the PROMPT LINE statement, the list includes the blank (NULL) value.

LET $badger = 10; LIST $badgers = 1, 2, 5, 10, 20, 50; PROMPT LINE $badger 'badger badger' DP 0 LIST $badgers;PROMPT DISPLAY; SCALARS $badger
In this case, however, the variable is already defined and in the list, therefore the list contains the values 1,2,5,10 20 and 50, and when the dialog is displayed, the value contains the string
Note that users are always allowed to enter new values into the lists where 'LIST' is used. 

Scalars
The SCALARS statement is primarily used for 'debugging' when the user is developing SQL queries but may also be used as an easy way of looking at a number of scalar variables. 

The keyword
SCALARS
on its own will display all the scalars
SCALARS followed by a comma separated list of scalar variables will display just those variables e.g.
SCALARS $x, $z

Adding and Removing Scenarios
Creation of scenarios
Scenarios can be added as follows
ADD SCENARIO 'name'
ADD SCENARIO $variable

The scenario can optionally be based on another by adding
BASED ON 'name'
or
BASED ON 'variable'

Deletion of scenarios
Scenarios can be removed as follows
DROP SCENARIO 'name'
DROP SCENARIO $variable

Cross Network Queries
You can perform cross network queries for the two sorts of asset network using the menu item on the Tools menu. The network name and ID can be used in the query by saying network.id or network.name.

You will typically want to create the query using a single network and then generate the cross network report using the new tools menu item.
Control Logic
You can include the following control logic in the SQL queries
While loops
If.. elseif.. else... endif blocks

The syntax of while loops is as follows

WHILE expression;
<statements>
WEND

The syntax of IF statements is as follows

IF expression
<statements>
optionally one or more blocks 
ELSEIF expression
<statements>

optionally
ELSE
<statements>
ENDIF

For fans of the wildly varying world of programming languages note that ELSEIF and ENDIF are both one word

It is possible to break out of loops by using the BREAK keyword e.g.

IF $x>0 AND $y>0 
	BREAK
ENDIF

this breaks out of the loop which immediately contains the BREAK keyword.
If the SQL contains a WHILE loop then a progress bar appears and you can break into the query. Obviously the progress bar does not actually progress, since it can't work out how far into the running of the query you are. 
1




