# DragonLoot - Agent Guidelines

Project-specific guidelines for DragonLoot. See the parent `../AGENTS.md` for general WoW addon development rules.

---

## Overview

DragonLoot is a customizable loot addon that replaces the default Blizzard loot window and loot roll views.

**Status**: Phase 1 complete - Core bootstrap, config, slash commands, and minimap icon.

**GitHub**: TBD

---

## Target Versions

| Version | Interface | TOC Directive |
|---------|-----------|---------------|
| Retail | 110207, 120001, 120000 | `## Interface: 110207, 120001, 120000` |
| TBC Anniversary | 20505 | `## Interface-BCC: 20505` |
| MoP Classic | 50503 | `## Interface-Mists: 50503` |

Version-specific files are loaded via BigWigsMods packager comment directives (`#@retail@` / `#@tbc-anniversary@` / `#@version-mists@`) in the TOC.

---

## Architecture

| Layer | Directory | Responsibility |
|-------|-----------|----------------|
| Core | `Core/` | Addon lifecycle, config, slash commands, minimap icon |
| Display | `Display/` | UI frames and presentation (loot window, roll frame, history) |
| Listeners | `Listeners/` | Event handling and version-specific loot/roll parsing |
| Libs | `Libs/` | Embedded Ace3 + utility libraries |

### Namespace Pattern

All files use the shared private namespace:
```lua
local ADDON_NAME, ns = ...
```

### Namespace Sub-tables

All modules attach to `ns`: `ns.Addon`, `ns.LootFrame`, `ns.LootAnimations`, `ns.RollFrame`, `ns.RollAnimations`, `ns.RollManager`, `ns.HistoryFrame`, `ns.ConfigWindow`, `ns.MinimapIcon`, `ns.Listeners`, `ns.Print`, `ns.DebugPrint`.

---

## Placeholders

The following values are placeholders and must be updated before first release:

| Item | Placeholder | File |
|------|-------------|------|
| CurseForge Project ID | `0000000` | `DragonLoot.toc` |
| Wago ID | `TBD` | `DragonLoot.toc` |
| Icon texture | `Interface\AddOns\DragonLoot\DragonLoot_Icon` | `DragonLoot.toc` |
| GitHub URL | TBD | This file |

---

## Ace3 Stack

DragonLoot embeds Ace3 via `Libs/embeds.xml`. The full Ace3 library set is available:

| Library | Usage |
|---------|-------|
| AceAddon | Addon lifecycle |
| AceEvent | Event registration |
| AceTimer | Timers |
| AceDB | SavedVariables + profiles |
| AceConfig | Options table registration |
| AceConfigDialog | Blizzard settings integration |
| AceGUI | Standalone config window |
| AceConsole | Slash command registration |
| LibSharedMedia-3.0 | Font/texture/sound selection |
| LibDataBroker-1.1 | Data source for minimap icon |
| LibDBIcon-1.0 | Minimap button |

### Local Dev: Ace3 Submodule

`.pkgmeta` externals only work during CI packaging. For local dev, add Ace3 as a git submodule at `Libs/Ace3/`.

---

## CI/CD

### Workflows

| File | Trigger | Purpose |
|------|---------|---------|
| `lint.yml` | `pull_request_target` to master | Luacheck (uses `pull_request_target` so it runs on release-please bot PRs) |
| `release-pr.yml` | `push` to master | release-please creates/updates a Release PR with version bump and changelog |
| `release.yml` | tag push or `workflow_dispatch` | BigWigsMods packager builds and uploads to CurseForge, Wago, and GitHub Releases |

### Secrets

| Secret | Purpose |
|--------|---------|
| `CF_API_KEY` | CurseForge upload |
| `WAGO_API_TOKEN` | Wago.io upload |

### Project IDs

| Platform | ID | TOC Field |
|----------|----|-----------|
| CurseForge | `0000000` (placeholder) | `X-Curse-Project-ID` |
| Wago | `TBD` (placeholder) | `X-Wago-ID` |

---

## Local Development

### Install Location

Create a directory junction from the WoW addons folder to the repo:
```powershell
New-Item -ItemType Junction -Path "E:\World of Warcraft\_anniversary_\Interface\AddOns\DragonLoot" -Target "F:\Repos\wow-addons\DragonLoot"
```

### Testing

No automated test framework. Test manually in-game.

#### Phase 1 - Manual Test Steps

1. Load the addon in any supported game version
2. `/console scriptErrors 1` to catch Lua errors
3. Verify addon loaded message appears in chat on login
4. `/dl help` - verify help text lists all commands
5. `/dl status` - verify status output shows current settings
6. `/dl config` - verify config window opens with all tab groups
7. `/dl config` again - verify config window toggles closed
8. `/dl` - verify addon toggles disabled, then `/dl` again to re-enable
9. `/dl enable` and `/dl disable` - verify explicit enable/disable
10. `/dl minimap` - verify minimap icon toggles visibility
11. `/dl reset` - verify message about loot frame not yet available
12. `/dl test` - verify message about test loot not yet available
13. Left-click minimap icon - verify config window opens
14. Right-click minimap icon - verify addon toggles enabled/disabled
15. Shift-left-click minimap icon - verify test message prints
16. Hover minimap icon - verify tooltip shows name, status, and shortcuts
17. `/dl unknowncommand` - verify unknown command message and help output
18. `/dragonloot help` - verify long alias works

---

## Known Gotchas

1. **GetItemInfo may return nil** on first call if item not cached - handle with retry timers
2. **CHAT_MSG_LOOT patterns are localized** - parsing requires Lua pattern matching on localized strings
3. **TOC conditional loading** - Mid-file `## Interface:` directives don't work. Use BigWigsMods packager comment directives (`#@retail@`, `#@tbc-anniversary@`, `#@version-mists@`)
4. **pull_request vs pull_request_target** - GitHub doesn't trigger `pull_request` workflows for PRs created by GITHUB_TOKEN (release-please). Use `pull_request_target` for lint workflows
5. **Blizzard frame suppression** - Must restore events on disable or the default loot window breaks permanently for the session
