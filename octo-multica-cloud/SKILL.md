---
name: "octo-multica-cloud"
description: "Call cloud multica (multica.imocto.cn) from octo via user-configured octo-multica-key secret. Generic/portable; onboarding guide + runtime discovery."
status: stable
version: "1.0.0"
---

# octo-multica-cloud

Call the **cloud-hosted multica SaaS** at `https://multica.imocto.cn` from inside octo/OpenClaw,
using a per-user API key. This skill is **generic**: any user only needs to configure their own
`octo-multica-key` secret — no account-specific ids are baked in; everything is discovered at runtime.

> Base URL default: `https://multica.imocto.cn`. If a different multica host is used, override
> `MULTICA_CLOUD_BASE` accordingly.

## 📦 First-run onboarding (run this when the user installs the skill or first asks to use it)
On install, or the first time the user invokes anything in this skill, the agent MUST verify the
key is configured and, if not, walk the user through setup before doing anything else.

**Onboarding flow the agent runs:**
1. Try to read the key (materialize via secret) and call `GET /api/me`.
2. If it succeeds (200) → greet with the identity + list reachable workspaces (`/api/workspaces`),
   so the user immediately sees what they can drive. Skill is ready.
3. If it fails (no secret / 401) → send the user the **setup guide** below and STOP until configured.

**Setup guide to send the user (verbatim-friendly):**
```
要用这个 skill 调用 multica.imocto.cn，需要先配置你自己的 API 密钥：
1. 打开 https://multica.imocto.cn → 登录 → Settings / 设置 → API Keys
2. 新建一个 API Key，复制出来的 mul_… 字符串
3. 在 Octo 里打开「设置 → 密钥（Secrets）」模块，自己新增一条密钥：
   别名填 octo-multica-key，把刚才复制的 Key 粘进去保存。
   ⚠️ 千万别把 Key 发到聊天里（哪怕是发给我）——只要打到会话里就等于泄露。请务必在密钥模块里自己添加。
配好后跟我说一声「已经存好了」，我验证一下就能用了。
```
After the user says it's configured, re-run step 1 to confirm (200 from `/api/me`), then show the
reachable workspaces. 🔴 NEVER ask the user to paste/send the API key into any chat message
(not even a DM to you) — putting it in a conversation = leaking it. The key must be added by the
user themselves in Octo's Settings → Secrets module; you only ever READ it from the secret store
via `octo_management write-secret` (alias resolution), never receive it through chat.

## Setup (per user, one time) — what "configured" means
The user stores their personal multica API token under the secret alias **`octo-multica-key`**
(a `mul_…` token from the multica web app → Settings → API keys), **adding it themselves via
Octo → Settings → Secrets**. Nothing else to configure. 🔴 The agent must never receive the raw
key through chat — only read it from the secret store. If `/api/me` returns
`401 missing authorization`, the key is missing/invalid → re-run onboarding.

## When to use
- User asks to call / drive / read from `multica.imocto.cn` (the cloud multica web app).
- Managing whatever workspace(s) their key can reach, and dispatching to that workspace's agents.

## The key — never hardcode it; use the helper
`octo-multica-key` is a user-managed stored secret (alias), not a file on disk.
Materialize it to a **unique temp file**, use it, and guarantee cleanup with a `trap` so the
plaintext key can never be left on disk even if a call fails midway.

Step 1 — materialize the secret (run once per session, before the helper):
```
# octo_management write-secret writes the current plaintext to a fresh temp path.
# Use a unique filename (mktemp) so concurrent sessions never clobber each other.
octo_management write-secret alias="octo-multica-key" filePath=".secrets/.mc-key.<rand>" template="{{secret}}"
```
When calling the octo_management tool, pick a random suffix for `<rand>` (e.g. a timestamp +
random) so two parallel runs don't share a file.

Step 2 — load it with guaranteed cleanup, then define the `mc` helper:
```bash
# point at the temp file written in step 1
MC_KEYFILE=".secrets/.mc-key.<rand>"
MC_KEY=$(cat "$MC_KEYFILE")
# wipe the on-disk copy immediately; keep the value only in this shell's memory
shred -u "$MC_KEYFILE" 2>/dev/null || rm -f "$MC_KEYFILE"
# belt-and-suspenders: scrub the var when the shell exits
trap 'unset MC_KEY' EXIT

MC_BASE=${MULTICA_CLOUD_BASE:-https://multica.imocto.cn}
MC_WS=""   # set to a workspace id OR slug after discovery; leave empty for /api/me etc.

# mc <METHOD> <path> [json-body]
# - auto-injects auth + base URL
# - auto-appends the workspace selector when MC_WS is set and the path has no '?'
#   (uses workspace_id for a UUID, workspace_slug otherwise)
mc() {
  local method="$1" path="$2" body="${3:-}"
  local url="$MC_BASE$path"
  if [ -n "$MC_WS" ] && [[ "$path" != *\?* ]]; then
    if [[ "$MC_WS" =~ ^[0-9a-fA-F-]{36}$ ]]; then
      url="$url?workspace_id=$MC_WS"
    else
      url="$url?workspace_slug=$MC_WS"
    fi
  fi
  if [ -n "$body" ]; then
    curl -fsS -m 30 -X "$method" -H "Authorization: Bearer $MC_KEY" \
         -H "Content-Type: application/json" "$url" -d "$body"
  else
    curl -fsS -m 30 -X "$method" -H "Authorization: Bearer $MC_KEY" "$url"
  fi
}
```
Never echo `$MC_KEY`, never paste the key into octo messages, never commit it.

### Error handling
- `401 missing authorization` → key missing/invalid → re-run onboarding (have the user reconfigure
  `octo-multica-key`).
- `400 workspace_id or workspace_slug is required` → set `MC_WS` (or add `?workspace_id=`) first.
- `429` → back off and retry with exponential delay; respect any `Retry-After`.
- `5xx` → transient; retry once or twice, then report the failure with the status code.
- `curl` exits non-zero (with `-fsS`) on HTTP errors → surface the message, don't silently continue.

### Enum values (issue status / priority)
- `status`: `backlog` | `todo` (default) | `in_progress` | `in_review` | `done` | `cancelled`
- `priority`: `none` | `low` | `medium` | `high` | `urgent`

## Auth & request shape
- Base URL: `https://multica.imocto.cn` (override via `MULTICA_CLOUD_BASE`).
- Header: `Authorization: Bearer <octo-multica-key>`
- Workspace selection (one of):
  - query param `?workspace_id=<uuid>` or `?workspace_slug=<slug>`
  - header `X-Workspace-ID: <uuid>`
- List endpoints REQUIRE a workspace (else `400 workspace_id or workspace_slug is required`).

## Discovery first (do this before any workspace-scoped call)
Never assume ids. Resolve them from the user's own account each session (uses the `mc` helper above):

```bash
# 1. confirm identity / key validity (no workspace needed)
mc GET /api/me

# 2. list the workspaces THIS key can reach -> pick id/slug
mc GET /api/workspaces

# 3. lock in the chosen workspace, then list its agents -> pick assignee_id
MC_WS=<chosen-workspace-id-or-slug>
mc GET /api/agents          # MC_WS auto-appended as ?workspace_id=
```

If the user has multiple workspaces, ask which one (or use the slug they named).

## Endpoint reference
Full endpoint list, request/response shapes, and worked examples live in
[`references/api.md`](references/api.md). Quick summary:

**Read:** `/api/me`, `/api/workspaces`, `/api/agents`, `/api/squads`, `/api/issues` (+ `/search`, `/<id>`,
`/<id>/comments`, `/<id>/task-runs`, `/<id>/pull-requests`, `/<id>/subscribers`),
`/api/projects`, `/api/runtimes` (+ `/<id>/usage`, `/<id>/activity`),
`/api/webhook-subscriptions` (+ `/<id>/deliveries`), `/health`.

**Write (use deliberately):** `POST /api/issues`, `PUT /api/issues/<id>`,
`POST /api/issues/<id>/comments`, `POST /api/issues/<id>/rerun`,
`POST /api/tasks/<taskId>/messages`, `POST /api/tasks/<taskId>/cancel`,
`DELETE /api/comments/<id>`,
`POST /api/webhook-subscriptions` (+ `PATCH`/`DELETE /<id>`, `POST /<id>/test`,
`POST /<id>/deliveries/<deliveryId>/redeliver`).

**Create agent / squad (verified live via REST 2026-06-25):**
`POST /api/agents` (needs `name` + `runtime_id`), `POST /api/agents/<id>/archive`,
`PUT /api/agents/<id>`; `POST /api/squads` (needs `name` + `leader_id`),
`DELETE /api/squads/<id>`. So agent/squad creation **is** possible via IM/REST, not just Web.

**Runtime management:** `GET /api/runtimes` (list), `GET /api/runtimes/<id>/usage`,
`GET /api/runtimes/<id>/activity`, `POST /api/runtimes/<id>/update` (upgrade the runtime CLI
to a target version), `POST /api/runtimes/<id>/archive-agents-and-delete` (archive its agents
and remove the runtime). ⚠️ The last one is destructive — confirm before running.

**Outbound webhooks (verified live via REST 2026-06-25):** Multica POSTs events to YOUR URL.
Workspace-level or project-level scoped. `GET /api/webhook-subscriptions` (list; add
`&project_id=<id>` to filter), `POST /api/webhook-subscriptions` (create — needs `url` + `events`;
add `project_id` to scope to one project), `PATCH /api/webhook-subscriptions/<id>`,
`DELETE /api/webhook-subscriptions/<id>`, `POST /api/webhook-subscriptions/<id>/test`,
`GET /api/webhook-subscriptions/<id>/deliveries` (+ `/<deliveryId>`),
`POST /api/webhook-subscriptions/<id>/deliveries/<deliveryId>/redeliver`.
Supported events: `issue.status_changed` (only one for now). The signing `secret` (`whsec_…`) is
returned **once on create** and never again (list/get only give `secret_hint` = last 4 chars) —
capture it then. Multica signs each POST `X-Multica-Signature-256: sha256=<hex(HMAC-SHA256(body,secret))>`
(+ `X-Multica-Event`, `X-Multica-Delivery` headers). See [`references/api.md`](references/api.md#outbound-webhook-subscriptions) for full shapes.

## Examples
```bash
K=$(cat .secrets/.tmp-mc-key)
B=${MULTICA_CLOUD_BASE:-https://multica.imocto.cn}
WS=<workspace-id-from-discovery>

# list issues
curl -s -H "Authorization: Bearer $K" "$B/api/issues?workspace_id=$WS"
## Examples (with the `mc` helper)
```bash
MC_WS=<workspace-id-or-slug-from-discovery>

# list issues
mc GET /api/issues

# create an issue assigned to an agent (agent id from /api/agents)
mc POST /api/issues \
  '{"title":"...","description":"...","priority":"high","assignee_type":"agent","assignee_id":"<agent-id>"}'

# add a comment (path has its own segments; MC_WS still auto-appended)
mc POST "/api/issues/<issue-id>/comments" '{"body":"..."}'

# update an issue's status
mc PUT "/api/issues/<issue-id>" '{"status":"in_progress"}'
```

## Using the `multica` CLI (optional — only for the execution plane)
This skill's primary path is **REST** (the `mc` helper above). REST is the full *control plane*
and is a **superset** of what the CLI exposes for driving the cloud (outbound webhooks, squad
management, agent/runtime create are REST-only). So for control-plane work — create/assign issues,
manage webhooks/squads/agents — **always use REST, never the CLI.**

The CLI is worth reaching for in exactly one case: the **execution plane**, i.e. the local
`daemon` that registers *this machine* as a runtime and actually executes assigned agent tasks.
REST cannot do that; only the CLI daemon can.

### Decision: REST or CLI?
- Want to drive cloud Multica (issues, webhooks, squads, agents)? → **REST** (`mc` helper).
- Want to turn the current machine into an agent-executing runtime? → **CLI `daemon`** (below).

### 🔴 Hard rule: always use an isolated `--profile`
The CLI stores auth + daemon state per profile. A machine may already have a **default profile
pointing at a different (e.g. self-hosted) server** — using it would talk to the wrong server and
clobber that config. The `--profile` flag fully isolates config, daemon state, and workspaces
(verified: a `--profile` login leaves the default `~/.multica/config.json` byte-for-byte
unchanged). So **every** CLI call for this skill MUST pass a dedicated `--profile` (e.g.
`octocloud`) and `--server-url https://multica.imocto.cn`.

### Setup (one time, isolated profile)
The `octo-multica-key` works as the CLI login token (it is a `mul_…` user PAT). Materialize the
secret as usual, then pass it via `--token="$MC_KEY"` (value comes from the shell var, not typed
as a literal, so it does not land in shell history). Do NOT use `--token=-` (the CLI has no stdin
mode; it reads `-` literally).
```bash
# MC_KEY already materialized + wiped-from-disk per "The key" section above
multica --profile octocloud --server-url https://multica.imocto.cn login --token="$MC_KEY"
multica --profile octocloud workspace list            # verify: lists cloud workspaces
```

### Start the runtime daemon (the actual CLI-only capability)
```bash
multica --profile octocloud workspace switch <id-or-slug>   # pick the workspace to serve
multica --profile octocloud daemon start                    # registers this machine as a runtime
multica --profile octocloud daemon status
multica --profile octocloud daemon logs -f
```
The daemon is a long-running process. **Do not start it on the user's behalf without their
explicit ask** — it consumes the machine and runs assigned tasks. Surface the commands and let
the user decide.

### CLI notes
- The CLI requires its own install (`brew install multica-ai/tap/multica` or the install script);
  if `command -v multica` is empty, only the REST path is available — that's fine, REST covers all
  control-plane needs.
- To remove the isolated profile later: `multica --profile octocloud auth logout` then
  `rm -rf ~/.multica/profiles/octocloud`.
- Never run CLI commands for this skill against the **default** profile.

## Safety / risk notes
- ✅ Control plane is curl-only and isolated from any local self-hosted multica daemon: different
  host, account, token, and code path; the REST path never reads/writes `~/.multica/config.json`.
  The optional CLI path (above) is for the execution-plane daemon only and MUST use an isolated
  `--profile` so it never touches the default profile.
- ⚠️ A multica API key is typically **account-scoped** — it may reach ALL of that user's
  workspaces and has **write** power (create/update issues, run agents). Confirm the target
  workspace before any write; don't write to the wrong workspace.
- Always materialize→use→wipe the key in one bounded flow. Never leave it on disk, never log it,
  never put it in an octo message or commit.
- Each user supplies their OWN `octo-multica-key`; the skill is portable and stores no ids of its own.
