# Work in progress
Import-Module "$PSScriptRoot/../module/NoGit/NoGit.psm1" -Force

Describe 'Get-NoGitHubRepoContents' {

    InModuleScope NoGit {

        BeforeEach {
            $script:RecursiveCallCount = 0

            # Prevent real API or file calls
            Mock -CommandName Invoke-RestMethod -MockWith { throw "Unexpected Invoke-RestMethod" }
            Mock -CommandName Invoke-WebRequest -MockWith { throw "Unexpected Invoke-WebRequest" }

            # Pretend directory doesn't exist
            Mock -CommandName Test-Path -MockWith { $false }

            # Mock directory creation
            Mock -CommandName New-Item -MockWith { return @{ FullName = $args[1] } }

            # Mock the recursive content function and track calls
            Mock -CommandName Get-NoGitHubRepoRecursiveContents -MockWith {
                $script:RecursiveCallCount++
            }

            Mock -CommandName Write-Verbose
            Mock -CommandName Write-Error
        }

        It 'creates the target directory if it does not exist' {
            Get-NoGitHubRepoContents -Token 'abc' -Owner 'octo' -Repo 'hello-world' -TargetDir 'C:\Temp\Repo'

            Should -Invoke -CommandName New-Item -Times 1
        }

        It 'calls the recursive content function once' {
            Get-NoGitHubRepoContents -Token 'abc' -Owner 'octo' -Repo 'hello-world' -TargetDir 'C:\Temp\Repo'

            $script:RecursiveCallCount | Should -Be 1
        }

        It 'constructs the API URL correctly with branch' {
            $capturedUrl = ''
            Mock -CommandName Get-NoGitHubRepoRecursiveContents -MockWith {
                param ($Url, $RelativePath, $Headers, $TargetDir, $Branch)
                $script:CapturedUrl = $Url
            }

            Get-NoGitHubRepoContents -Token 'abc' -Owner 'octo' -Repo 'hello-world' -Branch 'dev' -TargetDir 'C:\Temp\Repo'

            $script:CapturedUrl | Should -Be 'https://api.github.com/repos/octo/hello-world/contents?ref=dev'
        }

        It 'uses default branch "main" if none specified' {
            $capturedUrl = ''
            Mock -CommandName Get-NoGitHubRepoRecursiveContents -MockWith {
                param ($Url, $RelativePath, $Headers, $TargetDir, $Branch)
                $script:CapturedUrl = $Url
            }

            Get-NoGitHubRepoContents -Token 'abc' -Owner 'octo' -Repo 'hello-world' -TargetDir 'C:\Temp\Repo'

            $script:CapturedUrl | Should -Be 'https://api.github.com/repos/octo/hello-world/contents?ref=main'
        }
    }
}
