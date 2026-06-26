---
name: octo-loop
description: An OpenClaw loop-engineering standard built on octoim + octospec + octo-multica-cloud. A three-ring nested contract (orchestration / execution / verification) with a loop-uncheatable acceptance gate. Use when receiving a code-implementation / bug-fix / feature request, designing or reviewing cross-agent dispatch, or auditing whether a pipeline conforms to the loop standard. Triggers on "loop process", "engineering standard", "dispatch standard", "acceptance gate", "stop condition", "fake acceptance", "loop engineering". NOT for trivial one-line fixes / typos / pure config (use the trivial escape hatch and dispatch the implementer directly).
---

# octo-loop — OpenClaw Loop Engineering Standard

> **What it is**: an upper-layer composition standard layered on top of three public building blocks — it is a *methodology*, not a runnable dispatch adapter for any single repo.
> **De-branded**: this skill is written with role-name placeholders (`{{dispatcher_name}}`/`{{planner_name}}`/`{{coder_name}}`/`{{reviewer_name}}`/`{{qa_name}}`/`{{auditor_name}}`) plus a `{{token}}` placeholder. Real names live only in a gitignored `config.yaml` you create from `config.yaml.example`. Going public = copy the example, never commit the real `config.yaml` — zero second-pass redaction.

## What this is

It upgrades "hand-prompting an agent" into "designing a system that prompts agents" (loop engineering). The three primitives of this loop already exist in the OpenClaw ecosystem but are scattered:

- **octoim** — message / notification flow-back (dispatch visibility, sub-channel sync, notify-target).
- **octospec** — in-repo execution contract ([`Mininglamp-OSS/octo-spec`](https://github.com/Mininglamp-OSS/octo-spec); spec-only 4-phase flow + load-bearing rules + acceptance).
- **octo-multica-cloud** — the portable cross-agent orchestration layer (the sibling skill in this repo) that exposes the cloud multica SaaS to any octo/OpenClaw user via a per-user `octo-multica-key`, discovering workspace/agent at runtime with zero hardcoded account ids.

`octo-loop` welds them into a **three-ring nested contract** so any agent/sub-channel can reference one standard, instead of relying on rules living in one orchestrator's head. Because the multica access layer is `octo-multica-cloud` (a portable component), octo-loop is **account-agnostic and team-usable** — it is not bound to any private instance or private domain.

---

## Prerequisites

octo-loop only works once all three primitives below are in place. Each line includes a one-shot readiness check; the first-run onboarding (next section) runs all three for you.

| Dependency | Why it's required | Readiness check |
|---|---|---|
| **octoim** | Progress flow-back: without it, dispatch visibility and `notify-target` delivery break, so status never returns to the dispatcher. | Confirm octo IM is wired for flow-back (you receive issue-status updates / `notify-target` reaches its destination). No single command — verify a test notification arrives. |
| **octospec** | The in-repo execution contract (middle ring). The target repo **must** have been initialized first, producing `.octospec/rules/_index.yaml` and `tasks/_brief.template.md`; otherwise the middle ring degrades to an empty shell. Run `octospec init` in the repo if missing. | `ls .octospec/rules/_index.yaml` (exists = already initialized) |
| **octo-multica-cloud** | The orchestration access layer (outer ring). Configure your own `octo-multica-key` secret first (see that sibling skill's onboarding). Without a valid key, the outer ring cannot create/list issues or discover agents. | `mc GET /api/me` returns `200` (uses the `mc` helper from the octo-multica-cloud skill) |

If any of the three is missing, the corresponding ring fails silently — that is exactly the failure mode the onboarding self-check is designed to catch.

---

## 📦 First-run onboarding (run this when the user installs the skill or first asks to use it)

On install, or the first time the user invokes anything in this skill, the agent MUST verify the three primitives are ready and, if any is missing, send the matching setup guide and STOP until it is configured. (This mirrors the onboarding pattern of the sibling `octo-multica-cloud` skill.)

**Onboarding flow the agent runs (the three readiness checks above):**
1. **octo-multica-cloud** — materialize `octo-multica-key` and call `mc GET /api/me`. 200 → ready. No key / 401 → send the octo-multica-cloud setup guide and STOP.
2. **octospec** — in the target repo, run `ls .octospec/rules/_index.yaml`. Present → ready. Missing → tell the user to run `octospec init` in that repo and STOP.
3. **octoim** — confirm a test notification / status flow-back arrives. Working → ready. Otherwise → ask the user to wire octo IM flow-back and STOP.

Only when all three are green is the skill ready. Then read `config.yaml` (see Onboarding for new teams below) so the role placeholders resolve to real agents.

**Setup guide to send the user (verbatim-friendly):**
```
To use octo-loop, three building blocks must be ready:
1. octo-multica-cloud — install the sibling skill and configure your `octo-multica-key`
   (multica web app → Settings → API Keys). Check: `mc GET /api/me` returns 200.
2. octospec — in the repo you'll dispatch work into, run `octospec init`.
   Check: `ls .octospec/rules/_index.yaml` exists.
3. octoim — make sure octo IM message flow-back is wired so notify-target reaches you.
Tell me once these are set and I'll re-run the self-check.
```

---

## Core model: the three-ring nested loop

Every ring is a `goal -> observe state -> act -> verify -> continue/stop` loop, where the outer ring's "act" is starting the inner ring.

```
Outer ring (orchestration, multica domain) ── held by {{dispatcher_name}}
  └─ Middle ring (execution, octospec domain) ── held by {{coder_name}}
       └─ Inner ring (verification, cross-cutting) ── the stop/verify contract shared by all rings
```

### Outer ring — orchestration loop (Orchestration)

Holder: `{{dispatcher_name}}` (the orchestrator).

```
request -> classify tier -> {{planner_name}} produces a plan -> {{coder_name}} picks it up and implements
        -> {{reviewer_name}} reviews -> merge -> {{qa_name}} runs E2E -> closeout / status transition
```

**The orchestration access layer is octo-multica-cloud — never a bare multica CLI or a private instance.** All orchestration actions (issue create/list, agent discovery, comments, status transitions) go through the **octo-multica-cloud** `mc` helper pattern: `curl` + the user's own `octo-multica-key` + **runtime discovery** of workspace/agent (`mc GET /api/workspaces`, then `mc GET /api/agents`), with zero hardcoded account ids. This is what makes octo-loop portable and account-agnostic.

Hard constraints:
1. **plan-first by default**: for any code ticket, before dispatching the implementer, classify the tier and have `{{planner_name}}` produce a plan (lite: a few minutes to a 3-line machine-checkable acceptance + drift baseline / full: heavy tickets, cross-repo, P0, schema/API/security surface). The trivial escape hatch may skip this.
2. **the dispatch brief MUST reference the repo's `.octospec/`**: the load-bearing list is derived from `rules/_index.yaml`, never recited from memory. This is the weld between the outer and middle rings.
3. **dispatch via a multica issue, not a chat @**: issues are picked up asynchronously; chat @ gets lost. Issue operations go through the octo-multica-cloud `mc` helper (`mc POST /api/issues …`).
4. **notify-target is mandatory**: append `notify-target:` (sub-channel + DM) to the end of every issue description, otherwise progress cannot flow back to the dispatcher (octoim flow-back depends on it).
5. **review / audit / root-cause -> dispatch `{{reviewer_name}}` directly**; **E2E -> dispatch `{{qa_name}}` directly**; **repo-wide full audit / cross-system architecture review -> `{{auditor_name}}`** (large context, ingests the whole repo). Do NOT put a planning ticket in front of a review task — that is reviewing the review.

### Middle ring — execution loop (Execution, octospec 4-phase)

Holder: `{{coder_name}}` (the implementer). octospec already defines this ring; octo-loop only enforces "attach it at dispatch time".

```
1. Plan      — read _brief.template.md, write .octospec/tasks/<slug>/brief.md
               (Goal / Load-bearing list / Out-of-scope / Acceptance), confirm before writing code
2. Implement — parse rules/_index.yaml, read every matched rule in full and obey it (load_bearing first).
               Record resolved rules in context.yaml. For release/docs-style tickets with zero `.rs`
               changes, you STILL must write context.yaml with an explicit `injected: []`
               (rules were resolved, zero matched) — this distinguishes "omitted" from "skipped".
3. Verify    — for each injected rule, walk the load-bearing path (not the happy path); run lint/type/test; self-fix
4. Finish    — run the gate once more; write the journal; reusable learnings go to learnings/pending
               (not auto-promoted to rules); open the PR with Linked Spec + the COMPREHENSION 3 questions
               (load-bearing / architecture / P0 changes)
```

### Inner ring — verification loop (Verification & Stop) 🔴 the core increment of this standard

This is octo-loop's **only true increment** over the existing parts, and the team's most painful point.

#### Contract V1 — the stop condition must be loop-uncheatable

> "Verification decides whether a loop is useful; the stop condition decides whether a loop is safe; and the stop condition must be written in a form the loop cannot cheat."

For any ticket with acceptance, the acceptance clause must satisfy:

- ✅ **Falsifiable / observable lower bound**: assert "at least X happened" (a lower bound), "under condition Y, Z was observed to actually occur".
- ❌ **No "true unless triggered" assertions**: forbid probes that **pass even when the target code path is never invoked** — such assertions cannot prove the behavior actually happened, and a weak implementer can leave the wiring undone and still go green.

**Decision rule (to avoid false-flagging legitimate upper-bound assertions)**:
whether a single assertion is a violation has **one and only one criterion = "would it fail if the target behavior did not happen?"**:
- ✅ **Legal**: evidence that "the path was triggered" (call count / observable side effect / state transition) **plus** an assertion of the boundary value. E.g. "clamp was called N≥1 times **and** each output ≤ upper bound" — without wiring, count = 0 fails, so it cannot falsely go green.
- ✅ **Legal**: a pure upper-bound safety/resource guard (e.g. "peak memory ≤ X", "timeout ≤ Y") **is itself** the falsifiable target of that scenario — these are not violations, use them normally.
- ❌ **Violation**: a lone upper bound with no "behavior happened" evidence (e.g. "return value ≤ upper bound" but never asserting the function was reached) — true unless wired.

Shorthand: **what is banned is not "≤", what is banned is "≤ with no trigger evidence".** When producing a plan, the planner asks of each clause "would this fail if the target behavior did not happen?" — if not, add one piece of trigger evidence (lower bound / count / side effect). The reviewer re-checks this clause as the fake-acceptance gate.

#### Contract V2 — STOP-on-hole (find a hole in the design/premise and stop; do not deviate on your own)

If the implementer finds a hole in some decision of the plan/design (a machine-demonstrable contradiction — e.g. implementing strictly per the design would break an already-merged load-bearing test or violate a load-bearing rule) → **STOP and report; do not write code, do not deviate on your own.** Post the essence of the hole + the evidence chain + a proposed fix back to the issue, and wait for the design owner to decide.

> This is not a stall, it's the correct posture: when the stop condition fires, you don't fudge it. Distinguish "give up at the first ordinary difficulty" (wrong) vs "stop and report on finding a load-bearing contradiction" (right) — the latter must carry machine-checkable evidence (point to the specific test/rule + the leak path).

#### Contract V3 — rework cap = 3 (hard gate)

The rework (fix/re-review) rounds on a single PR cap at 3. Before dispatching round 4 you must stop: count how many rounds this PR has already been through (issue comments + PR timeline); at 4, switch to producing a holistic redesign ticket for the decision-maker, instead of playing whack-a-mole.

#### Contract V4 — Verification over throughput

The stronger the loop, the harder verification gets, the more volatile the token economy, and the sharper the failure modes. Any "speed-up" proposal must first ask "does this make verification harder?". Do not trade acceptance strength for throughput.

---

## The human node (Comprehension Gate, narrow trigger)

Only for **P0 / architectural / load-bearing-behavior-touching** PRs:

- **Head (spec-first)**: the implementer first produces a SPEC.md (change goal / architecture decision / test strategy / load-bearing list / what not to touch); the decision-maker scans the direction in 30 seconds and only then is coding allowed.
- **Tail (comprehension gate)**: the PR body carries the COMPREHENSION 3 questions — ① which load-bearing behaviors were touched ② why it's safe (which conditions / consuming branches already cover this delta) ③ what blows up first when it breaks. The decision-maker reads this section (not the diff) and judges in 30 seconds "did someone actually understand this change". Unreadable = the change itself wasn't understood clearly → bounced for a rewrite.

Ordinary bug/lint/format/dependency upgrades do **not** trigger this — they take the fast path.

---

## Reuse (compounding the loop)

- Reusable learnings → `.octospec/learnings/pending/` (promotion into rules is a separate reviewed PR, never automatic).
- Structural bug patterns that recur across repos (e.g. the "unconditional advance vs conditional consume" decoupling of a cursor) → crystallize into a rule or memory.
- These rules flow back into the middle ring's Implement phase as forced injection → the loop closes and compounds.

---

## Onboarding for new teams

octo-loop ships de-branded. A new team makes it concrete via a gitignored `config.yaml` (real values never committed):

1. Copy the template: `cp octo-loop/config.yaml.example octo-loop/config.yaml` (the repo's `.gitignore` already ignores `config.yaml`, keeping `*.example` tracked).
2. Map every role placeholder to your own agent instance — `{{dispatcher_name}}`, `{{planner_name}}`, `{{coder_name}}`, `{{reviewer_name}}`, `{{qa_name}}`, `{{auditor_name}}` — and fill the `{{token}}` slot. See `config.yaml.example` for the skeleton; every value there is a placeholder, never a real id.
3. Configure `octo-multica-key` for the outer ring (see the octo-multica-cloud sibling skill), so orchestration runs through the portable cloud access layer rather than any private multica instance.

### Install

This is a standard AgentSkill. Use the repo's generic installer (no edit to `install.sh` needed — it copies by subdirectory name):

```bash
bash install.sh octo-loop
# or one-shot:
curl -fsSL https://raw.githubusercontent.com/Mininglamp-OSS/octo-skills/main/install.sh | bash -s octo-loop
```

After copying, the agent reads this `SKILL.md` and runs the **First-run onboarding** above (the three readiness checks), then loads `config.yaml`.

---

## Anti-pattern quick reference

- ❌ Dispatching a code ticket without a plan (trivial excepted) → skips the outer-ring plan-first.
- ❌ An acceptance assertion that "passes even when the target behavior doesn't happen" (a lone upper bound with no trigger evidence) → violates V1, can bury an always-green gate.
- ❌ Finding a hole in the design and deviating on your own → violates V2, should STOP and report.
- ❌ Still playing whack-a-mole on round 4 of the same PR → violates V3, should produce a holistic plan.
- ❌ A dispatch brief that doesn't reference `.octospec/` rules → outer and middle rings unweld, load-bearing drifts by hearsay.
- ❌ Dispatching without a notify-target → octoim flow-back breaks, progress can't return to a human.
- ❌ Wiring the outer ring to a bare multica CLI / private instance instead of octo-multica-cloud → re-privatizes the loop; others can't run it.
- ❌ A release/docs ticket with zero `.rs` changes that omits `context.yaml` → write `injected: []` explicitly so "skipped" is distinguishable from "omitted".
