# Releasing JiraPS

This document covers the release process for JiraPS.

## Files to Update

> Examples below use `X.Y` as a placeholder for the version being released
> (e.g. substitute `2.17` or `3.0`). The `v` prefix is **only** used in git tags.

| File | What to Change |
|------|----------------|
| `CHANGELOG.md` | Add release entry (no `v` prefix: `## X.Y - YYYY-MM-DD`) |
| `JiraPS/JiraPS.psd1` | Update `ModuleVersion` (e.g., `'X.Y'`) |

## Changelog Format

- **Header format**: `## X.Y - YYYY-MM-DD` (no `v` prefix, matches historical entries)
- **Sections**: `### Added`, `### Changed`, `### Fixed`
- **Content**: User-facing summary — consolidate beta entries, omit internal details (test cleanup, private functions)
- **Beta consolidation**: When releasing after betas, squash beta changelogs into one release entry; beta details remain in GitHub Releases

## Pre-Release Verification

```powershell
# ALWAYS run before pushing release commits
Invoke-Build -Task Build, Test
```

## Release Workflow

```powershell
git checkout master && git pull origin master

# Edit CHANGELOG.md (add release section) and JiraPS/JiraPS.psd1 (update ModuleVersion)

Invoke-Build -Task Build, Test

git add CHANGELOG.md JiraPS/JiraPS.psd1
git commit -m "Release vX.Y"

# Tags use the v prefix and trigger release.yml
git tag -a vX.Y -m "Release vX.Y"
git push origin master --tags
```

## Versioning Pattern

| Release Type | Tag example | Changelog example | Manifest example |
|--------------|-------------|-------------------|------------------|
| Minor release | `v2.17` | `## 2.17 - YYYY-MM-DD` | `'2.17'` |
| Patch release | `v2.17.1` | `## 2.17.1 - YYYY-MM-DD` | `'2.17.1'` |
| Pre-release | `v2.18.0-beta` | `## 2.18.0-beta - YYYY-MM-DD` | `'2.18'` + `Prerelease = 'beta'` |

- **Tags use `v` prefix**, changelog headers omit it
- **Minor releases**: 2-part version (e.g. `v2.17`) — PSGallery normalizes to `2.17.0`
- **Patch releases**: 3-part version (e.g. `v2.17.1`) — use when fixing bugs in a released version
- **Release workflow triggers on**: `v*` tags

## Common Mistakes

- ❌ Releasing from a feature branch — always release from `master`
- ❌ Forgetting to run tests before pushing
- ❌ Using `v` prefix in changelog headers (historical convention is no prefix)
- ❌ Creating tag without `-a -m` (requires annotated tag message)
- ❌ Pushing tag before pushing commit
- ❌ Creating duplicate tags (e.g., both `v2.16` and `v2.16.0`) — causes duplicate workflow runs

## What Happens After Tag Push

- `release.yml` workflow triggers automatically
- Publishes module to PowerShell Gallery
- Creates GitHub Release with changelog excerpt
- If workflow fails but PSGallery publish succeeded, the version is taken

## Recovery Procedures

```powershell
# Check existing tags before creating
git tag -l 'v2.*'

# Delete accidental tag (local + remote) BEFORE it publishes
git tag -d vX.Y
git push origin --delete vX.Y

# Create GitHub Release manually if workflow failed
gh release create vX.Y --title "vX.Y" --notes "$(cat <<'EOF'
## X.Y - YYYY-MM-DD
... changelog content ...
EOF
)"
```

**Note**: Once published to PSGallery, that version number is permanently taken. You cannot re-publish the same version.
