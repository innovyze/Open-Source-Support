net = WSApplication.current_network

# Define which table/link_type combinations require RTC configuration.
# link_types: nil  => all objects in that table are checked regardless of link_type.
# optional: true   => RTC is recommended but not required (reported as INFO).
# optional: false  => RTC is required for the object to operate (reported as WARNING).
rtc_checks = [
  { table: 'hw_blockage', link_types: nil,                              optional: false },
  { table: 'hw_pump',     link_types: ['FIXPMP'],                       optional: true  },
  { table: 'hw_orifice',  link_types: ['Vldorf'],                       optional: false },
  { table: 'hw_sluice',   link_types: ['VSGate', 'RSGate', 'VRGate'],  optional: false },
  { table: 'hw_weir',     link_types: ['VCWEIR', 'VWWEIR', 'GTWEIR'],  optional: false },
]

# Step 1: Collect all objects that match RTC-dependent link types
candidates = []
rtc_checks.each do |check|
  net.row_objects(check[:table]).each do |obj|
    if check[:link_types].nil? || check[:link_types].include?(obj.link_type)
      id = "#{obj.us_node_id}.#{obj.link_suffix}"
      candidates << {
        id:        id,
        table:     check[:table],
        link_type: obj.link_type,
        optional:  check[:optional]
      }
    end
  end
end

if candidates.empty?
  puts "No RTC-dependent objects found in the network."
else
  # Step 2: Get RTC text blob
  rtc_row  = net.row_object('hw_rtc', nil)
  rtc_text = rtc_row.nil? ? '' : (rtc_row['rtc_data'] || '')

  # Step 3: Check which candidates appear in the RTC definition
  missing_required = []
  missing_optional = []

  candidates.each do |c|
    unless rtc_text.include?(c[:id])
      if c[:optional]
        missing_optional << c
      else
        missing_required << c
      end
    end
  end

  # Step 4: Report results
  if missing_required.empty? && missing_optional.empty?
    puts "All RTC-dependent objects are configured in RTC."
  else
    unless missing_required.empty?
      puts "=== WARNING: Objects that require RTC but are NOT found in the RTC editor ==="
      missing_required.each do |c|
        puts "  #{c[:table]}  #{c[:id]}  (link_type: #{c[:link_type]})"
      end
    end
    unless missing_optional.empty?
      puts ""
      puts "=== INFO: Objects that may benefit from RTC but are NOT configured ==="
      missing_optional.each do |c|
        puts "  #{c[:table]}  #{c[:id]}  (link_type: #{c[:link_type]})"
      end
    end
    puts ""
    puts "Total: #{missing_required.length} required, #{missing_optional.length} optional missing from RTC"
  end
end
