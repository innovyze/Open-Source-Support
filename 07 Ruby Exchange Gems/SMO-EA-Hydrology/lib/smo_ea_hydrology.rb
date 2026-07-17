# frozen_string_literal: true

require_relative "smo_ea_hydrology/version"
require_relative "smo_ea_hydrology/errors"
require_relative "smo_ea_hydrology/station"
require_relative "smo_ea_hydrology/measure"
require_relative "smo_ea_hydrology/reading"
require_relative "smo_ea_hydrology/inventory_entry"
require_relative "smo_ea_hydrology/client"

module SmoEaHydrology
  # Convenience — build a default client.
  def self.client
    Client.new
  end
end
