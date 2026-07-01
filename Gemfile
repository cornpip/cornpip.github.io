# frozen_string_literal: true

source "https://rubygems.org"

gem "jekyll-theme-chirpy", "~> 7.6"

gem "jekyll-polyglot"

# jekyll-paginate-v2: classic jekyll-paginate does not generate paged pages
# under Polyglot. v2 is dormant unless a page opts in via `pagination.enabled`,
# so the theme's classic `paginate:` path stays inert (no gem conflict).
gem "jekyll-paginate-v2"

gem "html-proofer", "~> 5.0", group: :test

platforms :windows, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "wdm", "~> 0.2.0", :platforms => [:windows]
