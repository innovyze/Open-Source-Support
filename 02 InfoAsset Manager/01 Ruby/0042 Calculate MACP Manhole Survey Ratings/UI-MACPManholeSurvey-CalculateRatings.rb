# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-MACPManholeSurvey-CalculateRatings.rb
# Purpose: For each MACP manhole survey in cams_manhole_survey, calculate
#          NASSCO MACP ratings by scoring two sources:
#
#          1. Header-level component condition fields (Cover, Frame, Seal,
#             Chimney, pipe connections) per the MACP Condition Grade Matrix
#             (NASSCO PACP/MACP v7.0.3, Appendix C, pages 32–34).
#             Traffic-sensitive grades use location_code (MACP Field 25):
#               Traffic     (T)  – codes A, B, C, D, G, H, M
#               No-Traffic  (NT) – codes E, F, I, J, K, L, Y, Z
#
#          2. Detail-blob defect observations (structural_score / service_score,
#             with continuous defect S##/F## pair support).
#
#          Both sources contribute to the same grade-count tallies; the nine
#          MACP summary rating fields are then written back to the survey.
#          A full per-survey scoring breakdown is printed to the Ruby console.
#
# Run from: Network > Run Ruby Script (with a Collection Network open)
# ============================================================================

startTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)

net = WSApplication.current_network

# ---------------------------------------------------------------------------
# Helper: encode an occurrence count per NASSCO MACP quick-rating spec.
#   1–9    → '1'–'9'
#   10–14  → 'A', 15–19 → 'B', 20–24 → 'C' … (bands of 5 per letter, capped at 'Z')
# ---------------------------------------------------------------------------
def format_occurrence_count(count)
  return count.to_s if count <= 9
  letter_index = (count - 10) / 5
  letter_index = 25 if letter_index > 25
  (65 + letter_index).chr
end

# ---------------------------------------------------------------------------
# Helper: build NASSCO quick-rating string from a grade→count hash.
#   No defects           → '0000'
#   One grade only       → e.g. '4200' (grade + count + '00')
#   Two or more grades   → e.g. '5132'
# ---------------------------------------------------------------------------
def build_quick_rating(grade_counts)
  active = (5).downto(1)
              .map    { |g| [g, grade_counts[g] || 0] }
              .select { |_g, c| c > 0 }
  return '0000' if active.empty?
  result = active.first(2).map { |g, c| "#{g}#{format_occurrence_count(c)}" }.join
  result.length == 2 ? result + '00' : result
end

# ---------------------------------------------------------------------------
# Lookup tables used in header-level scoring
# ---------------------------------------------------------------------------

# MACP Field 25 – location codes that indicate vehicular traffic (T).
# All other recorded codes are treated as No-Traffic (NT).
traffic_location_codes = %w[A B C D G H M].freeze

# Infiltration/Inflow code → O&M grade (Structural grade is blank for both
# Field 71 Frame Seal Inflow and Field 76 Chimney I/I per MACP grade matrix)
ini_flow_grade = {
  'NONE' => 1, 'N' => 1, 'IS' => 2, 'IW' => 3, 'ID' => 4, 'IR' => 5, 'IG' => 5
}.freeze

# Pipe connection condition code → O&M grade (Structural grade is blank
# for Field 115 per MACP grade matrix)
pipe_condition_grade = {
  'S' => 1, 'SOUND' => 1, 'D' => 3, 'DEFECTIVE' => 3
}.freeze

# ---------------------------------------------------------------------------
# Detail-defect grade lookup tables
# Reference: NASSCO MACP Condition Grade Matrix, Appendix C
#
# Each code belongs to either the Structural family or the O&M family.
# Grade arrays are indexed: [0]=Chimney [1]=Cone and Wall [2]=Bench [3]=Channel
# nil = the defect code is not applicable at that location.
# ---------------------------------------------------------------------------

# Normalise descriptive_location field value → location index 0-3, or nil.
# Codes: B=Bench, C=Channel, CME/CMI=Chimney, COE/COI=Cone, WE/WI=Wall
# Cone and Wall share index 1 in the grade arrays.
detail_loc_idx = lambda do |loc_str|
  case loc_str.to_s.strip.upcase
  when 'CME', 'CMI'        then 0   # Chimney
  when 'COE', 'COI', 'WE', 'WI' then 1   # Cone / Wall
  when 'B'                 then 2   # Bench
  when 'C'                 then 3   # Channel
  else nil
  end
end

# Structural family detail grades: code → [chimney, cone/wall, bench, channel]
STRUCT_DETAIL_GRADES = {
  # Crack (C)
  'CC' => [2,2,2,2], 'CL' => [2,2,2,2], 'CM' => [3,3,3,3], 'CS' => [2,2,2,2],
  # Fracture (F)
  'FC' => [3,3,3,3], 'FL' => [3,3,3,3], 'FM' => [4,4,4,4], 'FS' => [3,3,3,3],
  # Broken (B)
  'B'   => [5,5,5,5], 'BSV' => [5,5,5,5], 'BVV' => [5,5,5,5],
  # Hole (H) – channel grade depends on clock_at: 1 position→4, other/nil→5 (resolved at runtime)
  'H'   => [2,2,2,5], 'HSV' => [5,5,5,5], 'HVV' => [5,5,5,5],
  # Collapse (X)
  'X'   => [5,5,5,5],
  # Joint (J)
  'JOM' => [5,5,5,5], 'JOL' => [5,5,5,5], 'JSM' => [5,5,5,5],
  'JSL' => [5,5,5,5], 'JAM' => [5,5,5,5], 'JAL' => [5,5,5,5],
  # Surface Damage
  'SRI' => [1,1,1,1], 'SSS' => [2,2,2,2], 'SSC' => [2,2,2,2],
  'SAV' => [2,2,2,2], 'SAP' => [3,3,3,3],
  # Surface Damage (Silent)
  'SAM' => [4,4,4,4], 'SRV' => [5,5,5,5], 'SRP' => [5,5,5,5],
  'SRC' => [5,5,5,5], 'SMW' => [5,5,5,5], 'SZ'  => [nil,nil,nil,nil],
  # Surface Damage (Metal)
  'SCP' => [3,3,3,3],
  # Lining Features (LF)
  'LFD'  => [4,4,3,3], 'LFDE' => [3,3,3,3], 'LFB'  => [3,3,3,3],
  'LFCS' => [3,3,3,3], 'LFAC' => [nil,nil,nil,nil],
  'LFOC' => [2,2,2,2], 'LFUC' => [2,2,2,2], 'LFBK' => [3,3,3,3],
  'LFAS' => [3,3,3,3], 'LFBU' => [3,3,3,3], 'LFDC' => [3,2,3,3],
  'LFDL' => [4,4,4,4], 'LFPH' => [4,4,4,4], 'LFRS' => [3,3,3,3],
  'LFW'  => [2,2,2,2], 'LFZ'  => [nil,nil,nil,nil],
  # Weld Failure (WF)
  'WFC' => [2,2,2,2], 'WFL' => [2,2,2,2],
  'WFM' => [3,3,3,3], 'WFS' => [2,2,2,2],
  # Point Repair (RP)
  'RPLD' => [4,4,4,4], 'RPPD' => [4,4,4,4],
  'RPRD' => [4,4,nil,nil], 'RPZD' => [nil,nil,nil,nil],
  # Brickwork (Silent)
  'DB'  => [3,3,3,3], 'MB'  => [4,4,4,4],
  'MMS' => [2,2,2,2], 'MMM' => [3,3,3,3], 'MML' => [4,4,4,4],
}.freeze

# O&M family detail grades – fixed (non-percentage) codes
# code → [chimney, cone/wall, bench, channel]
OM_DETAIL_GRADES_FIXED = {
  # Roots – Fine (RF): location suffix B=Both B/C, L=Lateral, C=Connection, J=Joint
  'RFB' => [1,1,1,2], 'RFL' => [1,1,1,1], 'RFC' => [1,1,1,1], 'RFJ' => [1,1,1,1],
  # Roots – Tap (RT)
  'RTB' => [1,1,1,3], 'RTL' => [1,1,1,2], 'RTC' => [1,1,1,2], 'RTJ' => [1,1,1,2],
  # Roots – Medium (RM)
  'RMB' => [1,1,1,4], 'RML' => [1,1,1,3], 'RMC' => [1,1,1,3], 'RMJ' => [1,1,1,3],
  # Roots – Blocking (RB) – grade 2 on chimney/cone/bench, higher on channel
  'RBB' => [2,2,2,5], 'RBL' => [2,2,2,4], 'RBC' => [2,2,2,4], 'RBJ' => [2,2,2,4],
  # Infiltration (I) – detail-level observation codes
  'IS' => [1,1,1,1], 'IW' => [2,2,2,2],
  'ID' => [3,3,3,3],  # Dripping: chimney=2, all other locations=3
  'IR' => [4,4,4,4], 'IG' => [5,5,5,5],
  # Vermin (V)
  'VR' => [2,2,2,2], 'VC' => [1,1,1,1], 'VZ' => [1,1,1,1],
  # Construction Features / Intruding Sealing Material (IS)
  'ISSR'  => [1,1,1,1], 'ISSRH' => [1,1,1,1], 'ISSRB' => [1,1,1,1],
  'ISSRL' => [1,1,1,1], 'ISGT'  => [1,1,1,1], 'ISZ'   => [1,1,1,1],
}.freeze

# Grade-function factories for percentage-based O&M codes.
# Each factory returns a lambda that accepts a percentage value (or nil)
# and returns the appropriate grade integer (or nil for N/A locations).
#   _F[g]  flat grade g regardless of percentage
#   _T2[]  2-tier: pct < 30% → 1, pct ≥ 30% → 2
#   _CD[]  deposit 4-tier channel: ≤10%→1, >10–≤20%→2, >20–≤30%→3, >30%→4
#   _CO[]  obstacle 4-tier channel: ≤10%→2, >10–≤20%→3, >20–≤30%→4, >30%→5
#   _NA[]  not applicable at this location (always nil)
_F  = ->(g) { ->(p) { g } }
_T2 = ->    { ->(p) { !p || p.to_f <  30 ? 1 : 2 } }
_CD = ->    { ->(p) { p.nil? ? 1 : (pf = p.to_f) <= 10 ? 1 : pf <= 20 ? 2 : pf <= 30 ? 3 : 4 } }
_CO = ->    { ->(p) { p.nil? ? 2 : (pf = p.to_f) <= 10 ? 2 : pf <= 20 ? 3 : pf <= 30 ? 4 : 5 } }
_NA = ->    { ->(_p) { nil } }

# O&M percentage-based grade table.
# code → [fn_chimney, fn_cone_wall, fn_bench, fn_channel]
# Each fn receives the percentage value and returns a grade Integer or nil.
OM_PCT_GRADE_TABLE = {
  # ── Deposits – Attached ────────────────────────────────────────────────────
  # DAE has the same tier structure as DAGS/DAR
  'DAE'  => [_T2[], _T2[], _T2[], _CD[]],
  'DAGS' => [_F[1], _F[1], _T2[], _CD[]],
  'DAR'  => [_F[1], _F[1], _T2[], _CD[]],
  'DAZ'  => [_T2[], _T2[], _T2[], _CD[]],
  # ── Deposits – Settled ─────────────────────────────────────────────────────
  'DSC'  => [_NA[], _NA[], _T2[], _CD[]],  # n/a chimney/cone
  'DSF'  => [_NA[], _NA[], _T2[], _CD[]],
  'DSGV' => [_NA[], _NA[], _T2[], _CD[]],
  'DSZ'  => [_NA[], _NA[], _T2[], _CD[]],
  # ── Deposits – Non-cohesive ────────────────────────────────────────────────
  'DNF'  => [_NA[], _NA[], _T2[], _CD[]],  # n/a chimney/cone
  'DNGV' => [_NA[], _NA[], _T2[], _CD[]],
  'DNZ'  => [_NA[], _NA[], _T2[], _CD[]],
  # ── Obstacles / Obstructions ───────────────────────────────────────────────
  # OBB single-tier: flat 1 on chimney/cone/bench, flat 2 on channel
  'OBB'  => [_F[1], _F[1], _F[1], _F[2]],
  'OBM'  => [_T2[], _T2[], _T2[], _CO[]],
  'OBI'  => [_T2[], _T2[], _T2[], _CO[]],
  'OBJ'  => [_T2[], _T2[], _T2[], _CO[]],
  'OBC'  => [_T2[], _T2[], _T2[], _CO[]],
  'OBP'  => [_T2[], _T2[], _T2[], _CO[]],
  'OBS'  => [_T2[], _T2[], _T2[], _CO[]],
  'OBN'  => [_T2[], _T2[], _T2[], _CO[]],
  'OBR'  => [_T2[], _T2[], _T2[], _CO[]],
  'OBZ'  => [_T2[], _T2[], _T2[], _CO[]],
}.freeze

# O&M percentage-based grade lookup.
om_pct_grade = lambda do |code, loc_idx, pct|
  row = OM_PCT_GRADE_TABLE[code]
  return nil unless row && !loc_idx.nil?
  fn = row[loc_idx]
  fn ? fn.call(pct) : nil
end

# Set of all percentage-based O&M codes – used by J-suffix normalisation.
OM_PCT_CODES = %w[
  DAE DAGS DAR DAZ DSC DSF DSGV DSZ DNF DNGV DNZ
  OBB OBM OBI OBJ OBC OBP OBS OBN OBR OBZ
].freeze

# ---------------------------------------------------------------------------
# Discover available fields on cams_manhole_survey and its details blob
# ---------------------------------------------------------------------------
survey_fields = {}
detail_fields = {}

net.table('cams_manhole_survey').fields.each do |f|
  if f.name == 'details'
    f.fields.each { |bf| detail_fields[bf.name] = true }
  else
    survey_fields[f.name] = true
  end
end

missing_detail_fields = []
missing_detail_fields << 'structural_score' unless detail_fields.key?('structural_score')
missing_detail_fields << 'service_score'    unless detail_fields.key?('service_score')

unless missing_detail_fields.empty?
  WSApplication.message_box(
    "Required field(s) not found in cams_manhole_survey details blob:\n" \
    "  #{missing_detail_fields.join(', ')}\n\nScript cancelled.",
    'OK', '!', false
  )
  exit
end

can_process_continuous = detail_fields.key?('cd') && detail_fields.key?('distance')
can_lookup_location    = detail_fields.key?('descriptive_location')
can_lookup_percentage  = detail_fields.key?('percentage')
can_write_equiv_count  = detail_fields.key?('characterisation3')

#puts "Detail-defect grade source: code-based lookup (descriptive_location: #{can_lookup_location ? 'found' : 'NOT found – location unknown for lookup'}, percentage: #{can_lookup_percentage ? 'found' : 'NOT found – pct-based codes fall back to stored score'})"
#puts ''

macp_output_fields = %w[
  macp_struct_rating
  macp_oandm_rating
  macp_overall_rating
  macp_struct_quick_rating
  macp_oandm_quick_rating
  macp_overall_quick_rating
  macp_struct_index_rating
  macp_oandm_index_rating
  macp_overall_index_rating
].freeze

available_output   = macp_output_fields.select { |f| survey_fields.key?(f) }
unavailable_output = macp_output_fields - available_output

#puts 'Output fields available on cams_manhole_survey:'
#available_output.each   { |f| puts "  found    : #{f}" }
#unavailable_output.each { |f| puts "  NOT found: #{f} (skipped)" }
#puts ''

# ---------------------------------------------------------------------------
# Prompt: scope and distance units
# ---------------------------------------------------------------------------
val = WSApplication.prompt(
  'MACP Manhole Survey – Calculate Ratings',
  [
    ['Process SELECTION only?',                         'Boolean', true],
    ['Distance units are Imperial (feet)?',             'Boolean', true],
    ['Index rating decimal places:',                    'Number',  1, nil, 'RANGE', 1, 3],
    ['Write equiv. point count to characterisation3?',  'Boolean', false],
    ['Full calculation output?',                        'Boolean', false]
  ],
  false
)

if val.nil?
  WSApplication.message_box("Dialog closed\nScript cancelled", 'OK', '!', false)
  exit
end

selection_only  = val[0]
imperial_units  = val[1]
index_dp        = val[2].to_i
write_equiv     = val[3] && can_write_equiv_count
verbose_output  = val[4]
cont_divisor   = imperial_units ? 1.0 : 0.3
units_label    = imperial_units ? 'ft' : 'm'
puts "Continuous defect divisor: #{cont_divisor} #{units_label} / equivalent point defect"
puts "Index rating decimal places: #{index_dp}"
puts ''

survey_objects = selection_only \
  ? net.row_objects_selection('cams_manhole_survey') \
  : net.row_objects('cams_manhole_survey')

if survey_objects.length == 0
  msg = selection_only \
    ? "No manhole surveys are selected.\nPlease select one or more surveys and re-run." \
    : 'No manhole surveys found in the network.'
  WSApplication.message_box(msg, 'OK', 'Information', false)
  exit
end

scope_label = selection_only ? 'selected' : 'all'
puts "Processing #{survey_objects.length} #{scope_label} manhole survey(s)..."
puts ''

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
count_processed  = 0
count_no_scores  = 0
dup_cd_surveys   = []   # { id:, survey_index:, count: } for end-of-run summary

net.transaction_begin

survey_objects.each do |survey|
  survey_idx = survey.survey_index.to_s.strip
  puts "=" * 70
  puts "Survey: #{survey.id}#{survey_idx.empty? ? '' : "  |  Survey Index: #{survey_idx}"}"
  puts "=" * 70

  struct_counts = { 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0 }
  om_counts     = { 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0 }

  # Determine Traffic (T) vs No-Traffic (NT) from location_code (MACP Field 25)
  loc_code   = survey.location_code.to_s.strip.upcase
  is_traffic = traffic_location_codes.include?(loc_code)
  loc_label  = is_traffic ? "Traffic (T)" : "No-Traffic (NT)"
  if verbose_output
    puts "  Location code: #{loc_code.empty? ? '(blank)' : loc_code}  ->  #{loc_label}"
    puts ''
  end

  # comp_log collects one entry per header-level observation scored.
  # Each entry: { label: String, st: Integer|nil, om: Integer|nil }
  comp_log = []

  # Add one grade occurrence and append to comp_log.  nil skips a category.
  add_grade = lambda do |st_g, om_g, label = '(unlabelled)'|
    st_valid = !st_g.nil? && st_g >= 1 && st_g <= 5
    om_valid = !om_g.nil? && om_g >= 1 && om_g <= 5
    struct_counts[st_g] += 1 if st_valid
    om_counts[om_g]     += 1 if om_valid
    comp_log << { label: label, st: st_valid ? st_g : nil, om: om_valid ? om_g : nil }
  end

  # Traffic-conditional grade value.
  tg = ->(nt_grade, t_grade) { is_traffic ? t_grade : nt_grade }
  # Traffic-conditional label suffix showing the grade actually applied.
  tl = ->(nt_grade, t_grade) { is_traffic ? "T→#{t_grade}" : "NT→#{nt_grade}" }

  # =========================================================================
  # Source 1: Header-level component condition fields
  # Reference: NASSCO MACP Condition Grade Matrix, Appendix C pp. 32–34
  # =========================================================================

  # ---- Field 52: Hole Number + Field 27: Potential for Runoff (O&M only) --
  hn = survey.hole_number
  if !hn.nil? && hn.is_a?(Numeric) && hn > 0
    runoff_val = survey.potential_for_runoff.to_s.strip.upcase
    om_g = { 'S' => 3, 'P' => 4, 'I' => 5 }[runoff_val]
    add_grade.call(nil, om_g, "F52/27 hole_number=#{hn}  potential_for_runoff=#{runoff_val}") if om_g
  end

  # ---- Field 55: Cover/Frame Fit ------------------------------------------
  fit_val = survey.cover_frame_fit.to_s.strip.upcase
  case fit_val
  when 'R', 'U'
    g = tg.call(4, 5)
    add_grade.call(g, g, "F55 cover_frame_fit=#{fit_val} [#{tl.call(4,5)}]")
  when 'O'
    add_grade.call(5, 5, "F55 cover_frame_fit=O (Open)")
  when 'G'
    add_grade.call(nil, 1, "F55 cover_frame_fit=G (Good)")
  end

  # ---- Field 56: Cover Condition ------------------------------------------
  add_grade.call(1,             nil, 'F56 cover_condition_sound')             if survey.cover_condition_sound             == true
  add_grade.call(tg.call(3, 4), nil, "F56 cover_condition_cracked [#{tl.call(3,4)}]")  if survey.cover_condition_cracked           == true
  add_grade.call(4,             nil, 'F56 cover_condition_corroded')           if survey.cover_condition_corroded           == true
  add_grade.call(5,             nil, 'F56 cover_condition_broken')             if survey.cover_condition_broken             == true
  add_grade.call(5,             nil, 'F56 cover_condition_missing')            if survey.cover_condition_missing            == true
  add_grade.call(nil,           2,   'F56 cover_condition_boltsmissing')       if survey.cover_condition_boltsmissing       == true
  add_grade.call(2,             2,   'F56 cover_condition_restraint_defect')   if survey.cover_condition_restraint_defect   == true
  add_grade.call(nil,           3,   'F56 cover_condition_restraint_miss')     if survey.cover_condition_restraint_miss     == true

  # ---- Field 58: Cover Insert Condition (Corroded=ST only; rest=O&M only) ---
  add_grade.call(nil, 1, 'F58 insert_condition_sound')         if survey.insert_condition_sound         == true
  add_grade.call(nil, 3, 'F58 insert_condition_poorlyfitting') if survey.insert_condition_poorlyfitting == true
  add_grade.call(nil, 3, 'F58 insert_condition_cracked')       if survey.insert_condition_cracked       == true
  add_grade.call(3, nil, 'F58 insert_condition_corroded')      if survey.insert_condition_corroded      == true
  add_grade.call(nil, 5, 'F58 insert_condition_insertfell')    if survey.insert_condition_insertfell    == true
  add_grade.call(nil, 5, 'F58 insert_condition_leaking')       if survey.insert_condition_leaking       == true

  # ---- Field 61: Adjustment Ring Condition (Structural; Leaking=O&M only) --
  add_grade.call(1,   nil, 'F61 ring_condition_sound')       if survey.ring_condition_sound       == true
  add_grade.call(3,   nil, 'F61 ring_condition_corroded')    if survey.ring_condition_corroded    == true
  add_grade.call(3,   nil, 'F61 ring_condition_cracked')     if survey.ring_condition_cracked     == true
  add_grade.call(3,   nil, 'F61 ring_condition_poorinstall') if survey.ring_condition_poorinstall == true
  add_grade.call(5,   nil, 'F61 ring_condition_broken')      if survey.ring_condition_broken      == true
  add_grade.call(nil, 5,   'F61 ring_condition_leaking')     if survey.ring_condition_leaking     == true

  # ---- Field 68: Frame Condition (Structural only) ------------------------
  add_grade.call(1,             nil, 'F68 frame_condition_sound')              if survey.frame_condition_sound    == true
  add_grade.call(1,             nil, 'F68 frame_condition_corroded')           if survey.frame_condition_corroded == true
  add_grade.call(tg.call(4, 5), nil, "F68 frame_condition_cracked [#{tl.call(4,5)}]") if survey.frame_condition_cracked  == true
  add_grade.call(5,             nil, 'F68 frame_condition_broken')             if survey.frame_condition_broken    == true
  add_grade.call(5,             nil, 'F68 frame_condition_missing')            if survey.frame_condition_missing   == true

  # ---- Field 69: Seal Condition (both Structural and O&M) -----------------
  add_grade.call(1,             1, 'F69 seal_condition_sound')                           if survey.seal_condition_sound   == true
  add_grade.call(tg.call(3, 4), 3, "F69 seal_condition_cracked [ST:#{tl.call(3,4)} OM:3]") if survey.seal_condition_cracked == true
  add_grade.call(tg.call(3, 4), 3, "F69 seal_condition_loose   [ST:#{tl.call(3,4)} OM:3]") if survey.seal_condition_loose   == true
  add_grade.call(3,             3, 'F69 seal_condition_offset')                           if survey.seal_condition_offset  == true
  add_grade.call(3,             3, 'F69 seal_condition_missing')                          if survey.seal_condition_missing == true

  # ---- Field 70: Frame Offset Distance (Structural only) ------------------
  fod = survey.frame_offset_distance
  if !fod.nil? && fod.is_a?(Numeric) && fod >= 0
    fod_grade = imperial_units \
      ? (fod <= 1.0 ? 1 : fod <= 4.0 ? 3 : 5) \
      : (fod <= 25.0 ? 1 : fod <= 102.0 ? 3 : 5)
    add_grade.call(fod_grade, nil, "F70 frame_offset_distance=#{fod} #{units_label} -> grade #{fod_grade}")
  end

  # ---- Field 71: Frame Seal Inflow (O&M only; Structural grade is blank) --
  fsi_val   = survey.frame_seal_inflow.to_s.strip.upcase
  fsi_grade = ini_flow_grade[fsi_val]
  add_grade.call(nil, fsi_grade, "F71 frame_seal_inflow=#{fsi_val}") if fsi_grade

  # ---- Field 76: Chimney Inflow and Infiltration (O&M only) ---------------
  chi_val   = survey.chimney_ini.to_s.strip.upcase
  chi_grade = ini_flow_grade[chi_val]
  add_grade.call(nil, chi_grade, "F76 chimney_ini=#{chi_val}") if chi_grade

  # ---- Field 115: Pipe Connections – incoming and outgoing (O&M only) -----
  [['pipes_in', survey.pipes_in], ['pipes_out', survey.pipes_out]].each do |blob_name, blob|
    (0...blob.size).each do |i|
      cc   = blob[i]['condition_code'].to_s.strip.upcase
      pc_g = pipe_condition_grade[cc]
      add_grade.call(nil, pc_g, "F115 #{blob_name}[#{i}] condition_code=#{cc}") if pc_g
    end
  end

  # =========================================================================
  # Source 2: Detail-blob defect observations
  # =========================================================================
  details = survey.details

  # Pass 1: identify continuous defect S##/F## pairs and calculate equivalent
  # point-defect counts. Finish markers are flagged to skip in pass 2.
  # Duplicate start or finish codes are warned about and ignored.
  detail_multiplier = {}
  finish_indices    = {}
  ignored_indices   = {}

  if can_process_continuous && details.size > 0
    # Pre-scan: group all S and F row indices by pairing id.
    start_rows_by_id  = {}
    finish_rows_by_id = {}

    (0...details.size).each do |i|
      cd_val = details[i]['cd']
      next if cd_val.nil? || cd_val.to_s.strip.empty?
      cd_str = cd_val.to_s.strip.upcase
      if cd_str.start_with?('S') && cd_str.length > 1
        pid = cd_str[1..-1].strip
        (start_rows_by_id[pid] ||= []) << i unless pid.empty?
      elsif cd_str.start_with?('F') && cd_str.length > 1
        pid = cd_str[1..-1].strip
        (finish_rows_by_id[pid] ||= []) << i unless pid.empty?
      end
    end

    cd_warnings = []

    start_rows_by_id.each do |pid, start_idxs|
      # Use the FIRST start for this id; all subsequent ones are duplicates.
      i          = start_idxs[0]
      start_dist = details[i]['distance']
      start_dist = Float(start_dist) rescue nil unless start_dist.is_a?(Numeric)

      # Finish rows after the used (first) start; use the LAST of these.
      matching_fins = start_dist ? (finish_rows_by_id[pid] || []).select { |jj| jj > i } : []
      j             = matching_fins[-1]
      fin_dist      = j ? details[j]['distance'] : nil
      fin_dist      = Float(fin_dist) rescue nil unless fin_dist.is_a?(Numeric) || fin_dist.nil?

      # Helper to format a row's details as a readable string.
      row_str = lambda do |idx|
        d  = '%.2f' % details[idx]['distance'].to_f
        c  = details[idx]['code'].to_s.strip
        cd = details[idx]['cd'].to_s.strip
        "row #{idx + 1}  dist #{d}  cd #{cd}  code #{c}"
      end

      used_start_str  = "    Used start:  #{row_str.call(i)}"
      used_finish_str = j ? "    Used finish: #{row_str.call(j)}" : "    Used finish: (no matching finish found)"

      # Warn about all subsequent duplicate starts.
      start_idxs[1..-1].each do |dup_i|
        ignored_indices[dup_i] = true
        cd_warnings << "  WARNING: Duplicate start S#{pid} - #{row_str.call(dup_i)} - row ignored"
        cd_warnings << used_start_str
        cd_warnings << used_finish_str
      end

      # Warn about all earlier duplicate finishes (all but the last matching fin).
      matching_fins[0..-2].each do |dup_j|
        ignored_indices[dup_j] = true
        cd_warnings << "  WARNING: Duplicate finish F#{pid} - #{row_str.call(dup_j)} - row ignored"
        cd_warnings << used_start_str
        cd_warnings << used_finish_str
      end

      next if start_dist.nil? || matching_fins.empty? || fin_dist.nil?

      length = (fin_dist - start_dist).abs.round(4)
      equiv  = (length / cont_divisor).round
      equiv  = 1 if equiv < 1

      detail_multiplier[i] = equiv
      details[i].characterisation3 = "x#{equiv}" if write_equiv
      finish_indices[j] = true
    end

    # Always output duplicate warnings regardless of verbose_output setting.
    unless cd_warnings.empty?
      dup_count = cd_warnings.size / 3
      dup_cd_surveys << { id: survey.id, survey_index: survey_idx, count: dup_count }
      puts "  [Continuous Defect Duplicate Warnings - #{dup_count}]"
      cd_warnings.each { |w| puts w }
      puts ''
    end
  end

  # Pass 2: tally grades from details blob and build det_log for reporting.
  det_log = []

  (0...details.size).each do |i|
    dist_v = details[i]['distance']
    cd_v   = details[i]['cd'].to_s.strip
    code_v = details[i]['code'].to_s.strip.upcase

    if finish_indices[i]
      details[i].structural_score = nil
      details[i].service_score    = nil
      det_log << {
        idx: i + 1, dist: dist_v, cd: cd_v, code: code_v,
        mul: 0, st: nil, om: nil, note: 'cd-finish, cleared'
      }
      next
    end

    if ignored_indices[i]
      details[i].structural_score = nil
      details[i].service_score    = nil
      det_log << {
        idx: i + 1, dist: dist_v, cd: cd_v, code: code_v,
        mul: 0, st: nil, om: nil, note: 'CD-DUPLICATE, NOT SCORED'
      }
      next
    end

    mul     = detail_multiplier[i] || 1
    loc_str = can_lookup_location   ? details[i]['descriptive_location'].to_s.strip : ''
    pct_raw = can_lookup_percentage ? details[i]['percentage'] : nil
    pct_val = pct_raw.is_a?(Numeric) ? pct_raw.to_f : nil
    loc_idx = detail_loc_idx.call(loc_str)

    # If the code isn't found as-is, strip trailing characters one at a time
    # until a base code is matched.  This handles location/size suffix variants
    # such as ISB/ISC/ISL → IS, IWB/IWC/IWJ/IWL → IW, IDJ → ID, etc.
    # Codes with their own direct table entries (ISSR, ISGT, ISZ …) are found
    # on the first check and are never stripped.
    in_any = lambda { |c| STRUCT_DETAIL_GRADES.key?(c) || OM_DETAIL_GRADES_FIXED.key?(c) || OM_PCT_CODES.include?(c) }
    effective_code = code_v
    unless in_any.call(code_v)
      (code_v.length - 1).downto(1) do |len|
        candidate = code_v[0, len]
        if in_any.call(candidate)
          effective_code = candidate
          break
        end
      end
    end
    suffix_stripped = effective_code != code_v

    st_g = nil
    om_g = nil
    grade_src = nil

    if STRUCT_DETAIL_GRADES.key?(effective_code)
      arr   = STRUCT_DETAIL_GRADES[effective_code]
      st_g  = loc_idx ? arr[loc_idx] : arr.compact.first
      # H (Hole) at Channel: 1 clock position → grade 4, 2+ positions → grade 5.
      # 1 position = clock_at only, or clock_at == clock_to.
      # 2+ positions = clock_at and clock_to are both present and differ.
      if effective_code == 'H' && loc_idx == 3
        cat = details[i]['clock_at']
        cto = details[i]['clock_to']
        multi_pos = !cat.nil? && !cto.nil? && cat.to_s.strip != cto.to_s.strip
        st_g = multi_pos ? 5 : 4
      end
      grade_src = loc_idx ? 'lookup' : 'lookup(loc?)'

    elsif OM_DETAIL_GRADES_FIXED.key?(effective_code)
      arr   = OM_DETAIL_GRADES_FIXED[effective_code]
      om_g  = loc_idx ? arr[loc_idx] : arr.compact.first
      grade_src = loc_idx ? 'lookup' : 'lookup(loc?)'

    else
      pct_g = om_pct_grade.call(effective_code, loc_idx, pct_val)
      if pct_g
        om_g      = pct_g
        grade_src = 'lookup(pct)'
      else
        grade_src = 'not found'
      end
    end

    struct_counts[st_g] += mul if st_g
    om_counts[om_g]     += mul if om_g

    # Write the calculated grades back into the details blob so the stored
    # structural_score / service_score fields reflect the correct values.
    # For continuous-defect start records (mul > 1) the single-observation
    # grade is written, not the multiplied count – the count is for tallying only.
    details[i].structural_score = st_g
    details[i].service_score    = om_g

    note_parts = []
    note_parts << "x#{mul}" if mul > 1
    note_parts << (suffix_stripped ? "lookup(sfx->#{effective_code})" : grade_src)
    note_parts << "loc:#{loc_str.empty? ? '?' : loc_str}" if can_lookup_location
    note = note_parts.join(' ')
    det_log << { idx: i + 1, dist: dist_v, cd: cd_v, code: code_v, mul: mul, st: st_g, om: om_g, note: note }
  end
  details.write

  # Skip surveys with no scored observations from either source
  total_observations = struct_counts.values.sum + om_counts.values.sum
  if total_observations == 0
    puts '  No scored observations from component conditions or details – skipping.'
    puts ''
    count_no_scores += 1
    next
  end

  # =========================================================================
  # Calculate ratings
  # =========================================================================
  total_st  = struct_counts.values.sum
  total_om  = om_counts.values.sum
  total_all = total_st + total_om

  st_rating      = struct_counts.sum { |g, c| g * c }
  om_rating      = om_counts.sum    { |g, c| g * c }
  overall_rating = st_rating + om_rating

  st_index      = total_st  > 0 ? (st_rating.to_f      / total_st).round(index_dp)  : nil
  om_index      = total_om  > 0 ? (om_rating.to_f      / total_om).round(index_dp)  : nil
  overall_index = total_all > 0 ? (overall_rating.to_f / total_all).round(index_dp) : nil

  st_quick    = build_quick_rating(struct_counts)
  om_quick    = build_quick_rating(om_counts)
  combined    = { 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0 }
  (1..5).each { |g| combined[g] = struct_counts[g] + om_counts[g] }
  overall_quick = build_quick_rating(combined)

  # =========================================================================
  # Print detailed scoring breakdown
  # =========================================================================

  # --- Component Conditions ------------------------------------------------
  if verbose_output
    puts "  [Component Conditions - #{comp_log.size} observation(s)]"
    if comp_log.empty?
      puts "    (none scored)"
    else
      lw = 54
      puts "  #{'Observation'.ljust(lw)}  ST   OM"
      puts "  #{'-' * lw}  --   --"
      comp_log.each do |e|
        st_s = e[:st] ? e[:st].to_s.rjust(2) : '--'
        om_s = e[:om] ? e[:om].to_s.rjust(2) : '--'
        puts "  #{e[:label].ljust(lw)}  #{st_s}   #{om_s}"
      end
    end
    puts ''
  end

  # --- Detail Observations -------------------------------------------------
  if verbose_output
    puts "  [Detail Observations - #{details.size} record(s)]"
    if details.size == 0
      puts "    (none)"
    else
      puts "  #{'Row'.rjust(4)}  #{'Dist'.rjust(8)}  #{'CD'.ljust(5)}  #{'Code'.ljust(8)}  Mul  ST   OM  Note"
      puts "  #{'-' * 4}  #{'-' * 8}  #{'-' * 5}  #{'-' * 8}  ---  --   --  ------------------"
      det_log.each do |d|
        dist_s = if d[:dist].nil?
                   '       -'
                 elsif d[:dist].is_a?(Numeric)
                   d[:dist].round(3).to_s.rjust(8)
                 else
                   d[:dist].to_s.rjust(8)
                 end
        cd_s   = d[:cd].ljust(5)
        code_s = d[:code].ljust(8)
        mul_s  = d[:note] == 'cd-finish, cleared' ? '  -' : d[:mul].to_s.rjust(3)
        st_s   = d[:st] ? d[:st].to_s.rjust(2) : '--'
        om_s   = d[:om] ? d[:om].to_s.rjust(2) : '--'
        note_s = d[:note].empty? ? '' : "  [#{d[:note]}]"
        puts "  #{d[:idx].to_s.rjust(4)}  #{dist_s}  #{cd_s}  #{code_s}  #{mul_s}  #{st_s}   #{om_s}#{note_s}"
      end
    end
    puts ''
  end

  # --- Grade Tally Table ---------------------------------------------------
  if verbose_output
    puts "  [Grade Tally]"
    puts "  #{'Grade'.rjust(5)}  #{'ST cnt'.rjust(6)}  #{'ST score'.rjust(8)}  #{'OM cnt'.rjust(6)}  #{'OM score'.rjust(8)}"
    puts "  #{'-' * 5}  #{'-' * 6}  #{'-' * 8}  #{'-' * 6}  #{'-' * 8}"
    (1..5).each do |g|
      sc = struct_counts[g]
      oc = om_counts[g]
      puts "  #{g.to_s.rjust(5)}  #{sc.to_s.rjust(6)}  #{(sc * g).to_s.rjust(8)}  #{oc.to_s.rjust(6)}  #{(oc * g).to_s.rjust(8)}"
    end
    puts "  #{'Total'.rjust(5)}  #{total_st.to_s.rjust(6)}  #{st_rating.to_s.rjust(8)}  #{total_om.to_s.rjust(6)}  #{om_rating.to_s.rjust(8)}"
    puts ''
  end

  # --- Summary Results -----------------------------------------------------
  puts "  [Results]"
  puts "  ST Rating: #{st_rating}  |  OM Rating: #{om_rating}  |  Overall Rating: #{overall_rating}"
  puts "  ST Quick:  #{st_quick}    |  OM Quick:  #{om_quick}    |  Overall Quick:  #{overall_quick}"
  puts "  ST Index:  #{st_index ? "%.#{index_dp}f" % st_index : 'n/a'}  |  OM Index:  #{om_index ? "%.#{index_dp}f" % om_index : 'n/a'}  |  Overall Index:  #{overall_index ? "%.#{index_dp}f" % overall_index : 'n/a'}"
  puts ''

  # =========================================================================
  # Write results
  # =========================================================================
  results = {
    'macp_struct_rating'        => st_rating,
    'macp_oandm_rating'         => om_rating,
    'macp_overall_rating'       => overall_rating,
    'macp_struct_quick_rating'  => st_quick,
    'macp_oandm_quick_rating'   => om_quick,
    'macp_overall_quick_rating' => overall_quick,
    'macp_struct_index_rating'  => st_index,
    'macp_oandm_index_rating'   => om_index,
    'macp_overall_index_rating' => overall_index
  }

  results.each do |field, value|
    next unless available_output.include?(field)
    survey[field] = value
  end

  survey.write
  count_processed += 1
end

net.transaction_commit

endTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = endTime - startTime

puts "=" * 70
puts 'Done.'
puts "  Surveys processed (ratings written)     : #{count_processed}"
puts "  Surveys skipped (no scored observations): #{count_no_scores}"


unless dup_cd_surveys.empty?
  puts ''
  puts "  WARNING: Surveys with duplicate continuous defect codes: #{dup_cd_surveys.size}"
  dup_cd_surveys.each do |s|
    idx_str = s[:survey_index].to_s.strip.empty? ? '' : "  Survey Index: #{s[:survey_index]}"
    puts "    #{s[:id]}#{idx_str}  (#{s[:count]} duplicate#{ s[:count] == 1 ? '' : 's'})"
  end
  WSApplication.message_box(
    "#{dup_cd_surveys.size} survey#{ dup_cd_surveys.size == 1 ? ' has' : 's have'} duplicate continuous defect codes.\n\nThese rows have been excluded from scoring.\nPlease review the script output for full details.",
    'OK', '!', false
  )
end
puts ''
puts "  Elapsed time: #{Time.at(elapsed).utc.strftime('%H:%M:%S')}"
