# frozen_string_literal: true

RSpec.describe "Spamtroll public post moderation" do
  fab!(:user) { Fabricate(:user, trust_level: 0) }
  fab!(:category)
  fab!(:topic) { Fabricate(:topic, category: category) }
  let(:raw) { "An ordinary public discussion message that is long enough for validation." }
  let(:args) { { raw: raw, topic_id: topic.id } }
  let(:endpoint) { DiscourseSpamtroll::Client::ENDPOINT.to_s }

  before do
    SiteSetting.spamtroll_enabled = true
    SiteSetting.spamtroll_api_key = "only-for-offline-tests"
    SiteSetting.spamtroll_max_trust_level = 1
    SiteSetting.spamtroll_review_suspicious = false
    SiteSetting.spamtroll_send_author_email = false
    SiteSetting.spamtroll_send_author_ip = false
    SiteSetting.approve_post_count = 0
    SiteSetting.auto_silence_fast_typers_on_first_post = false
  end

  def verdict(status)
    stub_request(:post, endpoint).to_return(
      body: { success: true, data: { status: status, spam_score: status == "blocked" ? 95 : 20 } }.to_json,
      headers: { "Content-Type" => "application/json" },
    )
  end

  def perform(author = user, options = args)
    NewPostManager.new(author, options.dup).perform
  end

  it "queues a blocked reply for actual human review, then permits moderator approval" do
    request = verdict("blocked")
    result = nil
    expect { result = perform }.to change(ReviewableQueuedPost, :count).by(1).and change(Post, :count).by(0)
    expect(result).to be_success
    expect(result.action).to eq(:enqueued)
    queued = result.reviewable
    expect(queued.payload["raw"]).to eq(raw)
    expect(queued.reviewable_scores.first.reason).to eq("spamtroll_spam")
    moderator = Fabricate(:moderator, refresh_auto_groups: true)
    expect { queued.perform(moderator, :approve_post) }.to change(Post, :count).by(1)
    expect(request).to have_been_requested.once
  end

  it "queues a blocked new topic without publishing it" do
    verdict("blocked")
    options = { raw: raw, title: "A new public topic for moderation", category: category.id }
    result = nil
    expect { result = perform(user, options) }.to change(Topic, :count).by(0).and change(ReviewableQueuedPost, :count).by(1)
    expect(result).to be_success
    expect(result.reviewable.payload["title"]).to eq(options[:title])
  end

  it "queues a blocked reply with a real additive score over 100" do
    stub_request(:post, endpoint).to_return(
      body: { success: true, data: { status: "blocked", spam_score: 250.125 } }.to_json,
      headers: { "Content-Type" => "application/json" },
    )
    expect { perform }.to change(ReviewableQueuedPost, :count).by(1).and change(Post, :count).by(0)
  end

  it "publishes a safe reply with a negative real additive score" do
    request = stub_request(:post, endpoint).to_return(
      body: { success: true, data: { status: "safe", spam_score: -12.5 } }.to_json,
      headers: { "Content-Type" => "application/json" },
    )
    expect { perform }.to change(Post, :count).by(1).and change(ReviewableQueuedPost, :count).by(0)
    expect(request).to have_been_requested.once
  end

  %w[safe suspicious].each do |status|
    it "publishes #{status} by default" do
      verdict(status)
      expect { perform }.to change(Post, :count).by(1).and change(ReviewableQueuedPost, :count).by(0)
    end
  end

  it "allows opting into review of suspicious verdicts" do
    SiteSetting.spamtroll_review_suspicious = true
    verdict("suspicious")
    expect { perform }.to change(ReviewableQueuedPost, :count).by(1)
  end

  [401, 402, 429, 503].each do |status|
    it "publishes during HTTP #{status} without labelling the verdict safe" do
      stub_request(:post, endpoint).to_return(status: status)
      result = nil
      expect { result = perform }.to change(Post, :count).by(1)
      expect(result).to be_success
      expect(result.reviewable).to be_nil
    end
  end

  it "publishes during timeout and malformed API responses" do
    stub_request(:post, endpoint).to_timeout
    expect { perform }.to change(Post, :count).by(1)
    stub_request(:post, endpoint).to_return(body: "not JSON", headers: { "Content-Type" => "application/json" })
    expect { perform }.to change(Post, :count).by(1)
  end

  it "preserves native approval requirements and their reason without scanning" do
    SiteSetting.approve_post_count = 10
    result = perform
    expect(result.action).to eq(:enqueued)
    expect(result.reviewable.reviewable_scores.first.reason).not_to eq("spamtroll_spam")
    expect(a_request(:post, endpoint)).not_to have_been_made
  end

  it "sends only public content/source by default" do
    request = stub_request(:post, endpoint).with do |req|
      JSON.parse(req.body) == { "content" => raw, "source" => "comment" }
    end.to_return(body: { success: true, data: { status: "safe", spam_score: 1 } }.to_json,
                  headers: { "Content-Type" => "application/json" })
    perform
    expect(request).to have_been_requested.once
  end

  it "keeps the API key out of browser-visible site settings" do
    expect(SiteSetting.client_settings_hash).not_to have_key(:spamtroll_api_key)
    expect(SiteSetting.client_settings_hash).not_to have_key("spamtroll_api_key")
    expect(SiteSetting.client_settings_json).not_to include("only-for-offline-tests")
  end

  it "includes author metadata only when explicitly configured" do
    SiteSetting.spamtroll_send_author_email = true
    SiteSetting.spamtroll_send_author_ip = true
    user.update!(ip_address: "198.51.100.7")
    request = stub_request(:post, endpoint).with do |req|
      data = JSON.parse(req.body)
      data["email"] == user.email && data["ip_address"] == "198.51.100.7"
    end.to_return(body: { success: true, data: { status: "safe", spam_score: 1 } }.to_json,
                  headers: { "Content-Type" => "application/json" })
    perform
    expect(request).to have_been_requested.once
  end

  it "skips staff, trusted users and a disabled/missing-key integration" do
    staff = Fabricate(:moderator)
    trusted = Fabricate(:user, trust_level: 3)
    expect(DiscourseSpamtroll::PostGate.call(NewPostManager.new(staff, args.dup))).to be_nil
    expect(DiscourseSpamtroll::PostGate.call(NewPostManager.new(trusted, args.dup))).to be_nil
    SiteSetting.spamtroll_enabled = false
    expect(DiscourseSpamtroll::PostGate.call(NewPostManager.new(user, args.dup))).to be_nil
    SiteSetting.spamtroll_enabled = true
    SiteSetting.spamtroll_api_key = ""
    expect(DiscourseSpamtroll::PostGate.call(NewPostManager.new(user, args.dup))).to be_nil
    expect(a_request(:post, endpoint)).not_to have_been_made
  end

  it "never scans private messages, restricted categories or import/review bypasses" do
    pm = Fabricate(:private_message_topic, user: user)
    private_category = Fabricate(:private_category, group: Fabricate(:group))
    hidden_topic = Fabricate(:topic, category: private_category)
    [{ raw: raw, archetype: Archetype.private_message },
     { raw: raw, topic_id: pm.id }, { raw: raw, topic_id: hidden_topic.id },
     { raw: raw, category: private_category.id }, args.merge(import_mode: true),
     args.merge(skip_validations: true), args.merge(reviewed_queued_post: true)].each do |options|
      expect(DiscourseSpamtroll::PostGate.call(NewPostManager.new(user, options.dup))).to be_nil
    end
    expect(a_request(:post, endpoint)).not_to have_been_made
  end
end
