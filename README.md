# Claude Code CLI Status Line for PowerShell

A custom PowerShell script that displays a rich, informative statusline in the Claude Code terminal.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-green)

## Features

- **Directory** - Current working directory (shortened with `~`)
- **Git Integration**
  - Branch name (clickable link to GitHub)
  - Dirty indicator (`*`) for uncommitted changes
  - Ahead/behind remote (`↑↓`)
- **Model Name** - Currently active Claude model (Opus 4.5, Sonnet, etc.)
- **Lines Changed** - Added/removed lines (green/red)
- **Session Cost** - Running total in USD
- **Context Window** - Used/total tokens with progress bar
- **Color-Coded Progress**
  - White: < 50% usage
  - Gold: 50-75% usage
  - Ferrari Red: > 75% usage
- **Responsive Design** - Compact mode for narrow terminals (< 100 chars)

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

1. Copy `statusline.ps1` to your Claude configuration directory:
   ```powershell
   Copy-Item statusline.ps1 "$env:USERPROFILE\.claude\statusline.ps1"
   ```

2. Add the following to your Claude Code settings (`~/.claude/settings.json`):
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\YOUR_USERNAME\\.claude\\statusline.ps1\""
     }
   }
   ```

3. Replace `YOUR_USERNAME` with your Windows username.

4. Restart Claude Code.

## Requirements

- Windows PowerShell 5.1 or later
- Git (for git integration features)
- A terminal that supports ANSI colors (Windows Terminal recommended)
- Optional: Terminal with OSC 8 support for clickable links

## Customization

You can customize the script by editing `statusline.ps1`:

- **Bar width**: Adjust `$minBarWidth` and `$maxBarWidth` values
- **Compact mode threshold**: Change `$termWidth -lt 100` to your preferred width
- **Colors**: Modify the ANSI color codes in the "ANSI color codes" section

## License

MIT License - Feel free to use and modify as needed.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.
