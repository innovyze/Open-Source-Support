
# Configuration

db_path = 'localhost:40000/test_thing'
snumbatdataDirectory = 'C:\ProgramData\Innovyze\SNumbatData'

logFilename = 'log.txt'
missingFilesFilename = 'missing.csv'
nonCurrentVideosFilename = 'NonCurrentVideos.txt'
nonCurrentAttachmentsFilename = 'NonCurrentAttachments.txt'

# End of configuration

network_types = ['Collection Network', 'Distribution Network', 'Asset Network']

dbRefFields = [
  'detail_image',
  'ds_image',
  'ds_photo',
  'external_photo',
  'injection_point_image',
  'internal_image',
  'internal_photo',
  'location_image',
  'location_photo',
  'location_sketch',
  'other_image',
  'photo',
  'plan_sketch',
  'sketch',
  'us_image',
  'us_photo'
]

startingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)

videoUids = Hash.new
attachmentUids = Hash.new

def fileJoin(a, b) # Just looks nicer to use backslashes throughout
  File.join(a, b).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
end

def readUids(uids, pathname)

  Dir.entries(pathname).select{ |entry|

    newPathname = fileJoin(pathname, entry)

    if (entry == "." || entry == "..") then
      # These can be ignored
    elsif (File.directory?(newPathname)) then
      readUids(uids, newPathname)
    else
      uids[entry] = newPathname
    end
  
  }
end

# Open log.txt and missing.txt files

$logFile = File.open(logFilename, 'w')
missingFile = File.open(missingFilesFilename, 'w')
missingFile.puts('Network type, Network number, Network name, Table name, Table description, Object id, db_ref, Original filename, Purpose')

def log(str = '')
  puts str
  $logFile.puts str
end

# Open database

log "Opening database #{db_path}"
log

db = WSApplication.open(db_path) 

log "Database guid: #{db.guid}"

videosDirectory = fileJoin(
  fileJoin(
    snumbatdataDirectory, 'Videos'
 ),
 db.guid
)

attachmentsDirectory = fileJoin(
  fileJoin(
    snumbatdataDirectory, 'Attachments'
  ),
  db.guid
)

# Read video uids

log
log "Reading video uids from #{videosDirectory}"

readUids(videoUids, videosDirectory)

log "Found #{videoUids.size()} videos"
log

# Read attachment uids

log
log "Reading attachment uids from #{attachmentsDirectory}"

readUids(attachmentUids, attachmentsDirectory)

log "Found #{attachmentUids.size()} attachments"
log

# Open networks

allUids = videoUids.merge(attachmentUids)

missingFilesCount = 0

network_types.each { |network_type|
  networks = db.model_object_collection(network_type)
  network_ids = Array.new

  networks.each { |network|
    log "Processing #{network_type} #{network.id}: #{network.name}"
    network_ids.push network.id

    open_network = network.open

    open_network.tables.each{ |table|

      table.fields.each { |field|

        if (field.name == 'attachments') then
          open_network.row_objects(table.name).each{ |ro|

            dbRefFields.each{ |fieldname|

              begin

                if (ro.field(fieldname) && ro[fieldname].to_s.length > 0) then
                  uid = ro[fieldname]
  
                  if (attachmentUids[uid]) then
                    # This attachment is current.  Remove it from the list of potentially non-current attachments
                    attachmentUids.delete(uid)
                  end
                end
  
              rescue
              end

            }

            ro.attachments.each { |element|
              if (element.db_ref.to_s.length > 0) then
                uid = element.db_ref

                if (videoUids[uid]) then
                  # This video is current.  Remove it from the list of potentially non-current videos
                  videoUids.delete(uid)
                elsif (attachmentUids[uid]) then
                  # This attachment is current.  Remove it from the list of potentially non-current attachments
                  attachmentUids.delete(uid)
                elsif (!allUids[uid]) then
                  # This file is missing
                  missingFile.puts "#{network_type}, #{network.id}, #{network.name}, #{table.name}, #{table.description}, #{ro.id}, #{element.db_ref}, #{element.filename}, #{element.purpose},"
                  missingFilesCount += 1
                end
              end
            }

          }
        end

      }

    }
  }

  log "Processed #{network_ids.size} #{network_type}"
  log
}

# Write out missing files

log "Found #{missingFilesCount} missing files"
log "Written to #{missingFilesFilename}"
log

# Write out non-current videos

log "Found #{videoUids.size()} non-current videos"

File.write(nonCurrentVideosFilename, videoUids.values().join("\n"))

log "Written to #{nonCurrentVideosFilename}"
log

# Write out non-current videos

log "Found #{attachmentUids.size()} non-current attachments"

File.write(nonCurrentAttachmentsFilename, attachmentUids.values().join("\n"))

log "Written to #{nonCurrentAttachmentsFilename}"
log

# Done

endingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = endingTime - startingTime

log "Done.  Time taken #{Time.at(elapsed).utc.strftime("%H:%M:%S")}"
log

$logFile.close()
missingFile.close()

