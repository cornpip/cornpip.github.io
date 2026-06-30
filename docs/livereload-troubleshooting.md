# LiveReload / 자동 반영 안 됨 트러블슈팅

> 이 문서는 `_config.yml`의 `exclude`에 `docs`가 포함돼 있어 **사이트에 배포되지 않는 내부 메모**입니다.

`bundle exec jekyll serve --livereload`로 띄워도 글을 고치고 저장했을 때 자동 반영이 안 되거나, 서버를 껐다 켜야만 반영되던 문제에 대한 정리.

---

## 1. 증상

- 글/레이아웃을 저장해도 화면이 그대로다.
- 서버를 재시작해야만 변경이 보인다.
- (폴링을 켜면 반영은 되지만) 한 글만 고쳐도 50초씩 걸린다.

---

## 2. 원인 — 소스가 Windows에 있고 Docker로 bind mount됨

현재 구조:

```
Windows D:\...\cornpip.github.io   (실제 소스, NTFS)
        │  ← Docker(devcontainer)가 컨테이너로 bind mount
        ▼
컨테이너 /workspaces/cornpip.github.io
```

- `--livereload`(밑단 `listen` gem)는 OS의 **inotify 이벤트**로 변경을 감지한다.
- 그런데 **Windows 호스트 → Docker bind mount 경계로는 inotify 이벤트가 전달되지 않는다.**
  → watcher가 변경을 영영 못 잡음 → 자동 반영·자동 새로고침 안 됨.
- 빌드가 느린 것(54초)도 같은 원인: `_site`에 파일 수백 개를 쓰는 작업이 전부
  NTFS↔Docker(9p/drvfs) 경계를 넘어가서 I/O가 느림. `--incremental`은 *렌더링*만
  줄일 뿐 이 파일쓰기 오버헤드는 못 줄여서 여전히 느리다.

> Jekyll/Docker 버그가 아니라 **"Windows 소스를 bind mount" 한 환경의 한계**다.
> 관련 이슈: jekyll/jekyll-watch#17, docker/for-win#12766, #8479.

---

## 3. 두 옵션의 역할 구분 (헷갈리기 쉬움)

| 옵션 | 하는 일 | 없으면 |
|---|---|---|
| `--force_polling` | 이벤트 대신 **약 1초마다 폴링**해서 변경 감지 → 재빌드 | 반영 자체가 안 됨 |
| `--livereload` | 재빌드 후 **브라우저 자동 새로고침** | F5 직접 누르면 됨 |

- 실제로 글을 다시 빌드해주는 건 `--force_polling`. 폴링 간격(~1초)은 `listen` 기본값이고
  Jekyll에서 바꾸는 플래그/설정은 없다.
- `--livereload`의 자동 새로고침은 **35729 포트(LiveReload 웹소켓)** 가 컨테이너에서
  포워딩돼 있어야 동작한다. → `.devcontainer/devcontainer.json`에 추가해 둠:
  ```json
  "forwardPorts": [4000, 35729]
  ```
  (이 줄 추가 후에는 컨테이너 Rebuild 필요)

---

## 4. 해결책

### A. 당장 쓰는 명령 (소스 안 옮김)

```bash
bundle exec jekyll serve --livereload --force_polling --incremental
```

- 폴링으로 감지 + 브라우저 자동 새로고침(포트 포워딩 돼 있으면).
- 단점: 빌드가 느려서(50초+) 저장 후 한참 기다려야 반영됨.

미리보기만 빠르게 하고 싶으면 빌드 대상 글 수를 줄인다(최신 글만):

```bash
bundle exec jekyll serve --livereload --force_polling --incremental --limit_posts 5
```

- 최신 5개만 빌드 → 출력 파일이 확 줄어 빌드가 몇 초로 단축.
- 배포 빌드는 GitHub Actions가 전체로 하므로 영향 없음.

### B. 근본 해결 — 소스를 ext4로 이동 (권장)

소스를 Windows NTFS가 아니라 **Linux 네이티브 FS(ext4)** 에 두면:
- inotify 정상 동작 → `--livereload`만으로 즉시 자동 반영 (`--force_polling` 불필요)
- 빌드도 수 초로 빨라짐

두 가지 방법:

1. **컨테이너 볼륨에 클론** — VS Code 명령 팔레트(F1):
   `Dev Containers: Clone Repository in Container Volume...`
   → 소스가 Docker named volume(ext4)에 들어감.

   ⚠️ **중요: 이건 원격에서 새로 `git clone` 하는 것**이다. 지금 Windows 작업 폴더를
   옮기는 게 아니라, **push된 내용만** 새 볼륨에 들어간다. 그리고 보통 **기본 브랜치(main)**
   를 클론하므로, 작업 브랜치(`t1` 등)와 미커밋 변경은 따라오지 않는다.

   **① 옮기기 전 — 현재 작업을 먼저 커밋·push (Windows 폴더에서):**
   ```bash
   git add -A
   git commit -m "WIP before moving to container volume"
   git push origin t1          # 현재 작업 브랜치
   ```

   **② 볼륨 클론 후 — 컨테이너 안에서 브랜치 체크아웃 + 서브모듈 + 의존성:**
   ```bash
   git checkout t1                          # 작업 브랜치로 전환 (기본은 main 클론됨)
   git submodule update --init --recursive  # assets/lib 서브모듈 받아오기
   bundle install                           # Gemfile 의존성 설치
   ```

   이후 `bundle exec jekyll serve --livereload`만으로 즉시 자동 반영된다
   (`--force_polling` 불필요).

2. **WSL 홈(`~`)에 클론** 후 거기서 컨테이너 열기:
   ```bash
   # (먼저 현재 작업을 push 해두기 — 위 1번 ①과 동일)
   git clone https://github.com/cornpip/cornpip.github.io.git ~/cornpip.github.io
   cd ~/cornpip.github.io
   git checkout t1                          # 작업 브랜치
   git submodule update --init --recursive  # assets/lib 서브모듈
   bundle install
   code .                                   # 이후 Reopen in Container
   ```
   bind mount지만 출처가 WSL ext4라 inotify 동작.

> inotify가 안 되는 것·빌드가 느린 것·자동 새로고침이 안 되는 것 모두 같은 원인이라,
> B로 옮기면 셋 다 한 번에 해결된다.

---

## 5. 빠른 점검

- 저장 후 **서버 터미널**에 `Regenerating: ... done in Xs` 줄이 뜨는가?
  - 뜸 → 감지는 됨. X(빌드시간)가 곧 대기시간. → 느리면 `--limit_posts` 또는 B.
  - 안 뜸 → 폴링조차 변경을 못 잡음. → B(ext4 이동)가 사실상 유일한 해법.
- 브라우저가 자동 새로고침까지 되는가?
  - 안 됨 → 35729 포트 포워딩 확인(VS Code PORTS 탭) + 컨테이너 Rebuild.

---

## 6. 참고: `_config.yml` 수정은 항상 재시작

`_config.yml`은 watch 대상이 아니라서 폴링/이동과 무관하게 **수정 시 서버 재시작 필요**.
그 외 `_posts`, `_layouts`, `_includes`, `assets` 등은 위 방법으로 자동 반영된다.
