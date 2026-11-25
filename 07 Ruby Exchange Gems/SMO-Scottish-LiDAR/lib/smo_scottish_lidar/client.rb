# frozen_string_literal: true

require "net/http"
require "uri"

module SmoScottishLidar
  # Low-level S3 client. Uses only Ruby stdlib net/http.
  # Accesses the public (unsigned) srsp-open-data bucket directly over HTTPS.
  class Client
    MAX_KEYS = 1000
    MSG_TOO_MANY_REDIRECTS = "Too many redirects"
    MSG_NO_LOCATION_HEADER = "Redirect with no Location header"

    def initialize(verbose: false)
      @verbose = verbose
    end

    # Lists all object keys under a given S3 prefix.
    # Handles S3 pagination (continuation tokens) automatically.
    # Returns an Array of Hashes: [{ key:, size:, last_modified: }, ...]
    def list_objects(prefix)
      objects = []
      continuation_token = nil

      loop do
        xml = fetch_list_page(prefix, continuation_token)
        page_objects, next_token, truncated = parse_list_response(xml)
        objects.concat(page_objects)

        break unless truncated

        continuation_token = next_token
      end

      objects
    end

    # Downloads a single S3 object key to a local file path.
    # Follows redirects, streams in chunks to avoid loading into memory.
    # Returns true on success, raises on error.
    def download_object(key, local_path, &progress_block)
      url = "#{BASE_URL}/#{key}"
      log "Downloading: #{url} -> #{local_path}"

      uri = URI.parse(url)
      fetch_with_redirect(uri, local_path, &progress_block)
      true
    end

    private

    def fetch_list_page(prefix, continuation_token)
      params = {
        "list-type" => "2",
        "prefix"    => prefix,
        "max-keys"  => MAX_KEYS.to_s
      }
      params["continuation-token"] = continuation_token if continuation_token

      query = params.map { |k, v| "#{uri_encode(k)}=#{uri_encode(v)}" }.join("&")
      uri = URI.parse("#{BASE_URL}/?#{query}")

      log "Listing: #{uri}"
      response = get_response(uri)
      response.body
    end

    def parse_list_response(xml)
      objects = []

      xml.scan(%r{<Contents>(.*?)</Contents>}m).each do |match|
        block = match[0]
        key   = extract_tag(block, "Key")
        size  = extract_tag(block, "Size").to_i
        mtime = extract_tag(block, "LastModified")
        objects << { key: key, size: size, last_modified: mtime }
      end

      truncated = extract_tag(xml, "IsTruncated") == "true"
      next_token = extract_tag(xml, "NextContinuationToken")

      [objects, next_token, truncated]
    end

    def fetch_with_redirect(uri, local_path, redirects_remaining: 5, &progress_block)
      raise MSG_TOO_MANY_REDIRECTS if redirects_remaining.zero?

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        http.request(request) do |response|
          case response.code.to_i
          when 200
            total = response["content-length"]&.to_i
            received = 0
            File.open(local_path, "wb") do |f|
              response.read_body do |chunk|
                f.write(chunk)
                received += chunk.bytesize
                progress_block&.call(received, total)
              end
            end
          when 301, 302, 307, 308
            location = response["location"]
            raise MSG_NO_LOCATION_HEADER unless location

            log "Redirect -> #{location}"
            fetch_with_redirect(URI.parse(location), local_path,
                                redirects_remaining: redirects_remaining - 1,
                                &progress_block)
          else
            raise "HTTP #{response.code} for #{uri}"
          end
        end
      end
    end

    def get_response(uri, redirects_remaining: 5)
      raise "#{MSG_TOO_MANY_REDIRECTS} listing #{uri}" if redirects_remaining.zero?

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        response = http.get(uri.request_uri)
        case response.code.to_i
        when 200
          response
        when 301, 302, 307, 308
          location = response["location"]
          raise MSG_NO_LOCATION_HEADER unless location

          log "Redirect -> #{location}"
          get_response(URI.parse(location), redirects_remaining: redirects_remaining - 1)
        else
          raise "HTTP #{response.code} listing #{uri}"
        end
      end
    end

    def extract_tag(xml, tag)
      match = xml.match(%r{<#{tag}>(.*?)</#{tag}>}m)
      match ? match[1].strip : ""
    end

    def uri_encode(str)
      URI.encode_uri_component(str.to_s)
    end

    def log(msg)
      warn "[smo_scottish_lidar] #{msg}" if @verbose
    end
  end
end
