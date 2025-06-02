function Get-NoGitHubRepoContents {
    <#
    .SYNOPSIS
    Recursively downloads the contents of a GitHub repository to a local directory using the GitHub REST API.

    .DESCRIPTION
    Get-NoGitHubRepoContents uses a personal access token (PAT) to authenticate against GitHub and retrieve all files 
    and folders from a given repository. The content is downloaded recursively and saved to a local folder. 

    .EXAMPLE
    Get-NoGitHubRepoContents -Token 'abc' -Owner 'kevinblumenfeld' -Repo 'PS7' -TargetDir 'C:\Temp\PS7'
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
