# Check simulation status (ICM Binary)

This script is designed to retrieve and display the status and success substatus of two specific simulation objects from a database. It also includes a function to pause the script and wait for the user to press a key before continuing.

## How it Works

1. The script defines a function, continue_story, that prompts the user to press any key to continue. It does this by printing a message, waiting for a key press, and then printing spaces to clear the message.

2. It opens a specific database located on a server.

3. It selects two specific simulation objects from the database using their IDs.

4. It retrieves the status and success substatus of each simulation object.

5. It prints the status and success substatus of each simulation object.

6. Finally, it calls the continue_story function to pause the script and wait for the user to press a key before continuing.