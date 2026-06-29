# Squad Archetypes — recommended compositions

Use these as **starting-point recommendations** in Phase 2. Identify the closest archetype to the user's
stated goal, propose it, then tailor with the user. None of this is fixed — every role/skill is editable.

These archetypes are modeled on the real, mature squads already running in this workspace (the Octo
`coding` and `review` squads), which use a **leader-as-single-dispatcher, event-driven** coordination model.

---

## Coordination model (the strong default)

**Leader-as-single-dispatcher, event-driven:**
- The squad has exactly one **leader** who is the only orchestrator/dispatcher.
- Work arrives as a task (e.g. an issue assigned to the leader). The leader decides the next role and
  hands off via `multica issue assign <tracker> --to <agent>`.
- Specialists do their work, then **always reassign back to the leader** — they never dispatch each other.
- Multica issues are single-assignee, so parallel reviewers must be dispatched **serially**.

Offer this as the default. Alternatives (flat peer collaboration, parallel fan-out) are possible but the
single-dispatcher model is what the proven squads use and avoids ping-pong loops.

---

## Archetype A — Engineering squad

Goal: take work items from triage → spec → implementation → draft PR.

| Role | Semantic role | Responsibility | Typical skills |
|---|---|---|---|
| Leader | `leader` | Triage, dispatch by state, aggregate | triage, state-machine vocab, team-foundation |
| Product analyst | `planner` | Turn feature into reviewed spec | spec-writing |
| Architect | `architect` | High-level design / NFR for big changes | architecture-design |
| Backend/Frontend/DevOps engineer | `executor` | Implement, open draft PR (TDD) | bug-fix / feature-impl engineering |

Collaboration: leader dispatches by issue state; specialists return to leader; reviewers live in a
**separate review squad** (cross-squad boundary).

---

## Archetype B — Review squad

Goal: deep multi-dimension PR review with verdict aggregation.

| Role | Semantic role | Responsibility | Typical skills |
|---|---|---|---|
| Review lead | `leader` | Serial dispatch of reviewers, aggregate verdict | review-orchestration, state-machine vocab |
| QA reviewer | `reviewer-qa` | Correctness / test coverage review | qa-review |
| Security reviewer | `reviewer-security` | Security review (fail-closed) | security-review |
| Code reviewer | `reviewer-code` | Readability / maintainability review | code-review |

Collaboration: 3 reviewers dispatched **serially** (single-assignee constraint); each writes a verdict and
returns to the lead; lead aggregates into a single verdict.

---

## Archetype C — Research squad

Goal: multi-source research with adversarial verification and a synthesized report.

| Role | Semantic role | Responsibility | Typical skills |
|---|---|---|---|
| Leader | `leader` | Scope question, dispatch, synthesize | research-orchestration |
| Researcher | `researcher` | Fan-out search + source gathering | deep-research, web-search |
| Verifier | `verifier` | Adversarially fact-check claims | claim-verification |
| Writer | `writer` | Synthesize cited report | report-writing |

---

## Archetype D — Content squad

Goal: produce polished written/visual deliverables.

| Role | Semantic role | Responsibility | Typical skills |
|---|---|---|---|
| Leader | `leader` | Brief intake, dispatch, final sign-off | content-strategy |
| Strategist | `planner` | Audience, angle, outline | content-strategy |
| Writer | `writer` | Draft | writing |
| Editor | `reviewer` | Edit, fact/style check | editing |

---

## Tailoring checklist (apply to any archetype)

- Drop roles the user doesn't need; merge roles for a small squad (min viable = leader + 1 specialist).
- Every squad **must** have exactly one leader.
- Give each role a **semantic** member role, not "member".
- Map each role's needed capabilities to concrete skills, tagged reuse / import / create.
- Decide hard constraints (timeouts, forbidden actions, cross-squad boundaries) — see instructions-playbook.
