# frozen_string_literal: true

# Asyntai AI chatbot for Jekyll: the logic, without the hooks, so it can be
# tested outside a Jekyll build.
#
# Adds the Asyntai chat widget to every HTML page the site builds. After a page
# is rendered, the plugin puts the ordinary embed loader just before </body>
# and changes nothing else about the page.

require "json"
require "jekyll-ai-chatbot/version"

module JekyllAiChatbot
  DEFAULT_SCRIPT_URL = "https://widget.asyntai.com/static/js/chat-widget.js"
  WIDGET_ID_PATTERN = /\Aasyntai_[A-Za-z0-9]+\z/
  NAME = "jekyll-ai-chatbot"
  CONFIG_KEY = "asyntai"

  class ConfigurationError < StandardError; end

  Settings = Struct.new(:widget_id, :script_url, :enable_in_development)

  module_function

  # Reads the `asyntai:` block of _config.yml. A wrong option stops the build
  # with a clear message instead of producing a site with no chat.
  def validate_options(options)
    unless options.nil? || options.is_a?(Hash)
      raise ConfigurationError,
            "#{NAME}: \"#{CONFIG_KEY}\" in _config.yml must be a block with " \
            "widget_id inside it, for example:\n\n" \
            "  #{CONFIG_KEY}:\n    widget_id: asyntai_1a2b3c4d5e6f"
    end

    opts = (options || {}).each_with_object({}) { |(k, v), h| h[k.to_s] = v }
    widget_id = opts["widget_id"].is_a?(String) ? opts["widget_id"].strip : ""

    if widget_id.empty?
      raise ConfigurationError,
            "#{NAME}: \"widget_id\" is required. Add it to _config.yml under " \
            "\"#{CONFIG_KEY}:\". Copy it from the Install page of your Asyntai " \
            "dashboard, for example asyntai_1a2b3c4d5e6f."
    end
    unless WIDGET_ID_PATTERN.match?(widget_id)
      raise ConfigurationError,
            "#{NAME}: \"#{widget_id}\" does not look like a widget ID. It starts with " \
            "asyntai_, for example asyntai_1a2b3c4d5e6f."
    end

    script_url = opts["script_url"].is_a?(String) && !opts["script_url"].strip.empty? ?
      opts["script_url"].strip : DEFAULT_SCRIPT_URL

    Settings.new(
      widget_id,
      script_url,
      # Set to false to keep the widget off the site while JEKYLL_ENV is development.
      opts["enable_in_development"] != false
    )
  end

  # JSON string, safe inside an HTML <script> element.
  def js_string(value)
    JSON.generate(value.to_s).gsub("<", "\\u003c")
  end

  # The loader waits for the page's load event before it fetches the widget.
  # An ordinary `<script async src>` holds the load event open until its own
  # fetch finishes, so an unreachable server would delay the host page. This
  # pattern cannot.
  def build_loader(widget_id, script_url)
    "(function(){var l=function(){" \
      "if(document.querySelector(\"script[data-asyntai-id]\"))return;" \
      "var s=document.createElement(\"script\");" \
      "s.src=#{js_string(script_url)};s.async=true;" \
      "s.setAttribute(\"data-asyntai-id\",#{js_string(widget_id)});" \
      "document.head.appendChild(s)};" \
      "if(document.readyState===\"complete\"){l()}" \
      "else{window.addEventListener(\"load\",l)}})();"
  end

  def build_tag(settings)
    "<script data-asyntai-loader>#{build_loader(settings.widget_id, settings.script_url)}</script>"
  end

  # Puts the tag before the last </body>, or before </html> when the page has no
  # body tag. A fragment with neither is left alone: it is not a whole page.
  # A page that already carries an Asyntai snippet is left alone too.
  def inject_into_html(html, tag)
    return html unless html.is_a?(String)
    return html if html.include?("data-asyntai-id")

    lower = html.downcase
    at = lower.rindex("</body>") || lower.rindex("</html>")
    return html if at.nil?

    html[0...at] + tag + html[at..-1]
  end

  # Only pages that are written to disk as .html get the widget. Feeds, JSON,
  # CSS, Sass and pages with `published: false` or no output stay as they are.
  def html_output?(document)
    if document.respond_to?(:write?)
      return false unless document.write?
    end
    ext = document.respond_to?(:output_ext) ? document.output_ext.to_s.downcase : ""
    [".html", ".htm"].include?(ext)
  end

  # A page can opt out with `asyntai: false` in its front matter.
  def opted_out?(document)
    data = document.respond_to?(:data) ? document.data : nil
    data.is_a?(Hash) && data[CONFIG_KEY] == false
  end

  def apply(document, settings, tag, environment)
    return if !settings.enable_in_development && environment.to_s == "development"
    return unless html_output?(document)
    return if opted_out?(document)

    document.output = inject_into_html(document.output, tag)
  end
end
