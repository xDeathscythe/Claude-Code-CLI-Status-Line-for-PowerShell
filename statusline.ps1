# Force UTF-8 output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Read JSON from stdin
$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json

# Extract values
$dir = $jsonInput.workspace.current_dir -replace '^C:\\Users\\[^\\]+', '~'

# Get git info (branch, status, ahead/behind, remote URL)
$gitBranch = ''
$gitDirty = $false
$gitAhead = 0
$gitBehind = 0
$gitRepoUrl = ''
try {
    $gitBranch = git -C $jsonInput.workspace.current_dir branch --show-current 2>$null
    if ($gitBranch) {
        $gitStatus = git -C $jsonInput.workspace.current_dir status --porcelain 2>$null
        if ($gitStatus) { $gitDirty = $true }

        # Get ahead/behind count
        $aheadBehind = git -C $jsonInput.workspace.current_dir rev-list --left-right --count "origin/$gitBranch...$gitBranch" 2>$null
        if ($aheadBehind -match '(\d+)\s+(\d+)') {
            $gitBehind = [int]$matches[1]
            $gitAhead = [int]$matches[2]
        }

        # Get remote URL and convert to HTTPS
        $remoteUrl = git -C $jsonInput.workspace.current_dir remote get-url origin 2>$null
        if ($remoteUrl) {
            # Convert SSH to HTTPS format
            if ($remoteUrl -match 'git@github\.com:(.+)\.git') {
                $gitRepoUrl = "https://github.com/$($matches[1])/tree/$gitBranch"
            } elseif ($remoteUrl -match 'https://github\.com/(.+?)(\.git)?$') {
                $gitRepoUrl = "https://github.com/$($matches[1])/tree/$gitBranch"
            }
        }
    }
} catch { }

# Context window info
$pct = if ($null -ne $jsonInput.context_window.used_percentage) { [math]::Round($jsonInput.context_window.used_percentage, 1) } else { 0 }
$usedTokens = if ($null -ne $jsonInput.context_window.total_input_tokens) { $jsonInput.context_window.total_input_tokens } else { 0 }
$totalTokens = if ($null -ne $jsonInput.context_window.context_window_size) { $jsonInput.context_window.context_window_size } else { 200000 }
$usedK = [math]::Round($usedTokens / 1000)
$totalK = [math]::Round($totalTokens / 1000)

# Cost and lines changed
$costUsd = if ($null -ne $jsonInput.cost.total_cost_usd) { [math]::Round($jsonInput.cost.total_cost_usd, 2) } else { 0 }
$linesAdded = if ($null -ne $jsonInput.cost.total_lines_added) { $jsonInput.cost.total_lines_added } else { 0 }
$linesRemoved = if ($null -ne $jsonInput.cost.total_lines_removed) { $jsonInput.cost.total_lines_removed } else { 0 }

# Terminal width and compact mode
$termWidth = $Host.UI.RawUI.WindowSize.Width
$compactMode = $termWidth -lt 100

# Calculate responsive bar width (5% shorter)
$fixedContentLen = if ($compactMode) { 30 } else { 50 }
$baseWidth = [math]::Max(10, [math]::Min(50, $termWidth - $fixedContentLen))
$width = [math]::Floor($baseWidth * 0.95)

# Build the bar
$fullBlock = [char]0x2588
$emptyBlock = [char]0x2591
$filled = [math]::Round($width * $pct / 100)
$empty = $width - $filled
$fullPart = if ($filled -gt 0) { [string]::new($fullBlock, $filled) } else { '' }
$emptyPart = if ($empty -gt 0) { [string]::new($emptyBlock, $empty) } else { '' }
$bar = $fullPart + $emptyPart

# ANSI color codes
$esc = [char]27
$white = "$esc[97m"
$gold = "$esc[38;5;220m"
$ferrariRed = "$esc[38;5;196m"
$cyan = "$esc[96m"
$green = "$esc[32m"
$red = "$esc[31m"
$yellow = "$esc[33m"
$dim = "$esc[90m"
$reset = "$esc[0m"

# Determine bar color based on percentage
$barColor = if ($pct -lt 50) { $white } elseif ($pct -lt 75) { $gold } else { $ferrariRed }

# Build git info with clickable link
$gitInfo = ''
if ($gitBranch) {
    $dirtyIndicator = if ($gitDirty) { "$yellow*$reset" } else { '' }
    $aheadIndicator = if ($gitAhead -gt 0) { " $green$([char]0x2191)$gitAhead$reset" } else { '' }
    $behindIndicator = if ($gitBehind -gt 0) { " $red$([char]0x2193)$gitBehind$reset" } else { '' }

    # OSC 8 hyperlink: ESC]8;;URL BEL text ESC]8;; BEL
    $bel = [char]0x07
    if ($gitRepoUrl) {
        $branchLink = "$esc]8;;$gitRepoUrl$bel$cyan$gitBranch$reset$esc]8;;$bel"
    } else {
        $branchLink = "$cyan$gitBranch$reset"
    }
    $gitInfo = " $dim|$reset $branchLink$dirtyIndicator$aheadIndicator$behindIndicator"
}

# Build main line based on mode
$modelName = $jsonInput.model.display_name
$linesInfo = "$green+$linesAdded$reset $red-$linesRemoved$reset"

if ($compactMode) {
    # Compact: only essential info
    Write-Host "$white$dir$reset$gitInfo $dim|$reset $cyan`$$costUsd$reset $dim|$reset $cyan${usedK}k$reset $barColor$bar$reset $cyan$pct%$reset" -NoNewline
} else {
    # Full: all info
    Write-Host "$white$dir$reset$gitInfo $dim|$reset $cyan$modelName$reset $dim|$reset $linesInfo $dim|$reset $cyan`$$costUsd$reset $dim|$reset $cyan${usedK}k/${totalK}k$reset $barColor$bar$reset $cyan$pct%$reset" -NoNewline
}
