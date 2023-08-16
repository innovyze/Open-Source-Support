# Interactive Exchange Terminal in VS Code
Interactive Exchange is a workflow developed for VS Code to make the development of Ruby scripts for Exchange easier. This workflow leverages VS Code's 'task' functionality to run a Ruby script in Exchange without defining a bat file and then create an interactive terminal to access Ruby script variables. Interactive terminal can also be used to give one-line commands to Exchange, while having access to variables from the Ruby script (something similar to an interactive Python IDE or Interactive Ruby (irb) ).

![](gif004.gif)

#### Note: Multi-line Ruby commands like loops, each statement, if/else statements, def, etc. are not supported by the interactive terminal described in this workflow.

This workflow does the following:
1. Uses VS Code 'tasks' to run exchange scripts in terminal, therefore eliminating the need for creating or running a bat file in the development phase.
2. Gives the user access to script variables after the script is executed in exchange, so that the user can interactively play with the script variables.

## How to use?
1. Download relevant files from GitHub ('hello_world.rb', '.vscode', 'repl.rb', 'task.json').
2. Copy files to your project folder without changing the folder structure ('hello_world.rb' is optional, 'hello_world.rb can be replaced with any other ruby script).
3. Open VS code and navigate to "File>Open Folder". In the pop-up dialog box, select the folder where you copied 'hello_world.rb' ruby script and '.vscode' folder in step 2.

![](gif001.gif)

4. The folder selected in step 3 will be considered a workspace folder by VS Code. 
5. Within the current workspace folder, locate '.vcode/tasks.json' file. Edit line 20 of 'tasks.json' file and replace it with the complete path of 'ICMExchange.exe'/'IExchange.exe'(these execuatables will be in the same location as your ICM/WS Pro installation).

![](gif002.gif)

6. Using the VS Code explorer window, open any Ruby script within the workspace folder.
7. Press ctrl+shift+b and select the "Run Ruby" task to run the Ruby script that you have currently opened in VS code.
8. Once the script is executed, the terminal will prompt with the message "Exchange>>>" and it will wait for user input. The user can give input to the terminal and also access the script variables through the terminal.

![](gif003.gif)

9. Delete the terminal before executing a new instance of the task or type "Exit" in the interactive Exchange terminal.