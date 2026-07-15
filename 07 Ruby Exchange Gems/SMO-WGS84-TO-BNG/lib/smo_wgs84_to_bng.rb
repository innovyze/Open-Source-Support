require "json"
require_relative "smo_wgs84_to_bng/version"
require_relative "smo_wgs84_to_bng/errors"
require_relative "smo_wgs84_to_bng/constants"
require_relative "smo_wgs84_to_bng/validator"
require_relative "smo_wgs84_to_bng/wgs84_to_bng"
require_relative "smo_wgs84_to_bng/bng_to_wgs84"

module SmoWgs84ToBng
  # -- Forward: WGS84 -> BNG --------------------------------------------------

  def self.convert_to_hash(id:, lat:, lon:, **extra)
    Validator.validate_wgs84!(id: id, lat: lat, lon: lon)
    e, n = Wgs84ToBng.convert(lat.to_f, lon.to_f)
    { id: id, easting: e, northing: n }.merge(extra)
  end

  def self.convert_to_array(id:, lat:, lon:, **_extra)
    Validator.validate_wgs84!(id: id, lat: lat, lon: lon)
    e, n = Wgs84ToBng.convert(lat.to_f, lon.to_f)
    [id, e, n]
  end

  def self.convert_to_json(id:, lat:, lon:, **extra)
    convert_to_hash(id: id, lat: lat, lon: lon, **extra).to_json
  end

  # Batch: accepts array of hashes with :id, :lat, :lon (plus optional extras)
  def self.convert_many_to_hash(points)
    points.each_with_index.map do |pt, i|
      id  = pt[:id]
      lat = pt[:lat]
      lon = pt[:lon]
      Validator.validate_wgs84!(id: id, lat: lat, lon: lon, index: i)
      extra = pt.reject { |k, _| [:id, :lat, :lon].include?(k) }
      e, n = Wgs84ToBng.convert(lat.to_f, lon.to_f)
      { id: id, easting: e, northing: n }.merge(extra)
    end
  end

  def self.convert_many_to_array(points)
    points.each_with_index.map do |pt, i|
      id  = pt[:id]
      lat = pt[:lat]
      lon = pt[:lon]
      Validator.validate_wgs84!(id: id, lat: lat, lon: lon, index: i)
      e, n = Wgs84ToBng.convert(lat.to_f, lon.to_f)
      [id, e, n]
    end
  end

  def self.convert_many_to_json(points)
    convert_many_to_hash(points).to_json
  end

  # -- Reverse: BNG -> WGS84 --------------------------------------------------

  def self.reverse_to_hash(id:, easting:, northing:, **extra)
    Validator.validate_bng!(id: id, easting: easting, northing: northing)
    lat, lon = BngToWgs84.convert(easting.to_f, northing.to_f)
    { id: id, lat: lat, lon: lon }.merge(extra)
  end

  def self.reverse_to_array(id:, easting:, northing:, **_extra)
    Validator.validate_bng!(id: id, easting: easting, northing: northing)
    lat, lon = BngToWgs84.convert(easting.to_f, northing.to_f)
    [id, lat, lon]
  end

  def self.reverse_to_json(id:, easting:, northing:, **extra)
    reverse_to_hash(id: id, easting: easting, northing: northing, **extra).to_json
  end

  def self.reverse_many_to_hash(points)
    points.each_with_index.map do |pt, i|
      id       = pt[:id]
      easting  = pt[:easting]
      northing = pt[:northing]
      Validator.validate_bng!(id: id, easting: easting, northing: northing, index: i)
      extra = pt.reject { |k, _| [:id, :easting, :northing].include?(k) }
      lat, lon = BngToWgs84.convert(easting.to_f, northing.to_f)
      { id: id, lat: lat, lon: lon }.merge(extra)
    end
  end

  def self.reverse_many_to_array(points)
    points.each_with_index.map do |pt, i|
      id       = pt[:id]
      easting  = pt[:easting]
      northing = pt[:northing]
      Validator.validate_bng!(id: id, easting: easting, northing: northing, index: i)
      lat, lon = BngToWgs84.convert(easting.to_f, northing.to_f)
      [id, lat, lon]
    end
  end

  def self.reverse_many_to_json(points)
    reverse_many_to_hash(points).to_json
  end
end
