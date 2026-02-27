<div align="center">

![Dragon Loot Logo](https://raw.githubusercontent.com/Xerrion/DragonLoot/refs/heads/main/assets/dragon-loot.png)

# Dragon Loot

*A customizable loot window and roll frame replacement for World of Warcraft*

[![Latest Release](https://img.shields.io/github/v/release/Xerrion/DragonLoot?style=for-the-badge)](https://github.com/Xerrion/DragonLoot/releases/latest)
[![License](https://img.shields.io/github/license/Xerrion/DragonLoot?style=for-the-badge)](LICENSE)
[![WoW Versions](https://img.shields.io/badge/WoW-Retail%20%7C%20MoP%20Classic%20%7C%20TBC%20Anniversary-blue?style=for-the-badge&logo=battledotnet)](https://worldofwarcraft.blizzard.com/)
[![Lint](https://img.shields.io/github/actions/workflow/status/Xerrion/DragonLoot/lint.yml?style=for-the-badge&label=luacheck)](https://github.com/Xerrion/DragonLoot/actions)

</div>

## 🐉 Features

- Replaces the default Blizzard loot window with a clean, modern design
- Custom loot roll frames with animated timer bars and overflow queue
- Loot roll history panel tracking recent rolls and winners
- Roll won notifications via DragonToast integration
- Individual roll result notifications (Need/Greed/Disenchant/Transmog)
- Instance-type filtering for roll notifications (world/dungeon/raid)
- Configurable minimum quality threshold for notifications
- Full appearance customization (fonts, icon size)
- Smooth open/close animations (powered by LibAnimate)
- Minimap button with LibDBIcon
- Profile support via AceDB

## 🎮 Supported Versions

| Version          | Interface              |
|:-----------------|:-----------------------|
| Retail           | 110207, 120001, 120000 |
| MoP Classic      | 50503                  |
| TBC Anniversary  | 20505                  |

## 📦 Installation

### Download

[![GitHub](https://img.shields.io/badge/GitHub-Releases-181717?style=for-the-badge&logo=github)](https://github.com/Xerrion/DragonLoot/releases/latest)

### Manual Install

1. Download the latest release from GitHub Releases
2. Extract the `DragonLoot` folder into your AddOns directory:

   ```text
   World of Warcraft/_retail_/Interface/AddOns/DragonLoot/
   ```

   For Classic variants, use `_classic_` instead of `_retail_`.

3. Restart WoW or type `/reload`

## ⌨️ Commands

All commands use the `/dl` prefix (or the full `/dragonloot`):

| Command           | Description                    |
|:------------------|:-------------------------------|
| `/dl`             | Open settings                  |
| `/dl test`        | Show test loot items           |
| `/dl testmode`    | Toggle continuous test mode    |
| `/dl testroll`    | Show test roll frame           |
| `/dl clear`       | Clear all test items           |
| `/dl history`     | Toggle loot history panel      |
| `/dl config`      | Open settings panel            |
| `/dl minimap`     | Toggle minimap icon            |

## ⚙️ Configuration

- **Loot Window**: Enable/disable, scale, lock position, dimensions
- **Roll Frame**: Enable/disable, scale, lock position, timer bar height
- **History Panel**: Enable/disable, max entries, auto-show, lock position
- **Roll Notifications**: Roll won, group wins, individual results, instance filtering, quality threshold
- **Appearance**: Font, font size, icon size
- **Animation**: Enable/disable, durations

Access settings with `/dl config` or click the minimap icon.

## 🔗 DragonToast Integration

When [DragonToast](https://github.com/Xerrion/DragonToast) is installed, DragonLoot automatically suppresses duplicate item toasts while the loot window is open, preventing double notifications. Roll wins and individual roll results are sent as toast notifications through DragonToast's feed.

Integration uses the generic DragonToast messaging API - fire-and-forget with no configuration needed. Neither addon requires the other; all features work independently when only one is installed.

## 🤝 Contributing

Contributions are welcome! Please open an issue or pull request on [GitHub](https://github.com/Xerrion/DragonLoot). Run `luacheck .` before submitting to ensure all linting passes.

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](https://github.com/Xerrion/DragonLoot/blob/main/LICENSE) file for details.

Made with ❤️ by [Xerrion](https://github.com/Xerrion)
