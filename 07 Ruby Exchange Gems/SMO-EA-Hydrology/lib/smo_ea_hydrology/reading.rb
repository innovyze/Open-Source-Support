# frozen_string_literal: true

module SmoEaHydrology
  Reading = Struct.new(
    :datetime,     # Time object
    :value,        # Float — rainfall in mm
    :quality,      # "Good" / "Estimated" / "Suspect" / "Unchecked" / "Missing"
    :completeness, # "Complete" / "Incomplete"
    keyword_init: true
  )
end
