# Access link geometry data

The provided script does the following:

1. Access the Current Network:
- It retrieves the currently open network in the application using WSApplication.current_network.
2. Prepare an Array for Data Storage:
-An empty array named data is initialized to hold the information.
3. Iterate Over Row Objects:
- The script accesses all row objects within the _links table of the network.
- For each row object (ro), it extracts the id and joins the elements of the point_array into a single string, separated by commas.
- This combined data (id and joined point_array) is then appended to the data array.
4. Print the Data:
- The script iterates over the data array and prints each row in the format id: point_array.

In summary, the script iterates through all row objects in the _links table of the open network, collects their id and point_array values, and prints them to the console in a formatted manner.