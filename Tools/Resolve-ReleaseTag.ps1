param(
    [Parameter(Mandatory)]
    [string] $ReleaseTag,

    [string] $OutputPath = $env:GITHUB_OUTPUT
)

$ErrorActionPreference = 'Stop'

if ($ReleaseTag -notmatch '^v[0-9]+(\.[0-9]+){1,2}([-.][0-9A-Za-z][0-9A-Za-z.-]*)?$') {
    throw "Release tag '$ReleaseTag' does not match the expected v-prefixed version pattern."
}

git show-ref --verify --quiet "refs/tags/$ReleaseTag"
if ($LASTEXITCODE -ne 0) {
    throw "Release ref '$ReleaseTag' is not a tag."
}

$tagType = git cat-file -t "refs/tags/$ReleaseTag"
if ($tagType -ne 'tag') {
    throw "Release tag '$ReleaseTag' must be an annotated tag."
}

git fetch --no-tags origin master
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to fetch origin/master.'
}

$releaseSha = git rev-list -n 1 $ReleaseTag
if (-not $releaseSha) {
    throw "Could not resolve commit for release tag '$ReleaseTag'."
}

git merge-base --is-ancestor $releaseSha 'origin/master'
if ($LASTEXITCODE -ne 0) {
    throw "Release tag '$ReleaseTag' does not point to a commit reachable from origin/master."
}

if ($OutputPath) {
    @(
        "release_tag=$ReleaseTag"
        "release_version=$($ReleaseTag.TrimStart('v'))"
        "release_sha=$releaseSha"
    ) | Add-Content -LiteralPath $OutputPath -Encoding UTF8
}
