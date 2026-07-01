# 이중언어(한/영) 포스팅 가이드

> 이 문서는 `_config.yml`의 `exclude`에 `docs`가 포함돼 있어 **사이트에 배포되지 않는 내부 메모**입니다.

글마다 한국어/영어 짝을 따로 작성하는 방식의 규칙과 템플릿을 정리해 둡니다.
영어판 파일을 **어디에 두느냐**로 두 가지가 있는데, 노출 범위가 다릅니다.

| | 영어판 위치 | 홈·아카이브·피드·검색 | override |
|---|---|---|---|
| **A. 둘 다 포스트** | `_posts/...-en.md` | 영어판도 **노출됨** (홈에 한/영 중복) | 없음 |
| **B. 영어판은 페이지** (권장) | `_posts/` **밖** (예: `en/167.md`) | 영어판 **제외** (홈엔 한국어만) | 없음 |

- 둘 다 `_config.yml`·gem을 안 건드리므로 **테마 업데이트에 안전**하다. 차이는 "영어판을 목록에 노출할지"뿐.
- **현재 이 사이트는 B**로 운영한다 (예: 글 167 → 영어판 `en/167.md`). 자세한 규칙은 아래 6번.

---

## 1. 큰 그림

| 층 | 위치 | 형식 | 작성 빈도 |
|---|---|---|---|
| 글 내용 + 언어 설정 | `_posts/*.md` 본문 + front matter | Markdown + YAML | 글마다 |
| 사이트 기본값(`lang`, `timezone`) | `_config.yml` | YAML | 거의 안 건드림 |
| hreflang HTML 출력 | `_includes/metadata-hook.html` | Liquid/HTML | **이미 세팅됨** |

- 사이트 기본 UI 언어: `lang: ko-KR`
- 시간대: `timezone: Asia/Seoul`
- hreflang 주입은 `_includes/metadata-hook.html`이 자동 처리 (테마 업데이트 안전).

---

## 2. 글 한 개만 쓸 때 (짝 없음 — 대부분의 글)

특별히 할 것 없음. 한국어 글이면 `lang`도 생략 가능(사이트 기본 `ko-KR` 따라감).

```markdown
---
title: 제목
date: 2026-06-29 12:00:00 +0900
categories: [Blog]
tags: [example]
---

본문...
```

- `<html lang="ko-KR">`이 자동 적용 → 검색엔진이 언어를 정확히 인식.
- hreflang은 출력되지 않음(짝이 없으므로 올바른 동작).

---

## 3. 한국어/영어 짝으로 쓸 때

핵심 규칙: **두 글이 서로를 가리켜야 한다(상호 참조).** 한쪽만 적으면 Google이 무시함.

### 한국어 글 — `_posts/2026-06-29-my-post-ko.md`
```markdown
---
title: 내 글 (한국어)
date: 2026-06-29 12:00:00 +0900
lang: ko-KR
alt_lang: en
alt_url: /posts/my-post-en/
categories: [Blog]
---

[🇺🇸 English](/posts/my-post-en/)

본문(한국어)...
```

### 영어 글 — `_posts/2026-06-29-my-post-en.md`
```markdown
---
title: My Post (English)
date: 2026-06-29 12:00:00 +0900
lang: en
alt_lang: ko-KR
alt_url: /posts/my-post-ko/
categories: [Blog]
---

[🇰🇷 한국어](/posts/my-post-ko/)

Body (English)...
```

생성되는 `<head>` (각 글):
```html
<link rel="alternate" hreflang="ko-KR" href="https://cornpip.github.io/posts/my-post-ko/">
<link rel="alternate" hreflang="en"    href="https://cornpip.github.io/posts/my-post-en/">
```

---

## 4. front matter 키 의미

| 키 | 의미 | 비고 |
|---|---|---|
| `lang` | 이 글의 언어 → `<html lang>` | 생략 시 사이트 기본 `ko-KR` |
| `alt_lang` | 짝 글의 언어 | hreflang 출력에 필요 |
| `alt_url` | 짝 글의 경로 | 이 키가 있어야 hreflang 출력됨 |

- `alt_lang`, `alt_url`은 Chirpy 기본 키가 아니라 **이 프로젝트에서 정의한 커스텀 변수**.
  이름을 바꾸려면 `_includes/metadata-hook.html`의 변수명도 같이 바꿔야 함.
- URL 경로는 permalink 규칙(`_config.yml`의 `permalink: /posts/:title/`)을 따름.
  보통 `/posts/<파일명에서 날짜 뺀 부분>/` 형태.

---

## 5. 체크리스트 (짝 글 발행 시)

- [ ] 두 `.md` 모두에 `lang`, `alt_lang`, `alt_url` 작성했는가
- [ ] 두 글의 `alt_url`이 **서로**를 정확히 가리키는가
- [ ] 본문 상단에 상대 언어로 가는 수동 링크를 넣었는가
- [ ] 빌드 후 각 페이지 소스에서 `rel="alternate"` 2줄이 보이는가

---

## 6. 방법 B — 영어판을 "페이지"로 (홈/목록에서 제외, 권장)

한국어 글은 그대로 `_posts/`에 두고, **영어판만 `_posts/` 밖에 페이지로** 둔다.
그러면 영어판이 `site.posts`에 안 들어가므로 **홈·아카이브·피드·검색에서 자동 제외**되고,
홈 피드에 한/영이 중복으로 뜨는 문제가 사라진다. URL·hreflang은 그대로 유효하다.

### 한국어 글 — `_posts/2026-07-01-167.md` (그대로 포스트)
```markdown
---
title: "..."
date: 2026-07-01 00:00:00 +0900
permalink: /posts/167/
lang: ko-KR
alt_lang: en
alt_url: /posts/167-en/
categories: [Log, Notes]
---

[🇺🇸 English](/posts/167-en/)

본문(한국어)...
```

### 영어판 — `en/167.md` (`_posts/` 밖 페이지)
```markdown
---
title: "..."
layout: post          # _posts 밖이라 기본 layout이 안 붙으니 명시
permalink: /posts/167-en/
toc: true             # posts 기본값이 안 오므로 직접 켬
comments: true        # posts 기본값이 안 오므로 직접 켬
render_with_liquid: false
date: 2026-07-01 00:00:00 +0900
categories: [Log, Notes]
lang: en
alt_lang: ko-KR
alt_url: /posts/167/
---

[🇰🇷 한국어](/posts/167/)

Body (English)...
```

### 방법 B의 특성

- **홈/아카이브/피드/검색**: 영어판 안 나옴 (의도된 동작).
- **카테고리/태그 목록 페이지**: 영어판 안 잡힘 (`site.posts` 기반이라).
- **이전/다음 글 네비**: 영어판 하단에 안 뜸 (포스트 시퀀스 밖). 에러 아님, 그냥 없음.
- **TOC·댓글·외형**: `layout: post` + `toc`/`comments` 명시로 글과 동일하게 보임.
- **hreflang·sitemap**: metadata-hook이 페이지에도 동작 → 정상. sitemap에도 포함.

### 방법 B 체크리스트

- [ ] 영어판을 `_posts/`가 **아닌** 폴더(예: `en/`)에 두었는가
- [ ] 영어판 front matter에 `layout: post` + `permalink` + `toc`/`comments`를 넣었는가
- [ ] 한/영 `alt_url`이 서로를 정확히 가리키는가
- [ ] 두 글 상단에 상대 언어 수동 링크가 있는가
- [ ] 빌드 후 홈에 영어판이 **안 뜨는지**, 각 페이지 소스에 `rel="alternate"` 2줄이 보이는지

> 영어판을 검색·아카이브에도 정식으로 남기고 싶다면 방법 A(둘 다 포스트)를 쓴다.
> 홈 중복만 지우고 A의 노출은 유지하려면 `home.html` 등을 override해야 하는데,
> 그건 테마 업데이트마다 수동 재패치가 필요해 권장하지 않는다. (그래서 B가 기본)
