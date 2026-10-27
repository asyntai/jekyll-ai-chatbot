# frozen_string_literal: true

# Asyntai AI chatbot for Jekyll.
#
# In _config.yml:
#
#   plugins:
#     - jekyll-ai-chatbot
#
#   asyntai:
#     widget_id: asyntai_1a2b3c4d5e6f

require "jekyll"
require "jekyll-ai-chatbot/core"

module JekyllAiChatbot
  # Settings of the site being built, read once per build.
  @settings = nil
  @tag = nil

  class << self
    attr_reader :settings, :tag

    def configure(site)
      @settings = validate_options(site.config[CONFIG_KEY])
      @tag = build_tag(@settings)
    rescue ConfigurationError => e
      raise Jekyll::Errors::FatalException, e.message
    end
  end
end

# `after_reset` runs at the start of every build, also on each rebuild of
# `jekyll serve`, so a changed widget ID in _config.yml is picked up.
Jekyll::Hooks.register :site, :after_reset do |site|
  JekyllAiChatbot.configure(site)
end

# Pages, posts and collection documents. Low priority, so the widget goes in
# after other plugins change the page.
Jekyll::Hooks.register [:pages, :documents], :post_render, priority: :low do |doc|
  next if JekyllAiChatbot.settings.nil?

  JekyllAiChatbot.apply(doc, JekyllAiChatbot.settings, JekyllAiChatbot.tag, Jekyll.env)
end
