# Claude Code CLI Status Line for PowerShell

A custom PowerShell script that displays a rich, informative statusline in the Claude Code terminal.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-green)

## Features

- **Directory** - Current working directory with **clickable link** to open in File Explorer
- **Git Integration**
  - Branch name with **clickable link** to repository
  - Dirty indicator (`*`) for uncommitted changes
  - Ahead/behind remote (`↑↓`)
- **Model Name** - Currently active Claude model (Opus 4.5, Sonnet, etc.)
- **Lines Changed** - Added/removed lines (green/red)
- **Session Cost** - Running total in USD
- **Context Window** - Used/total tokens with progress bar
- **Optional Timestamp** - Show current time
- **Color-Coded Progress**
  - White: < 50% usage
  - Gold: 50-75% usage
  - Ferrari Red: > 75% usage
- **Responsive Design** - Compact mode for narrow terminals
- **JSON Configuration** - Full customization via config file
- **Caching** - Improved performance for large repositories
- **Multi-Host Support** - GitHub, GitLab, Bitbucket, Azure DevOps, Codeberg, SourceHut, Gitea, Gogs + custom hosts

## Example Output

**Full mode:**
```
~\myproject | main* ↑2 | Opus 4.5 | +150 -30 | $1.25 | 45k/200k ██████████░░░░░░░░░░ 22.5%
```

**Compact mode:**
```
~\myproject | main* | $1.25 | 45k ██████░░░░ 22.5%
```

## Installation

### 1. Download the files

Place both files in a folder of your choice:
- `statusline.ps1`
- `statusline-config.json`

Example location: `C:\Users\YourName\.claude\statusline\`

### 2. Configure Claude Code

Add the following to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\YOUR_USERNAME\\.claude\\statusline\\statusline.ps1\""
  }
}
```

Replace `YOUR_USERNAME` with your Windows username.

### 3. Restart Claude Code

The custom status line will appear at the top of the Claude Code interface.

---

## Clickable Links Setup

The status line has **two clickable elements**:

| Element | Click Action |
|---------|--------------|
| **Directory path** | Opens folder in Windows File Explorer |
| **Git branch name** | Opens repository in web browser |

### Directory Link

The directory path (e.g., `~\Projects\my-app`) is clickable and opens the folder in **Windows File Explorer**.

This uses the `file:///` URL protocol to launch Explorer at the current working directory.

### Git Branch Link

The git branch name is a **clickable hyperlink** that opens your repository in the browser.

### Windows Terminal Configuration

By default, Windows Terminal requires **Ctrl+Click** to open links. To enable **single-click** for both directory and branch links:

**Option 1: Via Settings UI**
1. Open Windows Terminal
2. Press `Ctrl+,` to open Settings
3. Go to **Interaction**
4. Find **"Ctrl+click required to follow links"**
5. **Turn OFF** this option

**Option 2: Via settings.json**

Open Settings → click the gear icon (Open JSON file) → add:

```json
{
  "experimental.detectURLs": true,
  "experimental.ctrlClickOpensLinks": false
}
```

After this change, simply **click** on the branch name to open the repository.

### Supported Git Hosts

| Host | SSH Format | HTTPS Format |
|------|------------|--------------|
| GitHub | `git@github.com:user/repo` | `https://github.com/user/repo` |
| GitLab | `git@gitlab.com:user/repo` | `https://gitlab.com/user/repo` |
| Bitbucket | `git@bitbucket.org:user/repo` | `https://bitbucket.org/user/repo` |
| Azure DevOps | `git@ssh.dev.azure.com:v3/org/project/repo` | `https://dev.azure.com/org/...` |
| Codeberg | `git@codeberg.org:user/repo` | `https://codeberg.org/user/repo` |
| SourceHut | `git@git.sr.ht:~user/repo` | `https://git.sr.ht/~user/repo` |
| Gitea/Forgejo | Auto-detected | Auto-detected |
| Gogs | Auto-detected | Auto-detected |

### Adding Custom Git Hosts

For self-hosted or private git servers, edit `statusline-config.json`:

```json
{
  "gitHosts": {
    "custom": [
      {
        "name": "Company GitLab",
        "hostPattern": "git.mycompany.com",
        "urlTemplate": "https://{host}/{path}/-/tree/{branch}",
        "enabled": true
      }
    ]
  }
}
```

**Template variables:**
- `{host}` - the hostname (e.g., `git.mycompany.com`)
- `{path}` - repository path (e.g., `team/project`)
- `{branch}` - current branch name

**URL templates by platform:**
- GitLab: `https://{host}/{path}/-/tree/{branch}`
- Gitea/Forgejo: `https://{host}/{path}/src/branch/{branch}`
- Gogs: `https://{host}/{path}/src/{branch}`

---

## Configuration

All settings are in `statusline-config.json`. The script works without this file (uses defaults).

### Display Options

```json
{
  "display": {
    "showDirectory": true,
    "showGitBranch": true,
    "showGitStatus": true,
    "showModel": true,
    "showLinesChanged": true,
    "showCost": true,
    "showTokens": true,
    "showProgressBar": true,
    "showPercentage": true,
    "showTimestamp": false,
    "timestampFormat": "HH:mm:ss",
    "compactModeWidth": 100
  }
}
```

Set any option to `false` to hide that element.

### Colors

Colors use ANSI escape codes:

| Code | Color | Code | Bright Color |
|------|-------|------|--------------|
| `30` | Black | `90` | Bright Black (Gray) |
| `31` | Red | `91` | Bright Red |
| `32` | Green | `92` | Bright Green |
| `33` | Yellow | `93` | Bright Yellow |
| `34` | Blue | `94` | Bright Blue |
| `35` | Magenta | `95` | Bright Magenta |
| `36` | Cyan | `96` | Bright Cyan |
| `37` | White | `97` | Bright White |

**256-color mode:** Use `38;5;N` where N is 0-255.

Example:
```json
{
  "colors": {
    "directory": "38;5;214",
    "branch": "38;5;39",
    "cost": "38;5;226",
    "barLow": "38;5;46",
    "barMedium": "38;5;220",
    "barHigh": "38;5;196"
  }
}
```

### Progress Bar Thresholds

```json
{
  "thresholds": {
    "barMediumPercent": 50,
    "barHighPercent": 75
  }
}
```

### Cache Settings

```json
{
  "cache": {
    "ttlSeconds": 5
  }
}
```

Increase this value for better performance on large repositories.

---

## Requirements

- Windows PowerShell 5.1 or later (PowerShell 7+ recommended)
- Git (for git integration features)
- Terminal with ANSI color support (Windows Terminal recommended)
- Terminal with OSC 8 hyperlink support for clickable links

## Troubleshooting

### Links not clickable
- Ensure your terminal supports OSC 8 hyperlinks
- Windows Terminal, iTerm2, and most modern terminals support this
- Check that "Ctrl+click required" setting is disabled

### Colors not showing
- Use Windows Terminal or PowerShell 7+
- Legacy Command Prompt has limited color support

### Git info not showing
- Ensure you're in a git repository with a remote named `origin`
- Check that git is in your PATH

### Performance issues on large repos
- Increase `cache.ttlSeconds` in config (e.g., to 10 or 15)
- First load fetches data; subsequent loads use cache

### Branch link goes to wrong URL
- Add your git host to `gitHosts.custom` in config
- Check the `urlTemplate` format for your platform

---

## License

MIT License - Feel free to use and modify as needed.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.
