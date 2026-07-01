# kramdown 확장 문법 + Chirpy 클래스 가이드

> 이 문서는 `_config.yml`의 `exclude`에 `docs`가 포함돼 있어 **사이트에 배포되지 않는 내부 메모**입니다.

표준 마크다운에는 없지만 이 블로그에서 쓸 수 있는 문법 + 자주 헷갈리는 동작을 정리해 둔다.
(순수 마크다운 문법 — 제목/굵게/목록/표/링크 등 — 은 여기서 다루지 않는다.)

> **중요:** Chirpy 전용 *문법*은 없다. 여기 나오는 문법은 전부 **kramdown**(IAL `{: ... }`, 정의목록·약어·각주 등) 표준이다.
> Chirpy가 하는 일은 **문법이 아니라** CSS 클래스와 렌더링 동작을 제공하는 것뿐이다.
> 즉 `{: .prompt-tip }` 은 "kramdown IAL로 Chirpy가 스타일을 정의해 둔 클래스를 붙이는 것"이다. 섹션 제목의 `(Chirpy)` 표기는 *문법*이 아니라 *스타일/동작이 Chirpy 소속*이라는 뜻.

- 마크다운 엔진: **kramdown** (Jekyll 기본)
- 테마: **jekyll-theme-chirpy** 7.6.x
- 살아있는 예시 포스트: `_posts/2026-07-01-167.md`

## 클래스 출처 구분 (검증 결과)

IAL(`{: ... }`)로 붙이는 클래스는 출처가 세 가지로 갈린다. 아래는 이 블로그에서 실제로 쓰는 것 기준.

| 클래스 / 표기                                                   | 출처                        | 정의 위치                                                    | 역할              |
| --------------------------------------------------------------- | --------------------------- | ------------------------------------------------------------ | ----------------- |
| `.prompt-tip` `.prompt-info` `.prompt-warning` `.prompt-danger` | **Chirpy**                  | `_sass/themes/_light.scss`, `_dark.scss`                     | 콜아웃 박스       |
| `.left` `.right`                                                | **Chirpy**                  | `_sass/base/_base.scss`                                      | 이미지 float 정렬 |
| `.normal`                                                       | **Chirpy**                  | `_sass/base/_typography.scss` (자동 가운데정렬 opt-out 마커) | 이미지 왼쪽 정렬  |
| `.filepath`                                                     | **Chirpy**                  | `_sass/base/_syntax.scss`                                    | 파일 경로 스타일  |
| `.shadow`                                                       | **Bootstrap** (테마에 번들) | `_sass/vendors/_bootstrap.scss`                              | box-shadow 유틸   |
| `.text-center`                                                  | **Bootstrap** (테마에 번들) | `_sass/vendors/_bootstrap.scss`                              | 가운데 정렬 유틸  |
| `{: file="..." }` (속성)                                        | **Chirpy 동작**             | 코드블록 include가 속성을 읽어 파일명 바 렌더                | 클래스 아님       |
| 이미지 자동 가운데정렬·캡션·lazy-load                           | **Chirpy 동작**             | 이미지 후처리                                                | 클래스 아님       |

- **Chirpy 클래스**: `.prompt-*`, `.left`, `.right`, `.normal`, `.filepath`
- **Bootstrap 유틸**(Chirpy 전용 아님, 다른 Bootstrap 사이트에서도 동일): `.shadow`, `.text-center`
- **Chirpy 동작**(클래스가 아니라 렌더링 처리): `file="..."` 파일명 바, 이미지 자동 가운데정렬·캡션

> 확인법: `bundle show jekyll-theme-chirpy` 로 gem 경로를 찾아 `_sass/` 아래를 `grep` 하면 어느 클래스가 Chirpy 소속인지 바로 보인다. `.shadow`/`.text-center` 처럼 `_sass/vendors/_bootstrap.scss` 에만 있으면 Bootstrap 것.

---

## 1. IAL — 모든 확장의 뿌리

**IAL(Inline Attribute List)** = kramdown이 마크다운으로 만든 요소에 **클래스·id·속성을 덧붙이는** 기능. `{: ... }` 로 쓴다.

```text
안녕하세요
{: .text-center }
    ↓
<p class="text-center">안녕하세요</p>
```

`{: }` 안에 넣는 것:

| 표기       | 의미           | 결과             |
| ---------- | -------------- | ---------------- |
| `.클래스`  | CSS class 추가 | `class="클래스"` |
| `#아이디`  | id 지정        | `id="아이디"`    |
| `key="값"` | HTML 속성      | `key="값"`       |

### 위치 규칙 (중요)

- **블록 요소**(문단·제목·인용·이미지·코드블록 등)에 붙일 때 → **바로 다음 줄**에 둔다. 사이에 빈 줄이 있으면 안 된다.
- **인라인 요소**(인라인 코드 등)에 붙일 때 → **바로 뒤에** 붙인다.

```text
설정은 `_config.yml`{: .filepath } 에서 바꾼다.   ← 인라인: 바로 뒤

이 문단은 가운데 정렬.
{: .text-center }                                  ← 블록: 다음 줄
```

> Chirpy의 콜아웃 `{: .prompt-tip }`, 이미지 옵션 `{: .shadow }` 등은 **전부 IAL의 응용**이다.

---

## 2. Chirpy 콜아웃 (prompt)

인용구(`>`) **바로 다음 줄**에 `{: .prompt-* }` 를 붙인다.

```markdown
> 유용한 팁입니다.
{: .prompt-tip }
```

| 클래스            | 색상   | 용도      |
| ----------------- | ------ | --------- |
| `.prompt-tip`     | 초록 💡 | 팁        |
| `.prompt-info`    | 파랑 ℹ️ | 정보      |
| `.prompt-warning` | 노랑 ⚠️ | 경고      |
| `.prompt-danger`  | 빨강 ❗ | 위험/주의 |

---

## 3. 이미지 옵션 (정렬은 Chirpy, 그림자는 Bootstrap)

이미지 뒤에 IAL로 크기·정렬·그림자·캡션을 준다.

```markdown
![설명](/assets/img/x.png){: width="200" height="200" }   # 크기 (HTML 속성)
![설명](/assets/img/x.png){: .shadow }                     # 그림자 (Bootstrap 유틸)
![설명](/assets/img/x.png){: .left }                       # 왼쪽 정렬 float (Chirpy)
![설명](/assets/img/x.png){: .right }                      # 오른쪽 정렬 float (Chirpy)
![설명](/assets/img/x.png){: .normal }                     # 왼쪽 정렬, float 아님 (Chirpy)
```

캡션 — 이미지 **바로 아래 이탤릭 한 줄**:

```markdown
![사진](/assets/img/x.png)
_사진 캡션입니다._
```

### ⚠️ 정렬 클래스의 함정 (float 동작)

`.left` / `.right` 는 CSS **float** 라서 "정상 흐름에서 빠져" 뒤 내용이 이미지 옆으로 흐른다. `.normal` 은 float가 아니라 그냥 왼쪽 정렬이다. 이 차이 때문에 "텍스트를 이미지 **아래**로 내리는 방법"이 다르다:

| 클래스             | 방식                 | 아래로 내리려면                                               |
| ------------------ | -------------------- | ------------------------------------------------------------- |
| `.normal`          | 정상 흐름, 왼쪽 정렬 | **빈 줄**로 문단 분리하면 됨                                  |
| `.left` / `.right` | **float**            | 빈 줄로는 안 됨 → **`<div style="clear: both;"></div>`** 필요 |

- `.normal` 뒤 텍스트가 같은 문단(빈 줄 없음)이면, 텍스트가 이미지 **오른쪽 하단 옆**에 붙는다. 아래로 내리려면 빈 줄을 넣어 문단을 나눈다.
- `.left`/`.right` 는 빈 줄로 문단을 나눠도 새 문단이 **여전히 옆으로** 파고든다. float를 끊으려면 clear가 답:

```html
![왼쪽](/assets/img/x.png){: .left width="150" }
옆으로 흐르는 설명 텍스트...

<div style="clear: both;"></div>   <!-- 여기서 float 끊김 -->

다음 내용은 이미지 아래로 내려간다.
```

(`render_with_liquid: false` 인 글에서는 위 `<div>` 가 Liquid로 오해받지 않고 그대로 HTML로 렌더링된다.)

---

## 4. 코드 블록에 파일명 표시 (Chirpy)

코드 블록 **다음 줄**에 `{: file="..." }` → 코드블록 상단에 파일 경로 바가 뜬다.

````markdown
```python
print("hello")
```
{: file="src/main.py" }
````

---

## 5. 파일 경로 강조 (Chirpy)

인라인 코드에 `.filepath` → 파일 경로 스타일.

```markdown
설정은 `_config.yml`{: .filepath } 에서 바꾼다.
```

---

## 6. 정의 목록 (kramdown)

용어 아래 줄에 `: ` 로 정의를 붙인다. (`<dl>/<dt>/<dd>` 로 렌더링)

```markdown
kramdown
: 마크다운을 HTML로 변환하는 Jekyll 기본 엔진.

Chirpy
: 이 블로그가 쓰는 Jekyll 테마.
```

---

## 7. 약어 (kramdown)

문서 아무 곳에 `*[약어]: 뜻` 을 정의하면, 본문의 해당 단어에 `<abbr>` 툴팁이 붙는다.

```markdown
HTML 은 마크업 언어다.

*[HTML]: HyperText Markup Language
```

---

## 8. 각주 (kramdown)

```markdown
본문입니다.[^note]

[^note]: 페이지 하단에 표시되는 각주.
```
