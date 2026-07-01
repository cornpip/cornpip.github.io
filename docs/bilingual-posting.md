# 이중언어(한/영) 포스팅 가이드 — jekyll-polyglot

> 이 문서는 `_config.yml`의 `exclude`에 `docs`가 포함돼 있어 **사이트에 배포되지 않는 내부 메모**입니다.

이 블로그는 **jekyll-polyglot**으로 전역 언어 전환을 합니다.
사이트를 언어마다 **한 번씩 통째로 빌드**해서, 한국어는 루트(`/`), 영어는 `/en/` 아래에 둡니다.

- **기본 언어**: `ko-KR` (루트 `/`)
- **영어**: `/en/` 하위 트리
- 영어판이 **있는 글**은 영어로, **없는 글**은 한국어 원문 그대로(폴백) `/en/`에도 나옵니다.
- 우상단 검색창 옆 **언어 스위처(`한국어 / English`)** 로 전환합니다.

## 핵심 원칙: gem 파일을 하나도 안 건드림 (shadow 0)

모든 커스터마이징이 **내 파일(설정·플러그인·hook)** 로만 돼 있어, `bundle update jekyll-theme-chirpy` 시 **conflict도, 조용히 깨지는 shadow 파일도 없습니다.** (자세한 근거는 [updating-chirpy.md](updating-chirpy.md) 4장)

---

## 1. 구성 요소 (이미 세팅됨 — 참고용)

| 파일 | 역할 | shadow? |
|---|---|---|
| `Gemfile` | `jekyll-polyglot`, `jekyll-paginate-v2` 선언 | 내 파일 |
| `_config.yml` | 언어 설정 + paginate-v2 설정 | 내 파일 |
| `_plugins/polyglot-search-path-hook.rb` | 언어별 검색 인덱스 경로로 교정(메모리 패치) | ❌ (추가 파일) |
| `_includes/metadata-hook.html` | hreflang + **언어 스위처 JS 주입** | ❌ (공식 hook) |
| `index.html` | 홈 paginate-v2 opt-in | 내 파일 |

### `_config.yml` 핵심 라인
```yaml
plugins:
  - jekyll-polyglot
  - jekyll-paginate-v2

languages: ["ko-KR", "en"]
default_lang: "ko-KR"
lang_vars: ["lang"]          # Chirpy의 site.lang이 활성 언어를 따라감 → 테마 UI 자동 번역
parallel_localization: false
exclude_from_localization: ["assets/js/dist", "assets/css", "assets/img", "assets/lib", "assets/fonts"]

pagination:                  # classic paginate는 Polyglot에서 페이지 생성이 안 돼 v2로 대체
  enabled: true
  per_page: 10
  permalink: "/page/:num/"
  sort_reverse: true
  sort_field: "date"
```

---

## 2. 글 한 개만 쓸 때 (한국어 전용 — 대부분의 글)

특별히 할 것 없습니다. 그냥 평소대로 `_posts/`에 씁니다.

```markdown
---
title: 제목
date: 2026-06-29 12:00:00 +0900
categories: [Blog]
tags: [example]
---

본문(한국어)...
```

- `lang` 생략 시 사이트 기본 `ko-KR`로 처리됩니다.
- 이 글은 루트 `/posts/...`에 나오고, **`/en/`에도 한국어 원문 그대로(폴백)** 나옵니다.
  영어 독자가 언어 스위처로 en 모드에 있어도, 번역 없는 글은 원문을 보게 됩니다. (의도된 동작)

---

## 3. 한/영 짝으로 쓸 때

**규칙: 두 파일이 같은 `permalink`를 갖고, `lang`만 다르게 한다.**
Polyglot이 en 파일을 자동으로 `/en/` 아래에 깔아줍니다.

### 한국어 — `_posts/2026-07-01-167.md`
```markdown
---
title: "..."
date: 2026-07-01 00:00:00 +0900
permalink: /posts/167/
lang: ko-KR
alt_lang: en
alt_url: /en/posts/167/
categories: [Log, Notes]
render_with_liquid: false
---

본문(한국어)...
```

### 영어 — `_posts/2026-07-01-167-en.md`
```markdown
---
title: "..."
date: 2026-07-01 00:00:00 +0900
permalink: /posts/167/          # ← 한국어판과 동일! Polyglot이 /en/posts/167/ 로 출력
lang: en
alt_lang: ko-KR
alt_url: /posts/167/
categories: [Log, Notes]
render_with_liquid: false
---

Body (English)...
```

- `permalink`을 **똑같이** 두는 게 핵심 (파일명은 달라도 됨, 예: `-167.md` / `-167-en.md`).
  Polyglot은 언어별로 빌드를 분리하므로 permalink이 같아도 충돌하지 않습니다.
- `alt_lang`/`alt_url`은 **hreflang용**(SEO). 서로를 정확히 가리켜야 합니다.
- 언어 스위처는 URL의 `/en/` 접두어만 갈아끼우므로, permalink이 같으면 글 간 전환이 정확히 맞물립니다.
- **본문 안 수동 언어 링크(🇺🇸/🇰🇷)는 넣지 않습니다** — topbar 언어 스위처가 그 역할을 하므로 중복입니다.

---

## 4. 언어 스위처 동작

`metadata-hook.html`의 JS가 topbar에 `<select>`를 주입합니다 (gem 미수정).

- 현재 경로가 `/en/...`이면 en, 아니면 ko로 인식
- 전환 시 `/en/` 접두어를 붙이거나 떼서 **같은 페이지의 다른 언어판**으로 이동
- Polyglot이 사이트 전체를 언어별로 미러링하므로, 어떤 페이지(홈·글·아카이브)에서도 대응 페이지가 존재 → 항상 이동 성공

### 전환 안내 toast
**기본 언어(ko)가 아닌 언어(en)로 전환하면**, 위치와 관계없이(홈·글·목록) select 바로 아래에
`Untranslated posts show the original.` toast가 ~3.5초 떴다 사라집니다.

- 트리거: select로 **비-기본 언어로 바꾼 직후 한 번**(`sessionStorage` 플래그). 한국어(기본)로 돌아갈 땐 안 뜸.
- 목적: "영어판 없는 글은 원문으로 보여준다"는 **폴백 정책을 안내**. 그래서 번역본·홈에서 떠도 문구가 틀리지 않음.
- 위치: `#lang-switcher`의 위치를 기준으로 그 아래에 표시. 전부 JS(`metadata-hook.html`)라 **shadow 0**.
- 문구/스타일: `metadata-hook.html`의 `messages` / `#lang-toast` CSS에서 조정.

---

## 5. ⚠️ 주의점 (반드시 지킬 것)

1. **`exclude_from_localization`에 `assets/js/data`를 넣지 말 것.**
   넣으면 언어별 `search.json`이 생성 안 돼 **검색이 깨집니다(404).** 무거운 정적 폴더(`assets/css/img/lib/fonts`, `assets/js/dist`)만 제외.

2. **페이지네이션은 반드시 `jekyll-paginate-v2`.**
   Chirpy 기본 `paginate:`(classic)는 Polyglot에서 **페이저 UI는 뜨는데 `/page/N/`을 안 만들어** 404가 됩니다. `paginate:` 키를 쓰지 말고 `pagination:`(v2)만 사용. 홈은 `index.html` front matter에 `pagination: {enabled: true}` 필요.

3. **짝 글은 `permalink`을 동일하게.** (3장) 다르면 스위처가 대응 페이지를 못 찾음.

4. **빌드 시간 ≈ 언어 수 배.** 언어마다 전체 빌드라 2개 언어면 대략 2배(현재 ~40초). 정상입니다.

5. **검색 경로 플러그인은 문자열 하나에 의존.**
   `_plugins/polyglot-search-path-hook.rb`가 `/assets/js/data/search.json` 문자열을 교정합니다. 훗날 Chirpy가 이 경로를 바꾸면 플러그인이 **조용히 no-op**(검색이 기본 인덱스로 폴백, 빌드는 안 깨짐) → soft failure. 그때 플러그인의 경로 상수만 갱신.

6. **`assets/css`가 `/en/`에도 중복 생성**되지만 죽은 바이트일 뿐 무해(en 페이지는 루트 CSS를 참조). 필요 없으면 무시.

---

## 6. 체크리스트 (짝 글 발행 시)

- [ ] 한/영 두 `.md`의 `permalink`이 **동일**한가
- [ ] 영어판에 `lang: en`, 한국어판에 `lang: ko-KR`
- [ ] `alt_lang`/`alt_url`이 서로를 정확히 가리키는가 (hreflang)
- [ ] 빌드 후: 루트에 ko, `/en/`에 영어 본문이 뜨는가
- [ ] 빌드 후: 각 페이지 소스에 `rel="alternate"` 2줄, en 페이지가 `/en/assets/js/data/search.json`을 참조하는가

---

## 7. 로컬 확인

```bash
bundle exec jekyll serve            # http://127.0.0.1:4000 (ko) / :4000/en/ (en)
```
> `--incremental`은 목록/페이지네이션 갱신을 놓칠 수 있으니 노출 검증 땐 빼세요.
```

---

## 부록: 왜 이렇게 갔나 (히스토리)

- 처음엔 영어판을 `_en/` 컬렉션 + `/en/` 탭으로 두는 "방법 B"를 검토했으나, **전역 UI 언어 전환**이 안 돼 Polyglot으로 전환.
- Polyglot이 Chirpy와 **shadow 0**으로 붙는지 별도 실험으로 검증함 (검색은 `_plugins/*.rb`로, 페이지네이션은 paginate-v2로 해결). 결과: **gem 파일 미복사, git conflict 없음.**
