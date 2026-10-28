# Candidate releases

The Continuous Release workflow delegates alpha and beta releases to the pinned
Standards workflow. Dispatch from protected `master`, choose the release impact,
and select `release_channel=alpha` or `beta`. The planner calculates the version.
Set `prerelease_branch` to package another repository branch before merging,
or leave it empty to use `master`. The dispatch stays on `master` and the release
environment retains its branch restriction. Builds, tests, the ledger, and the
release tag use one resolved source commit. Stable releases reject this input;
merge the changes into `master` before publishing stable.
For a major numeric base, enter fresh confirmation in `major_authorization` as
`AtlassianPS/JiraPS vMAJOR`.

Candidate CI runs the required platform tests and configured smoke checks, verifies
the full version and archive, then promotes the same artifact through the protected
release environment. Candidates keep the existing Gallery module name and use a
GitHub prerelease. Stable release notes remain under `Unreleased` on `master`.

Select `stable` after reviewing candidate results and merging fixes. Stable CI
validates a new final package with an empty prerelease label. Rerun failed jobs for
transient publication failures while the original artifact exists. Fix lasting
failures in a reviewed PR and dispatch a new version; never replace a tag or package.

Use stable provisioning by default. Explicit candidate dependencies require a
released Standards version exporting `Install-AtlassianPSModuleCandidate` and the
installer's `CandidateRequirement` option. Keep exact full candidate selections
separate from numeric runtime minimum/maximum bounds. Local archives require SHA256
verification and an isolated root; changing candidates requires a fresh process.

The temporary JiraPS/Configuration helpers remain until
the shared replacements pass acquisition and Cloud/Data Center integration tests
and a compatible stable Configuration prerequisite is available. Preserve published
packages, verification ledgers, and disposable configuration storage during cleanup.

See the [shared ReleaseBlueprint](https://github.com/AtlassianPS/AtlassianPS.Standards/blob/master/docs/ReleaseBlueprint.md)
for ordering, operator steps, provisioning examples, and recovery rules.
