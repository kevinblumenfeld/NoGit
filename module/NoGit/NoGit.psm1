Get-ChildItem -File -Recurse *.ps1 -Path @(
    "$PSScriptRoot/Public"
    "$PSScriptRoot/Private")  | ForEach-Object {
    . $_.FullName
}
