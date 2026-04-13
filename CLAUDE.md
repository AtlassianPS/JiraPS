# Claude Code Instructions

This file exists for Claude Code compatibility.

**Canonical sources**:
- Project rules: [AGENTS.md](AGENTS.md)
- PowerShell rules: [.github/ai-context/powershell-rules.md](.github/ai-context/powershell-rules.md)

## Quick Reference

1. **One Functionality Per Commit** — code + tests + docs + green tests
2. **Cloud AND Data Center** — all API changes must work on both Jira deployment types
3. **User Identity** — `accountId` for Cloud, `username`/`name` for DC
4. **REST calls** — always go through `Invoke-JiraMethod`
5. **Tests required** — every function needs `.Unit.Tests.ps1`
6. **Run tests before commit** — `Invoke-Build -Task Build, Test` (must build first!)

## File Locations

| Type | Location |
|------|----------|
| Public functions | `JiraPS/Public/` |
| Private functions | `JiraPS/Private/` |
| Tests | `Tests/Functions/Public/` or `Tests/Functions/Private/` |
| Docs | `docs/en-US/commands/` |

For full instructions, read `AGENTS.md` and `.github/ai-context/powershell-rules.md`.
