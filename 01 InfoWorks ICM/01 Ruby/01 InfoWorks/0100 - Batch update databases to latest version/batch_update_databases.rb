# ==============================================================================
# InfoWorks ICM - Batch Database Update Script
# ==============================================================================
# Ingests a CSV ledger of on-premise (Workgroup/Standalone) and Cloud databases,
# opens each database sequentially with update mode enabled, and writes a
# timestamped execution summary CSV.
#
# Usage (Command Line with ICM Exchange):
#   "C:\Program Files\Autodesk\InfoWorks ICM <Version>\ICMExchange.exe" batch_update_databases.rb -l [databases.csv]
#
# Arguments:
#   ARGV[0] = 'ADSK' (injected automatically by ICMExchange)
#   ARGV[1] = Path to CSV file (optional, defaults to 'databases.csv' in script dir)
#   -l / -login = Triggers Autodesk SSO authentication if required
#
# Each database's target_version column controls WSApplication.open's second
# argument: blank/'latest' passes true (update to the installed client's
# version); any other value is passed through as a version string (e.g.
# "2026.0", "2025.2") per the Exchange API's WSApplication.open(path, version).
#
# NOTE: This script never calls `exit`. ICMExchange.exe traps Ruby's
# SystemExit itself (prints "#<SystemExit: exit>" and "error reading file
# $<script>$ 6"), and the process exit code is always 0 regardless. Check the
# console summary and the results CSV for FAILED rows instead.
# ==============================================================================

require 'csv'
require 'time'

def run
  # 1. Resolve Input CSV File Path
  script_dir = File.dirname(WSApplication.script_file)
  csv_input_path = ARGV[1] || File.join(script_dir, 'databases.csv')

  unless File.exist?(csv_input_path)
    puts "\n[ERROR] CSV ledger not found at: #{csv_input_path}"
    puts "Please ensure 'databases.csv' exists or provide the path as an argument."
    return
  end

  # 2. Setup Output Summary CSV
  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  summary_csv_path = File.join(script_dir, "update_results_#{timestamp}.csv")

  puts "\n" + ("=" * 75)
  puts "  InfoWorks ICM Batch Database Update"
  puts "  ICM Version: #{WSApplication.version} | Started: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
  puts "  Ledger: #{csv_input_path}"
  puts "  Results Log: #{summary_csv_path}"
  puts ("=" * 75)

  # 3. Read and Parse Ledger
  records = []
  begin
    CSV.foreach(csv_input_path, headers: true, encoding: 'bom|utf-8') do |row|
      first_field = (row[0] || '').strip
      next if first_field.start_with?('#')

      path = (row['path'] || '').strip
      next if path.empty?

      records << {
        name: (row['name'] || '').strip,
        type: (row['type'] || 'unknown').strip.downcase,
        path: path,
        target_version: (row['target_version'] || '').strip
      }
    end
  rescue CSV::MalformedCSVError => e
    puts "\n[ERROR] Malformed CSV in #{csv_input_path}: #{e.message}"
    return
  rescue Errno::ENOENT
    puts "\n[ERROR] CSV ledger not found at: #{csv_input_path}"
    return
  end

  if records.empty?
    puts "\n[WARNING] No valid database entries found in #{csv_input_path}."
    return
  end

  puts "\nFound #{records.size} database(s) to process.\n"

  # 4. Process Each Database Sequentially
  results = []
  success_count = 0
  fail_count = 0
  start_overall_time = Time.now

  records.each_with_index do |rec, index|
    item_num = index + 1
    db_name = rec[:name].empty? ? rec[:path] : rec[:name]
    target_ver_str = rec[:target_version]

    # Determine update mode: specific version string or boolean true (latest)
    update_param = if target_ver_str.empty? || target_ver_str.casecmp('latest').zero?
                     true
                   else
                     target_ver_str
                   end

    display_target = update_param == true ? "Latest (Client #{WSApplication.version})" : target_ver_str

    puts "-" * 75
    puts "[#{item_num}/#{records.size}] Processing: #{db_name}"
    puts "  Type: #{rec[:type].upcase} | Target: #{display_target}"
    puts "  Path: #{rec[:path]}"

    t_start = Time.now
    db = nil
    status = 'FAILED'
    guid = ''
    err_msg = ''

    begin
      # Open database with update parameter
      db = WSApplication.open(rec[:path], update_param)

      if db.nil?
        status = 'FAILED'
        err_msg = 'open returned nil'
        fail_count += 1
        puts "  >>> RESULT: FAILED"
        puts "  >>> ERROR:  #{err_msg}"
      else
        begin
          guid = db.guid
        rescue => e
          guid = ''
          err_msg = e.message.strip.gsub(/[\r\n]+/, ' ')
        end
        status = 'SUCCESS'
        success_count += 1

        puts "  >>> RESULT: SUCCESS"
        puts "  >>> GUID: #{guid}"
      end
    rescue => e
      if e.message.include?('database not updated')
        puts "  >>> Update reported failure, retrying once..."
        sleep 1
        begin
          db = WSApplication.open(rec[:path], update_param)
          if db.nil?
            fail_count += 1
            err_msg = 'open returned nil'
            puts "  >>> RESULT: FAILED"
            puts "  >>> ERROR:  #{err_msg}"
          else
            guid = db.guid rescue ''
            status = 'SUCCESS'
            success_count += 1
            err_msg = 'retried once'
            puts "  >>> RESULT: SUCCESS (after retry)"
            puts "  >>> GUID: #{guid}"
          end
        rescue => e2
          fail_count += 1
          err_msg = e2.message.strip.gsub(/[\r\n]+/, ' ')
          puts "  >>> RESULT: FAILED"
          puts "  >>> ERROR:  #{err_msg}"
        end
      else
        fail_count += 1
        err_msg = e.message.strip.gsub(/[\r\n]+/, ' ')
        puts "  >>> RESULT: FAILED"
        puts "  >>> ERROR:  #{err_msg}"
      end
    ensure
      # Always release the database connection before continuing
      if db
        begin
          db.close
          puts "  Connection closed."
        rescue => close_err
          puts "  [Notice] Connection close warning: #{close_err.message}"
        end
      end
    end

    elapsed = (Time.now - t_start).round(2)
    puts "  Elapsed Time: #{elapsed}s"

    results << {
      name: rec[:name],
      type: rec[:type],
      path: rec[:path],
      target_version: (update_param == true ? 'latest' : update_param),
      status: status,
      guid: guid,
      duration_seconds: elapsed,
      error_message: err_msg
    }
  end

  # 5. Write Execution Summary CSV
  CSV.open(summary_csv_path, 'w', write_headers: true, headers: [
    'Name', 'Type', 'Path', 'Requested_Version', 'Status', 'GUID', 'Duration_Seconds', 'Error_Message'
  ]) do |csv|
    results.each do |r|
      csv << [
        r[:name],
        r[:type],
        r[:path],
        r[:target_version],
        r[:status],
        r[:guid],
        r[:duration_seconds],
        r[:error_message]
      ]
    end
  end

  total_duration = (Time.now - start_overall_time).round(2)

  # 6. Final Console Summary
  puts "\n" + ("=" * 75)
  puts "  BATCH UPDATE SUMMARY"
  puts "  Total Processed: #{records.size}"
  puts "  Successful:      #{success_count}"
  puts "  Failed:          #{fail_count}"
  puts "  Total Duration:  #{total_duration}s"
  puts "  Detailed Log:    #{summary_csv_path}"
  puts ("=" * 75) + "\n"
end

run
