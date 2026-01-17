# Force UTF-8 output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Read JSON from stdin
$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json

# Extract values
$currentDir = $jsonInput.workspace.current_dir
$dir = $currentDir -replace '^C:\\Users\\[^\\]+', '~'

# ============================================
# CONFIGURATION
# ============================================
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configFile = Join-Path $scriptDir "statusline-config.json"

# Default configuration
$defaultConfig = @{
    display = @{
        showDirectory = $true
        showGitBranch = $true
        showGitStatus = $true
        showModel = $true
        showLinesChanged = $true
        showCost = $true
        showTokens = $true
        showProgressBar = $true
        showPercentage = $true
        showTimestamp = $false
        timestampFormat = "HH:mm:ss"
        compactModeWidth = 100
    }
    colors = @{
        directory = "97"
        branch = "96"
        dirtyIndicator = "33"
        ahead = "32"
        behind = "31"
        model = "96"
        linesAdded = "32"
        linesRemoved = "31"
        cost = "96"
        tokens = "96"
        percentage = "96"
        timestamp = "90"
        separator = "90"
        barLow = "97"
        barMedium = "93"
        barHigh = "91"
        barEmpty = "90"
    }
    thresholds = @{
        barMediumPercent = 50
        barHighPercent = 75
    }
    cache = @{
        ttlSeconds = 5
    }
    gitHosts = @{
        custom = @()
    }
}

# Load config or use defaults
$config = $defaultConfig
if (Test-Path $configFile) {
    try {
        $loadedConfig = Get-Content $configFile -Raw | ConvertFrom-Json
        # Merge loaded config with defaults (loaded takes precedence)
        foreach ($section in @('display', 'colors', 'thresholds', 'cache')) {
            if ($loadedConfig.$section) {
                foreach ($prop in $loadedConfig.$section.PSObject.Properties) {
                    $config.$section[$prop.Name] = $prop.Value
                }
            }
        }
        if ($loadedConfig.gitHosts.custom) {
            $config.gitHosts.custom = $loadedConfig.gitHosts.custom
        }
    } catch { }
}

# ============================================
# ANSI COLOR HELPER
# ============================================
$esc = [char]27
function Get-AnsiColor { param([string]$code) return "$esc[$($code)m" }
$reset = "$esc[0m"

# Load colors from config
$colDirectory = Get-AnsiColor $config.colors.directory
$colBranch = Get-AnsiColor $config.colors.branch
$colDirty = Get-AnsiColor $config.colors.dirtyIndicator
$colAhead = Get-AnsiColor $config.colors.ahead
$colBehind = Get-AnsiColor $config.colors.behind
$colModel = Get-AnsiColor $config.colors.model
$colAdded = Get-AnsiColor $config.colors.linesAdded
$colRemoved = Get-AnsiColor $config.colors.linesRemoved
$colCost = Get-AnsiColor $config.colors.cost
$colTokens = Get-AnsiColor $config.colors.tokens
$colPct = Get-AnsiColor $config.colors.percentage
$colTimestamp = Get-AnsiColor $config.colors.timestamp
$colSep = Get-AnsiColor $config.colors.separator
$colBarLow = Get-AnsiColor $config.colors.barLow
$colBarMed = Get-AnsiColor $config.colors.barMedium
$colBarHigh = Get-AnsiColor $config.colors.barHigh

# ============================================
# CACHING MECHANISM
# ============================================
$cacheFile = Join-Path $env:TEMP "claude-statusline-cache.json"
$cacheTTL = $config.cache.ttlSeconds

function Get-CachedGitInfo {
    param([string]$directory)

    if (Test-Path $cacheFile) {
        try {
            $cache = Get-Content $cacheFile -Raw | ConvertFrom-Json
            $cacheAge = (Get-Date) - [datetime]$cache.timestamp

            if ($cache.directory -eq $directory -and $cacheAge.TotalSeconds -lt $cacheTTL) {
                return $cache
            }
        } catch { }
    }
    return $null
}

function Save-GitCache {
    param($data)
    try {
        $data | ConvertTo-Json | Set-Content $cacheFile -Force
    } catch { }
}

# ============================================
# MULTI-HOST URL BUILDER (Extended)
# ============================================
function Get-GitRepoUrl {
    param([string]$remoteUrl, [string]$branch, [array]$customHosts)

    if (-not $remoteUrl -or -not $branch) { return '' }

    $cleanUrl = $remoteUrl -replace '\.git$', ''

    # Check custom hosts first
    foreach ($customHost in $customHosts) {
        if (-not $customHost.enabled) { continue }
        $pattern = $customHost.hostPattern

        # SSH format: git@hostname:path
        if ($cleanUrl -match "git@$([regex]::Escape($pattern)):(.+)$") {
            $path = $matches[1]
            $url = $customHost.urlTemplate -replace '\{host\}', $pattern -replace '\{path\}', $path -replace '\{branch\}', $branch
            return $url
        }
        # HTTPS format: https://hostname/path
        if ($cleanUrl -match "https://$([regex]::Escape($pattern))/(.+)$") {
            $path = $matches[1]
            $url = $customHost.urlTemplate -replace '\{host\}', $pattern -replace '\{path\}', $path -replace '\{branch\}', $branch
            return $url
        }
    }

    # GitHub (SSH and HTTPS)
    if ($cleanUrl -match 'git@github\.com:(.+)$') {
        return "https://github.com/$($matches[1])/tree/$branch"
    }
    if ($cleanUrl -match 'https://github\.com/(.+)$') {
        return "https://github.com/$($matches[1])/tree/$branch"
    }

    # GitLab (SSH and HTTPS)
    if ($cleanUrl -match 'git@gitlab\.com:(.+)$') {
        return "https://gitlab.com/$($matches[1])/-/tree/$branch"
    }
    if ($cleanUrl -match 'https://gitlab\.com/(.+)$') {
        return "https://gitlab.com/$($matches[1])/-/tree/$branch"
    }

    # Bitbucket (SSH and HTTPS)
    if ($cleanUrl -match 'git@bitbucket\.org:(.+)$') {
        return "https://bitbucket.org/$($matches[1])/src/$branch"
    }
    if ($cleanUrl -match 'https://bitbucket\.org/(.+)$') {
        return "https://bitbucket.org/$($matches[1])/src/$branch"
    }

    # Azure DevOps (multiple formats)
    if ($cleanUrl -match 'git@ssh\.dev\.azure\.com:v3/([^/]+)/([^/]+)/(.+)$') {
        return "https://dev.azure.com/$($matches[1])/$($matches[2])/_git/$($matches[3])?version=GB$branch"
    }
    if ($cleanUrl -match 'https://dev\.azure\.com/([^/]+)/([^/]+)/_git/(.+)$') {
        return "https://dev.azure.com/$($matches[1])/$($matches[2])/_git/$($matches[3])?version=GB$branch"
    }
    if ($cleanUrl -match 'https://([^.]+)\.visualstudio\.com/([^/]+)/_git/(.+)$') {
        return "https://dev.azure.com/$($matches[1])/$($matches[2])/_git/$($matches[3])?version=GB$branch"
    }

    # Gitea / Forgejo (common self-hosted)
    if ($cleanUrl -match 'git@([^:]+):(.+)$') {
        $hostName = $matches[1]
        $path = $matches[2]
        # Detect Gitea/Codeberg by common patterns
        if ($hostName -match 'codeberg\.org') {
            return "https://$hostName/$path/src/branch/$branch"
        }
        if ($hostName -match 'gitea|forgejo') {
            return "https://$hostName/$path/src/branch/$branch"
        }
    }
    if ($cleanUrl -match 'https://([^/]+)/(.+)$') {
        $hostName = $matches[1]
        $path = $matches[2]
        if ($hostName -match 'codeberg\.org') {
            return "https://$hostName/$path/src/branch/$branch"
        }
    }

    # Codeberg (Gitea-based)
    if ($cleanUrl -match 'git@codeberg\.org:(.+)$') {
        return "https://codeberg.org/$($matches[1])/src/branch/$branch"
    }
    if ($cleanUrl -match 'https://codeberg\.org/(.+)$') {
        return "https://codeberg.org/$($matches[1])/src/branch/$branch"
    }

    # SourceHut
    if ($cleanUrl -match 'git@git\.sr\.ht:~(.+)$') {
        return "https://git.sr.ht/~$($matches[1])/tree/$branch"
    }
    if ($cleanUrl -match 'https://git\.sr\.ht/~(.+)$') {
        return "https://git.sr.ht/~$($matches[1])/tree/$branch"
    }

    # Gogs (similar to Gitea)
    if ($cleanUrl -match 'git@([^:]*gogs[^:]*):(.+)$') {
        return "https://$($matches[1])/$($matches[2])/src/$branch"
    }

    # Generic self-hosted GitLab (fallback for git@ URLs)
    if ($cleanUrl -match 'git@([^:]+):(.+)$') {
        return "https://$($matches[1])/$($matches[2])/-/tree/$branch"
    }

    # Generic HTTPS fallback (assume GitLab-style)
    if ($cleanUrl -match 'https://([^/]+)/(.+)$') {
        return "https://$($matches[1])/$($matches[2])/-/tree/$branch"
    }

    return ''
}

# ============================================
# GIT INFO WITH CACHING
# ============================================
$gitBranch = ''
$gitDirty = $false
$gitAhead = 0
$gitBehind = 0
$gitRepoUrl = ''

$cached = Get-CachedGitInfo -directory $currentDir

if ($cached) {
    $gitBranch = $cached.branch
    $gitDirty = $cached.dirty
    $gitAhead = $cached.ahead
    $gitBehind = $cached.behind
    $gitRepoUrl = $cached.repoUrl
} else {
    try {
        $statusOutput = git -C $currentDir status -b --porcelain 2>$null

        if ($statusOutput) {
            $lines = $statusOutput -split "`n"

            if ($lines[0] -match '^## ([^.\s]+)') {
                $gitBranch = $matches[1]

                if ($lines[0] -match '\[ahead (\d+)') {
                    $gitAhead = [int]$matches[1]
                }
                if ($lines[0] -match 'behind (\d+)') {
                    $gitBehind = [int]$matches[1]
                }
            }

            if ($lines.Count -gt 1 -and $lines[1]) {
                $gitDirty = $true
            }

            if ($gitBranch) {
                $remoteUrl = git -C $currentDir remote get-url origin 2>$null
                if ($remoteUrl) {
                    $gitRepoUrl = Get-GitRepoUrl -remoteUrl $remoteUrl -branch $gitBranch -customHosts $config.gitHosts.custom
                }
            }
        }

        $cacheData = @{
            timestamp = (Get-Date).ToString('o')
            directory = $currentDir
            branch = $gitBranch
            dirty = $gitDirty
            ahead = $gitAhead
            behind = $gitBehind
            repoUrl = $gitRepoUrl
        }
        Save-GitCache -data $cacheData

    } catch { }
}

# ============================================
# CONTEXT WINDOW & COST INFO
# ============================================
$pct = if ($null -ne $jsonInput.context_window.used_percentage) { [math]::Round($jsonInput.context_window.used_percentage, 1) } else { 0 }
$usedTokens = if ($null -ne $jsonInput.context_window.total_input_tokens) { $jsonInput.context_window.total_input_tokens } else { 0 }
$totalTokens = if ($null -ne $jsonInput.context_window.context_window_size) { $jsonInput.context_window.context_window_size } else { 200000 }
$usedK = [math]::Round($usedTokens / 1000)
$totalK = [math]::Round($totalTokens / 1000)

$costUsd = if ($null -ne $jsonInput.cost.total_cost_usd) { [math]::Round($jsonInput.cost.total_cost_usd, 2) } else { 0 }
$linesAdded = if ($null -ne $jsonInput.cost.total_lines_added) { $jsonInput.cost.total_lines_added } else { 0 }
$linesRemoved = if ($null -ne $jsonInput.cost.total_lines_removed) { $jsonInput.cost.total_lines_removed } else { 0 }

# ============================================
# TERMINAL & DISPLAY
# ============================================
$termWidth = $Host.UI.RawUI.WindowSize.Width
$compactMode = $termWidth -lt $config.display.compactModeWidth

# Progress bar
$fixedContentLen = if ($compactMode) { 30 } else { 50 }
$baseWidth = [math]::Max(10, [math]::Min(50, $termWidth - $fixedContentLen))
$width = [math]::Floor($baseWidth * 0.95)

$fullBlock = [char]0x2588
$emptyBlock = [char]0x2591
$filled = [math]::Round($width * $pct / 100)
$empty = $width - $filled
$fullPart = if ($filled -gt 0) { [string]::new($fullBlock, $filled) } else { '' }
$emptyPart = if ($empty -gt 0) { [string]::new($emptyBlock, $empty) } else { '' }
$bar = $fullPart + $emptyPart

# Bar color based on thresholds
$barColor = if ($pct -lt $config.thresholds.barMediumPercent) { $colBarLow }
            elseif ($pct -lt $config.thresholds.barHighPercent) { $colBarMed }
            else { $colBarHigh }

# ============================================
# BUILD OUTPUT
# ============================================
$sep = " $colSep|$reset "
$output = @()

# Directory
if ($config.display.showDirectory) {
    $output += "$colDirectory$dir$reset"
}

# Git info
if ($config.display.showGitBranch -and $gitBranch) {
    $dirtyIndicator = if ($config.display.showGitStatus -and $gitDirty) { "$colDirty*$reset" } else { '' }
    $aheadIndicator = if ($config.display.showGitStatus -and $gitAhead -gt 0) { " $colAhead$([char]0x2191)$gitAhead$reset" } else { '' }
    $behindIndicator = if ($config.display.showGitStatus -and $gitBehind -gt 0) { " $colBehind$([char]0x2193)$gitBehind$reset" } else { '' }

    $st = "$esc\"
    if ($gitRepoUrl) {
        $branchLink = "$esc]8;;$gitRepoUrl$st$colBranch$gitBranch$reset$esc]8;;$st"
    } else {
        $branchLink = "$colBranch$gitBranch$reset"
    }
    $output += "$branchLink$dirtyIndicator$aheadIndicator$behindIndicator"
}

# Model (full mode only)
if (-not $compactMode -and $config.display.showModel) {
    $modelName = $jsonInput.model.display_name
    $output += "$colModel$modelName$reset"
}

# Lines changed (full mode only)
if (-not $compactMode -and $config.display.showLinesChanged) {
    $output += "$colAdded+$linesAdded$reset $colRemoved-$linesRemoved$reset"
}

# Cost
if ($config.display.showCost) {
    $output += "$colCost`$$costUsd$reset"
}

# Tokens
if ($config.display.showTokens) {
    if ($compactMode) {
        $output += "$colTokens${usedK}k$reset"
    } else {
        $output += "$colTokens${usedK}k/${totalK}k$reset"
    }
}

# Timestamp
if ($config.display.showTimestamp) {
    $timestamp = (Get-Date).ToString($config.display.timestampFormat)
    $output += "$colTimestamp$timestamp$reset"
}

# Progress bar and percentage
$barOutput = ""
if ($config.display.showProgressBar) {
    $barOutput = "$barColor$bar$reset"
}
if ($config.display.showPercentage) {
    $barOutput += " $colPct$pct%$reset"
}
if ($barOutput) {
    $output += $barOutput.Trim()
}

# Join and output
Write-Host ($output -join $sep) -NoNewline
