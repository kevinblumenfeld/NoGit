# Work in progress
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$here\..\module\NoGit" -Force

Describe 'Get-NoGitHubRepoRecursiveContents' {

    BeforeEach {
        $TestDir = Join-Path $env:TEMP ("NoGitTest_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestDir | Out-Null
    }

    AfterEach {
        Remove-Item -Recurse -Force -Path $TestDir -ErrorAction SilentlyContinue
    }

    Context 'Flat files' {
        It 'downloads flat files correctly' {
            $downloadUrl = 'https://raw.githubusercontent.com/owner/repo/main/file.txt'
            $mockFile = [PSCustomObject]@{
                name         = 'file.txt'
                path         = 'file.txt'
                type         = 'file'
                download_url = $downloadUrl
            }

            Mock Invoke-RestMethod {
                param ($Uri)
                if ($Uri -like '*contents*') { return @($mockFile) }
                if ($Uri -eq $downloadUrl) { return 'mock file content' }
            }

            $params = @{
                Url       = 'https://api.github.com/repos/owner/repo/contents?ref=main'
                Headers   = @{ Authorization = 'token test'; 'User-Agent' = 'owner' }
                TargetDir = $TestDir
                Branch    = 'main'
            }

            Get-NoGitHubRepoRecursiveContents @params

            $downloadedPath = Join-Path $TestDir 'file.txt'
            Test-Path $downloadedPath | Should -BeTrue
            Get-Content $downloadedPath | Should -Be 'mock file content'
        }
    }

    Context 'Nested directories' {
        It 'recurses into subdirectories and downloads nested files' {
            $subUrl = 'https://api.github.com/repos/owner/repo/contents/folder?ref=main'
            $root = @(
                [PSCustomObject]@{
                    name = 'folder'
                    path = 'folder'
                    type = 'dir'
                    url  = $subUrl
                }
            )

            $nested = @(
                [PSCustomObject]@{
                    name         = 'nested.txt'
                    path         = 'folder/nested.txt'
                    type         = 'file'
                    download_url = 'https://raw.githubusercontent.com/owner/repo/main/folder/nested.txt'
                }
            )

            Mock Invoke-RestMethod {
                param ($Uri)
                switch ($Uri) {
                    'https://api.github.com/repos/owner/repo/contents?ref=main' {
                        return $root
                    }
                    'https://api.github.com/repos/owner/repo/contents/folder?ref=main' {
                        return $nested
                    }
                    'https://raw.githubusercontent.com/owner/repo/main/folder/nested.txt' {
                        return 'nested file content'
                    }
                }
            }

            $params = @{
                Url       = 'https://api.github.com/repos/owner/repo/contents?ref=main'
                Headers   = @{ Authorization = 'token test'; 'User-Agent' = 'owner' }
                TargetDir = $TestDir
                Branch    = 'main'
            }

            Get-NoGitHubRepoRecursiveContents @params

            $nestedPath = Join-Path $TestDir 'folder\nested.txt'
            Test-Path $nestedPath | Should -BeTrue
            Get-Content $nestedPath | Should -Be 'nested file content'
        }
    }

    Context 'API calls and headers' {
        It 'calls correct URLs with expected headers' {
            $calledUrls = @()
            $script:CapturedHeaders = $null

            Mock Invoke-RestMethod {
                param ($Uri, $Headers)
                $calledUrls += $Uri
                $script:CapturedHeaders = $Headers

                if ($Uri -like '*contents*') {
                    return @([PSCustomObject]@{
                            name         = 'file.txt'
                            path         = 'file.txt'
                            type         = 'file'
                            download_url = 'https://raw.githubusercontent.com/owner/repo/main/file.txt'
                        })
                }
                if ($Uri -like '*.txt') {
                    return 'content'
                }
            }

            $params = @{
                Url       = 'https://api.github.com/repos/owner/repo/contents?ref=main'
                Headers   = @{ Authorization = 'token test'; 'User-Agent' = 'owner' }
                TargetDir = $TestDir
                Branch    = 'main'
            }

            Get-NoGitHubRepoRecursiveContents @params

            $calledUrls | Should -Contain 'https://api.github.com/repos/owner/repo/contents?ref=main'
            $calledUrls | Should -Contain 'https://raw.githubusercontent.com/owner/repo/main/file.txt'

            $script:CapturedHeaders.Authorization | Should -Be 'token test'
            $script:CapturedHeaders.'User-Agent'  | Should -Be 'owner'
        }
    }
}
