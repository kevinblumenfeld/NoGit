function Get-NoGitHubRepoContents {
    <#
    .SYNOPSIS
    Recursively downloads the contents of a GitHub repository to a local directory using the GitHub REST API.

    .DESCRIPTION
    This function connects to the GitHub API and performs a breadth-first traversal of the specified repository
    and branch. It downloads each file to a local directory, preserving folder structure. A typed queue is used
    instead of recursion for safe and scalable folder traversal.

    .PARAMETER Token
    GitHub personal access token for authentication.

    .PARAMETER Owner
    GitHub username or organization name.

    .PARAMETER Repo
    Name of the GitHub repository.

    .PARAMETER Branch
    Optional. Branch to download from. Defaults to 'main'.

    .PARAMETER TargetDir
    Local directory path to save downloaded content.

    .EXAMPLE
    Get-NoGitHubRepoContents -Token 'ghp_...' -Owner 'octocat' -Repo 'Hello-World' -TargetDir 'C:\Git\Hello' -Verbose
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Token,

        [Parameter(Mandatory)]
        [string] $Owner,

        [Parameter(Mandatory)]
        [string] $Repo,

        [string] $Branch = 'main',

        [Parameter(Mandatory)]
        [string] $TargetDir
    )

    # Start a timer to measure execution time
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Set up GitHub API request headers
    $headers = @{
        Authorization = "token $Token"
        'User-Agent'  = $Owner
    }

    # Ensure target directory exists
    if (-not (Test-Path -Path $TargetDir)) {
        try {
            New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
            Write-Verbose "Created directory: $TargetDir"
        }
        catch {
            Write-Error "Failed to create directory: $TargetDir - $($_.Exception.Message)"
            return
        }
    }

    # Initialize counters for success and failure
    $SuccessCount = 0
    $FailCount = 0

    # Initialize a strongly typed queue for BFS directory traversal
    $queue = [System.Collections.Generic.Queue[PSObject]]::new()
    $queue.Enqueue([PSCustomObject]@{
            Url     = "https://api.github.com/repos/$Owner/$Repo/contents?ref=$Branch"
            RelPath = ''
        })

    # Process directories and files in a breadth-first manner
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()

        try {
            $items = Invoke-RestMethod -Uri $current.Url -Headers $headers -ErrorAction Stop -Verbose:$false
            Write-Verbose "Fetched: $($current.Url) ($(@($items).Count) item(s))"
        }
        catch {
            Write-Error "Failed to fetch: $($current.Url) - $($_.Exception.Message)"
            $FailCount++
            continue
        }

        foreach ($item in $items) {
            $path = if ($current.RelPath) {
                Join-Path -Path $current.RelPath -ChildPath $item.name
            }
            else {
                $item.name
            }
        
            if ($item.type -eq 'dir') {
                $nextUrl = if ($item.url -like '*?ref=*') { $item.url } else { "$($item.url)?ref=$Branch" }
                $queue.Enqueue([PSCustomObject]@{
                        Url     = $nextUrl
                        RelPath = $path
                    })
                continue
            }
        
            # Are there any other item types?
            if ($item.type -ne 'file') {
                continue
            }

            $outPath = Join-Path $TargetDir $path
            $outDir = Split-Path $outPath -Parent

            try {
                if (-not (Test-Path $outDir)) {
                    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
                }

                Invoke-WebRequest -Uri $item.download_url -Headers $headers -OutFile $outPath -ErrorAction Stop -Verbose:$false
                Write-Verbose "Downloaded: $path"
                $SuccessCount++
            }
            catch {
                Write-Error "Failed to download: $path - $($_.Exception.Message)"
                $FailCount++
            }
        }
    }

    # Stop the timer and show summary
    $stopwatch.Stop()
    $elapsed = $stopwatch.Elapsed
    $formattedTime = '{0:D2}:{1:D2}:{2:D2}' -f $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds

    Write-Verbose "--- Summary for $Owner/$Repo ---"
    Write-Verbose ("Success   : {0}" -f $SuccessCount)
    Write-Verbose ("Fail      : {0}" -f $FailCount)
    Write-Verbose ("OutputDir : {0}" -f $TargetDir)
    Write-Verbose ("Elapsed   : {0}" -f $formattedTime)
}
