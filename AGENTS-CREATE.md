# AGENT 추가 하기
최신 OpenClaw에서는 **에이전트를 추가하는 가장 쉬운 방법이 `openclaw agents add`** 입니다. 
공식 문서도 멀티 에이전트 Quick Start에서 새 에이전트 생성은 `openclaw agents add work` 같은 식으로 안내하고, 각 에이전트는 별도 workspace와 `~/.openclaw/agents/<agentId>` 아래의 전용 상태 디렉터리를 갖는다고 설명합니다. ([OpenClaw][1])


---

# 1. 현재 에이전트 목록 확인

먼저 지금 등록된 에이전트를 봅니다.

```bash
cd ~/openclaw-docker
docker compose run --rm openclaw-cli agents list
```

공식 CLI 문서에 `openclaw agents list`가 있습니다. ([OpenClaw][2])

---

# 2. 새 에이전트 추가

예를 들어 `work` 에이전트를 추가하려면:

```bash
cd ~/openclaw-docker
docker compose run --rm openclaw-cli agents add work
```

또는 workspace를 직접 지정하려면:

```bash
docker compose run --rm openclaw-cli agents add work --workspace ~/.openclaw/workspace-work
```

공식 문서 예시도 거의 이 형태입니다. `openclaw agents add work --workspace ~/.openclaw/workspace-work` 를 바로 보여 줍니다. ([OpenClaw][2])

이 명령을 실행하면 보통 다음이 생깁니다.

* 새 agent id
* 새 workspace
* 전용 agentDir / session store

공식 문서상 각 에이전트는 `SOUL.md`, `AGENTS.md`, 필요 시 `USER.md`를 포함하는 고유 workspace를 갖습니다. ([OpenClaw][1])

---

# 3. 추가된 에이전트 확인

```bash
docker compose run --rm openclaw-cli agents list
```

바인딩까지 같이 보고 싶으면:

```bash
docker compose run --rm openclaw-cli agents list --bindings
```

이것도 공식 문서에 있는 확인 방법입니다. ([OpenClaw][1])

---

# 4. 기본 에이전트가 아닌 “추가 에이전트”로 두기

보통 `main`은 기본 에이전트로 두고, `work`, `family`, `coding` 같은 식으로 추가합니다. 공식 보안 문서도 이런 패턴을 예시로 설명합니다. 예를 들어 personal/full access, family/read-only, public/no filesystem/shell tools 같은 식으로 에이전트별 정책을 다르게 둘 수 있습니다. ([OpenClaw][3])

예시 구조는 이런 느낌입니다.

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "workspace": "~/.openclaw/workspace",
        "sandbox": { "mode": "off" }
      },
      {
        "id": "work",
        "workspace": "~/.openclaw/workspace-work",
        "sandbox": { "mode": "off" }
      }
    ]
  }
}
```

에이전트별 `sandbox`와 `tools`를 따로 둘 수 있다는 점은 공식 multi-agent 문서에 나옵니다. ([OpenClaw][3])

---

# 5. 수동으로 `openclaw.json`에 직접 추가하는 방법

CLI 대신 직접 파일을 고쳐도 됩니다.

`~/.openclaw/openclaw.json` 예시:

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
      },
      {
        "id": "work",
        "name": "Work Agent",
        "workspace": "~/.openclaw/workspace-work",
        "sandbox": {
          "mode": "off"
        }
      },
      {
        "id": "coding",
        "name": "Coding Agent",
        "workspace": "~/.openclaw/workspace-coding",
        "sandbox": {
          "mode": "off"
        }
      }
    ]
  }
}
```

그리고 workspace도 미리 만듭니다.

```bash
mkdir -p ~/.openclaw/workspace-work
mkdir -p ~/.openclaw/workspace-coding
```

OpenClaw는 각 agent에 대해 별도 workspace를 쓰는 구조이고, workspace는 파일 도구와 컨텍스트의 기본 작업 디렉터리입니다. ([OpenClaw][4])

---

# 6. 에이전트별 권한을 다르게 주는 방법

이게 멀티 에이전트의 핵심입니다.

예를 들어:

* `main` = 전체 권한
* `family` = 읽기 전용
* `public` = 거의 제한

공식 문서 예시를 따라 쓰면 이런 식입니다. ([OpenClaw][3])

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "workspace": "~/.openclaw/workspace",
        "sandbox": { "mode": "off" }
      },
      {
        "id": "family",
        "workspace": "~/.openclaw/workspace-family",
        "sandbox": {
          "mode": "all",
          "scope": "agent",
          "workspaceAccess": "ro"
        },
        "tools": {
          "allow": ["read"],
          "deny": ["write", "edit", "apply_patch", "exec", "process", "browser"]
        }
      }
    ]
  }
}
```

즉, “에이전트를 추가한다”는 건 단순히 이름만 늘리는 게 아니라, **각 agent를 독립 persona + 독립 workspace + 독립 보안 정책**으로 운영하는 개념입니다. ([OpenClaw][3])

---

# 7. 채널별로 특정 에이전트에 연결하는 방법

나중에 텔레그램/디스코드/왓츠앱 같은 채널을 붙이면, 특정 채널 계정을 특정 에이전트에 묶을 수 있습니다.

예:

```bash
docker compose run --rm openclaw-cli agents bind --agent work --bind telegram:ops
docker compose run --rm openclaw-cli agents bind --agent main --bind discord:default
```

공식 CLI 문서에서 `agents bind`, `agents unbind`, `agents bindings`를 지원합니다. ([OpenClaw][2])

지금은 로컬 dashboard만 쓰고 있어도, 나중에 채널을 붙일 때 이 구조가 그대로 확장됩니다.

---

# 7-1. 여러 텔레그램 채널 설정하기

하나의 OpenClaw 인스턴스에서 **여러 개의 텔레그램 봇**을 운영할 수 있습니다. 각 봇은 독자적인 botToken과 계정 설정을 가지며, 특정 에이전트에 연결됩니다.

## 구조 요약

여러 텔레그램 채널을 구성하려면 세 가지 섹션이 필요합니다:

1. **`agents.list`** - 각 봇에 연결될 에이전트
2. **`channels.telegram.accounts`** - 각 텔레그램 봇 계정 (botToken, allowFrom 등)
3. **`bindings`** - 에이전트와 텔레그램 계정 연결

## 전체 예시 (`openclaw.json`)

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "workspace": "~/.openclaw/workspace"
      },
      {
        "id": "news",
        "workspace": "~/.openclaw/agents/news"
      }
    ]
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "accounts": {
        "default": {
          "dmPolicy": "pairing",
          "botToken": "TOKEN_1",
          "allowFrom": [8254472361],
          "groupPolicy": "allowlist",
          "streaming": "partial"
        },
        "news": {
          "dmPolicy": "pairing",
          "botToken": "TOKEN_2",
          "allowFrom": [8254472361],
          "groupPolicy": "allowlist",
          "streaming": "partial"
        }
      }
    }
  },
  "bindings": [
    {
      "agentId": "main",
      "match": {
        "channel": "telegram",
        "accountId": "default"
      }
    },
    {
      "agentId": "news",
      "match": {
        "channel": "telegram",
        "accountId": "news"
      }
    }
  ]
}
```

## 설정 설명

| 섹션 | 설명 |
|------|------|
| `agents.list` | 각 봇이 사용할 에이전트 (`main`, `news`) |
| `channels.telegram.accounts.default` | 첫 번째 텔레그램 봇 (TOKEN_1) |
| `channels.telegram.accounts.news` | 두 번째 텔레그램 봇 (TOKEN_2) |
| `bindings` | `main` → `default` 봇, `news` → `news` 봇 연결 |

## 텔레그램 BotToken 얻기

1. [@BotFather](https://t.me/BotFather) 대화 시작
2. `/newbot` 명령으로 새 봇 생성
3. 생성된 봇의 토큰 복사
4. 필요한 만큼 봇 생성 (각각 다른 토큰)

## 설정 순서

```bash
# 1. 에이전트 추가
docker compose run --rm openclaw-cli agents add news --workspace ~/.openclaw/agents/news

# 2. workspace 생성
mkdir -p ~/.openclaw/agents/news

# 3. openclaw.json 편집 (위 예시 참고)
nano ~/.openclaw/openclaw.json

# 4. gateway 재시작
docker compose restart openclaw-gateway
```

## 더 많은 채널 추가하기

세 번째, 네 번째 텔레그램 채널을 추가하려면:

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "accounts": {
        "default": { "botToken": "TOKEN_1", ... },
        "news": { "botToken": "TOKEN_2", ... },
        "alerts": { "botToken": "TOKEN_3", ... },
        "support": { "botToken": "TOKEN_4", ... }
      }
    }
  },
  "bindings": [
    { "agentId": "main", "match": { "channel": "telegram", "accountId": "default" } },
    { "agentId": "news", "match": { "channel": "telegram", "accountId": "news" } },
    { "agentId": "alerts", "match": { "channel": "telegram", "accountId": "alerts" } },
    { "agentId": "support", "match": { "channel": "telegram", "accountId": "support" } }
  ]
}
```

---

# 8. 가장 추천하는 실제 추가 순서

당장 가장 무난한 방법은 이 순서입니다.

```bash
cd ~/openclaw-docker
docker compose run --rm openclaw-cli agents list
docker compose run --rm openclaw-cli agents add work --workspace ~/.openclaw/workspace-work
docker compose run --rm openclaw-cli agents add coding --workspace ~/.openclaw/workspace-coding
docker compose run --rm openclaw-cli agents list
```

그 다음 gateway 재시작:

```bash
docker compose restart openclaw-gateway
```

그리고 dashboard 새로고침.

멀티 에이전트 문서도 추가 후 `gateway restart`와 `agents list --bindings`로 검증하는 흐름을 보여 줍니다. ([OpenClaw][1])

---

# 9. 당신 환경 기준 추천 예시

지금처럼 권한을 넓게 쓰는 개인 환경이라면 우선 이렇게 시작하는 게 좋습니다.

* `main` : 일상/관리용
* `coding` : 코드 작업용
* `work` : 업무용

예시:

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "workspace": "~/.openclaw/workspace",
        "sandbox": { "mode": "off" }
      },
      {
        "id": "coding",
        "workspace": "~/.openclaw/workspace-coding",
        "sandbox": { "mode": "off" }
      },
      {
        "id": "work",
        "workspace": "~/.openclaw/workspace-work",
        "sandbox": { "mode": "off" }
      }
    ]
  }
}
```

나중에 필요하면 `work`만 read-only 또는 sandboxed로 바꾸면 됩니다. 공식 문서도 이런 per-agent override를 권장합니다. ([OpenClaw][3])

---

# 10. 바로 실행할 명령

지금 바로는 이 두 줄부터 해보시면 됩니다.

```bash
cd ~/openclaw-docker
docker compose run --rm openclaw-cli agents add work --workspace ~/.openclaw/workspace-work
docker compose run --rm openclaw-cli agents add coding --workspace ~/.openclaw/workspace-coding
```

그리고:

```bash
docker compose run --rm openclaw-cli agents list
docker compose restart openclaw-gateway
```

원하시면 다음 답변에서 제가 **당신의 현재 `openclaw.json` 기준으로 `main + work + coding` 3개 에이전트가 들어간 최종 JSON**을 바로 만들어 드리겠습니다.

[1]: https://docs.openclaw.ai/concepts/multi-agent?utm_source=chatgpt.com "Multi-Agent Routing"
[2]: https://docs.openclaw.ai/cli/agents?utm_source=chatgpt.com "agents - OpenClaw Docs"
[3]: https://docs.openclaw.ai/tools/multi-agent-sandbox-tools?utm_source=chatgpt.com "Multi-Agent Sandbox & Tools"
[4]: https://docs.openclaw.ai/concepts/agent?utm_source=chatgpt.com "Agent Runtime - OpenClaw Docs"
