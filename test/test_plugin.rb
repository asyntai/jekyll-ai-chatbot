# frozen_string_literal: true

# Offline checks for jekyll-ai-chatbot. Run: ruby -Ilib test/test_plugin.rb

require "minitest/autorun"
require "jekyll-ai-chatbot/core"

class TestJekyllAiChatbot < Minitest::Test
  P = JekyllAiChatbot
  ID = "asyntai_1a2b3c4d5e6f"

  class FakeDoc
    attr_accessor :output, :output_ext, :data

    def initialize(output:, output_ext:, writes: true, data: {})
      @output = output
      @output_ext = output_ext
      @writes = writes
      @data = data
    end

    def write?
      @writes != false
    end
  end

  def settings(extra = {})
    P.validate_options({ "widget_id" => ID }.merge(extra))
  end

  def tag
    P.build_tag(settings)
  end

  def page(ext = ".html", **opts)
    FakeDoc.new(output: "<html><body></body></html>", output_ext: ext, **opts)
  end

  # --- options -------------------------------------------------------------

  def test_missing_widget_id_stops_the_build
    err = assert_raises(P::ConfigurationError) { P.validate_options({}) }
    assert_includes err.message, "widget_id"
    assert_includes err.message, "_config.yml"
    assert_includes err.message, "Install page"
  end

  def test_missing_asyntai_block_stops_the_build
    assert_raises(P::ConfigurationError) { P.validate_options(nil) }
  end

  def test_asyntai_as_plain_string_explains_the_block
    err = assert_raises(P::ConfigurationError) { P.validate_options(ID) }
    assert_includes err.message, "must be a block"
  end

  def test_blank_widget_id_stops_the_build
    assert_raises(P::ConfigurationError) { P.validate_options("widget_id" => "   ") }
  end

  def test_number_widget_id_stops_the_build
    assert_raises(P::ConfigurationError) { P.validate_options("widget_id" => 12345) }
  end

  def test_malformed_widget_id_stops_the_build
    err = assert_raises(P::ConfigurationError) { P.validate_options("widget_id" => "1a2b3c") }
    assert_includes err.message, "does not look like a widget ID"
  end

  def test_widget_id_with_script_injection_is_refused
    assert_raises(P::ConfigurationError) do
      P.validate_options("widget_id" => "asyntai_x\"></script><script>alert(1)")
    end
  end

  def test_widget_id_is_trimmed
    assert_equal ID, P.validate_options("widget_id" => "  #{ID} ").widget_id
  end

  def test_symbol_keys_work
    assert_equal ID, P.validate_options(widget_id: ID).widget_id
  end

  def test_default_script_url
    assert_equal P::DEFAULT_SCRIPT_URL, settings.script_url
  end

  def test_custom_script_url
    assert_equal "https://example.com/w.js", settings("script_url" => "https://example.com/w.js").script_url
  end

  def test_blank_script_url_falls_back
    assert_equal P::DEFAULT_SCRIPT_URL, settings("script_url" => " ").script_url
  end

  def test_enable_in_development_default_true
    assert settings.enable_in_development
    refute settings("enable_in_development" => false).enable_in_development
  end

  # --- loader --------------------------------------------------------------

  def test_loader_has_widget_id_and_url
    js = P.build_loader(ID, P::DEFAULT_SCRIPT_URL)
    assert_includes js, "\"#{ID}\""
    assert_includes js, "\"#{P::DEFAULT_SCRIPT_URL}\""
    assert_includes js, "addEventListener(\"load\",l)"
    assert_includes js, "script[data-asyntai-id]"
  end

  def test_loader_escapes_less_than
    js = P.build_loader(ID, "https://example.com/</script>.js")
    refute_includes js, "</script>"
    assert_includes js, "\\u003c/script>"
  end

  def test_tag_is_one_script_element
    t = tag
    assert t.start_with?("<script data-asyntai-loader>")
    assert t.end_with?("</script>")
    assert_equal 1, t.scan("</script>").length
  end

  def test_loader_is_valid_javascript
    node = ENV.fetch("NODE", "node")
    skip "node not found" unless system(node, "--version", out: File::NULL, err: File::NULL)
    require "tmpdir"
    Dir.mktmpdir do |dir|
      path = File.join(dir, "loader.js")
      File.write(path, P.build_loader(ID, P::DEFAULT_SCRIPT_URL))
      assert system(node, "--check", path), "node --check failed"
    end
  end

  # --- injection -----------------------------------------------------------

  def test_inject_before_body
    out = P.inject_into_html("<html><body><p>x</p></body></html>", tag)
    assert_includes out, "<p>x</p>#{tag}</body>"
  end

  def test_inject_before_last_body
    html = "<html><body><pre>&lt;/body&gt; </body> text</pre></body></html>"
    out = P.inject_into_html(html, tag)
    assert out.end_with?("#{tag}</body></html>")
    assert_equal 1, out.scan("data-asyntai-loader").length
  end

  def test_inject_uppercase_body
    out = P.inject_into_html("<HTML><BODY>x</BODY></HTML>", tag)
    assert_includes out, "x#{tag}</BODY>"
  end

  def test_inject_before_html_without_body
    out = P.inject_into_html("<html><p>x</p></html>", tag)
    assert_includes out, "<p>x</p>#{tag}</html>"
  end

  def test_fragment_is_left_alone
    assert_equal "<p>x</p>", P.inject_into_html("<p>x</p>", tag)
  end

  def test_existing_snippet_is_left_alone
    html = "<html><body><script data-asyntai-id=\"#{ID}\"></script></body></html>"
    assert_equal html, P.inject_into_html(html, tag)
  end

  def test_nil_is_left_alone
    assert_nil P.inject_into_html(nil, tag)
  end

  def test_injection_runs_once
    once = P.inject_into_html("<html><body></body></html>", tag)
    assert_equal once, P.inject_into_html(once, tag)
  end

  # --- which documents -----------------------------------------------------

  def test_apply_html_page
    doc = page
    P.apply(doc, settings, tag, "production")
    assert_includes doc.output, "data-asyntai-loader"
  end

  def test_apply_htm_page
    doc = page(".htm")
    P.apply(doc, settings, tag, "production")
    assert_includes doc.output, "data-asyntai-loader"
  end

  def test_apply_skips_feed
    doc = FakeDoc.new(output: "<feed></feed>", output_ext: ".xml")
    P.apply(doc, settings, tag, "production")
    assert_equal "<feed></feed>", doc.output
  end

  def test_apply_skips_json
    doc = FakeDoc.new(output: "{\"a\":\"</body>\"}", output_ext: ".json")
    P.apply(doc, settings, tag, "production")
    assert_equal "{\"a\":\"</body>\"}", doc.output
  end

  def test_apply_skips_unwritten_page
    doc = page(writes: false)
    P.apply(doc, settings, tag, "production")
    refute_includes doc.output, "data-asyntai-loader"
  end

  def test_apply_skips_page_with_front_matter_opt_out
    doc = page(data: { "asyntai" => false })
    P.apply(doc, settings, tag, "production")
    refute_includes doc.output, "data-asyntai-loader"
  end

  def test_apply_keeps_widget_when_front_matter_has_other_asyntai_value
    doc = page(data: { "asyntai" => "yes" })
    P.apply(doc, settings, tag, "production")
    assert_includes doc.output, "data-asyntai-loader"
  end

  def test_apply_on_in_development_by_default
    doc = page
    P.apply(doc, settings, tag, "development")
    assert_includes doc.output, "data-asyntai-loader"
  end

  def test_apply_off_in_development_when_disabled
    doc = page
    P.apply(doc, settings("enable_in_development" => false), tag, "development")
    refute_includes doc.output, "data-asyntai-loader"
  end

  def test_apply_on_in_production_when_disabled_for_development
    doc = page
    P.apply(doc, settings("enable_in_development" => false), tag, "production")
    assert_includes doc.output, "data-asyntai-loader"
  end
end
