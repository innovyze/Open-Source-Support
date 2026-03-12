################################################################################
# zone_schematic_helpers.rb
# Utility functions for the area schematic script.
# Loaded via require_relative from zone_schematic.rb
################################################################################

def sanitize_filename(name)
  name.to_s.gsub(/[\\\/:"*?<>|]+/, '_').gsub(/\s+/, '_').gsub(/_+/, '_').sub(/_$/, '')
end

def has_field?(ro, field_name)
  begin
    !ro.field(field_name).nil?
  rescue
    false
  end
end

def safe_result(ro, field)
  begin
    ro.result(field)
  rescue
    nil
  end
end

def safe_result_any(ro, fields)
  fields.each do |field|
    value = safe_result(ro, field)
    return value unless value.nil?
  end
  nil
end

def format_value(value, decimals = 2)
  return 'n/a' if value.nil?
  format("%0.#{decimals}f", value.to_f)
end

def link_open_state(link)
  flow = safe_result(link, 'flow')
  return flow.to_f.abs > 1.0e-6 unless flow.nil?

  begin
    if link.field('control_status')
      status = link['control_status']
      return status.to_i != 0
    end
  rescue
  end

  nil
end
