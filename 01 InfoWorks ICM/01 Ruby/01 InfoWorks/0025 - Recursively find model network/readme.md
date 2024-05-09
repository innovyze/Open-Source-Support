# Recursively find model network

This script is designed to list all the "Model Network" objects in a standalone InfoWorks ICM database.

## How it Works

1. The script first determines the directory of the current script file.
2. It then sets the name of the standalone database to open and constructs the full path to the database file.
3. The specified database is opened without making it the active database.
4. It then creates an empty array, $toProcess, to hold the objects to be processed.
5. It adds all root model objects in the database to the $toProcess array.
6. It then enters a loop that continues until all objects have been processed. In each iteration of the loop:
    a. It removes the first object from the $toProcess array and sets it as the current object to process.
    b. If the current object is a "Model Network" object, it prints the name and path of the object.
    c. It then adds all children of the current object to the $toProcess array for future processing.
7. The loop continues until the $toProcess array is empty, meaning all objects in the database have been processed.