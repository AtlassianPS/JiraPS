# Licensing history

JiraPS was originally distributed under the GNU General Public License.
Commit [`e1239bd6`](https://github.com/AtlassianPS/JiraPS/commit/e1239bd6)
updated the project from GPLv2 to GPLv3 on 20 August 2016.

Commit [`d4352777`](https://github.com/AtlassianPS/JiraPS/commit/d4352777)
changed the repository license from GPLv3 to MIT on 5 October 2017.
The available public project history does not document permission from all
contributors whose GPL-era work may have been included in that change.

The project is auditing those contributions and collecting public consent in
[issue #706](https://github.com/AtlassianPS/JiraPS/issues/706).

## Current-code provenance audit

The current branch was audited at commit `da1c4e85` with
`git blame --line-porcelain -C -C HEAD` for every tracked file.
Only current lines attributed to commits made before the MIT change were retained.
The copy and move detection options help preserve attribution when text moved between files.

This method excludes deleted work and current lines attributed to later independent rewrites.
It is a provenance lower bound rather than a legal conclusion: Git may not recognize heavily
modified derivative work, and line counts do not measure copyright significance.

The audit found 4,549 current lines in 177 files, attributed to 114 pre-MIT commits and
10 consolidated contributors.

| Contributor | Current lines | Files | Commits |
|---|---:|---:|---:|
| Oliver Lipkau | 2,632 | 148 | 36 |
| Joshua Taliaferro | 1,530 | 115 | 62 |
| Liam Leane | 126 | 4 | 1 |
| Josh Knorr | 72 | 8 | 3 |
| Eugene Bekker | 61 | 5 | 2 |
| Joe Beaudry | 56 | 4 | 4 |
| Axel Gluth | 42 | 4 | 2 |
| Neil Padgham | 20 | 2 | 1 |
| Michael Dejulia | 6 | 2 | 2 |
| Brian Bunke | 4 | 1 | 1 |

| Area | Current lines | Files |
|---|---:|---:|
| Module source and manifests | 2,031 | 107 |
| Tests | 2,286 | 58 |
| Documentation | 154 | 4 |
| Other repository files | 78 | 8 |

The preliminary inventory in issue #706 also named Tomas Deceuninck, ThePSAdmin, and kittholland.
No current line was attributed to a pre-MIT commit by those identities.

Multiple historical commit identities for Joshua Taliaferro and Joe Beaudry were consolidated.
The published data deliberately omits email addresses.
The exact file and line ranges, authors, commits, author dates, and commit subjects are recorded in
[`LICENSING-PROVENANCE.tsv`](LICENSING-PROVENANCE.tsv).

Until that audit is complete, the current MIT license should not be interpreted
as proof that every surviving pre-5-October-2017 contribution was validly
relicensed.
