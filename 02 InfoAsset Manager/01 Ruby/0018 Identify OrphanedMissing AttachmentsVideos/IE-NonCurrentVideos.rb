
# Configuration

db_path = 'localhost:40000/DATABASE_TO_TEST'
videosDirectory = 'C:\ProgramData\Innovyze\SNumbatData\Videos' # You can probably identify non-current attachments by setting this to the Attachments directory

# End of configuration

require 'Set'

network_types = ['Collection Network', 'Distribution Network', 'Asset Network']

startingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)

$uids = Hash.new

def fileJoin(a, b) # Just looks nicer to use backslashes throughout
  File.join(a, b).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
end

def readUids(pathname)

  Dir.entries(pathname).select{ |entry|

    newPathname = fileJoin(pathname, entry)

    if (entry == "." || entry == "..") then
      # These can be ignored
    elsif (File.directory?(newPathname)) then
      readUids(newPathname)
    else
      $uids[entry] = newPathname
    end
  
  }
end

# Open database

puts "Opening database #{db_path}"
puts

db = WSApplication.open(db_path) 

puts "Database guid: #{db.guid}"

blobsDirectory = fileJoin(videosDirectory, db.guid)

# Read blob uids

puts
puts "Reading video uids from #{blobsDirectory}"

readUids(blobsDirectory)

puts "Found #{$uids.size()} videos"
puts

# Open networks

network_types.each { |network_type|
  networks = db.model_object_collection(network_type)
  network_ids = Array.new

  networks.each { |network|
    puts "Processing #{network_type} #{network.id}"
    network_ids.push network.id

    open_network = network.open

    open_network.tables.each{ |table|

      blobFields = Array.new

      table.fields.each { |field|

        if (field.name == 'attachments') then
          open_network.row_objects(table.name).each{ |ro|

            ro.attachments.each { |element|
              if (element.db_ref.to_s.length > 0) then
                uid = element.db_ref

                if ($uids[uid]) then
                  $uids.delete(uid)
                end
              end
            }

          }
        end

      }

    }
  }

  puts "Processed #{network_ids.size} #{network_type}"
  puts
}

puts "Found #{$uids.size()} non-current videos"

File.write('output.txt', $uids.values().join("\n"))

puts "Written to output.txt"
puts

# Done

endingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = endingTime - startingTime

puts "Done.  Time taken #{Time.at(elapsed).utc.strftime("%H:%M:%S")}"
puts

