# ============================================================================
# Design Flow Calculator - PEAKABLE/UNPEAKABLE SEPARATION
# ============================================================================
# VERSION: 3.0
# FEATURES:
#   - Separated peakable (trade) and unpeakable (base) flows
#   - EFF explanation in dialog
#   - ASCII-only output (no Unicode issues)
#   - Topology analysis
#   - CSV export with flow components
#   - Robust transaction handling
# ============================================================================

begin
  require 'date'
  require 'csv'
rescue LoadError => e
  puts "ERROR: Could not load required library: #{e.message}"
  WSApplication.message_box(
    "ERROR: Missing required Ruby library\n\n#{e.message}",
    "OK",
    "!",
    false
  )
  exit
end

net = WSApplication.current_network

unless net
  WSApplication.message_box(
    "ERROR: No Network Open\n\n" +
    "Please open a network before running this script.",
    "OK",
    "!",
    false
  )
  exit
end

puts "\n" + "="*80
puts " DESIGN FLOW CALCULATOR - PEAKABLE/UNPEAKABLE SEPARATION"
puts " " + Time.now.strftime("%Y-%m-%d %H:%M:%S")
puts "="*80

# Clean up any existing transaction
puts "\nChecking for existing transactions..."
begin
  net.transaction_commit
  puts "[OK] Cleaned up previous transaction"
rescue
  puts "[OK] No existing transaction to clean up"
end

# ============================================================================
# CONFIGURATION & FORMULA PRESETS
# ============================================================================

FORMULA_PRESETS = {
  'Harmon Formula' => {
    desc: 'EFF = 1 + (14 / sqrt(P)) - Traditional US formula',
    c1: 1.0, c2: 14.0, c3: 0.0, e1: 0.0, e2: 0.5, m1: 0.0, m2: 1.0
  },
  'Modified Harmon' => {
    desc: 'EFF = 1 + (18 / (4 + sqrt(P))) - Ten States Standards',
    c1: 1.0, c2: 18.0, c3: 4.0, e1: 0.0, e2: 0.5, m1: 0.0, m2: 1.0
  },
  'Babbitt Formula' => {
    desc: 'EFF = 5 / P^0.2 - For small communities',
    c1: 0.0, c2: 5.0, c3: 0.0, e1: 0.0, e2: 0.2, m1: 0.0, m2: 1.0
  },
  'Custom Formula' => {
    desc: 'Enter your own coefficients',
    c1: 1.0, c2: 14.0, c3: 0.0, e1: 0.0, e2: 0.5, m1: 0.0, m2: 1.0
  }
}

# ============================================================================
# STEP 1: Get user input with EFF explanation
# ============================================================================

puts "\nDisplaying parameter dialog..."

preset_options = FORMULA_PRESETS.keys

layout = [
  ['=== DESIGN FLOW CALCULATOR ===', 'READONLY', ''],
  
  ['Formula Preset for Peaking', 'String', 'Harmon Formula', nil, 'LIST', preset_options],  # 18
  ['Peakable flow per capita (L/person/day)', 'NUMBER', 150.0, 2],                          # 19
  ['Maximum EFF cutoff', 'NUMBER', 6.0, 2],                                                  # 20
  ['Base flow per capita (L/person/day)', 'NUMBER', 50.0, 2],                               # 30
  
  ['=== FORMULA COEFFICIENTS (FOR PEAKING) ===', 'READONLY', ''],
  ['Only change these if using Custom Formula preset', 'READONLY', ''],
  ['c1 (constant term)', 'NUMBER', 1.0, 4],                                                 # 35
  ['c2 (numerator constant)', 'NUMBER', 14.0, 4],                                           # 36
  ['c3 (denominator constant)', 'NUMBER', 0.0, 4],                                          # 37
  ['m1 (numerator multiplier)', 'NUMBER', 0.0, 4],                                          # 38
  ['m2 (denominator multiplier)', 'NUMBER', 1.0, 4],                                        # 39
  ['e1 (numerator exponent)', 'NUMBER', 0.0, 4],                                            # 40
  ['e2 (denominator exponent)', 'NUMBER', 0.5, 4],                                          # 41
  
  ['=== UNITS & OPTIONS ===', 'READONLY', ''],
  ['Convert to flow per second?', 'Boolean', true],                                         # 52
  ['Dry run (calculate but don\'t save)', 'Boolean', false],                                # 53
  ['Export results to CSV', 'Boolean', true],                                               # 54
  ['Show detailed topology stats', 'Boolean', true],                                        # 55
  ['Enable debug mode', 'Boolean', false]                                                   # 56
]

result = WSApplication.prompt(
  'Design Flow Calculator - Enter Parameters',
  layout,
  false
)

if result.nil?
  puts "Calculation cancelled by user"
  exit
end

# Extract parameters with correct indices
formula_preset = result[18]
q_per_capita_peakable = result[19]
cutoff = result[20]
q_per_capita_base = result[30]
c1 = result[35]
c2 = result[36]
c3 = result[37]
m1 = result[38]
m2 = result[39]
e1 = result[40]
e2 = result[41]
convert_to_per_second = result[52]
dry_run = result[53]
export_csv = result[54]
show_topology = result[55]
debug_mode = result[56]

# Apply formula preset
if formula_preset && formula_preset != 'Custom Formula' && FORMULA_PRESETS[formula_preset]
  preset = FORMULA_PRESETS[formula_preset]
  c1 = preset[:c1]
  c2 = preset[:c2]
  c3 = preset[:c3]
  m1 = preset[:m1]
  m2 = preset[:m2]
  e1 = preset[:e1]
  e2 = preset[:e2]
  
  puts "\nApplied formula preset: #{formula_preset}"
  puts "  Description: #{preset[:desc]}"
end

# Convert flow units
q_peakable_per_sec = convert_to_per_second ? (q_per_capita_peakable / 86400.0) : q_per_capita_peakable
q_base_per_sec = convert_to_per_second ? (q_per_capita_base / 86400.0) : q_per_capita_base
flow_units = convert_to_per_second ? "L/s" : "L/day"

# ============================================================================
# PARAMETER VALIDATION
# ============================================================================

puts "\n" + "-"*80
puts "VALIDATING PARAMETERS"
puts "-"*80

validation_errors = []
validation_warnings = []

if q_per_capita_peakable.nil? || q_per_capita_peakable <= 0
  validation_errors << "Peakable flow per capita must be greater than 0"
end

if q_per_capita_base.nil? || q_per_capita_base < 0
  validation_errors << "Base flow per capita cannot be negative"
end

if q_per_capita_peakable && q_per_capita_peakable < 50
  validation_warnings << "Peakable flow (#{q_per_capita_peakable} L/person/day) is unusually low"
elsif q_per_capita_peakable && q_per_capita_peakable > 500
  validation_warnings << "Peakable flow (#{q_per_capita_peakable} L/person/day) is unusually high"
end

if q_per_capita_base && q_per_capita_base > 100
  validation_warnings << "Base flow (#{q_per_capita_base} L/person/day) is unusually high for I/I"
end

if cutoff.nil? || cutoff <= 0
  validation_errors << "Cutoff value must be greater than 0"
end

if c3 == 0 && m2 == 0
  validation_errors << "c3 and m2 cannot both be zero (causes division by zero)"
end

if validation_warnings.size > 0
  puts "\nWARNINGS:"
  validation_warnings.each { |w| puts "  [!] #{w}" }
end

if validation_errors.size > 0
  puts "\nERRORS:"
  validation_errors.each { |e| puts "  [X] #{e}" }
  
  WSApplication.message_box(
    "Parameter Validation Failed:\n\n" + validation_errors.join("\n"),
    "OK",
    "!",
    false
  )
  exit
end

puts "\n[OK] Parameter validation passed"

# Display parameters
puts "\n" + "-"*80
puts "CALCULATION PARAMETERS"
puts "-"*80
puts "Peaking Formula: #{formula_preset}"
puts "  EFF = c1 + ((c2 + (m1 * P^e1)) / (c3 + (m2 * P^e2)))"
puts "  c1=#{c1}, c2=#{c2}, c3=#{c3}"
puts "  m1=#{m1}, m2=#{m2}"
puts "  e1=#{e1}, e2=#{e2}"
puts "  Maximum EFF cutoff: #{cutoff}"
puts ""
puts "WHAT EFF DOES:"
puts "  EFF is the peaking factor - it accounts for how much"
puts "  instantaneous peak flow exceeds average daily flow."
puts "  Higher EFF = higher peaks (small systems)"
puts "  Lower EFF = flatter peaks (large systems)"
puts ""
puts "EXAMPLE VALUES FOR THIS FORMULA:"
if c1 == 1.0 && c2 == 14.0 && c3 == 0.0 && m2 == 1.0 && e2 == 0.5
  puts "  100 people -> EFF = 2.40 (peak is 2.4x average)"
  puts "  500 people -> EFF = 1.63 (peak is 1.63x average)"
  puts "  1,000 people -> EFF = 1.44 (peak is 1.44x average)"
  puts "  5,000 people -> EFF = 1.20 (peak is 1.2x average)"
  puts "  10,000 people -> EFF = 1.14 (peak is 1.14x average)"
end
puts ""
puts "Flow Components:"
puts "  Peakable (Trade) Flow: #{q_per_capita_peakable} L/person/day"
puts "    -> Converted to: #{q_peakable_per_sec.round(6)} #{flow_units}"
puts "    -> This flow VARIES with EFF (gets peaked)"
puts ""
puts "  Unpeakable (Base) Flow: #{q_per_capita_base} L/person/day"
puts "    -> Converted to: #{q_base_per_sec.round(6)} #{flow_units}"
puts "    -> This flow is CONSTANT (no peaking applied)"
puts ""
puts "  Total per capita: #{q_per_capita_peakable + q_per_capita_base} L/person/day"
puts "-"*80

# ============================================================================
# STEP 2: Build node-subcatchment mapping
# ============================================================================

puts "\n" + "="*80
puts "PHASE 1: BUILDING NETWORK TOPOLOGY"
puts "="*80

puts "\nMapping subcatchments to nodes..."

all_subs = net.row_object_collection('hw_subcatchment')
all_nodes = net.row_object_collection('hw_node')

node_sub_hash_map = Hash.new { |hash, key| hash[key] = [] }

all_nodes.each do |node|
  node_sub_hash_map[node.id] = []
end

sub_count = 0
subs_with_population = 0
total_population = 0.0
subs_without_connection = 0

all_subs.each do |sub|
  sub_count += 1
  
  has_connection = false
  
  if sub.node_id && !sub.node_id.empty?
    node_sub_hash_map[sub.node_id] << sub
    has_connection = true
  else
    begin
      sub.lateral_links.each do |link|
        if link.ds_node
          node_sub_hash_map[link.ds_node.id] ||= []
          node_sub_hash_map[link.ds_node.id] << sub
          has_connection = true
        end
      end
    rescue
    end
  end
  
  subs_without_connection += 1 unless has_connection
  
  if sub.population && sub.population > 0
    subs_with_population += 1
    total_population += sub.population
  end
end

puts "[OK] Mapped #{sub_count} subcatchments"
puts "  With population: #{subs_with_population}"
puts "  Total population: #{total_population.round(0)}"
puts "  Not connected: #{subs_without_connection}" if subs_without_connection > 0

if subs_with_population == 0
  WSApplication.message_box(
    "ERROR: No subcatchments have population data!",
    "OK",
    "!",
    false
  )
  exit
end

# ============================================================================
# ANALYZE NETWORK TOPOLOGY
# ============================================================================

puts "\n" + "-"*80
puts "ANALYZING NETWORK TOPOLOGY"
puts "-"*80

all_conduits = net.row_object_collection('hw_conduit')

conduit_map = {}
upstream_sources = []
downstream_outlets = []
has_upstream = {}
has_downstream = {}

puts "\nBuilding network connectivity map..."

all_conduits.each do |conduit|
  conduit_id = conduit.id rescue nil
  next unless conduit_id
  
  conduit_map[conduit_id] = conduit
  
  begin
    us_node = conduit.us_node
    if us_node
      us_conduit_count = 0
      us_node.us_links.each do |ul|
        us_conduit_count += 1 if ul.table == 'hw_conduit'
      end
      has_upstream[conduit_id] = us_conduit_count > 0
    else
      has_upstream[conduit_id] = false
    end
  rescue
    has_upstream[conduit_id] = false
  end
  
  begin
    ds_node = conduit.ds_node
    if ds_node
      ds_conduit_count = 0
      ds_node.ds_links.each do |dl|
        ds_conduit_count += 1 if dl.table == 'hw_conduit'
      end
      has_downstream[conduit_id] = ds_conduit_count > 0
    else
      has_downstream[conduit_id] = false
    end
  rescue
    has_downstream[conduit_id] = false
  end
end

conduit_map.each do |id, conduit|
  upstream_sources << conduit unless has_upstream[id]
  downstream_outlets << conduit unless has_downstream[id]
end

puts "\nNetwork Structure:"
puts "  Total conduits: #{conduit_map.size}"
puts "  Starting points: #{upstream_sources.size}"
puts "  Ending points: #{downstream_outlets.size}"
puts "  Through conduits: #{conduit_map.size - upstream_sources.size - downstream_outlets.size}"

if show_topology && upstream_sources.size > 0
  puts "\n** Starting Points (Network Sources):"
  upstream_sources.first([10, upstream_sources.size].min).each do |conduit|
    begin
      us_node_id = conduit.us_node.id rescue "?"
      ds_node_id = conduit.ds_node.id rescue "?"
      puts "  * Conduit #{conduit.id}: #{us_node_id} -> #{ds_node_id}"
    rescue
      puts "  * Conduit #{conduit.id}"
    end
  end
  puts "  ... (showing first 10 of #{upstream_sources.size})" if upstream_sources.size > 10
end

if show_topology && downstream_outlets.size > 0
  puts "\n** Ending Points (Network Outlets):"
  downstream_outlets.first([10, downstream_outlets.size].min).each do |conduit|
    begin
      us_node_id = conduit.us_node.id rescue "?"
      ds_node_id = conduit.ds_node.id rescue "?"
      puts "  * Conduit #{conduit.id}: #{us_node_id} -> #{ds_node_id}"
    rescue
      puts "  * Conduit #{conduit.id}"
    end
  end
  puts "  ... (showing first 10 of #{downstream_outlets.size})" if downstream_outlets.size > 10
end

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def get_conduit_flow_area(conduit)
  begin
    width = conduit.conduit_width
    height = conduit.conduit_height
    
    return 1.0 if width.nil? || width <= 0
    
    if !height.nil? && height > 0 && (height - width).abs > 0.001
      area = width * height
      return area > 0 ? area : 1.0
    else
      radius = width / 2.0
      area = Math::PI * radius * radius
      return area > 0 ? area : 1.0
    end
  rescue
    return 1.0
  end
end

$upstream_pop_cache = {}

def trace_upstream_population(conduit, node_sub_hash_map, debug_mode = false)
  conduit_id = conduit.id rescue nil
  return $upstream_pop_cache[conduit_id] if conduit_id && $upstream_pop_cache[conduit_id]
  
  unprocessed_links = [[conduit, 1.0]]
  seen_links = {}
  total_weighted_population = 0.0
  
  seen_links[conduit_id] = true if conduit_id
  
  max_iterations = 10000
  iteration_count = 0
  
  while unprocessed_links.size > 0 && iteration_count < max_iterations
    iteration_count += 1
    working_link, current_weight = unprocessed_links.shift
    
    begin
      us_node = working_link.us_node
    rescue
      next
    end
    
    next if us_node.nil?
    node_id = us_node.id rescue nil
    next if node_id.nil?
    
    adjusted_weight = current_weight
    
    downstream_conduits = []
    begin
      us_node.ds_links.each do |dl|
        downstream_conduits << dl if dl.table == 'hw_conduit'
      end
    rescue
    end
    
    if downstream_conduits.size > 1
      total_area = 0.0
      areas = {}
      
      downstream_conduits.each do |dc|
        area = get_conduit_flow_area(dc)
        dc_id = dc.id rescue nil
        areas[dc_id] = area if dc_id
        total_area += area
      end
      
      begin
        working_link_ds_node = working_link.ds_node
        working_link_ds_node_id = working_link_ds_node.id rescue nil
      rescue
        working_link_ds_node_id = nil
      end
      
      if working_link_ds_node_id && total_area > 0
        downstream_conduits.each do |dc|
          begin
            dc_ds_node = dc.ds_node
            dc_ds_node_id = dc_ds_node.id rescue nil
            
            if dc_ds_node_id == working_link_ds_node_id
              dc_id = dc.id rescue nil
              if dc_id && areas[dc_id]
                split_ratio = areas[dc_id] / total_area
                adjusted_weight = current_weight * split_ratio
                break
              end
            end
          rescue
          end
        end
      end
    end
    
    if node_sub_hash_map[node_id]
      node_sub_hash_map[node_id].each do |sub|
        if sub.population && sub.population > 0
          weighted_pop = sub.population * adjusted_weight
          total_weighted_population += weighted_pop
        end
      end
    end
    
    begin
      us_node.us_links.each do |ul|
        ul_id = ul.id rescue nil
        next if ul_id.nil? || seen_links[ul_id]
        
        unprocessed_links << [ul, adjusted_weight]
        seen_links[ul_id] = true
      end
    rescue
    end
  end
  
  $upstream_pop_cache[conduit_id] = total_weighted_population if conduit_id
  return total_weighted_population
end

# ============================================================================
# STEP 3: Calculate design flows
# ============================================================================

puts "\n" + "="*80
puts "PHASE 2: CALCULATING DESIGN FLOWS"
puts "="*80

total_conduits = conduit_map.size
puts "\nProcessing #{total_conduits} conduits..."

results = []
processed = 0
updated = 0
skipped_no_pop = 0
errors = 0
eff_warnings = []

min_peakable_flow = Float::INFINITY
max_peakable_flow = 0.0
sum_peakable_flow = 0.0
min_base_flow = Float::INFINITY
max_base_flow = 0.0
sum_base_flow = 0.0
min_total_flow = Float::INFINITY
max_total_flow = 0.0
sum_total_flow = 0.0
sum_population = 0.0

source_results = []
outlet_results = []
through_results = []

transaction_started = false

unless dry_run
  begin
    net.transaction_begin
    transaction_started = true
    puts "[OK] Transaction started"
  rescue => e
    puts "[!] Could not start transaction: #{e.message}"
    begin
      net.transaction_rollback
    rescue
      begin
        net.transaction_commit
      rescue
      end
    end
    begin
      net.transaction_begin
      transaction_started = true
      puts "  [OK] Transaction started on retry"
    rescue
      puts "  [!] Continuing without transaction"
    end
  end
end

begin
  conduit_map.each do |conduit_id, conduit|
    processed += 1
    
    if processed % 100 == 0
      percent = ((processed.to_f / total_conduits) * 100).round(1)
      puts "  Progress: #{processed}/#{total_conduits} (#{percent}%)"
    end
    
    begin
      population = trace_upstream_population(conduit, node_sub_hash_map, debug_mode)
      
      if population.nil? || population <= 0
        skipped_no_pop += 1
        next
      end
      
      if population.infinite? || population.nan?
        errors += 1
        next
      end
      
      # Calculate EFF
      p_to_e1 = population ** e1
      p_to_e2 = population ** e2
      numerator = c2 + (m1 * p_to_e1)
      denominator = c3 + (m2 * p_to_e2)
      
      if denominator.abs < 1e-10
        next
      end
      
      eff = c1 + (numerator / denominator)
      
      if eff.infinite? || eff.nan?
        errors += 1
        next
      end
      
      if eff < 0.5 && eff_warnings.size < 5
        eff_warnings << "Conduit #{conduit_id}: EFF=#{eff.round(3)} (low)"
      elsif eff > 20.0 && eff_warnings.size < 5
        eff_warnings << "Conduit #{conduit_id}: EFF=#{eff.round(3)} (high)"
      end
      
      eff_capped = eff > cutoff ? cutoff : eff
      
      # Peakable flow with peaking factor
      peakable_flow = eff_capped * population * q_peakable_per_sec
      
      # Base flow is constant - no peaking factor
      base_flow = population * q_base_per_sec
      
      # Total design flow
      total_design_flow = peakable_flow + base_flow
      
      if total_design_flow.infinite? || total_design_flow.nan? || total_design_flow < 0
        errors += 1
        next
      end
      
      # Store results
      unless dry_run
        conduit.trade_flow = peakable_flow
        conduit.base_flow = base_flow
        conduit.user_number_1 = total_design_flow
        conduit.write
      end
      
      # Track statistics
      min_peakable_flow = [min_peakable_flow, peakable_flow].min
      max_peakable_flow = [max_peakable_flow, peakable_flow].max
      sum_peakable_flow += peakable_flow
      
      min_base_flow = [min_base_flow, base_flow].min
      max_base_flow = [max_base_flow, base_flow].max
      sum_base_flow += base_flow
      
      min_total_flow = [min_total_flow, total_design_flow].min
      max_total_flow = [max_total_flow, total_design_flow].max
      sum_total_flow += total_design_flow
      
      sum_population += population
      
      result_data = {
        conduit_id: conduit_id,
        population: population,
        eff: eff,
        eff_capped: eff_capped,
        peakable_flow: peakable_flow,
        base_flow: base_flow,
        total_flow: total_design_flow
      }
      
      results << result_data
      
      if !has_upstream[conduit_id]
        source_results << result_data
      elsif !has_downstream[conduit_id]
        outlet_results << result_data
      else
        through_results << result_data
      end
      
      updated += 1
      
    rescue => e
      errors += 1
      puts "  [X] ERROR: #{conduit_id} - #{e.message}" if debug_mode
    end
  end
  
  if transaction_started && !dry_run
    begin
      net.transaction_commit
      puts "\n[OK] Changes committed to network"
    rescue => e
      puts "\n[X] Error committing: #{e.message}"
    end
  elsif dry_run
    puts "\n[OK] Dry run complete - no changes made"
  else
    puts "\n[OK] Changes written directly"
  end
  
rescue => e
  if transaction_started
    begin
      net.transaction_rollback
      puts "\n[X] Transaction rolled back"
    rescue
    end
  end
  
  puts "\n[X] FATAL ERROR: #{e.message}"
  WSApplication.message_box(
    "FATAL ERROR\n\n#{e.message}",
    "OK",
    "!",
    false
  )
  exit
end

# ============================================================================
# STEP 4: ENHANCED STATISTICS
# ============================================================================

puts "\n" + "="*80
puts "CALCULATION RESULTS & FLOW COMPONENT ANALYSIS"
puts "="*80

puts "\nProcessing Summary:"
puts "  Total conduits: #{total_conduits}"
puts "  Successfully calculated: #{updated}"
puts "  Skipped (no population): #{skipped_no_pop}"
puts "  Errors: #{errors}"
puts "  Success rate: #{((updated.to_f / total_conduits) * 100).round(1)}%"

if updated > 0
  avg_peakable = sum_peakable_flow / updated
  avg_base = sum_base_flow / updated
  avg_total = sum_total_flow / updated
  avg_population = sum_population / updated
  avg_eff = results.map{|r| r[:eff_capped]}.sum / results.size
  
  puts "\n" + "-"*80
  puts "EFF (PEAKING FACTOR) STATISTICS"
  puts "-"*80
  puts "  Average EFF: #{avg_eff.round(2)}"
  puts "  Min EFF: #{results.map{|r| r[:eff_capped]}.min.round(2)}"
  puts "  Max EFF: #{results.map{|r| r[:eff_capped]}.max.round(2)}"
  puts ""
  puts "  This means average peak flow is #{avg_eff.round(2)}x the average flow"
  puts "  (e.g., EFF=2.0 means peak is 2x average daily flow)"
  
  puts "\n" + "-"*80
  puts "PEAKABLE FLOW STATISTICS (Trade Flow)"
  puts "-"*80
  puts "  Minimum: #{min_peakable_flow.round(4)} #{flow_units}"
  puts "  Maximum: #{max_peakable_flow.round(4)} #{flow_units}"
  puts "  Average: #{avg_peakable.round(4)} #{flow_units}"
  puts "  Total: #{sum_peakable_flow.round(2)} #{flow_units}"
  puts "  % of Total: #{((sum_peakable_flow / sum_total_flow) * 100).round(1)}%"
  
  puts "\n" + "-"*80
  puts "UNPEAKABLE FLOW STATISTICS (Base Flow)"
  puts "-"*80
  puts "  Minimum: #{min_base_flow.round(4)} #{flow_units}"
  puts "  Maximum: #{max_base_flow.round(4)} #{flow_units}"
  puts "  Average: #{avg_base.round(4)} #{flow_units}"
  puts "  Total: #{sum_base_flow.round(2)} #{flow_units}"
  puts "  % of Total: #{((sum_base_flow / sum_total_flow) * 100).round(1)}%"
  
  puts "\n" + "-"*80
  puts "TOTAL DESIGN FLOW STATISTICS"
  puts "-"*80
  puts "  Minimum: #{min_total_flow.round(4)} #{flow_units}"
  puts "  Maximum: #{max_total_flow.round(4)} #{flow_units}"
  puts "  Average: #{avg_total.round(4)} #{flow_units}"
  puts "  Total: #{sum_total_flow.round(2)} #{flow_units}"
  puts "  Peakable + Base: #{(sum_peakable_flow + sum_base_flow).round(2)} #{flow_units}"
  
  puts "\n" + "-"*80
  puts "POPULATION STATISTICS"
  puts "-"*80
  puts "  Average per conduit: #{avg_population.round(0)} people"
  puts "  Total contributing: #{sum_population.round(0)} people"
  puts "  Min: #{results.map{|r| r[:population]}.min.round(0)} people"
  puts "  Max: #{results.map{|r| r[:population]}.max.round(0)} people"
end

# ============================================================================
# TOPOLOGY-BASED STATISTICS
# ============================================================================

if show_topology && updated > 0
  puts "\n" + "="*80
  puts "TOPOLOGY-BASED ANALYSIS"
  puts "="*80
  
  if source_results.size > 0
    source_peakable = source_results.map{|r| r[:peakable_flow]}.sum
    source_base = source_results.map{|r| r[:base_flow]}.sum
    source_total = source_results.map{|r| r[:total_flow]}.sum
    
    puts "\n** STARTING POINTS"
    puts "-"*80
    puts "  Count: #{source_results.size}"
    puts "  Total peakable: #{source_peakable.round(2)} #{flow_units}"
    puts "  Total base: #{source_base.round(2)} #{flow_units}"
    puts "  Total flow: #{source_total.round(2)} #{flow_units}"
    puts "  Avg flow: #{(source_total / source_results.size).round(4)} #{flow_units}"
  end
  
  if outlet_results.size > 0
    outlet_peakable = outlet_results.map{|r| r[:peakable_flow]}.sum
    outlet_base = outlet_results.map{|r| r[:base_flow]}.sum
    outlet_total = outlet_results.map{|r| r[:total_flow]}.sum
    
    puts "\n** ENDING POINTS"
    puts "-"*80
    puts "  Count: #{outlet_results.size}"
    puts "  Total peakable: #{outlet_peakable.round(2)} #{flow_units}"
    puts "  Total base: #{outlet_base.round(2)} #{flow_units}"
    puts "  Total flow: #{outlet_total.round(2)} #{flow_units}"
    puts "  Avg flow: #{(outlet_total / outlet_results.size).round(4)} #{flow_units}"
    
    puts "\n  Top 5 Outlets by Total Flow:"
    outlet_results.sort_by{|r| -r[:total_flow]}.first(5).each_with_index do |r, idx|
      puts "    #{idx+1}. #{r[:conduit_id]}: #{r[:total_flow].round(4)} #{flow_units}"
      puts "        (Peakable: #{r[:peakable_flow].round(4)}, Base: #{r[:base_flow].round(4)})"
    end
  end
  
  if through_results.size > 0
    through_flows = through_results.map{|r| r[:total_flow]}
    through_pops = through_results.map{|r| r[:population]}
    
    puts "\n** THROUGH CONDUITS (Internal Network)"
    puts "-"*80
    puts "  Count: #{through_results.size}"
    puts "  Average flow: #{(through_flows.sum / through_results.size).round(4)} #{flow_units}"
    puts "  Average population: #{(through_pops.sum / through_results.size).round(0)} people"
    puts "  Min flow: #{through_flows.min.round(4)} #{flow_units}"
    puts "  Max flow: #{through_flows.max.round(4)} #{flow_units}"
  end
  
  if source_results.size > 0 && outlet_results.size > 0
    puts "\n** FLOW ACCUMULATION"
    puts "-"*80
    source_total_all = source_results.map{|r| r[:total_flow]}.sum
    outlet_total_all = outlet_results.map{|r| r[:total_flow]}.sum
    ratio = outlet_total_all > 0 ? (outlet_total_all / source_total_all) : 0
    
    puts "  Sources: #{source_total_all.round(2)} #{flow_units}"
    puts "  Outlets: #{outlet_total_all.round(2)} #{flow_units}"
    puts "  Ratio: #{ratio.round(2)}x"
    
    if ratio > 1.5
      puts "  [OK] Good accumulation - flow increases downstream"
    elsif ratio < 0.8
      puts "  [!] Low accumulation - check for losses or splits"
    else
      puts "  [OK] Moderate accumulation"
    end
  end
end

if eff_warnings.size > 0
  puts "\n[!] EFF Warnings:"
  eff_warnings.each { |w| puts "  #{w}" }
end

# ============================================================================
# STEP 5: Export to CSV
# ============================================================================

if export_csv && results.size > 0
  puts "\n" + "-"*80
  puts "EXPORTING RESULTS TO CSV"
  puts "-"*80
  
  timestamp_str = Time.now.strftime("%Y%m%d_%H%M%S")
  filename = "design_flows_#{timestamp_str}.csv"
  
  documents_path = File.join(ENV['USERPROFILE'] || ENV['HOME'] || '', 'Documents')
  
  csv_paths_to_try = []
  csv_paths_to_try << File.join(documents_path, filename) if File.directory?(documents_path)
  
  desktop_path = File.join(ENV['USERPROFILE'] || ENV['HOME'] || '', 'Desktop')
  csv_paths_to_try << File.join(desktop_path, filename) if File.directory?(desktop_path)
  
  temp_path = ENV['TEMP'] || ENV['TMP'] || 'C:/Temp'
  csv_paths_to_try << File.join(temp_path, filename) if File.directory?(temp_path)
  
  csv_saved = false
  final_path = nil
  
  csv_paths_to_try.each do |path|
    begin
      CSV.open(path, "wb") do |csv|
        csv << [
          "Conduit ID",
          "Position",
          "Population",
          "EFF (calc)",
          "EFF (capped)",
          "Peakable Flow (#{flow_units})",
          "Base Flow (#{flow_units})",
          "Total Flow (#{flow_units})"
        ]
        
        results.each do |row|
          position_type = if !has_upstream[row[:conduit_id]]
            "SOURCE"
          elsif !has_downstream[row[:conduit_id]]
            "OUTLET"
          else
            "THROUGH"
          end
          
          csv << [
            row[:conduit_id],
            position_type,
            row[:population].round(2),
            row[:eff].round(4),
            row[:eff_capped].round(4),
            row[:peakable_flow].round(6),
            row[:base_flow].round(6),
            row[:total_flow].round(6)
          ]
        end
      end
      
      csv_saved = true
      final_path = path
      break
      
    rescue => e
      puts "  [!] Could not write to #{path}: #{e.message}"
      next
    end
  end
  
  if csv_saved
    puts "[OK] Exported to: #{final_path}"
    puts "  Rows: #{results.size}"
    puts "  Includes: Position Type (SOURCE/OUTLET/THROUGH)"
    
    if RUBY_PLATFORM =~ /mswin|mingw|cygwin/
      begin
        system("explorer /select,\"#{final_path.gsub('/', '\\')}\"")
      rescue
      end
    end
  else
    puts "[X] Could not save CSV"
  end
end

# ============================================================================
# STEP 6: Final summary
# ============================================================================

summary = "Design Flow Calculation Complete!\n\n"
summary += "Mode: #{dry_run ? 'DRY RUN' : 'LIVE RUN'}\n\n"

summary += "Results:\n"
summary += "  Processed: #{processed}\n"
summary += "  Updated: #{updated}\n"
summary += "  Skipped: #{skipped_no_pop}\n\n"

if updated > 0
  avg_eff = results.map{|r| r[:eff_capped]}.sum / results.size
  
  summary += "EFF Statistics:\n"
  summary += "  Average EFF: #{avg_eff.round(2)}\n"
  summary += "  Min EFF: #{results.map{|r| r[:eff_capped]}.min.round(2)}\n"
  summary += "  Max EFF: #{results.map{|r| r[:eff_capped]}.max.round(2)}\n\n"
  
  summary += "This means:\n"
  summary += "  Average peak flow = #{avg_eff.round(2)}x the average flow\n\n"
  
  summary += "Flow Components:\n"
  summary += "  Peakable (trade_flow): #{sum_peakable_flow.round(2)} #{flow_units}\n"
  summary += "  Base (base_flow): #{sum_base_flow.round(2)} #{flow_units}\n"
  summary += "  Total: #{sum_total_flow.round(2)} #{flow_units}\n\n"
  
  peakable_pct = (sum_peakable_flow / sum_total_flow * 100).round(1)
  base_pct = (sum_base_flow / sum_total_flow * 100).round(1)
  
  summary += "  Peakable: #{peakable_pct}% of total\n"
  summary += "  Base: #{base_pct}% of total\n\n"
  
  summary += "Network:\n"
  summary += "  Sources: #{source_results.size}\n"
  summary += "  Outlets: #{outlet_results.size}\n\n"
end

summary += "Stored in:\n"
summary += "  trade_flow = Peakable flow (with EFF)\n"
summary += "  base_flow = Unpeakable flow (constant)\n"
summary += "  user_number_1 = Total design flow\n\n"

summary += "EFF represents how much peak flow exceeds average.\n"
summary += "Higher EFF = higher peaks (small populations)\n"
summary += "Lower EFF = flatter peaks (large populations)"

WSApplication.message_box(
  summary,
  "OK",
  "Information",
  false
)

puts "\n" + "="*80
puts "SCRIPT COMPLETE"
puts "="*80