function Get-NoGitHubRepoTreeContents { 
    <#
    .SYNOPSIS
        Downloads files from a GitHub repository using the Git Trees API.

    .DESCRIPTION
        Uses the Git Trees API to recursively traverse a repository tree
        and download all blob (file) entries to a local directory.

        The -SourcePath parameter specifies where within the repository to begin copying.
        Only files under this path are downloaded, and the SourcePath itself is removed
        from the output folder structure. Subfolders under SourcePath are preserved.

        Handles SHA resolution, recursive trees, blob retrieval, and writes
        file contents to disk. Skips directories and submodules.

    .PARAMETER Token
        The GitHub Personal Access Token (PAT).

        Use a fine-grained personal access token with `repo contents:read` permission:
        https://github.com/settings/personal-access-tokens

    .PARAMETER Owner
        The repository owner (user or organization).

    .PARAMETER Repo
        The name of the repository.

    .PARAMETER Branch
        The branch to download (default: main).

    .PARAMETER TargetDir
        Directory to save the files to.

    .PARAMETER SourcePath
        The folder or path within the repository to start copying from.

        - Acts as a starting point filter.
        - Downloads all files and subfolders under this path, recursively.
        - The SourcePath folder itself is not included in your local output – only its contents and subfolders are preserved.

        For example:
            If SourcePath is 'Build/DTect' and TargetDir is 'C:\Temp\DTect',
            then a file at 'Build/DTect/0.0.637/file.psd1' in the repo will be saved as:
                'C:\Temp\DTect\0.0.637\file.psd1'

        Note:
            Any directory path in the repository that matches SourcePath will be downloaded.

        This is useful when you want to extract specific folders or modules from a repository
        without keeping their entire parent folder structure.

    .EXAMPLE
        Get-NoGitHubRepoTreeContents -Token 'abc' -Owner 'octocat' -Repo 'Hello-World' -TargetDir './repo' -SourcePath 'Build/DTect'

    .NOTES
        Use Get-NoGitHubRepoTreeContents when working with repositories that:

        - Contain directories with large numbers of files (over 1000), where the standard Contents API may truncate results.
        - Require efficient retrieval and fine-grained filtering of specific subfolders and their contents.

        This approach ensures reliable downloads without missing files due to API listing limits.

        For more details and examples, see:
        https://github.com/kevinblumenfeld/NoGit

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
        $TargetDir,

        [string[]]
        $SourcePath
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

        # 🔹 Only process paths matching SourcePath if specified
        if ($SourcePath -and (-not ($SourcePath | ForEach-Object { $entry.path -like "$_*" }))) {
            continue
        }

        # 🔹 Strip SourcePath prefix from path before joining with TargetDir
        $relativePath = $entry.path
        foreach ($src in $SourcePath) {
            if ($relativePath -like "$src*") {
                $relativePath = $relativePath.Substring($src.Length).TrimStart('/', '\')
                break
            }
        }

        $outputPath = Join-Path -Path $TargetDir -ChildPath $relativePath
        $outputDir = Split-Path -Path $outputPath -Parent

        if (-not (Test-Path -Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        try {
            $blobUrl = "https://api.github.com/repos/$Owner/$Repo/git/blobs/$($entry.sha)"
            $blobHeaders = $headers.Clone()
            $blobHeaders['Accept'] = 'application/vnd.github.v3.raw'

            Invoke-WebRequest -Uri $blobUrl -Headers $blobHeaders -OutFile $outputPath -Verbose:$false
            Write-Verbose "Downloaded: $($entry.path) -> $relativePath"
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
