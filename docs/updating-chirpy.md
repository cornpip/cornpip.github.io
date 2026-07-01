# Chirpy 테마 업데이트 가이드

> 이 문서는 `_config.yml`의 `exclude`에 `docs`가 포함돼 있어 **사이트에 배포되지 않는 내부 메모**입니다.

이 블로그는 **gem 방식(chirpy-starter)** 입니다. 테마 코드가 레포에 복사돼 있는 게 아니라
`Gemfile`에 gem으로 선언돼 있으므로, 업데이트는 `git pull`이 아니라 **bundler**로 합니다.

```ruby
# Gemfile
gem "jekyll-theme-chirpy", "~> 7.6"   # "7.6 이상, 8.0 미만"
```

---

## 0. 사전 준비 (최초 1회)

로컬에 루비/번들러가 없으면 먼저 설치해야 합니다.

```bash
sudo apt update && sudo apt install -y ruby-full build-essential
gem install bundler
bundle install        # Gemfile의 gem들 설치
```

---

## 1. 마이너 업데이트 (가장 흔함, 7.x 내 최신)

`~> 7.6` 제약 안에서 최신으로 올립니다. `Gemfile` 수정 불필요.

```bash
bundle update jekyll-theme-chirpy   # Gemfile.lock 갱신
bundle exec jekyll serve            # localhost:4000 에서 확인 (Ctrl+C 종료)
```

이상 없으면 배포:

```bash
git add Gemfile.lock
git commit -m "Update Chirpy"
git push                            # GitHub Actions가 자동 빌드·배포
```

---

## 2. 메이저 업데이트 (예: 7.x → 8.x)

호환성 깨지는 변경(breaking change) 가능성이 있으므로 **릴리스 노트 먼저 확인**:
https://github.com/cotes2020/jekyll-theme-chirpy/releases

```ruby
# Gemfile 직접 수정
gem "jekyll-theme-chirpy", "~> 8.0"
```

```bash
bundle update jekyll-theme-chirpy
bundle exec jekyll serve            # 깨진 부분 점검
```

---

## 3. gem이 자동으로 안 바꿔주는 것

테마 본체(레이아웃·include·로직)는 gem 업데이트로 자동 반영됩니다.
하지만 **레포에 직접 들어있는 파일**은 gem이 못 건드리므로, 큰 업데이트 때 수동 비교가 필요할 수 있습니다.

| 대상                                      | 자동 업데이트 | 메이저 업데이트 시 할 일        |
| ----------------------------------------- | ------------- | ------------------------------- |
| 테마 레이아웃/include/플러그인 (gem 내부) | ✅             | 없음                            |
| `_config.yml` (새 옵션 추가 시)           | ❌             | starter와 비교해 새 키 반영     |
| `.github/workflows/*.yml`                 | ❌             | starter와 비교해 갱신           |
| `assets/lib` 서브모듈(정적 에셋)          | ❌             | `git submodule update --remote` |

비교 기준: https://github.com/cotes2020/chirpy-starter 의 같은 파일.

---

## 4. 우리 커스터마이징은 업데이트에 안전함

아래는 gem을 복사한 게 아니라 **공식 hook/플러그인 방식**이라 `bundle update` 후에도 유지됩니다.

| 파일                                    | 역할                                    | 안전한 이유                                    |
| --------------------------------------- | --------------------------------------- | ---------------------------------------------- |
| `_includes/metadata-hook.html`          | hreflang + **언어 스위처 JS 주입**      | Chirpy 공식 hook 오버라이드(빈 파일 대체)      |
| `_plugins/license-override-hook.rb`     | 라이선스 CC BY-NC 4.0로 패치            | locale 키만 메모리에서 덮어씀(파일 복사 X)     |
| `_plugins/polyglot-search-path-hook.rb` | Polyglot 언어별 검색 인덱스 경로 교정   | 렌더 결과 문자열만 메모리에서 치환(파일 복사 X) |
| `_config.yml` (polyglot/paginate-v2)    | 다국어 + 페이지네이션 설정              | 내 설정 파일                                    |

> locale 전체를 복사하지 않은 이유: Jekyll은 데이터 파일을 deep-merge하지 않고 통째로 대체하므로,
> 복사하면 이후 테마가 추가하는 번역 키를 못 받아 깨집니다. 그래서 플러그인으로 필요한 키만 패치.

### 4-1. 다국어(Polyglot) 관련 업데이트 주의점

Polyglot도 **gem 파일을 하나도 복사(shadow)하지 않아** `bundle update`에 안전합니다.
다만 아래 두 가지는 Chirpy 내부 구조에 의존하므로, 메이저 업데이트 후 확인하세요. (가이드: [bilingual-posting.md](bilingual-posting.md))

- **검색 경로 커플링**: `polyglot-search-path-hook.rb`가 `/assets/js/data/search.json` 문자열에 의존.
  Chirpy가 검색 인덱스 경로를 바꾸면 플러그인이 **조용히 no-op**(검색이 루트 인덱스로 폴백, 빌드는 안 깨짐). 이때 플러그인의 경로 상수만 갱신.
- **페이지네이션**: classic `paginate:`는 Polyglot에서 `/page/N/`을 안 만들어 `jekyll-paginate-v2`로 대체함.
  Chirpy가 홈(`home.html`)의 `paginator` 사용법을 크게 바꾸면 페이저 확인 필요(현재는 v2가 호환).
- **금지**: `exclude_from_localization`에 `assets/js/data`를 넣으면 언어별 `search.json`이 사라져 검색이 깨짐.

---

## 5. 전체 흐름 요약

```
(최초 1회) 루비·번들러 설치 → bundle install
   │
   ▼
bundle update jekyll-theme-chirpy   # 업데이트
bundle exec jekyll serve            # 로컬 확인 (Ctrl+C 종료)
   │
   ▼
git add Gemfile.lock && commit && push   # 실제 배포
```

## 6. 문제 생기면 (롤백)

`bundle update` 후 사이트가 깨졌을 때:

```bash
git checkout Gemfile.lock           # 아직 커밋 전이면 lock 되돌리기
bundle install                      # 이전 버전으로 복구
```

이미 커밋했다면 해당 커밋을 `git revert` 한 뒤 push.