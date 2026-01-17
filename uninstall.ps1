# Claude Code Custom Status Line - Uninstaller
# Run: irm https://raw.githubusercontent.com/xDeathscythe/Claude-Code-CLI-Status-Line-for-PowerShell/main/uninstall.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host " Claude Code Status Line Uninstaller" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Paths
$installDir = Join-Path $env:USERPROFILE ".claude\statusline"
$settingsFile = Join-Path $env:USERPROFILE ".claude\settings.json"

$removed = $false

# Remove statusline directory
if (Test-Path $installDir) {
    Write-Host "Removing statusline files..." -ForegroundColor Yellow
    Remove-Item $installDir -Recurse -Force
    Write-Host "Removed: $installDir" -ForegroundColor Green
    $removed = $true
} else {
    Write-Host "Statusline directory not found (already removed)" -ForegroundColor Gray
}

# Remove from Claude Code settings
if (Test-Path $settingsFile) {
    Write-Host "Updating Claude Code settings..." -ForegroundColor Yellow

    $content = Get-Content $settingsFile -Raw
    $settings = $content | ConvertFrom-Json
    $settingsModified = $false

    # Remove new format (statusLine)
    if ($settings.PSObject.Properties.Name -contains "statusLine") {
        $settings.PSObject.Properties.Remove("statusLine")
        Write-Host "Removed statusLine from settings.json" -ForegroundColor Green
        $settingsModified = $true
        $removed = $true
    }

    # Remove old format (statusLineCommand) for backward compatibility
    if ($settings.PSObject.Properties.Name -contains "statusLineCommand") {
        $settings.PSObject.Properties.Remove("statusLineCommand")
        Write-Host "Removed statusLineCommand from settings.json" -ForegroundColor Green
        $settingsModified = $true
        $removed = $true
    }

    if ($settingsModified) {
        # Check if settings is now empty
        $remainingProps = $settings.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' }

        if ($remainingProps.Count -eq 0) {
            # Remove empty settings file
            Remove-Item $settingsFile -Force
            Write-Host "Removed empty settings.json" -ForegroundColor Green
        } else {
            # Write updated settings
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
        }
    } else {
        Write-Host "Status line config not found in settings (already removed)" -ForegroundColor Gray
    }
} else {
    Write-Host "Settings file not found" -ForegroundColor Gray
}

Write-Host ""
if ($removed) {
    Write-Host "===================================" -ForegroundColor Green
    Write-Host " Uninstallation Complete!" -ForegroundColor Green
    Write-Host "===================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Restart Claude Code to apply changes." -ForegroundColor Yellow
} else {
    Write-Host "===================================" -ForegroundColor Yellow
    Write-Host " Nothing to uninstall" -ForegroundColor Yellow
    Write-Host "===================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Claude Code Status Line was not installed." -ForegroundColor Gray
}
Write-Host ""
