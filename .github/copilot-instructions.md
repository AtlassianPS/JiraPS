# GitHub Copilot Entry Point

GitHub Copilot reads this file as its repository-level instructions.

**Canonical sources**:
- Project rules: [AGENTS.md](../AGENTS.md)
- PowerShell rules: [ai-context/powershell-rules.md](ai-context/powershell-rules.md)
- File-pattern rules: [instructions/](instructions/) (Copilot-specific globs)

## Quick Reference

1. **One Functionality Per Commit** — code + tests + docs + green tests
2. **Cloud AND Data Center** — all API changes must work on both Jira deployment types
3. **User Identity** — `accountId` for Cloud, `username`/`name` for DC
4. **REST calls** — always go through `Invoke-JiraMethod`
5. **Tests required** — every function needs `.Unit.Tests.ps1`
6. **Build before test** — `Invoke-Build -Task Build, Test` (tests run against `Release/`, not source)

## File Locations

| Type | Location |
|------|----------|
| Public functions | `JiraPS/Public/` |
| Private functions | `JiraPS/Private/` |
| Tests | `Tests/Functions/Public/` or `Tests/Functions/Private/` |
| Docs | `docs/en-US/commands/` |

For full instructions, read [`AGENTS.md`](../AGENTS.md) and [`ai-context/powershell-rules.md`](ai-context/powershell-rules.md).
