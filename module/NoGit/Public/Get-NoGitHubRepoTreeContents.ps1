function Get-NoGitHubRepoTreeContents {
    <#
    .SYNOPSIS
        Downloads files from a GitHub repository using the Git Trees API.

    .DESCRIPTION
        Uses the Git Trees API to recursively traverse a repository tree
        and download all blob (file) entries to a local directory.

        Handles SHA resolution, recursive trees, blob retrieval, and writes
        file contents to disk. Skips directories and submodules.

    .PARAMETER Token
        The GitHub Personal Access Token (PAT).

    .PARAMETER Owner
        The repository owner (user or organization).

    .PARAMETER Repo
        The name of the repository.

    .PARAMETER Branch
        The branch to download (default: main).

    .PARAMETER TargetDir
        Directory to save the files to.

    .EXAMPLE
        Get-NoGitHubRepoTreeContents -Token 'abc' -Owner 'octocat' -Repo 'Hello-World' -TargetDir './repo'
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

        [Parameter()]
        [string] 
        $Branch = 'main',

        [Parameter(Mandatory)]
        [string]
        $TargetDir
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $headers = @{
        Authorization = "token $Token"
        'User-Agent'  = 'NoGit'
        Accept        = 'application/vnd.github+json'
    }

    if (-not (Test-Path -Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    # Step 1: Get commit SHA from branch reference
    $refUrl = "https://api.github.com/repos/$Owner/$Repo/git/refs/heads/$Branch"
    try {
        $refResponse = Invoke-RestMethod -Uri $refUrl -Headers $headers
        $commitUrl = $refResponse.object.url
    }
    catch {
        Write-Error "Failed to resolve branch '$Branch'. Verify that it exists."
        return
    }

    # Step 2: Get commit object to find tree SHA
    $commitResponse = Invoke-RestMethod -Uri $commitUrl -Headers $headers
    $treeSha = $commitResponse.tree.sha

    # Step 3: Get tree recursively
    $treeUrl = "https://api.github.com/repos/$Owner/$Repo/git/trees/${treeSha}?recursive=1"
    $treeResponse = Invoke-RestMethod -Uri $treeUrl -Headers $headers

    if ($treeResponse.truncated -eq $true) {
        Write-Warning "Tree listing was truncated. Not all files may be downloaded."
    }

    $script:SuccessCount = 0
    $script:FailCount = 0

    foreach ($entry in $treeResponse.tree) {
        if ($entry.type -ne 'blob') { continue }

        $outputPath = Join-Path -Path $TargetDir -ChildPath $entry.path
        $outputDir = Split-Path -Path $outputPath -Parent

        if (-not (Test-Path -Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        try {
            $blobUrl = "https://api.github.com/repos/$Owner/$Repo/git/blobs/$($entry.sha)"
            $blobHeaders = $headers.Clone()
            $blobHeaders['Accept'] = 'application/vnd.github.v3.raw'

            Invoke-WebRequest -Uri $blobUrl -Headers $blobHeaders -OutFile $outputPath -Verbose:$false
            Write-Verbose "Downloaded: $($entry.path)"
            $script:SuccessCount++
        }
        catch {
            Write-Error "Failed to download: $($entry.path) - $_"
            $script:FailCount++
        }
    }

    $stopwatch.Stop()

    $elapsed = $stopwatch.Elapsed
    $formattedTime = '{0:D2}:{1:D2}:{2:D2}' -f $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds

    Write-Verbose "--- Summary for $Owner/$Repo ---"
    Write-Verbose ("Success   : {0}" -f $script:SuccessCount)
    Write-Verbose ("Fail      : {0}" -f $script:FailCount)
    Write-Verbose ("OutputDir : {0}" -f $TargetDir)
    Write-Verbose ("Elapsed   : {0}" -f $formattedTime)
    
}
