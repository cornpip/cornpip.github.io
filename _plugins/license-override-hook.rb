#!/usr/bin/env ruby
#
# Override the post/footer license to CC BY-NC 4.0 (저작자표시-비영리).
#
# Why a plugin instead of copying _data/locales/*.yml?
#   Jekyll replaces a data file entirely (no deep-merge), so a full locale
#   copy would freeze every other translation key. This hook patches ONLY
#   copyright.license in memory at build time; all other locale strings keep
#   coming from the theme gem, so theme updates flow through untouched.
#
# To revert to the theme default (CC BY 4.0), just delete this file.

LICENSE_NAME = "CC BY-NC 4.0"
LICENSE_LINK = "https://creativecommons.org/licenses/by-nc/4.0/"

# Localized tooltip text (footer copyright.verbose). Only languages listed
# here get a rewritten sentence; others keep the gem's verbose text but still
# get the correct license name/link below.
VERBOSE = {
  "ko-KR" => "이 사이트의 블로그 게시물은 별도 명시가 없는 한 " \
             "Creative Commons 저작자표시-비영리 4.0 국제 라이선스(CC BY-NC 4.0)를 따릅니다."
}

Jekyll::Hooks.register :site, :post_read do |site|
  locales = site.data["locales"]
  next unless locales.is_a?(Hash)

  locales.each do |lang, data|
    copyright = data && data["copyright"]
    next unless copyright.is_a?(Hash)

    license = copyright["license"]
    if license.is_a?(Hash)
      license["name"] = LICENSE_NAME
      license["link"] = LICENSE_LINK
    end

    copyright["verbose"] = VERBOSE[lang] if VERBOSE.key?(lang)
  end
end
