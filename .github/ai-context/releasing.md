# Releasing JiraPS

This document covers the release process for JiraPS.
The release workflow is tag based and promotes the CI artifact from the exact commit that was tagged.
Release notes are extracted once from `CHANGELOG.md` and reused for both the GitHub release body and the PSGallery manifest `PrivateData.PSData.ReleaseNotes`.

## Files to Update

> Examples below use `X.Y.Z` as a placeholder for the version being released
> (e.g. substitute `3.0.0` or `3.0.1`).

| File | What to Change |
|------|----------------|
| `CHANGELOG.md` | Add release entry matching the tag: `## vX.Y.Z - YYYY-MM-DD` |
| `JiraPS/JiraPS.psd1` | Update `ModuleVersion` (e.g., `'X.Y.Z'`) |

## Changelog Format

- **Header format**: `## vX.Y.Z - YYYY-MM-DD` (matches the annotated release tag)
- **Sections**: `### Added`, `### Changed`, `### Fixed`
- **Content**: User-facing summary — consolidate beta entries, omit internal details (test cleanup, private functions)
- **Beta consolidation**: When releasing after betas, squash beta changelogs into one release entry; beta details remain in GitHub Releases

The release notes parser preserves the entire body under the matching `##` heading until the next `##` heading.
Introductory paragraphs before `###` sections are supported and are included in both PSGallery and GitHub release notes.

## Pre-Release Verification

```powershell
# ALWAYS run before pushing release commits
Invoke-Build -Task Build, Test

# Optional local release packaging preflight; CI runs this in the build job
Invoke-Build -Task TestPublish

# Release metadata preflight for the target tag
Invoke-Build -Task Build, SetVersion -VersionToPublish vX.Y.Z
```

## Release Workflow

```powershell
git checkout master && git pull origin master

# Edit CHANGELOG.md (add release section) and JiraPS/JiraPS.psd1 (update ModuleVersion)

Invoke-Build -Task Build, Test
Invoke-Build -Task Build, SetVersion -VersionToPublish vX.Y.Z

git add CHANGELOG.md JiraPS/JiraPS.psd1
git commit -m "Release vX.Y.Z"

# Tags use the v prefix and trigger release.yml
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin master --tags
```

## Versioning Pattern

| Release Type | Tag example | Changelog example | Manifest example |
|--------------|-------------|-------------------|------------------|
| Minor release | `v3.1.0` | `## v3.1.0 - YYYY-MM-DD` | `'3.1.0'` |
| Patch release | `v3.0.1` | `## v3.0.1 - YYYY-MM-DD` | `'3.0.1'` |
| Pre-release | `v3.1.0-beta` | `## v3.1.0-beta - YYYY-MM-DD` | `'3.1.0'` + `Prerelease = 'beta'` |

- **Tags and changelog headings use the same `v`-prefixed version**
- **Use three-part versions** for release tags, changelog headings, and module manifests
- **Release workflow triggers on**: `v*` annotated tags
- **Release workflow verifies**: the tag is annotated and points to a commit reachable from `origin/master`
- **Release workflow downloads**: the `Release` artifact built by CI for the tagged commit
- **Release workflow writes**: GitHub release notes with `AtlassianPS.Standards/.github/actions/build-release-notes`
- **Publish task writes**: PSGallery manifest release notes with `Get-AtlassianPSReleaseNotesFromChangelog`

## Common Mistakes

- ❌ Releasing from a feature branch — always release from `master`
- ❌ Forgetting to run tests before pushing
- ❌ Using a changelog heading that differs from the tag (for example `## 3.0.0` for tag `v3.0.0`)
- ❌ Creating tag without `-a -m` (requires annotated tag message)
- ❌ Pushing tag before pushing commit
- ❌ Creating duplicate tags (for example both `v3.0` and `v3.0.0`) — causes duplicate workflow runs
- ❌ Editing release notes after publishing to PSGallery — published package metadata is immutable

## What Happens After Tag Push

- `release.yml` workflow triggers automatically
- Validates the annotated tag and master ancestry
- Downloads the CI `Release` artifact for the tagged commit
- Builds `Release/release-notes.md` from the matching changelog section
- Publishes module to PowerShell Gallery
- Creates GitHub Release with the same changelog text used for manifest release notes
- If workflow fails but PSGallery publish succeeded, the version is taken

## Recovery Procedures

```powershell
# Check existing tags before creating
git tag -l 'v2.*'

# Delete accidental tag (local + remote) BEFORE it publishes
git tag -d vX.Y
git push origin --delete vX.Y

# Create GitHub Release manually if workflow failed
gh release create vX.Y.Z --title "vX.Y.Z" --notes "$(cat <<'EOF'
... changelog section body ...
EOF
)"
```

**Note**: Once published to PSGallery, that version number is permanently taken. You cannot re-publish the same version.
