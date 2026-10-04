# frozen_string_literal: true

# name: spamtroll-discourse
# about: Queue spam verdicts for human moderation; allow posting during API failures.
# version: 1.0.1
# authors: Spamtroll
# url: https://github.com/spamtroll/spamtroll-discourse
# required_version: 2026.9.0

enabled_site_setting :spamtroll_enabled

after_initialize do
  require_relative "lib/discourse_spamtroll/client"
  require_relative "lib/discourse_spamtroll/post_gate"

  NewPostManager.add_handler(10) { |manager| DiscourseSpamtroll::PostGate.call(manager) }
end
