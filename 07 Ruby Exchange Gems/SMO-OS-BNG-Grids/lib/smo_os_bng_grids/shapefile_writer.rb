# frozen_string_literal: true

require "fileutils"

module SmoOsBngGrids
  # Writes a set of BNG grid squares to ESRI Shapefile format (.shp/.shx/.dbf/.prj).
  # Pure Ruby, no external dependencies.
  # Output CRS: OSGB36 British National Grid (EPSG:27700).
  class ShapefileWriter
    SHAPE_TYPE_POLYGON = 5
    DBF_VERSION = 0x03

    # @param entries [Array<Hash>] from Lister#list: [{ref:, min_e:, min_n:, max_e:, max_n:}]
    # @param path    [String] output path WITHOUT extension, e.g. "/tmp/ns_10km"
    def write(entries, path)
      FileUtils.mkdir_p(File.dirname(path))
      write_shp_shx(entries, path)
      write_dbf(entries, path)
      write_prj(path)
      puts "Written #{entries.size} features to:"
      puts "  #{path}.shp"
      puts "  #{path}.shx"
      puts "  #{path}.dbf"
      puts "  #{path}.prj"
    end

    private

    # Each polygon is a rectangle: SW, SE, NE, NW, SW (5 points, closed ring).
    def polygon_points(e)
      [
        [e[:min_e], e[:min_n]],
        [e[:max_e], e[:min_n]],
        [e[:max_e], e[:max_n]],
        [e[:min_e], e[:max_n]],
        [e[:min_e], e[:min_n]]
      ]
    end

    # Content length of one polygon record in bytes and 16-bit words.
    # 4 (shape type) + 32 (bbox) + 4 (num parts) + 4 (num points) + 4 (parts[0]) + 5*16 (points)
    RECORD_CONTENT_BYTES = 4 + 32 + 4 + 4 + 4 + (5 * 16)  # 128 bytes
    RECORD_CONTENT_WORDS = RECORD_CONTENT_BYTES / 2         # 64 words
    # Total size of one SHP record (8-byte header + content), in 16-bit words.
    RECORD_TOTAL_WORDS   = (8 + RECORD_CONTENT_BYTES) / 2  # 68 words

    def write_shp_shx(entries, path)
      num = entries.size

      # Overall bounding box.
      min_e = entries.map { |e| e[:min_e] }.min.to_f
      min_n = entries.map { |e| e[:min_n] }.min.to_f
      max_e = entries.map { |e| e[:max_e] }.max.to_f
      max_n = entries.map { |e| e[:max_n] }.max.to_f

      shp = File.open("#{path}.shp", "wb")
      shx = File.open("#{path}.shx", "wb")

      # File headers (100 bytes each).
      shp_file_words = 50 + num * RECORD_TOTAL_WORDS
      shx_file_words = 50 + num * 4  # SHX: 8 bytes (4 words) per record

      [shp, shx].each_with_index do |f, i|
        fw = i == 0 ? shp_file_words : shx_file_words
        f.write([9994].pack("N"))           # file code
        f.write(([0] * 5).pack("N5"))       # unused
        f.write([fw].pack("N"))             # file length in 16-bit words
        f.write([1000].pack("V"))           # version
        f.write([SHAPE_TYPE_POLYGON].pack("V")) # shape type
        f.write([min_e, min_n, max_e, max_n].pack("d4")) # bounding box
        f.write([0.0, 0.0, 0.0, 0.0].pack("d4"))         # Z and M ranges
      end

      shx_offset = 50  # byte offset of first record from file start, in 16-bit words

      entries.each_with_index do |e, i|
        pts  = polygon_points(e)
        bbox = [e[:min_e].to_f, e[:min_n].to_f, e[:max_e].to_f, e[:max_n].to_f]

        # SHX record: offset of SHP record (words from file start) + content length (words, no header).
        shx.write([shx_offset, RECORD_CONTENT_WORDS].pack("N2"))
        shx_offset += RECORD_TOTAL_WORDS  # advance by full record size (header + content)

        # SHP record header: record number (1-based) + content length (words, excluding this header).
        shp.write([i + 1, RECORD_CONTENT_WORDS].pack("N2"))

        # SHP record content.
        shp.write([SHAPE_TYPE_POLYGON].pack("V"))
        shp.write(bbox.pack("d4"))
        shp.write([1].pack("V"))           # num parts
        shp.write([5].pack("V"))           # num points
        shp.write([0].pack("V"))           # parts[0] = 0
        pts.each { |x, y| shp.write([x.to_f, y.to_f].pack("d2")) }
      end

      shp.close
      shx.close
    end

    def write_dbf(entries, path)
      # Fields: bng_ref (C,12), min_e (N,10), min_n (N,10), max_e (N,10), max_n (N,10), resolution (C,6)
      fields = [
        { name: "bng_ref",    type: "C", length: 12, decimals: 0 },
        { name: "min_e",      type: "N", length: 10, decimals: 0 },
        { name: "min_n",      type: "N", length: 10, decimals: 0 },
        { name: "max_e",      type: "N", length: 10, decimals: 0 },
        { name: "max_n",      type: "N", length: 10, decimals: 0 },
        { name: "res",        type: "C", length:  6, decimals: 0 }
      ]

      header_size = 32 + fields.size * 32 + 1
      record_size = 1 + fields.sum { |f| f[:length] }

      File.open("#{path}.dbf", "wb") do |f|
        # DBF header.
        f.write([DBF_VERSION].pack("C"))
        now = Time.now
        f.write([now.year - 1900, now.month, now.day].pack("C3"))
        f.write([entries.size].pack("V"))
        f.write([header_size].pack("v"))
        f.write([record_size].pack("v"))
        f.write(("\x00" * 20))  # reserved

        # Field descriptors.
        fields.each do |fld|
          name_bytes = fld[:name].ljust(11, "\x00")[0, 11]
          f.write(name_bytes)
          f.write(fld[:type])
          f.write("\x00" * 4)  # reserved
          f.write([fld[:length]].pack("C"))
          f.write([fld[:decimals]].pack("C"))
          f.write("\x00" * 14)  # reserved
        end
        f.write("\r")  # header terminator

        # Records.
        entries.each do |e|
          resolution = Grid.resolution_of(e[:ref]) rescue "?"
          f.write(" ")  # deletion flag
          f.write(e[:ref].to_s.ljust(12)[0, 12])
          f.write(e[:min_e].to_s.rjust(10)[0, 10])
          f.write(e[:min_n].to_s.rjust(10)[0, 10])
          f.write(e[:max_e].to_s.rjust(10)[0, 10])
          f.write(e[:max_n].to_s.rjust(10)[0, 10])
          f.write(resolution.ljust(6)[0, 6])
        end

        f.write("\x1a")  # EOF
      end
    end

    def write_prj(path)
      File.write("#{path}.prj", CRS_WKT)
    end
  end
end
