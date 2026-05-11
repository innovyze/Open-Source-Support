require 'fileutils'

# Configuration

db_path                  = 'localhost:40000/database'
network_type             = 'Collection Network'
network_id               = 20
attachmentsRootDirectory = 'C:\ProgramData\Innovyze\SNumbatData\Attachments'
videosRootDirectory      = 'C:\ProgramData\Innovyze\SNumbatData\Videos'
destinationDirectory     = 'C:\Temp\AttachmentExport'
renameFiles              = true   # true  = use original filename when copying
                                  # false = keep the UID as the filename
logFilename              = destinationDirectory+'\log.txt'
indexFilename            = destinationDirectory+'\attachment_index.csv'

# End of Configuration

# Image/attachment reference fields checked in addition to the attachments collection
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

def fileJoin(a, b)
  File.join(a, b).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
end

def readUids(uids, pathname)
  Dir.entries(pathname).each do |entry|
    next if entry == '.' || entry == '..'
    newPathname = fileJoin(pathname, entry)
    if File.directory?(newPathname)
      readUids(uids, newPathname)
    else
      uids[entry] = newPathname
    end
  end
end

def csvEscape(val)
  str = val.to_s
  if str.include?('"') || str.include?(',') || str.include?("\n") || str.include?("\r")
    '"' + str.gsub('"', '""') + '"'
  else
    str
  end
end

def csvRow(*fields)
  fields.map { |f| csvEscape(f) }.join(',')
end

# Returns a filename for the destination that does not already exist in dir.
# Falls back to uid if proposedName is blank.
def resolveDestFilename(dir, proposedName, uid)
  base = proposedName.to_s.strip
  base = uid.to_s if base.empty?
  base = base.gsub(/[\\\/\:\*\?\"\<\>\|]/, '_')

  return base unless File.exist?(fileJoin(dir, base))

  ext  = File.extname(base)
  stem = File.basename(base, ext)
  idx  = 1
  loop do
    candidate = "#{stem}_#{idx}#{ext}"
    return candidate unless File.exist?(fileJoin(dir, candidate))
    idx += 1
  end
end

$logFile = File.open(logFilename, 'w')

def log(str = '')
  puts str
  $logFile.puts str
end

FileUtils.mkdir_p(destinationDirectory)

log "Opening database #{db_path}"
log

db = WSApplication.open(db_path)

log "Database guid: #{db.guid}"

attachmentsDirectory = fileJoin(attachmentsRootDirectory, db.guid)
videosDirectory      = fileJoin(videosRootDirectory,      db.guid)

log
log "Reading attachment uids from #{attachmentsDirectory}"

attachmentUids = {}
readUids(attachmentUids, attachmentsDirectory) if File.directory?(attachmentsDirectory)

log "Found #{attachmentUids.size} attachment(s) in store"

log "Reading video uids from #{videosDirectory}"

videoUids = {}
readUids(videoUids, videosDirectory) if File.directory?(videosDirectory)

log "Found #{videoUids.size} video(s) in store"

allUids = attachmentUids.merge(videoUids)

log
log "Searching for #{network_type} with ID #{network_id}"

targetNetwork = nil
db.model_object_collection(network_type).each do |network|
  if network.id == network_id
    targetNetwork = network
    break
  end
end

if targetNetwork.nil?
  log "ERROR: #{network_type} with ID #{network_id} was not found in the database."
  $logFile.close
  exit
end

log "Found network - ID: #{targetNetwork.id}, Name: #{targetNetwork.name}"
log

copiedCount  = 0
missingCount = 0
errorCount   = 0
copiedUids   = {}

indexFileExists = File.exist?(indexFilename)
indexFile = File.open(indexFilename, 'a')
indexFile.puts csvRow('Network ID', 'Network Name', 'Object Type', 'Object ID', 'File Name', 'Purpose', 'Original Filename', 'Description') unless indexFileExists

openNetwork = targetNetwork.open

openNetwork.tables.each do |table|

  next unless table.fields.any? { |f| f.name == 'attachments' }

  log "Processing table: #{table.description} (#{table.name})"

  openNetwork.row_objects(table.name).each do |ro|

    # Process the attachments collection - these carry full metadata
    ro.attachments.each do |element|

      next if element.db_ref.to_s.empty?

      uid = element.db_ref

      if copiedUids.key?(uid)
        # File already copied by an earlier object; record the additional reference in the index
        indexFile.puts csvRow(
          targetNetwork.id, targetNetwork.name,
          table.description, ro.id,
          copiedUids[uid],
          element.purpose.to_s, element.filename.to_s,
          (element.description rescue '').to_s
        )
        next
      end

      sourcePath = allUids[uid]

      if sourcePath.nil?
        log "  MISSING  #{table.name} | #{ro.id} | #{element.filename} (uid: #{uid})"
        missingCount += 1
        next
      end

      proposedName = renameFiles ? element.filename.to_s : uid.to_s
      destFilename = resolveDestFilename(destinationDirectory, proposedName, uid)
      destPath     = fileJoin(destinationDirectory, destFilename)

      begin
        FileUtils.cp(sourcePath, destPath)
        copiedUids[uid] = destFilename
        log "  COPIED   #{ro.id} | #{element.filename} -> #{destFilename}"
        copiedCount += 1
      rescue => e
        log "  ERROR    #{ro.id} | #{element.filename} : #{e.message}"
        errorCount += 1
        next
      end

      indexFile.puts csvRow(
        targetNetwork.id, targetNetwork.name,
        table.description, ro.id,
        destFilename,
        element.purpose.to_s, element.filename.to_s,
        (element.description rescue '').to_s
      )

    end

    # Process individual image/attachment reference fields
    dbRefFields.each do |fieldname|

      begin

        next unless ro.field(fieldname) && ro[fieldname].to_s.length > 0

        uid = ro[fieldname]

        next if copiedUids.key?(uid)

        sourcePath = allUids[uid]

        if sourcePath.nil?
          log "  MISSING  #{table.name} | #{ro.id} | field:#{fieldname} (uid: #{uid})"
          missingCount += 1
          next
        end

        if renameFiles
          extname  = File.extname(File.basename(sourcePath))
          proposed = "#{ro.id}_#{fieldname}#{extname}".gsub(/[^0-9A-Za-z._\- ]/, '_')
        else
          proposed = uid.to_s
        end
        destFilename = resolveDestFilename(destinationDirectory, proposed, uid)
        destPath     = fileJoin(destinationDirectory, destFilename)

        FileUtils.cp(sourcePath, destPath)
        copiedUids[uid] = destFilename
        log "  COPIED   #{ro.id} | field:#{fieldname} -> #{destFilename}"
        copiedCount += 1

        indexFile.puts csvRow(
          targetNetwork.id, targetNetwork.name,
          table.description, ro.id,
          destFilename,
          fieldname, proposed, ''
        )

      rescue
      end

    end

  end

end

indexFile.close

log
log "Summary:"
log "  Files copied:        #{copiedCount}"
log "  Files missing:       #{missingCount}"
log "  Errors:              #{errorCount}"
log "  Index written to:    #{indexFilename}"
log "  Destination folder:  #{destinationDirectory}"

endingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed    = endingTime - startingTime

log
log "Done. Time taken #{Time.at(elapsed).utc.strftime('%H:%M:%S')}"
log

$logFile.close
