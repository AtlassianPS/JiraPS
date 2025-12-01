function Resolve-ModuleSource {
    $actualPath = Resolve-Path $PSScriptRoot

    # we expect $env:BH* to be empty when `Invoke-Build` is not used
    if (
        (Test-Path "$env:BHBuildOutput") -and
        ($actualPath -like "$(Resolve-Path $env:BHBuildOutput)/Tests/*")
    ) {
        Join-Path -Path $env:BHBuildOutput -ChildPath "JiraPS/JiraPS.psd1"
    }
    else {
        if ($actualPath -like "*/Functions/*.ps1") {
            Join-Path -Path $PSScriptRoot -ChildPath "../../../JiraPS/JiraPS.psd1"
        }
        else {
            Join-Path -Path $PSScriptRoot -ChildPath "../../JiraPS/JiraPS.psd1"
        }
    }
}
