# Work in progress
Import-Module "$PSScriptRoot/../module/NoGit/NoGit.psm1" -Force

Describe 'Get-NoGitHubRepoTreeContents' {

    InModuleScope NoGit {

        BeforeEach {
            $script:BlobUris = @()

            Mock -CommandName Invoke-RestMethod -MockWith {
                param ($Uri)

                switch -Wildcard ($Uri) {
                    '*refs/heads*' {
                        return @{ object = @{ url = 'https://api.github.com/repos/foo/bar/git/commits/abc123' } }
                    }
                    '*commits*' {
                        return @{ tree = @{ sha = 'treeSha123' } }
                    }
                    '*trees*' {
                        return @{
                            truncated = $false
                            tree      = @(
                                @{ path = 'file1.txt'; type = 'blob'; sha = 'sha1' },
                                @{ path = 'folder/file2.txt'; type = 'blob'; sha = 'sha2' },
                                @{ path = 'folder'; type = 'tree'; sha = 'sha3' }
                            )
                        }
                    }
                    default { throw "Unexpected URI: $Uri" }
                }
            }

            Mock -CommandName Invoke-WebRequest -MockWith {
                param($Uri)
                $script:BlobUris += $Uri
            }

            Mock -CommandName Test-Path -MockWith { $false }
            Mock -CommandName New-Item
            Mock -CommandName Write-Verbose
            Mock -CommandName Write-Error
            Mock -CommandName Join-Path -MockWith {
                param ($Path, $ChildPath)
                return "$Path\$ChildPath"
            }
            Mock -CommandName Split-Path -MockWith {
                param ($Path, $Parent)
                return [System.IO.Path]::GetDirectoryName($Path)
            }
        }

        It 'resolves the branch to a commit SHA' {
            Get-NoGitHubRepoTreeContents -Token 'token' -Owner 'foo' -Repo 'bar' -TargetDir 'C:\Test\Tree'

            Should -Invoke -CommandName Invoke-RestMethod -ParameterFilter { $Uri -like '*refs/heads*' }
        }

        It 'retrieves the commit tree SHA' {
            Get-NoGitHubRepoTreeContents -Token 'token' -Owner 'foo' -Repo 'bar' -TargetDir 'C:\Test\Tree'

            Should -Invoke -CommandName Invoke-RestMethod -ParameterFilter { $Uri -like '*commits*' }
        }

        It 'downloads all blob files using Invoke-WebRequest' {
            Get-NoGitHubRepoTreeContents -Token 'token' -Owner 'foo' -Repo 'bar' -TargetDir 'C:\Test\Tree'

            $script:BlobUris.Count | Should -Be 2
            $script:BlobUris | Should -Contain 'https://api.github.com/repos/foo/bar/git/blobs/sha1'
            $script:BlobUris | Should -Contain 'https://api.github.com/repos/foo/bar/git/blobs/sha2'
        }

        It 'creates folders before downloading files' {
            Get-NoGitHubRepoTreeContents -Token 'token' -Owner 'foo' -Repo 'bar' -TargetDir 'C:\Test\Tree'

            Should -Invoke -CommandName New-Item
        }

        It 'does not attempt to download non-blob entries' {
            Get-NoGitHubRepoTreeContents -Token 'token' -Owner 'foo' -Repo 'bar' -TargetDir 'C:\Test\Tree'

            $script:BlobUris | Should -Not -Contain 'https://api.github.com/repos/foo/bar/git/blobs/sha3'
        }
    }
}
