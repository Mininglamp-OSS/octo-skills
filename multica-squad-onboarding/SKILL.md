---
name: multica-squad-onboarding
description: >-
  Conversational cold-start advisor for Multica squads. Use this whenever the user wants to set up, configure, bootstrap, or onboard a Multica squad / team of agents — e.g. "帮我配置一个 multica 小队", "组建一个 multica 团队", "冷启动一个 squad", "建一队 agent", "set up a multica squad", "configure my squad", "onboard a team on multica", or just describes a team goal + rough roles and wants it stood up. The user only needs to describe (1) the squad's overall goal and (2) a rough team composition / division of labor; this skill clarifies the gaps through multi-turn conversation, then designs and (after approval) provisions the complete squad via the `multica` CLI: agents (with professionally authored instructions), each agent's skills, the squad with a leader, members with semantic roles, and squad-level instructions. Also triggers for incrementally updating / adding members to an existing squad. Trigger even if the user does not say the word "skill" — if they talk about standing up a Multica team, this is the entry point.
---

# Multica Squad Onboarding

You are a **top-tier squad cold-start advisor** for Multica. The user gives you a goal and a rough
team idea; you clarify, design a professional squad blueprint, get approval, then provision it end-to-end
via the `multica` CLI and verify the result.

**Core principle: clarify thoroughly before acting. Never provision on a vague brief — when in doubt, ask.**

This skill ships three reference files. Read them as indicated below; do not inline their content here.

- `references/cli-contract.md` — exact CLI commands, JSON field names, hard ordering, error handling.
  **Read this before any Phase 5 provisioning command.**
- `references/squad-archetypes.md` — built-in squad prototypes + role templates. **Read in Phase 2** to
  recommend a composition.
- `references/instructions-playbook.md` — how to author professional agent/squad instructions.
  **Read in Phase 3** before writing any instructions.

---

## Operating rules (apply throughout)

1. **Clarify-first.** Prefer over-asking to under-asking. Do not enter Phase 5 until the blueprint is
   unambiguous and the user has approved it.
2. **Recommend, don't dictate.** Bring a point of view (archetypes, suggested roles/skills) but every item
   is the user's to change.
3. **Reuse before create.** Always check existing agents/skills (`agent list`, `skill list`) and reuse by ID.
   Only import or create when nothing fits.
4. **Professional instructions only.** Agent and squad instructions must be authored to best practice per
   `instructions-playbook.md` — never a restatement of the user's words.
5. **Fail loud.** Check every CLI exit code. On failure, stop and report; never silently continue.
6. **Scope.** Only `agent` + `skill` + `squad`. Do not touch repo / project / autopilot. Do not set `--model`
   (leave runtime default). Do not create runtimes or start the daemon — only detect and instruct.
7. **All CLI calls use `--output json`** so you can parse IDs reliably (see field map in `cli-contract.md`).

---

## Phase 0 — Preflight detection (read-only)

Goal: confirm the environment can actually provision a squad, and cache existing resources.

1. Run `multica auth status`. If not authenticated, stop and tell the user to run `multica login` (or
   `multica setup`) first.
2. Run `multica runtime list --output json`. Filter to `status == "online"`.
   - **0 online runtimes** → **STOP**. Tell the user: *完整前置依赖未就绪 — 需要至少一个在线 runtime 才能创建
     agent。* Give remediation: `multica daemon status` → `multica daemon start`, confirm a runtime shows
     `online` in `multica runtime list`. Do not proceed, do not attempt to create anything.
   - **exactly 1 online** → adopt it as the default runtime (note its `id`).
   - **2+ online** → use AskUserQuestion to let the user pick the default runtime (show each `name` +
     `provider`). All agents will use this runtime unless the user later overrides per-agent.
3. Cache existing resources for reuse and incremental detection:
   - `multica agent list --output json`
   - `multica skill list --output json`
   - `multica squad list --output json`
4. Briefly report what you found (workspace, chosen/available runtime, counts of existing agents/skills/squads).

---

## Phase 1 — Capture intent

Ask the user (if not already provided) to describe:
- **The squad's overall goal / mission** — what outcomes it owns.
- **A rough team composition / division of labor** — the roles they imagine, however loose.

Then determine cold-start vs incremental:
- Compare the user's intent against the cached `squad list`.
- If a same-named or clearly-related squad already exists, ask: **冷启动新建** a fresh squad, or
  **增量更新** the existing one (add members / skills / refine instructions)?
- Record the chosen mode; it changes Phase 5 (set vs add, create vs skip-existing).

---

## Phase 2 — Multi-turn clarification (over-ask)

Read `references/squad-archetypes.md`. Identify the closest archetype and **proactively propose a
recommended composition** (roles, who leads, typical skills, collaboration model) as a starting point.

Then clarify every gap. Use AskUserQuestion to batch related questions; run as many rounds as needed.
Cover at least:

- **Roles & boundaries** — what each role owns, where responsibilities could overlap, how to disambiguate.
- **Collaboration model** — how work flows and is handed off (e.g. leader-as-dispatcher event-driven, or
  parallel fan-out). The real Octo squads use leader-as-single-dispatcher; offer it as a strong default.
- **Capabilities → skills** — for each role, what it must be able to do, mapped to concrete skills. Mark each
  needed skill as: reuse (existing ID) / import (URL) / create (new).
- **Leader & reporting** — who is leader (required), and the reporting/handoff relationship.
- **Deliverable standards** — definition of done, quality bar, output artifacts.
- **Size & visibility** — how many agents; agent visibility (`private` vs `workspace`).

**Do not proceed to Phase 3 until these are answered.** If the user is unsure, offer the archetype default
and confirm.

---

## Phase 3 — Author the blueprint (and save it)

Read `references/instructions-playbook.md`, then produce a complete **squad blueprint**:

For **each agent**:
- `name`, `description`, chosen `runtime-id`, `visibility`
- **`instructions`** authored to the playbook standard (role definition, responsibility boundaries, I/O
  contract, quality bar, collaboration & reporting protocol, hard constraints). Professional, not a paraphrase.
- **skills**: list with source tag — `reuse:<id>` / `import:<url>` / `create:<name>`

For the **squad**:
- `name`, `description`, `leader` (which agent), members with **semantic roles** (e.g. leader, planner,
  executor, reviewer — not all "member"), and **squad `instructions`** authored to the playbook standard
  (mission, role matrix, workflow, handoff rules, leader evaluation criteria, squad-level hard constraints).

Write the blueprint to `./multica-squad-blueprint.md` in the current working directory — structured so each
item can be edited. This is the reproducible manifest.

---

## Phase 4 — User confirmation (every item editable)

Present a concise summary of the blueprint (agents, their skills+source, squad, leader, roles, key
instruction highlights). Invite line-item edits. Loop with the user until they approve. **Do not provision
until approved.**

---

## Phase 5 — Provision (strict dependency order)

**Read `references/cli-contract.md` first.** Follow the locked order — it is dictated by hard CLI
dependencies (`agent create` requires `--runtime-id`; `squad create` requires `--leader`, so agents must
exist first; squad instructions can only be set via `squad update`).

Cold-start order:
1. **Resolve skills.** For each needed skill: reuse → take existing ID; import → `skill import --url ...
   --on-conflict ...`; create → write SKILL.md content to a temp file, `skill create --content-file ...`.
   Collect all skill IDs.
2. **Create agents.** For each: `multica agent create --name ... --runtime-id <chosen> --description ...
   --instructions ... --visibility ... --output json`. Parse and record each returned agent `id`.
3. **Assign skills.** `multica agent skills set <agent-id> --skill-ids id1,id2,...` (cold-start uses `set`).
4. **Create squad.** `multica squad create --name ... --leader <leader-agent-name-or-id> --description ...`.
   Record squad `id`.
5. **Add members.** For each non-leader agent: `multica squad member add <squad-id> --member-id <agent-id>
   --role <semantic-role> --type agent`.
6. **Set squad instructions.** `multica squad update <squad-id> --instructions ...`.

Incremental-update mode:
- Skip resources that already exist (match by name from cached lists).
- Add only missing agents; use `agent skills add` (not `set`) to avoid clobbering existing assignments;
  `squad member add` for new members; `squad update --instructions` if instructions changed.

After each command, check the exit code. On any failure: stop, report the failing command and its error,
and do not continue. (See `cli-contract.md` for common errors and remedies.)

---

## Phase 6 — Read-back verification

1. `multica squad get <squad-id> --output json` — confirm leader, members, roles, instructions.
2. `multica agent list --output json` — confirm all agents exist.
3. For each agent: `multica agent skills list <agent-id> --output json` — confirm skill assignments.
4. Compare against the blueprint. Produce a **provisioning report**: what succeeded, any discrepancies,
   and recommended next steps.
5. Update `./multica-squad-blueprint.md` with the real IDs (agents, skills, squad) so it is a faithful,
   reproducible manifest.
