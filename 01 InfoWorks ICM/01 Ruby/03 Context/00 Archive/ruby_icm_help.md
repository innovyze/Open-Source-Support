Introduction to Scripts
This documentation describes the Ruby API for external scripts that run within the user interface and Exchange.

For those of you who are not familiar with Ruby scripts, an Introduction to Ruby Scripting in InfoWorks topic is included in the product help.

Scripts that run from the user interface are designed to work with the current network, including importing and exporting data, but have limited access to the database. Exchange is a command line application that can run scripts with far greater access to database objects, making it well suited to more complex automation.

Task	User Interface	Exchange
Add, Import, and Manipulate Network Data	✔	✔
Commit and Revert Changes	✔	✔
Display Dialogs and other UI Features	✔	❌
Manipulate any other Database Objects	❌	✔
Open or Close Databases	❌	✔
Configure & Run Simulations	❌	✔
Ruby scripts are only intended to manipulate data via the product's documented API. While you can use most features of the Ruby Standard Library, you cannot install and use external packages (gems).

The application uses an embedded Ruby 2.4.0 interpreter.

This example script displays the number of nodes in the network:

network = WSApplication.current_network
nodes = network.row_objects('_nodes')
puts format("Your Network has %i nodes!", nodes.length)
Reading this Documentation
Ruby is a flexible language with many conventions and style guides. The examples in this documentation try to follow best practices.

Methods
Throughout this documentation, methods are described in this format:

#method(param1, param2) ⇒ Integer?
Where ⇒ indicates a return from the method, followed by the most commonly returned type.

void means that you should not expect a return value
A question mark means that the type may be nil (NULL)
An array is written as Array where the contents of the <> indicates the type of object the array will contain
Naming Conventions
PascalCase for Modules and Classes
SCREAMING_SNAKE_CASE for constants
snake_case for variables and methods
Variables for workgroup objects are often abbreviated in examples, e.g. a WSRowObject will be ro, WSModelObject is mo
Note that in the 2025.0 release, several methods which included capitalization were updated to be all lowercase. While the previous method names still work for backwards compatibility, we recommend using the newer method names for consistency.

Options hashes will not follow these guidelines and may include spaces and punctuation.

Other Conventions
Two space width for indentation (either spaces or tabs)
Use literal syntax to define arrays and hashes i.e. my_hash = {} instead of my_hash = Hash.new
Tips
You can check if an object (e.g. the value from a field) is nil with .nil?
If you want to call a method but are unsure if the object is nil, use the safe navigator & i.e. array&.empty?
For concise code, try the following:
Ruby supports some opposite conditions / actions, e.g. if and unless, while and until
To do one thing based on a condition, instead of writing a three line if statement, use (action) if (condition) i.e. puts 'Hi' if 5 > 2
If you want to set a value conditionally, use the ternary operator (condition) ? (true) : (false) i.e. animal = (3 > 4) ? 'badger' : 'penguin'

---

Introduction to Scripts
This documentation describes the Ruby API for external scripts that run within the user interface and Exchange.

For those of you who are not familiar with Ruby scripts, an Introduction to Ruby Scripting in InfoWorks topic is included in the product help.

Scripts that run from the user interface are designed to work with the current network, including importing and exporting data, but have limited access to the database. Exchange is a command line application that can run scripts with far greater access to database objects, making it well suited to more complex automation.

Task	User Interface	Exchange
Add, Import, and Manipulate Network Data	✔	✔
Commit and Revert Changes	✔	✔
Display Dialogs and other UI Features	✔	❌
Manipulate any other Database Objects	❌	✔
Open or Close Databases	❌	✔
Configure & Run Simulations	❌	✔
Ruby scripts are only intended to manipulate data via the product's documented API. While you can use most features of the Ruby Standard Library, you cannot install and use external packages (gems).

The application uses an embedded Ruby 2.4.0 interpreter.

This example script displays the number of nodes in the network:

network = WSApplication.current_network
nodes = network.row_objects('_nodes')
puts format("Your Network has %i nodes!", nodes.length)
Reading this Documentation
Ruby is a flexible language with many conventions and style guides. The examples in this documentation try to follow best practices.

Methods
Throughout this documentation, methods are described in this format:

#method(param1, param2) ⇒ Integer?
Where ⇒ indicates a return from the method, followed by the most commonly returned type.

void means that you should not expect a return value
A question mark means that the type may be nil (NULL)
An array is written as Array where the contents of the <> indicates the type of object the array will contain
Naming Conventions
PascalCase for Modules and Classes
SCREAMING_SNAKE_CASE for constants
snake_case for variables and methods
Variables for workgroup objects are often abbreviated in examples, e.g. a WSRowObject will be ro, WSModelObject is mo
Note that in the 2025.0 release, several methods which included capitalization were updated to be all lowercase. While the previous method names still work for backwards compatibility, we recommend using the newer method names for consistency.

Options hashes will not follow these guidelines and may include spaces and punctuation.

Other Conventions
Two space width for indentation (either spaces or tabs)
Use literal syntax to define arrays and hashes i.e. my_hash = {} instead of my_hash = Hash.new
Tips
You can check if an object (e.g. the value from a field) is nil with .nil?
If you want to call a method but are unsure if the object is nil, use the safe navigator & i.e. array&.empty?
For concise code, try the following:
Ruby supports some opposite conditions / actions, e.g. if and unless, while and until
To do one thing based on a condition, instead of writing a three line if statement, use (action) if (condition) i.e. puts 'Hi' if 5 > 2
If you want to set a value conditionally, use the ternary operator (condition) ? (true) : (false) i.e. animal = (3 > 4) ? 'badger' : 'penguin'

Running Scripts From the User Interface
Ruby scripts may be run from the user interface when a network is open. The script can access the current network via the WSApplication.current_network method.

When a script is running in the user interface, anything directed to stdout or stderr (e.g. using the puts, warn, or printf methods) is displayed in a log window once the script finishes. It is not displayed in real time.

You are allowed to create selection list groups when running Ruby scripts from the user interface.

There are three ways to run external scripts from the User Interface. Configuring Add-Ons and User Actions may be useful if you are automating a repeat task, particularly if you want to share these with your team.

From the Network Menu
In the Network menu, use 'Run Ruby Script...' to locate and run a script file. The 'Recent Scripts' sub-menu will show previously run scripts.

As an Add-On
Add-ons are configured per user, and allow you to save frequently run scripts as a menu item.

As a User Action
User Actions are similar to Add-Ons, but support more than just Ruby Scripts. These can be configured in the File > Database Settings > User Custom Actions window.

Tip: You can also use a Ruby script database item, rather than an external script, to run a script from the user interface.

Running Scripts from Exchange
Autodesk Licensing
ICM Exchange is the IExchange implementation of InfoWorks ICM for our Autodesk products. It is only available for users with an Ultimate license.

Usage
ICMExchange [options] [--] script [-login|-l] [args]

Parameter	Description
options	(Optional) These are any ruby command line options. See Command Line Options.
--	(Optional) Separator for the ruby command line options.
script	The path of the ruby script. Make sure to surround with "" if it contains spaces.
-login or -l	(Optional) When set, it displays the Autodesk Identity web page for users to log-in. If the user is already logged-in, it will proceed without showing the web page. If not set and the user is not logged-in, it will show the error: "Autodesk Licensing Error: The licence is not authorised (3).unable to initialise"
args	(Optional) It is possible to provide more arguments to the script with the extra arguments.
Note: Subscription overuse rules should apply.
Innovyze Licensing
IExchange [options] [--] script [product] [args]

Parameter	Description
options	(Optional) These are any ruby command line options. See Command Line Options.
--	(Optional) Separator for the ruby command line options.
script	The path of the ruby script. Make sure to surround with "" if it contains spaces.
product	The product code - either ICM, IA, or WS
args	(Optional) It is possible to provide extra arguments to the script. Make sure to surround them with "" if they contain spaces.
Additional Arguments
It is possible to provide more arguments to the script to custodies it's behavior, such as which database or network it should work with.

ICMExchange.exe "C:/Badger/my_script.rb" one two

Like regular Ruby scripts, the command line arguments are accessed from the ARGV array. The first element of the array is always the string 'ADSK'. For the above example, the ARGV array would contain:

['ADSK', one, two]

And the first custom argument could be accessed with ARGV[1].

Note that when using Innovyze licensing, the first element is a string of the product code instead of 'ADSK':

['ICM', one, two]

Working with the Database
Ruby scripts can manipulate items in the database, which are known as model objects. User interface scripts have limited access to the database, while Exchange provides full support for creating, renaming, copying, and deleting model objects.

The most relevant classes are WSDatabase, and WSModelObject.

All model objects in the database tree have the following properties:

Type - e.g. Network, Run, Selection List Group
Name
GUID - Globally Unique IDentifier, a long string of characters which can be found in the object properties in the UI
Model ID - an integer which can be found in the object properties in the UI
Using this information, a model object can be referenced by:

The type of object and it's GUID using WSDatabase.model_object_from_type_and_guid
The type of object and it's model ID using WSDatabase.model_object_from_type_and_id
The type of object and it's name using WSDatabase.find_root_model_object or WSModelObject.find_child_model_object
The scripting path (described in more detail below) using WSDatabase.model_object
Examples
Example 1
It is often easiest to use a model type and ID to access the model object. This example exports data for a rainfall event with ID 18:

database = WSApplication.open

mo = database.model_object_from_type_and_id('Rainfall Event', 18)
mo.export('D:/Badger/Rainfall.csv', 'csv')
Example 2
Alternatively, given the scripting path of an object you can access the object that way. This can sometimes be useful when you have to programmatically create the path.

This example exports binary results:

SCRIPTING_PATH = '>MODG~Basic Initial Loss Runs>MODG~Initial Loss Type>RUN~Abs>SIM~M2-60'

database = WSApplication.open

sim_mo = database.model_object(SCRIPTING_PATH)
sim_mo.results_binary_export(nil, nil, 'D:/Badger/Sim.dat')
Further Examples
It is possible to find all the objects in the root of the database using the #root_model_objects method of WSDatabase.

database = WSApplication.open
database.root_model_objects.each { |o| puts o.path }
Similarly, it is possible to find all the children of a given object using the #children method.

This example finds all the root objects in the database, and then all the child objects of the root objects:

database = WSApplication.open

database.root_model_objects.each do |o|
  o.children.each { |c| puts c.path }
end
These methods can be used recursively to find all the objects in the database. The technique used in the example below is a 'breadth first search' i.e. we start by finding the objects in the root of the database and putting them in an array. Thereafter we take the first object in the array, find its children, add them onto the end of the array and remove the first object.

database = WSApplication.open

process = []
database.root_model_objects.each { |o| process CG~General>CG~NorthArea>GMT~MyNetwork

A path always begins with >, then each level of the tree is formed by taking the model object type's 'short code', then a ~, then it's name.

If the name of any model object contains the characters ~, >, or \, then those characters must be escaped with a backslash, to avoid them being interpreted as part of the path.

For example, a model group with the unlikely name My >>>~~~\\ Group would have the path >CG~My \>\>\>\~\~\~\\\\ Group.

Working with Networks
A Network in this context refers to a WSModelObject that contains tables and objects.

Obtaining a Network
To work with individual objects within a network, you need to access a WSOpenNetwork instance. The mechanism for doing this is different between the UI and Exchange.

Within the UI:

network = WSApplication.current_network()
Within Exchange, you need to first access the WSNetworkObject or WSNumbatNetworkObject class:

database = WSApplication.open()
network_mo = database.model_object_from_type_and_id('Model Network', 2)
network = network.open
Accessing Row Objects
Objects within a network are called row objects, represented by the WSRowObject class.

You can access objects specifically by type and ID:

node = network.row_object('wn_node', 'Badger')
Or you can obtain an array of objects:

nodes = network.row_objects('wn_node')
Or an array of selected objects:

nodes = network.row_objects_selection('wn_node')
Categories can be used to obtain the objects across multiple tables. The most common use of a category is to obtain all of the nodes or links in a network, regardless of the types of the individual nodes or links.

The categories are:

_nodes - all nodes
_links - all links
_subcatchments - all subcatchments
_other - other objects
For example, to obtain an array of all nodes:

nodes = network.row_objects('_nodes')
Getting and Setting Values in Row Objects
Named Fields
Named fields are the fixed properties of each type of object, which will be familiar to users of the software. A field can contain different types of data:

Primitive data types - strings, numbers, booleans, etc which can be accessed and set directly
Arrays - some fields contain arrays of data, e.g. pipe bends
Structured data - represented by a WSStructure class, which is used to access and set rows of data
Fake - not accessible to Ruby, but exist in the user interface to summarize other data
Flags are separate fields, i.e. a field node_id also has a field node_id_flag.

The real (database) name of a field may not match the interface name. The interface name is usually called the 'Description'.

Get / Set Methods
Getting and setting values can use the Array/Hash like [] and []= notation:

value = ro['field'] # Get value from an object field
ro['field'] = value # Set value of an object field
Or using method like notation:

value = ro.field # Get value from an object field
ro.field = value # Set value of an object field
Note that some fields are incompatible with the method like notation due to their name.

Nil Values
Fields can usually be set to nil which is the equivalent of being empty in the user interface, or NULL in SQL. Like SQL, some fields may contain an empty string value, which is not the same as nil.

Unlike SQL, nil values cannot be safely ignored. For example, this SQL script finds and selects pipes with a length less than or equal to 200:

DESELECT ALL;
SELECT WHERE length  0
  working = unprocessedLinks.shift
  working.selected = true
  workingUSNode = working.us_node
  if !workingUSNode.nil? && !workingUSNode._seen
    workingUSNode.selected = true
    workingUSNode.us_links.each do |l|
      if !l._seen
        unprocessedLinks  0
  working = unprocessedLinks.shift
  working.selected = true
  workingUSNode = working.navigate1('us_node')
  if !workingUSNode.nil? && !workingUSNode._seen
    workingUSNode.selected=true
    workingUSNode.navigate('us_links').each do |l|
      if !l._seen
        unprocessedLinks .to_time, and to convert back use .to_datetime. Workgroup methods expecting a DateTime will not work with Time.

Creating new DateTime objects
You can create DateTime objects using the new method:

puts DateTime.new(2001, 01, 01, 12, 45)
⇒ "2024-01-01T12:45:00+00:00"
You can also get the current time:

right_now = DateTime.now
Overriding Display Behaviour
By default, when a DateTime object is converted to a string (e.g. via the puts method) the output will appear like this:

puts commit.date
⇒ "2023-12-25T16:58:50+01:00"
To customise the output you can use strftime:

puts commit.strftime("%F %T")
⇒ "2023-12-25 17:00:37"
For the best compatibility with other systems, you should use the .iso8601 method which returns a string in a standard format.

puts commit.iso8601
⇒ "2023-12-25T10:36:50+01:00"
Dates and Times in Results
Simulations can use absolute or relative times, so the following convention is used:

Absolute times are represented as a Ruby DateTime object
Relative times are represented as a negative double (time in seconds)

ICM Exchange for Autodesk
ICM Exchange is the IExchange implementation of InfoWorks ICM for our Autodesk products. It is only available for users with an Ultimate licence.

Usage
ICMExchange [options] [--] script [-login|-l] [args]

Parameter	Description
options	
(Optional) These are any Ruby command line options. See Command Line Options.

--	(Optional) Separator for the Ruby command line options.
script	
The path of the Ruby script.

Make sure to surround with "" if it contains spaces.

-login or -l	
(Optional) When set, it displays the Autodesk Identity web page for users to log-in.

If the user is already logged-in, it will proceed without showing the web page.

If not set and the user is not logged-in, it will show the error:

"Autodesk Licensing Error: The licence is not authorised (3).unable to initialise"

args	(Optional) It is possible to provide more arguments to the script with the extra arguments.
Note: Subscription overuse rules will apply.

Command Line Options
Ruby interpreter accepts following command-line options (switches). Basically they are quite similar to those of Perl.

-0digit

Specifies the input record separator ($/) as an octal number. If no digits given, the null character is the separator. Other switches may follow the digits. -00 turns Ruby into paragraph mode. -0777 makes Ruby read whole file at once as a single string, since there is no legal character with that value.

-a

Turns on auto-split mode when used with -n or -p. In auto-split mode, Ruby executes

$F = $_.split
at beginning of each loop.

-c

Causes Ruby to check the syntax of the script and exit without executing. If there is no syntax error, Ruby will print "Syntax OK" to the standard output.

-Kc

Specifies KANJI (Japanese character) code-set.

-d

--debug

Turns on debug mode. $DEBUG will set true.

-e script

Specifies script from command-line. if -e switch specified, Ruby will not look for a script filename in the arguments.

-F regexp

Specifies input field separator ($;).

-h

--help

Prints a summary of the options.

-i extension

Specifies in-place-edit mode. The extension, if specified, is added to old filename to make a backup copy.

Example:

% echo matz > /tmp/junk	
% cat /tmp/junk	
matz
% ruby -p -i.bak -e '$_.upcase!' /tmp/junk
% cat /tmp/junk
MATZ
% cat /tmp/junk.bak
matz
-I directory

Used to tell Ruby where to load the library scripts. Directory path will be added to the load-path variable (`$:').

-l

Enables automatic line-ending processing, which means firstly set $\ to the value of $/, and secondly chops every line read using chop!, when used with -n or -p.

-n

Causes Ruby to assume the following loop around your script, which makes it iterate over filename arguments somewhat like sed -n or awk.

while gets
...
end
-p

Acts mostly same as -n switch, but print the value of variable $_ at the each end of the loop.

Example:

% echo matz | ruby -p -e '$_.tr! "a-z", "A-Z"'
MATZ
-r filename

Causes Ruby to load the file using require. It is useful with switches -n or -p.

-s

Enables some switch parsing for switches after script name but before any filename arguments (or before a --). Any switches found there is removed from ARGV and set the corresponding variable in the script.

Example:

#! /usr/local/bin/ruby -s
# prints "true" if invoked with `-xyz' switch.
print "true\n" if $xyz
-S

Makes Ruby uses the PATH environment variable to search for script, unless if its name begins with a slash. This is used to emulate #! on machines that don't support it, in the following manner:

#!/bin/sh
exec ruby -S -x $0 "$@"
#! ruby
On some systems $0 does not always contain the full pathname, so you need -S switch to tell Ruby to search for the script if necessary.

-T [level]

Forces "taint" checks to be turned on so you can test them. If level is specified, $SAFE to be set to that level. It's a good idea to turn them on explicitly for programs run on another's behalf, such as CGI programs.

-v

--verbose

Enables verbose mode. Ruby will prints its version at the beginning, and set the variable `$VERBOSE' to true. Some methods prints extra messages if this variable is true. If this switch is given, and no other switches present, Ruby quits after printing its version.

--version

Prints the version of Ruby executable.

-w

Enables verbose mode without printing version message at the beginning. It set the variable `$VERBOSE' to true.

-x[directory]

Tells Ruby that the script is embedded in a message. Leading garbage will be discarded until the first that starts with "#!" and contains string "ruby". Any meaningful switches on that line will applied. The end of script must be specified with either EOF, ^D (control-D), ^Z (control-Z), or reserved word __END__.If the directory name is specified, Ruby will switch to that directory before executing script.

-X directory

Causes Ruby to switch to the directory.

-y

--yydebug

Turns on compiler debug mode. Ruby will print bunch of internal state messages during compiling scripts. You don't have to specify this switch, unless you are going to debug the Ruby interpreter itself.

WSApplication
The top-level of the application in scripts run from the User Interface and Exchange.

This is a static class, meaning that methods are used anywhere in your scripts with WSApplication.method_name syntax. Most methods are used to get/set global application settings, or create/open databases.

Methods:

add_ons_folder
background_network
cancel_job
choose_selection
color
connect_local_agent
create
create_transportable
current_database
current_network
file_dialog
folder_dialog
graph
input_box
launch_sims
launch_sims_ex
local_root
map_component
map_component= (Set)
message_box
open
open_text_view
override_user_unit
override_user_units
prompt
results_folder
rpa_export
scalars
script_file
set_exit_code
set_results_folder
set_working_folder
ui?
use_arcgis_desktop_licence
use_user_units= (Set)
use_user_units?
use_utf8= (Set)
use_utf8?
version
wait_for_jobs
wds_query_databases
working_folder
add_ons_folder
#add_ons_folder ⇒ String
EXCHANGE, UI

Returns the full path of the add-ons folder e.g.

C:\Users\badger\AppData\Roaming\Innovyze\WorkgroupClient\scripts

Note that the folder will not exist unless manually created. Its parent folder will almost certainly exist.

Parameters

Name	Type(s)	Description
Return	String	
background_network
#background_network ⇒ WSOpenNetwork?
UI

Returns the active background network, which will be from the GeoPlan that currently has focus.

cancel_job
#cancel_job(id) ⇒ void
EXCHANGE

Cancel a job being run by the agent.

Parameters

Name	Type(s)	Description
id	Integer	The job id, retrieved from the #launch_sims method.
choose_selection
#choose_selection(title) ⇒ WSModelObject?
UI

Displays a prompt allowing the user to choose a selection list object from the current database.

Parameters

Name	Type(s)	Description
title	String	The text displayed on the prompt's title bar.
Return	WSModelObject, nil	The selection list if the user chooses one and presses ok, returns nil otherwise.
color
#color(r, g, b) ⇒ Integer
UI

This method converts RGB values to an integer format suitable for the #graph method.

#color(0, 0, 0) returns black, #color(255, 0, 0) returns red, #color(255, 255, 255) returns white.

Note: this method previously used the international English spelling (colour), instead of US English (color). We recommend using the new method name.
Parameters

Name	Type(s)	Description
r	Numeric	The red value (between 0 and 255).
g	Numeric	The green value (between 0 and 255).
b	Numeric	The blue value (between 0 and 255).
connect_local_agent
#connect_local_agent(timeout) ⇒ Boolean
EXCHANGE

Connects to the local agent.

Parameters

Name	Type(s)	Description
timeout	Numeric	The number of milliseconds to wait (1000ms = 1s).
Return	Boolean	If the connection to the local agent was successful.
create
#create(path, version) ⇒ void
EXCHANGE

Creates a new database, which can be a standalone or workgroup database. To create a transportable database, use the #create_transportable method instead.

Note: it is important to use an absolute path when creating a standalone database.
Examples

WSApplication.create('C:/Badger/MyNewDatabase.icmm')
WSApplication.create('C:/Badger/MyNewDatabase.icmm', "2024.0")
WSApplication.create('localhost:40000/Badger/MyNewDatabase')
WSApplication.create('localhost:40000/Badger/MyNewDatabase', "2024.0")
Parameters

Name	Type(s)	Description
path	String	Path to the database, which could be a filepath for a standalone database c:/badger/mynewdatabase.icmm, or a connection string localhost:40000/badger/mynewdatabase.
version	String	The specific application version to use, in the format 2023.0, 2023.1 etc - if unset, then the current application version is used.
Exceptions

Error 43 : Can't overwrite an existing database - if the database already exists
C:/Badger/MyNewDatabase.icmm contains an incorrect path - if the database path is invalid
create_transportable
#create_transportable(path, version) ⇒ void
EXCHANGE

Creates a transportable database.

Note: it is important to use an absolute path when creating the database.
Examples

WSApplication.create('C:/Temp/Badger.wspt')
WSApplication.create('C:/Temp/Badger.wspt', "2024.0")
Parameters

Name	Type(s)	Description
path	String	The absolute path to the database, which should include the filename and extension.
version	String	The application version number, e.g. 2024.0 - see the #create method.
current_database
#current_database ⇒ WSDatabase
UI

Returns the current database, when the script is running in the user interface. Note that there is limited database functionality from the UI.

Parameters

Name	Type(s)	Description
Return	WSDatabase	
current_network
#current_network ⇒ WSOpenNetwork
UI

Returns the active network, which will be from the GeoPlan that currently has focus.

The current network may have results loaded, and/or be read only. If results are loaded then these will be available to the script.

Parameters

Name	Type(s)	Description
Return	WSOpenNetwork	
file_dialog
#file_dialog(open, extension, description, default, multiple, hard_wire_cancel) ⇒ String? or Array\?
UI

Displays a file prompt (open or save), and if OK is selected returns the file path, or if allow_multiple_files was set to true, an array of selected files.

It is not possible to indicate a default folder to open the dialog in.

Parameters

Name	Type(s)	Description
open	Boolean	If true, presents an 'open file' dialog to select an existing file you intend to read, otherwise presents a 'save file' dialog to select the name of a new file you intend to write to.
extension	String	The file extension (without a period) e.g csv, dat, or xml.
description	String	A file type description e.g. comma separated value file.
default	String	The default file name (not including path).
multiple	Boolean	If true, this allows more than one file to be selected - it is ignored if open is true.
hard_wire_cancel	Boolean	If true or nil, then if the user cancels or closes the dialog the ruby script will exit.
Return	String, Array, nil	The path of the file as a string, an array of strings if multiple_files is true, or nil if hard_wire_cancel is false and the user cancels or closes the dialog.
folder_dialog
#folder_dialog(title, hard_wire_cancel) ⇒ String?
UI

Displays a dialog allowing the user to select a folder.

Parameters

Name	Type(s)	Description
title	String	The title for the dialog.
hard_wire_cancel	Boolean	If true or nil, then if the user cancels or closes the dialog the ruby script will exit.
Return	String, nil	The path of the folder, will be nil if hard_wire_cancel is false and the user cancels or closes the dialog.
graph
#graph(options) ⇒ void
UI

Displays a graph according to the parameters passed in.

The graph method contains 1 parameter, a hash. It has the following keys, which are all strings:

WindowTitle - a string containing the title of the window
GraphTitle - a string containing the title of the graph
XAxisLabel - a string containing the label of the X-axis
YAxisLabel - a string containing the label of the Y-axis
IsTime - a boolean (or statement which evaluates as true or false) which should be set to true if the x axis is made up of time values and is labelled as dates / times.
Traces - an array of traces
Each trace in the array of traces is in turn also a hash. The trace hash has the following keys, which are all strings:

Title - a string giving the trace's name
TraceColour - an integer containing an RGB value of the trace's colour. A convenient way of getting this is to use the WSApplicatioon.colour method
SymbolColour - an integer containing an RGB value of the colour used for the symbol used at the points along the trace. A convenient way of getting this is to use the WSApplicatioon.colour method
Marker - a string containing the symbol to be used for the points along the trace - possible values are (F means 'filled'):
None, Cross, XCross, Star, Circle, Triangle, Diamond, Square, FCircle, FTriangle, FDiamond, FSquare
LineType - a string containing the style to be used for the trace's line - possible values are:
None, Solid, Dash, Dot, DashDot, DashDotDot
XArray - an array containing the values used in the trace for the x coordinates of the points. They must be floating point values (or values that can be converted to a floating point values) if IsTime is false or time values if IsTime is true.
YArray - an array containing the values used in the trace for the x coordinates of the points. They must be floating point values (or values that can be converted to a floating point values).
There must be an equal number of values in the XArray and YArray in each trace, though they can vary between traces.

input_box
#input_box(prompt, title, default) ⇒ String?
UI

Displays a dialog prompting the user for a text value.

Can also be used for number values, but you will need to convert and validate the input manually, for example:

distance = WSApplication.input_box('Distance in Meters (1-100m)', 'Enter A Distance', '50.0')
distance_f = distance.to_f
raise format("Invalid Value: %s", distance) unless (distance_f&.between?(0, 100)
Parameters

Name	Type(s)	Description
prompt	String	Text that appears on the dialog.
title	String, nil	The title of the dialog window, if nil or an empty string then a default title is used instead.
default	String	The initial value of the text input.
Return	String, nil	The value of the text field when the user clicks ok, or nil if the user clicks cancel.
launch_sims
#launch_sims(sims, server, results_on_server, max_threads, after) ⇒ Array
EXCHANGE

Launches one or more simulations. This method requires #connect_local_agent to have been called already.

The job IDs returned are intended for use as parameters to the #wait_for_jobs method and the #cancel_job method. Any nil values in the array will be safely ignored by the #wait_for_jobs method so the results array may be passed into it.

Parameters

Name	Type(s)	Description
sims	Array	An array of simulations.
server	String	The name of the server to run the simulation on, or '.' for the local machine or '*' for any computer.
results_on_server	Boolean	
max_threads	Integer	The maximum number of threads to use for this simulation (or 0 to allow the simulation agent to choose).
after	Integer	The time (as a time_t time) after which the simulation should run, or 0 for 'now'.
Return	Array	An array of job ids, one for each simulation in the sims array, the id of a given simulation will be nil if the simulation failed to launch.
launch_sims_ex
#launch_sims_ex(sims, options) ⇒ Array
EXCHANGE

Launches one or more simulations. This method requires #connect_local_agent to have been called already.

The job IDs returned are intended for use as parameters to the #wait_for_jobs method and the #cancel_job method. Any nil values in the array will be safely ignored by the #wait_for_jobs method so the results array may be passed into it.

The options hash contains the following keys:

Name	Type	Default	Description
RunOn	String	'.'	the name of the server to run the simulation on, or '.' for the local machine or '*' for any computer. Non-cloud databases only.
ResultsOnServer	Boolean	false	Results on server or locally. Non-cloud databases only.
MaxThreads	Integer	0	The maximum number of threads to use for this simulation (or 0 to allow the simulation agent to choose). Non-cloud databases only.
After	Integer	0	The time after which the simulation should run, or 0 for ‘now’. Non-cloud databases only.
SU	Boolean	false	Use ICMOne license if available. Non-cloud databases only. Default False.
DownloadSelection	String	'ALL_RESULTS'	Results to download. Valid values are NO_RESULTS, SUMMARY_RESULTS and ALL_RESULTS. Could databases only.
Parameters

Name	Type(s)	Description
sims	Array	An array of simulations.
options	Hash	An options hash, see method description.
Return	Array	An array of job ids, one for each simulation in the sims array, the id of a given simulation will be nil if the simulation failed to launch.
local_root
#local_root ⇒ String
EXCHANGE, UI

This method has no arguments and returns a string indicating the working folder.

Example

puts WSApplication.local_root
Parameters

Name	Type(s)	Description
Return	String	String indicating the working folder.
map_component
#map_component ⇒ String?
EXCHANGE

Returns the map component being used.

Parameters

Name	Type(s)	Description
Return	String, nil	The map component in use, if any. the supported map components are mapxtreme, arcobjects, and arcengine.
map_component= (Set)
#map_component=(component) ⇒ void
EXCHANGE

Sets the map component to be used.

Parameters

Name	Type(s)	Description
component	String	The map component to use. supported values are mapxtreme, arcobjects, and arcengine.
message_box
#message_box(text, buttons, icon, hard_wire_cancel) ⇒ String?
UI

Displays a message box. The title bar cannot be customised.

Icon '!' or nil:

!

Icon '?':

!

Icon 'Information':

!

Icon 'Stop':

!

Buttons 'OK':

!

Buttons 'OkCancel' or nil:

!

Buttons 'YesNo':

!

Buttons 'YesNoCancel':

!

Parameters

Name	Type(s)	Description
text	String	The text displayed in the prompt.
buttons	String, nil	Buttons to display, one of 'ok', 'okcancel', 'yesno', 'yesnocancel', or nil (which defaults to 'okcancel').
icon	String, nil	Icon to display, one of '!', '?', 'information', 'stop', or nil (which defaults to '!').
hard_wire_cancel	Boolean, nil	If true or nil, when the user closes the prompt or presses cancel, the running of the ruby script is interrupted.
Return	String, nil	The selected option as a string, e.g. 'yes', 'no', 'ok', or 'cancel'.
open
#open() ⇒ WSDatabase
#open(path) ⇒ WSDatabase
#open(path, update) ⇒ WSDatabase
#open(path, version) ⇒ WSDatabase
EXCHANGE

Opens a database and returns it as a WSDatabase object.

Note that this method implements method overloading, where the second positional parameter is either update or version depending on the type.

You should only open one instance of a database per Exchange process. Opening multiple instances of the same database, even if the variable containing the earlier instance is now out of scope, can cause errors. Multiple instances of unique databases is ok.

Parameters

Name	Type(s)	Description
path	String	Path to the database. This can be obtained from the "Database" row in the "Additional Information" window opened from the About box in the user interface. It could be the path to a cloud database cloud://mydatabase.4@63f653b1c7cf77000873ab9b/namer a connection string localhost:40000/badger/mydatabase, or a filepath to a standalone database c:/badger/mydatabase.icmm. If unset it will use the database most recently opened in the UI.
update	Boolean	Updates the database to the current software version, default is false.
version	String	Updates the database to a specific software version, in the format 2024.0, 2024.1, etc.
Return	WSDatabase	The opened database, this method will raise an exception if the database could not be opened.
Exceptions

Error 13 : File Not Found : C:/Badger/MyDatabase.icmm (error=2: "The system cannot find the file specified.") - if the database is not present
Error 13 : File Not Found : C:/Badger/MyDatabase.icmm (error=3: "The system cannot find the path specified.") - if the database path is invalid
no database path specified - if the path is nil and there is no recently opened database in the UI
minor update failed major update failed - if there is a problem with a database update
database requires minor update but allow update flag is not set database requires major update but allow update flag is not set - if the database requires an update, but the update parameter is false
open_text_view
#open_text_view(title, filename, delete_on_exit) ⇒ void
UI

Opens a text file and displays it in a dialog.

This does not block the current thread, meaning that the dialog is opened and the script will continue running and potentially exit.

Parameters

Name	Type(s)	Description
title	String	The window title.
filename	String	The path to the text file to open.
delete_on_exit	Boolean	If true, the file will be deleted when the dialog is closed by the user. this allows the script to create a temporary file, and have the application handle deletion once the use closes the dialog, which may happen after the script has finished.
override_user_unit
#override_user_unit(code, value) ⇒ Boolean
EXCHANGE

Used to override a user unit for the duration of the script. This may be useful where Exchange is running on a system that does not have any existing user settings, and you don't want to use the default user units selected for the locale.

success = WSApplication.override_user_unit('X', 'ft')
raise "Failed to set user unit X" unless success
To apply user unit overrides in bulk using a CSV file, use the #override_user_units method.

Parameters

Name	Type(s)	Description
code	String	Unit code to override e.g. 'xy'.
value	String	Unit value code e.g. 'us survey ft'.
Return	Boolean	If the user unit was set successfully, false if the unit code or unit value was invalid.
override_user_units
#override_user_units(file) ⇒ String
EXCHANGE

Used to override the user units for the duration of the script, using a CSV file. This may be useful where Exchange is running on a system that does not have any existing user settings, and you don't want to use the default user units selected for the locale.

The CSV file should contain comma separated pairs of the unit code and unit value with no header, for example:

XY, US Survey ft
All valid units from the CSV will be applied, even if there are some errors with lines in the file.

errs = WSApplication.override_user_units('c:/temp/uu.csv')
puts format("Error reading CSV file: %s", errs) unless errs == ''
To apply unit overrides directly, see the #override_user_unit method.

Parameters

Name	Type(s)	Description
file	String	Filepath to the units file (see description).
Return	String	Any errors, or an empty string if all units were set successfully.
Exceptions

Error 13 : File Not Found : c:\temp\uu.csv (error=3: "The system cannot find the path specified.") - if the file does not exist
prompt
#prompt(title, layout, hard_wire_cancel) ⇒ Array?
UI

Displays a window containing a grid of values, which users can optionally edit. This can be used to create scripts that can be launched from the UI with many customisable parameters.

The layout parameter is an Array, containing one Array for each row / line.

0 (String) - description of the value
1 (String) - type of value, one of NUMBER, STRING, DATE, BOOLEAN, READONLY
2 (Any) - default value, optional unless the type is READONLY
3 (Integer, nil) - number of decimal places for numbers
4 (String) - subtype, this also determines the further index values
RANGE - valid for type NUMBER, where the value is chosen from a combo box with values between index 5 and 6 inclusive
5 (Numeric) - Minimum range
6 (Numeric) - Maximum range
LIST - valid for types NUMBER, STRING, and DATE, where the value is chosen from a combo box with values from index 5
5 (Array) - Values in the combo box
MONTH - valid for type NUMBER only, the value will be chosen from a combo box containing the names of the months
FILE - valid for type STRING only, with the options from index 5 through 8
5 (Boolean) - true for an 'open' dialog, false for a 'save' dialog
6 (String) - file extension without period e.g. csv, txt
7 (String) - description of the file type
8 (Boolean, nil) - whether to allow selecting multiple files if this is a open dialog (index 5 is true)
FOLDER - valid for type STRING
5 (String, nil) - title for the folder window, if nil a default title is used
Example numbers:

['A number', 'NUMBER']
['A readonly number with a decimal precision of 2', 'READONLY', 35.02463, 2]
['Range of numbers', 'NUMBER', 13, 2, 'RANGE', 100, 200]
['List of numbers with no default', 'NUMBER', nil, nil, 'LIST',[3, 5, 7, 11]]
['List of numbers with default', 'NUMBER', 23, nil, 'LIST', [13, 17, 19, 23]]
Example strings:

['A string', 'STRING']
['A readonly string', 'READONLY', 'Default Value']
['List', 'STRING', 'Default', nil, 'LIST', ['Alpha','Beta','Gamma']]
Example dates:

['A date', 'DATE']
['A date with default value', 'DATE']
['This is a month', 'Number', 11, nil, 'MONTH']
Example booleans:

['A boolean', 'BOOLEAN']
['A boolean with a default value of false', 'BOOLEAN', false]
Example files:

['File save', 'STRING', 'Badger.txt', nil, 'FILE', false, 'txt', 'Text file', false],
['File load single', 'STRING', nil, nil, 'FILE', true, 'txt', 'MySystem text file', false],
['File load multiple', 'STRING', nil, nil, 'FILE', true, 'txt', 'More than one text file', true]
Example folders:

['Results folder', 'STRING', nil, nil, 'FOLDER', 'Select a Results Folder']
['Results folder with a default', 'STRING', 'C:/SomeFolder', nil, 'FOLDER', nil]
Parameters

Name	Type(s)	Description
title	String	The title of the window.
layout	Array	See method description.
hard_wire_cancel	Boolean, nil	If true or nil, when the user closes the prompt or presses cancel, the running of the ruby script is interrupted.
Return	Array, nil	An array of values matching each line of the layout array, unless the prompt was cancelled.
results_folder
#results_folder ⇒ String
EXCHANGE, UI

Returns the current results folder. By default, this is %AppData%\Local\Innovyze\Results Folder.

Parameters

Name	Type(s)	Description
Return	String	
rpa_export
#rpa_export(sim_ids, return_per, output_file)  ⇒ void
EXCHANGE, UI

Performs a Return Period Analysis and exports the results to a csv file. The output is equivalent to the Results - RPA Grid Report in the ICM application.

Parameters

Name	Type(s)	Description
sim_ids	Array	Integer ids of successful sims.
return_per	Integer	Return period in years.
output_file	String	Path with filename for the csv output.
scalars
#scalars(title, layout, hard_wire_cancel) ⇒ void
UI

This method displays a grid of key / values, similar to that generated by SQL, except only a simple pair instead of a table.

Each item in the layout array is one row of the grid, and must contain 2 or 3 values as follows:

Index 0 (String) description / key of the row
Index 1 (Any) the value to be displayed, if the value is a float or a double it will be displayed by using the Ruby #to_f method, otherwise the Ruby #to_s method will be used
Index 2 (Integer) - optional when displaying numbers, the number of decimal places to be used (between 0 and 8 inclusive)
Parameters

Name	Type(s)	Description
title	String	The window title.
layout	Array	Array of items to show, see description.
hard_wire_cancel	Boolean	If true or nil, when the user hits cancel the running of the ruby script is interrupted.
script_file
#script_file ⇒ String
EXCHANGE, UI

Returns the absolute path of the first Ruby script: either the file specified in the command line of Exchange, or the file selected from the user interface.

This method can be used to consistently obtain the script's location, in order to access other files in the same directory e.g. config files for the Open Data Import / Export methods.

For example, using Ruby's File.dirname to get the folder:

script_file = WSApplication.script_file
⇒ "C:\Badger\script.rb"

File.dirname(script_file)
⇒ "C:\Badger"
This is different to Ruby's built in __dir__ constant, which returns the directory of the current script file the method is called from. For example, if your primary script is C:\Badger\script.rb, but it requires another script C:\Badger\lib\util.rb, when __dir__ is used anywhere in util.rb it would return C:\Badger\lib.

Parameters

Name	Type(s)	Description
Return	String	
set_exit_code
#set_exit_code(code) ⇒ void
EXCHANGE

Sets the exit code of the Exchange process. The default exit code is 0, which by common convention indicates success, with any number higher than that indicating an exceptional state.

This does not affect the script's execution, it only sets the exit code returned to the operating system when it finishes. Exit codes are commonly used to indicate the outcome of a process, e.g. if you are running scripts via a task scheduler this could return whether it was successful.

Parameters

Name	Type(s)	Description
code	Integer	The application exit code, should be a positive integer (default 0).
Exceptions

exit code is not a number - if the code was an invalid type or value
set_results_folder
#set_results_folder(path) ⇒ void
EXCHANGE

Sets the results folder for this instance of Exchange. By default Exchange will use the same results directory as the user interface, usually %AppData%\Local\Innovyze\Results Folder.

This setting is not stored or persisted in any way, it is only used for the current running Exchange process.

Parameters

Name	Type(s)	Description
path	String	Path to results folder.
set_working_folder
#set_working_folder(path) ⇒ void
EXCHANGE

Sets the working folder for this instance of Exchange. By default Exchange will use the same working directory as the user interface, usually %AppData%\Local\Innovyze\Working Folder.

If multiple instances of the application (including the user interface) attempt to access the same database using the same working directory, this can cause data access conflicts. Changing the working directory can be used to avoid this.

This setting is not stored or persisted in any way, it is only used for the current running Exchange process.

Parameters

Name	Type(s)	Description
path	String	Path to working folder.
ui?
#ui? ⇒ Boolean
EXCHANGE, UI

Returns whether the the script is running in the user interface. This allows a Ruby script to behave differently depending on context, or ensure certain scripts only work in the intended environment.

Exampless

# Restrict script to running via the User Interface
raise "This script must be run from the user interface" unless WSApplication.ui?

# Restrict script to running via Exchange
raise "This script cannot be run from the user interface" if WSApplication.ui?

# Change behavior
if WSApplication.ui?
  network = WSApplication.current_network
else
  database = WSApplication.open
  network = database.model_object_from_type_and_id('Geometry', 1)
end
Parameters

Name	Type(s)	Description
Return	Boolean	
use_arcgis_desktop_licence
#use_arcgis_desktop_licence(bool) ⇒ void
EXCHANGE

Sets whether the Open Data Import / Export Centre methods should use an ArcGIS desktop license.

By default, Exchange will use an ArcGIS server license if one is available. When scripts are run from the UI, an ArcGIS desktop license is always used.

It is the responsibility of the user to choose an appropriate ArcGIS license based on their use of the software.

Parameters

Name	Type(s)	Description
bool	Boolean	
use_user_units= (Set)
#use_user_units=(bool) ⇒ void
EXCHANGE, UI

Sets whether the application should use user units. By default it will be false when the script is running via Exchange, and true via the UI.

Parameters

Name	Type(s)	Description
bool	Boolean	
use_user_units?
#use_user_units? ⇒ Boolean
EXCHANGE, UI

Returns whether the application is using user units. By default it will be false when the script is running via Exchange, and true via the UI.

Parameters

Name	Type(s)	Description
Return	Boolean	
use_utf8= (Set)
#use_utf8=(flag) ⇒ void
EXCHANGE, UI

Sets whether the application should use UTF8 in string handling. The default is false.

Note: This method previously included capitalization, we recommend using the new lower case method name.
Parameters

Name	Type(s)	Description
flag	Boolean	Whether to use utf8 in string handling.
use_utf8?
#use_utf8? ⇒ Boolean
EXCHANGE, UI

Returns whether the application is using UTF8 in string handling. The default is false.

Note: This method previously included capitalization, we recommend using the new lower case method name.
Parameters

Name	Type(s)	Description
Return	Boolean	
version
#version ⇒ String
EXCHANGE, UI

Returns the software version number as a string. This is the software version found in the About dialog, not the version title.

puts WSApplication.version
⇒ '26.0.162'
Parameters

Name	Type(s)	Description
Return	String	
wait_for_jobs
#wait_for_jobs(jobs, wait_for_all, timeout) ⇒ Integer?
EXCHANGE

Waits for one or all of the jobs to complete, or for the timeout to be reached. This will block the current script thread.

Parameters

Name	Type(s)	Description
jobs	Array	An array of job ids (e.g. from the #launch_sims method) - the array can contain nil values, which will be safely ignored.
wait_for_all	Boolean	If true, wait for all jobs in the jobs array to complete, false to wait for any.
timeout	Numeric	A timeout in milliseconds (1000ms = 1s).
Return	Integer, nil	The index of the jobs array that caused the wait to end, or nil if the timeout was exceeded.
wds_query_databases
#wds_query_databases(server, port) ⇒ Hash
EXCHANGE, UI

Queries a Workgroup Data Server. Returns a hash containing:

response (String) - the server response, i.e. the workgroup data server version
databases (Array), where each hash contains:
databaseName (String) - the database group and name
version (String) - the database version
versionIsCurrent (Boolean) - if the database is the latest version supported by the workgroup data server
allowDatabaseCreation (Boolean)
wds = WSApplication.wds_query_databases('localhost', 40000)
{
  "response": "SuperNumbat 29.0.60 Sep 13 2023",
  "databases": [
    {
      "databaseName": "Databases/Badger",
      "version": "2024.2",
      "versionIsCurrent": false
    },
    {
      "databaseName": "Databases/Penguin",
      "version": "2024.5",
      "versionIsCurrent": true
    }
  ],
  "allowDatabaseCreation": true
}
Parameters

Name	Type(s)	Description
server	String	The server address, for a local workgroup data server use localhost.
port	Integer	The server port, the default port is 40000.
Return	Hash	See method description.
working_folder
#working_folder ⇒ String
EXCHANGE, UI

Returns the current working folder. By default, this will be %AppData%\Local\Innovyze\Working Folder.

Parameters

Name	Type(s)	Description
Return	String

WSBaseNetworkObject
WSModelObject > WSBaseNetworkObject

Methods:

csv_export
csv_import
odec_export_ex
Data Export for CSV (Comma Separated Values)
Data Export for TSV (Tab Separated Values)
Data Export for XML (Extensible Markup Language)
Data Export for MDB (Jet / Microsoft Access Database)
Data Export for SHP (ESRI Shapefile)
Data Export for TAB (MapInfo TAB)
Data Export for GDB (Personal GeoDatabase)
Data Export for FILEGDB (File GeoDatabase)
Data Export for ORACLE (Oracle Database)
Data Export for SQLSERVER (Microsoft SQL Server)
odic_import_ex
Data Import for CSV (Comma Separated Values)
Data Import for TSV (Tab Separated Values)
Data Import for XML (Extensible Markup Language)
Data Import for MDB (Jet / Microsoft Access Database)
Data Import for SHP (ESRI Shapefile)
Data Import for TAB (MapInfo TAB)
Data Import for GDB (Personal GeoDatabase)
Data Import for FILEGDB (File GeoDatabase)
Data Import for ORACLE (Oracle Database)
Data Import for SQLSERVER (Microsoft SQL Server)
remove_local
csv_export
#csv_export(file, options) ⇒ void
EXCHANGE

Exports the network to a CSV file, with options similar to those in the user interface.

The options hash contains the following keys:

Key	Type	Default	Notes
Use Display Precision	Boolean	true	
Field Descriptions	Boolean	false	
Field Names	Boolean	true	
Flag Fields	Boolean	true	
Multiple Files	Boolean	false	Set to true to export to different files, false to export to the same file
Native System Types	Boolean	false	
User Units	Boolean	false	
Object Types	Boolean	false	
Selection Only	Boolean	false	
Units Text	Boolean	false	
Triangles	Boolean	false	
Coordinate Arrays Format	String	'Packed'	'Packed', 'None', or 'Separate'
Other Arrays Format	String	'Packed'	'Packed', 'None', or 'Unpacked'
WGS84	Boolean	false	Export coordinates as WGS84
Examples

options = {
  'Multiple Files' => true,
  'Coordinate Arrays Format' => 'None'
}

network.csv_export('C:/Badger/my_csv.csv', options)
Parameters

Name	Type(s)	Description
file	String	Path to the csv file.
options	Hash, nil	Options hash (see description), or nil to use default values.
csv_import
#csv_import(file, options) ⇒ void
EXCHANGE

Updates the network from a CSV file, with options similar to those in the user interface.

The options hash uses the following keys:

Key	Type	Default	Notes
Force Link Rename	Boolean	true	
Flag Genuine Only	Boolean	false	
Load Null Fields	Boolean	true	
Update With Any Flag	Boolean	true	True to update all values, false to only update fields with the 'update flag' flag
Use Asset ID	Boolean	false	
User Units	Boolean	true	Set to true for User Units, false for Native Units - used for fields without an explicit unit set in a 'units' record
UK Dates	Boolean	false	If set to true, the import is done with the UK date format for dates regardless of the PC's settings
Action	String	'Mixed'	One of 'Mixed', 'Update And Add', 'Update Only', or 'Delete'
Header	String	'ID'	One of 'ID', 'ID Description', 'ID Description Units', or 'ID Units'
New Flag	String	nil	Flag used for new and updated data
Update Flag	String	nil	If the 'update with any flag' option is set to false, only update fields with this flag value
Examples

options = {
  'Use Asset ID' => true,
  'New Flag' => 'NEW'
}

network.csv_import('C:/Badger/my_csv.csv', options)
Parameters

Name	Type(s)	Description
file	String	Path to the csv file.
options	Hash, nil	Options hash (see description), or nil to use default values.
odec_export_ex
#odec_export_ex(format, config, options, table, *args) ⇒ void
EXCHANGE

Exports network data using the Open Data Export Centre.

The supported formats are CSV, TSV, XML, MDB, SHP, TAB, GDB, FILEGDB, ORACLE, and SQLSERVER. The format used determines the number of additional arguments in the method, which are detailed below.

The options hash uses the following keys:

Key	Type	Default	Notes
Error File	String	nil	
Image Folder	String	''	Asset Networks Only
Units Behaviour	String	'Native'	'Native' or 'User'
Report Mode	Boolean	false	True to export in 'report mode'
Append	Boolean	false	True to enable ‘Append to existing data’
Export Selection	Boolean	false	True to export the selected objects only
Previous Version	Integer	0	Previous version, if not zero differences are exported
Callback Class	Ruby Class	nil	
Create Primary Key	Boolean	false	
Previous Version	Integer	0	
Append	Boolean	false	
WGS84	Boolean	false	Shapefile only
Don't Update Geometry	Boolean	false	
Data Export for CSV (Comma Separated Values)
#odic_export_ex(format, config, options, table, file)
Exports data to a Comma Separated Values file.

Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be CSV
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ExportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the table to export, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
file	String		the absolute filepath to the export file, including extension e.g. "C:/Temp/Badger.csv"
Data Export for TSV (Tab Separated Values)
#odic_export_ex(format, config, options, table, file)
Exports data to a Tab Separated Values file.

Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be TSV
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ExportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the table to export, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
file	String		the absolute filepath to the export file, including extension e.g. "C:/Temp/Badger.csv" or "C:/Temp/Badger.tsv"
Data Export for XML (Extensible Markup Language)
#odic_export_ex(format, config, options, table, feature_class, feature_dataset, filename)
Exports data to an XML (Extensible Markup Language) file.

Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be XML
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ExportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the table to export, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
feature_class	String		the name of the root element, equivalent to UI option
feature_dataset	String		the name used for each data element, equivalent to UI option
file	String		the absolute filepath to the export file, including extension e.g. "C:/Temp/Badger.xml"
Data Export for MDB (Jet / Microsoft Access Database)
#odic_export_ex(format, config, options, table, destination, file)
Exports data to a Jet / Microsoft Access Database file.

Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be MDB
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ExportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the table to export, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
destination	String		the destination table in the database
file	String		the absolute filepath to the database, including extension e.g. "C:/Temp/Badger.mdb"
Data Export for SHP (ESRI Shapefile)
#odic_export_ex(format, config, options, table, file)
Exports data to an ESRI Shapefile.

Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be SHP
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ExportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the table to export, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
file	String		the absolute filepath to the export file, including extension e.g. "C:/Temp/Badger.shp"
Data Export for TAB (MapInfo TAB)
#odic_export_ex(format, config, options, table, file)
Exports data to a MapInfo TAB file.

Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be TAB
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ExportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the table to export, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
file	String		the absolute filepath to the export file, including extension e.g. "C:/Temp/Badger.tab"
Data Export for GDB (Personal GeoDatabase)
#odic_export_ex(format, config, options, table, feature_class, feature_dataset, update, keyword, file)
Exports data to a GeoDatabase.

Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be CSV
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ExportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the table to export, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
feature_class	String		the name of the root element, equivalent to UI option
feature_dataset	String		the name used for each data element, equivalent to UI option
update	Boolean		if true the feature class must already exist
keyword	String, nil		ArcSDE configuration keyword, nil for personal or File GeoDatabases, ignored for updates"
file	String		the absolute filepath to the export file, including extension e.g. .GDB for personal / file GeoDatabases, or the connection name for SDE
Data Export for FILEGDB (File GeoDatabase)
#odic_export_ex(format, config, options, table, feature_class, feature_dataset, update, keyword, file)
Exports data to a GeoDatabase.

Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be CSV
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ExportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the table to export, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
feature_class	String		the name of the root element, equivalent to UI option
feature_dataset	String		the name used for each data element, equivalent to UI option
update	Boolean		if true the feature class must already exist
keyword	String, nil		ArcSDE configuration keyword, nil for personal or File GeoDatabases, ignored for updates"
file	String		the absolute filepath to the export file, including extension e.g. .GDB for personal / file GeoDatabases, or the connection name for SDE
Data Export for ORACLE (Oracle Database)
#odic_export_ex(format, config, options, table, destination, owner, update, username, password, connection_string)
Exports data to an Oracle database.

Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be CSV
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ExportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the table to export, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
destination	String		the destination table name
owner	String		the owner of the destination table
update	Boolean		
password	String		
connection_string	String		
username	String		
Data Export for SQLSERVER (Microsoft SQL Server)
#odic_export_ex(format, config, options, table, destination, server, instance, database, update, trusted, username, password)
Exports data to a Microsoft SQL Server database. Other SQL database types such as PostGIS are not supported.

Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be SQLSERVER
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ExportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the table to export, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
destination	String		the destination table in the SQL Server database
server	String		the server address, e.g. localhost//SQLEXPRESS
instance	String		the SQL server instance name, or nil
database	String		the name of the database
update	String		
trusted	Boolean		use trusted connection / integrated security
username	String, nil		username, or nil if using a trusted connection
password	String, nil		password, or nil if using a trusted connection
odic_import_ex
#odic_import_ex(format, config, options, table, *args) ⇒ void
EXCHANGE

Imports and updates network data using the Open Data Import Centre.

The supported formats are CSV, TSV, XML, MDB, SHP, TAB, GDB, FILEGDB, ORACLE, and SQLSERVER. The format used determines the number of additional arguments in the method, which are detailed below.

The options hash uses the following keys:

Key	Type	Default	Notes
Allow Multiple Asset IDs	Boolean	false	
Blob Merge	Boolean	false	
Callback Class	Ruby Class	nil	Class used for Ruby callback method
Default Value Flag	String	nil	Flag used for fields set from the default value column
Delete Missing Objects	Boolean	false	
Duplication Behaviour	String	'Merge'	One of 'Overwrite', 'Merge', 'Ignore'
Error File	String	nil	Path of error file
Group Name	String	nil	Asset networks only
Group Type	String	nil	Asset networks only
Image Folder	String	nil	Folder to import images from (asset networks only)
Import Images	Boolean	false	Asset networks only
Set Value Flag	String	nil	Flag used for fields set from data
Units Behaviour	String	'Native'	One of 'Native', 'User', or 'Custom'
Update Based On Asset ID	Boolean	false	
Update Links From Points	Boolean	false	
Update Only	Boolean	false	
Use Network Naming Conventions	Boolean	false	
Don't Update Geometry	Boolean	false	
Data Import for CSV (Comma Separated Values)
#odic_import_ex(format, config, options, table, file) ⇒ void
Imports data from a Comma Separated Values file.

Examples

network.odic_import_ex('CSV', 'C:/Badger/Config.cfg', nil, 'Node', 'C:/Badger/MyNodes.csv')
Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be CSV
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ImportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the destination table, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)

Note that when importing a RTK Hydrograph table, the destination table must be specifed as UnitHydrograph not RTKHydrograph
file	String		the absolute filepath to the import file, including extension e.g. "C:/Temp/Badger.csv"
Data Import for TSV (Tab Separated Values)
#odic_import_ex(format, config, options, table, file) ⇒ void
Imports data from a Tab Separated Values file.

Examples

network.odic_import_ex('TSV', 'C:/Badger/Config.cfg', nil, 'Node', 'C:/Badger/MyNodes.tsv')
Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be TSV
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ImportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the destination table, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)

Note that when importing a RTK Hydrograph table, the destination table must be specifed as UnitHydrograph not RTKHydrograph
file	String		the absolute filepath to the import file, including extension e.g. "C:/Temp/Badger.csv" or "C:/Temp/Penguin.tsv"
Data Import for XML (Extensible Markup Language)
#odic_import_ex(format, config, options, table, file) ⇒ void
Imports data from an XML (Extensible Markup Language) file.

Examples

network.odic_import_ex('XML', 'C:/Badger/Config.cfg', nil, 'Node', 'C:/Badger/MyNodes.xml')
Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be XML
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ImportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the destination table, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)

Note that when importing a RTK Hydrograph table, the destination table must be specifed as UnitHydrograph not RTKHydrograph
file	String		the absolute filepath to the import file, including extension e.g. "C:/Temp/Badger.xml"
Data Import for MDB (Jet / Microsoft Access Database)
#odic_import_ex(format, config, options, table, database, source) ⇒ void
Imports data from a Jet / Microsoft Access Database file.

Examples

network.odic_import_ex('MDB', 'C:/Badger/Config.cfg', nil, 'Node', 'C:/Badger/MyDatabase.mdb', 'MyNodes')
Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be MDB
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ImportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the destination table, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
database	String		the absolute filepath to the database

Note that when importing a RTK Hydrograph table, the destination table must be specifed as UnitHydrograph not RTKHydrograph
source	String		a table in the database, or a stored SQL query in the database - a SQL expression cannot be used directly
Data Import for SHP (ESRI Shapefile)
#odic_import_ex(format, config, options, table, file) ⇒ void
Imports data from an ESRI Shapefile.

Examples

network.odic_import_ex('SHP', 'C:/Badger/Config.cfg', nil, 'Node', 'C:/Badger/MyNodes.shp')
Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be SHP
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ImportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the destination table, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)

Note that when importing a RTK Hydrograph table, the destination table must be specifed as UnitHydrograph not RTKHydrograph
file	String		the absolute filepath to the import file, including extension e.g. "C:/Temp/Badger.shp"
Data Import for TAB (MapInfo TAB)
#odic_import_ex(format, config, options, table, file) ⇒ void
Imports data from a MapInfo TAB file.

Examples

network.odic_import_ex('TAB', 'C:/Badger/Config.cfg', nil, 'Node', 'C:/Badger/MyNodes.tab')
Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be TAB
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ImportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the destination table, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)

Note that when importing a RTK Hydrograph table, the destination table must be specifed as UnitHydrograph not RTKHydrograph
file	String		the absolute filepath to the import file, including extension e.g. "C:/Temp/Badger.tab"
Data Import for GDB (Personal GeoDatabase)
#odic_import_ex(format, config, options, table, feature, file) ⇒ void
Imports data from a GeoDatabase.

Examples

network.odic_import_ex('GDB', 'C:/Badger/Config.cfg', nil, 'Node', 'GISNodes' 'C:/Badger/MyMap.gdb')
Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be XML
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ImportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the destination table, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)

Note that when importing a RTK Hydrograph table, the destination table must be specifed as UnitHydrograph not RTKHydrograph
feature	String		the feature class to import from
file	String		the absolute filepath to the import file, including extension e.g. "C:/Temp/Badger.gdb"
Data Import for FILEGDB (File GeoDatabase)
#odic_import_ex(format, config, options, table, feature, file) ⇒ void
Imports data from a GeoDatabase.

Examples

network.odic_import_ex('GDB', 'C:/Badger/Config.cfg', nil, 'Node', 'GISNodes' 'C:/Badger/MyMap.gdb')
Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be XML
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ImportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the destination table, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)
feature	String		the feature class to import from
file	String		the absolute filepath to the import file, including extension e.g. "C:/Temp/Badger.gdb"
Data Import for ORACLE (Oracle Database)
#odic_import_ex(format, config, options, table, source, connection, owner, username, password) ⇒ void
Imports data from an Oracle database.

Examples

network.odic_import_ex('ORACLE', 'C:/Badger/Config.cfg', nil, 'Node', 'MyNodes',
  'localhost/orcl', nil, 'username', 'badger1234')
Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be XML
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ImportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the destination table, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)

Note that when importing a RTK Hydrograph table, the destination table must be specifed as UnitHydrograph not RTKHydrograph
source	String		the source table in the Oracle database
connection	String		the connection string, e.g. //power/orcl
owner	String		the owner of the table being imported from
username	String		username
password	String		password
Data Import for SQLSERVER (Microsoft SQL Server)
#odic_import_ex(format, config, options, table, source, server, instance, database, trusted, username, password) ⇒ void
Imports data from a Microsoft SQL Server database. Other SQL database types such as PostGIS are not supported.

Examples

network.odic_import_ex('SQLSERVER', 'C:/Badger/Config.cfg', nil, 'Node', 'MyNodes',
  'localhost//SQLEXPRESS', nil, 'dbo.MyDatabase', nil, 'username', 'badger1234')
Parameters

Name	Type(s)	Default	Description
format	String		the data format, which should be SQLSERVER
config	String		the absolute filepath to the field config file exported from the user interface e.g. "C:/Temp/ImportFields.cfg"
options	Hash, nil		hash of options, or nil to use defaults
table	String		the destination table, as displayed in the UI with any spaces removed (e.g. CCTV Survey becomes CCTVSurvey)

Note that when importing a RTK Hydrograph table, the destination table must be specifed as UnitHydrograph not RTKHydrograph
source	String		the source table in the SQL Server database
server	String		the server address, e.g. localhost//SQLEXPRESS
instance	String, nil		the SQL server instance name, or nil
database	String		the name of the database
trusted	Boolean		use trusted connection / integrated security
username	String, nil		username, or nil if using a trusted connection
password	String, nil		password, or nil if using a trusted connection
remove_local
#remove_local ⇒ void
EXCHANGE

Removes any local working copy of this network. This can be used to free space in the user/script's working directory.
WSCommit
A single commit to a WSModelObject using merge version control.

The methods of this class are read only, and return the value in one of the fields that appears in the commit grid.

Methods:

branch_id
comment
commit_id
date
deleted_count
inserted_count
modified_count
setting_changed_count
user
branch_id
#branch_id ⇒ Integer
EXCHANGE

Returns the branch ID.

comment
#comment ⇒ String
EXCHANGE

Returns any comment associated with this commit. Comments are optional, so this may be an empty string.

commit_id
#commit_id ⇒ Integer
EXCHANGE

Returns the commit ID.

date
#date ⇒ DateTime
EXCHANGE

Returns the date.

deleted_count
#deleted_count ⇒ Integer
EXCHANGE

Returns the number of objects that were deleted.

inserted_count
#inserted_count ⇒ Integer
EXCHANGE

Returns the number of objects that were inserted.

modified_count
#modified_count ⇒ Integer
EXCHANGE

Returns the number of objects that were modified.

setting_changed_count
#setting_changed_count ⇒ Integer
EXCHANGE

Returns the number of settings that were changed.

Note: 'setting' is not plural.
user
#user ⇒ String
EXCHANGE

Returns the username associated with this commit.

WSCommits
A collection of WSCommit objects, representing the commit history of a WSModelObject using merge version control.

Methods:

[] (Get Index)
each
length
[] (Get Index)
#[(index)] ⇒ WSCommit?
EXCHANGE

Returns the WSCommit from the collection at the specified index.

Parameters

Name	Type(s)	Description
index	Integer	The index requested (zero-based).
Return	WSCommit, nil	The wscommit found, or nil if there is no object at this index.
each
#each { |c| ... } ⇒ WSCommit
EXCHANGE

Iterates through the collection, yielding a WSCommit.

commits.each { |c| puts c.branch_id }
commits.each.each do |c|
  puts "#{c.branch_id} - User '#{c.user}' changed #{c.modified_count} objects!"
end
length
#length ⇒ Integer
EXCHANGE

Returns the length of this collection i.e. how many WSCommits it contains.

Parameters

Name	Type(s)	Description
Return	Integer

WSDatabase
A database, including cloud databases and transportable databases.

The majority of these methods are only available in Exchange, there is only limited functionality in the UI. A database can be accessed from WSApplication.open (with Exchange) or WSApplication.current_database (with UI).

Methods:

copy_into_root
file_root
find_root_model_object
guid
list_read_write_run_fields
model_object
model_object_collection
model_object_from_type_and_guid
model_object_from_type_and_id
new_model_object
new_network_name
path
result_root
root_model_objects
copy_into_root
#copy_into_root(object, copy_results, copy_ground_models) ⇒ WSModelObject
EXCHANGE

Copies a WSModelObject and any children into the database root, returning the new model object. The model object being copied could be from the same database, or another database such as a transportable database.

Parameters

Name	Type(s)	Description
object	WSModelObject	The model object to copy.
copy_results	Boolean	Whether to copy simulation results, if the model object (or it's children) have simulations with results.
copy_ground_models	Boolean	Whether to copy ground models.
Return	WSModelObject	The newly copied object in this database.
file_root
#file_root ⇒ String
EXCHANGE, UI

Returns the path used by this database for files such as GIS layers, also known as the Remote Files Root.

This is the path shown in the UI under File > Database Settings > Set Remote Roots > Remote Files Root.

If this is a standalone database, and "force all remote roots to be below the database" is enabled, then the path will be the folder containing the database.

find_root_model_object
#find_root_model_object(type, name) ⇒ WSModelObject?
EXCHANGE, UI

Returns the WSModelObject at the root (top level) of the database. Model objects at this level will have unique names.

The valid types at this level are Asset Group, Model Group, and Master Group.

Parameters

Name	Type(s)	Description
type	String	The scripting type of the object.
name	String	The name of the object (case sensitive).
Return	WSModelObject, nil	The object if found, nil otherwise.
guid
#guid ⇒ String
EXCHANGE, UI

Returns the GUID for the database, which is also called the database identifier in the user interface.

puts database.guid
=> 'CEB7E8B9-D383-485C-B085-19F6E3E3C8CD'
Parameters

Name	Type(s)	Description
Return	String	
list_read_write_run_fields
#list_read_write_run_fields ⇒ Array
EXCHANGE, UI

Returns the field names in run objects that are read-write i.e. fields that can be set from Exchange scripts.

database.list_read_write_run_fields.each { |field| puts field }
Parameters

Name	Type(s)	Description
Return	Array	
model_object
#model_object(path) ⇒ WSModelObject?
EXCHANGE, UI

Finds a WSModelObject in the database using its scripting path.

network = database.model_object('>MODG~My Root Model Group')
raise "Could not find network" if network.nil?
Parameters

Name	Type(s)	Description
path	String	The scripting path to the object.
model_object_collection
#model_object_collection(type) ⇒ WSModelObjectCollection
EXCHANGE, UI

Finds all WSModelObjects in the database of a given type.

database.model_object_collection('Rainfall Event').each do |model_object|
  puts model_object.name
end
Parameters

Name	Type(s)	Description
type	String	The scripting type of the object.
Return	WSModelObjectCollection	The object(s) found, will be an empty collection if there are no objects of this type.
model_object_from_type_and_guid
#model_object_from_type_and_guid(type, guid) ⇒ WSModelObject?
EXCHANGE, UI

Finds a WSModelObject in the database using its scripting type and GUID. The GUID can be found in the user interface via the properties dialog.

rainfall = database.model_object_from_type_and_guid('Rainfall Event', '{CEB7E8B9-D383-485C-B085-19F6E3E3C8CD}')
raise "Could not find rainfall" if rainfall.nil?
Parameters

Name	Type(s)	Description
type	String	The scripting type of the object.
guid	String	The creation guid.
Return	WSModelObject, nil	The object if found, nil otherwise.
model_object_from_type_and_id
#model_object_from_type_and_id(type, id) ⇒ WSModelObject?
EXCHANGE, UI

Finds a WSModelObject in the database using its scripting type and ID. The ID can be found in the user interface via the properties dialog.

rainfall = database.model_object_from_type_and_id('Rainfall Event', 1)
raise "Could not find rainfall" if rainfall.nil?
Parameters

Name	Type(s)	Description
type	String	The scripting type of the object.
id	Integer	The model id.
Return	WSModelObject, nil	The object if found, nil otherwise.
new_model_object
#new_model_object(type, name) ⇒ WSModelObject
EXCHANGE

Creates a WSModelObject in the root of the database.

The valid object types at this level are Asset Group, Model Group, or Master Group.

Parameters

Name	Type(s)	Description
type	String	The scripting type of the object - must be a valid type for this level of the database.
name	String	The name of the new object, must be unique.
Exceptions

unrecognised type - if the object type is not valid
invalid object type for the root of a database - if the object type is valid, but not allowed for this level of the database (see method description)
an object of this type and name already exists in root of database - object names must be unique
licence and/or permissions do not permit creation of a child of this type in the root of the database - if the object cannot be created in the root of the database for licence and/or permission reasons (not applicable to some products / licenses)
unable to create object - if the creation fails for some other reason
new_network_name
#new_network_name(type, name, branch, add) ⇒ String
EXCHANGE, UI

Generates a new network (model object) name. This is intended to be used with an existing model object's name to generate a unique variant for a new network model object.

new_name = database.new_network_name('Model Network', 'Badger', false, false)
⇒ Badger#1
Parameters

Name	Type(s)	Description
type	String	The scripting type of the object.
name	String	The base name.
branch	Boolean	If true, the number increment will be an underscore e.g. mynetwork_1. if false, it will be a hash symbol e.g. mynetwork#1.
add	Boolean	If true, #1 or _1 will always be appended to the name, instead of incrementing the number.
Return	String	The new name.
path
#path ⇒ String
EXCHANGE, UI

Returns the path of the database.

This is the same path that would be used by WSApplication.open, for example:

Transportable database: 'C:/Badger/MyDatabase.icmt'
Standalone database: 'C:/Badger/MyDatabase.icmm'
Workgroup database: 'localhost:40000/Badger/MyDatabase'
Parameters

Name	Type(s)	Description
Return	String	
result_root
#result_root ⇒ String
EXCHANGE

Returns the path used by this database for results files when results are stored 'on server', also known as the Remote Results Root.

This is the path shown in the UI under File > Database Settings > Set Remote Roots > Remote Results Root.

If this is a standalone database, and "force all remote roots to be below the database" is enabled, then the path will be the folder containing the database.

root_model_objects
#root_model_objects ⇒ WSModelObjectCollection
EXCHANGE, UI

Finds all the objects at the root (top level) of the database.

WSFieldInfo
Metadata for a field in a network table. This only contains information about the table structure, not the current values for any particular object.

Methods:

data_type
description
fields
has_time_varying_results?
name
read_only?
size
data_type
#data_type ⇒ String
EXCHANGE, UI

Returns the data type of the field as a string. This is the InfoWorks type, not the Ruby type - which are shown below:

WS Type	Ruby Type
Flag	String
Boolean	Boolean
Single	Float
Double	Float
Short	Integer
Long	Integer
Date	DateTime
String	String
Array:Long	Array
Array:Double	Array
WSStructure	WSStructure
GUID	String
Note that Ruby does not have specific types for Single/Double floating point numbers, or Short/Long integers.

Parameters

Name	Type(s)	Description
Return	String	
description
#description ⇒ String
EXCHANGE, UI

Returns the field description, which is the name of the field that appears in the UI.

Parameters

Name	Type(s)	Description
Return	String	
fields
#fields ⇒ Array?
EXCHANGE, UI

Returns an array of fields, if the field is a structure blob i.e. it contains rows of structured data.

If the field is not a structure blob, it will return nil.

Parameters

Name	Type(s)	Description
Return	Array, nil	
has_time_varying_results?
#has_time_varying_results? ⇒ Boolean
EXCHANGE, UI

Returns if the field has time varying results, will always be false for network fields. See the WSTableInfo.results_fields method.

Parameters

Name	Type(s)	Description
Return	Boolean	
name
#name ⇒ String
EXCHANGE, UI

Returns the database name of the field i.e. the name which is used with Ruby methods.

Parameters

Name	Type(s)	Description
Return	String	
read_only?
#read_only? ⇒ Boolean
EXCHANGE, UI

Returns if the field is read only.

Parameters

Name	Type(s)	Description
Return	Boolean	
size
#size ⇒ Integer
EXCHANGE, UI

Returns the maximum length of a string field. Flag fields will always be length 4, any field which is not a string type will be 0.

Parameters

Name	Type(s)	Description
Return	Integer

WSLink
WSRowObject > WSLink

A link object i.e. a WSRowObject with a category type link.

Methods:

ds_node
us_node
ds_node
#ds_node ⇒ WSNode?
EXCHANGE, UI

Returns the link's downstream node, or nil if it doesn't have one.

us_node
#us_node ⇒ WSNode?
EXCHANGE, UI

Returns the link's upstream node, or nil if it doesn't have one.

WSModelObject
An object that exist in the database tree such as model groups, networks, selection lists, and stored queries.

Methods that return a WSModelObject may return a derived class, for example a WSNumbatNetworkObject for network types, or WSSimObject for simulations.

Methods:

!= (Does Not Equal)
== (Equals)
[] (Get Field)
[]= (Set Field)
bulk_delete
children
comment
comment= (Set)
compare
copy_here
csv_import_tvd
deletable?
delete
delete_results
export
find_child_model_object
id
import_all_sw_model_objects
import_data
import_grid_ground_model
import_infodrainage_object
import_new_model_object
import_new_model_object_from_generic_csv_files
import_new_sw_model_object
import_tvd
modified_by
name
name= (Set)
new_model_object
new_risk_analysis_run
new_run
new_synthetic_rainfall
open
parent_id
parent_type
path
type
update_to_latest
!= (Does Not Equal)
#!=(other_mo) ⇒ Boolean
EXCHANGE, UI

Checks if this model object is not the same as another model object (inequality check).

== (Equals)
#==(other_mo) ⇒ Boolean
EXCHANGE, UI

Checks if this model object is the same as another model object (equality check).

[] (Get Field)
#[(field)] ⇒ Any
EXCHANGE, UI

Returns the value of a field.

[]= (Set Field)
#[(field)]=(value) ⇒ void
EXCHANGE, UI

Sets the value of a field.

Parameters

Name	Type(s)	Description
field	String	Name of the field.
value	Any	Value to set, if this field references a database object the value can be the id, scripting path, or a wsmodelobject of the correct type.
bulk_delete
#bulk_delete ⇒ void
EXCHANGE, UI

Permanently deletes the object and all of its children, skipping the recycle bin.

This method works even if the object has children or is used in a simulation, which does not follow the user interface convention. For a safer version of this method, see #delete.

children
#children ⇒ WSModelObjectCollection
EXCHANGE, UI

Returns the children of the object.

Parameters

Name	Type(s)	Description
Return	WSModelObjectCollection	
comment
#comment ⇒ String
EXCHANGE

Returns the comment, a.k.a the description in the user interface.

Parameters

Name	Type(s)	Description
Return	String	
comment= (Set)
#comment=(text) ⇒ void
EXCHANGE

Sets the comment, a.k.a the description in the user interface.

Parameters

Name	Type(s)	Description
comment	String	The comment text.
compare
#compare(other) ⇒ Boolean
EXCHANGE

Compares this model object to another, both model objects must be the same type of version controlled object or simulation results.

Simulation results can only be compared if they are both from the current database.

if mo.compare(mo2) then
  puts 'Networks are the same!'
else
  puts 'Networks are not the same!'
end
Parameters

Name	Type(s)	Description
other	WSModelObject	The object to compare.
Return	Boolean	If the objects are identical.
copy_here
#copy_here(object, copy_sims, copy_ground_models) ⇒ WSModelObject
EXCHANGE, UI

Copies a model object and any children as a child of this object, returning the new model object. The model object being copied could be from the same database, or another database such as a transportable database.

Parameters

Name	Type(s)	Description
object	WSModelObject	The model object to copy.
copy_results	Boolean	Whether to copy simulation results, if the model object (or it's children) have simulations with results.
copy_ground_models	Boolean	Whether to copy ground models.
Return	WSModelObject	The newly copied object in this database.
csv_import_tvd
#csv_import_tvd(file, name, config_file) ⇒ Array
EXCHANGE

Performs an import of time varying data into an asset group, creating one or more 'time varying data' objects in the same manner as the user interface when the import time varying data from generic CSV option is used.

Parameters

Name	Type(s)	Description
file	String	Path to the file.
name	String	Root name of the new object.
config_file	String	Path to the config file, saved from the ui.
Return	Array	
deletable?
#deletable? ⇒ Boolean
EXCHANGE

Whether this model object can be deleted using the #delete method, which follows the user interface rules: has no children, and is not used in a simulation.

Parameters

Name	Type(s)	Description
Return	Boolean	
delete
#delete ⇒ void
EXCHANGE, UI

Deletes the object, provided it meets the user interface rules: has no children, and is not used in a simulation.

This is a safer alternative to the #bulk_delete method, which ignores these rules.

delete_results
#delete_results ⇒ void
EXCHANGE

Deletes the results, if this object is a simulation.

export
#export(path, format) ⇒ void
EXCHANGE

Exports the model object in the appropriate format.

The formats permitted depend on the object type. The format string may affect the actual data exported as well as the format in which the data is exported e.g. for rainfall events the parameter 'CRD' means that the Catchment Runoff Data is exported.

When the format is the empty string the data is exported in the InfoWorks text file format. This format may be used for:

Inflow
Level
Infiltration
Waste Water
Trade Waste
Rainfall Event (non-synthetic)
Pipe Sediment Data
Observed Flow Event
Observed Depth Event
Observed Velocity Event
Layer List ( this is a different file format but still termed the 'InfoWorks file' in the user interface).
Regulator (from 6.0)
For rainfall events the following parameters cause the export of other data in a text file format:

CRD - Catchment Runoff Data
CSD - Catchment Sediment Data
EVP - Evaporation
ISD - Initial Snow Data
TEM - Temperature Data
WND - Wind Data
For pollutant graphs the appropriate pollutant graph code causes the export of that pollutant's data in the text file format.

If the format is 'CSV' the file will be exported in 'InfoWorks CSV' format for the following object types:

Level
Infiltration
Inflow
Observed Flow
Observed Depth
Observed Velocity
Rainfall Event (synthetic - main rainfall data)
Regulator
Damage Function (from version 6.5)
Waste Water (from a version 7.5 patch)
Trade Waste (from a version 7.5 patch)
The results obtained by risk analysis runs may be exported as follows:

For Risk Analysis Results objects (known in ICM Exchange as Risk Calculation Results) the files may be exported by using the following in the format field:

"Receptor Damages"
"Component Damages"
"Code Damages"
"Impact Zone Damages"
"Category Damages"
"Inundation Depth Results"
For Risk Analysis Sim objects (known in ICM Exchange as Damage Calculation Results) the files may be exported by using the following in the format field:

"Receptor vs Code"
"Receptor vs Component"
"Code vs Component"
"Impact Zone vs Code"
"Impact Zone Code vs Component"
"Category Code vs Component"
For dashboards in InfoAsset Manager the format must be 'html', and the filename the name of the HTML file. Note in this case that other files are exported alongside the html file in the same folder. The names of these files are fixed for each individual dashboard object in the database so exporting the same dashboard object multiple times to different HTML files in the same folder will not give the intended results, you should instead export them to different folders.

Parameters

Name	Type(s)	Description
path	String	Path to the export file.
format	String	
find_child_model_object
#find_child_model_object(type, name) ⇒ WSModelObject?
EXCHANGE, UI

Finds a child model object of a given type and name.

Parameters

Name	Type(s)	Description
type	String	The type of the object.
name	String	The name of the object.
id
#id ⇒ Integer
EXCHANGE, UI

Returns the ID of this model object.

import_all_sw_model_objects
#import_all_sw_model_objects(file, format, scenario, logfile) ⇒ Array
EXCHANGE

Imports all SWMM model objects from a supported file. Object types imported:

SWMM Network
Inflow
IWSW Run
IWSW Time Patterns
Selection List
Level
Rainfall Event
IWSW pollutograph
IWSW Climatology
Regulator
This model object must be of a suitable type to contain the model objects imported.

Parameters

Name	Type(s)	Description
file	String	Path to the file for import.
format	String	Object format to import, can be inp for swmm5, xpx for xpswmm/xpstorm, or mxd for infoswmm.
scenario	String	Scenario name, only used when importing an mxd file.
logfile	String	Path to a log file, ending with a .txt extension.
Return	Array	
import_data
#import_data(format, file) ⇒ void
EXCHANGE

Imports data into this object.

This is only relevant for rainfall events and pollutographs, because they contain multiple pages of data which must be imported and exported separately. You have the choice of either:

Creating an empty object and importing all the data items using this method
Importing the first data item into a new object using #import_new_model_object and importing subsequent items into the object using this method - in the case of rainfall events the first item must be the rainfall, in the case of pollutographs is can be any item
Both InfoWorks CSV and InfoWorks file formats are supported. The parameter is 'CSV' for CSV files or some other string for the InfoWorks files.

For rainfall events the formats are SMD, EVP, SOL, WND, TEM, CSD, ISD, CRD and RED - for RED you can also put nil or ''. These are as documented in the main product documentation.

For pollutographs the format name is the pollutograph code.

CSV files import into the blob based on data in the CSV file.

For rainfall events the CSV files may only be used for the time varying data i.e Rainfall, Temperature, Wind, Evaporation, Solar Radiation and Soil Moisture Deficit.

mo_rain.import_data('CSV', 'C:/temp/MyRain_EVP.csv')
mo_rain.import_data('SMD', 'C:/temp/MyRain.smd')
mo_pollutograph.import_data('CSV', 'C:/temp/P.csv')
Parameters

Name	Type(s)	Description
format	String	File format.
file	String	Path to the file.
import_grid_ground_model
#import_grid_ground_model(polygon, files, options) ⇒ void
EXCHANGE

Imports a gridded ground model. This WSModelObject must be a model group or asset group.

The options hash contains the following options:

Key	Type	Default	Description
ground_model_name	String		Must be non-empty and unique in group
data_type	String		Displayed in the UI
cell_size	Float	1	Must be non-zero
unit_multiplier	Float	0.001	Must be non-zero
xy_unit_multiplier	Float	1	Must be non-zero
systematic_error	Float	0	
use_polygon	Boolean	false	Polygon is only used if this is true, if it is true the polygon must be non-nil
integer_format	Boolean	true	
model_group = database.model_object_from_type_and_id('Model Group', 2)
files = ['C:/temp/small_grid.asc']
options = {
  'ground_model_name' => 'my_ground_model',
  'data_type' => 'badger',
  'cell_size' => 5.0,
  'unit_multiplier' => 1.0,
  'xy_multiplier' => 1.0,
  'integer_format' => false,
  'use_polygon' => false
}
model_group.import_grid_ground_model(nil, files, options)
Parameters

Name	Type(s)	Description
polygon	WSRowObject, nil	An object with polygon geometry from a currently open WSOpenNetwork.
files	Array	Array of file paths.
options	Hash	See method description.
import_infodrainage_object
#import_infodrainage_object(file, type, log) ⇒ WSModelObject
EXCHANGE

Imports an InfoDrainage object. This WSModelObject must be a model group.

Parameters

Name	Type(s)	Description
file	String	Path to the infodrainagae file to import, with .idxx extension.
type	String	Type of object to import, the only accepted value is inflow.
log	String	Path to save the import log.
Return	WSModelObject	
import_new_model_object
#import_new_model_object(type, name, format, file, event) ⇒ WSModelObject
EXCHANGE

Imports a new model object from a file, as a child of this WSModelObject. This must be a suitable type to contain the new model object.

Permitted types are:

Inflow
Level
Ground Infiltration
Waste Water
Trade Waste
Rainfall Event (non-synthetic)
Pipe Sediment Data
Observed Flow Event
Observed Depth Event
Observed Velocity Event
Layer List (this is a different file format but still termed the 'InfoWorks file' in the user interface)
Regulator
Damage Function
Pollutograph
Permitted formats are:

An empty string - for InfoWorks format files
CSV for InfoWorks format CSV files (not available for layer lists, or damage functions)
CSV for Pollutographs (the data imported will depend on the CSV file)
The 3 letter pollutograph code
You can only import one pollutant, if you wish to import more into the same InfoWorks object you can use the #import_data method. You can also use that method to import additional data into Rainfall Events.

rainfall = model_group.import_new_model_object('Rainfall Event', 'The Rainfall', '', 'C:/temp/1.red')
Parameters

Name	Type(s)	Description
type	String	See method description for list of supported types.
name	String	Name of the imported object.
format	String	See method description for list of supported formats.
file	String	Path to the file.
event	Integer	Optional from version 11.5, should be set to 0 if used.
Return	WSModelObject	
import_new_model_object_from_generic_csv_files
#import_new_model_object_from_generic_csv_files(type, name, file, config) ⇒ Array
EXCHANGE

Imports a new model object using the generic CSV importer, as a child of this WSModelObject. This must be a suitable type to contain the new model object.

It requires a config file previously set up in the UI.

Permitted types are:

Inflow
Level
Infiltration
Rainfall Event (non-synthetic)
Pipe Sediment Data
Observed Flow Event
Observed Depth Event
Observed Velocity Event
Regulator
The return value is an array with 2 elements. The first element is the WSModelObject created. The second element is either nil or a string of the warning message that would appear in the UI .

Parameters

Name	Type(s)	Description
type	String	See method description for list of supported types.
name	String	Used as a prefix for the event name (ignored for multiple rainfall events).
file	String, Array	A single file path, or an array of file paths which matches the ui behaviour of 'import multiple files into an event'.
config	String	Path to the config file.
Return	Array	
import_new_sw_model_object
#import_new_sw_model_object(type, format, file, scenario, log) ⇒ WSModelObject
EXCHANGE

Imports a new SWMM model object as a child of this WSModelObject. This must be a suitable type to contain the new model object.

Permitted types are:

Inflow
IWSW Run
IWSW Time Patterns
Selection List
Level
Rainfall Event
IWSW pollutograph
IWSW Climatology
Regulator
new_swmm = model_group.import_new_sw_model_object('Rainfall Event', 'INP', 'C:/temp/1.inp', '', 'C:/temp/log.txt')
Parameters

Name	Type(s)	Description
type	String	See method description for list of supported types.
format	String	Object format to import, can be inp for swmm5, xpx for xpswmm/xpstorm, or mxd for infoswmm.
file	String	Path to the file for import.
scenario	String	Scenario name, only used when importing an mxd file.
log	String	Path to a log file, ending with a .txt extension.
Return	WSModelObject	
import_tvd
#import_tvd(file, format, event) ⇒ void
EXCHANGE

Imports event data into an existing object.

If the format is 'CSV' this expects the 'InfoWorks CSV file' format, and imports this into an existing event, overwriting any data already there.

If the format is 'RED' and the type of the object is a rainfall event, this will import the data in event file format into an existing event, overwriting any data already there.

Parameters

Name	Type(s)	Description
file	String	Path to the file to be imported.
format	String	Either csv or red.
event	Integer	Must be present but is ignored.
modified_by
#modified_by ⇒ String
EXCHANGE, UI

Returns the username which last modified the object. This may be different from the latest commit of a version controlled network.

name
#name ⇒ String
EXCHANGE, UI

Returns the name of this object.

name= (Set)
#name=(new_name) ⇒ void
EXCHANGE, UI

Sets the name of this object.

Parameters

Name	Type(s)	Description
new_name	String	
new_model_object
#new_model_object(type, name) ⇒ WSModelObject
EXCHANGE, UI

Creates a new model object as a child of this object - the type must be valid for this object.

Scripts that are running in the user interface are unable to create most types of model objects, the only exceptions being Selection Lists and Selection List Groups. The full functionality of this method is only available in Exchange.

Runs cannot be created using this method, they are created using #new_run or #new_risk_analysis_run.

Parameters

Name	Type(s)	Description
type	String	Type of the new model object.
name	String	Name of the new model object.
Exceptions

unrecognised type - if the type is not a valid scripting type
sims cannot be created directly - if an attempt is made to create a sim
invalid child type for this object - if the new type may not be a child of this object type
name already in use - if the name is in use by another model object (that is also a child of this object), or globally if this is a version controlled type with a standalone database
licence and/or permissions do not permit creation of a child of this type for this object - if this type of object cannot be created for licensing and/or permissions reasons
unable to create object - if the call fails for some other reason
new_risk_analysis_run
#new_risk_analysis_run(name, damage_function, runs, param) ⇒ WSRiskAnalysisRunObject
EXCHANGE

Creates a new risk analysis run object.

Parameters

Name	Type(s)	Description
name	String	Name of the new object.
damage_function	Integer, String, WSModelObject	The damage function object - can be the id, scripting path, or a wsmodelobject of the correct type.
runs	Integer, Array, String, Array, WSModelObject, Array	The run object, or array of run objects - can be the id, scripting path, or a wsmodelobject of the correct type (all elements in the array must be the same type).
param	Numeric	The numerical parameter.
Return	WSRiskAnalysisRunObject	
new_run
#new_run(name, network, commit_id, rainfalls_and_flow_surveys, scenarios, options) => WSModelObject
EXCHANGE

Creates a new run. This WSModelObject must be a model group.

The method can take arrays as parameters for both the rainfalls and flow surveys and for the scenarios. In the same way that dropping multiple rainfall events and flow surveys into the drop target on the schedule run dialog and selecting multiple scenarios on it yield multiple simulations for a run, so calling this method with arrays of values and with synthetic rainfall events which have multiple parameters (singly or in an array) will yield multiple sims for the run.

The #run method which actually runs simulations is a method of the individual sim objects below the run, which can be accessed by using the #children method of the WSModelObject returned by this method.

The rainfalls_and_flow_surveys parameter can be:

nil - in this case the run will be a dry weather flow run
a WSModelObject which is a rainfall event or a flow survey
the scripting path of a rainfall event or a flow survey as a string
the ID of a rainfall event
a negative number equal to -1 times the ID of a flow survey e.g. -7 means the Flow Survey with ID 7.
An array. If the parameter is an array, then if the length of the array is 0 then the event will be a dry weather flow run, otherwise all the array elements must be one of 2 - 5 above. The array may not contain duplicates otherwise an exception will be thrown.
Parameters

Name	Type(s)	Description
name	String	The name of the new run, this must be unique within the model group.
network	Integer, String, WSModelObject	The network used for the run - can be the id, scripting path, or a wsmodelobject of the correct type.
commit_id	Integer, nil	The commit id to be used for the run, this can be the integer commit id, or nil in which case the latest commit is used.
rainfalls_and_flow_surveys	Multiple	See method description.
scenarios	String, Array, nil	Nil to use the base scenario, the name of the scenario, or an array f scenario names (which must not contain duplicates, or scenarios that do not exist).
options	Hash	A hash containing run options.
Exceptions

new_run : runs may only be created in model groups - the run must only be created in a model group
new_run : name already in use - if the run name is already in use
new_synthetic_rainfall
#new_synthetic_rainfall(name , type, params) ⇒ void
EXCHANGE

Creates a new synthetic rainfall model object as a child of this WSModelObject. Permitted generator types are:

UKRain
FEHRain
ReFHRain
GermanRain
HKRain
HK5thEdRain
AUSRain
FRQRain
FRRain
MYRain
MY2015Rain
USRain
ChineseRain
ChicagoRain
The params hash contains the following.

Key	Type	Default	Description
Location	Integer		UKRain
Profile	Integer		UKRain
WetnessIndex	Integer		UKRain
Series	Integer		UKRain
5yr1hr	Float		UKRain
RainfallRatio	Float		UKRain
API30	Float		UKRain
SMS	Float		UKRain
SMD	Float		UKRain
Cini	Float		UKRain
BF0	Float		UKRain
Evaporation	Float		UKRain
CatchmentArea	Float		UKRain
Profile	Integer		FEHRain, ReFHRain, GermanRain
WetnessIndex	Integer		FEHRain, ReFHRain, GermanRain
ReturnPeriodType	Integer		FEHRain, ReFHRain, GermanRain
ReturnPeriod	Float		FEHRain, ReFHRain, GermanRain
Duration	Float		FEHRain, ReFHRain, GermanRain
Antecedentdepth	Float		FEHRain, ReFHRain, GermanRain
UCWI	Float		FEHRain, ReFHRain, GermanRain
API30	Float		FEHRain, ReFHRain, GermanRain
SMS	Float		FEHRain, ReFHRain, GermanRain
SMD	Float		FEHRain, ReFHRain, GermanRain
Cini	Float		FEHRain, ReFHRain, GermanRain
BF0	Float		FEHRain, ReFHRain, GermanRain
Evaporation	Float		FEHRain, ReFHRain, GermanRain
WetnessIndex	Integer		HKRain, HK5thEdRain
Method	Integer		HKRain, HK5thEdRain
ReturnPeriod	Float		HKRain, HK5thEdRain
Duration	Float		HKRain, HK5thEdRain
Antecedentdepth	Float		HKRain, HK5thEdRain
UCWI	Float		HKRain, HK5thEdRain
API30	Float		HKRain, HK5thEdRain
SMS	Float		HKRain, HK5thEdRain
SMD	Float		HKRain, HK5thEdRain
Cini	Float		HKRain, HK5thEdRain
BF0	Float		HKRain, HK5thEdRain
Evaporation	Float		HKRain, HK5thEdRain
A	Float		HKRain, HK5thEdRain
B	Float		HKRain, HK5thEdRain
C	Float		HKRain, HK5thEdRain
WetnessIndex	Integer		AUSRain
Zone	Float		AUSRain
2 yr 1 hour	Float		AUSRain
2 yr 12 hour	Float		AUSRain
2 yr 72 hour	Float		AUSRain
50 yr 1 hour	Float		AUSRain
50 yr 12 hour	Float		AUSRain
50 yr 72 hour	Float		AUSRain
2 yr 6 minutes	Float		AUSRain
50 yr 6 minutes	Float		AUSRain
Coefficient	Float		AUSRain
UCWI	Float		AUSRain
API30	Float		AUSRain
SMS	Float		AUSRain
SMD	Float		AUSRain
Cini	Float		AUSRain
BF0	Float		AUSRain
Evaporation	Float		AUSRain
Antecedentdepth	Float		AUSRain
Enable Lan / Long	Float		AUSRain
Latitude	Float		AUSRain
Longitude	Float		AUSRain
ARI	Float		AUSRain
Duration	Float		AUSRain
Multiplying Factor	Float		AUSRain
WetnessIndex	Integer		FRRain
Location	Integer		FRRain
ReturnPeriod	Float		FRRain
PeakDuration	Float		FRRain
Antecedentdepth	Float		FRRain
UCWI	Float		FRRain
API30	Float		FRRain
SMS	Float		FRRain
SMD	Float		FRRain
Cini	Float		FRRain
BF0	Float		FRRain
Evaporation	Float		FRRain
PeakPosition	Float		FRRain
A	Float		FRRain
B	Float		FRRain
Profile	Integer		FRQRain
WetnessIndex	Integer		FRQRain
Antecedentdepth	Float		FRQRain
UCWI	Float		FRQRain
API30	Float		FRQRain
SMS	Float		FRQRain
SMD	Float		FRQRain
Cini	Float		FRQRain
BF0	Float		FRQRain
Evaporation	Float		FRQRain
PeakPosition	Float		FRQRain
PeakDuration	Float		FRQRain
Intensity	Float		FRQRain
PeakRainfall	Float		FRQRain
StormRainfall	Float		FRQRain
Timestep	Float		FRQRain
Duration	Float		FRQRain
StartTime	Float		FRQRain
EndTime	Float		FRQRain
WetnessIndex	Integer		MYRain, MY2015Rain
Location	Integer		MYRain, MY2015Rain
ReturnPeriod	Float		MYRain, MY2015Rain
Duration	Float		MYRain, MY2015Rain
Antecedentdepth	Float		MYRain, MY2015Rain
UCWI	Float		MYRain, MY2015Rain
API30	Float		MYRain, MY2015Rain
SMS	Float		MYRain, MY2015Rain
SMD	Float		MYRain, MY2015Rain
Cini	Float		MYRain, MY2015Rain
BF0	Float		MYRain, MY2015Rain
Evaporation	Float		MYRain, MY2015Rain
A	Float		MYRain, MY2015Rain
B	Float		MYRain, MY2015Rain
C	Float		MYRain, MY2015Rain
D	Float		MYRain, MY2015Rain
CatchmentArea	Float		MYRain, MY2015Rain
2P24hr	Float		MYRain
WetnessIndex	Integer		USRain
SCSInPat	Integer		USRain
SCSDur	Integer		USRain
Antecedentdepth	Float		USRain
UCWI	Float		USRain
API30	Float		USRain
SMS	Float		USRain
SMD	Float		USRain
Cini	Float		USRain
BF0	Float		USRain
Evaporation	Float		USRain
SCS24Rain	Float		USRain
SCSTS	Float		USRain
CalculationOfA	Integer		ChineseRain
ReturnPeriod	Float		ChineseRain
Duration	Float		ChineseRain
PeakTimeRatio	Float		ChineseRain
BigA	Float		ChineseRain
SmlA	Float		ChineseRain
SmlB	Float		ChineseRain
C	Float		ChineseRain
SmlN	Float		ChineseRain
Timestep	Float		ChineseRain
ReturnPeriod	Float		ChicagoRain
Duration	Float		ChicagoRain
PeakTimeRatio	Float		ChicagoRain
A	Float		ChicagoRain
B	Float		ChicagoRain
C	Float		ChicagoRain
Timestep	Float		ChicagoRain
Parameters

Name	Type(s)	Description
name	String	Name of the new model object.
type	String	Generator type of the new rainfall model object.
params	Hash	A hash containing rainfall parameters.
Exceptions

synthetic rainfall events may only be created in model groups : the rainfall event must be created in a model group.
name already in use : if the rainfall event name is already in use.
rainfall type XXXX cannot be created by scripting : input type one of the following FEH2013, FEH2022, AUS2016Rain, NOAARain which cannot be created using scripting since they need external software.
rainfall type XXXX not found : input type not valid.
parameter 3 is not a Hash : input params is not a valid hash.
unable to load DLL : problem loading rainfall generator software.
open
#open ⇒ WSModelObject
EXCHANGE, UI

Only available for model objects of a network type or sim.

Opens the network and returns a WSOpenNetwork object. When this method is called on a sim, the network and results are opened. An exception will be thrown if the simulation did not succeed or the results are inaccessible.

Note that when you open the results of a simulation:

The network is opened as read only
The current scenario is set to the scenario used for the simulation
The current scenario cannot be changed
As with the behaviour in the UI of the software, the network with the results loaded has a current timestep. The results start by being opened at the first timestep (timestep 0) unless there are only maximum results in which case they are opened as the maximum results timestep.
Parameters

Name	Type(s)	Description
Return	WSModelObject	
parent_id
#parent_id ⇒ Integer
EXCHANGE, UI

Returns the ID of this object's parent. This will be 0 if the object is in the root of the database.

parent_type
#parent_type ⇒ String
EXCHANGE, UI

Returns the type of this object's parent. This will be 'Master Database' if the object is in the root of the database.

path
#path ⇒ String
EXCHANGE, UI

Returns the scripting path of this object.

type
#type ⇒ String
EXCHANGE, UI

Returns the type of this model object.

update_to_latest
#update_to_latest ⇒ void
EXCHANGE

Updates a run model object, equivalent to the 'update to latest version of network' button in the run view of the user interface. The following conditions apply:

The 'Working' field must be set to true
There must be no uncommitted changes for the network used in the run
All scenarios that were included in the scenarios list must be present and validated

WSModelObjectCollection
A collection of WSModelObject objects (including derived classes).

Methods:

[] (Get Index)
each
length
[] (Get Index)
#[(index)] ⇒ WSModelObject?
EXCHANGE, UI

Returns the object from the collection at the specified index.

Parameters

Name	Type(s)	Description
index	Integer	The index requested (zero-based).
Return	WSModelObject, nil	The object found, or nil if there is no object at this index.
each
#each { |mo| ... } ⇒ WSModelObject
EXCHANGE, UI

Iterates through the collection, yielding a WSModelObject.

For example, using WSDatabase.model_object_collection:

database.model_object_collection('Geometry').each { |mo| puts mo.name }
database.model_object_collection('Geometry').each do |mo|
  puts mo.name
end
Parameters

Name	Type(s)	Description
Return	WSModelObject	
length
#length ⇒ Integer
EXCHANGE, UI

Returns the number of objects in this collection.

Parameters

Name	Type(s)	Description
Return	Integer	
Was this information helpful?YesNo

WSNode
WSRowObject > WSNode

A node object.

Methods:

ds_links
us_links
ds_links
#ds_links ⇒ WSRowObjectCollection
EXCHANGE, UI

Returns a collection of the node's downstream links, if there are no downstream links the collection will be empty.

Parameters

Name	Type(s)	Description
Return	WSRowObjectCollection	
us_links
#us_links ⇒ WSRowObjectCollection
EXCHANGE, UI

Returns a collection of the node's upstream links, if there are no upstream links the collection will be empty.

Parameters

Name	Type(s)	Description
Return	WSRowObjectCollection

WSNumbatNetworkObject
WSModelObject > WSBaseNetworkObject > WSNumbatNetworkObject

A network using merge version control.

Note: a network in this context is not the same as a 'network' in the user interface.
Methods:

branch
commit
commit_reserve
commits
csv_changes
current_commit_id
gis_export
latest_commit_id
list_gis_export_tables
open
open_version
reserve
revert
select_changes
select_clear
select_count
select_sql
uncommitted_changes?
unreserve
update
user_field_names
branch
#branch(commit_id, new_name) ⇒ WSModelObject
EXCHANGE

Branches the network object, creating a new network object.

Parameters

Name	Type(s)	Description
commit_id	Integer	The branch is performed from this commit id.
new_name	String	The new network name.
Return	WSModelObject	
commit
#commit(comment) ⇒ Integer
EXCHANGE

Commits any changes to the network to the database. Returns the commit ID, or returns nil if there were no changes made and therefore no new commit.

network.commit('This is the comment for my commit')
Parameters

Name	Type(s)	Description
comment	String	
Return	Integer	
commit_reserve
#commit_reserve(comment) ⇒ Integer
EXCHANGE

Performs the same action as commit, but keeps the network reserved if it was already.

Parameters

Name	Type(s)	Description
comment	String	
Return	Integer	
commits
#commits ⇒ WSCommits
EXCHANGE

Returns the commit history for the network.

Example of printing the number of commits:

commits = network.commits
puts "There have been #{commits.length} commits to this network!"
Example of printing all comments from user 'Badger':

network.commits.each do |commit|
  puts \"#{commit.commit_id}: #{commit.comment}\" if commit.user == 'Badger'
end
Parameters

Name	Type(s)	Description
Return	WSCommits	
csv_changes
#csv_changes(commit_id_1, commit_id_2, file) ⇒ void
EXCHANGE

Outputs the differences between commit_id_1 and commit_id_2 of this network to the specified CSV file. The CSV file output is the same as the 'compare network' tool in the user interface, and can be used to apply the changes to another network via the 'Import/Update from CSV files' function.

Parameters

Name	Type(s)	Description
commit_id_1	Integer	
commit_id_2	Integer	
file	String	Path to the csv file, including extension.
current_commit_id
#current_commit_id ⇒ Integer
EXCHANGE

Returns the commit ID of the local copy of the network. This may not be the most recent commit ID on the server, which is returned by #latest_commit_id.

Parameters

Name	Type(s)	Description
Return	Integer	
gis_export
#gis_export(format, options, destination) ⇒ void
EXCHANGE

Exports the network data to a GIS format.

The options hash contains the following keys. If the options parameter is nil or where the provided hash is missing a key, the default behavior applies.

Key	Data Type	Description
ExportFlags	Boolean	If true field flags are exported along with the data - default is true
Feature Dataset	String	Only relevant for GeoDatabases - the name of the feature dataset, the default is an empty string
SkipEmptyTables	Boolean	If true, will skip empty tables - default is false
Tables	Array	Table names which can be returned by the #list_gis_export_tables method, does not allow duplicates or unrecognized tables - by default, will export all tables
UseArcGISCompatability	Boolean	Default is false
Note: This method previously included capitalization, we recommend using the new lower case method name.
Parameters

Name	Type(s)	Description
format	String	Either shp (esri shapefile), tab (mapinfo tab), mif (mapinfo mif), or gdb (esri geodatabase).
options	Hash, nil	See hash options in method description.
destination	String	The folder for the files to be exported, except for a geodatabase, where it is the name of the geodatabase file with .gdb extension.
latest_commit_id
#latest_commit_id ⇒ Integer
EXCHANGE

Returns the latest commit ID for the network from the server. This may not be the same commit ID as the local copy, which is returned by #current_commit_id.

Parameters

Name	Type(s)	Description
Return	Integer	
list_gis_export_tables
#list_gis_export_tables ⇒ Array
EXCHANGE

Returns the tables that will be exported using the #gis_export method.

Note: This method previously included capitalization, we recommend using the new lower case method name.
Parameters

Name	Type(s)	Description
Return	Array	
open
#open ⇒ WSOpenNetwork
EXCHANGE

Opens the latest version of the network.

Parameters

Name	Type(s)	Description
Return	WSOpenNetwork	
open_version
#open_version(commit_id) ⇒ WSOpenNetwork
EXCHANGE

Opens a specific version of the network, from it's commit ID.

Parameters

Name	Type(s)	Description
Return	WSOpenNetwork	
reserve
#reserve ⇒ void
EXCHANGE

Reserves the network so no-one else can edit it, and also updates the local copy to the latest version.

revert
#revert ⇒ void
EXCHANGE

Reverts any changes to the network that have not yet been committed. This does not guarantee that the network is up to date, only that any changes made to the local copy have been abandoned.

select_changes
#select_changes(commit_id) ⇒ void
EXCHANGE

Select all objects added or changed between the provided commit ID, and the current network.

Deleted objects cannot be selected. The network must have no outstanding changes, or an exception will be raised.

select_clear
#select_clear ⇒ void
EXCHANGE

Deselects all objects in the network.

select_count
#select_count ⇒ Integer
EXCHANGE

Returns the number of selected objects in the network.

Parameters

Name	Type(s)	Description
Return	Integer	
select_sql
#select_sql(table, query) ⇒ Integer
EXCHANGE

Runs a SQL select query. A SQL query can further qualify the table name in the query, or work with multiple tables.

The SQL query can include multiple clauses, including saving results to a file, but cannot use any of the options that open results or prompt grids.

Example of selecting all nodes in the network, above 40m elevation:

count = network.select_sql('_nodes', 'z > 40')
puts format("There are %i nodes above 40m in this network!", count)
Example of selecting node ID's into a file:

network.select_sql('hw_node', "SELECT oid INTO FILE 'C:\Export\Distinct.csv'")
Parameters

Name	Type(s)	Description
table	String	The table name, _nodes or _links are equivalent to 'all nodes' and 'all links' in sql.
query	String	The sql query.
Return	Integer	The number of objects selected in the last clause, or 0.
uncommitted_changes?
#uncommitted_changes? ⇒ Boolean
EXCHANGE

Returns if there are uncommitted changes to the network.

Parameters

Name	Type(s)	Description
Return	Boolean	
unreserve
#reserve ⇒ void
EXCHANGE

Cancels any reservation of the network.

update
#update ⇒ Boolean
EXCHANGE

Updates the local copy of the network to the latest version from the server. Not relevant for Standalone databases.

Parameters

Name	Type(s)	Description
Return	Boolean	True if this was successful, false if there are conflicts.
user_field_names
#user_field_names(file, string) ⇒ void
EXCHANGE

Exports a CSV file containing the user field names for all object types in the network, which will include any network or database customisations.

The CSV file has no header. The first column is the provided string, the second column is the internal user field table name, and the third column is the user field name as shown in the user interface including customisations.

network.user_field_names('C:/Temp/Badger.csv', 'x')
Produces:

x, user_text_1, Badger
x, user_text_2, Penguin
Parameters

Name	Type(s)	Description
file	String	The file to export, including extension (.csv).
string	String	An arbitrary string value, which will be output as the first column.

WSOpenNetwork
An open network. An open network allows access to the network contents, similar to opening the network as a grid or GeoPlan in the UI.

Note: a network in this context is not the same as a 'network' in the user interface.
Methods:

add_scenario
cancel_mesh_job
clear_selection
csv_export
csv_import
current_scenario
current_scenario= (Set)
current_timestep
current_timestep= (Set)
current_timestep_time
delete_scenario
delete_selection
download_mesh_job_log
each
each_selected
export_ids
field_names
gauge_timestep_count
gauge_timestep_time
gis_export
infodrainage_import
list_gauge_timesteps
list_gis_export_tables
list_timesteps
load_mesh_job
load_selection
mesh
mesh_async
mesh_job_status
model_object
mscc_export_cctv_surveys
mscc_export_manhole_surveys
mscc_import_cctv_surveys
mscc_import_manhole_surveys
network_model_object
new_row_object
objects_in_polygon
odec_export_ex
odic_import_ex
ribx_export_surveys
ribx_import_surveys
row_object
row_object_collection
row_object_collection_selection
row_objects
row_objects_from_asset_id
row_objects_selection
run_sql
run_inference
run_stored_query_object
save_selection
scenarios
search_at_point
selection_size
set_projection_string
snapshot_export
snapshot_export_ex
snapshot_import_ex
snapshot_scan
table
table_names
tables
timestep_count
timestep_time
transaction_begin
transaction_commit
transaction_rollback
update_cctv_scores
xprafts_import
add_scenario
#add_scenario(name, based_on, notes) ⇒ void
EXCHANGE, UI

Adds a new scenario to the network.

network.add_scenario('MyNewScenario', nil, 'Some notes...')
Parameters

Name	Type(s)	Description
name	String	Name of the new scenario.
based_on	String, nil	The name of the scenario to use as a base, if any.
notes	String	Notes or description for this scenario.
cancel_mesh_job
#cancel_mesh_job(job_id) ⇒ void
EXCHANGE

Cancels a mesh job.

Parameters

Name	Type(s)	Description
job_id	Integer	The job id from the #mesh_async method.
clear_selection
#clear_selection ⇒ void
EXCHANGE, UI

Clears the current selection, i.e. any WSRowObjects that are currently selected will be deselected.

csv_export
#csv_export(filename, options) ⇒ void
EXCHANGE, UI

Exports data to CSV.

See WSBaseNetworkObject.csv_export.

csv_import
#csv_import(filename, options) ⇒ void
EXCHANGE, UI

Imports data from CSV.

See WSBaseNetworkObject.csv_import.

current_scenario
#current_scenario ⇒ String
EXCHANGE, UI

Returns the current scenario of the network. If the current scenario is the base scenario, returns the string Base (in English).

Parameters

Name	Type(s)	Description
Return	String	
current_scenario= (Set)
#current_scenario=(name) ⇒ void
EXCHANGE, UI

Sets the current scenario of the network. The scenario must exist.

Parameters

Name	Type(s)	Description
name	String, nil	The name of the scenario, if nil then the scenario is set to the base scenario.
current_timestep
#current_timestep ⇒ Integer
EXCHANGE, UI

The WSOpenNetwork object has a current timestep corresponding to the current timestep results have when opened in the software's UI. It determines the timestep for which the 'result' method of the WSRowObject returns its value. This method returns the index of the current timestep, with the first timestep being index 0 and the final timestep begin timestep_count - 1. The value of -1, representing the 'maximum' 'timestep' is also possible. The initial value when a sim is opened in ICM Exchange will be 0 if there are time varying results, otherwise -1 for the 'maximum' 'timestep'.

puts network.current_timestep_time
=> 0
Parameters

Name	Type(s)	Description
Return	Integer	
current_timestep= (Set)
#current_timestep=(index) ⇒ void
EXCHANGE

Sets the current network timestep.

Parameters

Name	Type(s)	Description
index	Integer	The timestep index, 0 sets the current timestep to the first timestep, -1 returns the maximum timestep.
current_timestep_time
#current_timestep_time ⇒ DateTime
EXCHANGE, UI

Returns the actual time of the current timestep.

puts network.current_timestep_time
=> ?
Parameters

Name	Type(s)	Description
Return	DateTime	
delete_scenario
#delete_scenario(name) ⇒ void
EXCHANGE, UI

Deletes a named scenario from the network. If the deleted scenario is the current scenario, the network will switch to the base scenario.

puts network.current_scenario
=> 'ScenarioBadger'

network.delete_scenario('ScenarioBadger')

puts network.current_scenario
=> 'Base'
Parameters

Name	Type(s)	Description
name	String	The name of the scenario to delete.
delete_selection
#delete_selection ⇒ void
EXCHANGE, UI

Deletes the currently selected objects from the network, in the current scenario.

download_mesh_job_log
#download_mesh_job_log(job_id, path) ⇒ void
EXCHANGE

Copies the log output from a #mesh_async job to a new file.

Parameters

Name	Type(s)	Description
job_id	Integer	The job id from the #mesh_async method.
path	String	Path to the new file, including extension (.txt).
each
#each { |ro| ... } ⇒ WSRowObject
EXCHANGE, UI

Iterates through each object in the network.

Parameters

Name	Type(s)	Description
Return	WSRowObject	
each_selected
#each_selected { |ro| ... } ⇒ WSRowObject
EXCHANGE, UI

Iterates through each selected object in the network.

Parameters

Name	Type(s)	Description
Return	WSRowObject	
export_ids
#export_ids(filename, options) ⇒ void
EXCHANGE, UI

Exports the IDs of WSRowObjects to a file, grouped by table.

The options hash has the following keys:

Key	Type	Default	Description
Selection Only	Boolean	false	If true, only the currently selected WSRowObjects will be exported
UTF8	Boolean	false	If true will save the file with UTF8 encoding, otherwise will use current locale
Note: This method previously included capitalization, we recommend using the new lower case method name.
Parameters

Name	Type(s)	Description
filename	String	Path to the file, including extension (.txt).
options	Hash, nil	See description.
field_names
#field_names(table) ⇒ Array
EXCHANGE, UI

Returns the field names for a given table.

network.field_names('wn_node').each { |s| puts s }
Parameters

Name	Type(s)	Description
table	String	The name of the table (type) of wsrowobject.
Return	Array	
gauge_timestep_count
#gauge_timestep_count ⇒ Integer
EXCHANGE, UI

Returns the number of gauge timesteps.

Parameters

Name	Type(s)	Description
Return	Integer	The number of gauge timesteps, if there are no gauge timesteps (e.g. no objects are gauged, or the gauge timestep multiplier is 0) this will be 0.
gauge_timestep_time
#gauge_timestep_time(index) ⇒ DateTime
EXCHANGE, UI

Returns the actual time of the timestep.

puts network.gauge_timestep_time(0)
=> ?
Parameters

Name	Type(s)	Description
index	Integer	The gauge timestep index.
Return	DateTime	
gis_export
#gis_export(format, options, location) ⇒ void
EXCHANGE, UI

Exports the network data to GIS format. See the WSNumbatNetworkObject.gis_export method.

Note: This method previously included capitalization, we recommend using the new lower case method name.
infodrainage_import
#infodrainage_import(filename, log) ⇒ void
EXCHANGE

Imports an InfoDrainage model into the network.

Note: This method previously included capitalization, we recommend using the new lower case method name.
Parameters

Name	Type(s)	Description
filename	String	Filepath to the infodrainage file including extension .iddx.
log	String	Filepath to save the import log including extension .txt, which will be in rich text format.
list_gauge_timesteps
#list_gauge_timesteps ⇒ Array
EXCHANGE, UI

Returns the times of all gauge timesteps, in order.

Parameters

Name	Type(s)	Description
Return	Array	
list_gis_export_tables
#list_gis_export_tables ⇒ Array
EXCHANGE

Returns the tables that can be exported using the #gis_export method.

Note: This method previously included capitalization, we recommend using the new lower case method name.
Parameters

Name	Type(s)	Description
Return	Array	
list_timesteps
#list_timesteps ⇒ Array
EXCHANGE, UI

Returns the times of all timesteps, in order.

Parameters

Name	Type(s)	Description
Return	Array	
load_mesh_job
#load_mesh_job(job_id) ⇒ void
EXCHANGE

Loads the the completed mesh from a #mesh_async job into the network.

Parameters

Name	Type(s)	Description
job_id	Integer	The job id from the #mesh_async method.
load_selection
#load_selection(selection_list) ⇒ void
EXCHANGE, UI

Selects objects in the network from the selection list object.

Parameters

Name	Type(s)	Description
selection_list	Integer, String, WSModelObject	The selection list - can be the id, scripting path, or a wsmodelobject of the correct type.
mesh
#mesh(options) ⇒ Hash
EXCHANGE

Meshes one or more 2D zones. This method performs meshing synchronously i.e. it blocks the script thread. To perform meshing asynchronously, see the #mesh_async method.

The options hash contains the following keys:

Name	Type	Required	Description
GroundModel	Integer, String, WSModelObject	Yes	This may either be the scripting path, the ID, or the WSModelObject representing a ground model (either grid or TIN). If the ID is negative then it represents a TIN ground model i.e. -7 represents the TIN ground model with ID 7. If the ID is positive it represents a gridded ground model.
VoidsFile	String	No	The path of a GIS file containing the voids
VoidsFeatureClass	String	No	For a GeoDatabase, the feature class within the GeoDatabase for the voids
VoidsCategory	String	No	The category of polygon within the network used for voids
BreakLinesFile	String	No	The path of a GIS file containing the break lines
BreakLinesFeatureClass	String	No	For a GeoDatabase, the feature class within the GeoDatabase for the break lines
BreakLinesCategory	String	No	The category of polyline within the network used for break lines
WallsFile	String	No	The path of a GIS file containing the walls
WallsFeatureClass	String	No	For a GeoDatabase, the feature class within the GeoDatabase for the walls
WallsCategory	String	No	The category of polyline within the network used for walls
2DZones	String, Array	Yes	If the 2DZonesSelectionList parameter is absent and this parameter is absent or nil all 2D zones will be meshed. Otherwise can contain the name of a 2D zone as a string, or an array of strings containing the names of 2D zones
2DZonesSelectionList	Integer, String, WSModelObject	No	A selection list of 2D zones to mesh
LowerElementGroundLevels	Boolean	No	If present and evaluates to true, the process will lower 2D mesh elements with ground levels higher than the adjacent bank levels
RunOn	String	No	The computer to run the job on - . for 'this computer', * for 'any computer'
LogFile	String	No	The path of the log file with .HTML extension, if empty one will not be saved. This can only be used if only one 2D zone is meshed.
LogPath	String	No	The path of a folder for the log files. This may be used however many 2D zones are meshed. The file will be given the name of the 2D zone with the file type HTML.
For the pairs of keys (voids, break lines and wall) only one of the two values may be set.
If any of the VoidsFile, WallsFile or BreakLinesFile values are set, i.e. if any voids, walls or break lines are to be read in from a GIS files, the GIS component must be set with WSApplication.map_component= The user must have the GIS component they are selecting.
The FeatureClass keys can only be set if the corresponding File key is set and the map control is set and is not MapXTreme.
Only one of the 2DZones and 2DZonesSelectionList keys may be present.
Only one of the LogFile and LogDir keys may be present.
Parameters

Name	Type(s)	Description
options	Hash	An options hash, see method description.
Return	Hash	A hash with the 2d zone names as keys, with a boolean indicating success or failure.
mesh_async
#mesh_async(options) ⇒ Array
EXCHANGE

Meshes one or more 2D zones. Similar to the #mesh method, except it runs asynchronously i.e. it does not block the script thread.

Each 2D zone will have a unique job ID, returned in the array. These are integers that can be used in the #load_mesh_job, #cancel_mesh_job, #download_mesh_job_log, and #mesh_job_status methods of this network class, or the WSApplication.wait_for_jobs method.

Parameters

Name	Type(s)	Description
options	Hash	An options hash, identical to #mesh except it does not have the logfile or logdir keys.
Return	Array	An array of job ids, which can be used in other methods (see description).
mesh_job_status
#mesh_job_status(job_id) ⇒ String
EXCHANGE

Returns the current status of a mesh job, identified by a job ID from #mesh_async.

Parameters

Name	Type(s)	Description
job_id	Integer	The job id from the #mesh_async method.
Return	String	
model_object
#model_object ⇒ WSModelObject
EXCHANGE, UI

Returns a WSModelObject (or derived class) associated with this network.

If the network was loaded from a sim, then the model object of that sim will be returned. This is different from #network_model_object which always returns the network.

Parameters

Name	Type(s)	Description
Return	WSModelObject	
mscc_export_cctv_surveys
#mscc_export_cctv_surveys(export_file, export_images, selection_only, log_file ⇒ Boolean
EXCHANGE, UI

This method exports CCTV survey data from a Collection Network to the MSCC4 XML format.

The export_file argument specified the output XML file and log_file the location of a text file for errors.

The other two arguments take Boolean values. export_images controls whether defect images are to be exported and selection_only will limit the export to selected objects.

Parameters

Name	Type(s)	Description
Return	Boolean	
mscc_export_manhole_surveys
#mscc_export_manhole_surveys(export_file, export_images, selection_only, log_file) ⇒ Boolean
EXCHANGE, UI

This method exports manhole survey data from a Collection Network to the MSCC5 XML format.

The export_file argument specified the output XML file and log_file the location of a text file for errors.

The other two arguments take Boolean values. export_images controls whether defect images are to be exported and selection_only will limit the export to selected objects.

Parameters

Name	Type(s)	Description
Return	Boolean	
mscc_import_cctv_surveys
#mscc_import_cctv_surveys(import_file, import_flag, import_images, id_gen, overwrite, log_file)
EXCHANGE, UI

This method imports CCTV survey data into a Collection Network from the MSCC4 XML format.

The import_file argument specifies the XML file and log_file the location of a text file for errors.

The import_flag text specifies the data flag for imported fields. import_images controls whether defect images are to be imported.

To prevent the overwriting of existing surveys in the event of name clashes, set overwite to false.

The id generation parameter, id_gen, uses the following values (these correspond to the user interface options in the help):

1 - StartNodeRef, Direction, Date and Time
2 - StartNodeRef, Direction and an index for uniqueness
3 - US node ID, Direction, Date and Time
4 - US node ID, Direction and an index for uniqueness
5 - ClientDefined1
6 - ClientDefined2
7 - ClientDefined3
mscc_import_manhole_surveys
#mscc_import_manhole_surveys(import_file, import_flag, import_images, id_gen, overwrite, log_file)
EXCHANGE, UI

This method imports manhole survey data into a Collection Network from the MSCC5 XML format.

The import_file argument specifies the XML file and log_file the location of a text file for errors.

The import_flag text specifies the data flag for imported fields. import_images controls whether defect images are to be imported.

To prevent the overwriting of existing surveys in the event of name clashes, set overwite to false.

The id generation parameter, id_gen, uses the following values (these correspond to the user interface options in the help):

1 - Manhole/Node reference, Date and Time
2 - Manhole/Node reference and an index for uniqueness
network_model_object
#network_model_object ⇒ WSModelObject
EXCHANGE, UI

Returns the WSModelObject (or derived class) associated with this network.

If the network was loaded from a sim, then the model object of that network will be returned. This is different from #model_object which would return the sim.

Parameters

Name	Type(s)	Description
Return	WSModelObject	
new_row_object
#new_row_object(type) ⇒ WSRowObject
EXCHANGE, UI

Creates a new object in this network. This must be done within a network transaction, and you must set a primary ID for the object before you can write changes to it.

Parameters

Name	Type(s)	Description
type	String	The object type.
Return	WSRowObject	
objects_in_polygon
#objects_in_polygon(polygon, type) ⇒ Array
EXCHANGE, UI

Returns an array of the WSRowObject objects inside the polygon geometry, matching the type parameter.

When using an array of strings as the type, all values must be unique (no duplicates) and cannot contain a category and a table within the same category.

Parameters

Name	Type(s)	Description
polygon	WSRowObject	An object containing polygon geometry.
type	String, Array, nil	The name(s) of a type or category of object, nil will search all tables.
Return	Array	
odec_export_ex
#odec_export_ex(format, config, options, table, *args) ⇒ void
EXCHANGE, UI

Exports network data using the Open Data Export Centre.

See WSBaseNetworkObject.odec_export_ex.

odic_import_ex
#odic_import_ex(format, config, options, table, *args) ⇒ Array
EXCHANGE, UI

Imports and updates network data using the Open Data Import Centre, returning an array of the objects created or updated in the process. Objects may also be deleted, but these are not returned / listed.

See WSBaseNetworkObject.odec_import_ex.

Parameters

Name	Type(s)	Description
Return	Array	
ribx_export_surveys
#ribx_export_surveys(export_file, selection_only, log_file) ⇒ Boolean
EXCHANGE, UI

Exports manhole survey and cctv survey data from a Collection Network to the RIBX XML format.

The export_file argument specified the output XML file and log_file the location of a text file for errors.

The selection_only argument is a Boolean value and will limit the export to selected objects if it is true.

Parameters

Name	Type(s)	Description
Return	Boolean	
ribx_import_surveys
#ribx_import_surveys(import_file, import_flag, id_gen, overwrite, log_file)
EXCHANGE, UI

This method imports CCTV survey & manhole survey data into a Collection Network from the RIBX XML format.

The import_file argument specifies the XML file and log_file the location of a text file for errors.

The import_flag text specifies the data flag for imported fields.

To prevent the overwriting of existing surveys in the event of name clashes, set overwite to false.

The id generation parameter, id_gen, uses the following values (these correspond to the user interface options in the help).

1 - StartNodeRef, Direction, Date and Time
2 - StartNodeRef, Direction and an index for uniqueness
3 - US node ID, Direction, Date and Time
4 - US node ID, Direction and an index for uniqueness
row_object
#row_object(type, id) ⇒ WSRowObject?
EXCHANGE, UI

Returns a specific row object by type and ID.

node = network.row_object('wn_node', 'ST543643')
raise "Could not get node" if node.nil?
Parameters

Name	Type(s)	Description
type	String	The object type.
id	String	The object id, e.g. 'st543643' or st543643.st543473.1.
Return	WSRowObject, nil	The object found, or nil if there is no such object in the network.
row_object_collection
#row_object_collection(type) ⇒ WSRowObjectCollection
EXCHANGE, UI

Returns all row objects of a given type as a WSRowObjectCollection.

Parameters

Name	Type(s)	Description
type	String	The object type.
Return	WSRowObjectCollection	All objects of this type in the network, will be empty if there are none of this type.
row_object_collection_selection
#row_object_collection_selection(type) ⇒ WSRowObjectCollection
EXCHANGE, UI

Returns all selected row objects of a given type as a WSRowObjectCollection.

Parameters

Name	Type(s)	Description
type	String	The object type.
Return	WSRowObjectCollection	The selected objects of this type in the network, will be empty if there are none of this type selected.
row_objects
#row_objects(type) ⇒ Array
EXCHANGE, UI

Returns all row objects of a given type in an Array.

Parameters

Name	Type(s)	Description
type	String	The object type.
Return	Array	The objects of this type in the network, will be empty if there are none.
row_objects_from_asset_id
#row_objects_from_asset_id(type, id) ⇒ Array
EXCHANGE, UI

Returns all row objects of a given type with this Asset ID. This method is useful when working with imported link objects, where you may not know the multi-part ID.

Asset ID's are not guaranteed to be unique, so there may be multiple results. You can use the first Array method to access the first object.

nodes = network.row_objects_from_asset_id('wn_node', 'ST543643')
puts nodes.first['asset_id']
=> 'ST543643'
You can also create your own method which enforces a single result, returning nil if no object is found or multiple objects are found:

def unique_row_object_from_asset_id(network, type, id)
  nodes = network.row_objects_from_asset_id(type, id)
  return (nodes.size != 1) ? nil : nodes.first
end
Parameters

Name	Type(s)	Description
type	String	The object type - cannot be _nodes or _links.
id	String	The object's asset id e.g. 'st543643'.
Return	Array	The objects found in the network, will be an empty array if there are none.
row_objects_selection
#row_objects_selection(type) ⇒ Array
EXCHANGE, UI

Returns all selected row objects of a given type in an Array.

Parameters

Name	Type(s)	Description
type	String	The object type.
Return	Array	The selected objects of this type in the network, will be empty if there are none of this type selected.
run_sql
#run_sql(table, query) ⇒ void
EXCHANGE, UI

Runs a SQL query on this network.

The SQL query can include multiple clauses, including saving results to a file, but cannot use any of the options that open results or prompt grids.

Note: This method previously included capitalization, we recommend using the new lower case method name.
Parameters

Name	Type(s)	Description
table	String	The table name, _nodes or _links are equivalent to 'all nodes' and 'all links' in sql.
query	String	The sql query.
run_inference
#run_inference(inference, ground_model, mode, zone, error_file) ⇒ void
EXCHANGE, UI

Runs the inference object on this network, which must be a collection asset network or a distribution asset network.

The supported modes are:

nil, false or the string Network - run the inference on the whole network
true or the string Selection - run the inference on the current selection (which, of course, must be set up within the script)
the string Zone - run the inference for the zone specified in the following parameter.
The string Category - run the inference for zones with the zone specified in the following parameter.
The ground model parameter must be nil when this method is used from the UI. If there is a ground model loaded into the network (either TIN or grid), it will be used instead.

Parameters

Name	Type(s)	Description
inference	Integer, String, WSModelObject	The inference object - can be the id, scripting path, or a wsmodelobject of the correct type.
ground_model	Integer, String, WSModelObject, nil	Optional ground model to use (exchange only) - can be the id (grid ground model only), scripting path, or a wsmodelobject of the correct type.
mode	String, Boolean, nil	See method description.
zone	String, nil	If the mode parameter is zone or category, this string should be the name of the zone or zone category.
error_file	String, nil	Path to an error file.
run_stored_query_object
#run_stored_query_object(stored_query) ⇒ void
EXCHANGE, UI

Runs a stored query on this network.

Parameters

Name	Type(s)	Description
stored_query	Integer, String, WSModelObject	The stored query object - can be the id, scripting path, or a wsmodelobject of the correct type.
save_selection
#save_selection(selection_list) ⇒ void
EXCHANGE, UI

Saves the current selection (in the current scenario) to an already existing selection list model object.

Parameters

Name	Type(s)	Description
selection_list	Integer, String, WSModelObject	The selection list object - can be the id, scripting path, or a wsmodelobject of the correct type.
scenarios
#scenarios { |s| ... } ⇒ String
EXCHANGE, UI

Iterates through the scenarios, yielding a String of each scenario name. The base scenario is included as the string Base in English.

  network.scenarios { |scenario| puts scenario }
  network.scenarios do |scenario|
    puts scenario
  end
Parameters

Name	Type(s)	Description
Return	String	
search_at_point
#search_at_point(x, y, distance, types) ⇒ Array
EXCHANGE, UI

Find all objects within a distance of a given point.

When using an array of strings as the type, all values must be unique and cannot contain a category and a table within that category. This is similar to the WSRowObject.objects_in_polygon method.

Parameters

Name	Type(s)	Description
x	Numeric	X coordinate.
y	Numeric	Y coordinate.
distance	Numeric	Search radius around point.
type	String, Array. nil	The name of a table or category, an array of names, or nil to search all tables.
Return	Array	
selection_size
#selection_size ⇒ Integer
EXCHANGE, UI

Returns the number of objects currently selected.

Parameters

Name	Type(s)	Description
Return	Integer	
set_projection_string
#set_projection_string(string) ⇒ void
EXCHANGE

Sets the map projection string. The format of the string depends on the current map control.

Compatible projection strings or MapXTreme can be found in C:\Program Files\Common Files\MapInfo\MapXtreme\VERSION\MapInfoCoordinateSystemSet.xml, where VERSION will depend on the current application version.

E.g. for British National Grid [EPSG 27700]:

  coordsys 8,79,7,-2,49,0.9996012717,400000,-100000

The projection string is: 8,79,7,-2,49,0.9996012717,400000,-100000.

Parameters

Name	Type(s)	Description
string	String	
snapshot_export
#snapshot_export(file) ⇒ void
EXCHANGE, UI

Exports a snapshot of the network to the given file. All objects are exported from all tables, but image files and GeoPlan properties and themes are not exported.

Snapshots cannot be exported from networks with uncommitted changes.

Parameters

Name	Type(s)	Description
file	String	Path to the file.
snapshot_export_ex
#snapshot_export_ex(file, options) ⇒ void
EXCHANGE, UI

Exports a snapshot of the network to the given file. If no options hash is provided, all objects are exported from all tables, but image files and GeoPlan properties and themes are not exported.

Snapshots cannot be exported from networks with uncommitted changes.

The options hash contains the following keys:

Name	Type	Description
SelectedOnly	Boolean	If present and true, only the currently selected objects are exported, otherwise by default all objects of the appropriate tables are exported.
IncludeImageFiles	Boolean	If present and true, includes the data for image files in the network, otherwise by default images are not exported.
IncludeGeoPlanPropertiesAndThemes	Boolean	If present and true, includes the data for GeoPlan properties and themes, otherwise by default they are not exported.
ChangesFromVersion	Integer	If present, the snapshot will be of the different from the network's version with this commit ID, otherwise by default the current version of the network will be exported.
Tables	Array	If present, a list of the internal table names (as returned by the table_names method of this class) If not present then all tables will be exported.
The SelectedOnlyOptions must not be mixed with the Tables option or the ChangesFromVersion option.

Parameters

Name	Type(s)	Description
file	String	Path to the file.
options	Hash	See method description.
snapshot_import_ex
#snapshot_import_ex(file, options) ⇒ void
EXCHANGE, UI

Imports a snapshot file into the network from a file, with the provided options.

The options hash contains the following keys:

Name	Type	Description
Tables	Array	A list of network table names to import. If this key is not provided then all tables will be imported.
AllowDeletes	Boolean	
ImportGeoPlanPropertiesAndThemes	Boolean	
UpdateExistingObjectsFoundByID	Boolean	
UpdateExistingObjectsFoundByUID	Boolean	
ImportImageFiles	Boolean	
Parameters

Name	Type(s)	Description
file	String	Path to the file.
options	Hash	See method description.
snapshot_scan
#snapshot_scan(file) ⇒ Hash
EXCHANGE, UI

Scans a snapshot file and returns a hash containing the following details:

NetworkGUID (String) the GUID of the network from which the snapshot was exported.
CommitGUID (String) the GUID of the commit of the network from which the snapshot was exported.
CommitID (Integer) the ID of the commit of the network from which the snapshot was exported.
NetworkTypeCode (String) the type of network from which the snapshot was exported. This matches the name of the network type e.g. 'Collection Network'
DatabaseGUID (String) the GUID associated with the database version from which the snapshot was exported.
DatabaseSubVersion (Integer) the 'subversion' associated with the database version from which the snapshot was exported.
UnknownTableCount (Integer) the number of tables in the snapshot not recognised by the software, this will only be greater than 0 if the snapshot were exported from a more recent version of the software.
FileCount (Integer) the number of image files contained within the snapshot.
ContainsGeoPlanPropertiesAndThemes - Boolean - true if the snapshot was exported with the option to included GeoPlan properties and themes.
Tables (Hash) a hash containing information about the tables exported:
ObjectCount (Integer) the number of objects in the snapshot for the table.
ObjectsWithOldVersionsCount (Integer)
ObjectsFoundByUID (Integer)
ObjectsFoundByID (Integer)
DeleteRecordsCount (Integer)
UnknownFieldCount (Integer) the number of unknown fields for the table, this will be zero unless the export is from a more recent version of the software than the user is using to import the data.
Parameters

Name	Type(s)	Description
file	String	Path to the snapshot file.
Return	Hash	
table
#table(name) ⇒ WSTableInfo
EXCHANGE, UI

Returns a WSTableInfo object for a specific table in this network.

Parameters

Name	Type(s)	Description
name	String	Name of the table.
Return	WSTableInfo	
table_names
#table_names ⇒ Array
EXCHANGE, UI

Returns the names of all tables in this network.

Parameters

Name	Type(s)	Description
Return	Array	
tables
#tables ⇒ Array
EXCHANGE, UI

Returns an array of WSTableInfo objects for the tables in this network.

Parameters

Name	Type(s)	Description
Return	Array	
timestep_count
#timestep_count ⇒ Integer
EXCHANGE, UI

Returns the number of result timesteps, not including the maximum timestep.

Parameters

Name	Type(s)	Description
Return	Integer	
timestep_time
#timestep_time(timestep_no) ⇒ DateTime
EXCHANGE, UI

Returns the actual time of the timestep index provided.

Parameters

Name	Type(s)	Description
timestep_no	Integer	
Return	DateTime	
transaction_begin
#transaction_begin ⇒ void
EXCHANGE, UI

Begins a transaction, during which you can modify network data such as adding/removing objects or changing fields. Most changes to a network must be within a transaction.

A transaction can be ended with #transaction_commit (to save the changes) or #transaction_rollback (to abandon them).

transaction_commit
#transaction_commit ⇒ void
EXCHANGE, UI

Commits any changes to the network since #transaction_begin.

transaction_rollback
#transaction_rollback ⇒ void
EXCHANGE, UI

Rolls back (ends) the transaction, which reverts any changes made since #transaction_begin.

This should be used with caution if you are storing references to WSRowObjects or associated data, as this may break references and cause an exception when you attempt to access or work with them.

update_cctv_scores
#update_cctv_scores ⇒ void
EXCHANGE, UI

Calculates CCTV scores for all surveys in the network using the current standard.

xprafts_import
#xprafts_import(file, use_large_size, split_on_lag_links, combine_subcatchments, log) ⇒ void
EXCHANGE

Updates the network from an XPRAFTS .xpx file.

model_group.xprafts_import('C:/temp/1.xpx', true, false, true, 'C:/temp/log.txt')
Note: This method previously included capitalization, we recommend using the new lower case method name.
Parameters

Name	Type(s)	Description
file	String	The absolute path to the xprafts model, including extension (.xpx).
use_large_size	Boolean	If the xprafts model is configured to use the large unit size.
split_on_lag_links	Boolean	If true networks are split downstream of channel links and maintain lag link data, if false network connectivity is maintained by converting downstream lag links to channel links.
combine_subcatchments	Boolean	If true combine the 1st and 2nd subcatchment as a single subcatchment polygon. this would set the per-surface rafts b option and setting the rafts adapt factor and manning's roughness at the runoff surface level.
log	String	Path to save the import log including extension (.txt).

WSOpenTSD
An open TSD object, allowing access to the timeseries data, similar to opening the TSD as a grid in the UI.

Dates and times in TSD are handled using the DateTime class provided by the Ruby standard library, if it is defined in the script. If DateTime is not available, then the built-in Time class is used. Note that DateTime is deprecated in modern Ruby.

TSD Hashes
Data Source
Data Stream
Data Value
Lookup
User Edit
Geometry
data_sources_count
data_source_by_id
data_source_by_index
data_source_by_name
data_source_delete
data_source_new
data_source_update
forecast_data_add
forecast_data_get
forecast_origins_get
geometry_get
geometry_set
lookups_count
lookup_by_id
lookup_by_index
lookup_by_name
lookup_delete
lookup_new
lookup_update
streams_count
streams_load
streams_save
stream_by_id
stream_by_index
stream_by_name
stream_delete
stream_new
stream_update
time_series_data_add
time_series_data_get
user_edit_data_get
user_edit_data_update
user_edits
user_edit_apply
user_edit_by_id
user_edit_by_name
user_edit_delete
user_edit_new
user_edit_update
TSD Hashes
The following TSD objects are implemented as hashes of their properties. Properties that must be set by the user when creating a new object are marked with a *. Properties that are set by the software, and cannot be updated, are marked with a +. Boolean, integer and string values default to false, 0 and '' respectively and are not included in the returned hash if they have a default value. Properties that are omitted when updating an existing object will retain their existing values after the update.

Data Source
The data source hash contains the following properties:

Key	Type	Default	Description
+dataSourceId	Integer		The data source ID. Only present if there is an ID (i.e. the data source has been saved to the database).
+index	Integer		The index of the data source. Only present if there is no ID (i.e. the data source has not yet been saved to the database).
*streamName	String		The data source name
filename	String		Path to the telemetry database or folder
timeZone	String		Time zone of the data
+lastTimeSeriesUpdate	Time		UTC time that the data source was last updated
autoUpdateEnabled	Boolean		Not used in InfoWorks ICM
autoUpdateStartAt	Integer		Not used in InfoWorks ICM
autoUpdateInterval	Integer		Not used in InfoWorks ICM
autoUpdateTriggerFile	String		Not used in InfoWorks ICM
script	String		Absolute path and name of the script file, plus any script parameters, which will be run at the start of the data update process.
scriptTimeout	Integer		Interval of time after which the script is deemed to have failed (s)
+lastModified	Time		Time that the data source was last modified
srcGeomMetadata	String		(Spatial TSD only)
fileCount	Integer		(Spatial TSD only)
projection	String		(Spatial TSD only)
areaOfInterest	Array		(Spatial TSD only) Array of four Floats
logonType	Integer		0 = trusted, 1 = username/password (Scalar TSD only)
username	String		Username for connecting to telemetry (Scalar TSD only)
password	String		Password for connecting to telemetry (Scalar TSD only)
server	String		Name of the server on which the telemetry database is stored. (Scalar TSD only)
database	String		Telemetry database, data server or URL (Scalar TSD only)
provider	Integer		Database type (Scalar TSD only)

-1 = Unknown

0 = JET

1 = Oracle

2 = SQL Server 7

3 = SQL Server

4 = ODBC

5 = PI

6 = Simple CSV

7 = SOPHIE (Pre)

8 = SANDRE (XMO)

9 = iHistorian

10 = ClearSCADA

11 = SQL Server (ODBC)

12 = JET (ACE)

13 = SCADAWatch

14 = PI WebAPI

15 = EA REST API

16 = ADS Rest

17 = Info360.com

18 = Generic REST
netServiceName	String		Net service name (Scalar TSD only)
creationUser	String		Creation user (Scalar TSD only)
connectionString	String		Connection string (Scalar TSD only)
commandTimeout	Integer		Command timeout (Scalar TSD only)
Data Stream
The data stream hash contains the following properties:

Key	Type	Default	Description
+streamId	Integer		The data stream ID. Only present if there is an ID (i.e. the data stream has been saved to the database).
+index	Integer		The index of the stream. Only present if there is no ID (i.e. the data stream has not yet been saved to the database).
*streamType	Integer		0 = observed, 1 = forecast, 2 = derived, 3 = stream type count. Cannot be changed after the object is created.
*streamName	String		The stream name
+versionId	Integer		Version ID
dataInterval	Float		Data interval
+latestUpdate	Time		The time the stream was last updated
+latestData	Time		The time of the most recent data
exFactor	Float		Value factor
exTimeOffset	Float		Value offset
+isRefd	Boolean		Stream has been used in a simulation
+lastModified	Time		The time the stream was last modified
+recordCount	Integer		The number of entries on the stream
units	String		(Scalar TSD only) Unit code for the physical quantity in the stream
exUpdateDisabled	Boolean		External update disabled (Scalar TSD only)
exDataSourceId	Integer		External data source (Scalar TSD only)
exUnits	String		Units type (Scalar TSD only)
exOffset	Float		Value offset (Scalar TSD only)
exMinThreshold	Float		Min. threshold (Scalar TSD only)
exMaxThreshold	Float		Max. threshold (Scalar TSD only)
exTable	String		Name of the table in the telemetry database which contains the live data feed (Scalar TSD only)
exDataColumn	String		Data column (Scalar TSD only)
exTimeColumn	String		Time column (Scalar TSD only)
exOriginTimeColumn	String		Origin time column (Scalar TSD only)
exUserField1	String		User field 1 (Scalar TSD only)
exUserVal1	String		User value 1 (Scalar TSD only)
exUserField2	String		User field 2 (Scalar TSD only)
exUserVal2	String		User value 2 (Scalar TSD only)
exUserField3	String		User field 3 (Scalar TSD only)
exUserVal3	String		User value 3 (Scalar TSD only)
x	Float		(Scalar TSD only)
y	Float		(Scalar TSD only)
lookupId	Integer		ID of lookup that is used to transform data imported to the stream (Scalar TSD only)
tagName	String		Tag name (Scalar TSD only)
description	String		Description (Scalar TSD only)
Data Value
Time series data values are hashes containing the following properties. Note that existing properties are not preserved when updating a data value.

Key	Type	Default	Description
*t	Time		Timestamp of the value or of the forecast origin (for data that is a series of forecast origins)
+tOrigin	Time		(Forecast value only) timestamp of the origin of this forecast value
exclude	Boolean		Value is not to be used in simulation
readonly	Boolean		Value is not to be updated by an automated update (not used in InfoWorks ICM)
geomKey	String		Spatial TSD only - uniquely identifies the geometry of the spatial data
flag	String		Flag
value	Double		Value (Scalar TSD only). Not present if this is a forecast origin. May be missing (a null value).
values	Array		Array of values (Spatial TSD only). May be missing (a null value).
Lookup
Live data lookups are hashes containing the following properties.

Key	Type	Default	Description
+lookupId	Integer		The lookup ID. Only present if there is an ID (i.e. the lookup has been saved to the database).
+index	Integer		The index of the lookup. Only present if there is no ID (i.e. the lookup has not yet been saved to the database).
*lookupName	String		The lookup name
+lastModified	Time		The time the lookup was last modified
map	Hash		The lookup mapping
User Edit
User edits are hashes containing the following properties.

Key	Type	Default	Description
+userEditId	Integer		The user edit ID
*userEditName	String		The name of the user edit
+applied	Boolean		Whether the user edit has been permanently applied to the stream
shared	Boolean		Set if the user edit is available for use by other users (always true in InfoWorks ICM)
+locked	Boolean		Set if the user edit has been used in a simulation
+userName	String		Name of the user who created the user edit
comment	String		Description or other comment on the user edit
*userEditStream	String		ID of the data stream to which the edit relates. Cannot be changed.
Geometry
A geometry (Spatial TSD only) is a hash containing parameters and point coordinates relating to the geometry of spatial data. It can be copied, but is not intended for external construction or manipulation.

Methods:

data_sources_count
#data_sources_count(type) ⇒ Integer
EXCHANGE

Returns the number of data sources in the TSD.

Parameters

Name	Type(s)	Description
Return	Integer	Number of data sources in the TSD
data_source_by_id
#data_source_by_id(ID) ⇒ Hash
EXCHANGE

Returns the data source with the specified ID.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the data source to be returned
Return	Hash	The data source
data_source_by_index
#data_source_by_index(index) ⇒ Hash
EXCHANGE

Returns the data source with the specified index.

Parameters

Name	Type(s)	Description
index	Integer	Index of the data source to be returned
Return	Hash	The data source
data_source_by_name
#data_source_by_name(name) ⇒ Hash
EXCHANGE

Returns the data source with the specified name.

Parameters

Name	Type(s)	Description
Name	String	Name of the data source to be returned
Return	Hash	The data source
data_source_delete
#data_source_delete(ID) ⇒ void
EXCHANGE

Deletes the data source with the specified ID.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the data source to be deleted
data_source_new
#data_source_new(ID) ⇒ Hash
EXCHANGE

Creates a new data source with the specified name.

An exception is thrown if the TSD is a spatial TSD and already has a data source, or if the TSD is a sclar TSD and a data source with the supplied name already exists.

Parameters

Name	Type(s)	Description
Name	String	Name for the new data source
Return	Hash	The data source
data_source_update
#data_source_update(Source) ⇒ Hash
EXCHANGE

Finds the data source with the ID (or index if there is no ID) supplied in the Source hash, and updates it with the properties of the Source.

An exception is thrown if the name supplied in the hash is the same as the name of a different, existing data source.

Parameters

Name	Type(s)	Description
Source	Hash	The new properties of the data data source
Return	Hash	The updated data data source
forecast_data_add
#forecast_data_add(ID, origin, flag, data, comment) ⇒ void
EXCHANGE

Adds forecast data to the specified data stream. The data should be passed in as an array of Data Value hashes (note that tOrigin must not be set in these hashes).

Parameters

Name	Type(s)	Description
ID	Integer	ID of the data stream
origin	Time	Forecast origin of the data
flag	String	Flag to be assigned to all the added data values
data	Array	Array of data values to be added
forecast_data_get
#forecast_data_get(ID, origin) ⇒ Array
EXCHANGE

Gets forecast data from the specified data stream as an array of Data Value hashes.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the data stream
origin	Time	Forecast origin of the data
Return	Array	Forecast data values
forecast_origins_get
#forecast_origins_get(ID, from, to, options) ⇒ Array
EXCHANGE

Gets forecast origins in the given period from the specified data stream.

The options hash contains the following keys:

Key	Type	Default	Description
inclusive	Boolean	True	Whether to include the from and to time points in the returned values, if present
limit	Integer	0	Limit on number of values to be returned (0 for no limit)
versionId	Integer	0	TSD version for which results are to be returned (0 for latest)
Parameters

Name	Type(s)	Description
ID	Integer	ID of the data stream
from	Time/String	From time (or string 'min' for minimum possible time)
to	Time/String	From time (or string 'max' for maximum possible time)
options	Hash	Hash of options (see above)
Return	Array	Forecast origin data
geometry_get
#geometry_get(key) ⇒ Hash
EXCHANGE

Gets #Geometry as a hash.

Parameters

Name	Type(s)	Description
key	String	
Return	Hash	Geometry hash
geometry_set
#geometry_set(key, geometry) ⇒ void
EXCHANGE

Sets geometry from a geometry hash.

Name	Type(s)	Description
key	String	
geometry	Hash	Geometry hash
lookups_count
#lookups_count() ⇒ Integer
EXCHANGE

Returns the number of lookups in the TSD.

Parameters

Name	Type(s)	Description
Return	Integer	Number of lookups in the TSD
lookup_by_id
#lookup_by_id(id) ⇒ Hash
EXCHANGE

Returns the lookup specified by the ID.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the lookup
Return	Hash	Lookup
lookup_by_index
#lookup_by_index(index) ⇒ Hash
EXCHANGE

Returns the lookup with the specified index.

Parameters

Name	Type(s)	Description
index	Integer	Index of the lookup to be returned
Return	Hash	The lookup
lookup_by_name
#lookup_by_name(name) ⇒ Hash
EXCHANGE

Returns the lookup with the specified name.

Parameters

Name	Type(s)	Description
Name	String	Name of the lookup to be returned
Return	Hash	The lookup
lookup_delete
#lookup(ID) ⇒ void
EXCHANGE

Deletes the lookup with the specified ID.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the lookup to be deleted
lookup_new
#lookup_new(ID) ⇒ Hash
EXCHANGE

Creates a new lookup with the specified name.

Parameters

Name	Type(s)	Description
Name	String	Name for the new lookup
Return	Hash	The lookup
lookup_update
#lookup_update(Source) ⇒ Hash
EXCHANGE

Finds the lookup with the ID (or index if there is no ID) supplied in the Source hash, and updates it with the properties of the Source.

An exception is thrown if the name supplied in the hash is the same as the name of a different, existing lookup

Parameters

Name	Type(s)	Description
Source	Hash	The new properties of the lookup
Return	Hash	The updated lookup
streams_count
#streams_count(type) ⇒ Integer
EXCHANGE

Returns the number of data streams of the given type in the TSD.

Parameters

Name	Type(s)	Description
type	Integer	0 = observed streams, 1 = forecast streams
Return	Integer	Number of streams
streams_load
#streams_load(version) ⇒ void
EXCHANGE

Loads the TSD at the specified version from the database. This is required before accessing or editing the data. A version of 0 indicates that the current version should be loaded.

Parameters

Name	Type(s)	Description
version	Integer	Database version, or 0 for latest
streams_save
#streams_save(comment) ⇒ void
EXCHANGE

Saves the updated data streams, sources and lookups to the database.

Parameters

Name	Type(s)	Description
comment	String	Comment to attach
stream_by_id
#stream_by_id(id) ⇒ Hash
EXCHANGE

Returns the properties of the data stream with the given ID as a hash.

Parameters

Name	Type(s)	Description
id	Integer	
Return	Hash	The data stream
stream_by_index
#stream_by_index(index) ⇒ Hash
EXCHANGE

Returns the data stream with the specified index.

Parameters

Name	Type(s)	Description
index	Integer	Index of the data stream to be returned
Return	Hash	The data stream
stream_by_name
#stream_by_name(name) ⇒ Hash
EXCHANGE

Returns the data stream with the specified name.

Parameters

Name	Type(s)	Description
Name	String	Name of the data stream to be returned
Return	Hash	The data stream
stream_delete
#stream(ID) ⇒ void
EXCHANGE

Deletes the data stream with the specified ID.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the data stream to be deleted
stream_new
#stream_new(ID) ⇒ Hash
EXCHANGE

Creates a new data stream with the specified name.

Parameters

Name	Type(s)	Description
Name	String	Name for the new data stream
Return	Hash	Data stream
stream_update
#stream_update(Source) ⇒ Hash
EXCHANGE

Finds the data stream with the ID (or index if there is no ID) supplied in the Source hash, and updates it with the properties of the Source.

An exception is thrown if the name supplied in the hash is the same as the name of a different, existing data source.

Parameters

Name	Type(s)	Description
Source	Hash	The new properties of the data stream
Return	Hash	The updated data stream
time_series_data_add
#time_series_data_add(ID, data, comment) ⇒ void
EXCHANGE

Adds time series data to the specified data stream. The data should be passed in as an array of Data value hashes.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the data stream
data	Array	Data calues to be added
comment	String	Comment to be associated with the data
time_series_data_get
#time_series_data_get(ID, from, to, options) ⇒ Array
EXCHANGE

Gets time series data from the specified data stream as an array of Data value hashes. For forecast data, the returned series may contain values from multiple forecasts (different time origins) but only one value is returned for any given timestamp and this is the value that has the latest time origin (i.e. the most recent forecast for that time). The range option defaults to "between" and has the following choices:

| inside | data at times that are inside from and to (i.e. not including the from and to times) | | between | data at times between from and to (including those time points, if they exist) | | outside | data at times between from and to, plus the time points immediately before the start and after the end of the specified range, if they exist |

The options hash has the following keys:

Key	Type	Default	Description
range	String,		Optional. "between", "inside", "outside" or nil
limit	Integer	0	Limit on the number of values to be returned (0 for no limit)
versionId	Integer	0	Version of the TSD from which the values are to be returned (0 for latest)
userEditIds	Array		Optional. User edits that should be applied to the returned values.
futureExclude	Time		Optional. Exclude data values that are from the nominal future of the specified time (i.e. observed data with a timestamp after this time and forecast data with an origin timestamp after this time)
ref	String		Optional. Value to be set as a reference for a simulation in which this data is to be used. If set, has the effect of setting the refd property of the stream to true
Parameters

Name	Type(s)	Description
ID	Integer	ID of the data stream
from	Time/String	From time (or string 'min' for minimum possible time)
to	Time/String	From time (or string 'max' for maximum possible time)
options	Hash	Optional hash of options. See description above
Return	Array	Data values
user_edit_data_get
#user_edit_data_get(ID, from, to, options) ⇒ Array
EXCHANGE

Gets data from the specified user edit as an array of Data value hashes.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the user edit
from	Time/String	From time (or string 'min' for minimum possible time)
to	Time/String	From time (or string 'max' for maximum possible time)
Return	Array	User edit data values
user_edit_data_update
#user_edit_data_update(ID, from, to, options) ⇒ void
EXCHANGE

Adds data to or removes data from the specified user edit.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the user edit
add	Array	Array of data values to be added
remove	Array	Array of timestamps of data to be removed
user_edits
#user_edits(ID, from, to) ⇒ Array
EXCHANGE

Gets the current user's user edits from the specified data stream as an array of user edit hashes, sorted by name.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the user edit
from	Time/String	From time (or string 'min' for minimum possible time)
to	Time/String	From time (or string 'max' for maximum possible time)
Return	Array	Array of user edits
user_edit_apply
#user_edit_apply(ID, readonly) ⇒ void
EXCHANGE

Applies the specified user edit to the data stream that it is associated with.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the user edit
readonly	Boolean	Whether to mark the edited data as readonly
user_edit_by_id
#user_edit_by_id(ID) ⇒ Hash
EXCHANGE

Retrieves the specified user edit as a user edit hash.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the user edit
Return	Hash	The user edit
user_edit_by_name
#user_edit_by_name(Name) ⇒ Hash
EXCHANGE

Retrieves the specified user edit as a user edit hash.

Parameters

Name	Type(s)	Description
Name	String	Name of the user edit
Return	Hash	The user edit
user_edit_delete
#user_edit_delete(ID) ⇒ void
EXCHANGE

Deletes the specified user edit.

Parameters

Name	Type(s)	Description
ID	Integer	ID of the user edit
user_edit_new
#user_edit_new(Name, StreamID, shared) ⇒ void
EXCHANGE

Creates a new user edit. Throws an exception if an edit with the specified name already exists.

Parameters

Name	Type(s)	Description
Name	String	Name for the the user edit
SrreamID	Integer	ID of the data stream that the edit is to be associated with
shared	Boolean	Whether the user edit should be shared for use by other users (should be set to true to be consistent with normal InfoWorks ICM usage)
user_edit_update
#user_edit_update(Edit) ⇒ Hash
EXCHANGE

Updates the user edit with the name, comment and shared properties from the hash. Throws an exception if the ID is missing or invalid or doesn't match en existing edit or if a different edit has the same name.

Parameters

Name	Type(s)	Description
Edit	Hash	The user edit hash
Return	Hash	The updated user edit

WSRiskAnalysisRunObject
WSModelObject > WSRiskAnalysisRunObject

A risk analysis run.

Methods:

run
run
#run ⇒ void
EXCHANGE

Performs the risk analysis run.

WSRowObject
An individual object in a network.

Methods that return this type of object may actually return a derived class, for example a WSNode for nodes or WSLink for links.

Methods:

[] (Get Field)
[]= (Set Field)
_* (Get Tag)
_*= (Set Tag)
autoname
category
contains?
delete
field
gauge_results
id
id= (Set)
is_inside?
navigate
navigate1
objects_in_polygon
result
results
selected= (Set)
selected?
table
table_info
write
[] (Get Field)
#[(field)] ⇒ Any
EXCHANGE, UI

Returns the value of a field, using hash-like syntax. May return a simple value, or a WSStructure if the field is a structure blob.

puts node['node_id']
⇒ 'Badger'
Parameters

Name	Type(s)	Description
field	String	The name of the field.
[]= (Set Field)
#[(field)]=(value) ⇒ void
EXCHANGE, UI

Sets the value of a field, using hash-like syntax. The value must be an appropriate type for the field, and this cannot be used to set structure blobs.

node['node_id'] = 'Badger'
Parameters

Name	Type(s)	Description
field	String	The name of the field.
value	Any	The value, must be an appropriate type for the field.
_* (Get Tag)
#_* ⇒ Any
EXCHANGE, UI

Reads the value of a tag, which are temporary values added to the object during the script.

puts mo._badger
⇒ 'Penguin'
_*= (Set Tag)
#_*=(value) ⇒ void
EXCHANGE, UI

Sets the value of a tag, which are user defined temporary values added to the object during the script. The name of tags can contain only alphanumeric characters (i.e. letters and numbers).

mo._badger = 'Penguin'
autoname
#autoname ⇒ void
EXCHANGE, UI

Sets the ID of this object using the current network autoname convention.

category
#category ⇒ String
EXCHANGE, UI

Returns the category name of the object e.g. _nodes, _links.

contains?
#contains(other) ⇒ Boolean
EXCHANGE, UI

If this object is a polygon, checks if another WSRowObject is inside it. This is effectively the inverse of the #is_inside? method.

Parameters

Name	Type(s)	Description
other	WSRowObject	The other object.
Return	Boolean	If the other object is inside this polygon.
delete
#delete ⇒ void
EXCHANGE, UI

Deletes the row object. This is immediate and does not require the #write method.

field
#field(name) ⇒ WSFieldInfo?
EXCHANGE, UI

Returns the WSFieldInfo object for a given field name.

This only returns information about the named field such as it's data type, not any data associated with this particular object.

gauge_results
#gauge_results(field) ⇒ Array
EXCHANGE, UI

Returns an array of values for the given results field name, at all gauge time-steps. The field must have time varying results.

If the object or field does not have gauge results it will return the regular results.

If the simulation results time-step multiplier is 0, this method will return no results, even if gauge results are available in the user interface.

Parameters

Name	Type(s)	Description
field	String	
Return	Array	
id
#id => String
EXCHANGE, UI

Returns the ID of the object.

If the object has a multi-part primary key (such as a link) then the key will be output with parts separated by a . character, similar to accessing the OID field in SQL.

puts node.id
=> "ST39469"
puts link.id
=> "ST41337.ST34322.1"
id= (Set)
#id=(new_id) ⇒ void
EXCHANGE, UI

Sets the ID of the object. Will raise an exception if the ID cannot be set e.g. is a duplicate.

Parameters

Name	Type(s)	Description
new_id	String	The new id, which must be unique and formatted the same way as an id retrieved from the #id method.
is_inside?
#is_inside?(other) ⇒ Boolean
EXCHANGE, UI

Checks if this object is inside a polygon.

Parameters

Name	Type(s)	Description
other	WSRowObject	The other object, which should be a polygon.
Return	Boolean	If this object is inside the other wsrowobject.
navigate
#navigate(type) ⇒ Array
EXCHANGE, UI

Navigates between objects and other objects based on their relationship. Supports one-to-one and one-to-many relationships, and returns an array of objects.

See also: #navigate1

Name	Has Results	One to Many
alt_demand	No	No
cctv_surveys	No	Yes
custom	No	No
data_logger	No	No
drain_tests	No	Yes
ds_flow_links	Yes	Yes
ds_links	Yes	Yes
ds_node	Yes	No
dye_tests	No	Yes
gps_surveys	No	Yes
hydrant_tests	No	Yes
incidents	No	Yes
joined	No	No
joined_pipes	No	Yes
lateral_pipe	No	No
maintenance_records	No	Yes
manhole_repairs	No	Yes
manhole_surveys	No	Yes
meter_tests	No	Yes
meters	No	Yes
monitoring_surveys	No	Yes
node	Yes	No
pipe	Yes	No
pipe_cleans	No	Yes
pipe_repairs	No	Yes
pipe_samples	No	Yes
properties	No	Yes
property	No	No
sanitary_manhole	No	No
sanitary_pipe	No	No
smoke_defects	No	Yes
smoke_test	No	No
smoke_tests	No	Yes
storm_manhole	No	No
storm_pipe	No	No
us_flow_links	Yes	Yes
us_links	Yes	Yes
us_node	Yes	No
Parameters

Name	Type(s)	Description
type	String	The navigation type, see method description.
navigate1
#navigate1(type) ⇒ WSRowObject?
EXCHANGE, UI

Navigates between objects and other objects based on their relationship. Supports one-to-one relationships, and returns a single object if found.

See also: #navigate

Parameters

Name	Type(s)	Description
type	String	The navigation type, see method description.
objects_in_polygon
#objects_in_polygon(type) ⇒ Array
EXCHANGE, UI

If this object is a polygon, returns an array of the WSRowObject objects inside it, matching the type parameter.

When using an array of strings as the type, all values must be unique (no duplicates) and cannot contain a category and a table within the same category. This is similar to the WSNumbatNetworkObject.search_at_point method.

Parameters

Name	Type(s)	Description
type	String, Array, nil	The name(s) of a type or category of object, nil will search all tables.
result
#result(field) ⇒ Float
EXCHANGE, UI

Returns the value for the given results field, at the current time-step.

Parameters

Name	Type(s)	Description
field	String	
Return	Float	
results
#results(field) ⇒ Array
EXCHANGE, UI

Returns an array of values for the given results field name, at all timesteps. The field must have time varying results.

Parameters

Name	Type(s)	Description
field	String	
Return	Array	
selected= (Set)
#selected=(bool) ⇒ void
EXCHANGE, UI

Sets whether this object is selected or deselected. This does not need to occur within a transaction.

Parameters

Name	Type(s)	Description
bool	Boolean	If the object is selected, this could be an explicit true or false, or a statement that evaluates to true or false.
selected?
#selected? ⇒ Boolean
EXCHANGE, UI

Returns if the object is currently selected.

table
#table ⇒ String
EXCHANGE, UI

Returns the object's table name.

table_info
#table_info ⇒ WSTableInfo
EXCHANGE, UI

Returns a WSTableInfo for this object's table, which contains metadata about the table structure.

write
#write ⇒ void
EXCHANGE, UI

Writes any changes to the object, such as modified field values.

WSRowObjectCollection
A collection of WSRowObjects.

Methods:

[] (Get Index)
each
length
[] (Get Index)
#[(index)] ⇒ WSRowObject?
EXCHANGE, UI

Returns the WSRowObject from the collection at the specified index.

Parameters

Name	Type(s)	Description
index	Integer	The index requested (zero-based).
Return	WSRowObject, nil	The object found, or nil if there is no object at this index.
each
#each { |ro| ... } ⇒ WSRowObject
EXCHANGE, UI

Iterates through the collection, yielding a WSRowObject.

Examples

network.row_object_collection('_nodes').each { |ro| puts ro.id }
network.row_object_collection('_nodes').each do |ro|
  puts ro.id
end
length
#length ⇒ Integer
EXCHANGE, UI

Returns the length of this collection, i.e. how many WSRowObjects it contains.

WSSimObject
WSModelObject > WSBaseNetworkObject > WSNumbatNetworkObject > WSSimObject

A read-only network with simulation results, representing an ICM Sim object, an ICM Risk Analysis Results object, or an ICM Risk Analysis Sim object. The Risk Analysis Results objects contain the results for a number of return periods and summary results. The Risk Analysis Sim objects contain only summary results.

The different return periods for the Risk Analysis Results objects correspond to the timesteps for regular simulations. The names of the methods reflect the usage for regular simulations i.e. to list the return periods for a risk analysis results object, you should use the list_timesteps method.

Methods:

list_max_results_attributes
list_results_attributes
list_results_gis_export_tables
list_timesteps
max_flood_contours_export
max_results_binary_export
max_results_csv_export
results_binary_export
results_csv_export
results_csv_export_ex
results_gis_export
results_path
run
run_ex
Single Parameter (Options Hash)
Two Parameters
status
success_substatus
timestep_count
list_max_results_attributes
#list_max_results_attributes ⇒ Array
EXCHANGE

Supported Types: ICM Sim, Risk Analysis Results, Risk Analysis Sim

This method returns attributes that can be exported using the #max_results_binary_export and #max_results_csv_export methods, and returns arrays corresponding to the tabs of the result export dialog in the UI.

[
  ['Scalar', ['totfl', 'totout', 'totr', ...]],
  ['Node', ['flooddepth', 'floodvolume', 'flvol', ...]]
]
Parameters

Name	Type(s)	Description
Return	Array	
list_results_attributes
#list_results_attributes ⇒ Array
EXCHANGE

Supported Types: ICM Sim, Risk Analysis Results

This method returns attributes that can be exported using the #results_binary_export and #results_csv_export methods, and returns arrays corresponding to the tabs of the result export dialog in the UI.

[
  ['Node', ['flooddepth', 'floodvolume', 'flvol', ...]],
  ['Link', ['ds_depth', 'ds_flow', 'ds_froude', ...]]
]
Parameters

Name	Type(s)	Description
Return	Array	
list_results_gis_export_tables
#list_results_gis export_tables ⇒ Array
EXCHANGE

Supported Types: ICM Sim, Risk Analysis Results, Risk Analysis Sim

Returns an array of the tables that may be exported to GIS using the #results_gis_export method.

The results for 2D elements is _2Delements
All links are combined into one GIS layer called _links
Note: This method previously included capitalization, we recommend using the new lower case method name.
Parameters

Name	Type(s)	Description
Return	Array	
list_timesteps
#list_timesteps ⇒ Array
EXCHANGE

Supported Types: ICM Sim, Risk Analysis Results, Risk Analysis Sim

For a normal simulation, this returns an array of the results timesteps for the simulation.

For a risk analysis results object, this returns an array of the return periods for the object.

Parameters

Name	Type(s)	Description
Return	Array	
max_flood_contours_export
#max_flood_contours_export(format, ground_model, theme, filename) ⇒ void
EXCHANGE

Supported Types: ICM Sim

Exports the flood contours to files (GIS or ASCII). The ASCII format is the same as produced via the user interface.

Parameters

Name	Type(s)	Description
format	String	The fomat, one of mif, tab, shp, or ascii - as in the user interface, geodatabases are not supported.
ground_model	Integer, String, WSModelObject	The ground model, which must be a gridded ground model for an ascii export. can be the id (see description), scripting path, or a wsmodelobject of the correct type. if the ground_model id is negative then it represents a tin ground model, i.e. -6 represents the tin ground model with id 6, 9 is a gridded ground model with id 9.
theme	Integer, String, WSModelObject	The theme to use for contours - can be the id, scripting path, or a wsmodelobject of the correct type.
filename	String	The file to export to.
max_results_binary_export
#max_results_binary_export(selection, attributes, file) ⇒ void
EXCHANGE

Supported Types: ICM Sim, Risk Analysis Results

Exports the maximum results (and other summary results) for the simulation in a binary file format - the format is documented elsewhere.

Parameters

Name	Type(s)	Description
selection	WSModelObject, String, Integer, nil	A selection list object as a wsmodelobject of the correct type, a scripting path, or a model id. if nil then the whole network will be exported.
attributes	Array, nil	Attributes to export, e.g. from the #list_results_attributes method, if nil then all attributes are exported.
file	String	Filepath to export.
max_results_csv_export
#max_results_csv_export(selection, attributes, folder) ⇒ void
EXCHANGE

Supported Types: ICM Sim

Exports the maximum results (and other summary results) for the simulation to .CSV files.

Parameters

Name	Type(s)	Description
selection	WSModelObject, String, Integer, nil	A selection list object as a wsmodelobject of the correct type, a scripting path, or a model id. if nil then the whole network will be exported.
attributes	Array, nil	Attributes to export, e.g. from the #list_results_attributes method, if nil then all attributes are exported.
folder	String	Folder to export the .csv files.
results_binary_export
#results_binary_export(selection, attributes, file) ⇒ void
EXCHANGE

Supported Types: ICM Sim, Risk Analysis Results

Exports the results at each timestep of the simulation in a binary file format - the format is documented elsewhere.

Parameters

Name	Type(s)	Description
selection	WSModelObject, String, Integer, nil	A selection list object as a wsmodelobject of the correct type, a scripting path, or a model id. if nil then the whole network will be exported.
attributes	Array, nil	Attributes to export, e.g. from the #list_results_attributes method, if nil then all attributes are exported.
file	String	Filepath to export.
results_csv_export
#results_csv_export(selection, folder) ⇒ void
EXCHANGE

Supported Types: ICM Sim

Exports the simulation results in CSV format, corresponding to the CSV results export in the user interface.

If the results multiplier is set to 0, the CSV will be empty.

Parameters

Name	Type(s)	Description
selection	WSModelObject, String, Integer, nil	A selection list object as a wsmodelobject of the correct type, a scripting path, or a model id. if nil then the whole network will be exported.
folder	String	Folder to export the .csv files.
results_csv_export_ex
#results_csv_export_ex(selection, attributes, folder) ⇒ void
EXCHANGE

Supported Types: ICM Sim

Similar to #results_csv_export, with an additional attributes parameter.

If the results multiplier is set to 0, the CSV will be empty.

Parameters

Name	Type(s)	Description
selection	WSModelObject, String, Integer, nil	A selection list object as a wsmodelobject of the correct type, a scripting path, or a model id. if nil then the whole network will be exported.
attributes	Array, nil	Attributes to export, e.g. from the #list_results_attributes method, if nil then all attributes are exported.
folder	String	Folder to export the .csv files.
results_gis_export
#results_gis_export(format, timesteps, options, folder) ⇒ void
EXCHANGE

Supported Types: ICM Sim, Risk Analysis Results, Risk Analysis Sim

Exports simulation results to a GIS data format, similar to the equivalent options in the user interface.

The options for timesteps are:

nil - this is the equivalent of the 'None' options when selecting timesteps in the UI i.e. it only makes sense if the options hash exports maximum results
String 'All' - all timesteps, does not include maximum results unless included in the options hash
String 'Max' - maximum results, alternative to including maximum results in the options hash
Integer - timestep index, where 0 is the first timestep, and the last valid value is the number of timesteps - 1.
Array - array of timestep indexes, which must all be valid and cannot contain duplicates
The options hash contains the following keys:

Key	Type	Default	Description
2DZoneSQL	Array		Array of arrays, where the array contains:

0 - String - The name of the field to be exported

1 - String - The SQL expression

2 - Integer - Optional value between 0-9 inclusive, representing the number of decimal places. Default is 2.

The default is not to export any extra fields for 2D elements.
AlternativeNaming	Boolean		If this is set then the subfolders / feature datasets used for the export are given simpler but less attractive names which may be helpful if the aim is process the files with software rather than to have a user select and open them in a GIS package.

The simple names are _ with the timesteps numbered from zero as with the timesteps parameter of the method and with _Max for the maxima.

The default is to use the same naming convention as the UI.
ExportMaxima	Boolean	false	If this is set to true the maximum results are exported.
Feature Dataset	String	''	For GeoDatabases, the name of the feature dataset.
Tables	Array		Array of table names from #list_results_gis_exports_table. Must all be valid, and cannot contain duplicates.
Threshold	Float		The depth threshold below which a 2D element is not exported. This is the equivalent of checking the check-box in the UI and entering a value.

The default is to behave as though the check-box is unchecked i.e. all elements are exported.
UseArcGISCompatibility	Boolean	false	This is the equivalent of selecting the check-box in the UI.
Note: This method previously included capitalization, we recommend using the new lower case method name.
Parameters

Name	Type(s)	Description
format	String	Export format, one of shp, tab, mif, or gdb.
timesteps	String, Integer, Array, nil	See description.
options	Hash, nil	Hash of options (see description) or nil to use defaults.
folder	String	The base folder for files to be exported, or path to the .gdb if format is gdb.
results_path
#results_path ⇒ String
EXCHANGE

Returns full path for results.

Parameters

Name	Type(s)	Description
Return	String	
run
#run ⇒ void
EXCHANGE

Supported Types: ICM Sim

Runs (or re-runs) the simulation. This will block the current thread i.e. script execution will halt while this task finishes.

The simulation will be run on the current machine.

run_ex
#run_ex(*args) ⇒ void
EXCHANGE

Supported Types: ICM Sim, Risk Analysis Sim

This method is similar to #run, and is also a blocking operation. There are two versions of this method.

Single Parameter (Options Hash)
#run_ex(options) ⇒ void
This version takes a single parameter, which is an options hash containing the following keys:

Name	Type	Default	Description
Server	String	*	The name of the server the simulation may run on, or one of:

- . (period) means the local server / computer

- * (asterisk) means any available server
Threads	Integer	0	The number of threads to use, 0 indicates as many threads as possible.
SU	Boolean	false	If you are using InfoWorks One you must set this to true.
ResultsOnServer	Boolean	true	Whether to store results on server. False stores results locally.
DownloadSelection	String	ALL_RESULTS	May be "NO_RESULTS", "SUMMARY_RESULTS" or "ALL_RESULTS". Only applies to cloud databases.
Parameters

Name	Type(s)	Description
options	Hash	Options Hash. See method description
Two Parameters
#run_ex(server, number_of_threads) ⇒ void
Parameters

Name	Type(s)	Description
server	String	The name of the server the simulation may run on, or '.' (period) means the local machine, or '*' (asterisk) means any available server.
number_of_threads	Integer	The number of threads to use, 0 indicates as many threads as possible.
status
#status ⇒ String
EXCHANGE, UI

Supported Types: ICM Sim

Returns the status of a simulation.

To monitor for completion of a simulation, the recommended approach is to use the #wait_for_jobs method.

Parameters

Name	Type(s)	Description
Return	String, nil	Simulation status, one of none, active, success, or fail.
success_substatus
#success_substatus ⇒ String
EXCHANGE

Supported Types: ICM Sim

Returns the simulation substatus, if the sim was successful.

Parameters

Name	Type(s)	Description
Return	String, nil	Simulation substatus, one of incomplete, warnings, or ok - will return nil if the simulation was not successful.
timestep_count
#timestep_count ⇒ Integer
EXCHANGE

Supported Types: ICM Sim, Risk Analysis Results, Risk Analysis Sim

Returns the number of results timesteps in the simulation.

Parameters

Name	Type(s)	Description
Return	Integer

WSStructureRow
A single element (row) in a WSStructure.

Methods:

[] (Get Field)
[]= (Set Field)
[] (Get Field)
#[(field)] ⇒ Any
EXCHANGE, UI

Returns the value of the named field, which could be any data type.

puts struct_row['flow']
⇒ 42.01
Parameters

Name	Type(s)	Description
field	String	The field name.
Return	Any	The value of the field.
[]= (Set Field)
#[(field)]=(value) ⇒ void
EXCHANGE, UI

Sets the value of the named field. The value's Ruby type should be appropriate for the field, e.g. a date field requires a Ruby DateTime object.

For any changes to be saved, the parent WSStructure.write method must be used.

struct_row['date_time'] = DateTime.now
struct_row['flow'] = 42.01
Parameters

Name	Type(s)	Description
field	String	The field name.
value	Any	The value for the field, must be appropriate type to be stored in this field.

WSSWMMRunBuilder
Used to create and modify SWMM runs. Runs can be created using an existing run as a template, or created from scratch by setting all of the required parameters.

You can create an instance using the #new method and call the remaining methods.

Methods:

[] (Get Key)
[]= (Set Key)
create_new_run
get_run_mo
list_parameters
load
new
validate
[] (Get Key)
#[(key)] ⇒ Any
EXCHANGE

Gets the value of a named run parameter.

Parameters

Name	Type(s)	Description
Return	Any	
[]= (Set Key)
#[(key)]=(value) ⇒ void
EXCHANGE

Sets the value of a named run parameter.

create_new_run
#create_new_run(run_group_id) ⇒ Boolean
EXCHANGE

Creates a new run in the specified run group, using the currently set parameters.

Parameters

Name	Type(s)	Description
run_group_id	Integer	The id of a run group.
Return	Boolean	If the run was created.
get_run_mo
#get_run_mo ⇒ WSRun?
EXCHANGE

Returns the WSModelObject associated with the most recent call to either #load, #create_new_run, or #save.

list_parameters
#list_parameters ⇒ Array
EXCHANGE

Returns a list of available run parameters.

This is for information only, it does not return the current value of any parameter. These will be the same for all runs.

Parameters

Name	Type(s)	Description
Return	Array	
load
#load(run) ⇒ Boolean
EXCHANGE

Loads the parameters from an existing run.

Parameters

Name	Type(s)	Description
run	Integer, String, WSModelObject	The id, scripting path, or a wsmodelobject of the correct type (run).
Return	Boolean	If the run was successfully loaded.
new
#new ⇒ WSSWMMRunBuilder
EXCHANGE

Creates a new instance of this class.

Parameters

Name	Type(s)	Description
Return	WSSWMMRunBuilder	
validate
#validate(file) ⇒ Boolean
EXCHANGE

Validates the current run parameters, saving any validation errors to the specified file.

Parameters

Name	Type(s)	Description
file	String	A text file to save validation errors to.
Return	Boolean	If the validation was successful with no errors.

WSTableInfo
Metadata for a network table. This only contains information about the table structure, not the current values for any particular object.

Methods:

description
fields
name
results_fields
tableinfo_json
description
#description ⇒ String
EXCHANGE, UI

Returns the description of the table.

fields
#fields ⇒ Array
EXCHANGE, UI

Returns the fields of this table, as an array of WSFieldInfo objects. Flags are treated as separate fields.

name
#name ⇒ String
EXCHANGE, UI

Returns the internal name of the table.

results_fields
#results_fields ⇒ Array
EXCHANGE, UI

Returns the results fields of this table, as an array of WSFieldInfo objects.

This method is only available when the WSTableInfo object was accessed from a network with simulation results available. The fields returned will reflect the results in that simulation, including the values of their #has_time_varying_results? and #has_max_results? methods. This can vary considerably depending on the type of simulation, run configuration, results selector, etc.

tableinfo_json
#tableinfo_json ⇒ String
EXCHANGE, UI

Returns the table information as a JSON string.

WSTSDObject
A TSD object in the database, which can be opened to access the data.

WSTSDObject > WSTSDObject

Methods:

open
open
#open ⇒ WSOpenTSD
EXCHANGE

Opens the TSD object and returns a WSOpenTSD object.

Parameters

Name	Type(s)	Description
Return	WSOpenTSD

WSValidation
A single validation message.

All methods in this class are read only, and return the value of one of the fields found in the UI validation window.

Methods:

code
field
field_description
message
object_id
object_type
priority
scenario
type
code
#code ⇒ Integer
EXCHANGE, UI

Returns the code of the validation message.

field
#field ⇒ String
EXCHANGE, UI

Returns the field name. This may not be a real database field, but if it is then the actual field name rather than the description (the name used in the UI) will be returned.

puts validation.field
⇒ 'wn_node'
field_description
#field_description ⇒ String
EXCHANGE, UI

Returns the field description. The field description is how the field would appear in the UI.

puts validation.field_description
⇒ 'node'
message
#message ⇒ String
EXCHANGE, UI

Returns the text content of validation message.

object_id
#object_id ⇒ String?
EXCHANGE, UI

Returns the object ID from the validation message, if any.

object_type
#object_type ⇒ String?
EXCHANGE, UI

Returns the object type from the validation message, if any.

priority
#priority ⇒ Integer
EXCHANGE, UI

Returns the priority of the validation message.

scenario
#scenario ⇒ String
EXCHANGE, UI

Returns the scenario name for the validation message.

Parameters

Name	Type(s)	Description
Return	String	Name of the scenario, or 'base' for the base scenario.
type
#type ⇒ String
EXCHANGE, UI

Returns the type of the validation message as a string.

Parameters

Name	Type(s)	Description
Return	String	One of error, warning, or information.

WSValidations
The results generated by the validation of a network, for example from the WSOpenNetwork.validate method.

It is a collection of WSValidation objects, which each represent a validation message that would appear in the user interface.

All methods in this class are read only.

Methods:

[] (Get Index)
each
error_count
length
warning_count
[] (Get Index)
#[(index)] ⇒ WSValidation?
EXCHANGE, UI

Returns the object from the collection at the specified index.

Parameters

Name	Type(s)	Description
index	Integer	The index requested (zero-based).
Return	WSValidation, nil	The object found, or nil if there is no object at this index.
each
#each { |v| ...} ⇒ WSValidation
EXCHANGE, UI

Iterates through the collection, yielding a WSValidation object.

Examples

validations.each { |v| puts v.message }
validations.each do |v|
  puts v.message
end
error_count
#error_count ⇒ Integer
EXCHANGE, UI

Returns the number of errors found during validation.

length
#length ⇒ Integer
EXCHANGE, UI

Returns the number of validation messages.

warning_count
#warning_count ⇒ Integer
EXCHANGE, UI

Returns the number of warnings found during validation.

Add-ons
It is possible to store a CSV file containing the names of a number of scripts along with a name of a menu item to invoke them. These appear as sub-menu items of the ‘Run add-on’ menu item, which also appears on the ‘Network’ menu.

The CSV file must be stored in a directory below that used by the user’s application data named ‘scripts’ and must be called ‘scripts.csv’.

The name of the directory used by the user’s application data will vary according to the user’s set up, version of Windows etc. and can be found in the about box of the software as ‘NEP (iws) Folder’. Having found this folder e.g.

C:\Users\badgerb\AppData\Roaming\Innovyze\WorkgroupClient

Add a sub-directory called ‘scripts’.

The folder may also be determined by using the WSApplication.add_on_folder method, this will return the path of the scripts folder i.e. C:\Users\badgerb\AppData\Roaming\Innovyze\WorkgroupClient\scripts in this case.

In this scripts.csv file you should add a CSV file containing 2 columns, the first being the menu item for the script, the second the path for the script file itself.

The paths for the script files may either be fully qualified paths (i.e. beginning with a drive letter or the name of a network share) in which case that path will be used, or a non-fully qualified path in which case the software will assume the file is in the folder containing the csv file or a subdirectory of it.

Changes to this file only take effect when the application is restarted.

Character Encoding
The behaviour of strings passed into / returned by Ruby methods is determined by the WSApplication.use_utf8 setting. The default value is false.

If this setting is set to true, the methods will expect strings passed into methods to have UTF8 encoding, and will return UTF8 strings.

If this setting is set to false, the methods will expect strings passed into methods will have the locale appropriate encoding, and will return strings in that encoding.

The strings are expected to be passed in with the correct encoding - the encoding is not checked, and strings with a different encoding do not have their encoding changed.

If you are using constant strings in your Ruby scripts you will find things go much more smoothly if you use the corresponding encoding in your script. As well as ensuring that the script file is in the encoding you think it is, you need to communicate this to Ruby by setting the encoding in the first line of the script e.g

# encoding: UTF-8
Language	Encoding	Synonym
Bulgarian	Windows-1251	
Japanese	Shift_JIS	CP932
Korean	CP949	
Simplified Chinese	GBK	CP936
Turkish	Windows-1254	CP857
Western European	Windows-1252	CP1252
*	UTF-8	

Model Objects
The following model objects and corresponding short codes are used in the database.

Short codes are used when referring to a model object by it's scripting path. The Type is used by other methods e.g. WSDatabase.model_object_from_type_and_id. The Description is the name found in the user interface, which is different from the Type in some important cases.

Type	Description	ShortCode
Action List		ACTL
Alert Definition List		ADL
Alert Instance List		AIL
Asset Group		AG
Asset Network		ASSETNET
Asset Network Template		ASSETTMP
Asset Validation		ASSETVAL
Assimilation		ASSIM
Calibration		PDMC
Collection Cost Estimator		COST
Collection Inference		CINF
Collection Network		CNN
Collection Network Template		CNTMP
Collection Validation		VAL
Custom Graph		CGDT
Custom Report		CR
Damage Calculation Results		DMGCALC
Damage Function		DMGFUNC
Dashboard		DASH
Distribution Cost Estimator		WCOST
Distribution Inference		WINF
Distribution Network		NWNET
Distribution Network Template		WNTMP
Distribution Validation		WVAL
Episode Collection		EPC
Flow Survey		FS
Geo Explorer		NGX
Graph		GDT
Gridded Ground Model		GGM
Ground Infiltration		IFN
Ground Model		GM
Infinity Configuration		INFINITY
Inflow		INF
Initial Conditions 1D		IC1D
Initial Conditions 2D		IC2D
Initial Conditions Catchment		ICCA
Label List		LAB
Layer List		LL
Level		LEV
Lifetime Estimator		LIFEE
Live Group		LG
Manifest		MAN
Manifest Deployment		MAND
Master Group		MASG
Model Group		MODG
Model Inference		INFR
Model Network		NNET
Model Network Template		NNT
Model Validation		ENV
Observed Depth Event		OBD
Observed Flow Event		OBF
Observed Velocity Event		OBV
Pipe Sediment Data		PSD
Point Selection		PTSEL
Pollutant Graph		PGR
Print Layout		PTL
Rainfall Event		RAIN
Regulator		REG
Rehabilitation Planner		REHABP
Risk Analysis Run		RAR
Risk Assessment		RISK
Risk Calculation Results		RISKCALC
Run		RUN
Selection List		SEL
Sim		SIM
Sim Stats		STAT
Statistics Template		ST
Stored Query		SQL
Theme		THM
Time Varying Data		TVD
Trade Waste		TW
TSDB		TSDB
TSDB Spatial		TSDBS
UPM River Data		UPMRD
UPM Threshold		UPTHR
Waste Water		WW
Workspace		WKSP

ICM Open Data Import / Export Centre Ruby Scripts
Ruby scripting can be used to make the import / export of data via the open data import centre more streamlined for users of the software, by using Ruby scripts from the UI in conjunction with pre-prepared configuration files, and the Ruby scripting's UI elements.

At its simplest, if you can hard-code the paths of all files, then this can be done with 2 lines of code.

For import:

net=WSApplication.current_network
net.odic_import_ex('CSV','d:\temp\odic.cfg',nil,'Node','d:\temp\goat.csv','Pipe','d:\temp\stoat.csv')
For export:

net=WSApplication.current_network
net.odec_export_ex('CSV','d:\temp\odxc.cfg',nil,'Node','d:\temp\goat2.csv','Pipe','d:\temp\stoat2.csv')
As described above, both methods take a variable number of parameters. If you are importing a large number of files you may find it less unwieldy to call the method multiple times importing one file at a time e.g.

For import:

net=WSApplication.current_network
import=[['Node','goat'],['Pipe','stoat']]
import.each do |f|
  net.odic_import_ex('CSV','d:\temp\odic.cfg',nil,f[0],'d:\temp\\'+f[1]+'.csv')
end
For export:

net=WSApplication.current_network
export=[['Node','goat'],['Pipe','stoat']]
export.each do |f|
  net.odec_export_ex('CSV','d:\temp\odxc.cfg',nil,f[0],'d:\temp\\'+f[1]+'2.csv')
end
It should be noted that you will not see any of the error messages on import that would appear in the text box. Exceptions are not thrown for that sort of error, only for more serious errors in the processing. Also by using nil in the 3rd parameter of each method, default behaviour will be used for the options set on the dialog, this may not be what you want.

The first of these issues can be solved by specifying an error text file e.g.

net=WSApplication.current_network
import=[['Node','goat'],['Pipe','stoat']]
import.each do |f|
  params=Hash.new
  params['Error File']='d:\\temp\\errs'+f[0]+'.txt'
  net.odic_import_ex('CSV','d:\temp\odic.cfg',params,f[0],'d:\temp\\'+f[1]+'.csv')
end
The aim is to produce one file per table. The files will be created but of zero bytes long if there are no errors for that table.

You will probably want to communicate the errors to the user. In its simplest form this could be done by checking the size of the files and displaying a message box at the end of the process e.g.

require 'FileUtils'
net=WSApplication.current_network
import=[['Node','goatwitherrs'],['Pipe','stoat']]
errFiles=Array.new
import.each do |f|
  params=Hash.new
  errFile='d:\\temp\\errs'+f[0]+'.txt'
  params['Error File']=errFile
  net.odic_import_ex('CSV','d:\temp\odic.cfg',params,f[0],'d:\temp\\'+f[1]+'.csv')
  if File.size(errFile)>0
    errFiles 0
  msg="Errors occurred - please consult the following files:"
  errFiles.each do |f|
    msg+="\r\n"
    msg+=f
  end
  WSApplication.message_box msg,nil,nil,nil
end
Note the inclusion of FileUtils and the use of the FileUtils.rm method to delete files of zero length. This will display a message reporting to the user the error files which should be consulted.

If you wish to show the user the actual messages then this can be achieved either by reading the files and outputting them to the standard output e.g.

require 'FileUtils'
net=WSApplication.current_network
import=[['Node','goatwitherrs','nodes'],['Pipe','stoat','pipes']]
errInfo=Array.new
import.each do |f|
  params=Hash.new
  errFile='d:\\temp\\errs'+f[0]+'.txt'
  if File.exists? errFile
    FileUtils.rm errFile

  end
  params['Error File']=errFile
  net.odic_import_ex('CSV','d:\temp\odic.cfg',params,f[0],'d:\temp\\'+f[1]+'.csv')
  if File.size(errFile)>0
    temp=Array.new
    temp 0
  puts "Errors importing data:"
  errInfo.each do |ei|
    puts "Errors for #{ei[1]}:"
    outputString=''
    File.open ei[0] do |f|
      f.each_line do |l|
        l.chomp!
        outputString+=l
        outputString+="\r"
      end
    end
    puts outputString
  end
end
Or by using the open_text_view method, in which case the block beginning with if ErrInfo.size>0 would be replaced with the following:

if errInfo.size>0
  consolidatedErrFileName='d:\\temp\\allerrs.txt'
  if File.exists? consolidatedErrFileName
    FileUtils.rm consolidatedErrFileName
  end
  consolidatedFile=File.open consolidatedErrFileName,'w'
  errInfo.each do |ei|
    consolidatedFile.puts "Errors for #{ei[1]}:"
    File.open ei[0] do |f|
      f.each_line do |l|
        l.chomp!
        consolidatedFile.puts l
      end
    end
  end
  consolidatedFile.close
  WSApplication.open_text_view 'Open Data Import Centre Errors',consolidatedErrFileName,false
end
You may wish to not hard code the path of the config file but to store it with the Ruby script. This may be done by obtaining the path of the folder containing the script then adding the configuration file name onto the name e.g.

configfile=File.dirname(WSApplication.script_file)+'\\odicwithsource.cfg'
This works via the following 3 steps:

Get the file name of the script file e.g. d:\temp\myscript.rb
Use the File.dirname method to obtain the folder name e.g. d:\temp
Add the configuration file name e.g. d:\temp\odicwitsource.cfg
Alternatively you may wish to allow the user to choose a config file using the WSApplication.file_dialog method e.g. by beginning the script with

net=WSApplication.current_network
configfile=WSApplication.file_dialog(true,'cfg','Open Data Import Centre Config File',nil,false,false)
if configfile.nil?
  WSApplication.message_box 'No config file selected - no import will be performed',nil,nil,false
  exit
end
Similarly you may wish to allow the user to choose the location of the data files or database tables etc. This may be done in numerous ways depending on the data type and/or how things are structured.

Allowing the user to select a folder and then using hard-coded names based on that folder:

require 'FileUtils'
net=WSApplication.current_network
configfile=WSApplication.file_dialog(true,'cfg','Open Data Import Centre Config File',nil,false,false)
if configfile.nil?
  WSApplication.message_box 'No config file selected - no import will be performed',nil,nil,false
else
  folder=WSApplication.folder_dialog 'Select a folder containing the files to import',false
  if folder.nil?
    WSApplication.message_box 'No folder selected - no import will be performed'
  else
    import=[['Node','goatwitherrs','nodes'],['Pipe','stoat','pipes']]
    errInfo=Array.new
    import.each do |f|
      params=Hash.new
      errFile=folder+'\\errs'+f[0]+'.txt'
      if File.exists? errFile
        FileUtils.rm errFile
      end
      params['Error File']=errFile
      net.odic_import_ex('CSV',configfile,params,f[0],folder+'\\'+f[1]+'.csv')
      if File.size(errFile)>0
        temp=Array.new
        temp 0
      puts "Errors importing data:"
      errInfo.each do |ei|
        puts "Errors for #{ei[1]}:"
        outputString=''
        File.open ei[0] do |f|
          f.each_line do |l|
            l.chomp!
            outputString+=l
            outputString+="\r"
          end
        end
        puts outputString
      end
    end
  end
end
Allowing the user to choose one file and then selecting similarly named files in the same folder (e.g. if we are expecting a file with the suffix 'stoat' and we find a file called 'northwest_stoat' we will also look for files called 'northwest_goat' etc.):

require 'FileUtils'
net=WSApplication.current_network
configfile=configfile=File.dirname(WSApplication.script_file)+'\\odicwithsource.cfg'
import=[['Node','goat','nodes'],['Pipe','stoat','pipes']]
file=WSApplication.file_dialog(true,'csv','CSV File',nil,false,false)
if file.nil?
  WSApplication.message_box 'No file selected - no import will be performed','OK',nil,false
elsif file[-4..-1].downcase!='.csv'
  WSApplication.message_box 'Not a csv file - no import will be peformed','OK',nil,false
else
  folder=File.dirname(file)
  name=File.basename(file)[0..-5]
  prefix=''
  found=false
  import.each do |i|
    if name.downcase[-i[1].length..-1]==i[1].downcase
      prefixlen=name.length-i[1].length
      if prefixlen>0
        prefix=name[0..prefixlen-1]
      end
      found=true
      break
    end
  end
  if !found
    WSApplication.message_box 'File name does not have an expected suffix - no import will be performed','OK',nil,false
  else
    # errInfo is an array of arrays, with one entry added for each imported CSV file with some sort of issue
    # it will either contain the error file name and a name to be used for the table in error messages
    # or nil and a filename for any expected files which are missing
    errInfo=Array.new
    import.each do |f|
      csvfilename=folder+'\\'+prefix+f[1]+'.csv'
      if !File.exists? csvfilename
        temp=Array.new
        temp 0
          temp=Array.new
          temp 0
      puts "Errors importing data:"
      errInfo.each do |ei|
        if ei[0].nil?
          puts "Expected file #{ei[1]} not found"
        else
          puts "Errors for #{ei[1]}:"
          outputString=''
          File.open ei[0] do |f|
            f.each_line do |l|
              l.chomp!
              outputString+=l
              outputString+="\r"
            end
          end
          puts outputString
        end
      end
    end
end
Allowing the user to select multiple files and choosing the data type to import based on the file names:

require 'FileUtils'
net=WSApplication.current_network
configfile=configfile=File.dirname(WSApplication.script_file)+'\\odicwithsource.cfg'
import=[['Node','goat','nodes'],['Pipe','stoat','pipes']]
files=WSApplication.file_dialog(true,'csv','CSV File',nil,true,false)
if files.nil? || files.length==0
  WSApplication.message_box 'No file selected - no import will be performed','OK',nil,false
else
  nErrs=0
  errInfo=Array.new
  files.each do |file|
    folder=File.dirname(file)
    name=File.basename(file)
    if name[-4..-1].downcase=='.csv'
      name=name[0..-5]
      import.each do |i|
        if i[1].downcase==name.downcase[-i[1].length..-1]
          params=Hash.new
          nErrs+=1
                    errFile=folder+'\\errs'+nErrs.to_s+'.txt'
          if File.exists? errFile
            FileUtils.rm errFile
          end
          params['Error File']=errFile
      net.odic_import_ex('CSV',configfile,params,i[0],file)
          if File.size(errFile)>0
            temp=Array.new
            temp 0
    puts "Errors importing data:"
    errInfo.each do |ei|
      if ei[0].nil?
        puts "Expected file #{ei[1]} not found"
      else
        puts "Errors for #{ei[1]}:"
        outputString=''
        File.open ei[0] do |f|
          f.each_line do |l|
            l.chomp!
            outputString+=l
            outputString+="\r"
          end
        end
        puts outputString
      end
    end
  end
end

Pollutograph Codes
The following is a list of pollutograph codes used in InfoWorks ICM.

Code
P2D
P2A
P1D
P1A
NHD
COD
COA
PH_
SAL
NO3
NO2
DO_
COL
TW_
BOD
TPD
TPA
TKD
TKA
SF2
SF1
P4D
P4A
P3D
P3A
BOA

Run Parameters
Run parameters are set as key value pairs for the WSModelObject.new_run method, called on the asset group in which the run is being created.

The run parameters used for ICM Exchange broadly correspond to those in the user interface run dialog. The list below therefore includes the field’s location in the run dialog and its sub-dialogs, and its description in the user interface if the difference is noteworthy.

InfoWorks Run Parameters
Name	Data Type	Location in UI	Description in UI	Notes	Default	Nil	Range
Always Use Final State	Boolean	Main page col 2	Always use state without initialization				
Buildup Time	Long Integer	Water Quality Form		Can either be nil (in which case it is not used) or a value between 1 and 1000000			
CheckPumps	Boolean	Timestep Control Sheet - Control Page					
Comment	String	Tree object property page					
ConcentrationWarning	Double	Diagnostics Form	Concentration				
Depth	Double	2D Sheet, Tolerance Tab		Must be less then Innundation Map Dept hThreshold		0.001	0 - 99999999
Depth_threshold	Double	2d Sheet, Steady State Tab	Threshold for 1-hour change in depth				
DontApplyRainfallSmoothing	Boolean	Main Page col 2		This is the opposite sense to the check box on the dialog		TRUE	
DontLogModeSwitches	Boolean	Diagnostics Form		This is the opposite sense to the check box on the dialog			
DontLogRTCRuleChanges	Boolean	Diagnostics Form		This is the opposite sense to the check box on the dialog			
DontOutputRTCState	Boolean	Diagnostics Form		This is the opposite sense to the check box on the dialog			
Duration	Long Integer	Main Page col 1		Duration of simulation, in units used in duration unit	60		
DurationUnit	String	Main Page col 1		The DurationType field must be nil or one of the strings:

'Minutes', 'Hours', 'Days', 'Weeks', 'Years'.

It is important to realise that the value of this field does NOT affect the meaning of the Duration field, which is always in minutes, it merely affects the way the duration is displayed e.g. to run a simulation for a day, and have the time in the run view displayed as '1 day' you should enter the values 1440 in the Duration fields and 'Days' in the DurationType field.			
DWFDefinition	String	Timestep Control Sheet - RTC Page	DWF Mode Definition				
DWFModeResults	Boolean	Timestep Control Sheet - Control Page	Store results when in DWF mode				
DWFMultiplier	Long Integer	Timestep Control Sheet - Control Page		Must be a power of 2	32		1 - 2048
End Duration	Boolean	Main Page col 1		True for time/date, false for duration			
End Time	Double / DateTime	Main Page col 1		See Notes			
EveryNode	Boolean	Timestep Control Sheet - Node Page		True = Total flow into system, False = flow at each node	FALSE		
EveryOutflow	Boolean	Timestep Control Sheet - Outflows Page		True = Total flow from system, False = flow at each outfall	FALSE		
EverySubcatchment	Boolean	Timestep Control Sheet - Subcatchment Page		True = Total flow into system, False = flow at each subcatchment	FALSE		
ExitOnFailedInit	Boolean	Main Page col 2		Exit if initialization fails			
ExitOnFailedInitCompletion	Boolean	Main Page col 2	Exit if initialization complete in (mins)	If the ExitOnFailedInitCompletion field is set to true, the InitCompletionMinutes field must be set to a value between 1 and 99999999			
GaugeMultiplier	Long Integer	Main Page col 1		Gauge timestep multiplier	1		0 - 99999
Gauges	Index	Main Page col 1	Additional links to be gauged	A selection list object			
GetStartTimeFromRainEvent	Boolean	Main Page col 2					
Ground Infiltration	Index	Main Page col 3		Ground Infiltration object used for simulation			
IncludeBaseFlow	Boolean	Timestep Control Sheet - Subcatchments Page	Include Base Flow		FALSE		
IncludeLevel	Boolean	Timestep Control Sheet - Level Page	Check for levels		FALSE		
IncludeNode	Boolean	Timestep Control Sheet - Node Page	Check for inflows		FALSE		
IncludeOutflow	Boolean	Timestep Control Sheet - Outflows Page	Check for ouflows		FALSE		
IncludeRainfall	Boolean	Timestep Control Sheet - Rainfall Page	Check for rainfall		FALSE		
IncludeRTC	Boolean	Timestep Control Sheet - RTC Page	Check RTC				
IncludeRunoff	Boolean	Timestep Control Sheet - Subcatchments Page	Include Runoff		FALSE		
Inflow	Index	Main Page col 3		Inflow object used for simulation			
InitCompletionMinutes	Long Integer	Main page col 2					
Initial Conditions 2D	Index	Main Page col 3		2D Initial conditions object used for simulation			
InundationMapDepthThreshold	Double	2D Sheet, Advanced Tab		See Depth		0.01	0 - inf
Level	Index	Main Page col 3		Level object used for simulation			
LevelLag	Long Integer	Timestep Control Sheet - Level Page			0		
LevelThreshold	Double	Timestep Control Sheet - Level Page			0		0 - 99999999
MaxVelocity	Double	2D Sheet, Advanced Tab				10	0 - 99999999
Minor Timestep 2D	Boolean	2D Sheet, Advanced Tab	Link 1D-2D calculations at minor timestep				
Momentum	Double	2D Sheet, Tolerance Tab				0.01	0 - 99999999
NodeLag	Long Integer	Timestep Control Sheet - Node Page			0		
NodeThreshold	Double	Timestep Control Sheet - Node Page			0		
OutflowLag	Long Integer	Timestep Control Sheet - Outflows Page			0		
OutflowThreshold	Double	Timestep Control Sheet - Outflows Page			0		
Pipe Sediment Data	Index	Main Page col 3		Pipe sediment data object used fo simulation			
Pollutant Graph	Index	Main Page col 3		Pollutant graph object used for simulation			
QM Dependent Fractions	Boolean	Water Quality Form	Dependent Sediment Fractions				
QM Hydraulic Feedback	Boolean	Water Quality Form	Erosion Deposition Affects Hydraulics				
QM Model Macrophytes	Boolean	Water Quality Form					
QM Multiplier	Long Integer	Water Quality Form					0 - 10
QM Native Washoff Routing	Boolean	Water Quality Form					
QM Oxygen Demand	Text	Water Quality Form				BOD	
QM Pollutant Enabled	Array			This is an array of strings			
RainfallLag	Long Integer	Timestep Control Sheet - Rainfall Page			0		
RainfallThreshold	Double	Timestep Control Sheet - Rainfall Page			0		
RainType	Boolean	2D Sheet, Advanced Tab	Ignore rain falling on dry elements		FALSE		
ReadSubeventNAPIAndAntecedDepth	Boolean	Main Page col 2	Read subevent NAPI and Antecdent Depth				
ReadSubeventParams	Boolean	Main Page col 2	Read subevent UCWI & Evaporation				
Regulator	Index	Main Page col 2		Regulator object used for simulation			
ResultsMultiplier	Long Integer	Main Page col 1			6	Results timestep multiplier	0 - 99999
RTCLag	Long Integer	Timestep Control Sheet - RTC Page			0		0 - 99999999
RTCRulesOverride	Boolean	Main Page col 2	RTC rules override pump on levels			Restrictions as in UI	
RunoffOnly	Boolean	Main Page col 2		Restrictions as in UI			
Save Final State	Boolean	Main Page col 2					
Sediment Fraction Enabled	Array			This parameter must be an array of 2 Boolean values, true if you want that sediment fraction and false if you don't			
Sim	Index	Main Page col 2		Sim object used for the initial state			
SpillCorrection	Boolean	2D Sheet, Advanced Tab	Adjust bank levels based on adjacent element ground levels			TRUE	
Start Time	Double / DateTime	Main Page col 1		See notes	0		
StopOnEndOfTimeVaryingData	Boolean	Timestep Control Sheet - Control Page	Stop simulation at the end of tim varying data				
StorePRN	Boolean	Main Page col 2	Summary (PRN) results				
StormDefinition	String	Timestep Control Sheet - RTC Page		Storm Mode Condition			
SubcatchmentLag	Long Integer	Timestep Control Sheet - Subcatchments Page			0		
SubcatchmentThreshold	Double	Timestep Control Sheet - Subcatchments Page			0		
Theta	Double	2D Sheet, Advanced Tab				0.9	0 - 99999999
Time_lag	Double	2d Sheet, Steady State Tab				60	
TimeStep	Long Integer	Main Page col 1	Timestep (s)		60		1 - 99999
timestep_stability_control	Double	2D Sheet, Advanced Tab				0.95	0 - 1
TimestepLog	Boolean	Diagnostics Form					
Trade Waste	Index	Main Page col 3		Trade Waste object used for simulation			
Use_local_steady_state	Boolean	2d Sheet, Steady State Tab	Deactivate steady state areas				
UseGPU	Boolean	Main Page col 3		0 or nil = never, 1 = if available, 2 = always			
UseQM	Boolean	Main Page col 3					
Velocity	Double	2D Sheet, Tolerance Tab				0.01	0 - 99999999
Velocity_threshold	Double	2d Sheet, Steady State Tab	Threshold for 1-hour change in velocity				
VelocityWarning	Double	Diagnostics Form	Velocity				
VolumeBalanceWarning	Double	Diagnostics Form	Volume balance				
WarningBag	Hash			Warning thresholds for water priority parameters. It is a hash from strings to floating point numbers. The keys are as described in the 'QM Pollutant Enabled' key, and as with that key the best way to understand this parameter is to set up values in the UI and export them in a script.			
Waste Water	Index	Main Page col 3	Waste Water object used for simulation				
Working	Boolean	Main Page col 1	Allow re-runs using updated network	Must be set to tru before the update_to_latest method may be used.			
SWMM Run Parameters
Name	Data Type	Location in UI	Description in UI	Notes	Default	Range
climatology	Index	Main page col 3	SWMM climatology	SWMM Climatology object used in simulation		
date_time_end_date	DateTime	Timestep Control Sheet - Dates Page	End analysis		Current date + 1 day at time 00:00:00	
date_time_end_sweep	DateTime	Timestep Control Sheet - Dates Page	End sweeping	The year and time are ignored	31 Dec	
date_time_report_start	DateTime	Timestep Control Sheet - Dates Page	Start reporting		Current date at time 00:00:00	
date_time_start_date	DateTime	Timestep Control Sheet - Dates Page	Start analysis		Current date at time 00:00:00	
date_time_start_sweep	DateTime	Timestep Control Sheet - Dates Page	Start sweeping	The year and time are ignored	01 Jan	
dry_days	Float	Timestep Control Sheet - Dates Page	Antecedent dry days	Must be zero or a positive float value.	0.0	
dyn_wave_length_step	Float	Main Page col 4 - Dynamic wave group box	Conduit lengthening timestep		0.0	
dyn_wave_minimum_step	Float	Main Page col 4 - Dynamic wave group box	Minimum timestep		0.5	
dyn_wave_use_var_step	Boolean	Main Page col 4 - Dynamic wave group box	Adjust variable timesteps by (%) - checkbox		TRUE	
dyn_wave_variable_step	Float	Main Page col 4 - Dynamic wave group box	Adjust variable timesteps by (%) - edit box		75.0	10.0 – 200.0
inflow	Index	Main Page col 2	Inflow	Inflow object used in simulation		
initial_state_sim	Index	Main Page col 1	Sim providing initial state	The simulation object that provides the initial state to host-start the simulation. The simulation providing state must have saved its state and its simulation succeeded.		
level	Index	Main Page col 2	Level	Level object used in simulation		
name	String	Top of main Page	Run title	If the name is Nil then one is randomly generated		
network	Index	Main Page col 1 - Network group box	SWMM network	Network object used in simulation		
network_commit_id	Long Integer	Main Page col 1 - Network group box	SWMM network	Network commit ID or version number used in simulation that appears in parenthesis following the network name		
pollutographs	Array of Index	Main Page col 3	SWMM pollutograph			
proc_parm_gw	Boolean	Options Sheet - Processes Page	Groundwater		TRUE	
proc_parm_rain	Boolean	Options Sheet - Processes Page	Rainfall / runoff		TRUE	
proc_parm_rdii	Boolean	Options Sheet - Processes Page	Rainfall dependent I/I		TRUE	
proc_parm_route	Boolean	Options Sheet - Processes Page	Flow routing		TRUE	
proc_parm_snow	Boolean	Options Sheet - Processes Page	Snowmelt		TRUE	
proc_parm_wq	Boolean	Options Sheet - Processes Page	Water quality		TRUE	
rainfall	Index	Main Page col 2	Rainfall event / Flow survey	Rainfall or flow survey object used in simulation		
regulator	Index	Main Page col 2	Regulator	Regulator object used in simulation		
rpt_parm_averages	Boolean	Main Page col 4 - Reporting group box	Average results		FALSE	
rpt_parm_continue	Boolean	Main Page col 4 - Reporting group box	Continuity checks		TRUE	
rpt_parm_controls	Boolean	Main Page col 4 - Reporting group box	Control actions		FALSE	
rpt_parm_det_obj_id	Array of Index	Main Page col 4 - Reporting group box	Objects for detailed reporting - Selection list			
rpt_parm_flow_stats	Boolean	Main Page col 4 - Reporting group box	Summary flow statistics		TRUE	
rpt_parm_input	Boolean	Main Page col 4 - Reporting group box	Input summary		FALSE	
save_state_at_end	Boolean	Main Page col 1	Save state at end of simulation		FALSE	
scenarios	Array of String	Main Page col 1 - Network group box	Scenarios			
stdy_flow_lat_tol	Float	Timestep Control Sheet - Timesteps Page - Steady flow periods group box	Lateral flow tolerance (%)		5.0	
stdy_flow_skip_stdy_state	Boolean	Timestep Control Sheet - Timesteps Page - Steady flow periods group box	Skip steady flow periods		FALSE	
stdy_flow_sys_tol	Float	Timestep Control Sheet - Timesteps Page - Steady flow periods group box	System flow tolerance (%)		5.0	
surcharge_method_type	String	Options Sheet - Surcharge Method Page	Surcharge Method		Must be either 'Extran' or 'Slot'.	
time_pattern	Index	Main Page col 3	SWMM time patterns	SWMM time pattern object used for simulation.		
time_step_control	Float	Timestep control sheet - Timesteps Page	Control rule step	Relative time in seconds. Must be a negative value.	0.0	
time_step_dry	Float	Timestep control sheet - Timesteps Page	Dry weather runoff step	Relative time in seconds. Must be a negative value.	-3600.0	
time_step_report	Float	Timestep control sheet - Timesteps Page	Reporting timestep	Relative time in seconds that timesteps are reported. Must be a negative value.	-900.0	
time_step_route	Float	Timestep control sheet - Timesteps Page	Routing timestep (s)	Unlike other time_steps, this is an explicit number of seconds.	30.0	
time_step_wet	Float	Timestep control sheet - Timesteps Page	Wet weather runoff step	Relative time in seconds. Must be a negative value.	-300.0	
working	Boolean	Main Page col 1	Allow re-runs using updated network	Must be set to true before the update_to_latest method may be used.	FALSE	
Notes
The keys are all strings, the values are different types as specified.

Where values have units, they must always be specified in S.I units.

When the run is created, several run parameters are supplied with default values. For example, if you create a run and use an empty parameters hash, then use the [] method on the run to inspect the values, you would see that several fields have default values set.

Other fields will use a nil value by default. For a number of fields a nil value is treated as a particular default value for that field as specified in the detailed notes for the fields in question.

Where the name of the field contains spaces or underscores, the spaces or underscores must be used when setting the value in the hash.

The percentage volume balance is not available from ICM Exchange.

Time
As ICM Exchange does not have a Ruby data time to represent the use of times in ICM simulations, in which both relative times and absolute times are used, the following convention is used for the start time and end time:

- Absolute times are represented as a DateTime object
- Relative times as a negative double – a time in seconds
Therefore to set a relative time, negate the number of seconds and set the field to this value, to set an absolute time use a ruby DateTime object as described earlier in this document.

When reading a value from the database to determine whether the start time is relative of absolute you will want to use code like this:

start_time = working['Start Time']

if start_time.nil?
  puts "nil"
elsif start_time.kind_of?(DateTime)
  puts format("Absolute: %i/%i/%i", start_time.year, start_time.month, start_time.day)
elsif start_time.kind_of(Float)
  puts format("Relative: %f seconds", start_time)
else
  puts "Unexpected type"
end

Network Tables
Model Network Tables
Description	Table
2D boundary	hw_2d_boundary_line
2D point source	hw_2d_point_source
2D zone	hw_2d_zone
2D zone defaults	hw_2d_zone_defaults
Bank line	hw_bank_survey
Base linear structure (2D)	hw_2d_linear_structure
Bridge	hw_bridge
Bridge inlet	hw_bridge_inlet
Bridge opening	hw_bridge_opening
Bridge outlet	hw_bridge_outlet
Channel	hw_channel
Channel defaults	hw_channel_defaults
Channel shape	hw_channel_shape
Conduit	hw_conduit
Conduit defaults	hw_conduit_defaults
Cross section line	hw_cross_section_survey
Culvert inlet	hw_culvert_inlet
Culvert outlet	hw_culvert_outlet
Flap valve	hw_flap_valve
Flow efficiency	hw_flow_efficiency
Flume	hw_flume
General line	hw_general_line
General point	hw_general_point
Ground infiltration	hw_ground_infiltration
Head discharge	hw_head_discharge
Headloss curve	hw_headloss
IC zone - hydraulics (2D)	hw_2d_ic_polygon
IC zone - infiltration (2D)	hw_2d_inf_ic_polygon
IC zone - water quality (2D)	hw_2d_wq_ic_polygon
Infiltration surface (2D)	hw_2d_infil_surface
Infiltration zone (2D)	hw_2d_infiltration_zone
Inline bank	hw_inline_bank
Irregular weir	hw_irregular_weir
Land use	hw_land_use
Large catchment parameters	hw_large_catchment_parameters
Mesh zone	hw_mesh_zone
Network results line (2D)	hw_2d_results_line
Network results point (1D)	hw_1d_results_point
Network results point (2D)	hw_2d_results_point
Network results polygon (2D)	hw_2d_results_polygon
Node	hw_node
Node defaults	hw_manhole_defaults
Orifice	hw_orifice
Polygon	hw_polygon
Porous polygon	hw_porous_polygon
Porous wall	hw_porous_wall
Pump	hw_pump
RTC data	hw_rtc
RTK hydrograph	hw_unit_hydrograph
River defaults	hw_river_reach_defaults
River reach	hw_river_reach
Roughness zone	hw_roughness_zone
Runoff surface	hw_runoff_surface
Screen	hw_screen
Shape	hw_shape
Sim parameters	hw_sim_parameters
Siphon	hw_siphon
Sluice	hw_sluice
Sluice linear structure (2D)	hw_2d_sluice
Snow pack	hw_snow_pack
Snow parameters	hw_snow_parameters
Storage area	hw_storage_area
Subcatchment	hw_subcatchment
Subcatchment defaults	hw_subcatchment_defaults
User control	hw_user_control
Water quality parameters	hw_wq_params
Weir	hw_weir
Collection Network Tables
Description	Table
Approval level	cams_approval_level
Blockage incident	cams_incident_blockage
CCTV survey	cams_cctv_survey
Channel	cams_channel
Collapse incident	cams_incident_collapse
Connection node	cams_connection_node
Connection pipe	cams_connection_pipe
Connection pipe name group	cams_name_group_connection_pipe
Cross section survey	cams_cross_section_survey
Customer complaint	cams_incident_complaint
Data logger	cams_data_logger
Defence area	cams_defence_area
Defence structure	cams_defence_structure
Drain test	cams_drain_test
Dye test	cams_dye_test
FOG inspection	cams_fog_inspection
Flooding incident	cams_incident_flooding
Flume	cams_flume
GPS survey	cams_gps_survey
General asset	cams_general_asset
General incident	cams_incident_general
General line	cams_general_line
General maintenance	cams_general_maintenance
General survey	cams_general_survey
General survey line	cams_general_survey_line
Generator	cams_generator
Manhole repair	cams_manhole_repair
Manhole survey	cams_manhole_survey
Material	cams_material
Monitoring survey	cams_mon_survey
Node	cams_manhole
Node name group	cams_name_group_node
Odor incident	cams_incident_odor
Order	cams_order
Orifice	cams_orifice
Outlet	cams_outlet
Pipe	cams_pipe
Pipe clean	cams_pipe_clean
Pipe name group	cams_name_group_pipe
Pipe repair	cams_pipe_repair
Pollution incident	cams_incident_pollution
Property	cams_property
Pump	cams_pump
Pump station	cams_pump_station
Pump station electrical maintenance	cams_pump_station_em
Pump station mechanical maintenance	cams_pump_station_mm
Pump station survey	cams_pump_station_survey
Resource	cams_resource
Screen	cams_screen
Siphon	cams_siphon
Sluice	cams_sluice
Smoke defect observation	cams_smoke_defect
Smoke test	cams_smoke_test
Storage area	cams_storage
Treatment works	cams_wtw
User ancillary	cams_ancillary
Valve	cams_valve
Vortex	cams_vortex
Weir	cams_weir
Zone	cams_zone
Distribution Network Tables
Description	Table
Approval level	wams_approval_level
Borehole	wams_borehole
Burst incident	wams_incident_burst
Customer complaint	wams_incident_complaint
Data logger	wams_data_logger
Fitting	wams_fitting
GPS survey	wams_gps_survey
General asset	wams_general_asset
General incident	wams_incident_general
General line	wams_general_line
General maintenance	wams_general_maintenance
General survey	wams_general_survey
General survey line	wams_general_survey_line
Generator	wams_generator
Hydrant	wams_hydrant
Hydrant maintenance	wams_hydrant_maintenance
Hydrant test	wams_hydrant_test
Leak detection	wams_leak_detection
Manhole	wams_manhole
Manhole repair	wams_manhole_repair
Manhole survey	wams_manhole_survey
Material	wams_material
Meter	wams_meter
Meter maintenance	wams_meter_maintenance
Meter test	wams_meter_test
Monitoring survey	wams_mon_survey
Node name group	wams_name_group_node
Order	wams_order
Pipe	wams_pipe
Pipe name group	wams_name_group_pipe
Pipe repair	wams_pipe_repair
Pipe sample	wams_pipe_sample
Property	wams_property
Pump	wams_pump
Pump station	wams_pump_station
Pump station electrical maintenance	wams_pump_station_em
Pump station mechanical maintenance	wams_pump_station_mm
Pump station survey	wams_pump_station_survey
Resource	wams_resource
Surface source	wams_surface_source
Tank	wams_tank
Treatment works	wams_wtw
Valve	wams_valve
Valve maintenance	wams_valve_maintenance
Water quality incident	wams_incident_wq
Zone	wams_zone

Ruby Script Editor
This editor lets you view and edit a Ruby script, validate its syntax and run the script in the current network in the GeoPlan.

It is displayed when you open a Ruby script.

Note: Dropping a Ruby script into the current network, rather than the background, runs the script without opening the editor.

Editor description
Item	Description
Content pane	Displays the Ruby script code.
Note: This pane is empty for a new Ruby script so you can add the relevant code. See Introduction to Ruby Scripting in InfoWorks for general information about using Ruby scripting in InfoWorks ICM.
Tip: Basic editing functions such as copy and paste are available from a right-click popup menu.
Run	Runs the Ruby script in the current network and exports all Ruby scripts in the Model or Live group to your local working folder.
If the Ruby script uses the require_relative command to reference other scripts in the Model or Live group, these are run in the order they are listed in the opened script.

If run successfully, a Script output window is displayed, listing the changes that have been applied.

Otherwise, a message is displayed that indicates the likely error and the name of the file that the 'failed' script is exported to.

Save	Enabled when you edit the script.
Saves any changes and closes the editor.

Parent topic: Ruby Script