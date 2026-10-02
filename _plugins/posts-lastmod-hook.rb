#!/usr/bin/env ruby
#
# Check for changed posts
#
# Commits whose message contains "[skip lastmod]" are skipped, so bulk edits
# that do not change post content keep last_modified_at. See docs/commit.md.

Jekyll::Hooks.register :posts, :post_init do |post|

  commit_dates = `git log -F --invert-grep --grep="[skip lastmod]" --pretty="%ad" --date=iso -- "#{ post.path }"`.lines

  if commit_dates.size > 1
    lastmod_date = commit_dates.first.strip
    post.data['last_modified_at'] = lastmod_date
  end

end
