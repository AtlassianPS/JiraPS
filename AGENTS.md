# AI Instructions for JiraPS

This file is the compact, always-loaded rule set for AI coding assistants.
Load deeper context only when the task needs it.

## Critical Rules

- One functionality per commit: code, tests, docs, changelog when user-facing, and green validation.
- Do not commit until the relevant local validation passes; use `Invoke-Build -Task Build, Test` as the full-suite gate.
- All behavior changes must work for Jira Cloud and Jira Data Center unless the task explicitly scopes one deployment.
- User identity differs by deployment: Cloud uses `accountId`; Data Center uses `username` or `name`.
- Cloud rich-text payloads use Atlassian Document Format; Data Center text fields generally use plain strings.
- All REST calls go through `Invoke-JiraMethod`; do not call `Invoke-RestMethod` or `Invoke-WebRequest` directly from cmdlets.
- Keep runtime dependencies at zero unless a task explicitly accepts adding one.
- Public functions use generated external help only; do not add comment-based help to files in `JiraPS/Public/`.
- Out-of-scope ideas go to the backlog, not into the current PR.

## Context Map

Read these files only when relevant:

| Need | File |
|------|------|
| Cloud/Data Center REST rules, parameter patterns, API review checklist | `.github/ai-context/powershell-rules.md` |
| CI triage | `.github/ai-context/ci-triage-runbook.md` |
| Release procedure | `.github/ai-context/releasing.md` |
| Unit-test conventions | `Tests/README.md` |
| Integration-test setup and fixtures | `Tests/Integration/README.md` |
| Cmdlet help source | `docs/en-US/commands/*.md` |
| Copilot file-pattern rule | `.github/instructions/jira-api-compatibility.instructions.md` |

## Repository Layout

| Type | Location |
|------|----------|
| Public cmdlets | `JiraPS/Public/` |
| Private helpers and converters | `JiraPS/Private/` |
| C# types and argument transformers | `JiraPS/Types/` |
| Unit tests | `Tests/Functions/Public/` or `Tests/Functions/Private/` |
| Integration tests | `Tests/Integration/` |
| External help markdown | `docs/en-US/commands/` and `docs/en-US/about_*.md` |
| Build and setup scripts | `JiraPS.build.ps1`, `Tools/` |
| Build output | `Release/` (ignored; never commit) |

## Development Workflow

Run setup before normal development:

```powershell
./Tools/setup.ps1
```

Use focused tests while iterating:

| Change | Validation |
|--------|------------|
| Any PowerShell source | `Invoke-Build -Task Lint` |
| Public function | `Invoke-Pester Tests/Functions/Public/<Function>.Unit.Tests.ps1` |
| Private function | `Invoke-Pester Tests/Functions/Private/<Function>.Unit.Tests.ps1` |
| Test file | `Invoke-Pester <path-to-test-file>` |
| Help markdown | `Invoke-Pester Tests/Help.Tests.ps1` |
| Full suite before commit | `Invoke-Build -Task Build, Test` |

Integration commands:

```powershell
Invoke-Build -Task TestIntegration
Invoke-Build -Task TestIntegration -Tag 'Smoke'
Invoke-Build -Task TestIntegrationServer
```

Integration tests require `.env` for Cloud.
Server tests use Dockerized Jira Data Center and can be slow.

## Coding Rules

- Follow existing cmdlet patterns: public cmdlet -> `Invoke-JiraMethod` -> private converter or resolver.
- Prefer small, focused changes that preserve backward compatibility.
- Use approved PowerShell verbs, PascalCase function/parameter names, and descriptive variable names.
- Parameter validation and transformation belong at binding boundaries; business invariants belong in cmdlet bodies.
- For argument transformers, return input unchanged only when competing pipeline parameter sets need binder fallthrough.
- Throw actionable `ArgumentTransformationMetadataException` errors when no alternate parameter set should bind.
- Do not hardcode server URLs; use the configured Jira server state.
- Do not mix Pester 4 and Pester 5 syntax in the same new or heavily edited test.
- Do not commit generated `Release/` content.

## Comments And Help

- Comments are a last resort; prefer clear names and structure.
- Comment only non-obvious API behavior, constraints, design decisions, or justified suppressions.
- Use `#ToDo:Category` with a specific reason; common categories are `CustomClass`, `Deprecate`, `Implement`, and `Refactor`.
- Remove dead code instead of commenting it out.
- Public cmdlet help lives in `docs/en-US/commands/*.md`; public function files should only contain the external-help directive.
- Private functions may use minimal comment-based help when it adds clarity.

## Documentation Style

- Markdown uses one sentence per line.
- Preserve code fences, YAML frontmatter, and generated metadata blocks.
- Updating public behavior usually requires `CHANGELOG.md` and cmdlet help updates.

## CI And Release Notes

- Branch protection should require only `CI / CI Result`.
- `ci.yml` skips expensive jobs for docs/instruction-only changes while still emitting `CI Result`.
- Smoke tests gate first-party PRs and pushes but skip when secrets are unavailable for forks or Dependabot.
- Releases are tag based from `master`; release details live in `.github/ai-context/releasing.md`.

## Backlog Handling

- Do not expand the current PR with unrelated findings.
- File durable follow-ups as `Backlog` issues on the JiraPS backlog project.
- Include context, proposal, trade-offs, and related PR or transcript links when filing.

## Tool Entry Points

- GitHub Copilot: `.github/copilot-instructions.md`
- Cursor: `.cursor/rules/jiraps.mdc`
- Claude Code: `CLAUDE.md`
- Antigravity: `GEMINI.md`
- Keep entry points short and route detailed guidance back here or to `.github/ai-context/`.
