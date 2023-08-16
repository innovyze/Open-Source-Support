# Interactive Exchange in VS Code
This workflow does below things
1. Gives user access to script variable after the script is executed in exchange, so that user can interactively play with the script variables.
2. Uses VS Code 'tasks' to run exchange scripts in terminal, therefore eliminating the need for creating/running bat file in development phase.

## How to use?
1. Download relevant files from GitHub ('hello_world.rb', '.vscode', 'repl.rb', 'task.json').
2. Copy files to your project folder without changing the folder structure ('hello_world.rb' is optional, 'hello_world.rb can be replaced with any other ruby script).
3. Open VS code and navigate to "File>Open Folder". In pop-up dialog box select folder where you copied 'hello_world.rb' ruby script and '.vscode' folder in step 2.

![](gif001.gif)

4. Folder selected in step 3 will be considered as workspace folder by VS Code.
5. Within the current workspace folder locate '.vcode/tasks.json' file. Edit line 20 of 'tasks.json' file and replace it with complete path of 'ICMExchange.exe'/'IExchange.exe'(these execuatables will be in same location as your ICM/WS Pro installation).
![](gif002.gif)
6. Using VS Code explorer window open any ruby script within the workspace folder. 
7. Press ctrl+shift+b and select "Run Ruby" task to run the ruby script which you have opened.
8. Once the script is executed, terminal will prompt with message "Exchange>>>" and it will wait for user input. User can give input to the terminal and also access the script variables through terminal.
![](gif003.gif)
9. Delete the terminal before executing new instance of the task.