#!/usr/bin/env ruby
#
# Make Chirpy's client-side search language-aware under jekyll-polyglot.
#
# Why a plugin instead of shadowing _includes/search-loader.html?
#   Chirpy's search-loader.html hard-codes the index path as
#     json: '{{ "/assets/js/data/search.json" | relative_url }}'
#   `relative_url` only prepends site.baseurl, so it is NOT language-aware.
#   Polyglot's own URL relativization only rewrites `href="..."` attributes in
#   the rendered HTML; this path lives inside a `json:'...'` JS string, so it is
#   left untouched. Result: every /en/ page fetches the ROOT (default-lang)
#   search index -> English search returns Korean results.
#
#   Polyglot DOES emit a per-language index at /<lang>/assets/js/data/search.json
#   (as long as assets/js/data is NOT in exclude_from_localization). This hook
#   rewrites the loader's path in the rendered output of non-default-language
#   pages to point at that per-language index. No gem file is shadowed; if the
#   theme ever renames the loader path, this targeted string-replace simply
#   no-ops (search falls back to the root index) instead of breaking the build.
#
# To revert, delete this file.

SEARCH_INDEX_PATH = "/assets/js/data/search.json"

Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
  site = item.site
  active = site.respond_to?(:active_lang) ? site.active_lang : nil
  default = site.respond_to?(:default_lang) ? site.default_lang : nil

  # Default-language tree lives at the site root; its path is already correct.
  next if active.nil? || default.nil? || active == default
  next if item.output.nil?

  localized = "/#{active}#{SEARCH_INDEX_PATH}"
  # Guard against double-prefixing if the string is already localized.
  next if item.output.include?(localized)

  item.output = item.output.gsub(SEARCH_INDEX_PATH, localized)
end
