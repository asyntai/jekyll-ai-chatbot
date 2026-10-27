# frozen_string_literal: true

require_relative "lib/jekyll-ai-chatbot/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-ai-chatbot"
  spec.version       = JekyllAiChatbot::VERSION
  spec.author        = "Asyntai"
  spec.email         = "hello@asyntai.com"
  spec.summary       = "Add the Asyntai AI chat assistant to your Jekyll site."
  spec.description   = "Adds the Asyntai AI chatbot to every page of your Jekyll site. " \
                       "It answers visitor questions from your own content, in 80+ languages."
  spec.homepage      = "https://asyntai.com/documentation/integrations/jekyll/"
  spec.license       = "MIT"
  spec.metadata      = {
    "homepage_uri" => "https://asyntai.com/documentation/integrations/jekyll/",
    "source_code_uri" => "https://github.com/asyntai/jekyll-ai-chatbot",
    "bug_tracker_uri" => "https://github.com/asyntai/jekyll-ai-chatbot/issues",
    "rubygems_mfa_required" => "true",
  }

  spec.files         = Dir["lib/**/*.rb"] + %w[README.md LICENSE]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "jekyll", ">= 3.7", "< 5.0"
end
