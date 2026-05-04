# CI Triage Runbook

Use this runbook when `.github/workflows/ci.yml` fails on a pull request.

## Quick Triage Sequence

1. Open the failing run and identify the first failed job.
2. Determine whether the failure is `Lint`, `Test` (especially Windows PowerShell 5.1), or `Smoke`.
3. Fix the root cause before rerunning, instead of rerunning first.
4. Confirm all required checks are green, including `CI Result`, before merge.

## Lint Failures

1. Read the exact PSScriptAnalyzer rule name and file path from the failed log.
2. Prefer code fixes over suppressions, and only use suppressions that match repository patterns.
3. For private helper functions that intentionally mutate state, use narrow helper-level suppressions instead of broad file-level suppressions.
4. Re-run local lint with `Invoke-Build -Task Lint` before pushing.

## Windows PowerShell 5.1 Failures

1. Treat PS5 failures as compatibility defects, not flaky noise.
2. Remember that macOS and Linux cannot run Windows PowerShell 5.1 locally.
3. Focus on known PS5-sensitive areas such as inline C# (`Add-Type`), casting behavior, and legacy parser limitations.
4. Keep C# snippets compatible with PS5 compilation constraints.
5. Push the fix and use the CI PS5 lane as the source of truth for final verification.

## Edge-Case Matrix for High-Risk Refactors

For changes in request/transport/response helpers, verify tests cover:

1. request context resolution and invalid URI branches,
2. session variable capture and restoration paths,
3. cache read and cache write branches (including non-GET behavior),
4. paging and non-paging response shapes,
5. HTTP status fallback paths when status is only present on `Exception.Response`.

## Useful Commands

```bash
gh pr checks <pr-number>
gh run view <run-id> --log-failed
gh workflow run "Integration Tests" --ref <branch> -f track=cloud
```
