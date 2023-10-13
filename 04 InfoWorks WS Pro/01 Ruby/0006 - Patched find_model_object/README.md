# WSDatabase.find_model_object method patch

In Infoworks WS Pro version 2024.2 and above, the `WSDatabase.find_model_object` method has been deprecated as it was no longer supported with Workgroup databases. This is because Workgroup databases do not enforce unique names for model objects, so the method could not return a single unique reference reliably.

If you are writing a new script, we recommend finding an alternative approach due to the potential for duplicate names in the database. However, this demonstrate two ways to fix existing scripts without needing to many any significant changes.

## Script 1 - find_model_object.rb

This is the recommended approach.

You can `require` this script, and use the provided method to replace any existing use of the `find_model_object` method:

`#find_model_object_in_database(database, type, name) -> WSModelObject?`

Where the first argument is the WSDatabase object, and the second/third match the original method. For example:

```ruby
# Original
network = db.find_model_object('Geometry', 'MyNetwork')

# New
network = find_model_object_in_database(db, 'Geometry', 'MyNetwork')
```

## Script 2 - wsdatabase_patch.rb

This is not a recommended approach, as it uses a Ruby technique known as 'monkey-patching' to re-implement the `WSDatabase.find_model_object` method. This means that it can be used as a 'drop in' fix with no other modifications, which may be useful as a temporary fix or when dealing with more complex scripts.

You can `require` this script before any other part of the script needs to use the `WSDatabase.find_model_object`. This way, wherever that method is used in your script, it will use the patched version instead.

A slightly safer way to implement the patch is to rename the method from `find_model_object` to `find_model_object_patched`, and then change all occurrences in your script to match. This way it will not patch the existing method, but simply add an additional method to the class, which is more in line with Ruby best practices.
