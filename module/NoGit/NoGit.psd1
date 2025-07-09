# Copyright: (c) 2025, Kevin Blumenfeld <kevin.blumenfeld@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

@{
    RootModule        = 'NoGit.psm1'
    ModuleVersion     = '0.1.313'
    GUID              = '8e95c71c-83be-40bd-8633-2c9b080f0919'
    Author            = 'Kevin Blumenfeld'
    Copyright         = 'Copyright (c) 2025 by Kevin Blumenfeld, licensed under MIT.'
    Description       = "Recursively downloads files and folders from a GitHub repository using the GitHub REST API. Supports downloading the entire repository or specific subfolders.`nSee https://github.com/kevinblumenfeld/NoGit for usage examples and more details."
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-NoGitHubRepoContents'
        'Get-NoGitHubRepoTreeContents'
    )
    PrivateData       = @{
        PSData = @{
            Tags       = @(
                "GitHub",
                "NoGit",
                "Git",
                "RestAPI"
            )
            ProjectUri = 'https://github.com/kevinblumenfeld/NoGit'
        }
    }
}