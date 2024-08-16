# Ruby Script for Validating Flags in InfoWorks ICM

This Ruby script is used to validate flags in the InfoWorks ICM software. Here's a summary of what it does:

- It first sets up the current network (`$on`) and defines a validation array (`$valid_arr`) with the valid flag values.

- It then initializes an empty array (`$arr`) to hold the flag values found in the network.

- It iterates over each table in the network.

- For each table, it retrieves the fields and iterates over each field.

- For each field, it checks if the field name matches the pattern `/_flag/`.

- If the field name matches the pattern, it iterates over each row object in the table.

- For each row object, it checks if the value of the flag field is not empty.

- If the value of the flag field is not empty, it adds the value to the `$arr` array.

- After iterating over all tables, it subtracts the `$valid_arr` array from the `$arr` array to get an array of flag values that are not part of the validation list (`$validation`).

- Finally, it prints the flag values that are not part of the validation list.