# Ruby Script: Subcatchment Copy Generator for ICM InfoWorks

This script is used to create multiple copies of selected subcatchments in an InfoWorks ICM application.

## Steps

1. The script first accesses the current network in the application.

2. It asks the user for the number of copies they want to create.

3. The script then iterates over each subcatchment in the current network. If the subcatchment is selected, it proceeds to create the specified number of copies.

4. For each copy, the script does the following:
   - Starts a transaction. This allows all changes to be committed at once at the end of the script.
   - Creates a new subcatchment object.
   - Names the new subcatchment with a "_c_<number>" suffix, where <number> is the copy number.
   - Iterates over each field in the subcatchment. If the field is not the subcatchment name, it copies the field value from the original subcatchment to the new subcatchment.
   - Writes the changes to the new subcatchment.
   - Ends the transaction, making all changes permanent.

## Ruby Code

```ruby
# ... (code omitted for brevity)

# usage example
net = WSApplication.current_network
# ... (code omitted for brevity)