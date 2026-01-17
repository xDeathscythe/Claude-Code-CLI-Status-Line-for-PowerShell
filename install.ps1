# Claude Code Custom Status Line - Installer
# Run: irm https://raw.githubusercontent.com/xDeathscythe/Claude-Code-CLI-Status-Line-for-PowerShell/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host " Claude Code Status Line Installer" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Paths
$installDir = Join-Path $env:USERPROFILE ".claude\statusline"
$settingsFile = Join-Path $env:USERPROFILE ".claude\settings.json"
$repoUrl = "https://github.com/xDeathscythe/Claude-Code-CLI-Status-Line-for-PowerShell.git"

# Check if git is available
$gitAvailable = Get-Command git -ErrorAction SilentlyContinue

# Create .claude directory if needed
$claudeDir = Join-Path $env:USERPROFILE ".claude"
if (-not (Test-Path $claudeDir)) {
    Write-Host "Creating .claude directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}

# Install statusline files
if (Test-Path $installDir) {
    Write-Host "Updating existing installation..." -ForegroundColor Yellow
    if ($gitAvailable -and (Test-Path (Join-Path $installDir ".git"))) {
        Push-Location $installDir
        git pull --quiet
        Pop-Location
        Write-Host "Updated via git pull" -ForegroundColor Green
    } else {
        # Re-download files
        Remove-Item $installDir -Recurse -Force
        if ($gitAvailable) {
            git clone --quiet $repoUrl $installDir
            Write-Host "Re-cloned repository" -ForegroundColor Green
        } else {
            New-Item -ItemType Directory -Path $installDir -Force | Out-Null
            $baseUrl = "https://raw.githubusercontent.com/xDeathscythe/Claude-Code-CLI-Status-Line-for-PowerShell/main"
            Invoke-WebRequest -Uri "$baseUrl/statusline.ps1" -OutFile (Join-Path $installDir "statusline.ps1")
            Invoke-WebRequest -Uri "$baseUrl/statusline-config.json" -OutFile (Join-Path $installDir "statusline-config.json")
            Write-Host "Downloaded files directly" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Installing statusline..." -ForegroundColor Yellow
    if ($gitAvailable) {
        git clone --quiet $repoUrl $installDir
        Write-Host "Cloned repository" -ForegroundColor Green
    } else {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        $baseUrl = "https://raw.githubusercontent.com/xDeathscythe/Claude-Code-CLI-Status-Line-for-PowerShell/main"
        Invoke-WebRequest -Uri "$baseUrl/statusline.ps1" -OutFile (Join-Path $installDir "statusline.ps1")
        Invoke-WebRequest -Uri "$baseUrl/statusline-config.json" -OutFile (Join-Path $installDir "statusline-config.json")
        Write-Host "Downloaded files directly (git not found)" -ForegroundColor Green
    }
}

# Configure Claude Code settings
Write-Host "Configuring Claude Code settings..." -ForegroundColor Yellow

$scriptPath = (Join-Path $installDir "statusline.ps1") -replace '\\', '\\\\'
$statusLineCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

if (Test-Path $settingsFile) {
    # Read existing settings
    $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json

    # Add or update statusLineCommand
    if ($settings.PSObject.Properties.Name -contains "statusLineCommand") {
        $settings.statusLineCommand = $statusLineCommand
    } else {
        $settings | Add-Member -NotePropertyName "statusLineCommand" -NotePropertyValue $statusLineCommand
    }

    # Write back
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
    Write-Host "Updated existing settings.json" -ForegroundColor Green
} else {
    # Create new settings file
    $settings = @{
        statusLineCommand = $statusLineCommand
    }
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
    Write-Host "Created new settings.json" -ForegroundColor Green
}

Write-Host ""
Write-Host "=================================" -ForegroundColor Green
Write-Host " Installation Complete!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed to: $installDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart Claude Code" -ForegroundColor White
Write-Host "  2. (Optional) Edit config: $installDir\statusline-config.json" -ForegroundColor White
Write-Host ""
Write-Host "To enable single-click links in Windows Terminal:" -ForegroundColor Yellow
Write-Host "  Settings > Interaction > Disable 'Ctrl+click required to follow links'" -ForegroundColor White
Write-Host ""
