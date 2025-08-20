param([switch]$DryRun)
Write-Output "env-sync bootstrap (powershell)"
if ($DryRun) { Write-Output "Dry run mode" }
# Placeholder: install winget packages from profiles\web-dev\windows\winget.txt
if (Test-Path profiles\web-dev\windows\winget.txt) {
  if ($DryRun) { Get-Content profiles\web-dev\windows\winget.txt | ForEach-Object { "winget install $_" } }
  else { Get-Content profiles\web-dev\windows\winget.txt | ForEach-Object { winget install --id $_ } }
}
