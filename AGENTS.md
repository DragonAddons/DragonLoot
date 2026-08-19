# DragonLoot AGENTS.md

## Target Versions

| Version           | Interface | TOC Directive               |
| ----------------- | --------- | --------------------------- |
| Retail (Midnight) | 120005    | `## Interface: 120005`      |
| TBC Anniversary   | 20505     | `## Interface-BCC: 20505`   |
| MoP Classic       | 50503     | `## Interface-Mists: 50503` |

Version-specific files load via BigWigsMods packager comment directives (`#@retail@` / `#@non-retail@`) in the TOC.

## Project Structure

The repository is structured as a multi-addon project separating core logic, configuration companion, and testing/tooling:

- **`DragonLoot/`** (Core Addon)
  - `Core/`: Core bootstrap (`Init.lua`), addon lifecycle (`Lifecycle.lua`), AceDB database configurations, slash commands, and the minimap icon.
  - `Display/`: Custom loot frames (`LootFrame.lua`), roll frames (`RollFrame.lua`), history window (`HistoryFrame.lua`), and associated UI/layout animations.
  - `Listeners/`: Event listeners handling version-specific API differences (e.g., `LootListener_Retail.lua` vs. `LootListener_Classic.lua`). Uses packager directives (`#@retail@` / `#@non-retail@`) to load correct listeners.
  - `Locales/`: Localized strings for translation support.
  - `Libs/`: Embedded external libraries (Ace3, LibSharedMedia-3.0, LibAnimate, etc.).
- **`DragonLoot_Options/`** (Load-on-Demand Configuration)
  - A separate companion addon loaded on-demand when the user opens the options interface.
  - Contains individual tabs for configuring appearance, animations, roll frame, and history settings, and embeds the custom `DragonWidgets` library.
- **`spec/`** (Testing Suite)
  - Contains the busted unit test suite (`Config_spec.lua`, `Lifecycle_spec.lua`, `MasterLoot_spec.lua`) and a comprehensive WoW API mock harness (`wow_mock.lua`).

## Config Schema Reference

### Appearance (`db.profile.appearance`)

| Key               | Type    | Default                |
| ----------------- | ------- | ---------------------- |
| font              | string  | "Friz Quadrata TT"     |
| fontSize          | number  | 12                     |
| fontOutline       | string  | "OUTLINE"              |
| lootIconSize      | number  | 36                     |
| rollIconSize      | number  | 36                     |
| historyIconSize   | number  | 24                     |
| qualityBorder     | boolean | true                   |
| backgroundColor   | table   | {r=0.05,g=0.05,b=0.05} |
| backgroundAlpha   | number  | 0.9                    |
| backgroundTexture | string  | "Solid"                |
| borderColor       | table   | {r=0.3,g=0.3,b=0.3}    |
| borderSize        | number  | 1                      |
| borderTexture     | string  | "None"                 |

### Animation (`db.profile.animation`)

| Key           | Type    | Default        |
| ------------- | ------- | -------------- |
| enabled       | boolean | true           |
| openDuration  | number  | 0.3            |
| closeDuration | number  | 0.5            |
| lootOpenAnim  | string  | "fadeIn"       |
| lootCloseAnim | string  | "fadeOut"      |
| rollShowAnim  | string  | "slideInRight" |
| rollHideAnim  | string  | "fadeOut"      |

### Roll Frame (`db.profile.rollFrame`)

| Key                      | Type    | Default                 |
| ------------------------ | ------- | ----------------------- |
| enabled                  | boolean | true                    |
| scale                    | number  | 1.0                     |
| lock                     | boolean | false                   |
| autoConfirmRolls         | boolean | false                   |
| keepOpenAfterVote        | boolean | false                   |
| resultLingerDuration     | number  | 3                       |
| showRollTally            | boolean | false                   |
| timerBarHeight           | number  | 12                      |
| timerBarTexture          | string  | "Blizzard"              |
| timerBarBorder           | boolean | false                   |
| timerBarBorderColor      | table   | {r=0.3,g=0.3,b=0.3}     |
| timerBarColorMode        | string  | "gradient"              |
| timerBarColor            | table   | {r=0,g=1,b=0}           |
| timerBarBackgroundColor  | table   | {r=0.1,g=0.1,b=0.1}     |
| timerBarBackgroundAlpha  | number  | 0.8                     |
| frameWidth               | number  | 328                     |
| rowSpacing               | number  | 4                       |
| timerBarSpacing          | number  | 4                       |
| contentPadding           | number  | 4                       |
| buttonSize               | number  | 24                      |
| buttonSpacing            | number  | 4                       |
| frameSpacing             | number  | 4                       |
| frameMinHeight           | number  | 68                      |
| compactTextLayout        | boolean | false                   |
| iconPosition             | string  | "inside"                |
| iconSide                 | string  | "left"                  |
| iconOffsetX              | number  | 0                       |
| iconOffsetY              | number  | 0                       |
| iconOutsideGap           | number  | 4                       |
| timerBarStyle            | string  | "normal"                |
| timerBarMinimalHeight    | number  | 3                       |

`resultLingerDuration` applies only when `keepOpenAfterVote` is enabled. `showRollTally` is available only on Classic (TBC/MoP); Retail removed `C_LootHistory.GetItem` and `GetPlayerInfo` in patch 10.1.0.

### History (`db.profile.history`)

| Key              | Type    | Default |
| ---------------- | ------- | ------- |
| enabled          | boolean | true    |
| maxEntries       | number  | 50      |
| autoShow         | boolean | false   |
| lock             | boolean | false   |
| trackDirectLoot  | boolean | true    |
| minQuality       | number  | 2       |
| rowHeightPadding | number  | 6       |

## Version-Specific API Differences

| Aspect                              | Retail                        | Classic (TBC/MoP)       |
| ----------------------------------- | ----------------------------- | ----------------------- |
| GetLootSlotInfo returns             | 10                            | 6                       |
| GetLootRollItemInfo returns         | 13 (incl canTransmog)         | 12                      |
| C_LootHistory                       | Encounter-based               | Roll-item indexed       |
| C_LootHistory.GetItem/GetPlayerInfo | Removed in 10.1.0             | Available               |
| CANCEL_ALL_LOOT_ROLLS               | Yes                           | No                      |
| LOOT_READY event                    | Yes (fires after LOOT_OPENED) | No                      |
| C_Loot.GetLootRollDuration          | Yes                           | No                      |
| Loot listener                       | LootListener_Retail           | LootListener_Classic    |
| Roll listener                       | RollListener_Retail           | RollListener_Classic    |
| History listener                    | HistoryListener_Retail        | HistoryListener_Classic |

## DragonToast Integration

### Messages Sent by DragonLoot

| Message                   | Payload                        | When                   |
| ------------------------- | ------------------------------ | ---------------------- |
| `DRAGONTOAST_SUPPRESS`    | `"DragonLoot"` (source string) | Loot window opens      |
| `DRAGONTOAST_UNSUPPRESS`  | `"DragonLoot"` (source string) | Loot window closes     |
| `DRAGONTOAST_QUEUE_TOAST` | toast data table (see below)   | A player wins a roll   |
| `DRAGONTOAST_QUEUE_TOAST` | toast data table (see below)   | Individual roll result |

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

## Just Recipes

DragonLoot ships a `justfile` in addition to `.mise.toml`.

| Command          | Description                              |
| ---------------- | ---------------------------------------- |
| `just`           | List all recipes                         |
| `just test`      | Run busted test suite                    |
| `just lint`      | Run luacheck                             |
| `just fmt`       | Format Lua with StyLua                   |
| `just fmt-check` | Check formatting without modifying files |
| `just check`     | Run fmt-check + lint + test              |

StyLua config (`.stylua.toml`): 120-char width, 4-space indent, double quotes, Unix line endings, always parenthesized calls.
 
## Known Gotchas

1. **CHAT_MSG_LOOT patterns are localized** - parsing requires Lua pattern matching on localized strings
2. **Blizzard frame suppression** - Must restore events on disable or the default loot window breaks permanently for the session
3. **Retail C_LootHistory duplicate events** - LOOT_HISTORY_UPDATE_ENCOUNTER re-fires for all drops; use processedDrops dedup table
4. **Retail API field names** - `winner.playerClass` not `winner.className` in C_LootHistory
5. **Classic double-open** - LOOT_OPENED can fire twice; guard with `if isLootOpen then return end`
6. **Roll data availability** - Fetch item info via GetLootRollItemInfo BEFORE calling CancelRoll, as data is lost after cancel
7. **Local dev listener loading** - Packager directives (`#@retail@`, `#@non-retail@`) are plain comments locally, so both Retail and Classic listeners are loaded in dev. `IsRetail` / `IsClassic` version guards inside each file ensure only the correct one activates
8. **NOTIFICATION_STATE_MAP vs ROLL_STATE_MAP** - `ROLL_STATE_MAP` in HistoryListener_Retail maps Transmog->Greed (lossy) for history display. `ns.NOTIFICATION_STATE_MAP` in RollManager preserves Transmog as a distinct roll type for notifications
9. **Classic LOOT_HISTORY_ROLL_CHANGED timing** - May fire before roll value is assigned; ProcessClassicRollResult skips non-Pass rolls with nil roll values and relies on a later re-fire with the value
10. **Roll result dedup** - Both Retail and Classic listeners use `notifiedRollResults` tables to prevent duplicate notifications per player per drop; tables are wiped on history clear and shutdown
11. **CHAT_MSG_LOOT GlobalStrings differ by version** - TBC self-loot patterns have trailing periods, Retail does not. Build patterns from actual GlobalString values at runtime, never hardcode
12. **Classic Master Loot No-Payload Constraint** - The OPEN_MASTER_LOOT_LIST event has no payload. To handle this, LootFrame.lua:OnSlotClick stashes the slot index in s.pendingMasterLootSlot immediately before calling LootSlot(slotIndex). MasterLootListener_Classic consumes this value during the event. This state is carefully cleaned up on list consumption, window close, or addon disable to prevent dangling/leaking references.

## Labels

| Label                | Description                                       |
| -------------------- | ------------------------------------------------- |
| **Category**         |                                                   |
| `C-Bug`              | Unexpected or incorrect behavior                  |
| `C-Feature`          | New feature or enhancement                        |
| `C-Performance`      | Speed, memory, or efficiency improvement          |
| `C-Usability`        | UX improvement, better defaults, polish           |
| `C-Code-Quality`     | Refactor, cleanup, technical debt                 |
| `C-Documentation`    | Docs, README, AGENTS.md, comments                 |
| `C-Localization`     | Translation and locale support                    |
| **Area**             |                                                   |
| `A-Core`             | Addon lifecycle, slash commands, minimap icon     |
| `A-LootWindow`       | Custom loot frame and loot animations             |
| `A-History`          | Loot history frame and history listeners          |
| `A-RollFrame`        | Roll frames, timer bars, roll manager             |
| `A-Config`           | Options table, config window, AceDB               |
| `A-Listeners`        | Event listeners and version-specific loot parsing |
| `A-Integration`      | DragonToast messaging and cross-addon APIs        |
| `A-Appearance`       | Fonts, textures, borders, backdrops, animations   |
| `A-CI`               | Workflows, packaging, release pipeline            |
| **Difficulty**       |                                                   |
| `D-Good-First-Issue` | Good for newcomers or contributors                |
| `D-Straightforward`  | Clear scope, low risk                             |
| `D-Complex`          | Multiple files or systems involved                |
| `D-Expert`           | Deep WoW API knowledge or tricky edge cases       |
| **Platform**         |                                                   |
| `P-Retail`           | Retail-specific (11.x / 12.x)                     |
| `P-TBC-Anniversary`  | TBC Anniversary Classic                           |
| `P-MoP-Classic`      | Mists of Pandaria Classic                         |
| `P-All-Versions`     | Affects all supported WoW versions                |
| **Status**           |                                                   |
| `S-Needs-Triage`     | New issue awaiting review                         |

## GitHub Projects

- **DragonLoot - Bugs**: project #5 (`C-Bug` issues)
- **DragonLoot - Feature Requests**: project #4 (`C-Feature` issues)
