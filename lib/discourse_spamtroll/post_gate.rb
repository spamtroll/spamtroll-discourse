# frozen_string_literal: true

module DiscourseSpamtroll
  class PostGate
    def self.call(manager)
      return unless eligible?(manager)

      # Preserve native approval requirements and their explanations before scanning.
      native = NewPostManager.default_handler(manager)
      return native if native

      args = manager.args
      content = [args[:title], args[:raw]].compact.join("\n\n")
      payload = { content: content, source: "comment" }
      payload[:email] = manager.user.email if SiteSetting.spamtroll_send_author_email
      payload[:ip_address] = manager.user.ip_address.to_s if SiteSetting.spamtroll_send_author_ip
      verdict = Client.scan(payload, api_key: SiteSetting.spamtroll_api_key)
      return unless verdict
      return unless verdict[:status] == "blocked" ||
        (verdict[:status] == "suspicious" && SiteSetting.spamtroll_review_suspicious)

      manager.enqueue(:spamtroll_spam)
    end

    def self.eligible?(manager)
      return false unless SiteSetting.spamtroll_enabled && !SiteSetting.spamtroll_api_key.to_s.strip.empty?
      user = manager.user
      return false unless user && !user.staff? && user.trust_level <= SiteSetting.spamtroll_max_trust_level
      args = manager.args
      return false if args[:import_mode] || args[:skip_validations] || args[:reviewed_queued_post]
      return false if args[:archetype] == Archetype.private_message
      return false unless args[:raw].is_a?(String) && !args[:raw].strip.empty?

      if args[:topic_id]
        topic = Topic.find_by(id: args[:topic_id])
        return false unless topic && !topic.private_message? && user.guardian.can_create_post_on_topic?(topic)
        category = topic.category
      else
        category = Category.find_by(id: args[:category]) if args[:category]
        return false if category && !user.guardian.can_create_topic_on_category?(category)
      end
      return false if category&.read_restricted

      true
    end
  end
end
