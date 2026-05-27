# Claude Code Entry Point

Claude Code should treat `AGENTS.md` as the canonical project rule set.
Keep this file small to avoid duplicating context.

## Read First

- `AGENTS.md`
- `.github/ai-context/powershell-rules.md` for Cloud/Data Center or REST/API changes

## Critical Rules

- One functionality per commit: code, tests, docs, and green validation.
- Use `Invoke-Build -Task Build, Test` as the full-suite gate before commit.
- All behavior changes must work on Jira Cloud and Data Center unless explicitly scoped.
- Cloud uses `accountId`; Data Center uses `username` or `name`.
- REST calls must go through `Invoke-JiraMethod`.
- Public cmdlet help lives in `docs/en-US/commands/*.md`, not comment-based help.
