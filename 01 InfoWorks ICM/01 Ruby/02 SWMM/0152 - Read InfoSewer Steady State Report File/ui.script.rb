require 'csv'
require 'pathname'

# Get the current network object
cn = WSApplication.current_network

# Prompt the user to select a file
result = WSApplication.prompt "Reading the InfoSewer Steady State RPT File",
[
  ['RPT File', 'String', nil, nil, 'FILE', true, '*.*', 'rpt', false],  
    ['[Summary]','Boolean',true],
    ['[Loading Manholes]','Boolean',true],
    ['[Pipes]','Boolean',true],
    ['[Force Mains]','Boolean',true],
    ['[Pumps]','Boolean',true]
  ], false
  file_path = result[0]
  puts file_path

  # Check if file path is given
  return unless file_path

  # Check if file exists
  unless File.exist?(file_path)
    puts "File does not exist. Please provide a valid file path."
    return
  end

  sections = {}
  current_section = nil
  headers = []
  loading_manhole_headers = ['Base', 'Storm', 'Total']
  pumps_headers = ['Pump Count', 'Pump Flow', 'Pump Head']
  force_mains_headers = [ 'Pipe Diam', 'Pipe Flow', 'Pipe Vel.', 'Pipe Loss']
  pipe_headers = ['Pipe Count', 'Pipe Slope', 'Pipe Diam', 'Pipe Flow', 'Pipe Load', 'Pipe Flow', 'Pipe Flow', 'Pipe Flow', 'Pipe Flow', 'Pipe Veloc', 'Pipe d/D', 'Pipe Depth', 'Pipe Number', 'Pipe Depth', 'Pipe Flow', 'Cover Count']
  
  line_counter = 0
  File.readlines(file_path).each do |line|
    line = line.gsub('Exponential 3-Point', 'Exponential3-Point') if line.include?('Exponential 3-Point')
    puts line
    line.strip!
    if line.start_with?('[') && line.end_with?(']')
      current_section = line[1..-2]
      sections[current_section] = {}
      line_counter = 0
    elsif !line.empty? && current_section && line_counter >= 3
      tokens = line.split
      id = tokens.shift
      2.times { tokens.shift } if current_section == 'Pipes'
      2.times { tokens.shift } if current_section == 'Force Mains'
      3.times { tokens.shift } if current_section == 'Pumps'
      sections[current_section][id] = tokens.map(&:to_f)
    end
    line_counter += 1
  end
  
  sections.each do |section, ids|
    next if ['Title', 'Summary'].include?(section)
    
    puts "Section: #{section}"
    headers = case section
              when 'Loading Manholes' then loading_manhole_headers
              when 'Pumps' then pumps_headers
              when 'Force Mains' then force_mains_headers
              when 'Pipes' then pipe_headers
              end
    headers.each_with_index do |header, index|
      all_tokens = ids.values.map { |values| values[index] if values.size > index }.compact
      if all_tokens.size > 0
        mean = all_tokens.sum / all_tokens.size
        max = all_tokens.max
        min = all_tokens.min
        count = all_tokens.size
      else
        mean = max = min = 0
        count = 0
      end
      puts "Header: #{header.ljust(15)}, Mean: #{format('%.3f', mean).ljust(15)}, Max: #{format('%.3f', max).ljust(15)}, Min: #{format('%.3f', min).ljust(15)}, Count: #{count.to_s.ljust(15)}"
    end
  end


  @echo off
  setlocal enabledelayedexpansion
  
  for /D /R %%a in (*) do (
      :: Replace slashes with underscores
      set "folder=%%a"
      set "folder=!folder:\=_!"
  
      :: Output to log file
      echo !folder! >> log.txt
  )