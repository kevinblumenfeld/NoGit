function Get-NoGitHubRepoRecursiveContents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Url,

        [string]
        $RelativePath = '',

        [Parameter(Mandatory)]
        [hashtable]
        $Headers,

        [Parameter(Mandatory)]
        [string]
        $TargetDir,

        [Parameter(Mandatory)]
        [string]
        $Branch
    )

    try {
        $items = Invoke-RestMethod -Uri $Url -Headers $Headers -ErrorAction Stop -Verbose:$false
        $count = @($items).Count
        Write-Verbose "Fetching: $Url ($count item(s))"
    }
    catch {
        Write-Error "Error fetching contents from: $Url - $($_.Exception.Message)"
        $script:FailCount++
        return
    }

    foreach ($item in $items) {
        $ItemPath = if ($RelativePath) { "$RelativePath\$($item.name)" } else { $item.name }

        if ($item.type -eq 'file') {
            $DownloadUrl = $item.download_url
            $OutputPath = Join-Path -Path $TargetDir -ChildPath $ItemPath
            $OutputDir = Split-Path -Path $OutputPath -Parent

            try {
                if (-not (Test-Path -Path $OutputDir)) {
                    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
                }

                Invoke-WebRequest -Uri $DownloadUrl -Headers $Headers -OutFile $OutputPath -ErrorAction Stop -Verbose:$false
                Write-Verbose "Downloaded: $ItemPath"
                $script:SuccessCount++
            }
            catch {
                Write-Error "Failed: $ItemPath - $($_.Exception.Message)"
                $script:FailCount++
            }
        }
        elseif ($item.type -eq 'dir') {
            $UrlForItem = if ($item.url -like '*?ref=*') { $item.url } else { "$($item.url)?ref=$Branch" }

            $childParams = @{
                Url          = $UrlForItem
                RelativePath = $ItemPath
                Headers      = $Headers
                TargetDir    = $TargetDir
                Branch       = $Branch
            }

            Get-NoGitHubRepoRecursiveContents @childParams
        }
    }
}
