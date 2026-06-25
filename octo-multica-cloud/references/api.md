# multica.imocto.cn — API reference

Base URL: `https://multica.imocto.cn` (override via `MULTICA_CLOUD_BASE`).
Auth header on every request: `Authorization: Bearer <octo-multica-key>`.

Workspace-scoped list endpoints require a workspace selector, supplied as either:
- query param `?workspace_id=<uuid>` or `?workspace_slug=<slug>`, or
- header `X-Workspace-ID: <uuid>`.

Without it they return `400 {"error":"workspace_id or workspace_slug is required"}`.
Missing/invalid key returns `401 {"error":"missing authorization"}`.

## Identity & discovery

### `GET /api/me`
Returns the authenticated account. Use it to validate the key.
```json
{"id":"<uuid>","name":"...","email":"...","onboarded_at":"...", "...":"..."}
```

### `GET /api/workspaces`
All workspaces the key can reach.
```json
[{"id":"<uuid>","name":"...","slug":"...","issue_prefix":"<PREFIX>","repos":[], "...":"..."}]
```

### `GET /api/agents?workspace_id=<ws>`
Agents in a workspace. Each item has `id`, `name`, `model`. Use `id` as `assignee_id`.
(Lists non-archived agents only.)

### `POST /api/agents?workspace_id=<ws>`  ✅ create agent (verified live 2026-06-25)
Creates an agent. Required: `name` + `runtime_id` (a runtime id from `/api/runtimes`).
Returns `201` with the new agent object. Optional fields: `description`, `instructions`,
`runtime_config`, `custom_args`, `mcp_config`, etc.
```json
{"name":"required","runtime_id":"<id from /api/runtimes>","description":"optional","instructions":"optional"}
```

### `POST /api/agents/<id>/archive?workspace_id=<ws>`
Archives an agent (removes it from the active `/api/agents` list). Returns `200`.
(There is no `DELETE /api/agents/<id>` — that returns 405; use archive.)

### `PUT /api/agents/<id>?workspace_id=<ws>`
Update agent fields (partial object).

## Squads (teams)

### `GET /api/squads?workspace_id=<ws>`
Lists non-archived squads. Each item has `id`, `name`, `leader_id`, `member_count`,
`member_preview`. (`/api/teams` does not exist — 404.)

### `POST /api/squads?workspace_id=<ws>`  ✅ create squad (verified live 2026-06-25)
Creates a squad. Required: `name` + `leader_id` (an agent id to act as squad leader).
Returns `201` with the new squad object.
```json
{"name":"required","leader_id":"<agent id>","description":"optional","instructions":"optional"}
```

### `DELETE /api/squads/<id>?workspace_id=<ws>`
Deletes a squad. Returns `204`.

> ⚠️ Earlier notes suggested (incorrectly) that agent/squad creation was Web/desktop-only. Live
> probing on 2026-06-25 confirmed both create endpoints exist and return 201 via REST API.

### `GET /api/runtimes?workspace_id=<ws>`
Online daemons/runtimes for the workspace (name, provider, runtime_mode, status, device_info).

### `GET /api/runtimes/<id>/usage?workspace_id=<ws>`
Token usage for a runtime.

### `GET /api/runtimes/<id>/activity?workspace_id=<ws>`
Hourly task activity for a runtime.

### `POST /api/runtimes/<id>/update?workspace_id=<ws>`
Initiate a CLI update on the runtime.
```json
{"target_version": "<version>"}
```
Returns an update record with `id` + `status`; poll `GET /api/runtimes/<id>/update/<updateId>`
for progress (status reaches completed/failed).

### `POST /api/runtimes/<id>/archive-agents-and-delete?workspace_id=<ws>`
⚠️ **Destructive.** Archives all agents bound to the runtime and deletes the runtime. Confirm
with the user before calling.

### Other runtime sub-endpoints (POST)
- `POST /api/runtimes/<id>/models` — query available models for the runtime.
- `POST /api/runtimes/<id>/local-skills` — import local skills from the runtime
  (poll `GET /api/runtimes/<id>/local-skills/import/<importId>` for status).

## Issues

### `GET /api/issues?workspace_id=<ws>`
Query params: `status`, `priority`, `assignee_id`, `project_id`, `metadata`, `limit`, `offset`.
Returns `{"issues":[...],"total":<n>}`.

### `GET /api/issues/search?...`
Search issues (query params).

### `GET /api/issues/<id>`
Single issue detail. `<id>` may be the UUID or the readable id (e.g. `<PREFIX>-123`).

### `GET /api/issues/<id>/comments`
### `GET /api/issues/<id>/task-runs`
### `GET /api/issues/<id>/pull-requests`
### `GET /api/issues/<id>/subscribers`

### `POST /api/issues`
Create an issue. Workspace via `?workspace_id=` or `X-Workspace-ID` header.
```json
{
  "title": "required",
  "description": "markdown (optional)",
  "status": "optional",
  "priority": "optional",
  "assignee_type": "agent | user",
  "assignee_id": "<id from /api/agents or a user id>",
  "parent_issue_id": "<id>",
  "project_id": "<id>",
  "start_date": "ISO-8601 (optional)",
  "due_date": "ISO-8601 (optional)",
  "allow_duplicate": false
}
```
`title` is the only required field. Assigning to an agent triggers that agent to start work.

**Enum values:**
- `status`: `backlog` | `todo` (default) | `in_progress` | `in_review` | `done` | `cancelled`
- `priority`: `none` | `low` | `medium` | `high` | `urgent`

### `PUT /api/issues/<id>`
Update fields (status / priority / assignee / etc.). Body is a partial issue object.

### `POST /api/issues/<id>/comments`
```json
{"body": "comment text (markdown)"}
```

### `POST /api/issues/<id>/rerun`
Re-run the agent task for an issue. Empty body `{}`.

### `DELETE /api/comments/<id>`
Delete a comment.

## Tasks

### `POST /api/tasks/<taskId>/messages`
Send a message into a running task (e.g. steer/answer the agent mid-run).

### `POST /api/tasks/<taskId>/cancel`
Cancel a running task. Updates the DB row to status=cancelled.

## Projects

### `GET /api/projects?workspace_id=<ws>`
Returns `{"projects":[...],"total":<n>}`.

## Outbound webhook subscriptions

Multica POSTs events to **your** HTTP endpoint when something happens (currently issue status
changes). Subscriptions are scoped to a workspace, or narrowed to a single project. All endpoints
are workspace-scoped (need `?workspace_id=` / `X-Workspace-ID`). Verified live via REST 2026-06-25
(create→test→deliveries→delete round-trip on `multica.imocto.cn`).

> Don't confuse this with **inbound** autopilot webhooks (`/api/webhooks/autopilots/<token>` +
> `/api/autopilots/.../triggers`), which is the opposite direction (external event → Multica run).
> This section is OUTBOUND only: Multica → your URL.

### `GET /api/webhook-subscriptions?workspace_id=<ws>`
Lists subscriptions. Add `&project_id=<id>` to filter to one project's subscriptions.
Returns `{"subscriptions":[...]}`. The signing secret is **never** echoed here — each item carries
`secret_hint` (last 4 chars) only.
```json
{"subscriptions":[{
  "id":"<uuid>","workspace_id":"<uuid>","project_id":null,
  "url":"https://...","events":["issue.status_changed"],"enabled":true,
  "secret_hint":"vcKU","consecutive_failures":0,"disabled_reason":null,
  "created_at":"...","updated_at":"..."
}]}
```

### `POST /api/webhook-subscriptions?workspace_id=<ws>`  ✅ create
Required: `url` (absolute http/https; localhost & internal/loopback/link-local IPs rejected) +
`events` (non-empty, all from the allow-list). Add `project_id` to scope to one project; omit for
workspace-level. Returns `201`. 🔴 The full signing `secret` (`whsec_…`) is in the create
response's `secret` field **only this once** — capture and store it now; it's never retrievable
again (subsequent reads give only `secret_hint`).
```json
{"url":"https://example.com/hook","events":["issue.status_changed"],"project_id":"<id optional>"}
```
Response adds `"secret":"whsec_..."` (once) on top of the list-item shape.

**Supported events (allow-list):** `issue.status_changed` (the only event for now; anything else
→ `400 unsupported event`).

### `PATCH /api/webhook-subscriptions/<id>?workspace_id=<ws>`
Partial update: `url`, `events` (must be non-empty if present), `enabled`. Cannot change the
secret here. Use `enabled:false` to pause without deleting.

### `DELETE /api/webhook-subscriptions/<id>?workspace_id=<ws>`
Deletes the subscription. Returns `204`.

### `POST /api/webhook-subscriptions/<id>/test?workspace_id=<ws>`
Queues a synthetic `issue.status_changed` test push to the endpoint. Returns `202` (queued).
`409` if the subscription is disabled; `503` if the delivery queue is unavailable/full.

### `GET /api/webhook-subscriptions/<id>/deliveries?workspace_id=<ws>`  (+ `/<deliveryId>`)
Delivery history (status, attempt count, response code) for debugging.

### `POST /api/webhook-subscriptions/<id>/deliveries/<deliveryId>/redeliver?workspace_id=<ws>`
Manually re-POST a past delivery.

### Delivery contract (what your endpoint receives)
Multica POSTs JSON with these headers:
- `Content-Type: application/json`, `User-Agent: Multica-Webhook/1.0`
- `X-Multica-Event: <event>`, `X-Multica-Delivery: <deliveryId>`
- `X-Multica-Signature-256: sha256=<hex(HMAC-SHA256(rawBody, secret))>` — GitHub-compatible;
  verify with the `whsec_…` secret from create, constant-time compare.

Body shape:
```json
{
  "event":"issue.status_changed",
  "workspace_id":"<uuid>",
  "actor":{"type":"member|agent|system","id":"<id>"},
  "issue":{ ...issue object... },
  "previous_status":"todo",
  "delivered_at":"<RFC3339>"
}
```

Delivery behavior: fire-and-forget, 30s timeout, up to 3 attempts (1 + 2 retries, ~1s/4s backoff).
The sender runs an SSRF guard at delivery time (DNS re-resolved every hop), so endpoints that
resolve to internal addresses are refused even if the create-time literal check passed. Repeated
failures auto-disable the subscription (surfaced via `enabled:false` + `disabled_reason`).

## Health

### `GET /health` / `GET /healthz`
`200` liveness checks (no auth required).

## Notes
- `<id>` for issues accepts both UUID and readable id (`<PREFIX>-<number>`).
- The API client used by the official CLI also sends optional context headers
  (`X-Workspace-ID`, `X-Agent-ID`, `X-Task-ID`); only `Authorization` and a workspace
  selector are needed for direct curl usage.
