@{
    PSDependOptions = @{
        Target = "CurrentUser"
    }

    InvokeBuild = "latest"
    Configuration = @{
        SkipPublisherCheck = $true
        AllowClobber = $true
        Version = "latest"
    }
    BuildHelpers = @{
        AllowClobber = $true
        Version = "latest"
    }
    Pester = "4.1.1"
    platyPS = "latest"
    PSScriptAnalyzer = "latest"
}
