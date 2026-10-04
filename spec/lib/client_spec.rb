# frozen_string_literal: true

RSpec.describe DiscourseSpamtroll::Client do
  let(:payload) { { content: "A public message to scan", source: "comment" } }
  let(:key) { "only-for-offline-tests" }
  let(:endpoint) { described_class::ENDPOINT.to_s }

  def response(status = "blocked", score = 95)
    { success: true, data: { status: status, spam_score: score } }.to_json
  end

  def stub_json(body, status: 200)
    stub_request(:post, endpoint).to_return(
      status: status,
      body: body,
      headers: { "Content-Type" => "application/json" },
    )
  end

  it "uses the platform header, server-side key and exact public API envelope" do
    request = stub_request(:post, endpoint).with(
      headers: { "X-API-Key" => key, "Content-Type" => "application/json" },
      body: payload.to_json,
    ).to_return(body: response, headers: { "Content-Type" => "application/json" })
    expect(described_class.scan(payload, api_key: key)).to eq(status: "blocked", score: 95)
    expect(request).to have_been_requested.once
  end

  %w[safe suspicious blocked].each do |status|
    it "accepts a valid #{status} verdict" do
      stub_json(response(status, 42.5))
      expect(described_class.scan(payload, api_key: key)).to eq(status: status, score: 42.5)
    end
  end

  [-12.5, 0, 101, 250.125].each do |score|
    it "accepts a real additive score of #{score} without applying a percentage range" do
      stub_json(response("blocked", score))
      expect(described_class.scan(payload, api_key: key)).to eq(status: "blocked", score: score)
    end
  end

  [301, 401, 402, 422, 429, 500, 503].each do |status|
    it "fails open for HTTP #{status} without redirecting the key" do
      request = stub_json(response, status: status)
      expect(described_class.scan(payload, api_key: key)).to be_nil
      expect(request).to have_been_requested.once
    end
  end

  ["not JSON", "[]", "null", '{"success":false}', '{"status":"blocked","spam_score":99}',
   '{"success":true,"data":null}', '{"success":true,"data":{"status":"future","spam_score":99}}',
   '{"success":true,"data":{"status":"blocked","spam_score":"99"}}',
   '{"success":true,"data":{"status":"blocked","spam_score":null}}',
   '{"success":true,"data":{"status":"blocked","spam_score":true}}',
   '{"success":true,"data":{"status":"blocked","spam_score":1e999}}'].each_with_index do |body, index|
    it "fails open for malformed/unsupported verdict #{index}" do
      stub_json(body)
      expect(described_class.scan(payload, api_key: key)).to be_nil
    end
  end

  it "rejects non-JSON responses and bounds response size" do
    stub_request(:post, endpoint).to_return(body: response, headers: { "Content-Type" => "text/html" })
    expect(described_class.scan(payload, api_key: key)).to be_nil
    stub_json(" " * (described_class::MAX_RESPONSE_BYTES + 1))
    expect(described_class.scan(payload, api_key: key)).to be_nil
  end

  it "skips oversized/invalid content and absent credentials without a request" do
    expect(described_class.scan({ content: "x" * (described_class::MAX_CONTENT_BYTES + 1) }, api_key: key)).to be_nil
    expect(described_class.scan({ content: "\xFF".dup.force_encoding("UTF-8") }, api_key: key)).to be_nil
    expect(described_class.scan({ content: " " }, api_key: key)).to be_nil
    expect(described_class.scan(payload, api_key: " ")).to be_nil
    expect(a_request(:post, endpoint)).not_to have_been_made
  end

  it "fails open on transport failures without logging the secret/content" do
    stub_request(:post, endpoint).to_raise(OpenSSL::SSL::SSLError.new("#{key} #{payload[:content]}"))
    messages = []
    Rails.logger.stubs(:warn).with { |message| messages << message; true }
    expect(described_class.scan(payload, api_key: key)).to be_nil
    expect(messages.join).to include("OpenSSL::SSL::SSLError")
    expect(messages.join).not_to include(key, payload[:content])
  end

  it "enforces the total deadline even when a response keeps the request occupied" do
    stub_request(:post, endpoint).to_return do
      sleep(described_class::TOTAL_TIMEOUT + 1)
      { body: response, headers: { "Content-Type" => "application/json" } }
    end
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    expect(described_class.scan(payload, api_key: key)).to be_nil
    expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 6
  end
end
