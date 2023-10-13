# Alternative to using #WSDatabase.find_model_object. Attempts to find a unique model object
# of a given type and name in the database. Raises an exception if more than 1 match is found.
#
# @param database [WSDatabase] database object
# @param type [String] model object type (e.g. 'Geometry')
# @param name [String] model object name, not case sensitive
# @return [WSModelObject, nil] the model object if a single unique reference was found, nil if nothing was found
def find_model_object(database, type, name)
  matches = Array.new
  objects = database.model_object_collection(type)
  objects.each { |object| matches << object if object.name.casecmp?(name) }

  raise "Found #{matches.size} model objects of type #{type} with name #{name} in database" if matches.size > 1

  return (matches.size > 1) ? nil : matches.first
end
