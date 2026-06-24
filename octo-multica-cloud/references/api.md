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

## Health

### `GET /health` / `GET /healthz`
`200` liveness checks (no auth required).

## Notes
- `<id>` for issues accepts both UUID and readable id (`<PREFIX>-<number>`).
- The API client used by the official CLI also sends optional context headers
  (`X-Workspace-ID`, `X-Agent-ID`, `X-Task-ID`); only `Authorization` and a workspace
  selector are needed for direct curl usage.
