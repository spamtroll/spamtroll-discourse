# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "timeout"

module DiscourseSpamtroll
  class Client
    ENDPOINT = URI("https://api.spamtroll.io/api/v1/scan/check")
    MAX_CONTENT_BYTES = 64 * 1024
    MAX_RESPONSE_BYTES = 64 * 1024
    TOTAL_TIMEOUT = 5

    def self.scan(payload, api_key:)
      return if api_key.to_s.strip.empty?
      return unless payload[:content].is_a?(String) && payload[:content].valid_encoding?
      return if payload[:content].strip.empty? || payload[:content].bytesize > MAX_CONTENT_BYTES

      request = Net::HTTP::Post.new(ENDPOINT)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request["X-API-Key"] = api_key
      request["User-Agent"] = "SpamtrollDiscourse/1.0.1"
      request.body = JSON.generate(payload)
      http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port, nil)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = 2
      http.read_timeout = 3
      http.write_timeout = 2
      http.max_retries = 0
      body = +""
      Timeout.timeout(TOTAL_TIMEOUT) do
        http.start do |connection|
          connection.request(request) do |response|
            return unless response.code == "200"
            return unless response["Content-Type"].to_s.downcase.start_with?("application/json")
            response.read_body do |chunk|
              return if body.bytesize + chunk.bytesize > MAX_RESPONSE_BYTES
              body << chunk
            end
          end
        end
      end
      decoded = JSON.parse(body)
      return unless decoded.is_a?(Hash) && decoded["success"] == true
      verdict = decoded["data"]
      return unless verdict.is_a?(Hash) && %w[safe suspicious blocked].include?(verdict["status"])
      score = verdict["spam_score"]
      return unless score.is_a?(Numeric) && score.finite?

      { status: verdict["status"], score: score }
    rescue StandardError => error
      # Network/parser errors can contain keys, URLs or submitted content.
      Rails.logger.warn("Spamtroll scan unavailable (#{error.class.name})")
      nil
    end
  end
end
