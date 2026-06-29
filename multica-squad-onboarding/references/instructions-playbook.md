# Instructions Playbook — authoring professional agent & squad instructions

Agent and squad `instructions` are the heart of a "top-tier" squad. They must be **authored to best
practice**, never a restatement of the user's brief. This file gives the structure and quality bar,
modeled on the real Octo squads' instructions.

Multica agents have **no persona field** — the entire role identity lives in the agent's `--instructions`.
Squad `instructions` define how the members coordinate.

---

## Quality bar (both agent and squad instructions)

- **Specific over generic.** Name the artifacts, labels, commands, and handoff verbs the agent will use.
- **Boundaries are explicit.** State what the role does NOT do (prevents overlap and runaway behavior).
- **Evidence-based & fail-closed.** Decisions cite evidence; on uncertainty/failure, stop safely and flag
  for human review rather than guessing.
- **Handoff is unambiguous.** Every agent knows exactly who it returns to and how.
- **Hard constraints listed.** Timeouts, forbidden actions, scope limits — enumerated, not implied.

---

## Agent instructions template

```markdown
# Role: <role name>

<1-2 sentences: what this agent is and how it is triggered (e.g. "由 squad leader 通过 issue assign 触发").>

## Responsibilities
- <core duty 1 — concrete, with the artifact it produces>
- <core duty 2>

## Workflow
1. <read input: where the context/task comes from>
2. <load the bound skill(s) and run the expertise flow>
3. <produce output: comment / label / file / PR, named precisely>
4. **必须** 收尾: hand off — <exact command, e.g. `multica issue assign <tracker> --to leader`>
5. Write a trace line: `trace: <role> task=<id> action=<done> handoff=<to>`

## Boundaries (what this role does NOT do)
- <e.g. 不 dispatch 其他 specialist (只有 leader 能 dispatch)>
- <e.g. 不跨 squad 操作>
- <e.g. 不自加 <restricted labels>>

## Hard constraints
- <wall-clock timeout, e.g. 15 min hard / 12 min self-circuit-break>
- <on any sub-stage failure → flag needs-human-review + status blocked + hand back to leader>
- <forbidden commands>
- Bound skills carry the detailed expertise flow — see their SKILL.md.
```

Notes:
- Keep the identity here; keep deep domain procedure in the agent's **bound skills** (SKILL.md), referenced
  from the workflow. This keeps instructions focused and lets skills be reused across agents.
- Always specify the **return-to-leader** handoff for specialists. The leader's instructions specify dispatch.

---

## Squad instructions template

```markdown
# <squad name> — coordination instructions

**Trigger**: <how tasks enter the squad — e.g. tracker created + assigned to leader>.
**Coordination model**: <e.g. leader-as-single-dispatcher, event-driven. Specialists return to leader; the
leader is the only orchestrator.>

## Role matrix
| Role | Responsibility | Dispatched when |
|---|---|---|
| leader | orchestrate, decide next role, aggregate | always entry point |
| <role> | <duty> | <state/condition> |

## Leader decision table
| Incoming state (priority top→bottom) | Leader action | Handoff after |
|---|---|---|
| <state A> | <action> | <reassign to / terminal> |
| <state B> | <action> | <...> |

## Specialist fixed flow
1. read task context
2. load skill, run expertise
3. produce artifact + apply required state marker
4. **必须** reassign back to leader
5. write trace line

## Cross-squad boundaries (hard)
- <what this squad does NOT own; what to do if a wrong task arrives (reassign to the owning squad)>

## Loop detection
- <if N reassigns in a window with no state progress → flag needs-human-review + terminal>

## Hard constraints (squad-level)
- leader is single dispatcher; specialists don't reassign each other
- specialists must hand back to leader (unless terminal: needs-human-review)
- <forbidden actions: merge / force-push / cross-org / etc.>
- per-task timeout
```

---

## Authoring guidance

- Derive the **leader decision table** from the user's described workflow states — this is what makes the
  squad actually coordinate rather than just exist.
- Use **semantic member roles** consistently between the squad role matrix and the actual
  `squad member add --role` calls.
- If the squad collaborates via Multica issues, make handoff verbs explicit
  (`multica issue assign <tracker> --to <role>`).
- Tailor depth to squad size: a 2-agent squad needs a short table; a 6-agent pipeline needs the full
  state machine.
