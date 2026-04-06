# DragonLoot - Agent Guidelines

Project-specific guidelines for DragonLoot. See the parent `../AGENTS.md` for general WoW addon development rules.

---

## Overview

DragonLoot is a customizable loot addon that replaces the default Blizzard loot window, loot roll views, and provides a loot history frame.

**Status**: Feature-complete. Loot window, roll frame, loot history, config wiring, edge case fixes, DragonToast integration, individual roll notifications, instance-type filtering, appearance expansion (font outline, quality borders, background/border customization), and direct loot history tracking (CHAT_MSG_LOOT) are all implemented.

**GitHub**: https://github.com/Xerrion/DragonLoot

---

## Skills

Every `coder` delegation on this project must specify which skills to load. Use this matrix:

| Skill | When to load |
|-------|-------------|
| `code-philosophy` | All code changes (always) |
| `architecture-philosophy` | New modules, file structure, namespace design, layer boundaries |
| `wow-lua-patterns` | All WoW addon Lua (always) |
| `wow-frame-api` | Any UI frame creation, widget layout, anchoring, backdrop, textures |
| `wow-event-handling` | Any event registration, addon lifecycle, ADDON_LOADED, combat lockdown |

Use the `wow-addon` agent (not `coder`) for WoW API research before implementation when API correctness is uncertain. `wow-addon` is research-only; `coder` does the implementation.

Do **not** tell `coder` to load `wow-addon-dev` - that skill documents research tools only the `wow-addon` agent can use.

Never guess at WoW API signatures. Always verify with the `wow-addon` agent using `wow-api-lookup` first.

---

## Target Versions

| Version | Interface | TOC Directive |
|---------|-----------|---------------|
| Retail | 110207, 120001, 120000 | `## Interface: 110207, 120001, 120000` |
| TBC Anniversary | 20505 | `## Interface-BCC: 20505` |
| Cata Classic | 40402 | `## Interface-Cata: 40402` |
| MoP Classic | 50503 | `## Interface-Mists: 50503` |

Version-specific files are loaded via BigWigsMods packager comment directives (`#@retail@` / `#@tbc-anniversary@` / `#@version-mists@` / `#@version-cata@`) in the TOC.

---

## Architecture

| Layer | Directory | Responsibility |
|-------|-----------|----------------|
| Core | `DragonLoot/Core/` | Addon lifecycle, config, slash commands, minimap icon |
| Display | `DragonLoot/Display/` | UI frames and presentation (loot window, roll frame, history) |
| Listeners | `DragonLoot/Listeners/` | Event handling and version-specific loot/roll/history parsing |
| Libs | `DragonLoot/Libs/` | Embedded Ace3 + utility libraries |

### File Map

| File | Purpose |
|------|---------|
| `DragonLoot/Core/Init.lua` | AceAddon bootstrap, lifecycle, Blizzard frame suppression |
| `DragonLoot/Core/Config.lua` | AceDB defaults, AceConfig options table, schema migration |
| `DragonLoot/Core/ConfigWindow.lua` | AceConfigDialog toggle |
| `DragonLoot/Core/MinimapIcon.lua` | LDB + LibDBIcon minimap button |
| `DragonLoot/Core/SlashCommands.lua` | `/dl` and `/dragonloot` command router |
| `DragonLoot/Display/LootFrame.lua` | Loot window frame pool, slot rendering, drag/position, test loot |
| `DragonLoot/Display/LootAnimations.lua` | LibAnimate animations for loot window (configurable via config) |
| `DragonLoot/Display/RollFrame.lua` | Roll frame pool (up to 4), timer bar, Need/Greed/DE/Pass/Transmog buttons |
| `DragonLoot/Display/RollAnimations.lua` | LibAnimate animations for roll frames (configurable via config) |
| `DragonLoot/Display/RollManager.lua` | Roll orchestration, overflow FIFO queue, timer tick, DRAGONTOAST_QUEUE_TOAST messaging |
| `DragonLoot/Display/HistoryFrame.lua` | Scrollable loot history, entry pool, class-colored winners, time-ago refresh |
| `DragonLoot/Listeners/LootListener_Retail.lua` | Retail: LOOT_OPENED + LOOT_READY with pendingAutoLoot |
| `DragonLoot/Listeners/LootListener_Classic.lua` | Classic: LOOT_OPENED for TBC/MoP/Cata |
| `DragonLoot/Listeners/RollListener_Retail.lua` | Retail: START_LOOT_ROLL, CANCEL_LOOT_ROLL, CANCEL_ALL_LOOT_ROLLS, recovery |
| `DragonLoot/Listeners/RollListener_Classic.lua` | Classic: same minus CANCEL_ALL_LOOT_ROLLS |
| `DragonLoot/Listeners/HistoryListener_Retail.lua` | Retail: encounter-based C_LootHistory with dedup |
| `DragonLoot/Listeners/HistoryListener_Classic.lua` | Classic: roll-item indexed C_LootHistory |
| `DragonLoot/Listeners/LootHistoryChat.lua` | CHAT_MSG_LOOT parser for direct loot tracking (all versions) |

### Namespace Pattern

All files use the shared private namespace:
```lua
local ADDON_NAME, ns = ...
```

### Namespace Sub-tables

All modules attach to `ns`:

| Sub-table | Set by |
|-----------|--------|
| `ns.Addon` | `DragonLoot/Core/Init.lua` |
| `ns.LootFrame` | `DragonLoot/Display/LootFrame.lua` |
| `ns.LootAnimations` | `DragonLoot/Display/LootAnimations.lua` |
| `ns.RollFrame` | `DragonLoot/Display/RollFrame.lua` |
| `ns.RollAnimations` | `DragonLoot/Display/RollAnimations.lua` |
| `ns.RollManager` | `DragonLoot/Display/RollManager.lua` |
| `ns.HistoryFrame` | `DragonLoot/Display/HistoryFrame.lua` |
| `ns.LootListener` | `DragonLoot/Listeners/LootListener_*.lua` |
| `ns.RollListener` | `DragonLoot/Listeners/RollListener_*.lua` |
| `ns.HistoryListener` | `DragonLoot/Listeners/HistoryListener_*.lua` |
| `ns.LootHistoryChat` | `DragonLoot/Listeners/LootHistoryChat.lua` |
| `ns.ConfigWindow` | `DragonLoot/Core/ConfigWindow.lua` |
| `ns.MinimapIcon` | `DragonLoot/Core/MinimapIcon.lua` |
| `ns.Print` | `DragonLoot/Core/Init.lua` (helper function) |
| `ns.DebugPrint` | `DragonLoot/Core/Init.lua` (helper function) |

### Config Schema Reference

#### Appearance Config (`db.profile.appearance`)

| Key                | Type    | Default              | Description                       |
|--------------------|---------|----------------------|-----------------------------------|
| font               | string  | "Friz Quadrata TT"  | LSM font name                     |
| fontSize           | number  | 12                   | Font size (8-20)                  |
| fontOutline        | string  | "OUTLINE"            | Font outline style                |
| lootIconSize       | number  | 36                   | Loot window icon size (16-64)     |
| rollIconSize       | number  | 36                   | Roll frame icon size (16-64)      |
| historyIconSize    | number  | 24                   | History frame icon size (16-48)   |
| qualityBorder      | boolean | true                 | Show quality-colored icon borders |
| backgroundColor    | table   | {r=0.05,g=0.05,b=0.05} | Frame background color         |
| backgroundAlpha    | number  | 0.9                  | Frame background opacity (0-1)    |
| backgroundTexture  | string  | "Solid"              | LSM background key for bg         |
| borderColor        | table   | {r=0.3,g=0.3,b=0.3} | Frame border color                |
| borderSize         | number  | 1                    | Border thickness (0-4)            |
| borderTexture      | string  | "None"               | LSM border key for border         |

#### Animation Config (`db.profile.animation`)

| Key                | Type    | Default              | Description                       |
|--------------------|---------|----------------------|-----------------------------------|
| enabled            | boolean | true                 | Enable/disable animations         |
| openDuration       | number  | 0.3                  | Open animation duration (seconds) |
| closeDuration      | number  | 0.5                  | Close animation duration (seconds)|
| lootOpenAnim       | string  | "fadeIn"             | LibAnimate animation name for loot window open  |
| lootCloseAnim      | string  | "fadeOut"            | LibAnimate animation name for loot window close |
| rollShowAnim       | string  | "slideInRight"      | LibAnimate animation name for roll frame entrance |
| rollHideAnim       | string  | "fadeOut"            | LibAnimate animation name for roll frame exit   |

#### Roll Frame Config (`db.profile.rollFrame`)

| Key              | Type   | Default     | Description                     |
|------------------|--------|-------------|---------------------------------|
| timerBarTexture  | string | "Blizzard"  | LSM statusbar texture for timer |

> The table above shows a partial list. See `DragonLoot/Config.lua` for the full `rollFrame` schema (~25 keys).

#### History Config (`db.profile.history`)

| Key              | Type    | Default | Description                           |
|------------------|---------|---------|---------------------------------------|
| enabled          | boolean | true    | Enable loot history tracking          |
| maxEntries       | number  | 50      | Maximum history entries to display    |
| autoShow         | boolean | false   | Auto-show history on new loot         |
| lock             | boolean | false   | Lock history frame position           |
| trackDirectLoot  | boolean | true    | Track items picked up directly        |
| minQuality       | number  | 2       | Minimum quality for direct loot (0-5) |

---

## Version-Specific API Differences

> **Note**: This table is a quick reference. Always verify exact signatures, parameter counts, and return types using the `wow-api-lookup` tool from the `wow-addon-dev` skill.

| Aspect | Retail | Classic (TBC/Cata/MoP) |
|--------|--------|------------------------|
| GetLootSlotInfo returns | 10 | 6 |
| GetLootRollItemInfo returns | 13 (incl canTransmog) | 12 |
| C_LootHistory | Encounter-based | Roll-item indexed |
| CANCEL_ALL_LOOT_ROLLS | Yes | No |
| LOOT_READY event | Yes (fires after LOOT_OPENED) | No |
| C_Loot.GetLootRollDuration | Yes | No |
| Loot listener | LootListener_Retail | LootListener_Classic |
| Roll listener | RollListener_Retail | RollListener_Classic |
| History listener | HistoryListener_Retail | HistoryListener_Classic |

---

## DragonToast Integration

DragonLoot integrates with DragonToast (sibling addon) via the generic DragonToast messaging API. Messages are fire-and-forget - no detection needed. Neither addon requires the other.

### Messages Sent by DragonLoot

DragonLoot uses the generic DragonToast messaging API (fire-and-forget, no detection needed):

| Message | Payload | When |
|---------|---------|------|
| `DRAGONTOAST_SUPPRESS` | `"DragonLoot"` (source string) | Loot window opens |
| `DRAGONTOAST_UNSUPPRESS` | `"DragonLoot"` (source string) | Loot window closes |
| `DRAGONTOAST_QUEUE_TOAST` | toast data table (see below) | A player wins a roll |
| `DRAGONTOAST_QUEUE_TOAST` | toast data table (see below) | Individual roll result |

#### Roll Won Toast Data

```lua
{
    itemLink = string,     -- full item hyperlink
    itemName = string,     -- item name
    itemQuality = number,  -- 0-7 quality enum
    itemIcon = number,     -- icon texture ID
    itemID = number,       -- parsed from itemLink
    quantity = number,     -- stack count
    isRollWin = true,      -- suppression bypass flag
    isSelf = boolean,      -- true if current player won
    looter = string,       -- winner's name
    itemType = string,     -- e.g. "Need (87)" for display
    timestamp = number,    -- GetTime()
}
```

#### Individual Roll Result Toast Data

```lua
{
    itemLink = string,     -- full item hyperlink
    itemName = string,     -- item name
    itemQuality = number,  -- 0-7 quality enum
    itemIcon = number,     -- icon texture ID
    itemID = number,       -- parsed from itemLink
    quantity = 1,          -- always 1
    isRollWin = false,     -- not a win notification
    isSelf = boolean,      -- true if current player rolled
    looter = string,       -- roller's name
    itemType = string,     -- e.g. "Need (87)" or "Greed (42)" for display
    timestamp = number,    -- GetTime()
}
```

### DragonToast Behavior

- `DRAGONTOAST_SUPPRESS` with source `"DragonLoot"` sets a suppress flag; item loot toasts are suppressed while DragonLoot's loot window is open
- `DRAGONTOAST_UNSUPPRESS` with source `"DragonLoot"` clears the suppress flag
- `DRAGONTOAST_QUEUE_TOAST` with `isRollWin = true` triggers a celebration toast
- `DRAGONTOAST_QUEUE_TOAST` with `isRollWin = false` triggers a standard item toast (individual roll result)
- XP, honor, currency toasts are never suppressed
- DragonToast's `Listeners/MessageBridge.lua` handles backward compatibility for old message names (`DRAGONLOOT_LOOT_OPENED`, `DRAGONLOOT_LOOT_CLOSED`, `DRAGONLOOT_ROLL_WON`)

---

## Placeholders

The following values are placeholders and must be updated before first release:

| Item | Placeholder | File |
|------|-------------|------|
| CurseForge Project ID | `0000000` | `DragonLoot/DragonLoot.toc` |
| Wago ID | `TBD` | `DragonLoot/DragonLoot.toc` |
| Icon texture | `Interface\AddOns\DragonLoot\DragonLoot_Icon` | `DragonLoot/DragonLoot.toc` |

---

## Ace3 Stack

DragonLoot embeds Ace3 via `Libs/embeds.xml`. The full Ace3 library set is available:

| Library | Usage |
|---------|-------|
| AceAddon | Addon lifecycle |
| AceEvent | Event registration + inter-addon messaging |
| AceTimer | Timers (history refresh, roll tick) |
| AceDB | SavedVariables + profiles |
| AceConfig | Options table registration |
| AceConfigDialog | Blizzard settings integration |
| AceGUI | Standalone config window |
| AceConsole | Slash command registration |
| AceHook | Hook management |
| LibSharedMedia-3.0 | Font/texture selection |
| LibDataBroker-1.1 | Data source for minimap icon |
| LibDBIcon-1.0 | Minimap button |
| LibAnimate | Animation library (user-configurable via Animation config tab) |
| AceGUI-SharedMediaWidgets | SharedMedia dropdowns in AceGUI |

### Local Dev: Ace3 Submodule

`.pkgmeta` externals only work during CI packaging. For local dev, add Ace3 as a git submodule at `DragonLoot/Libs/Ace3/`.

---

## CI/CD

### Workflows

| File | Trigger | Purpose |
|------|---------|---------|
| `lint.yml` | `pull_request_target` to master | Luacheck (uses `pull_request_target` so it runs on release-please bot PRs) |
| `release.yml` | `push` to master | release-please creates/updates a Release PR; dispatches `packager.yml` on release |
| `packager.yml` | `workflow_dispatch` (from release.yml) | BigWigsMods packager builds and uploads to CurseForge, Wago, and GitHub Releases |

### Branch Protection

- PRs required to merge into `master`
- Luacheck status check must pass
- Branches must be up to date before merging
- No force pushes to `master`
- Squash merge only
- Auto-delete head branches after merge

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

Create a directory junction from the WoW addons folder to the `DragonLoot/` subdirectory in the repo (not the repo root):
```powershell
New-Item -ItemType Junction -Path "E:\World of Warcraft\_anniversary_\Interface\AddOns\DragonLoot" -Target "F:\Repos\wow-addons\DragonLoot\DragonLoot"
```

---

## Code Style

### Formatting
- Indent with **4 spaces**, no tabs
- Max line length **120** unless the addon `.luacheckrc` disables it
- Spaces around operators: `local x = 1 + 2`
- No trailing whitespace
- Use plain hyphens (`-`), **never** em or en dashes

### File Header
Every Lua file starts with:

```lua
-------------------------------------------------------------------------------
-- FileName.lua
-- Brief description
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------
```

### Imports and Scoping
- Use the shared namespace: `local ADDON_NAME, ns = ...`
- Cache WoW API and Lua globals used more than once as locals at the top of the file
- Keep addon logic in locals; only SavedVariables and `SLASH_*` are global
- Use `LibStub` for Ace3 or other embedded libs; never global `require`

```lua
local ADDON_NAME, ns = ...
local CreateFrame = CreateFrame
local GetTime = GetTime
local LSM = LibStub("LibSharedMedia-3.0")
```

### Naming

| Element | Convention | Example |
|---------|------------|---------|
| Files | PascalCase | `MyAddon_Core.lua` |
| SavedVariables | PascalCase | `MyAddonDB` |
| Local variables | camelCase | `local currentState` |
| Functions (public or local) | PascalCase | `local function UpdateState()` |
| Constants | UPPER_SNAKE | `local MAX_RETRIES = 5` |
| Slash commands | UPPER_SNAKE | `SLASH_MYADDON1` |
| Color codes | UPPER_SNAKE | `local COLOR_RED = "\|cffff0000"` |
| Unused args | underscore prefix | `local _unused` |

### Types
- Default to plain Lua 5.1 with no annotations
- Only add LuaLS annotations when the file already uses them or for public library APIs
- Keep annotations minimal and accurate; do not introduce new tooling
- LuaLS annotations for WoW APIs are available via the `wow-addon-dev` skill for reference, but do not add them to addon source files unless already present

### Functions and Structure
- Keep functions under 50 lines; extract helpers when longer
- Prefer early returns over deep nesting
- Prefer composition over inheritance
- Keep logic separated by layer when possible: Core (WoW API), Engine (pure Lua),
  Data (tables), Presentation (UI)

### Error Handling
- Use defensive nil checks for optional APIs
- For version differences, prefer `or` fallbacks over runtime version checks
- Use `pcall` for user callbacks or APIs that may be missing in some versions
- Use `error(msg, 2)` for public library input validation (reports at caller site)
- Always verify API signatures with `wow-api-lookup` before adding defensive checks - know what the API actually returns

---

## GitHub Workflow

### Issues
- Title format: `[Bug]: description` / `[Feature]: description`
- Always apply: one `C-*` (category), one `A-*` (area), one `D-*` (difficulty), one `P-*` (platform) label
- Use the repo's GitHub issue templates (bug-report or feature-request)
- Add new issues to the appropriate project and set status to **"To triage"**

### GitHub Projects
- **DragonLoot - Bugs**: project #5 (`C-Bug` issues)
- **DragonLoot - Feature Requests**: project #4 (`C-Feature` issues)
- Status columns: **To triage → Backlog → Ready → In progress → In review → Done**
- Move status as work progresses: filed (To triage) → scoped (Backlog) → branch created (In progress) → PR open (In review) → merged (Done)

### Branching and PRs
- Branch from `master`: `feat/<number>-short-desc`, `fix/<number>-short-desc`, `refactor/<number>-short-desc`
- One PR per issue; reference `Closes #N` in the PR body
- Fill the PR template fully (type of change, testing, checklist)
- CI must pass (`gh pr checks <N> --repo Xerrion/DragonLoot`) before merging
- Wait for CodeRabbit AI review to complete and address any findings before merging
- When replying to CodeRabbit review comments, always use `@coderabbitai` and always reply to the **specific comment thread** (not as a top-level PR comment)
- Squash merge only: `gh pr merge <N> --squash --delete-branch`
- **Never merge release-please PRs** (`chore(master): release X.Y.Z`) - the repo owner merges these manually

### Commits
- Conventional Commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- Reference issue numbers: `feat: add roll frame scaling (#92)`

---

## Known Gotchas

1. **GetItemInfo may return nil** on first call if item not cached - handle with retry timers
2. **CHAT_MSG_LOOT patterns are localized** - parsing requires Lua pattern matching on localized strings
3. **TOC conditional loading** - Mid-file `## Interface:` directives don't work. Use BigWigsMods packager comment directives (`#@retail@`, `#@tbc-anniversary@`, `#@version-mists@`, `#@version-cata@`)
4. **pull_request vs pull_request_target** - GitHub doesn't trigger `pull_request` workflows for PRs created by GITHUB_TOKEN (release-please). Use `pull_request_target` for lint workflows
5. **Blizzard frame suppression** - Must restore events on disable or the default loot window breaks permanently for the session
6. **Retail C_LootHistory duplicate events** - LOOT_HISTORY_UPDATE_ENCOUNTER re-fires for all drops; use processedDrops dedup table
7. **Retail API field names** - `winner.playerClass` not `winner.className` in C_LootHistory
8. **Classic double-open** - LOOT_OPENED can fire twice; guard with `if isLootOpen then return end`
9. **Roll data availability** - Fetch item info via GetLootRollItemInfo BEFORE calling CancelRoll, as data is lost after cancel
10. **Local dev listener loading** - All packager directives are comments locally; both Retail and Classic listeners load. Version guards (`WOW_PROJECT_ID` checks) in each file handle this correctly
11. **NOTIFICATION_STATE_MAP vs ROLL_STATE_MAP** - `ROLL_STATE_MAP` in HistoryListener_Retail maps Transmog->Greed (lossy) for history display. `ns.NOTIFICATION_STATE_MAP` in RollManager preserves Transmog as a distinct roll type for notifications
12. **Classic LOOT_HISTORY_ROLL_CHANGED timing** - May fire before roll value is assigned; ProcessClassicRollResult skips non-Pass rolls with nil roll values and relies on a later re-fire with the value
13. **Roll result dedup** - Both Retail and Classic listeners use `notifiedRollResults` tables to prevent duplicate notifications per player per drop; tables are wiped on history clear and shutdown
14. **CHAT_MSG_LOOT GlobalStrings differ by version** - TBC self-loot patterns have trailing periods, Retail does not. Build patterns from actual GlobalString values at runtime, never hardcode
15. **GetItemInfo nil on first call** - LootHistoryChat uses C_Timer.After(0.5) retry to update quality when GetItemInfo returns nil for uncached items

---

## Working Agreement for Agents
- Addon-level AGENTS.md overrides root rules when present
- Do not add new dependencies without discussing trade-offs
- Run luacheck before and after changes
- If only manual tests exist, document what you verified in-game
- Verify changes in the game client when possible
- Keep changes small and focused; prefer composition over inheritance
- Use the `wow-addon` agent to verify WoW API signatures before implementation - never guess at parameter counts or return types
- See `## Skills` above for the full skill-loading matrix for `coder` delegations

---

## Communication Style

When responding to or commenting on issues, always write in **first-person singular** ("I")
as the repo owner -- never use "we" or "our team". Speak as if you are the developer personally.

**Writing style:**
- Direct, structured, solution-driven. Get to the point fast. Text is a tool, not decoration.
- Think in systems. Break things into flows, roles, rules, and frameworks.
- Bias toward precision. Concrete output, copy-paste-ready solutions, clear constraints. Low
  tolerance for fluff.
- Tone is calm and rational with small flashes of humor and self-awareness.
- When confident in a topic, become more informal and creative.
- When something matters, become sharp and focused.
