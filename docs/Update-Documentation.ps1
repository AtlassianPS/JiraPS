# Configuration
$moduleName = 'JiraPS'
$docsFolder = 'docs'
$locale = 'en-US'

# determin parameters
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
$docsPath = (Join-Path -Path $moduleRoot -ChildPath $docsFolder)
$modulePath = (Join-Path -Path $moduleRoot -ChildPath $moduleName)

if(-not ((Test-Path $docsPath) -and (Test-Path $modulePath))){
	throw "Repository structure does not look OK"
} else {
	if (Get-Module -ListAvailable -Name platyPS) {
		# Import modules
		Import-Module platyPS
		Import-Module $modulePath -Force

		# Generate markdown and external help (Will overwrite existing)
		New-MarkdownHelp -Module $moduleName -OutputFolder $docsPath -Locale $locale -Force
		New-ExternalHelp -Path $docsPath -OutputPath (Join-Path -Path $modulePath -ChildPath $locale) -Force
	} else {
		Write-Error -Message "You require the platyPS module to generate new documentation"
	}
}
