@{
    RootModule        = 'CodeCovio.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'fa43cf5c-e130-4dfa-8415-84f07d37efce'
    Author            = 'Mark Kraus'
    Copyright         = '2017'
    Description       = 'Module for the CodeCov.io Code Coverage Reports'
    FunctionsToExport = @(
        'Export-CodeCovIoJson'
        'Invoke-UploadCoveCoveIoReport'
    )
}
