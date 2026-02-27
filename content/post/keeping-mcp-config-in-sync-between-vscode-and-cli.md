---
title: "Keeping MCP Server config in sync between VS Code and GitHub Copilot CLI"
date: 2026-02-26
tags: ["GitHub Copilot", "MCP", "VSCode"]
draft: false
---

![Keeping MCP config in sync between VS Code and Copilot CLI](../images/sync-mcp-vscode-copilot.png)

*Syncing MCP config from VS Code to Copilot CLI in a few simple steps.*

Hey awesome people,

Over the last weeks, I’ve been jumping between VS Code and Copilot CLI a lot more than usual. One thing kept annoying me: my MCP setup was perfect in VS Code, but I had to keep tweaking pieces again in CLI.

If that sounds familiar, good news: if you already have MCP servers working in VS Code, you can reuse most of that setup in GitHub Copilot CLI.

In this post, I’ll show you the fastest way to 'keep both in sync' from VS Code `mcp.json` to Copilot CLI `mcp-config.json`, with the necessary commands for both PowerShell and Bash.

## Why this matters

When you move between VS Code and terminal workflows, you really don’t want to rebuild MCP config from scratch every time.

I made that mistake once (probably multiple times, but didn't want to exagerate too much...), and it was exactly as fun as it sounds: tiny syntax differences, one invalid server name, one missing env var, and suddenly you’re troubleshooting config instead of actually building. (Although I can tell you that this would be a perfect use case for GenAI GitHub Copilot, lol)

This guide helps you:

- keep one consistent MCP setup style (VSCode MCP Config as the 'main' source)
- avoid common config parsing errors in Copilot CLI
- 'keep-in-sync' in a few minutes, even if you’re new to MCP

## MCP in plain English

MCP (Model Context Protocol) lets AI tools connect to external capabilities.

Think of MCP servers as “skill plugins” for your assistant, like:

- documentation search
- GitHub actions (issues, PRs, code search)
- browser automation
- Azure DevOps operations

## File locations you should know

VS Code MCP config is typically found at:

- Workspace: `./mcp.json` or `./.vscode/mcp.json`
- User-level:
  - Windows: `%APPDATA%\\Code\\User\\mcp.json`
  - macOS: `~/Library/Application Support/Code/User/mcp.json`
  - Linux: `~/.config/Code/User/mcp.json`

Copilot CLI MCP config lives here on all platforms:

- `~/.copilot/mcp-config.json`

## VS Code vs Copilot CLI: the important differences

The two formats are very close, but not identical:

1. Top-level key
   - VS Code: `servers`
   - Copilot CLI: `mcpServers`

2. Server ID naming rules in Copilot CLI
   - allowed: letters, numbers, `_`, `-`
   - server keys with `/` must be renamed

3. VS Code `inputs`
   - supported in VS Code flow
   - not used in Copilot CLI config

4. Placeholder syntax
   - VS Code often uses `${env:VAR}` and `${input:name}`
   - Copilot CLI expects `$VAR` and supports explicit `env` mappings

None of this is hard, but it’s just different enough to break things when done manually in a hurry.

## Fast path (recommended): automate conversion

You can grab both scripts directly from my GitHub repo:

- https://github.com/petender/MCP-Clone_VSCode2CLI

Quick clone commands (PowerShell, bash, zsh):

```bash
git clone https://github.com/petender/MCP-Clone_VSCode2CLI.git
cd MCP-Clone_VSCode2CLI
```

Use one of these scripts:

- `convert-mcp-config.ps1` (Windows/macOS/Linux with `pwsh`)
- `convert-mcp-config.sh` (macOS/Linux with `bash` + `python3`)

I personally use the PowerShell version most of the time, no surprise I'm primarily a Windows-guy, but didn't want to assume everyone is using PowerShell nowadays. (You should though ;)

### What the script converts automatically

- `servers` -> `mcpServers`
- removes VS Code-only `inputs`
- converts `${input:name}` -> `$NAME`
- converts `${env:VAR}` -> `$VAR`
- adds/merges `env` mappings like `"VAR": "$VAR"`
- renames invalid server IDs (for example containing `/`)

This is exactly the part that saves the most time (and avoids the most headaches).

## PowerShell usage (`convert-mcp-config.ps1`)

The script supports cross-platform defaults using your home path.

### Easiest mode

```powershell
pwsh -ExecutionPolicy Bypass -File ./convert-mcp-config.ps1
```

This auto-discovers common input locations and writes to `~/.copilot/mcp-config.json`.

### Explicit input, default output

```powershell
pwsh -ExecutionPolicy Bypass -File ./convert-mcp-config.ps1 \
  -InputPath ./mcp.json
```

### Explicit input and output

```powershell
pwsh -ExecutionPolicy Bypass -File ./convert-mcp-config.ps1 \
  -InputPath ./mcp.json \
  -OutputPath ~/.copilot/mcp-config.json
```

### Custom home path

```powershell
pwsh -ExecutionPolicy Bypass -File ./convert-mcp-config.ps1 \
  -InputPath ./mcp.json \
  -UserHome /home/<user>
```

## Bash usage (`convert-mcp-config.sh`)

First run:

```bash
chmod +x ./convert-mcp-config.sh
```

### Easiest mode

```bash
./convert-mcp-config.sh
```

### Explicit input, default output

```bash
./convert-mcp-config.sh --input ./mcp.json
```

### Explicit input and output

```bash
./convert-mcp-config.sh --input ./mcp.json --output ~/.copilot/mcp-config.json
```

### Custom home path

```bash
./convert-mcp-config.sh --input ./mcp.json --user-home /home/<user>
```

### Bash prerequisites

- `bash`
- `python3`

## Verify in Copilot CLI

After conversion, open Copilot CLI and run:

1. `/mcp reload`
2. `/mcp show`

If your config is valid, your servers should load without parsing errors.

If they don’t show up right away, don’t panic. In most cases it’s either naming rules or env vars (both covered below).

## Required environment variables (for the sample config)

Set these before launching Copilot CLI:

- `GITHUB_PERSONAL_ACCESS_TOKEN`
- `ADO_ORG`
- `ADO_DOMAIN`

PowerShell session example:

```powershell
$env:GITHUB_PERSONAL_ACCESS_TOKEN = "<your_token>"
$env:ADO_ORG = "<your_ado_org>"
$env:ADO_DOMAIN = "core"
```

bash/zsh example:

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="<your_token>"
export ADO_ORG="<your_ado_org>"
export ADO_DOMAIN="core"
```

## Manual conversion checklist

If you want to edit by hand, follow this sequence:

- rename `servers` to `mcpServers`
- remove `inputs`
- replace `${input:name}` with `$NAME`
- replace `${env:VAR}` with `$VAR` and add/update `env`
- rename server IDs that contain unsupported characters
- keep operational properties unchanged (`type`, `command`, `args`, `url`, `version`, `gallery`)

This checklist is also useful as a review checklist in PRs.

## Common errors and quick fixes

### `MCP server name must only contain alphanumeric characters, underscores, and hyphens`

Cause: a server key still contains `/` (or another invalid character).

Fix example:

- `microsoft/playwright-mcp` -> `microsoft_playwright_mcp`

### Server starts but fails with auth/runtime errors

Cause: missing or wrong environment variable values.

Fix:

- validate variable names exactly
- confirm values exist in the active shell session
- run `/mcp reload` again

Also make sure you start Copilot CLI from the same shell/session where variables are set.

### `command not found`

Cause: one of the required tools is missing.

Fix:

- install dependencies used by your config (`docker`, `npx`, `uvx`, etc.)

## Summary

Most VS Code MCP config can be reused in Copilot CLI. The key differences are server ID naming, top-level key name, and placeholder handling.

While one could assume that the MCP Configuration should be standardized across platforms, once I figured out the key syntax differences (GitHub Copilot for the win!), it ended up being much easier than I expected once I stopped doing it manually and automated the boring parts (GitHub Copilot for the win x2!).

If this helped you, feel free to share it with your team so everyone can standardize MCP config faster. And maybe give a little GitHub Star on the repo, so I know you like it ;).

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
