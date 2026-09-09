<div align="center">

![Dragon Loot Logo](https://raw.githubusercontent.com/Xerrion/DragonLoot/refs/heads/master/assets/dragon-loot.png)

# Dragon Loot

*A customizable loot window and roll frame replacement for World of Warcraft*

[![Latest Release](https://img.shields.io/github/v/release/Xerrion/DragonLoot?style=for-the-badge)](https://github.com/Xerrion/DragonLoot/releases/latest)
[![License](https://img.shields.io/github/license/Xerrion/DragonLoot?style=for-the-badge)](https://github.com/Xerrion/DragonLoot/blob/master/LICENSE)
[![CurseForge](https://img.shields.io/badge/CurseForge-1472582-f16436?style=for-the-badge&logo=curseforge)](https://www.curseforge.com/wow/addons/dragon-loot)
[![Wago](https://img.shields.io/badge/Wago-qKQmADKx-c0392b?style=for-the-badge&logo=wago)](https://addons.wago.io/addons/dragon-loot)
[![WoW Versions](https://img.shields.io/badge/WoW-Retail%20%7C%20MoP%20Classic%20%7C%20TBC%20Anniversary-blue?style=for-the-badge&logo=battledotnet)](https://worldofwarcraft.blizzard.com/)
[![Lint](https://img.shields.io/github/actions/workflow/status/Xerrion/DragonLoot/lint.yml?style=for-the-badge&label=luacheck)](https://github.com/Xerrion/DragonLoot/actions)

</div>

DragonLoot replaces the default Blizzard loot window and roll frame with cleaner, more configurable replacements, and
adds a dedicated loot history panel for tracking drops and winners.

## 🐉 Features

- **Modernized UI**: Replaces the Blizzard loot window, roll frames, and introduces a loot history panel.
- **Advanced Roll Frames**: Custom frames featuring timer bars, an overflow FIFO queue, item-level overlays, and
  configurable layouts (including 3-row mode and hide-after-voting).
- **Loot History**: Track drops with class-colored winners, time-ago refresh intervals, and direct loot tracking via
  `CHAT_MSG_LOOT` for items picked up without a roll.
- **Smart Notifications**: Filter Need, Greed, Disenchant, and Transmog notifications by instance type and item quality.
- **DragonToast Integration**: Suppresses duplicate toasts during loot and queues celebration or result toasts.
- **ElvUI Compatibility**: Detects conflicting ElvUI loot modules and provides a one-time prompt to disable them.
- **Complete Customization**: Control fonts (including outlines), per-frame icon sizes, quality-colored borders, LSM
  textures, and frame colors/transparency.
- **Animated Transitions**: Powered by LibAnimate with 4 selectable open/close styles and configurable durations.
- **Modern Addon Stack**: Minimap button support (LibDBIcon), AceDB profile management, and support for 11 locales.
- **Performance Optimized**: Companion `DragonLoot_Options` addon is LoadOnDemand to keep memory usage low during play.

## 🎮 Supported Versions

| Client | Interface Versions |
|---|---|
| Retail | 120005 |
| TBC Anniversary | 20505 |
| MoP Classic | 50503 |

## 📦 Installation

### Download

Available on major platforms:

- [**CurseForge**](https://www.curseforge.com/wow/addons/dragon-loot)
- [**Wago.io**](https://addons.wago.io/addons/dragon-loot)
- [**GitHub Releases**](https://github.com/Xerrion/DragonLoot/releases/latest)

### Manual Install

1. Download the latest release.
2. Extract the `DragonLoot` and `DragonLoot_Options` folders into your AddOns directory:
   - `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart World of Warcraft or type `/reload` in-game.

## 🧩 Sub-addons

DragonLoot is split into two modules to optimize performance:
- **DragonLoot**: The core engine that handles loot, rolls, and history. Always loaded.
- **DragonLoot_Options**: The configuration interface. It only loads when you open the settings panel and embeds the
  DragonWidgets shared library.

## ⌨️ Slash Commands

Use `/dl` or the alias `/dragonloot`.

| Command | Description |
|---|---|
| `/dl` | Toggle the addon on or off |
| `/dl toggle` | Explicitly toggle the addon on or off |
| `/dl enable` | Enable the addon |
| `/dl disable` | Disable the addon |
| `/dl config` | Open the options panel (aliases: `options`, `settings`) |
| `/dl history` | Open the loot history panel |
| `/dl test` | Spawn a single test roll |
| `/dl testroll loop` | Start continuous test roll spawning |
| `/dl testroll stop` | Stop continuous test roll spawning |
| `/dl reset` | Reset frame positions to defaults |
| `/dl version` | Print current version information |
| `/dl help` | Show the command list (alias: `?`) |

## ⚙️ Configuration

Settings are stored in `DragonLootDB` using AceDB profiles.

| Tab | Settings |
|---|---|
| **General** | Addon toggle, UI lock, minimap icon, DragonToast suppression |
| **Loot Window** | Open at mouse, scale, lock, slot count, icon size |
| **Loot Roll** | 3-row layout, hide after voting, item-level overlay, timer texture, stack direction |
| **Notifications** | Roll type filters (Need/Greed/etc), instance filters, quality threshold, group wins |
| **History** | Auto-open on loot, max entries, direct loot tracking, minimum quality threshold |
| **AutoLoot** | Enable, quality threshold, exclusion list |
| **Appearance** | Fonts, outlines, per-frame icon sizes, quality borders, background/border styling |
| **Animation** | Toggle, selectable open/close styles (4 types), duration sliders |
| **Profiles** | Standard AceDB profile management (Save/Copy/Reset) |

## 🔗 DragonToast Integration

DragonLoot features built-in integration with [DragonToast](https://github.com/Xerrion/DragonToast). It uses a
fire-and-forget communication system (AceComm) to:
- **Suppress**: Sends `DRAGONTOAST_SUPPRESS` when loot opens so DragonToast doesn't show duplicate loot alerts.
- **Unsuppress**: Sends `DRAGONTOAST_UNSUPPRESS` when the loot window closes.
- **Celebrate**: Sends `DRAGONTOAST_QUEUE_TOAST` to trigger celebratory notifications for roll wins.

This integration has no hard dependency; DragonLoot works perfectly fine without DragonToast.

## 🛡️ ElvUI Compatibility

DragonLoot automatically detects if ElvUI's built-in loot module is active. To prevent visual conflicts, it will prompt
you once to disable the ElvUI loot module. Your choice is remembered, and you can change it at any time in the ElvUI
settings.

## 🌐 Localization

DragonLoot is localized for the following regions:
`enUS, deDE, esES, esMX, frFR, itIT, koKR, ptBR, ruRU, zhCN, zhTW`.

Translation contributions are welcome! Please submit a pull request or open an issue on GitHub if you would like to
improve a specific locale.

## 🤝 Contributing

Contributions are welcome! Please refer to [AGENTS.md](AGENTS.md) for full coding conventions.

- **Linting**: Run `luacheck .` or `just lint`
- **Testing**: Run `busted --verbose` or `just test`
- **Formatting**: Uses `stylua` (`just fmt`)
- **Toolchain**: Managed via `mise` (Lua 5.1) and `just` recipes.

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](https://github.com/Xerrion/DragonLoot/blob/master/LICENSE)
file for details.

Made with ❤️ by [Xerrion](https://github.com/Xerrion)