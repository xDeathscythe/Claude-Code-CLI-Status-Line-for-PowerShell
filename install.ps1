# Claude Code Custom Status Line - Installer
# Run: irm https://raw.githubusercontent.com/xDeathscythe/Claude-Code-CLI-Status-Line-for-PowerShell/main/install.ps1 | iex

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host " Claude Code Status Line Installer" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Paths
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$installDir = Join-Path $claudeDir "statusline"
$settingsFile = Join-Path $claudeDir "settings.json"
$baseUrl = "https://raw.githubusercontent.com/xDeathscythe/Claude-Code-CLI-Status-Line-for-PowerShell/main"

try {
    # Create .claude directory if needed
    if (-not (Test-Path $claudeDir)) {
        Write-Host "Creating .claude directory..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }

    # Create statusline directory if needed
    if (-not (Test-Path $installDir)) {
        Write-Host "Creating statusline directory..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }

    # Download statusline files
    Write-Host "Downloading statusline.ps1..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "$baseUrl/statusline.ps1" -OutFile (Join-Path $installDir "statusline.ps1") -UseBasicParsing

    Write-Host "Downloading statusline-config.json..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "$baseUrl/statusline-config.json" -OutFile (Join-Path $installDir "statusline-config.json") -UseBasicParsing

    Write-Host "Files downloaded" -ForegroundColor Green

    # Build the command
    $scriptPath = Join-Path $installDir "statusline.ps1"
    $statusLineCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

    # Configure Claude Code settings (using new statusLine format)
    Write-Host "Configuring Claude Code settings..." -ForegroundColor Yellow

    $statusLineConfig = @{
        type = "command"
        command = $statusLineCommand
    }

    if (Test-Path $settingsFile) {
        $content = Get-Content $settingsFile -Raw
        $settings = $content | ConvertFrom-Json

        # Remove old format if exists
        if ($settings.PSObject.Properties.Name -contains "statusLineCommand") {
            $settings.PSObject.Properties.Remove("statusLineCommand")
        }

        # Add/update new format
        if ($settings.PSObject.Properties.Name -contains "statusLine") {
            $settings.statusLine = $statusLineConfig
        } else {
            $settings | Add-Member -NotePropertyName "statusLine" -NotePropertyValue $statusLineConfig
        }

        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
        Write-Host "Updated existing settings.json" -ForegroundColor Green
    } else {
        $settings = @{ statusLine = $statusLineConfig }
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
        Write-Host "Created settings.json" -ForegroundColor Green
    }

    # Verify
    Write-Host ""
    Write-Host "Verifying..." -ForegroundColor Yellow
    $ok = $true

    if (Test-Path (Join-Path $installDir "statusline.ps1")) {
        Write-Host "  [OK] statusline.ps1" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] statusline.ps1" -ForegroundColor Red
        $ok = $false
    }

    if (Test-Path $settingsFile) {
        Write-Host "  [OK] settings.json" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] settings.json" -ForegroundColor Red
        $ok = $false
    }

    Write-Host ""
    if ($ok) {
        Write-Host "=================================" -ForegroundColor Green
        Write-Host " Installation Complete!" -ForegroundColor Green
        Write-Host "=================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Installed to: $installDir" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Restart Claude Code" -ForegroundColor White
        Write-Host "  2. (Optional) Edit: $installDir\statusline-config.json" -ForegroundColor White
        Write-Host ""
        Write-Host "For single-click links in Windows Terminal:" -ForegroundColor Yellow
        Write-Host "  Settings > Interaction > Disable 'Ctrl+click required'" -ForegroundColor White
    } else {
        Write-Host "=================================" -ForegroundColor Red
        Write-Host " Installation had errors" -ForegroundColor Red
        Write-Host "=================================" -ForegroundColor Red
    }
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "=================================" -ForegroundColor Red
    Write-Host " Installation Failed" -ForegroundColor Red
    Write-Host "=================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}
