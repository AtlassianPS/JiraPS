# Releasing JiraPS

JiraPS uses the shared AtlassianPS continuous-delivery workflow.
CI creates and validates the publishable artifact without release credentials, and the release job promotes that exact artifact after CI succeeds.

## Current v3 rollout guard

JiraPS has a large unreleased `v3.0.0` change set on `master`.
Do not enable automatic releases before that version is intentionally published.

- Keep the repository variable `JIRAPS_CD_ENABLED` unset or set to `false` until the prepared v3 release commit and its CI artifact have been reviewed.
- Do not create a release tag manually.
- Do not manually dispatch `Continuous Release` as part of the CD implementation PR.
- When the v3 release is approved, manually dispatch `Continuous Release` with `major` to prepare `v3.0.0` from the full `Unreleased` changelog.
- Let CI finish while the gate remains disabled, then review the prepared commit and its release artifact.
- Set `JIRAPS_CD_ENABLED=true` and rerun CI for the prepared release commit; the successful rerun publishes that exact artifact.
- Verify PSGallery and the GitHub release, then leave the variable enabled for normal post-merge releases.

Before enabling publication, configure the `release` environment for protected `master`, protect
`refs/tags/v*` so only the `atlassianps-release-bot` App can create or change release tags, and require
both `CI Result` and `Release Intent` on `master`.

## Pull request contract

Every pull request must declare exactly one release impact:

- `release:none`
- `release:patch`
- `release:minor`
- `release:major`

A releasing pull request also needs one `changelog:*` label or a reviewed fragment named:

```text
.changelog/<pr-number>.<patch|minor|major>.<added|changed|fixed|removed|deprecated|security|breaking>.md
```

Use `release:none` for internal changes that should not independently trigger a package release.
It does not remove their code from the next release.
For an uncommon batched release, keep automatic release disabled, record the combined notes under
`Unreleased`, and use `release:none` on the held PRs until the maintainer deliberately prepares the batch.

## Changelog contract

- Keep pending release notes under `## Unreleased`.
- Release headings use `## vX.Y.Z - YYYY-MM-DD`.
- Prefer `### Added`, `### Changed`, `### Fixed`, `### Deprecated`, `### Removed`, `### Security`, and `### Breaking` for generated fragments.
- Keep the detailed v3 migration guidance and breaking-change notes in `Unreleased` until the major release is prepared.

The release preparation job moves the complete `Unreleased` body into the planned version section.
That section is used for both the GitHub release and the PSGallery manifest `PrivateData.PSData.ReleaseNotes`.

## Release flow

1. `Release Intent` validates the pull request labels and optional changelog fragment.
2. `CI` builds, tests, packages, and validates the module.
3. When automatic release is enabled, `Continuous Release` reconciles merged intent after successful `master` CI.
4. The release bot commits the versioned changelog and exact source manifest version.
5. CI builds and verifies the final release candidate.
6. The publisher downloads that exact artifact, creates an annotated tag, publishes to PSGallery, creates the GitHub release, and notifies the website.

## Validation

Run the full gate before merging release changes:

```powershell
Invoke-Build -Task Build, Test
```

For a prepared release candidate, also run:

```powershell
Invoke-Build -Task Build, SetVersion, VerifyReleaseArtifact -VersionToPublish vX.Y.Z
```

## Recovery

Rerun failed jobs for transient failures while the original CI artifact remains available.
For lasting failures, merge a reviewed fix and release the next version.
Never delete or move an existing release tag, and never attempt to republish an immutable PSGallery version.
