
<h1 align="center">NoGit</h1>
<div align="center">
<sub>Download GitHub repository contents without installing Git.</sub>
<br /><br />

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/NoGit?label=Gallery)](https://www.powershellgallery.com/packages/NoGit)
[![License](https://img.shields.io/github/license/kevinblumenfeld/NoGit)](LICENSE)
[![Build](https://github.com/kevinblumenfeld/NoGit/actions/workflows/ci.yml/badge.svg)](https://github.com/kevinblumenfeld/NoGit/actions)

</div>

---

**NoGit** is a PowerShell module that downloads the contents of a GitHub repository without requiring `git` to be installed. It uses the GitHub REST API and a personal access token (PAT) to retrieve files and folders recursively from any branch and saves them locally.

---

## 🚀 Features

* 🔒 Uses secure GitHub fine-grained personal access tokens (PAT)
* 📂 Recursively downloads full repo contents using two API methods
* 📁 Saves to any local directory with auto-creation
* 🛠️ CI/CD-friendly logging via `Write-Verbose`
* 🎯 Supports targeted downloads with `-SourcePath`
* 🚫 No dependency on `git`

---

## 📦 Installation

### From PowerShell Gallery

```powershell
Install-Module NoGit -Scope CurrentUser
```

---

## 💻 Usage

### Standard Method (Contents API)

To use the commands, identify the **Owner** and **Repo** from the GitHub URL:

```
https://github.com/Owner/Repo
                  └────┘└───┘
                  -Owner -Repo
```

```powershell
Get-NoGitHubRepoContents -Token 'ghp_...' -Owner 'octocat' -Repo 'Hello-World' -TargetDir 'C:\Temp\Hello-World'
```

```powershell
Get-NoGitHubRepoContents -Token 'ghp_...' -Owner 'octocat' -Repo 'Hello-World' -TargetDir 'C:\Temp\Hello-World' -Branch 'feature-x' -Verbose
```

> **ℹ️ Note:** The `-Branch` parameter is optional and defaults to `"main"`.

---

### Tree-Based Method (for large directories > 1000 files)

Use `Get-NoGitHubRepoTreeContents` when working with repositories that:

* Contain directories with large numbers of files (over 1000), where the standard Contents API may truncate results.
* Require efficient retrieval and fine-grained filtering of specific subfolders and their contents.

#### Example (Download entire repo):

```powershell
Get-NoGitHubRepoTreeContents -Token 'ghp_...' -Owner 'octocat' -Repo 'Hello-World' -TargetDir 'C:\Temp\Hello-World' -Verbose
```

#### Example (Download a specific folder with `-SourcePath`):

```powershell
Get-NoGitHubRepoTreeContents -Token 'ghp_...' -Owner 'octocat' -Repo 'Hello-World' -Branch 'main' -TargetDir 'C:\Temp\Hello-World' -SourcePath 'src/module' -Verbose
```

**What does `-SourcePath` do?**

* Filters files to only those under the specified folder path.
* Downloads all files and subfolders **recursively** under it.
* The `SourcePath` itself is **not included** in your local output – only its contents and subfolders are preserved.

*For example:*
If `SourcePath` is `'Build/DTect'` and `TargetDir` is `'C:\Temp\DTect'`,
then `'Build/DTect/0.0.637/file.psd1'` will be saved as:

```
C:\Temp\DTect\0.0.637\file.psd1
```

> ✅ **Note:** Any directory in the repository matching `SourcePath` will be downloaded.

---

## 🧪 Output (Verbose)

```
VERBOSE: Created directory: C:\Code\Hello
VERBOSE: Downloaded: README.md
VERBOSE: Downloaded: src/main.ps1
VERBOSE: --- Summary for octocat/Hello-World ---
VERBOSE: Success   : 2
VERBOSE: Fail      : 0
VERBOSE: OutputDir : C:\Code\Hello
VERBOSE: Elapsed   : 00:00:05
```

---

## 🔐 Requirements

* PowerShell 5.1 or later (7+ recommended)
* GitHub fine-grained [personal access token (PAT)](https://github.com/settings/personal-access-tokens) with `repo contents:read` permission

---

## 🤝 Contributing

Contributions are welcome! Open issues, suggest improvements, or submit a PR.

---

## 📝 Upcoming Features

- Parallel processing implementation for faster downloads of large repositories
- Pester tests for publishing automation

---

## 📄 License

Licensed under the [MIT License](LICENSE).
