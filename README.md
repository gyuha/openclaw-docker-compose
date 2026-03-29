
# 1. 목적

Mac + Docker 환경에서 최신 OpenClaw를 설치하고,

* Gateway 실행
* Dashboard 접속
* CLI 연결
* 마지막으로 브라우저 세션(Device/Session) 승인

까지 완료하는 흐름입니다.

---

# 2. 디렉터리 준비

먼저 설정 파일과 작업 디렉터리를 만듭니다.

```bash
mkdir -p ~/openclaw-docker
mkdir -p ~/.openclaw
mkdir -p ~/.openclaw/workspace
```

---

# 3. `docker-compose.yml` 작성

파일 위치:

```bash
~/openclaw-docker/docker-compose.yml
```

내용:

```yaml
services:
  openclaw-gateway:
    image: ghcr.io/openclaw/openclaw:latest
    container_name: openclaw-gateway
    environment:
      HOME: /home/node
      TERM: xterm-256color
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN}
      OPENCLAW_ALLOW_INSECURE_PRIVATE_WS: ${OPENCLAW_ALLOW_INSECURE_PRIVATE_WS:-}
    volumes:
      - ${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw
      - ${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace
    ports:
      - "${OPENCLAW_GATEWAY_PORT:-18789}:18789"
      - "${OPENCLAW_BRIDGE_PORT:-18790}:18790"
    init: true
    restart: unless-stopped
    command:
      [
        "node",
        "dist/index.js",
        "gateway",
        "--bind",
        "${OPENCLAW_GATEWAY_BIND:-lan}",
        "--port",
        "18789"
      ]

  openclaw-cli:
    image: ghcr.io/openclaw/openclaw:latest
    network_mode: "service:openclaw-gateway"
    environment:
      HOME: /home/node
      TERM: xterm-256color
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN}
      OPENCLAW_ALLOW_INSECURE_PRIVATE_WS: ${OPENCLAW_ALLOW_INSECURE_PRIVATE_WS:-}
      BROWSER: echo
    volumes:
      - ${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw
      - ${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace
    stdin_open: true
    tty: true
    init: true
    entrypoint: ["node", "dist/index.js"]
    depends_on:
      - openclaw-gateway
```

중요한 점:

* `gateway`는 계속 실행되는 서비스
* `cli`는 보통 **상시 실행용이 아니라 필요할 때 `task cli -- ARGS="..."` 또는 관련 `task` 명령으로 실행**

---

# 4. `.env` 작성

파일 위치:

```bash
~/openclaw-docker/.env
```

내용:

```env
OPENCLAW_GATEWAY_TOKEN=change-this-to-a-long-random-string
OPENCLAW_CONFIG_DIR=/Users/본인계정/.openclaw
OPENCLAW_WORKSPACE_DIR=/Users/본인계정/.openclaw/workspace
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_BRIDGE_PORT=18790
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_ALLOW_INSECURE_PRIVATE_WS=
```

여기서 `본인계정`은 Mac 사용자명으로 바꿉니다.

예:

```env
OPENCLAW_CONFIG_DIR=/Users/gyuha/.openclaw
OPENCLAW_WORKSPACE_DIR=/Users/gyuha/.openclaw/workspace
```

Mac 사용자명 확인:

```bash
whoami
```

---

# 5. `openclaw.json` 작성

파일 위치:

```bash
~/.openclaw/openclaw.json
```

최종 동작 기준 내용:

```json
{
  "tools": {
    "profile": "full",
    "deny": []
  },
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "port": 18789,
    "auth": {
      "mode": "token",
      "token": "change-this-to-a-long-random-string"
    },
    "remote": {
      "token": "change-this-to-a-long-random-string"
    },
    "controlUi": {
      "enabled": true,
      "allowedOrigins": [
        "http://127.0.0.1:18789",
        "http://localhost:18789"
      ]
    }
  },
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "name": "Main Agent",
        "workspace": "~/.openclaw/workspace",
        "sandbox": {
          "mode": "off"
        }
      }
    ]
  }
}
```

핵심 포인트:

* `tools.profile: "full"`
  가능한 도구를 최대한 넓게 사용

* `gateway.mode: "local"`
  최신 버전에서 이 값이 없으면 Gateway 시작이 막힘

* `gateway.bind: "lan"`
  Docker 호스트(Mac 브라우저)에서 대시보드 접속 가능하게 함

* `controlUi.allowedOrigins`
  `lan` 바인드일 때 반드시 명시

* `gateway.auth.token` 과 `gateway.remote.token` 값은 같아야 함

* `.env`의 `OPENCLAW_GATEWAY_TOKEN` 값도 같은 문자열로 맞추는 것이 안전

즉, 아래 3개 토큰 문자열은 **모두 동일**해야 합니다.

```text
gateway.auth.token
gateway.remote.token
OPENCLAW_GATEWAY_TOKEN
```

---

# 6. 처음 실행

이 저장소는 `Taskfile.yml`을 포함하고 있으므로 기본 운영 명령은 `docker compose` 직접 호출보다 `task` 사용을 기준으로 보면 됩니다.

먼저 사용 가능한 작업 목록을 확인:

```bash
task --list
```

Gateway 시작:

```bash
task up
```

상태와 로그 확인:

```bash
task ps
task logs
```

필요하면 로그 길이를 늘려서 볼 수 있습니다.

```bash
task logs -- TAIL=300
```

---

# 7. 실행 중에 만났던 오류들과 해결

## 오류 1

```text
Gateway start blocked: set gateway.mode=local
```

원인:

* `gateway.mode`가 설정되지 않음

해결:

```json
"gateway": {
  "mode": "local"
}
```

---

## 오류 2

```text
non-loopback Control UI requires gateway.controlUi.allowedOrigins
```

원인:

* `bind=lan` 상태에서 Control UI origin 허용 목록이 없음

해결:

```json
"controlUi": {
  "enabled": true,
  "allowedOrigins": [
    "http://127.0.0.1:18789",
    "http://localhost:18789"
  ]
}
```

---

## 오류 3

```text
gateway token mismatch
(set gateway.remote.token to match gateway.auth.token)
```

원인:

* CLI가 보내는 토큰과 Gateway가 기대하는 토큰이 다름

해결:
아래 3개를 같은 문자열로 통일

```text
gateway.auth.token
gateway.remote.token
OPENCLAW_GATEWAY_TOKEN
```

---

## 오류 4

```text
curl: (56) Recv failure: Connection reset by peer
```

원인:

* `bind=loopback`으로 해두면 Docker 호스트에서 published port 접근이 꼬일 수 있음

해결:

* `bind=lan`으로 변경
* `allowedOrigins` 추가

---

# 8. Dashboard 접속

브라우저에서 접속:

```text
http://127.0.0.1:18789/
```

또는

```text
http://localhost:18789/
```

대시보드가 뜨면 기본적으로 Gateway는 정상입니다.

---

# 9. CLI 사용 방법

`openclaw-cli` 컨테이너는 상시 실행 서비스가 아니라, 필요할 때 `task`로 일회성 명령을 실행하는 용도입니다.

자주 쓰는 명령:

```bash
task devices:list
task probe
task configure
```

임의의 CLI 명령을 직접 넘기고 싶다면:

```bash
task cli -- ARGS="devices list"
task cli -- ARGS="gateway probe"
```

즉, `task up` 이후에도 `openclaw-cli` 컨테이너가 계속 떠 있지 않아도 정상입니다.

## 10-1. 대화형 설정 (`configure`)

처음 설정하거나 설정을 수정할 때는 대화형 설정 도구를 사용할 수 있습니다.

```bash
task configure
```

이 명령을 실행하면 대화형 메뉴가 나오고, 다음을 포함한 다양한 설정을 수정할 수 있습니다.

* Gateway 설정 (bind, port 등)
* 인증 설정 (token 등)
* Control UI 설정
* Agent 설정

대화형 설정을 통해 `openclaw.json` 파일을 자동으로 수정할 수 있어 편리합니다.

---

# 10. Dashboard에서 `pairing required` 발생

대시보드에 접속했을 때 이런 메시지가 뜰 수 있습니다.

```text
pairing required
```

이 뜻은:

* 브라우저 세션 또는 디바이스가 아직 승인되지 않음
* 처음 접속하는 Control UI 브라우저는 1회 승인 필요

즉, 마지막 단계로 **세션(Device) 승인**을 해야 합니다.

---

# 11. Session / Device 승인 과정

## 11-1. 현재 대기 중인 pairing 요청 확인

```bash
task devices:list
```

여기서 pending 상태의 요청이 보입니다.

보통 다음 중 하나가 보입니다.

* pending device
* pending session
* request id

핵심은 **승인해야 할 요청 ID**를 찾는 것입니다.

---

## 11-2. 요청 승인

예를 들어 `requestId`가 `abc123`이라면:

```bash
task devices:approve -- REQUEST_ID=abc123
```

이렇게 승인합니다.

가장 최근 pending 요청을 바로 승인하고 다시 확인하려면:

```bash
task devices:approve:final
```

---

## 11-3. 다시 확인

```bash
task devices:list
```

pending이 사라졌는지 확인합니다.

---

## 11-4. Dashboard 새로고침

브라우저에서 다시 열거나 새로고침:

```text
http://127.0.0.1:18789/
```

이제 pairing required가 사라지고 정상적으로 붙어야 합니다.

---

# 12. 전체 순서만 짧게 다시 요약

## 1단계

디렉터리 생성

```bash
mkdir -p ~/openclaw-docker
mkdir -p ~/.openclaw
mkdir -p ~/.openclaw/workspace
```

## 2단계

`docker-compose.yml` 작성

## 3단계

`.env` 작성
여기서 `OPENCLAW_GATEWAY_BIND=lan`

## 4단계

`~/.openclaw/openclaw.json` 작성
반드시 포함:

```json
"mode": "local"
"bind": "lan"
"allowedOrigins": [...]
"auth.token": "동일토큰"
"remote.token": "동일토큰"
```

## 5단계

실행

```bash
task up
```

## 6단계

Dashboard 접속

```text
http://127.0.0.1:18789/
```

## 7단계

CLI 테스트

```bash
task devices:list
```

## 8단계

`pairing required`가 뜨면 pending 요청 확인

```bash
task devices:list
```

## 9단계

요청 승인

```bash
task devices:approve -- REQUEST_ID=<requestId>
```

## 10단계

브라우저 새로고침

---

# 13. 마지막에 바로 써먹는 명령만 따로 정리

이 섹션은 `Taskfile.yml` 기준의 실제 명령만 정리한 것입니다.

## 작업 목록 보기

```bash
task --list
```

## 시작

```bash
task up
```

## 중지

```bash
task down
```

## 재시작

```bash
task restart
```

## 업데이트

```bash
task pull
task update
```

`task pull`은 이미지만 내려받고, `task update`는 최신 이미지를 받은 뒤 컨테이너를 다시 생성합니다.

## 상태 확인

```bash
task ps
```

## 로그 확인

```bash
task logs
```

## 디바이스/세션 확인

```bash
task devices:list
```

## 디바이스/세션 승인

```bash
task devices:approve -- REQUEST_ID=<requestId>
```

## 최신 pending 요청 승인 후 재확인

```bash
task devices:approve:final
```

## Gateway probe

```bash
task probe
```

## 임의 CLI 명령 실행

```bash
task cli -- ARGS="devices list"
```

## Dashboard 접속

```text
http://127.0.0.1:18789/
```

## 관리자 계정으로 접근

컨테이너 내에서 root 권한으로 작업해야 할 경우:

```bash
task shell
```

root 권한 쉘이 필요하면:

```bash
task root-shell
```

이 명령을 사용하면 Gateway 컨테이너 내에서 bash 쉘에 접속할 수 있습니다.

## Python 설치

컨테이너 내에서 Python 설치가 필요할 경우:

```bash
docker compose exec -u root openclaw-gateway bash -c "apt update && apt install -y python3 python3-pip"
```

또는 컨테이너 접속 후 직접 실행:

```bash
apt update
apt install -y python3 python3-pip
```

### Python 3.11+ PEP 668 오류 해결

Python 3.11 이후 Debian/Ubuntu에서는 PEP 668 정책으로 인해 시스템 Python에 pip로 직접 설치하는 것이 막혀 있습니다.

오류 메시지:

```
error: externally-managed-environment
```

**해결 방법:**

`pip install` 명령에 `--break-system-packages` 옵션 추가:

```bash
pip3 install youtube-transcript-api --break-system-packages
```

또는

```bash
python3 -m pip install <패키지명> --break-system-packages
```

```bash
pip install <패키지명> --break-system-packages
```

Docker 컨테이너에서는 일반적으로 이 방법을 사용해도 안전합니다.
