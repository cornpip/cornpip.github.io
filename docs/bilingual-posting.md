# 이중언어(한/영) 포스팅 가이드

> 이 문서는 `_config.yml`의 `exclude`에 `docs`가 포함돼 있어 **사이트에 배포되지 않는 내부 메모**입니다.

방법 1(글마다 한국어/영어 짝을 따로 작성)로 운영할 때의 규칙과 템플릿을 정리해 둡니다.

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
