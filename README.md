# octo-skills

A collection of [OpenClaw](https://docs.openclaw.ai) / octo AgentSkills for working with
[Mininglamp](https://github.com/Mininglamp-OSS) tooling.

Each subdirectory is a self-contained skill with a `SKILL.md` (and optional `references/`).

## Skills

| Skill | What it does |
|---|---|
| [`octo-multica-cloud`](octo-multica-cloud/) | Drive the cloud-hosted multica SaaS (`multica.imocto.cn`) from octo/OpenClaw — read/create issues, list agents, dispatch tasks, add comments — using a per-user `octo-multica-key` API key. Account-agnostic; discovers workspaces and agents at runtime. |
| [`octo-loop`](octo-loop/) ⚗️ _experimental_ | An OpenClaw loop-engineering standard layered on octoim + octo-spec + octo-multica-cloud. A three-ring nested contract (orchestration / execution / verification) with a loop-uncheatable acceptance gate. De-branded with role placeholders; account-agnostic via octo-multica-cloud. Early access — efficacy still being validated by pilot data. |

## 🚀 Quick install (one line to your octo bot)

The easiest way: **paste one sentence to your OpenClaw/octo bot** and it installs the skill for
you, then runs onboarding. Copy-paste this into a chat with your bot (replace the skill name to
install a different one):

```
帮我安装 octo-skills 里的 octo-multica-cloud 技能：从 https://github.com/Mininglamp-OSS/octo-skills 拉取，装到我的 OpenClaw skills 目录，然后跑首次引导帮我配置密钥。
```

English version:

```
Install the octo-multica-cloud skill from https://github.com/Mininglamp-OSS/octo-skills into my OpenClaw skills directory, then run its first-run onboarding to help me configure the key.
```

What the bot does under the hood (no manual steps for you):

```bash
# one-shot installer (clones repo, copies the skill into your skills dir)
curl -fsSL https://raw.githubusercontent.com/Mininglamp-OSS/octo-skills/main/install.sh | bash -s octo-multica-cloud
```

Or equivalently, by hand:

```bash
TMP=$(mktemp -d)
git clone --depth 1 https://github.com/Mininglamp-OSS/octo-skills.git "$TMP/octo-skills"
DEST="${OPENCLAW_SKILLS_DIR:-$HOME/.openclaw/skills}"
mkdir -p "$DEST"
cp -r "$TMP/octo-skills/octo-multica-cloud" "$DEST/"
rm -rf "$TMP"
echo "installed -> $DEST/octo-multica-cloud"
```

After copying, the bot reads the new `SKILL.md` and runs its **first-run onboarding** — it checks
whether your `octo-multica-key` secret is configured and, if not, walks you through creating it.
So from your side it really is just: send the sentence → answer the key prompt → done.

## Manual install

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
