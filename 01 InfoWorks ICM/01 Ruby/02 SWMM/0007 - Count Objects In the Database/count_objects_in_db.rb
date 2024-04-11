DEPTH_LIMIT = 9999

# Get the current user
user = ENV['USER'] || ENV['USERNAME']
print "0007 - Count Objects In the Database...", user
puts ' '

# Recursive method to count the number of objects
#
# @param mo [WSModelObject]
# @param counts [Hash<Integer>]
# @param depth [Integer]

def get_child_objects(mo, counts, depth)
  depth += 1

  # Exit if we hit the depth limit - this shouldn't happen, but it's good practice for any recursion
  if depth >= DEPTH_LIMIT
    puts format("Depth limit of %i reached - either this database is very large, or something went wrong!", DEPTH_LIMIT)
    return
  end

  counts[mo.type] += 1
  mo.children.each { |cmo| get_child_objects(cmo, counts, depth) }
  return
end

counts = Hash.new { |h, k| h[k] = 0 } # Default constructor so when we add a new key, it gets set to 0
depth = 0 # Not technically depth, but this is used to avoid an (unlikely) infinite loop

# Iterate through the database objects (except recyled ones)
database = WSApplication.current_database
database.root_model_objects.each do |rmo|
  get_child_objects(rmo, counts, depth)
end

# Print the result
counts.each { |table, count| puts format("%s: %i object(s)", table, count)}




