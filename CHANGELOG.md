# Changelog

## [0.13.0](https://github.com/Xerrion/DragonLoot/compare/0.12.0...0.13.0) (2026-04-22)


### 🚀 Features

* detect ElvUI loot conflict and offer to disable ([#147](https://github.com/Xerrion/DragonLoot/issues/147)) ([#148](https://github.com/Xerrion/DragonLoot/issues/148)) ([da18e5b](https://github.com/Xerrion/DragonLoot/commit/da18e5b293c7523a7a297651bcb8bcb56325f1b9))


### ⚙️ Miscellaneous Tasks

* update TOC Interface versions ([#151](https://github.com/Xerrion/DragonLoot/issues/151)) ([2893e7b](https://github.com/Xerrion/DragonLoot/commit/2893e7b467adc17903da9783a1bf119f57e7aeaf))

## [0.12.0](https://github.com/Xerrion/DragonLoot/compare/0.11.2...0.12.0) (2026-04-18)


### 🚀 Features

* redesign options UI for natural UX flow ([#124](https://github.com/Xerrion/DragonLoot/issues/124)) ([#144](https://github.com/Xerrion/DragonLoot/issues/144)) ([13cb564](https://github.com/Xerrion/DragonLoot/commit/13cb564f24188f9617c84803d35fee782f7af7bc))


### 🐛 Bug Fixes

* prevent Blizzard roll frame showing alongside custom roll frame ([#145](https://github.com/Xerrion/DragonLoot/issues/145)) ([8dd8b5d](https://github.com/Xerrion/DragonLoot/commit/8dd8b5deb98fe2e42c0e70defb0949a1cdcd7355))
* remove invalid UpdateTooltip script handler on Button frames ([#143](https://github.com/Xerrion/DragonLoot/issues/143)) ([c7c54be](https://github.com/Xerrion/DragonLoot/commit/c7c54befe8dec8119082222630663bd6002d7905))
* **security:** autofix Using unsafe GitHub Actions trigger may allow privilege escalation via CI/CD ([#137](https://github.com/Xerrion/DragonLoot/issues/137)) ([110d15b](https://github.com/Xerrion/DragonLoot/commit/110d15bb27ad3f37ec632fdcd766022a574ae143))


### ⚙️ Miscellaneous Tasks

* auto-assign all new issues to Xerrion ([#141](https://github.com/Xerrion/DragonLoot/issues/141)) ([d614aa2](https://github.com/Xerrion/DragonLoot/commit/d614aa28f500f0e351d93af21bf13cbb8c32bfef))

## [0.11.2](https://github.com/Xerrion/DragonLoot/compare/0.11.1...0.11.2) (2026-04-15)


### 🐛 Bug Fixes

* correct DragonWidgets external path in .pkgmeta ([#136](https://github.com/Xerrion/DragonLoot/issues/136)) ([#138](https://github.com/Xerrion/DragonLoot/issues/138)) ([94ce245](https://github.com/Xerrion/DragonLoot/commit/94ce245e6a1fd04b62f524b02c7d35c71fb445b6))

## [0.11.1](https://github.com/Xerrion/DragonLoot/compare/0.11.0...0.11.1) (2026-04-15)


### 🐛 Bug Fixes

* address CodeRabbit code quality findings ([#133](https://github.com/Xerrion/DragonLoot/issues/133)) ([846bc48](https://github.com/Xerrion/DragonLoot/commit/846bc4830e1d0f07a6538b938dc176178c746969))
* refresh item comparison tooltip on modifier key change ([#135](https://github.com/Xerrion/DragonLoot/issues/135)) ([f780b5c](https://github.com/Xerrion/DragonLoot/commit/f780b5c344fbd990af836dd72a0d0cc47ecf5017))


### ⚙️ Miscellaneous Tasks

* add stylua formatting and justfile ([#128](https://github.com/Xerrion/DragonLoot/issues/128)) ([548dfa3](https://github.com/Xerrion/DragonLoot/commit/548dfa36a7f7afd6979fdd7f0617b6b4ae0aba8c))

## [0.11.0](https://github.com/Xerrion/DragonLoot/compare/0.10.0...0.11.0) (2026-04-06)


### 🚀 Features

* add busted test infrastructure with Lifecycle and Config tests ([#125](https://github.com/Xerrion/DragonLoot/issues/125)) ([#127](https://github.com/Xerrion/DragonLoot/issues/127)) ([804136a](https://github.com/Xerrion/DragonLoot/commit/804136a955f78a9e3367a8be5dcfa760e9cde745))
* add Center Horizontally and Center Vertically buttons to roll frame options ([#93](https://github.com/Xerrion/DragonLoot/issues/93)) ([#119](https://github.com/Xerrion/DragonLoot/issues/119)) ([9412532](https://github.com/Xerrion/DragonLoot/commit/9412532371209fc2b0c172dfbd0f6e721170752e))
* add icon outside/left position option to roll frame ([#91](https://github.com/Xerrion/DragonLoot/issues/91)) ([#120](https://github.com/Xerrion/DragonLoot/issues/120)) ([17c9456](https://github.com/Xerrion/DragonLoot/commit/17c9456b7621fb67767f4a6fd5bf1f02cce711db))
* lower minimum roll frame height slider to 24px ([#87](https://github.com/Xerrion/DragonLoot/issues/87)) ([#116](https://github.com/Xerrion/DragonLoot/issues/116)) ([d7d887d](https://github.com/Xerrion/DragonLoot/commit/d7d887dddfd1b55a0a99b541c0cc1ccdf4928102))
* show item level overlay on roll frame icon ([#92](https://github.com/Xerrion/DragonLoot/issues/92)) ([#117](https://github.com/Xerrion/DragonLoot/issues/117)) ([f4a37b5](https://github.com/Xerrion/DragonLoot/commit/f4a37b5b0ad93814d6e4d0a61c914f770e2fdf7c))


### 🐛 Bug Fixes

* correct DragonWidgets TOC paths and guard CONFIRM_DISENCHANT_ROLL on Classic ([#118](https://github.com/Xerrion/DragonLoot/issues/118)) ([b0a88c6](https://github.com/Xerrion/DragonLoot/commit/b0a88c6e53dc50fe5b28017dad8f6def12198154))
* highlight roll button icon on hover instead of grey box ([#86](https://github.com/Xerrion/DragonLoot/issues/86)) ([#115](https://github.com/Xerrion/DragonLoot/issues/115)) ([c270fbe](https://github.com/Xerrion/DragonLoot/commit/c270fbeb812cf9395eacfa7e9ec970860709335f))
* transmog button now occupies greed slot in roll button chain ([#121](https://github.com/Xerrion/DragonLoot/issues/121)) ([#123](https://github.com/Xerrion/DragonLoot/issues/123)) ([17173ad](https://github.com/Xerrion/DragonLoot/commit/17173ad0f5ed2f93b7029e3d2c0e1107392f2e05))


### 🚜 Refactor

* eliminate duplicated anchor formulas and magic offsets in RollFrame ([#111](https://github.com/Xerrion/DragonLoot/issues/111)) ([#113](https://github.com/Xerrion/DragonLoot/issues/113)) ([c046306](https://github.com/Xerrion/DragonLoot/commit/c046306dbac581aa5cb0825668a2cb240f49b296))
* promote magic layout literals to named constants in LootFrame ([#110](https://github.com/Xerrion/DragonLoot/issues/110)) ([#112](https://github.com/Xerrion/DragonLoot/issues/112)) ([1b91f95](https://github.com/Xerrion/DragonLoot/commit/1b91f956770b638eaa9b7ce79ee3cc2cc3bb1578))

## [0.10.0](https://github.com/Xerrion/DragonLoot/compare/0.9.0...0.10.0) (2026-04-05)


### 🚀 Features

* embed DragonWidgets as shared widget library in DragonLoot_Options ([#108](https://github.com/Xerrion/DragonLoot/issues/108)) ([5e47a53](https://github.com/Xerrion/DragonLoot/commit/5e47a53311080fe70963013da0b0a4e0fd40b053))
* wire L[...] locale lookups into all DragonLoot_Options tabs ([#109](https://github.com/Xerrion/DragonLoot/issues/109)) ([1308b23](https://github.com/Xerrion/DragonLoot/commit/1308b235cb1c9ea25a06a990ff96eafe5e7ef636))


### 🐛 Bug Fixes

* close Blizzard_LootUI LoD timing gap in loot frame suppression ([#107](https://github.com/Xerrion/DragonLoot/issues/107)) ([dde938b](https://github.com/Xerrion/DragonLoot/commit/dde938b806523463766e544f7265858c1ade4d55))


### ⚙️ Miscellaneous Tasks

* add mise.toml to pin Lua 5.1 for local dev tooling ([aff184d](https://github.com/Xerrion/DragonLoot/commit/aff184d0dca43a5fc849ea213d56e22e5a49c9e6))
* migrate to structured label taxonomy ([#105](https://github.com/Xerrion/DragonLoot/issues/105)) ([1921a73](https://github.com/Xerrion/DragonLoot/commit/1921a7308c81ed6c7336787191d425007b65e17c))
* use [@project-version](https://github.com/project-version)@ token in DragonLoot.toc ([5dc2d87](https://github.com/Xerrion/DragonLoot/commit/5dc2d876edb17f2ec5d55312374b8dce81930ba1))

## [0.9.0](https://github.com/Xerrion/DragonLoot/compare/0.8.1...0.9.0) (2026-03-28)


### 🚀 Features

* add hide roll frame after voting option ([#88](https://github.com/Xerrion/DragonLoot/issues/88)) ([#100](https://github.com/Xerrion/DragonLoot/issues/100)) ([44ca004](https://github.com/Xerrion/DragonLoot/commit/44ca004960d2af397911fbadb9d4e5f0bdd7e208))
* overhaul options GUI with visual hierarchy, color palette, and tab split ([#98](https://github.com/Xerrion/DragonLoot/issues/98)) ([#102](https://github.com/Xerrion/DragonLoot/issues/102)) ([7cb7ee4](https://github.com/Xerrion/DragonLoot/commit/7cb7ee4f8130dac8781375c3b872fe6318506b27))


### 🐛 Bug Fixes

* roll frame drag, confirm roll crash, and duplicate popup ([#96](https://github.com/Xerrion/DragonLoot/issues/96)) ([#97](https://github.com/Xerrion/DragonLoot/issues/97)) ([bff162f](https://github.com/Xerrion/DragonLoot/commit/bff162f747caabc55140369998272991978276ee))
* use correct atlas for transmog roll button ([#94](https://github.com/Xerrion/DragonLoot/issues/94)) ([#101](https://github.com/Xerrion/DragonLoot/issues/101)) ([a893d21](https://github.com/Xerrion/DragonLoot/commit/a893d2102a1452a6307288b71ee8fbcfad66d855))

## [0.8.1](https://github.com/Xerrion/DragonLoot/compare/0.8.0...0.8.1) (2026-03-24)


### 🐛 Bug Fixes

* resolve compact anchor crash, missing font settings, and history overlap ([#63](https://github.com/Xerrion/DragonLoot/issues/63)) ([#85](https://github.com/Xerrion/DragonLoot/issues/85)) ([265318c](https://github.com/Xerrion/DragonLoot/commit/265318c3f234c615a8d742e2cd90842cc96fa631))

## [0.8.0](https://github.com/Xerrion/DragonLoot/compare/0.7.0...0.8.0) (2026-03-24)


### 🚀 Features

* add more visual options ([#63](https://github.com/Xerrion/DragonLoot/issues/63)) ([#83](https://github.com/Xerrion/DragonLoot/issues/83)) ([8d4904f](https://github.com/Xerrion/DragonLoot/commit/8d4904f8b77cb97e0fe530f8176a3da787af5967))

## [0.7.0](https://github.com/Xerrion/DragonLoot/compare/0.6.7...0.7.0) (2026-03-15)


### 🚀 Features

* add individual roll notifications and instance filtering ([#13](https://github.com/Xerrion/DragonLoot/issues/13)) ([0b665fa](https://github.com/Xerrion/DragonLoot/commit/0b665fa437ccca567377f705a490d4303c2c69ab))
* align repo setup with DragonToast ([#34](https://github.com/Xerrion/DragonLoot/issues/34), [#35](https://github.com/Xerrion/DragonLoot/issues/35), [#36](https://github.com/Xerrion/DragonLoot/issues/36), [#37](https://github.com/Xerrion/DragonLoot/issues/37)) ([#38](https://github.com/Xerrion/DragonLoot/issues/38)) ([8729c30](https://github.com/Xerrion/DragonLoot/commit/8729c302e3002003eda6f150e39bfade01d88e1d))
* configurable roll-won notifications with group member support ([#11](https://github.com/Xerrion/DragonLoot/issues/11)) ([7e00d72](https://github.com/Xerrion/DragonLoot/commit/7e00d725da20bd1e532492dd3929faec136013f2))
* core bootstrap and config ([#1](https://github.com/Xerrion/DragonLoot/issues/1)) ([5754d53](https://github.com/Xerrion/DragonLoot/commit/5754d53a6bea239b18f45590464f777f7a8c0805))
* custom options panel replacing AceConfig ([#42](https://github.com/Xerrion/DragonLoot/issues/42)) ([384f7d0](https://github.com/Xerrion/DragonLoot/commit/384f7d02a461ac7d49f3d5b3aca0f00ddab8f241))
* expand appearance config with font outline, quality border, backdrop, and border customization ([#15](https://github.com/Xerrion/DragonLoot/issues/15)) ([51dcf83](https://github.com/Xerrion/DragonLoot/commit/51dcf83aa281927f90f642cc386d69d30204a139))
* loot history frame with encounter-based and roll-item tracking ([#9](https://github.com/Xerrion/DragonLoot/issues/9)) ([c576968](https://github.com/Xerrion/DragonLoot/commit/c57696807f9d8a9fb8a5116bea0dfa3137151cb8))
* loot roll replacement with timer bar and overflow queue ([#8](https://github.com/Xerrion/DragonLoot/issues/8)) ([322e2da](https://github.com/Xerrion/DragonLoot/commit/322e2dac6418016e6ecbd239ced9284f530e8e91))
* loot window replacement ([#6](https://github.com/Xerrion/DragonLoot/issues/6)) ([087bc4b](https://github.com/Xerrion/DragonLoot/commit/087bc4b893cbfabcd33efe2e8ca1f45b83d38501))
* migrate to generic DragonToast messaging API ([#12](https://github.com/Xerrion/DragonLoot/issues/12)) ([7f7ea40](https://github.com/Xerrion/DragonLoot/commit/7f7ea401bcd005bbab6ed1609e750cc9282f6855))
* open loot frame at mouse cursor ([#50](https://github.com/Xerrion/DragonLoot/issues/50)) ([#56](https://github.com/Xerrion/DragonLoot/issues/56)) ([60846ef](https://github.com/Xerrion/DragonLoot/commit/60846ef8878132c66b3f7bbecc43a2c924cbff59))
* Phase 11 - Direct loot history tracking via CHAT_MSG_LOOT ([#24](https://github.com/Xerrion/DragonLoot/issues/24)) ([684b615](https://github.com/Xerrion/DragonLoot/commit/684b615c05cb2f45258068dc48c8c03ec7c8890d))
* polish config wiring, edge cases, DragonToast detection, and AGENTS.md ([#10](https://github.com/Xerrion/DragonLoot/issues/10)) ([4edc838](https://github.com/Xerrion/DragonLoot/commit/4edc83821cf6ed520034c2d4941d06940631d954))
* restructure roll frame to 3-row layout and expose layout config ([#39](https://github.com/Xerrion/DragonLoot/issues/39)) ([0eadc71](https://github.com/Xerrion/DragonLoot/commit/0eadc7198b116ca4913fa4a6d26d698a7eeddf5a))


### 🐛 Bug Fixes

* add contents:write permission to release workflow ([#5](https://github.com/Xerrion/DragonLoot/issues/5)) ([6a41b59](https://github.com/Xerrion/DragonLoot/commit/6a41b5906b880e1faba48513870746460ecb2ffd))
* add issue types to issue templates ([#55](https://github.com/Xerrion/DragonLoot/issues/55)) ([8b1816c](https://github.com/Xerrion/DragonLoot/commit/8b1816ce816b34d612b458ca58feeb176d9712f0))
* add packager directives to TOC and fix author field ([#47](https://github.com/Xerrion/DragonLoot/issues/47)) ([3e689e1](https://github.com/Xerrion/DragonLoot/commit/3e689e1a0d88e263257a53d5ed7fa9c6fd5ee355))
* add permissions to caller workflow ([#3](https://github.com/Xerrion/DragonLoot/issues/3)) ([746393a](https://github.com/Xerrion/DragonLoot/commit/746393aed63938357dae1062e094bc6d423ae8e3))
* badge formatting in README.md ([#43](https://github.com/Xerrion/DragonLoot/issues/43)) ([5fbded5](https://github.com/Xerrion/DragonLoot/commit/5fbded5c1fd2f083b3ce14073d1e04c80926ef97))
* center close button and use TBC test items ([#21](https://github.com/Xerrion/DragonLoot/issues/21)) ([8211ef6](https://github.com/Xerrion/DragonLoot/commit/8211ef6e7f8fabb482cf3cc82dedc17ffdc33a2d))
* clarify slash command help and toggle behavior ([#52](https://github.com/Xerrion/DragonLoot/issues/52)) ([f944cd3](https://github.com/Xerrion/DragonLoot/commit/f944cd31605fee6aa924ebaa7859fdd443a7a8d1))
* correct CHAT_MSG_LOOT guid parameter offset ([#51](https://github.com/Xerrion/DragonLoot/issues/51)) ([#54](https://github.com/Xerrion/DragonLoot/issues/54)) ([92a2725](https://github.com/Xerrion/DragonLoot/commit/92a2725915d2b5a168e837db0c709d4826c3eb9e))
* profile reset refresh, toast suppression, roll frame width ([#20](https://github.com/Xerrion/DragonLoot/issues/20)) ([2e68b1d](https://github.com/Xerrion/DragonLoot/commit/2e68b1d4c2df7e8156d5822816d45ce1228296f0))
* remember to include missing interface versions ([#72](https://github.com/Xerrion/DragonLoot/issues/72)) ([249748a](https://github.com/Xerrion/DragonLoot/commit/249748a920af953cd3686bc333cc2ebf2b7e887b))
* render hover highlight under icon using ARTWORK sublevel ([#23](https://github.com/Xerrion/DragonLoot/issues/23)) ([c901f05](https://github.com/Xerrion/DragonLoot/commit/c901f050839de85990f5d0e10b1edf1ebc962cc3))
* resolve lingering roll frames caused by lootHandle/rollID mismatch ([#80](https://github.com/Xerrion/DragonLoot/issues/80)) ([9d4d38f](https://github.com/Xerrion/DragonLoot/commit/9d4d38fc85fb0cecf17e24a73664b4dd51f58977))
* resolve loot/roll frame animation jumping ([#60](https://github.com/Xerrion/DragonLoot/issues/60)) ([9ec9eb1](https://github.com/Xerrion/DragonLoot/commit/9ec9eb123b814b5757dad6084422be223b90cb0d))
* resolve runtime errors in Config and RollListener ([#17](https://github.com/Xerrion/DragonLoot/issues/17)) ([7e0dc2c](https://github.com/Xerrion/DragonLoot/commit/7e0dc2c7c898e21980567c4fef5400d6f3a843c4))
* restore roll anchor visibility and fix local listener loading ([#49](https://github.com/Xerrion/DragonLoot/issues/49)) ([6c56764](https://github.com/Xerrion/DragonLoot/commit/6c567648b4159c434fc6c485d02a4e4e2661e3c0))
* restructure TOC to eliminate duplicate listener file loads ([#16](https://github.com/Xerrion/DragonLoot/issues/16)) ([7b0c881](https://github.com/Xerrion/DragonLoot/commit/7b0c88131c1c7ea1565581638d1715238d28cf5e))
* robust Blizzard loot frame suppression on Retail ([#65](https://github.com/Xerrion/DragonLoot/issues/65)) ([debf24d](https://github.com/Xerrion/DragonLoot/commit/debf24d38b06a0e228add7da35b5589305a7997a))
* slot icon border draw layer and hover highlight ([#22](https://github.com/Xerrion/DragonLoot/issues/22)) ([3238927](https://github.com/Xerrion/DragonLoot/commit/323892757177ee887eb4d330b7b377dfb9915273))
* suppress Blizzard roll frames via UIParent and convert roll timer from ms to seconds ([#45](https://github.com/Xerrion/DragonLoot/issues/45)) ([93203ca](https://github.com/Xerrion/DragonLoot/commit/93203cadc32898d6e9bf1c5ff0b3266375558745))
* UI improvements and test roll support ([#19](https://github.com/Xerrion/DragonLoot/issues/19)) ([d240516](https://github.com/Xerrion/DragonLoot/commit/d240516327acdf2d3ce7dfba90fdaf2c738f4e2d))
* use correct verion tags ([#70](https://github.com/Xerrion/DragonLoot/issues/70)) ([b7a503d](https://github.com/Xerrion/DragonLoot/commit/b7a503d49723cbf0a700e3b91bf9d271edb5630a))
* wrap LOOT_HISTORY_CLEAR_HISTORY in pcall for TBC Anniversary ([#18](https://github.com/Xerrion/DragonLoot/issues/18)) ([e5f5215](https://github.com/Xerrion/DragonLoot/commit/e5f5215f23e126e25d137071139060d9965d963a))


### 🚜 Refactor

* codebase-wide consistency and maintainability improvements ([#73](https://github.com/Xerrion/DragonLoot/issues/73)) ([24619ab](https://github.com/Xerrion/DragonLoot/commit/24619abe3a3bb15c182f483d5f759ddd793b2723))


### ⚙️ Miscellaneous Tasks

* add nul to gitignore (Windows reserved name artifact) ([#7](https://github.com/Xerrion/DragonLoot/issues/7)) ([c05733c](https://github.com/Xerrion/DragonLoot/commit/c05733c624a2b0ac9953bfd1324409e402b9575c))
* fix wrong toc version ([864ec29](https://github.com/Xerrion/DragonLoot/commit/864ec29f1d447eae883951a613f32d5516c0c6a6))
* formatting issues in README.md ([#62](https://github.com/Xerrion/DragonLoot/issues/62)) ([21474e8](https://github.com/Xerrion/DragonLoot/commit/21474e8f92398172ac033e9f921dcb7fe632d22a))
* **main:** release 0.2.0 ([#4](https://github.com/Xerrion/DragonLoot/issues/4)) ([398becd](https://github.com/Xerrion/DragonLoot/commit/398becdfab0bdd7b13a665ce16a029c2c970db19))
* **main:** release 0.2.1 ([#26](https://github.com/Xerrion/DragonLoot/issues/26)) ([fd832c0](https://github.com/Xerrion/DragonLoot/commit/fd832c0f7acb2809b8e926e4551ff592088c2dbc))
* **main:** release 0.2.2 ([#29](https://github.com/Xerrion/DragonLoot/issues/29)) ([323e23e](https://github.com/Xerrion/DragonLoot/commit/323e23eee2c81b25757001a9765ab6fd0fdd465d))
* **master:** release 0.3.0 ([#40](https://github.com/Xerrion/DragonLoot/issues/40)) ([1163d57](https://github.com/Xerrion/DragonLoot/commit/1163d57f000bcda0c467af636259edb64358c629))
* **master:** release 0.4.0 ([#41](https://github.com/Xerrion/DragonLoot/issues/41)) ([c9dd1c6](https://github.com/Xerrion/DragonLoot/commit/c9dd1c61feca976abd09903455e94c534d926fce))
* **master:** release 0.5.0 ([#44](https://github.com/Xerrion/DragonLoot/issues/44)) ([12865e2](https://github.com/Xerrion/DragonLoot/commit/12865e293d872ddea00484a4fbbb97eec5993187))
* **master:** release 0.5.1 ([#46](https://github.com/Xerrion/DragonLoot/issues/46)) ([baf7927](https://github.com/Xerrion/DragonLoot/commit/baf7927f4f48bf6bf6aa8f8d30e77b83bd68c0d6))
* **master:** release 0.5.2 ([#48](https://github.com/Xerrion/DragonLoot/issues/48)) ([2ea08f3](https://github.com/Xerrion/DragonLoot/commit/2ea08f3e083283ebdcc3903fb1190936568cce1d))
* **master:** release 0.6.0 ([#53](https://github.com/Xerrion/DragonLoot/issues/53)) ([a0f3db6](https://github.com/Xerrion/DragonLoot/commit/a0f3db6d3eac9706bc730d41a04e592641b35614))
* **master:** release 0.6.1 ([#66](https://github.com/Xerrion/DragonLoot/issues/66)) ([626d45b](https://github.com/Xerrion/DragonLoot/commit/626d45b7f7d5a90164164eded8eabf92b90c3679))
* **master:** release 0.6.2 ([#71](https://github.com/Xerrion/DragonLoot/issues/71)) ([6d0b6d3](https://github.com/Xerrion/DragonLoot/commit/6d0b6d324338228ddd90b88f705c252cad94c4e5))
* **master:** release 0.6.3 ([#74](https://github.com/Xerrion/DragonLoot/issues/74)) ([61cbe79](https://github.com/Xerrion/DragonLoot/commit/61cbe795456925608de42e8907f0c33937ce1b9a))
* **master:** release 0.6.4 ([#75](https://github.com/Xerrion/DragonLoot/issues/75)) ([d52f628](https://github.com/Xerrion/DragonLoot/commit/d52f6286fa8da3f524f2406537ca95b2f8f430e7))
* **master:** release 0.6.5 ([#78](https://github.com/Xerrion/DragonLoot/issues/78)) ([a48fdfc](https://github.com/Xerrion/DragonLoot/commit/a48fdfc2ceb834e615bdd45f2a9a0256487c398f))
* **master:** release 0.6.6 ([#79](https://github.com/Xerrion/DragonLoot/issues/79)) ([621ca24](https://github.com/Xerrion/DragonLoot/commit/621ca2463396e9b85ac2afbf8161e4904bc0c14a))
* **master:** release 0.6.7 ([#81](https://github.com/Xerrion/DragonLoot/issues/81)) ([e664f93](https://github.com/Xerrion/DragonLoot/commit/e664f93383fb62ff621a5fc413d2b4ddd93e8943))
* migrate to shared release workflows ([#2](https://github.com/Xerrion/DragonLoot/issues/2)) ([0d830d9](https://github.com/Xerrion/DragonLoot/commit/0d830d9926c48ca4ec2576a43bb7a6ee53a035d3))
* removed submodule ([#61](https://github.com/Xerrion/DragonLoot/issues/61)) ([f390018](https://github.com/Xerrion/DragonLoot/commit/f390018f5461eec544ece08b2952745a686ffafa))
* scaffold dragonloot addon ([d741991](https://github.com/Xerrion/DragonLoot/commit/d741991dcd16f95340fa9cadebe7731a722176e4))
* toc bump ([91f3c40](https://github.com/Xerrion/DragonLoot/commit/91f3c40409d6867ac663b44e2caf17b49908a514))
* update repo refs ([0bd502a](https://github.com/Xerrion/DragonLoot/commit/0bd502a831b166b236d6a7fa158407c3d2c0c6ae))
* update TOC Interface versions ([#77](https://github.com/Xerrion/DragonLoot/issues/77)) ([b87f044](https://github.com/Xerrion/DragonLoot/commit/b87f0447a1f780cea361a324649856004c677a10))

## [0.6.7](https://github.com/Xerrion/DragonLoot/compare/0.6.6...0.6.7) (2026-03-15)


### 🐛 Bug Fixes

* resolve lingering roll frames caused by lootHandle/rollID mismatch ([#80](https://github.com/Xerrion/DragonLoot/issues/80)) ([9d4d38f](https://github.com/Xerrion/DragonLoot/commit/9d4d38fc85fb0cecf17e24a73664b4dd51f58977))

## [0.6.6](https://github.com/Xerrion/DragonLoot/compare/0.6.5...0.6.6) (2026-03-15)


### ⚙️ Miscellaneous Tasks

* update repo refs ([0bd502a](https://github.com/Xerrion/DragonLoot/commit/0bd502a831b166b236d6a7fa158407c3d2c0c6ae))

## [0.6.5](https://github.com/Xerrion/DragonLoot/compare/0.6.4...0.6.5) (2026-03-15)


### ⚙️ Miscellaneous Tasks

* update TOC Interface versions ([#77](https://github.com/Xerrion/DragonLoot/issues/77)) ([b87f044](https://github.com/Xerrion/DragonLoot/commit/b87f0447a1f780cea361a324649856004c677a10))

## [0.6.4](https://github.com/Xerrion/DragonLoot/compare/0.6.3...0.6.4) (2026-03-13)


### ⚙️ Miscellaneous Tasks

* fix wrong toc version ([864ec29](https://github.com/Xerrion/DragonLoot/commit/864ec29f1d447eae883951a613f32d5516c0c6a6))

## [0.6.3](https://github.com/Xerrion/DragonLoot/compare/0.6.2...0.6.3) (2026-03-13)


### ⚙️ Miscellaneous Tasks

* toc bump ([91f3c40](https://github.com/Xerrion/DragonLoot/commit/91f3c40409d6867ac663b44e2caf17b49908a514))

## [0.6.2](https://github.com/Xerrion/DragonLoot/compare/0.6.1...0.6.2) (2026-03-13)


### 🐛 Bug Fixes

* remember to include missing interface versions ([#72](https://github.com/Xerrion/DragonLoot/issues/72)) ([249748a](https://github.com/Xerrion/DragonLoot/commit/249748a920af953cd3686bc333cc2ebf2b7e887b))
* use correct verion tags ([#70](https://github.com/Xerrion/DragonLoot/issues/70)) ([b7a503d](https://github.com/Xerrion/DragonLoot/commit/b7a503d49723cbf0a700e3b91bf9d271edb5630a))


### 🚜 Refactor

* codebase-wide consistency and maintainability improvements ([#73](https://github.com/Xerrion/DragonLoot/issues/73)) ([24619ab](https://github.com/Xerrion/DragonLoot/commit/24619abe3a3bb15c182f483d5f759ddd793b2723))

## [0.6.1](https://github.com/Xerrion/DragonLoot/compare/0.6.0...0.6.1) (2026-03-11)


### 🐛 Bug Fixes

* robust Blizzard loot frame suppression on Retail ([#65](https://github.com/Xerrion/DragonLoot/issues/65)) ([debf24d](https://github.com/Xerrion/DragonLoot/commit/debf24d38b06a0e228add7da35b5589305a7997a))

## [0.6.0](https://github.com/Xerrion/DragonLoot/compare/0.5.2...0.6.0) (2026-03-07)


### 🚀 Features

* open loot frame at mouse cursor ([#50](https://github.com/Xerrion/DragonLoot/issues/50)) ([#56](https://github.com/Xerrion/DragonLoot/issues/56)) ([60846ef](https://github.com/Xerrion/DragonLoot/commit/60846ef8878132c66b3f7bbecc43a2c924cbff59))


### 🐛 Bug Fixes

* add issue types to issue templates ([#55](https://github.com/Xerrion/DragonLoot/issues/55)) ([8b1816c](https://github.com/Xerrion/DragonLoot/commit/8b1816ce816b34d612b458ca58feeb176d9712f0))
* clarify slash command help and toggle behavior ([#52](https://github.com/Xerrion/DragonLoot/issues/52)) ([f944cd3](https://github.com/Xerrion/DragonLoot/commit/f944cd31605fee6aa924ebaa7859fdd443a7a8d1))
* correct CHAT_MSG_LOOT guid parameter offset ([#51](https://github.com/Xerrion/DragonLoot/issues/51)) ([#54](https://github.com/Xerrion/DragonLoot/issues/54)) ([92a2725](https://github.com/Xerrion/DragonLoot/commit/92a2725915d2b5a168e837db0c709d4826c3eb9e))
* resolve loot/roll frame animation jumping ([#60](https://github.com/Xerrion/DragonLoot/issues/60)) ([9ec9eb1](https://github.com/Xerrion/DragonLoot/commit/9ec9eb123b814b5757dad6084422be223b90cb0d))

## [0.5.2](https://github.com/Xerrion/DragonLoot/compare/0.5.1...0.5.2) (2026-03-06)


### 🐛 Bug Fixes

* add packager directives to TOC and fix author field ([#47](https://github.com/Xerrion/DragonLoot/issues/47)) ([3e689e1](https://github.com/Xerrion/DragonLoot/commit/3e689e1a0d88e263257a53d5ed7fa9c6fd5ee355))
* restore roll anchor visibility and fix local listener loading ([#49](https://github.com/Xerrion/DragonLoot/issues/49)) ([6c56764](https://github.com/Xerrion/DragonLoot/commit/6c567648b4159c434fc6c485d02a4e4e2661e3c0))

## [0.5.1](https://github.com/Xerrion/DragonLoot/compare/0.5.0...0.5.1) (2026-03-06)


### 🐛 Bug Fixes

* suppress Blizzard roll frames via UIParent and convert roll timer from ms to seconds ([#45](https://github.com/Xerrion/DragonLoot/issues/45)) ([93203ca](https://github.com/Xerrion/DragonLoot/commit/93203cadc32898d6e9bf1c5ff0b3266375558745))

## [0.5.0](https://github.com/Xerrion/DragonLoot/compare/0.4.0...0.5.0) (2026-03-05)


### 🚀 Features

* custom options panel replacing AceConfig ([#42](https://github.com/Xerrion/DragonLoot/issues/42)) ([384f7d0](https://github.com/Xerrion/DragonLoot/commit/384f7d02a461ac7d49f3d5b3aca0f00ddab8f241))


### 🐛 Bug Fixes

* badge formatting in README.md ([#43](https://github.com/Xerrion/DragonLoot/issues/43)) ([5fbded5](https://github.com/Xerrion/DragonLoot/commit/5fbded5c1fd2f083b3ce14073d1e04c80926ef97))

## [0.4.0](https://github.com/Xerrion/DragonLoot/compare/0.3.0...0.4.0) (2026-03-01)


### 🚀 Features

* restructure roll frame to 3-row layout and expose layout config ([#39](https://github.com/Xerrion/DragonLoot/issues/39)) ([0eadc71](https://github.com/Xerrion/DragonLoot/commit/0eadc7198b116ca4913fa4a6d26d698a7eeddf5a))

## [0.3.0](https://github.com/Xerrion/DragonLoot/compare/0.2.2...0.3.0) (2026-03-01)


### 🚀 Features

* align repo setup with DragonToast ([#34](https://github.com/Xerrion/DragonLoot/issues/34), [#35](https://github.com/Xerrion/DragonLoot/issues/35), [#36](https://github.com/Xerrion/DragonLoot/issues/36), [#37](https://github.com/Xerrion/DragonLoot/issues/37)) ([#38](https://github.com/Xerrion/DragonLoot/issues/38)) ([8729c30](https://github.com/Xerrion/DragonLoot/commit/8729c302e3002003eda6f150e39bfade01d88e1d))

## [0.2.2](https://github.com/Xerrion/DragonLoot/compare/0.2.1...0.2.2) (2026-02-27)


### 📚 Documentation

* update repo location ([#28](https://github.com/Xerrion/DragonLoot/issues/28)) ([717216a](https://github.com/Xerrion/DragonLoot/commit/717216a307af2fa8fd84a4f96a1f22a3128e4680))

## [0.2.1](https://github.com/Xerrion/DragonLoot/compare/0.2.0...0.2.1) (2026-02-27)


### 📚 Documentation

* add correct logo ([#27](https://github.com/Xerrion/DragonLoot/issues/27)) ([6691e16](https://github.com/Xerrion/DragonLoot/commit/6691e16496f42b0b82ceeb5a42a383169756c7ba))
* add new better assets ([#25](https://github.com/Xerrion/DragonLoot/issues/25)) ([563edab](https://github.com/Xerrion/DragonLoot/commit/563edab863f30aeee9b4e91e7b65a0577d8b470e))

## [0.2.0](https://github.com/Xerrion/DragonLoot/compare/0.1.0...0.2.0) (2026-02-27)


### 🚀 Features

* add individual roll notifications and instance filtering ([#13](https://github.com/Xerrion/DragonLoot/issues/13)) ([0b665fa](https://github.com/Xerrion/DragonLoot/commit/0b665fa437ccca567377f705a490d4303c2c69ab))
* configurable roll-won notifications with group member support ([#11](https://github.com/Xerrion/DragonLoot/issues/11)) ([7e00d72](https://github.com/Xerrion/DragonLoot/commit/7e00d725da20bd1e532492dd3929faec136013f2))
* core bootstrap and config ([#1](https://github.com/Xerrion/DragonLoot/issues/1)) ([5754d53](https://github.com/Xerrion/DragonLoot/commit/5754d53a6bea239b18f45590464f777f7a8c0805))
* expand appearance config with font outline, quality border, backdrop, and border customization ([#15](https://github.com/Xerrion/DragonLoot/issues/15)) ([51dcf83](https://github.com/Xerrion/DragonLoot/commit/51dcf83aa281927f90f642cc386d69d30204a139))
* loot history frame with encounter-based and roll-item tracking ([#9](https://github.com/Xerrion/DragonLoot/issues/9)) ([c576968](https://github.com/Xerrion/DragonLoot/commit/c57696807f9d8a9fb8a5116bea0dfa3137151cb8))
* loot roll replacement with timer bar and overflow queue ([#8](https://github.com/Xerrion/DragonLoot/issues/8)) ([322e2da](https://github.com/Xerrion/DragonLoot/commit/322e2dac6418016e6ecbd239ced9284f530e8e91))
* loot window replacement ([#6](https://github.com/Xerrion/DragonLoot/issues/6)) ([087bc4b](https://github.com/Xerrion/DragonLoot/commit/087bc4b893cbfabcd33efe2e8ca1f45b83d38501))
* migrate to generic DragonToast messaging API ([#12](https://github.com/Xerrion/DragonLoot/issues/12)) ([7f7ea40](https://github.com/Xerrion/DragonLoot/commit/7f7ea401bcd005bbab6ed1609e750cc9282f6855))
* Phase 11 - Direct loot history tracking via CHAT_MSG_LOOT ([#24](https://github.com/Xerrion/DragonLoot/issues/24)) ([684b615](https://github.com/Xerrion/DragonLoot/commit/684b615c05cb2f45258068dc48c8c03ec7c8890d))
* polish config wiring, edge cases, DragonToast detection, and AGENTS.md ([#10](https://github.com/Xerrion/DragonLoot/issues/10)) ([4edc838](https://github.com/Xerrion/DragonLoot/commit/4edc83821cf6ed520034c2d4941d06940631d954))


### 🐛 Bug Fixes

* add contents:write permission to release workflow ([#5](https://github.com/Xerrion/DragonLoot/issues/5)) ([6a41b59](https://github.com/Xerrion/DragonLoot/commit/6a41b5906b880e1faba48513870746460ecb2ffd))
* add permissions to caller workflow ([#3](https://github.com/Xerrion/DragonLoot/issues/3)) ([746393a](https://github.com/Xerrion/DragonLoot/commit/746393aed63938357dae1062e094bc6d423ae8e3))
* center close button and use TBC test items ([#21](https://github.com/Xerrion/DragonLoot/issues/21)) ([8211ef6](https://github.com/Xerrion/DragonLoot/commit/8211ef6e7f8fabb482cf3cc82dedc17ffdc33a2d))
* profile reset refresh, toast suppression, roll frame width ([#20](https://github.com/Xerrion/DragonLoot/issues/20)) ([2e68b1d](https://github.com/Xerrion/DragonLoot/commit/2e68b1d4c2df7e8156d5822816d45ce1228296f0))
* render hover highlight under icon using ARTWORK sublevel ([#23](https://github.com/Xerrion/DragonLoot/issues/23)) ([c901f05](https://github.com/Xerrion/DragonLoot/commit/c901f050839de85990f5d0e10b1edf1ebc962cc3))
* resolve runtime errors in Config and RollListener ([#17](https://github.com/Xerrion/DragonLoot/issues/17)) ([7e0dc2c](https://github.com/Xerrion/DragonLoot/commit/7e0dc2c7c898e21980567c4fef5400d6f3a843c4))
* restructure TOC to eliminate duplicate listener file loads ([#16](https://github.com/Xerrion/DragonLoot/issues/16)) ([7b0c881](https://github.com/Xerrion/DragonLoot/commit/7b0c88131c1c7ea1565581638d1715238d28cf5e))
* slot icon border draw layer and hover highlight ([#22](https://github.com/Xerrion/DragonLoot/issues/22)) ([3238927](https://github.com/Xerrion/DragonLoot/commit/323892757177ee887eb4d330b7b377dfb9915273))
* UI improvements and test roll support ([#19](https://github.com/Xerrion/DragonLoot/issues/19)) ([d240516](https://github.com/Xerrion/DragonLoot/commit/d240516327acdf2d3ce7dfba90fdaf2c738f4e2d))
* wrap LOOT_HISTORY_CLEAR_HISTORY in pcall for TBC Anniversary ([#18](https://github.com/Xerrion/DragonLoot/issues/18)) ([e5f5215](https://github.com/Xerrion/DragonLoot/commit/e5f5215f23e126e25d137071139060d9965d963a))


### 📚 Documentation

* add README with features, commands, and integration guide ([#14](https://github.com/Xerrion/DragonLoot/issues/14)) ([7e415ab](https://github.com/Xerrion/DragonLoot/commit/7e415aba7f789d5d0fe4284e1b55d984ac7f0fae))


### ⚙️ Miscellaneous Tasks

* add nul to gitignore (Windows reserved name artifact) ([#7](https://github.com/Xerrion/DragonLoot/issues/7)) ([c05733c](https://github.com/Xerrion/DragonLoot/commit/c05733c624a2b0ac9953bfd1324409e402b9575c))
* migrate to shared release workflows ([#2](https://github.com/Xerrion/DragonLoot/issues/2)) ([0d830d9](https://github.com/Xerrion/DragonLoot/commit/0d830d9926c48ca4ec2576a43bb7a6ee53a035d3))
* scaffold dragonloot addon ([d741991](https://github.com/Xerrion/DragonLoot/commit/d741991dcd16f95340fa9cadebe7731a722176e4))

## Changelog
