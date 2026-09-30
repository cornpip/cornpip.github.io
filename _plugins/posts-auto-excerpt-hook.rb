#!/usr/bin/env ruby
#
# Meta description for posts.
#
# jekyll-seo-tag uses page.description, then page.excerpt. Chirpy shows
# page.description under the post title, so this hook fills page.excerpt
# instead: the first body paragraph of MIN_LEN chars or more, cut at the
# last sentence end within MAX_LEN. Paragraphs that are mostly link text
# (related-post references) are skipped. With no usable paragraph, the
# title is used.
# A front matter `excerpt:` string wins.

module AutoExcerpt
  MIN_LEN = 20
  MAX_LEN = 160
  FENCE = /^(`{3,}|~{3,})[^\n]*\n.*?^\1[ \t]*$/m
  SKIP = /\A(#|!\[|>|\||<|[-*+]\s|\d+\.\s|\{[:%]|\$\$| {4}|\t)/
  LINK = /\[((?:[^\[\]]|\[[^\]]*\])*)\]\([^)]*\)/

  module_function

  def extract(markdown)
    body = markdown.gsub(FENCE, "").gsub(/<!--.*?-->/m, "")
    body.split(/\n[ \t]*\n/).each do |para|
      para = para.strip
      next if para.empty? || para.match?(SKIP)

      text = clean(para)
      bare = clean(para.gsub(LINK, "")).length
      next if bare < MIN_LEN || bare * 2 < text.length

      return cut(text)
    end
    nil
  end

  def clean(str)
    str.gsub(/!\[[^\]]*\]\([^)]*\)/, "")
       .gsub(LINK, '\1')
       .gsub(%r{<https?://[^>]*>}, "")
       .gsub(%r{</?[a-zA-Z][a-zA-Z0-9-]*(\s[^>]*)?/?>}, "")
       .gsub(/\{:[^}]*\}/, "")
       .gsub(/\\$/, "")
       .gsub(/\*\*|`/, "")
       .gsub(/(?<![\w*])\*(?=\S)(.+?)(?<=\S)\*(?![\w*])/, '\1')
       .gsub(/\\([\\`*_{}\[\]()#+\-.!|])/, '\1')
       .gsub(/\s+/, " ")
       .strip
  end

  def cut(text)
    return text if text.length <= MAX_LEN

    ends = []
    text.scan(/[.!?](?=\s|\z)/) { ends << Regexp.last_match.begin(0) }
    last = ends.select { |i| i < MAX_LEN && i + 1 >= MIN_LEN }.max
    return text[0..last] if last

    head = text[0, MAX_LEN - 1]
    head = head[0, head.rindex(" ")] if head.rindex(" ")
    "#{head.rstrip}…"
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.posts.docs.each do |post|
    next if post.data["excerpt"].is_a?(String)

    post.data["excerpt"] = AutoExcerpt.extract(post.content.to_s) || post.data["title"].to_s
  end
end
