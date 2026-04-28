


Contents

Appendix A - Error Messages	3
A.1 - splitting into keywords	3
A. 2 - handling clauses and splitting them into sub-clauses	3
A.2.1 'normal' clauses	4
A 2.2 List clauses	5
A 2.3 Scalar assignments	6
A.3 - Handling individual clauses	6
A.4 - Checking variable and field names are valid	10
A.5 - Further notes on understanding error messages	11



Appendix A - Error Messages
The handling of SQL text is a multi-stage process. In general once a problem is found an error message will be displayed and the processing will stop.
The phases are as follows:
1 - splitting into keywords, field names etc.
2 - identifying the types of individual clauses and breaking them down into sub-clauses
3 - handling the individual clauses
4 - checking that variable and field names are valid
If there is a problem with the SQL text which prevents an individual phase completing, the following phases will not be performed.
As soon as a problem with the SQL text is identified, it is reported to the user and processing of the SQL text is stopped.

A.1 - splitting into keywords
The first phase of the process is splitting the text into keywords, field names, variable names, constants etc. If there is a problem with this stage an error message will be displayed and the processing will stop before the SQL text is broken into clauses. The message will begin 'error parsing query:' and will then contain a more detailed message explaining the precise problem. 
In this phase the following errors may occur:
1. invalid character at start of token - the invalid character will be displayed in the message. This typically occurs if you use a character not valid in a keyword, variable name or field name. ':' is an example of such a character. 
2. invalid character after field separator - in invalid character will be displayed in the message. This typically occurs if you use an invalid character after the '.' separating parts of a variable or field name. 


A. 2 - handling clauses and splitting them into sub-clauses
The next stage is to split the text into one or more clauses separated by semi-colons. To aid understanding of subsequent error messages the clauses will be numbered consecutively from one, with the error message both indicating the clause number and containing the full text of the clause itself.In the descriptions below, words within angular brackets stand in for other words e.g. <keyword> stands in for one of the keywords such as SELECT, DESELECT and DELETE
In this phase the following errors may occur:
A.2.1 'normal' clauses
Keyword '<keyword>' found more than once in clause
A keyword has been used more than once in a clause e.g. 
SELECT ALL FROM Node SELECT x > 0 
In this case the second SELECT should presumably have been the keyword WHERE.
There are a number of checks relating to the combination of keywords, which should be self explanatory:
Only one of the keywords SELECT, DESELECT and DELETE can be used within a clause.
Keyword SET cannot be used with the keywords SELECT, DESELECT, DELETE or GROUP BY.
Keyword HAVING cannot be used without they keyword GROUP BY.
Keyword DESELECT cannot be used with the keyword GROUP BY.
Keyword DELETE cannot be used with the keyword GROUP BY.
Keyword GROUP BY cannot be used without the keyword SELECT.

In GROUP BY clauses, the order of the keywords is strictly enforced. If there is a WHERE sub-clause it must be before the GROUP BY sub-clause. If there is a HAVING sub-clause it must be after the GROUP By sub-clause. 
If the sub-clauses are ordered incorrectly, the following two error messages may result:
The GROUP BY sub-clause cannot be placed before the WHERE sub-clause.
The HAVING sub-clause cannot be placed before the GROUP BY sub-clause.

SELECT, DESELECT or DELETE must be the first keyword in the clause.
Again, this should be self explanatory.

Invalid table name '<tablename>' after FROM in SELECT, DESELECT or DELETE clause
This error message will occur if the table name used when overriding the default table by using the keyword FROM followed by a table name is not recognised.

Invalid table name '<tablename>' after FROM in GROUP BY clause
This is the corresponding error message if an invalid table name is used following the FROM keyword in a GROUP BY clause.

Invalid table name '<tablename>' in SET clause
This is the corresponding error message if an invalid table name is used following the keyword UPDATE in a SET clause.
e.g.
UPDATE x SET user_number_1 = ground_level

Invalid syntax for SET clause - must be UPDATE (ALL | SELECTED) (table name) SET
This error message will typically occur if there is more than one token between the keywords UPDATE and the keyword SET e.g.
UPDATE x x SET user_number_1 = ground_level



A 2.2 List clauses
The following errors may occur when defining list clauses:

Variable <name> has already been defined
This error will occur if you attempt to define the same variable twice.

Variable <name> is not a valid list of comma separated values
This error will occur if you do not provide a list consisting of values separated by commas e.g.
LIST $widths = 200, 300, 
or
LIST $widths = 200 300 400

Variable <name> : lists must be lists of numbers, strings or dates
This error will occur if you include any unsuitable values in the list. The most likely cause of this error will be if you include strings that are not valid because they aren't enclosed in quotation marks e.g.
LIST $directions = D, U

Variable <name> : all values in the list must be of the same type
This error will occur if you attempt to mix values of the 3 valid types - a list must consist of all numbers, all strings or all dates e.g.
LIST $mixed = 1, 'two', 3
Variable <name> : <something> is not recognised as a valid date
This error will occur if the contents of one or more of the date constants beginning and ending with # is not recognised as a valid date e.g.
LIST $datelist = #1/1/2003#, #13/13/2003#

A 2.3 Scalar assignments
The following errors may occur when defining scalars:

Variable <name> has already been defined
This error will occur if you attempt to set a value for the same variable twice
Variable <name> : <something> is not recognised as a valid date
This error will occur if the contents of a date constant beginning and ending with # is not recognised as a valid date e.g.
LET $mydate = #12345#

LET clause is too long
This error will occur if you attempt to do anything other than assign a single value to a scalar variable e.g.
SET $area = $diameter * $pi

Variable <name> : scalars must be numbers, strings or dates
As described above, you must assign a value to a scalar variable, you cannot assign something else e.g. the value of another variable, the result of a query etc.
A.3 - Handling individual clauses
The following errors can be reported when the individual clauses are handled. To aid understanding of the errors, the number of the clause and the name of the sub clause are reported along with the clause text and the error message.
If you have a clause that selects objects e.g. x > 0, this is referred to as a WHERE sub-clause even though the keyword WHERE is not explicitly used. 

Expected = after name of field to assign to
This error will occur if a field name in a SET statement is followed by something other than an equals sign e.g.
SET user_number_1 > 23

Unexpected comma
This error will typically occur if you have used commas in sub-clauses where they are not allowed e.g.
x > 0, y > 0

Expected field, got comma
This error will typically occur in an expression in brackets if you follow an operator with a comma e.g.
SELECT x + (x + ,

Expecting field before comma
This error will typically occur in a SET sub-clause if you follow the = with a comma
SET user_number_1 =, user_number_2 = ground_level

Got comma at beginning of expression
This error will typically occur if you have a comma after the opening bracket of a function e.g.
SET user_text_1 = LEFT(,2)
or after a parameter e.g.
SET user_text_1 = LEFT(node_id,,

Got comma when not in function
Too many function parameters
Each function has a fixed number of parameters. If too many are supplied then this error message will occur e.g.
SET user_text_1 = LEFT(node_id,2,3)

Too few function parameters
On the other hand, this error message will occur if too few parameters are supplied to a function e.g.
SET user_text_1 = LEFT(node_id)

More than one parameter for aggregate function
All the aggregate functions such as COUNT, MIN, MAX, AVG etc. can contain one expression which will be evaluated for all the appropriate objects (e.g. one-to-many links, array fields, objects in GROUP BY clauses). If there is more than one sub expression within the aggregate function, this error message will occur e.g.
SET user_text_1 = COUNT(x,y)

Too many levels of aggregate functions
In  GROUP BY clauses it is, as described above, possible to use aggregate functions on the results of aggregate functions - this is because you are aggregating the results of the aggregate function on each object over a group of objects. This is the only case in which calling an aggregate function on the result of an aggregate function has a legitimate meaning, so if you attempt to say something like 
COUNT(COUNT(details.*))
or
SELECT COUNT(COUNT(COUNT(details.*))) GROUP BY direction
this error message will occur.

Unrecognised function - <functionname>
If an expression resembles a function, but the name of the function is not one of those available, this error message will occur e.g.
length(node_id)

Too many close brackets
This error message will occur if you have more close brackets than open brackets e.g.
direction = 'U')

Empty parenthesis
This error message will occur if open and close brackets are next to each other like this '()' except in the rare case of a function with no parameters (of which there is currently only one, NOW, as described above) e.g.
direction + ()

<token> : expected field or function
This error message will typically occur if you have two consecutive operators e.g.
cover_level-*ground_level
You are, of course, allowed to use the unary minus operator so
cover_level*-ground_level
is a valid expression.

Functions cannot be assigned to
You cannot assign values to functions, so something like
SET LEN(node_id)=10
is an error.

Aggregate functions cannot be assigned to
Similarly, you cannot assign values to aggregate functions, so something like
SET COUNT(details.*) = 10
is an error.

You can only assign to fields and functions
This error will occur if you attempt to assign a value to a constant e.g.
SET 2 + 2 = 5

AS cannot appear at the end of a SELECT sub-clause
If you use the keyword AS immediately before the end of the SELECT sub-clause in a GROUP BY clause, rather than giving an alias name, this error message will result e.g.
SELECT COUNT(*) AS GROUP BY status

'<text>' : invalid name for alias after AS keyword
This error message will result if something unsuitable e.g. a number is used after the keyword AS in the SELECT sub-clause of a GROUP BY clause e.g.
SELECT COUNT(*) AS 23 GROUP BY status

Other unsuitable aliases are variables, strings in quotes
SELECT COUNT(*) AS $variable GROUP BY status
SELECT COUNT(*) AS "my count" GROUP BY status

Only a comma or the end of the clause can appear after the alias after the AS keyword
This error message will result if you attempt to place anything other than a comma after the alias of an expression in the SELECT sub-clause of a GROUP BY clause e.g.
SELECT COUNT(*) AS [My Count] * 2 GROUP BY status

A.4 - Checking variable and field names are valid
The following error messages will be displayed if variables and/or field names are invalid. At this stage it is possible that more than one error message will be displayed at once.

<fieldname> is not a recognized field name
This simply means that the field name is not recognized as being a field for the current table.

<fieldname> - * used in an invalid context
As described above, * may only be used in a number of specific contexts viz:
COUNT(*)
ANY(<something>.*)
COUNT(<something>.*)
where something is the name of an array field or a one-to-many link. If an attempt is made to use it in some other context then this error message will result.
You can of course use * outside variable names to multiply numbers together.

variable <name> is not a list variable but is being used in a list context
As described above, list variables can only be used as the only or final parameter in a number of functions. Those functions can only take a list variable as the final parameter and you attempt to use something else as that final parameter this error message will result.

variable <name> has not been defined but is being used in a list context
As described above, variables are created the first time they are used. However, when they are used in a function expecting a list variable as its only or final parameter, they must have been previously defined in a LIST clause. If you try to use a variable for the first time as the final or only parameter of a function expecting a list variable, this error message will result.

variable <name> is a list variable but is being used in another context
This is the converse of the above message, and results if you attempt to use a list variable in another context e.g. if it has been set up for nodes and is then used for links. 

variable <name> has already been used in a different context
This message results if you attempt to use a variable that has already been used for one object type in another.

<something> is not recognized as a valid date
If you use a date constant within a query e.g.
SET survey_date = #1/2/2008#
the date string will be checked before the query is run, and if it is invalid e.g
SET survey_date = #13/13/2007#
this message will be displayed.


A.5 - Further notes on understanding error messages
The following notes may help you understand the nature of the error messages you are seeing.
1. If you forget to use the dollar sign at the beginning of a variable name in a LIST clause, the software will treat this as a normal clause without any keywords and produce an appropriate error message for that.
2. If you have a query that only defines list variables, when you hit the 'test' button the message 'Query has valid syntax, but not actions will be taken' will be displayed.


1




