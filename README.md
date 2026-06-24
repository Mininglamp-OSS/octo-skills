# octo-skills

A collection of [OpenClaw](https://docs.openclaw.ai) / octo AgentSkills for working with
[Mininglamp](https://github.com/Mininglamp-OSS) tooling.

Each subdirectory is a self-contained skill with a `SKILL.md` (and optional `references/`).

## Skills

| Skill | What it does |
|---|---|
| [`octo-multica-cloud`](octo-multica-cloud/) | Drive the cloud-hosted multica SaaS (`multica.imocto.cn`) from octo/OpenClaw — read/create issues, list agents, dispatch tasks, add comments — using a per-user `octo-multica-key` API key. Account-agnostic; discovers workspaces and agents at runtime. |

## Installing a skill

These are standard AgentSkills. Drop a skill directory into your OpenClaw skills path
(e.g. `~/.openclaw/skills/`), or install via [ClawHub](https://docs.openclaw.ai) if published there.

```bash
# manual install of one skill
git clone https://github.com/Mininglamp-OSS/octo-skills.git
cp -r octo-skills/octo-multica-cloud ~/.openclaw/skills/
```

Then the agent will pick it up by its `SKILL.md` description. Most skills here have a built-in
first-run onboarding flow that walks you through any required secret/key configuration.

## Contributing

Each skill should:
- live in its own top-level directory with a `SKILL.md` frontmatter (`name`, `description`),
- keep secrets out of the repo (skills materialize user-configured secrets at runtime),
- avoid hardcoding account-specific ids — discover them at runtime where possible.

## License

MIT
