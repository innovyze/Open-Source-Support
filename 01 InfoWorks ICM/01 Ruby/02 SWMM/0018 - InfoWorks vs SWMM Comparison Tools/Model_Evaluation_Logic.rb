# ICM InfoWorks vs ICM SWMM - COMPLETE MASTER SCRIPT (ENHANCED v2.2)
# Version: 2.2 - FIXED: Uses surface_type field for proper Pervious/Impervious matching
#
# CRITICAL FIX: Previous versions assumed Slot 1 = Pervious, Slot 2 = Impervious
#               This version reads hw_runoff_surface.surface_type to correctly identify surfaces
#
# SECTIONS:
#  1. InfoWorks Subcatchment Grid
#  2. InfoWorks Land Use Hierarchy
#  3. InfoWorks Runoff Surface Grid
#  4. SWMM Physical Properties (Roughness/Storage)
#  5. SWMM Infiltration Parameters (Non-Soil)
#  6. Infiltration Model Detection
#  7. Advanced Parameter Trace (with Surface Type Matching)
#  8. Area Distribution Analysis
#  9. Extended Parameter Comparison (with Surface Type Matching)
# 10. Parameter Mapping Reference
# 11. Mismatch Summary Report
# 12. CSV Export

# =============================================================================
# CONFIGURATION
# =============================================================================
PAGE_WIDTH = 180
TOLERANCE = 0.001          # Tolerance for numeric comparisons
EXPORT_CSV = true          # Set to false to disable CSV export
CSV_PATH = "C:/Temp/ICM_Comparison_Report.csv"  # Change as needed

# Surface type matching patterns (case-insensitive)
PERVIOUS_PATTERNS = ['pervious', 'perv', 'greenampt', 'green-ampt', 'horton']
IMPERVIOUS_PATTERNS = ['impervious', 'imperv', 'imp', 'fixed']

# =============================================================================
# HELPER: Safe Data Accessors
# =============================================================================
def safe_rows(net, table_name)
  return [] if net.nil?
  begin
    tables = net.tables rescue []
    return [] unless tables.any? { |t| t.name == table_name }
    return net.row_objects(table_name)
  rescue => e
    puts "Warning: Error accessing #{table_name}: #{e.message}" if $DEBUG
    return []
  end
end

def safe_get(obj, method_name, default=nil)
  begin
    val = obj.send(method_name)
    return val.nil? ? default : val
  rescue
    return default
  end
end

# Enhanced try_fields that returns both value AND the field name that worked
def try_fields_with_source(obj, field_list, default=nil)
  field_list.each do |f|
    val = safe_get(obj, f, nil)
    unless val.nil?
      return { value: val, source_field: f.to_s }
    end
  end
  return { value: default, source_field: "not_found" }
end

def try_fields(obj, field_list, default=nil)
  result = try_fields_with_source(obj, field_list, default)
  return result[:value]
end

def fmt_num(val, decimals=4)
  return "-" if val.nil?
  return sprintf("%.#{decimals}f", val) if val.is_a?(Numeric)
  return val.to_s
end

def check_diff(val1, val2, tolerance=TOLERANCE)
  return false unless val1.is_a?(Numeric) && val2.is_a?(Numeric)
  return (val1 - val2).abs > tolerance
end

# =============================================================================
# SURFACE TYPE CLASSIFICATION
# =============================================================================
def classify_surface_type(surface_type_str, runoff_volume_type_str=nil)
  return :unknown if surface_type_str.nil? && runoff_volume_type_str.nil?
  
  # Check surface_type field first (primary)
  if surface_type_str
    st = surface_type_str.to_s.downcase.strip
    return :impervious if IMPERVIOUS_PATTERNS.any? { |p| st.include?(p) }
    return :pervious if PERVIOUS_PATTERNS.any? { |p| st.include?(p) }
  end
  
  # Fall back to runoff_volume_type if surface_type not conclusive
  if runoff_volume_type_str
    rvt = runoff_volume_type_str.to_s.downcase.strip
    # "Fixed" runoff volume typically means impervious (fixed runoff coefficient)
    return :impervious if rvt.include?('fixed')
    # GreenAmpt, Horton typically mean pervious (infiltration-based)
    return :pervious if rvt.include?('green') || rvt.include?('horton')
  end
  
  return :unknown
end

def surface_type_label(classification)
  case classification
  when :pervious then "Pervious"
  when :impervious then "Impervious"
  else "Unknown"
  end
end

# =============================================================================
# MISMATCH TRACKING (Enhanced with source fields)
# =============================================================================
$mismatches = []
$stats = {
  iw_subcatchments: 0,
  sw_subcatchments: 0,
  matched_ids: 0,
  unmatched_sw: 0,
  unmatched_iw: 0,
  infiltration_types: Hash.new(0),
  parameter_mismatches: Hash.new(0),
  total_mismatches: 0,
  surface_type_counts: Hash.new(0)
}

def record_mismatch(subcatch_id, param_name, swmm_val, iw_val, category, swmm_source, iw_source)
  $mismatches << {
    id: subcatch_id,
    parameter: param_name,
    swmm_value: swmm_val,
    swmm_source_field: swmm_source,
    iw_value: iw_val,
    iw_source_field: iw_source,
    category: category,
    difference: (swmm_val.is_a?(Numeric) && iw_val.is_a?(Numeric)) ? (swmm_val - iw_val).abs : "N/A"
  }
  $stats[:parameter_mismatches][param_name] += 1
  $stats[:total_mismatches] += 1
end

# =============================================================================
# SETUP: Get Networks
# =============================================================================
cn = WSApplication.current_network
bn = WSApplication.background_network

iw_net = !safe_rows(cn, 'hw_subcatchment').empty? ? cn : (!safe_rows(bn, 'hw_subcatchment').empty? ? bn : nil)
sw_net = !safe_rows(cn, 'sw_subcatchment').empty? ? cn : (!safe_rows(bn, 'sw_subcatchment').empty? ? bn : nil)

puts "=" * PAGE_WIDTH
puts "MASTER REPORT: InfoWorks vs SWMM Comparison (Enhanced v2.2)"
puts "=" * PAGE_WIDTH
puts "InfoWorks Source: #{iw_net ? iw_net.model_object.name : 'Not Found'}"
puts "SWMM Source:      #{sw_net ? sw_net.model_object.name : 'Not Found'}"
puts "Timestamp:        #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
puts "Tolerance:        #{TOLERANCE}"
puts ""
puts "IMPORTANT: This version uses hw_runoff_surface.surface_type to correctly"
puts "           match Pervious/Impervious surfaces (not slot position)"
puts "=" * PAGE_WIDTH
puts ""

# =============================================================================
# PRE-PROCESSING: Build Lookups
# =============================================================================
iw_rs_map = {}           # runoff_index -> runoff_surface object
iw_rs_classified = {}    # runoff_index -> { object, classification, surface_type_str }
iw_lu_map = {}           # land_use_id -> array of runoff_index by slot
iw_sub_map = {}          # subcatchment_id -> land_use_id
iw_sub_data = {}         # subcatchment_id -> subcatchment object
sw_sub_data = {}         # id -> subcatchment object

if iw_net
  # Build runoff surface map with classification
  safe_rows(iw_net, 'hw_runoff_surface').each do |ro|
    rid = safe_get(ro, :runoff_index)
    iw_rs_map[rid] = ro
    
    surface_type_str = safe_get(ro, :surface_type, "")
    runoff_vol_type = safe_get(ro, :runoff_volume_type, "")
    classification = classify_surface_type(surface_type_str, runoff_vol_type)
    
    iw_rs_classified[rid] = {
      object: ro,
      classification: classification,
      surface_type_str: surface_type_str,
      runoff_volume_type: runoff_vol_type
    }
    
    $stats[:surface_type_counts][classification] += 1
  end
  
  # Build land use map
  safe_rows(iw_net, 'hw_land_use').each do |lu|
    surfaces = []
    (1..12).each { |i| surfaces[i] = safe_get(lu, "runoff_index_#{i}") }
    iw_lu_map[safe_get(lu, :land_use_id)] = surfaces
  end
  
  # Build subcatchment map
  safe_rows(iw_net, 'hw_subcatchment').each do |sc|
    sid = safe_get(sc, :subcatchment_id)
    iw_sub_map[sid] = safe_get(sc, :land_use_id)
    iw_sub_data[sid] = sc
    $stats[:iw_subcatchments] += 1
  end
end

if sw_net
  safe_rows(sw_net, 'sw_subcatchment').each do |sc|
    sid = safe_get(sc, :id)
    sw_sub_data[sid] = sc
    $stats[:sw_subcatchments] += 1
  end
end

# Track matched/unmatched
sw_sub_data.keys.each do |sid|
  if iw_sub_map.key?(sid)
    $stats[:matched_ids] += 1
  else
    $stats[:unmatched_sw] += 1
  end
end

iw_sub_data.keys.each do |sid|
  unless sw_sub_data.key?(sid)
    $stats[:unmatched_iw] += 1
  end
end

# =============================================================================
# HELPER: Get surfaces by type for a subcatchment
# =============================================================================
def get_surfaces_by_type(sid, iw_sub_map, iw_lu_map, iw_rs_classified)
  result = {
    pervious: [],    # Array of { slot:, index:, object:, surface_type_str: }
    impervious: [],
    unknown: []
  }
  
  lu_id = iw_sub_map[sid]
  return result unless lu_id
  
  surfaces = iw_lu_map[lu_id]
  return result unless surfaces
  
  (1..12).each do |slot|
    rid = surfaces[slot]
    next if rid.nil? || rid.to_s.strip.empty?
    
    classified = iw_rs_classified[rid]
    next unless classified
    
    entry = {
      slot: slot,
      index: rid,
      object: classified[:object],
      surface_type_str: classified[:surface_type_str],
      runoff_volume_type: classified[:runoff_volume_type]
    }
    
    case classified[:classification]
    when :pervious
      result[:pervious] << entry
    when :impervious
      result[:impervious] << entry
    else
      result[:unknown] << entry
    end
  end
  
  result
end

# =============================================================================
# SECTION 1: INFOWORKS SUBCATCHMENT GRID
# =============================================================================
if iw_net
  puts "SECTION 1: InfoWorks Subcatchment Grid"
  puts "-" * PAGE_WIDTH
  headers = ["ID", "Land Use", "Total Area", "Contrib Area", "Area 1 %", "Area 2 %", "Area 3 %", "Slope", "Node"]
  fmt_sc = "%-15s %-15s %-12s %-12s %-10s %-10s %-10s %-10s %-15s"
  puts sprintf(fmt_sc, *headers)
  puts "-" * PAGE_WIDTH

  safe_rows(iw_net, 'hw_subcatchment').each do |sc|
    vals = [
      safe_get(sc, :subcatchment_id, "?").to_s[0,14],
      safe_get(sc, :land_use_id, "-").to_s[0,14],
      fmt_num(safe_get(sc, :total_area, 0.0), 3),
      fmt_num(safe_get(sc, :contributing_area, 0.0), 3),
      fmt_num(safe_get(sc, :area_percent_1, 0.0), 1),
      fmt_num(safe_get(sc, :area_percent_2, 0.0), 1),
      fmt_num(safe_get(sc, :area_percent_3, 0.0), 1),
      fmt_num(try_fields(sc, [:ground_slope, :slope, :average_slope], 0.0), 3),
      safe_get(sc, :node_id, "-").to_s[0,14]
    ]
    puts sprintf(fmt_sc, *vals)
  end
  puts ""
end

# =============================================================================
# SECTION 2: INFOWORKS LAND USE HIERARCHY
# =============================================================================
if iw_net
  puts "SECTION 2: InfoWorks Land Use Hierarchy (with Surface Type Classification)"
  puts "-" * PAGE_WIDTH
  fmt = "%-15s %-15s %-15s %-12s %-15s %-15s %-15s"
  puts sprintf(fmt, "TYPE", "ID", "SURFACE TYPE", "CLASSIFIED", "ROUTE VAL", "LOSS VAL", "VOL TYPE")
  puts "-" * PAGE_WIDTH

  safe_rows(iw_net, 'hw_land_use').each do |land_use|
    lu_id = safe_get(land_use, :land_use_id, "?")
    puts sprintf(fmt, "Land Use", lu_id.to_s[0,14], safe_get(land_use, :land_use_description, "").to_s[0,14], "", "", "", "")

    (1..12).each do |i|
      rid = safe_get(land_use, "runoff_index_#{i}")
      next if rid.nil? || rid.to_s.strip.empty?
      
      classified = iw_rs_classified[rid]
      if classified
        ro = classified[:object]
        puts sprintf(fmt, 
          "  Slot #{i}", rid.to_s[0,14], 
          classified[:surface_type_str].to_s[0,14],
          surface_type_label(classified[:classification]),
          fmt_num(safe_get(ro, :runoff_routing_value, 0.0), 4),
          fmt_num(safe_get(ro, :initial_loss_value, 0.0), 4),
          classified[:runoff_volume_type].to_s[0,14]
        )
      end
    end
  end
  puts ""
end

# =============================================================================
# SECTION 3: INFOWORKS RUNOFF SURFACE GRID (with Classification)
# =============================================================================
if iw_net
  puts "SECTION 3: InfoWorks Runoff Surface Grid (with Surface Type)"
  puts "-" * PAGE_WIDTH
  headers = ["ID", "Surface Type", "Classified", "Route Type", "Route Val", "Vol Type", "Loss Type", "Loss Val", "Slope"]
  fmt_grid = "%-10s %-15s %-12s %-12s %-10s %-12s %-12s %-10s %-10s"
  puts sprintf(fmt_grid, *headers)
  puts "-" * PAGE_WIDTH

  safe_rows(iw_net, 'hw_runoff_surface').each do |ro|
    rid = safe_get(ro, :runoff_index, "?")
    classified = iw_rs_classified[rid]
    
    vals = [
      rid.to_s[0,9],
      safe_get(ro, :surface_type, "-").to_s[0,14],
      classified ? surface_type_label(classified[:classification]) : "-",
      safe_get(ro, :runoff_routing_type, "-").to_s[0,11],
      fmt_num(safe_get(ro, :runoff_routing_value, 0.0), 4),
      safe_get(ro, :runoff_volume_type, "-").to_s[0,11],
      safe_get(ro, :initial_loss_type, "-").to_s[0,11],
      fmt_num(safe_get(ro, :initial_loss_value, 0.0), 4),
      fmt_num(safe_get(ro, :ground_slope, 0.0), 4)
    ]
    puts sprintf(fmt_grid, *vals)
  end
  puts ""
end

# =============================================================================
# SECTION 4: SWMM PHYSICAL PROPERTIES
# =============================================================================
if sw_net
  puts "SECTION 4: SWMM Subcatchment Physical Properties"
  puts "-" * PAGE_WIDTH
  fmt_swmm = "%-15s %-12s %-12s %-12s %-12s %-12s %-12s %-12s %-12s"
  puts sprintf(fmt_swmm, "ID", "Area", "% Imperv", "Width", "Slope %", "Imp Rough", "Perv Rough", "Imp D-Stor", "Perv D-Stor")
  puts "-" * PAGE_WIDTH
  
  safe_rows(sw_net, 'sw_subcatchment').each do |sc|
    sid = safe_get(sc, :id, "?").to_s[0,14]
    area = try_fields(sc, [:area, :total_area], 0.0)
    pct_imp = try_fields(sc, [:percent_impervious, :pct_imperv, :imperviousness], 0.0)
    width = try_fields(sc, [:width, :characteristic_width], 0.0)
    slope = try_fields(sc, [:slope, :average_slope, :ground_slope], 0.0)
    n_imp = try_fields(sc, [:roughness_impervious, :n_imperv], 0.0)
    n_perv = try_fields(sc, [:roughness_pervious, :n_perv], 0.0)
    d_imp = try_fields(sc, [:storage_impervious, :ds_imperv, :depression_storage_impervious], 0.0)
    d_perv = try_fields(sc, [:storage_pervious, :ds_perv, :depression_storage_pervious], 0.0)
    
    puts sprintf(fmt_swmm, sid,
      fmt_num(area, 3), fmt_num(pct_imp, 2), fmt_num(width, 2), fmt_num(slope, 3),
      fmt_num(n_imp, 4), fmt_num(n_perv, 4), fmt_num(d_imp, 4), fmt_num(d_perv, 4))
  end
  puts ""
end

# =============================================================================
# SECTION 5: SWMM NON-SOIL INFILTRATION
# =============================================================================
if sw_net
  puts "SECTION 5: SWMM Non-Soil Infiltration Parameters (Detailed)"
  puts "-" * PAGE_WIDTH
  headers = ["ID", "Max Rate", "Min Rate", "Decay", "Max Vol", "Suction", "K (Cond)", "Deficit", "CurveNum", "Dry Time"]
  fmt = "%-15s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s"
  puts sprintf(fmt, *headers)
  puts "-" * PAGE_WIDTH

  safe_rows(sw_net, 'sw_subcatchment').each do |sc|
    sid = safe_get(sc, :id, "?").to_s[0,14]
    max_r = try_fields(sc, [:max_rate, :infiltration_initial], 0.0)
    min_r = try_fields(sc, [:min_rate, :infiltration_limiting], 0.0)
    decay = try_fields(sc, [:decay_constant, :infiltration_decay], 0.0)
    max_v = try_fields(sc, [:max_volume, :infiltration_max_volume], 0.0)
    suction = try_fields(sc, [:suction_head, :average_capillary_suction], 0.0)
    cond    = try_fields(sc, [:conductivity, :saturated_hydraulic_conductivity], 0.0)
    deficit = try_fields(sc, [:initial_deficit, :initial_moisture_deficit], 0.0)
    cn      = try_fields(sc, [:curve_number], 0.0)
    dry     = try_fields(sc, [:drying_time], 0.0)

    puts sprintf(fmt, sid,
      fmt_num(max_r, 2), fmt_num(min_r, 2), fmt_num(decay, 2), fmt_num(max_v, 2),
      fmt_num(suction, 1), fmt_num(cond, 2), fmt_num(deficit, 3),
      fmt_num(cn, 1), fmt_num(dry, 1))
  end
  puts ""
end

# =============================================================================
# SECTION 6: INFILTRATION MODEL DETECTION
# =============================================================================
if sw_net
  puts "SECTION 6: Infiltration Model Detection (Checking Values > 0)"
  puts "-" * PAGE_WIDTH
  fmt_inf = "%-15s | %-14s %-12s %-12s %-12s %-12s"
  puts sprintf(fmt_inf, "Subcatchment", "Detected Type", "Param 1", "Param 2", "Param 3", "Param 4")
  puts "-" * PAGE_WIDTH

  safe_rows(sw_net, 'sw_subcatchment').each do |sc|
    sid = safe_get(sc, :id).to_s[0,14]
    h_max = try_fields(sc, [:max_rate, :infiltration_initial], 0.0).to_f
    h_min = try_fields(sc, [:min_rate, :infiltration_limiting], 0.0).to_f
    h_decay = try_fields(sc, [:decay_constant, :infiltration_decay], 0.0).to_f
    h_maxvol = try_fields(sc, [:max_volume, :infiltration_max_volume], 0.0).to_f
    ga_suc = try_fields(sc, [:suction_head, :average_capillary_suction], 0.0).to_f
    ga_con = try_fields(sc, [:conductivity, :saturated_hydraulic_conductivity], 0.0).to_f
    ga_def = try_fields(sc, [:initial_deficit, :initial_moisture_deficit], 0.0).to_f
    cn_val = try_fields(sc, [:curve_number], 0.0).to_f
    
    type = "None"; p1 = 0.0; p2 = 0.0; p3 = 0.0; p4 = 0.0

    if h_max > 0 || h_min > 0
      if h_maxvol > 0
        type = "Mod Horton"
        p1 = h_max; p2 = h_min; p3 = h_decay; p4 = h_maxvol
      else
        type = "Horton"
        p1 = h_max; p2 = h_min; p3 = h_decay
      end
    elsif ga_suc > 0 || ga_con > 0
      type = "Green-Ampt"
      p1 = ga_con; p2 = ga_suc; p3 = ga_def
    elsif cn_val > 0
      type = "Curve Number"
      p1 = cn_val
    end
    
    $stats[:infiltration_types][type] += 1
    
    puts sprintf(fmt_inf, sid, type, fmt_num(p1, 3), fmt_num(p2, 3), fmt_num(p3, 3), fmt_num(p4, 3))
  end
  puts ""
end

# =============================================================================
# SECTION 7: ROUGHNESS COMPARISON (Using Surface Type Matching)
# =============================================================================
if sw_net && iw_net
  puts "SECTION 7: ROUGHNESS COMPARISON (Using Surface Type Field)"
  puts ""
  puts "MATCHING METHOD: Uses hw_runoff_surface.surface_type to identify Pervious/Impervious"
  puts "                 NOT based on slot position"
  puts ""
  puts "PARAMETER MAPPING:"
  puts "  SWMM roughness_pervious    <-->  IW runoff_routing_value WHERE surface_type = 'Pervious'"
  puts "  SWMM roughness_impervious  <-->  IW runoff_routing_value WHERE surface_type = 'Impervious'"
  puts ""
  puts "-" * PAGE_WIDTH
  fmt_trace = "%-12s | %-8s | %-28s %-8s | %-28s %-8s | %-4s"
  puts sprintf(fmt_trace, "Subcatch", "Type", "SWMM Source", "Value", "IW Source (surface_type)", "Value", "Diff")
  puts "-" * PAGE_WIDTH

  sw_sub_data.each do |sid, sw_sc|
    # Get SWMM values
    sw_n_p_result = try_fields_with_source(sw_sc, [:roughness_pervious, :n_perv], 0.0)
    sw_n_p = sw_n_p_result[:value]
    sw_n_p_src = "sw_subcatchment.#{sw_n_p_result[:source_field]}"
    
    sw_n_i_result = try_fields_with_source(sw_sc, [:roughness_impervious, :n_imperv], 0.0)
    sw_n_i = sw_n_i_result[:value]
    sw_n_i_src = "sw_subcatchment.#{sw_n_i_result[:source_field]}"
    
    # Get InfoWorks surfaces by type
    surfaces = get_surfaces_by_type(sid, iw_sub_map, iw_lu_map, iw_rs_classified)
    
    # Get pervious surface (first one if multiple)
    iw_n_p = nil; iw_n_p_src = "-"
    if surfaces[:pervious].any?
      perv = surfaces[:pervious].first
      iw_n_p = safe_get(perv[:object], :runoff_routing_value, nil)
      iw_n_p_src = "hw_rs[#{perv[:index]}] (#{perv[:surface_type_str]})"
    end
    
    # Get impervious surface (first one if multiple)
    iw_n_i = nil; iw_n_i_src = "-"
    if surfaces[:impervious].any?
      imp = surfaces[:impervious].first
      iw_n_i = safe_get(imp[:object], :runoff_routing_value, nil)
      iw_n_i_src = "hw_rs[#{imp[:index]}] (#{imp[:surface_type_str]})"
    end
    
    diff_p = check_diff(sw_n_p, iw_n_p)
    diff_i = check_diff(sw_n_i, iw_n_i)
    
    # Record mismatches
    if diff_p
      record_mismatch(sid, "Roughness Pervious (N)", sw_n_p, iw_n_p, "Roughness", sw_n_p_src, iw_n_p_src)
    end
    if diff_i
      record_mismatch(sid, "Roughness Impervious (N)", sw_n_i, iw_n_i, "Roughness", sw_n_i_src, iw_n_i_src)
    end
    
    # Print pervious row
    puts sprintf(fmt_trace, sid[0,12], "Pervious",
      sw_n_p_src[0,27], fmt_num(sw_n_p, 4),
      iw_n_p_src[0,27], iw_n_p ? fmt_num(iw_n_p, 4) : "-",
      diff_p ? "!!" : "")
    
    # Print impervious row  
    puts sprintf(fmt_trace, "", "Imperv",
      sw_n_i_src[0,27], fmt_num(sw_n_i, 4),
      iw_n_i_src[0,27], iw_n_i ? fmt_num(iw_n_i, 4) : "-",
      diff_i ? "!!" : "")
    
    # Warn if multiple surfaces of same type
    if surfaces[:pervious].length > 1
      puts sprintf("%-12s | WARNING: %d pervious surfaces found, using first (slots: %s)", 
        "", surfaces[:pervious].length, surfaces[:pervious].map{|s| s[:slot]}.join(","))
    end
    if surfaces[:impervious].length > 1
      puts sprintf("%-12s | WARNING: %d impervious surfaces found, using first (slots: %s)", 
        "", surfaces[:impervious].length, surfaces[:impervious].map{|s| s[:slot]}.join(","))
    end
    
    puts ""
  end
  puts ""
end

# =============================================================================
# SECTION 8: AREA DISTRIBUTION ANALYSIS
# =============================================================================
if iw_net
  puts "SECTION 8: AREA DISTRIBUTION (with Surface Type)"
  puts "-" * PAGE_WIDTH
  fmt_area = "%-15s | %-10s | %-6s %-10s %-12s | %-6s %-10s %-12s | %-6s %-10s %-12s"
  puts sprintf(fmt_area, "Subcatchment", "Total Ha", "Slot1%", "Slot1 Ha", "Slot1 Type", "Slot2%", "Slot2 Ha", "Slot2 Type", "Slot3%", "Slot3 Ha", "Slot3 Type")
  puts "-" * PAGE_WIDTH

  safe_rows(iw_net, 'hw_subcatchment').each do |sc|
    sid = safe_get(sc, :subcatchment_id).to_s
    total_area = safe_get(sc, :total_area, 0.0)
    ap1 = safe_get(sc, :area_percent_1, 0.0)
    ap2 = safe_get(sc, :area_percent_2, 0.0)
    ap3 = safe_get(sc, :area_percent_3, 0.0)
    
    # Get surface types for each slot
    lu_id = iw_sub_map[sid]
    surfaces = iw_lu_map[lu_id] if lu_id
    
    type1 = "-"; type2 = "-"; type3 = "-"
    if surfaces
      if surfaces[1] && iw_rs_classified[surfaces[1]]
        type1 = iw_rs_classified[surfaces[1]][:surface_type_str].to_s[0,11]
      end
      if surfaces[2] && iw_rs_classified[surfaces[2]]
        type2 = iw_rs_classified[surfaces[2]][:surface_type_str].to_s[0,11]
      end
      if surfaces[3] && iw_rs_classified[surfaces[3]]
        type3 = iw_rs_classified[surfaces[3]][:surface_type_str].to_s[0,11]
      end
    end
    
    puts sprintf(fmt_area, sid[0,14], fmt_num(total_area, 3),
      fmt_num(ap1, 1), fmt_num(total_area * ap1 / 100.0, 3), type1,
      fmt_num(ap2, 1), fmt_num(total_area * ap2 / 100.0, 3), type2,
      fmt_num(ap3, 1), fmt_num(total_area * ap3 / 100.0, 3), type3)
  end
  puts ""
end

# =============================================================================
# SECTION 9: EXTENDED PARAMETER COMPARISON (with Surface Type Matching)
# =============================================================================
if sw_net && iw_net
  puts "SECTION 9: EXTENDED PARAMETER COMPARISON (Using Surface Type)"
  puts ""
  puts "MATCHING METHOD: Uses hw_runoff_surface.surface_type to identify Pervious/Impervious"
  puts ""
  puts "-" * PAGE_WIDTH
  
  fmt_ext = "%-12s | %-12s | %-28s %-8s | %-28s %-8s | %-4s"
  puts sprintf(fmt_ext, "Subcatch", "Parameter", "SWMM Source", "Value", "IW Source", "Value", "Diff")
  puts "-" * PAGE_WIDTH

  sw_sub_data.each do |sid, sw_sc|
    iw_sc = iw_sub_data[sid]
    next unless iw_sc
    
    surfaces = get_surfaces_by_type(sid, iw_sub_map, iw_lu_map, iw_rs_classified)
    
    # --- AREA COMPARISON ---
    sw_area_result = try_fields_with_source(sw_sc, [:area, :total_area], 0.0)
    sw_area = sw_area_result[:value]
    sw_area_src = "sw_sub.#{sw_area_result[:source_field]}"
    
    iw_area = safe_get(iw_sc, :total_area, 0.0)
    iw_area_src = "hw_sub.total_area"
    
    diff_area = check_diff(sw_area, iw_area, 0.01)
    if diff_area
      record_mismatch(sid, "Area", sw_area, iw_area, "Geometry", sw_area_src, iw_area_src)
    end
    
    puts sprintf(fmt_ext, sid[0,12], "Area",
      sw_area_src[0,27], fmt_num(sw_area, 3),
      iw_area_src[0,27], fmt_num(iw_area, 3),
      diff_area ? "!!" : "")
    
    # --- SLOPE COMPARISON ---
    sw_slope_result = try_fields_with_source(sw_sc, [:slope, :average_slope, :ground_slope], 0.0)
    sw_slope = sw_slope_result[:value]
    sw_slope_src = "sw_sub.#{sw_slope_result[:source_field]}"
    
    iw_slope_result = try_fields_with_source(iw_sc, [:ground_slope, :slope, :average_slope], 0.0)
    iw_slope = iw_slope_result[:value]
    iw_slope_src = "hw_sub.#{iw_slope_result[:source_field]}"
    
    diff_slope = check_diff(sw_slope, iw_slope)
    if diff_slope
      record_mismatch(sid, "Slope", sw_slope, iw_slope, "Geometry", sw_slope_src, iw_slope_src)
    end
    
    puts sprintf(fmt_ext, "", "Slope",
      sw_slope_src[0,27], fmt_num(sw_slope, 4),
      iw_slope_src[0,27], fmt_num(iw_slope, 4),
      diff_slope ? "!!" : "")
    
    # --- DEPRESSION STORAGE IMPERVIOUS (using surface_type) ---
    sw_d_imp_result = try_fields_with_source(sw_sc, [:storage_impervious, :ds_imperv, :depression_storage_impervious], 0.0)
    sw_d_imp = sw_d_imp_result[:value]
    sw_d_imp_src = "sw_sub.#{sw_d_imp_result[:source_field]}"
    
    iw_d_imp = nil; iw_d_imp_src = "-"
    if surfaces[:impervious].any?
      imp = surfaces[:impervious].first
      iw_d_imp = safe_get(imp[:object], :initial_loss_value, nil)
      iw_d_imp_src = "hw_rs[#{imp[:index]}].init_loss (#{imp[:surface_type_str][0,8]})"
    end
    
    diff_d_imp = iw_d_imp ? check_diff(sw_d_imp, iw_d_imp) : false
    if diff_d_imp
      record_mismatch(sid, "Depression Storage Impervious", sw_d_imp, iw_d_imp, "Storage", sw_d_imp_src, iw_d_imp_src)
    end
    
    puts sprintf(fmt_ext, "", "D-Stor Imp",
      sw_d_imp_src[0,27], fmt_num(sw_d_imp, 4),
      iw_d_imp_src[0,27], iw_d_imp ? fmt_num(iw_d_imp, 4) : "-",
      diff_d_imp ? "!!" : "")
    
    # --- DEPRESSION STORAGE PERVIOUS (using surface_type) ---
    sw_d_perv_result = try_fields_with_source(sw_sc, [:storage_pervious, :ds_perv, :depression_storage_pervious], 0.0)
    sw_d_perv = sw_d_perv_result[:value]
    sw_d_perv_src = "sw_sub.#{sw_d_perv_result[:source_field]}"
    
    iw_d_perv = nil; iw_d_perv_src = "-"
    if surfaces[:pervious].any?
      perv = surfaces[:pervious].first
      iw_d_perv = safe_get(perv[:object], :initial_loss_value, nil)
      iw_d_perv_src = "hw_rs[#{perv[:index]}].init_loss (#{perv[:surface_type_str][0,8]})"
    end
    
    diff_d_perv = iw_d_perv ? check_diff(sw_d_perv, iw_d_perv) : false
    if diff_d_perv
      record_mismatch(sid, "Depression Storage Pervious", sw_d_perv, iw_d_perv, "Storage", sw_d_perv_src, iw_d_perv_src)
    end
    
    puts sprintf(fmt_ext, "", "D-Stor Perv",
      sw_d_perv_src[0,27], fmt_num(sw_d_perv, 4),
      iw_d_perv_src[0,27], iw_d_perv ? fmt_num(iw_d_perv, 4) : "-",
      diff_d_perv ? "!!" : "")
    
    puts "-" * PAGE_WIDTH
  end
  puts ""
  
  # --- PERCENT IMPERVIOUS COMPARISON ---
  puts "SECTION 9B: IMPERVIOUS PERCENTAGE COMPARISON"
  puts ""
  puts "MATCHING: Sums area_percent for all slots where surface_type = 'Impervious'"
  puts ""
  puts "-" * PAGE_WIDTH
  fmt_imp = "%-12s | %-28s %-8s | %-35s %-8s | %-4s"
  puts sprintf(fmt_imp, "Subcatch", "SWMM Source", "Value", "IW Source (sum of Impervious slots)", "Value", "Diff")
  puts "-" * PAGE_WIDTH
  
  sw_sub_data.each do |sid, sw_sc|
    iw_sc = iw_sub_data[sid]
    next unless iw_sc
    
    sw_pct_result = try_fields_with_source(sw_sc, [:percent_impervious, :pct_imperv, :imperviousness], 0.0)
    sw_pct_imp = sw_pct_result[:value]
    sw_pct_src = "sw_sub.#{sw_pct_result[:source_field]}"
    
    # Calculate IW impervious % by summing area_percent for impervious surfaces
    lu_id = iw_sub_map[sid]
    surfaces_arr = iw_lu_map[lu_id] if lu_id
    
    iw_pct_imp = 0.0
    iw_imp_slots = []
    
    if surfaces_arr
      (1..12).each do |slot|
        rid = surfaces_arr[slot]
        next if rid.nil?
        
        classified = iw_rs_classified[rid]
        next unless classified && classified[:classification] == :impervious
        
        # Get the area_percent for this slot
        ap = safe_get(iw_sc, "area_percent_#{slot}", 0.0)
        iw_pct_imp += ap if ap
        iw_imp_slots << "slot#{slot}=#{fmt_num(ap,1)}%"
      end
    end
    
    iw_pct_src = iw_imp_slots.any? ? iw_imp_slots.join("+") : "no impervious slots"
    
    diff_imp = check_diff(sw_pct_imp, iw_pct_imp, 1.0)  # 1% tolerance
    
    if diff_imp
      record_mismatch(sid, "Percent Impervious", sw_pct_imp, iw_pct_imp, "Imperviousness", sw_pct_src, iw_pct_src)
    end
    
    puts sprintf(fmt_imp, sid[0,12],
      sw_pct_src[0,27], fmt_num(sw_pct_imp, 2),
      iw_pct_src[0,34], fmt_num(iw_pct_imp, 2),
      diff_imp ? "!!" : "")
  end
  puts ""
end

# =============================================================================
# SECTION 10: PARAMETER MAPPING REFERENCE
# =============================================================================
puts "=" * PAGE_WIDTH
puts "SECTION 10: PARAMETER MAPPING REFERENCE"
puts "=" * PAGE_WIDTH
puts ""
puts "CRITICAL: Matching is based on hw_runoff_surface.surface_type field, NOT slot position"
puts ""

fmt_map = "%-35s | %-45s | %-50s"
puts sprintf(fmt_map, "PARAMETER", "SWMM SOURCE", "INFOWORKS SOURCE")
puts "-" * PAGE_WIDTH

mappings = [
  ["Roughness - Pervious (Manning's N)", "sw_subcatchment.roughness_pervious", "hw_runoff_surface.runoff_routing_value WHERE surface_type='Pervious'"],
  ["Roughness - Impervious (Manning's N)", "sw_subcatchment.roughness_impervious", "hw_runoff_surface.runoff_routing_value WHERE surface_type='Impervious'"],
  ["Depression Storage - Pervious", "sw_subcatchment.storage_pervious", "hw_runoff_surface.initial_loss_value WHERE surface_type='Pervious'"],
  ["Depression Storage - Impervious", "sw_subcatchment.storage_impervious", "hw_runoff_surface.initial_loss_value WHERE surface_type='Impervious'"],
  ["Total Area", "sw_subcatchment.area", "hw_subcatchment.total_area"],
  ["Average Slope", "sw_subcatchment.slope", "hw_subcatchment.ground_slope"],
  ["Percent Impervious", "sw_subcatchment.percent_impervious", "SUM(area_percent_N) WHERE slot N surface_type='Impervious'"],
  ["Width", "sw_subcatchment.width", "Calculated from area/length"],
  ["Outlet Node", "sw_subcatchment.outlet", "hw_subcatchment.node_id"]
]

mappings.each do |m|
  puts sprintf(fmt_map, m[0], m[1], m[2])
end

puts ""
puts "SURFACE TYPE CLASSIFICATION:"
puts "  'Impervious' detected from: surface_type contains 'impervious', 'imperv', 'imp'"
puts "                          or: runoff_volume_type = 'Fixed'"
puts "  'Pervious' detected from:   surface_type contains 'pervious', 'perv'"
puts "                          or: runoff_volume_type = 'GreenAmpt', 'Horton'"
puts ""
puts "INFOWORKS HIERARCHY:"
puts "  hw_subcatchment --> land_use_id --> hw_land_use --> runoff_index_N --> hw_runoff_surface"
puts "                                                                          |-> surface_type"
puts ""

# Surface type distribution
puts "SURFACE TYPE DISTRIBUTION IN THIS MODEL:"
puts "-" * 60
$stats[:surface_type_counts].each do |type, count|
  puts sprintf("  %-20s %d surfaces", surface_type_label(type) + ":", count)
end
puts ""

# =============================================================================
# SECTION 11: MISMATCH SUMMARY REPORT
# =============================================================================
puts "=" * PAGE_WIDTH
puts "SECTION 11: MISMATCH SUMMARY REPORT"
puts "=" * PAGE_WIDTH
puts ""

# Statistics Summary
puts "OVERALL STATISTICS"
puts "-" * 60
puts sprintf("%-40s %s", "InfoWorks Subcatchments:", $stats[:iw_subcatchments])
puts sprintf("%-40s %s", "SWMM Subcatchments:", $stats[:sw_subcatchments])
puts sprintf("%-40s %s", "Matched IDs:", $stats[:matched_ids])
puts sprintf("%-40s %s", "Unmatched SWMM (no IW equivalent):", $stats[:unmatched_sw])
puts sprintf("%-40s %s", "Unmatched InfoWorks (no SWMM equiv):", $stats[:unmatched_iw])
puts sprintf("%-40s %s", "Total Parameter Mismatches:", $stats[:total_mismatches])
puts ""

# Infiltration Type Summary
puts "INFILTRATION MODEL DISTRIBUTION"
puts "-" * 60
$stats[:infiltration_types].each do |type, count|
  puts sprintf("%-40s %d", type + ":", count)
end
puts ""

# Parameter Mismatch Summary
if $stats[:parameter_mismatches].any?
  puts "PARAMETER MISMATCH COUNTS"
  puts "-" * 60
  $stats[:parameter_mismatches].sort_by { |k, v| -v }.each do |param, count|
    puts sprintf("%-40s %d", param + ":", count)
  end
  puts ""
end

# Detailed Mismatch List (Top 50)
if $mismatches.any?
  puts "DETAILED MISMATCH LIST (Top 50)"
  puts "-" * PAGE_WIDTH
  fmt_mm = "%-12s %-28s %-8s %-28s %-8s %-28s"
  puts sprintf(fmt_mm, "Subcatch", "Parameter", "SW Val", "SWMM Source", "IW Val", "IW Source")
  puts "-" * PAGE_WIDTH
  
  $mismatches.first(50).each do |mm|
    puts sprintf(fmt_mm, 
      mm[:id].to_s[0,11],
      mm[:parameter].to_s[0,27],
      fmt_num(mm[:swmm_value], 4),
      mm[:swmm_source_field].to_s[0,27],
      fmt_num(mm[:iw_value], 4),
      mm[:iw_source_field].to_s[0,27])
  end
  
  if $mismatches.length > 50
    puts ""
    puts "... and #{$mismatches.length - 50} more mismatches (see CSV export for complete list)"
  end
  puts ""
end

# Unmatched Subcatchments
if $stats[:unmatched_sw] > 0 || $stats[:unmatched_iw] > 0
  puts "UNMATCHED SUBCATCHMENTS"
  puts "-" * 60
  
  if $stats[:unmatched_sw] > 0
    puts "SWMM subcatchments with no InfoWorks match:"
    sw_sub_data.keys.each do |sid|
      unless iw_sub_map.key?(sid)
        puts "  - #{sid}"
      end
    end
    puts ""
  end
  
  if $stats[:unmatched_iw] > 0
    puts "InfoWorks subcatchments with no SWMM match:"
    iw_sub_data.keys.each do |sid|
      unless sw_sub_data.key?(sid)
        puts "  - #{sid}"
      end
    end
    puts ""
  end
end

# =============================================================================
# SECTION 12: CSV EXPORT
# =============================================================================
if EXPORT_CSV && $mismatches.any?
  puts "SECTION 12: CSV EXPORT"
  puts "-" * 60
  
  begin
    File.open(CSV_PATH, 'w') do |f|
      # Header
      f.puts "Subcatchment,Parameter,SWMM_Value,SWMM_Source_Field,IW_Value,IW_Source_Field,Difference,Category"
      
      # Data rows
      $mismatches.each do |mm|
        swmm_val = mm[:swmm_value].is_a?(Numeric) ? mm[:swmm_value] : "\"#{mm[:swmm_value]}\""
        iw_val = mm[:iw_value].is_a?(Numeric) ? mm[:iw_value] : "\"#{mm[:iw_value]}\""
        diff_val = mm[:difference].is_a?(Numeric) ? mm[:difference] : "\"#{mm[:difference]}\""
        
        f.puts "#{mm[:id]},#{mm[:parameter]},#{swmm_val},\"#{mm[:swmm_source_field]}\",#{iw_val},\"#{mm[:iw_source_field]}\",#{diff_val},#{mm[:category]}"
      end
    end
    puts "CSV exported successfully to: #{CSV_PATH}"
  rescue => e
    puts "CSV export failed: #{e.message}"
    puts "Tip: Check if the path exists and you have write permissions"
  end
  puts ""
end

# =============================================================================
# FINAL SUMMARY
# =============================================================================
puts ""
puts "=" * PAGE_WIDTH
puts "MASTER ANALYSIS COMPLETE (v2.2 - Surface Type Matching)"
puts "=" * PAGE_WIDTH
puts ""
puts "Key Findings:"
puts "-" * 60

if $stats[:total_mismatches] == 0
  puts "✓ No parameter mismatches detected between SWMM and InfoWorks models"
else
  puts "! #{$stats[:total_mismatches]} parameter mismatches detected"
  puts "  Most common: #{$stats[:parameter_mismatches].max_by{|k,v| v}&.first || 'None'}"
end

if $stats[:unmatched_sw] > 0 || $stats[:unmatched_iw] > 0
  puts "! #{$stats[:unmatched_sw] + $stats[:unmatched_iw]} unmatched subcatchments found"
end

puts ""
puts "Surface Types Found:"
$stats[:surface_type_counts].each do |type, count|
  puts "  #{surface_type_label(type)}: #{count}"
end

puts ""
puts "Dominant infiltration model: #{$stats[:infiltration_types].max_by{|k,v| v}&.first || 'None detected'}"
puts ""
puts "MATCHING METHODOLOGY:"
puts "  Pervious params  <--> hw_runoff_surface WHERE surface_type = 'Pervious'"
puts "  Impervious params <--> hw_runoff_surface WHERE surface_type = 'Impervious'"
puts ""
puts "Report generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
puts "=" * PAGE_WIDTH