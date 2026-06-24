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
3. 在 octo 里把它存成密钥，别名必须叫 `octo-multica-key`
   （直接把密钥发给我并说“存为 octo-multica-key”，我不会回显明文）
配好后跟我说一声，我验证一下就能用了。
```
After the user says it's configured, re-run step 1 to confirm (200 from `/api/me`), then show the
reachable workspaces. Never ask the user to paste the key into a normal chat message in plaintext
beyond the secret-store flow; the secret tooling keeps the value out of the transcript.

## Setup (per user, one time) — what "configured" means
The user stores their personal multica API token under the secret alias **`octo-multica-key`**
(a `mul_…` token from the multica web app → Settings → API keys). Nothing else to configure.
If `/api/me` returns `401 missing authorization`, the key is missing/invalid → re-run onboarding.

## When to use
- User asks to call / drive / read from `multica.imocto.cn` (the cloud multica web app).
- Managing whatever workspace(s) their key can reach, and dispatching to that workspace's agents.

## The key — never hardcode it
`octo-multica-key` is a user-managed stored secret (alias), not a file on disk.
Materialize it on demand with the octo_management `write-secret` action, use it, then wipe it:

```
# 1. write secret to a temp file (plaintext never returned to the agent)
octo_management write-secret alias="octo-multica-key" filePath=".secrets/.tmp-mc-key" template="{{secret}}"
# 2. use it
K=$(cat .secrets/.tmp-mc-key)
# ... curl calls ...
# 3. wipe it
shred -u .secrets/.tmp-mc-key 2>/dev/null || rm -f .secrets/.tmp-mc-key
```

Never echo the full key, never paste it into octo messages, never commit it.

## Auth & request shape
- Base URL: `https://multica.imocto.cn` (override via `MULTICA_CLOUD_BASE`).
- Header: `Authorization: Bearer <octo-multica-key>`
- Workspace selection (one of):
  - query param `?workspace_id=<uuid>` or `?workspace_slug=<slug>`
  - header `X-Workspace-ID: <uuid>`
- List endpoints REQUIRE a workspace (else `400 workspace_id or workspace_slug is required`).

## Discovery first (do this before any workspace-scoped call)
Never assume ids. Resolve them from the user's own account each session:

```bash
K=$(cat .secrets/.tmp-mc-key)
B=${MULTICA_CLOUD_BASE:-https://multica.imocto.cn}

# 1. confirm identity / key validity
curl -s -H "Authorization: Bearer $K" "$B/api/me"

# 2. list the workspaces THIS key can reach -> pick id/slug
curl -s -H "Authorization: Bearer $K" "$B/api/workspaces"

# 3. with the chosen workspace, list its agents -> pick assignee_id
WS=<chosen-workspace-id>
curl -s -H "Authorization: Bearer $K" "$B/api/agents?workspace_id=$WS"
```

If the user has multiple workspaces, ask which one (or use the slug they named).

## Endpoint reference
Full endpoint list, request/response shapes, and worked examples live in
[`references/api.md`](references/api.md). Quick summary:

**Read:** `/api/me`, `/api/workspaces`, `/api/agents`, `/api/issues` (+ `/search`, `/<id>`,
`/<id>/comments`, `/<id>/task-runs`, `/<id>/pull-requests`, `/<id>/subscribers`),
`/api/projects`, `/api/runtimes`, `/health`.

**Write (use deliberately):** `POST /api/issues`, `PUT /api/issues/<id>`,
`POST /api/issues/<id>/comments`, `POST /api/issues/<id>/rerun`,
`POST /api/tasks/<taskId>/messages`, `POST /api/tasks/<taskId>/cancel`,
`DELETE /api/comments/<id>`.

## Examples
```bash
K=$(cat .secrets/.tmp-mc-key)
B=${MULTICA_CLOUD_BASE:-https://multica.imocto.cn}
WS=<workspace-id-from-discovery>

# list issues
curl -s -H "Authorization: Bearer $K" "$B/api/issues?workspace_id=$WS"

# create an issue assigned to an agent (agent id from /api/agents)
curl -s -H "Authorization: Bearer $K" -H "Content-Type: application/json" \
  "$B/api/issues?workspace_id=$WS" \
  -d '{"title":"...","description":"...","assignee_type":"agent","assignee_id":"<agent-id>"}'

# add a comment
curl -s -H "Authorization: Bearer $K" -H "Content-Type: application/json" \
  "$B/api/issues/<issue-id>/comments" -d '{"body":"..."}'
```

## Safety / risk notes
- ✅ Isolated from any local self-hosted multica daemon: different host, account, token, and code
  path (curl-only, no CLI, never reads/writes `~/.multica/config.json`).
- ⚠️ A multica API key is typically **account-scoped** — it may reach ALL of that user's
  workspaces and has **write** power (create/update issues, run agents). Confirm the target
  workspace before any write; don't write to the wrong workspace.
- Always materialize→use→wipe the key in one bounded flow. Never leave it on disk, never log it,
  never put it in an octo message or commit.
- Each user supplies their OWN `octo-multica-key`; the skill is portable and stores no ids of its own.
