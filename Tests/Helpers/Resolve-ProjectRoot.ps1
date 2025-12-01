function Resolve-ProjectRoot {
    $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath "../.."

    if (-not (Test-Path "$projectRoot/LICENSE")) {
        $projectRoot = Join-Path -Path $projectRoot -ChildPath ".."
    }

    $projectRoot
}
