# Context: Exchange
# Purpose: Copy a specific version/commit of a network to a new independent network
# Method: Branch from specific commit, then copy to create independent network
#
# ============================================================================
# CONFIGURATION
# ============================================================================
# Database path - set here or leave nil to use most recently opened
DATABASE_PATH = nil  # e.g., 'C:/Database.icmm' or 'cloud://db@123/name'

# Network ID to copy
NETWORK_ID = nil  # e.g., 123

# New network name (optional - leave nil to use original name)
NEW_NETWORK_NAME = nil  # e.g., 'My Network Copy'

# Specific commit ID (optional - leave nil to use latest)
COMMIT_ID = nil  # e.g., 456
# ============================================================================

begin
  puts "="*80
  puts "Copy Network Version"
  puts "="*80
  
  # Validate configuration
  if NETWORK_ID.nil?
    puts "\nERROR: NETWORK_ID not configured"
    puts "Please edit the script and set NETWORK_ID at the top"
    exit 1
  end
  
  # Open database
  if DATABASE_PATH.nil?
    puts "\nOpening most recently used database..."
    db = WSApplication.open
  else
    puts "\nOpening database: #{DATABASE_PATH}"
    db = WSApplication.open(DATABASE_PATH, false)
  end
  
  if db.nil?
    puts "ERROR: Failed to open database"
    exit 1
  end
  
  puts "Database opened: #{db.path}"
  puts "Network ID: #{NETWORK_ID}"
  
  # Get source network
  source_network = db.model_object_from_type_and_id('Model Network', NETWORK_ID)
  
  if source_network.nil?
    puts "ERROR: Network with ID #{NETWORK_ID} not found"
    exit 1
  end
  
  puts "Found network: #{source_network.name}"
  
  # Determine new name
  new_name = NEW_NETWORK_NAME.nil? || NEW_NETWORK_NAME.strip.empty? ? source_network.name : NEW_NETWORK_NAME
  
  # Determine commit to use
  latest_commit = source_network.latest_commit_id
  selected_commit = COMMIT_ID.nil? ? latest_commit : COMMIT_ID
  
  if selected_commit > latest_commit
    puts "ERROR: Commit ID #{selected_commit} exceeds latest commit #{latest_commit}"
    exit 1
  end
  
  puts "Using commit: #{selected_commit}" + (selected_commit == latest_commit ? " (latest)" : "")
  
  # Get commit details
  commit_info = "Commit #{selected_commit}"
  
  begin
    source_network.commits.each do |c|
      if c.commit_id == selected_commit
        commit_info = "Commit #{selected_commit} by #{c.user}"
        puts commit_info
        break
      end
    end
  rescue => e
    puts "Commit #{selected_commit} (details unavailable)"
  end
  
  # Get parent group
  parent_group = db.model_object_from_type_and_id(source_network.parent_type, source_network.parent_id)
  
  if parent_group.nil?
    puts "ERROR: Parent group not found"
    exit 1
  end
  
  puts "Parent group: #{parent_group.name}"
  
  # Check for name conflicts
  existing = nil
  parent_group.children.each do |c|
    if c.type == 'Model Network' && c.name == new_name && c.id != source_network.id
      existing = c
      break
    end
  end
  
  if existing
    puts "WARNING: Network '#{new_name}' already exists (ID: #{existing.id})"
    puts "Name may be automatically modified"
  end
  
  # Step 1: Branch from commit
  temp_name = "#{new_name}_TEMP_#{Time.now.strftime('%Y%m%d%H%M%S')}"
  puts "\nStep 1: Creating temporary branch..."
  branched = source_network.branch(selected_commit, temp_name)
  
  if branched.nil?
    puts "ERROR: Failed to create branch"
    exit 1
  end
  
  puts "Branch created (ID: #{branched.id})"
  
  # Step 2: Copy branch to independent network
  puts "\nStep 2: Copying to independent network..."
  puts "Please wait..."
  start_time = Time.now
  
  # copy_here(source_object, copy_results, copy_children)
  independent_copy = parent_group.copy_here(branched, false, false)
  
  if independent_copy.nil?
    puts "ERROR: Failed to copy network"
    exit 1
  end
  
  duration = Time.now - start_time
  puts "Copy completed in #{duration.round(1)}s (ID: #{independent_copy.id})"
  
  # Step 3: Rename and set description
  puts "\nStep 3: Setting name and description..."
  independent_copy.name = new_name
  
  description = "Copied from: #{source_network.name}\n #{commit_info}\n Copied: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
  
  begin
    independent_copy.comment = description
  rescue => e
    puts "Note: Could not set description (#{e.message})"
  end
  
  puts "Name set to: #{new_name}"
  
  # Step 4: Cleanup temporary branch
  puts "\nStep 4: Cleaning up..."
  
  begin
    if branched.deletable?
      branched.delete
      puts "Temporary branch deleted"
    else
      puts "WARNING: Could not delete temporary branch '#{temp_name}' (ID: #{branched.id})"
      puts "Manual deletion may be required"
    end
  rescue => e
    puts "WARNING: Failed to delete branch: #{e.message}"
  end
  
  # Step 5: Validate
  puts "\nStep 5: Validating..."
  
  begin
    test = independent_copy.open
    if test
      node_count = test.row_objects('_nodes').length
      link_count = test.row_objects('_links').length
      puts "Validation passed: #{node_count} nodes, #{link_count} links"
    else
      puts "WARNING: Could not open copied network"
    end
  rescue => e
    puts "WARNING: Validation error: #{e.message}"
  end
  
  # Success summary
  puts "\n" + "="*80
  puts "SUCCESS"
  puts "="*80
  puts "Original: #{source_network.name} (ID: #{source_network.id})"
  puts "New copy: #{independent_copy.name} (ID: #{independent_copy.id})"
  puts "Commit: #{selected_commit}"
  puts "Parent: #{parent_group.name}"
  
rescue => e
  puts "\n" + "="*80
  puts "ERROR"
  puts "="*80
  puts e.message
  puts e.backtrace.join("\n")
  exit 1
ensure
  db.close if db
end
