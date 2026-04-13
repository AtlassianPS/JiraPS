---
applyTo: "**/*.ps1"
---

# PowerShell File Rules (GitHub Copilot)

This file applies to all `.ps1` files. It references shared rules.

**Canonical source**: [.github/ai-context/powershell-rules.md](../ai-context/powershell-rules.md)

## Quick Reference

1. **Cloud AND Data Center** — all changes must work on both Jira deployment types
2. **User Identity** — `accountId` for Cloud, `username`/`name` for DC
3. **ADF** — only use `ConvertTo-ADF`/`ConvertFrom-ADF` for Cloud
4. **REST calls** — always go through `Invoke-JiraMethod`
5. **Tests required** — every function needs `.Unit.Tests.ps1`

For full rules, read `.github/ai-context/powershell-rules.md`.
