
<h1 align="center">NoGit</h1>
<div align="center">
<sub>Download GitHub repository contents without installing Git.</sub>
<br /><br />

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/NoGit?label=Gallery)](https://www.powershellgallery.com/packages/NoGit)
[![License](https://img.shields.io/github/license/kevinblumenfeld/NoGit)](LICENSE)


</div>

---

**NoGit** is a PowerShell module that downloads the contents of a GitHub repository without requiring `git` to be installed. It uses the GitHub REST API and a personal access token (PAT) to retrieve files and folders recursively from any branch or path and saves them locally.

---

## 🚀 Features

* 🔒 Uses secure GitHub fine-grained personal access tokens (PAT)
* 📂 Recursively downloads full repository contents
* 📁 Saves to any local directory with auto-creation
* 🎯 Supports targeted downloads with `-SourcePath`
* 🚫 No dependency on `git`

---

## 📦 Installation

### From PowerShell Gallery

```powershell
Install-Module NoGit -Scope CurrentUser -Force
```


> **ℹ️ Note:** If you cannot install this module, run the command below, then paste it (CTRL + V) into PowerShell and press Enter. You can then run the commands below.

```powershell
irm 'https://raw.githubusercontent.com/kevinblumenfeld/NoGit/main/module/NoGit/Public/Get-NoGitHubRepoTreeContents.ps1' | Set-Clipboard
# then press CTRL + V and enter
```

---

## 💻 Usage


To use the commands, identify the **Owner** and **Repo** from the GitHub URL:

```
https://github.com/Owner/Repo
                  └────┘└───┘
                  -Owner -Repo
```
---

#### Example:

```powershell
Get-NoGitHubRepoTreeContents -Token 'ghp_...' -Owner 'octocat' -Repo 'Hello-World' -TargetDir 'C:\Temp\Hello-World' -Verbose
```

#### Example: Downloading a specific folder using -SourcePath
```powershell
Get-NoGitHubRepoTreeContents -Token 'ghp_...' -Owner 'octocat' -Repo 'Hello-World' -TargetDir 'C:\Temp\Hello-World' -SourcePath 'src/module' -Verbose
```

**What does -SourcePath do?** 
- It filters the download to only include files and folders under the path you specify.
- It downloads everything inside that folder recursively, including all its subfolders and files.
- The folder itself is not included in your local download. Only its contents are placed inside your target directory.

**For example:**

If you set:

> - `SourcePath = 'Build/DTect'`
> - `TargetDir = 'C:\Temp\DTect'`


Then a file like: `Build/DTect/0.0.637/file.psd1`

...will be saved locally as: `C:\Temp\DTect\0.0.637\file.psd1`


> ✅ **Note:** Any directory in the repository matching `SourcePath` will be downloaded.

#### Alternative Method (Contents API)
```powershell
Get-NoGitHubRepoContents -Token 'ghp_...' -Owner 'octocat' -Repo 'Hello-World' -TargetDir 'C:\Temp\Hello-World' -Branch 'feature-x' -Verbose
```

> **ℹ️ Note:** The `-Branch` parameter is optional and defaults to `"main"`.

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

Contributions are welcome. Open issues, suggest improvements, or submit a PR.

---

## 📝 Upcoming Features

- Parallel processing implementation for faster downloads of large repositories
- Pester tests for publishing automation

---

## 📄 License

Licensed under the [MIT License](LICENSE).
