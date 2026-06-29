# CLI Contract — multica squad onboarding

Exact commands, JSON field names, hard ordering, and error handling for provisioning.
All commands target the current default workspace unless `--workspace-id` is passed.
Always use `--output json` when you need to parse output.

---

## Hard dependency ordering (do not deviate)

```
1. skills exist  ─────────────────┐
2. agent create  (needs runtime-id)│  agents must exist before squad,
3. agent skills set/add            │  because squad create needs --leader
4. squad create  (needs --leader) ◄┘
5. squad member add  (needs squad-id + agent-id)
6. squad update --instructions     (squad create has NO --instructions)
```

Why:
- `agent create` **requires** `--runtime-id`. There is no persona field — role identity goes in `--instructions`.
- `squad create` **requires** `--leader` (agent name or ID) → the leader agent must already exist.
- `squad create` has **no** `--instructions` flag → set squad instructions afterward via `squad update`.

---

## Command reference

### Preflight (read-only)
```
multica auth status
multica runtime list --output json        # filter status=="online"
multica agent list  --output json
multica skill list  --output json
multica squad list  --output json
```

### Skills
```
# reuse: just take the id from `skill list`
# import:
multica skill import --url <github.com|clawhub.ai|skills.sh URL> \
  --on-conflict fail|overwrite|rename|skip --output json
# search (to discover importable skills):
multica skill search "<query>" --output json
# create new (prefer --content-file to keep large SKILL.md bodies out of argv):
multica skill create --name <name> --description <desc> \
  --content-file <path-to-SKILL.md-body> --output json
```

### Agents
```
multica agent create \
  --name <name>            # required
  --runtime-id <id>        # required (the online runtime chosen in Phase 0)
  --description <desc> \
  --instructions <text>    # role identity + boundaries + protocol (authored, not paraphrased)
  --visibility private|workspace \   # default private
  --output json
# (omit --model on purpose → falls back to runtime default)

multica agent skills set <agent-id> --skill-ids id1,id2,id3   # cold-start: full replace
multica agent skills add <agent-id> --skill-ids id4,id5       # incremental: append
multica agent skills list <agent-id> --output json            # verify
```

For long instruction bodies, prefer writing to a temp file then reading it inline; if instructions contain
shell-hostile characters, keep them in a file and pass via a heredoc-free mechanism. (The CLI has no
`--instructions-file`; pass the string directly but keep it shell-safe, or use `agent update` after create.)

### Squad
```
multica squad create --name <name> --leader <leader-agent-name-or-id> --description <desc> --output json
multica squad member add <squad-id> --member-id <agent-id> --role <semantic-role> --type agent --output json
multica squad member set-role <squad-id> --member-id <agent-id> --role <role> --member-type agent
multica squad update <squad-id> --instructions <text>          # squad-level instructions
multica squad get <squad-id> --output json                     # verify
```

`--role` is free-form text (default "member"). Use semantic roles: `leader`, `planner`, `executor`,
`reviewer`, `researcher`, `verifier`, `writer`, etc. The leader given at `squad create` is auto-recorded
with role `leader`; you do not need to re-add the leader as a member.

---

## JSON field map (verified)

`runtime list` (array) — each item:
- `id`, `name`, `provider` (claude|codex|openclaw), `runtime_mode`, `status` (online|offline)

`agent list` / `agent create` (object or array) — each agent:
- `id`, `name`, `description`, `instructions`, `runtime_id`, `model`, `visibility`,
  `max_concurrent_tasks`, `skills` (array of {id,name,description})

`skill list` / `skill create` — each skill:
- `id`, `name`, `description`

`squad list` / `squad get` / `squad create` — each squad:
- `id`, `name`, `description`, `instructions`, `leader_id`, `member_count`,
  `member_preview` (array of {member_id, member_type, role})

→ To get the new agent ID after create: parse `.id` from the `agent create --output json` result.
→ To get the new squad ID: parse `.id` from `squad create --output json`.

---

## Error handling

- Check the exit code of every command. Non-zero → STOP, report the command + stderr, do not continue.
- Add `--debug` to a failing command to surface full error details.
- Common failures:
  - **missing `--runtime-id`** → agent create rejected. Ensure a runtime was chosen in Phase 0.
  - **no online runtime** → do not even start provisioning; this is the Phase 0 stop condition.
  - **`--leader` agent not found** → the leader agent wasn't created yet, or name mismatch. Create agents first.
  - **skill import conflict** → a skill with that name exists. Re-run with `--on-conflict rename|skip|overwrite`
    per user choice (default `fail` is intentional so nothing is clobbered silently).
  - **duplicate agent/squad name** → in incremental mode this is expected; reuse the existing ID instead of creating.
