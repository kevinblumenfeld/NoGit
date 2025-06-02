function Get-NoGitHubRepoContents {
    <#
    .SYNOPSIS
    Recursively downloads the contents of a GitHub repository to a local directory using the GitHub REST API.

    .DESCRIPTION
    This function connects to GitHub using a personal access token (PAT) to authenticate and recursively downloads all 
    files and folders from a specified repository and branch. It supports downloading the entire content tree of the 
    repository and saves it to a designated local directory.

    It uses GitHub's REST API (`/repos/:owner/:repo/contents`) to fetch files and handles directories by recursion.

    .PARAMETER Token
    A GitHub Personal Access Token (PAT) with appropriate repository access permissions. 
    This token is used for authentication with the GitHub API.

    You can create a token at: https://github.com/settings/tokens

    .PARAMETER Owner
    The username or organization name that owns the GitHub repository. 
    This is part of the GitHub repository URL. For example:

        GitHub URL: https://github.com/microsoft/PowerToys
                                       ^^^^^^^^^
                                       This is the Owner

    .PARAMETER Repo
    The name of the repository to download contents from. 
    This is also part of the GitHub repository URL. For example:

        GitHub URL: https://github.com/microsoft/PowerToys
                                                 ^^^^^^^^
                                                 This is the Repo

    .PARAMETER Branch
    (Optional) The name of the branch to download from. 
    Defaults to 'main' if not specified.

    .PARAMETER TargetDir
    The local directory path where the contents of the GitHub repository will be downloaded. 
    If the directory does not exist, it will be created.

    .EXAMPLE
    Get-NoGitHubRepoContents -Token 'ghp_xxx' -Owner 'microsoft' -Repo 'PowerToys' -TargetDir 'C:\Repos\PowerToys'

    Downloads the contents of the `PowerToys` repository from the `microsoft` organization on the `main` branch and saves them into `C:\Repos\PowerToys`.

    .EXAMPLE
    Get-NoGitHubRepoContents -Token 'ghp_abc' -Owner 'kevinblumenfeld' -Repo 'PS7' -Branch 'dev' -TargetDir 'D:\Temp\PS7Dev'

    Downloads the contents of the `PS7` repository from the `kevinblumenfeld` account on the `dev` branch into `D:\Temp\PS7Dev`.

    .NOTES
    Author: Your Name
    Required: PowerShell 7.0+
    GitHub API Rate Limits apply (even for authenticated requests). For large repositories, use cautiously.

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Token,

        [Parameter(Mandatory)]
        [string]
        $Owner,

        [Parameter(Mandatory)]
        [string]
        $Repo,

        [string]
        $Branch = 'main',

        [Parameter(Mandatory)]
        [string]
        $TargetDir
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $headers = @{
        Authorization = "token $Token"
        'User-Agent'  = $Owner
    }

    if (-not (Test-Path -Path $TargetDir)) {
        try {
            New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
            Write-Verbose "Created directory: $TargetDir"
        }
        catch {
            Write-Error ("Failed to create directory: $TargetDir - {0}" -f $_.Exception.Message)
            return
        }
    }

    $script:SuccessCount = 0
    $script:FailCount = 0

    $ApiUrl = "https://api.github.com/repos/$Owner/$Repo/contents"
    $initialParams = @{
        Url       = "${ApiUrl}?ref=${Branch}"
        Headers   = $headers
        TargetDir = $TargetDir
        Branch    = $Branch
    }

    Get-NoGitHubRepoRecursiveContents @initialParams

    $stopwatch.Stop()

    $elapsed = $stopwatch.Elapsed
    $formattedTime = '{0:D2}:{1:D2}:{2:D2}' -f $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds

    Write-Verbose "--- Summary for $Owner/$Repo ---"
    Write-Verbose ("Success   : {0}" -f $script:SuccessCount)
    Write-Verbose ("Fail      : {0}" -f $script:FailCount)
    Write-Verbose ("OutputDir : {0}" -f $TargetDir)
    Write-Verbose ("Elapsed   : {0}" -f $formattedTime)
    
}
