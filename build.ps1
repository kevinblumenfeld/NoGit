<#
.SYNOPSIS
    Build script for the NoGit PowerShell module using ModuleBuilder.
#>

param (
    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Release'
)

# Determine paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ModuleDir = Join-Path $ScriptDir 'module\NoGit'
$ManifestFile = Join-Path $ModuleDir 'NoGit.psd1'

# Verify manifest exists
if (-not (Test-Path $ManifestFile)) {
    Write-Error "Module manifest not found at $ManifestFile"
    exit 1
}

# Get version from manifest
$manifestData = Import-PowerShellDataFile $ManifestFile
if (-not $manifestData.ModuleVersion -or $manifestData.ModuleVersion -eq '') {
    Write-Error "ModuleVersion not set in manifest $ManifestFile"
    exit 1
}
$version = [string]$manifestData.ModuleVersion
Write-Host "Building NoGit version $version..."

# Ensure ModuleBuilder is installed
if (-not (Get-Module -ListAvailable -Name ModuleBuilder)) {
    Write-Host "Installing ModuleBuilder..."
    Install-Module ModuleBuilder -Force -Scope CurrentUser -AllowClobber
}
Import-Module ModuleBuilder -Force

# Prepare output directory
$OutputDir = Join-Path $ModuleDir 'Output'
if (Test-Path $OutputDir) {
    Remove-Item $OutputDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Build the module
$buildResult = Build-Module -Path $ManifestFile -OutputDirectory $OutputDir -Version $version -ErrorAction Stop
Write-Host "Module built at: $($buildResult.Path)"

# (Optional) Test stub
Write-Host "Running tests (stub)..."
# Example:
# Invoke-Pester -Path "$ModuleDir\Tests" -OutputFormat NUnitXml -OutputFile "TestResults.xml"
