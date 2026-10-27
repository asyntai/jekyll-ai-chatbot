# jekyll-ai-chatbot

Add the [Asyntai](https://asyntai.com) AI chat assistant to your Jekyll site.
It answers visitor questions from your own content, in more than 80 languages.

## Install

Add the gem to your `Gemfile`, in the `jekyll_plugins` group:

```ruby
group :jekyll_plugins do
  gem "jekyll-ai-chatbot"
end
```

Run `bundle install`. Then add your widget ID to `_config.yml`:

```yaml
asyntai:
  widget_id: asyntai_1a2b3c4d5e6f
```

If your site lists its plugins in `_config.yml` instead of the Gemfile group,
add it there too:

```yaml
plugins:
  - jekyll-ai-chatbot
```

Build the site. The chat bubble is on every page.

## Where the widget ID comes from

Open the Install page in your [Asyntai dashboard](https://asyntai.com/dashboard).
The widget ID is the value of `data-asyntai-id` in the snippet shown there. It
starts with `asyntai_`.

Creating an account is free, and the Free plan is enough to try the widget.

## Options

All options go under `asyntai:` in `_config.yml`.

| Option | Type | Default | What it does |
| --- | --- | --- | --- |
| `widget_id` | string | required | Your Asyntai widget ID |
| `enable_in_development` | boolean | `true` | Set to `false` to keep the widget off the site while `JEKYLL_ENV` is `development` |
| `script_url` | string | the Asyntai CDN | Advanced. Load the widget from another URL |

A missing or malformed `widget_id` stops the build with a message that says how
to fix it.

Jekyll uses `development` when `JEKYLL_ENV` is not set, also for `jekyll build`.
If you set `enable_in_development: false`, build with
`JEKYLL_ENV=production jekyll build` to get the widget.

To keep the widget off one page, add this to its front matter:

```yaml
asyntai: false
```

## What the plugin does

- It adds the Asyntai loader to every HTML page, just before `</body>`.
  That includes pages, posts, collection documents and pagination pages.
- The loader waits for the page's `load` event, so your own content always
  renders first.
- Feeds, JSON, CSS, Sass and other non-HTML files stay as they are.
- A page that already has the Asyntai snippet keeps it and gets no second one.

Tested with Jekyll 3.10 and 4.4.

## GitHub Pages

The classic GitHub Pages build runs only the plugins on its own approved list.
To use this gem on GitHub Pages, build the site with GitHub Actions
(the "Jekyll" workflow in your repository's Pages settings). Then the gem runs
like on any other host.

## Answering from your content

Asyntai reads your published pages. Add your site URL in the dashboard, and the
assistant answers from the same pages the widget sits on. You can also add extra
documents and question and answer pairs.

## Removing it

Remove the gem from your `Gemfile` and the `asyntai:` block from `_config.yml`,
then build again. The widget is gone.

## Support

Email [hello@asyntai.com](mailto:hello@asyntai.com), or read the
[Jekyll guide](https://asyntai.com/documentation/integrations/jekyll/).

## Licence

MIT
