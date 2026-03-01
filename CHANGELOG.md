# Changelog

## [0.2.2](https://github.com/DragonAddons/DragonLoot/compare/0.2.1...0.2.2) (2026-02-27)


### 📚 Documentation

* update repo location ([#28](https://github.com/DragonAddons/DragonLoot/issues/28)) ([717216a](https://github.com/DragonAddons/DragonLoot/commit/717216a307af2fa8fd84a4f96a1f22a3128e4680))

## [0.2.1](https://github.com/DragonAddons/DragonLoot/compare/0.2.0...0.2.1) (2026-02-27)


### 📚 Documentation

* add correct logo ([#27](https://github.com/DragonAddons/DragonLoot/issues/27)) ([6691e16](https://github.com/DragonAddons/DragonLoot/commit/6691e16496f42b0b82ceeb5a42a383169756c7ba))
* add new better assets ([#25](https://github.com/DragonAddons/DragonLoot/issues/25)) ([563edab](https://github.com/DragonAddons/DragonLoot/commit/563edab863f30aeee9b4e91e7b65a0577d8b470e))

## [0.2.0](https://github.com/DragonAddons/DragonLoot/compare/0.1.0...0.2.0) (2026-02-27)


### 🚀 Features

* add individual roll notifications and instance filtering ([#13](https://github.com/DragonAddons/DragonLoot/issues/13)) ([0b665fa](https://github.com/DragonAddons/DragonLoot/commit/0b665fa437ccca567377f705a490d4303c2c69ab))
* configurable roll-won notifications with group member support ([#11](https://github.com/DragonAddons/DragonLoot/issues/11)) ([7e00d72](https://github.com/DragonAddons/DragonLoot/commit/7e00d725da20bd1e532492dd3929faec136013f2))
* core bootstrap and config ([#1](https://github.com/DragonAddons/DragonLoot/issues/1)) ([5754d53](https://github.com/DragonAddons/DragonLoot/commit/5754d53a6bea239b18f45590464f777f7a8c0805))
* expand appearance config with font outline, quality border, backdrop, and border customization ([#15](https://github.com/DragonAddons/DragonLoot/issues/15)) ([51dcf83](https://github.com/DragonAddons/DragonLoot/commit/51dcf83aa281927f90f642cc386d69d30204a139))
* loot history frame with encounter-based and roll-item tracking ([#9](https://github.com/DragonAddons/DragonLoot/issues/9)) ([c576968](https://github.com/DragonAddons/DragonLoot/commit/c57696807f9d8a9fb8a5116bea0dfa3137151cb8))
* loot roll replacement with timer bar and overflow queue ([#8](https://github.com/DragonAddons/DragonLoot/issues/8)) ([322e2da](https://github.com/DragonAddons/DragonLoot/commit/322e2dac6418016e6ecbd239ced9284f530e8e91))
* loot window replacement ([#6](https://github.com/DragonAddons/DragonLoot/issues/6)) ([087bc4b](https://github.com/DragonAddons/DragonLoot/commit/087bc4b893cbfabcd33efe2e8ca1f45b83d38501))
* migrate to generic DragonToast messaging API ([#12](https://github.com/DragonAddons/DragonLoot/issues/12)) ([7f7ea40](https://github.com/DragonAddons/DragonLoot/commit/7f7ea401bcd005bbab6ed1609e750cc9282f6855))
* Phase 11 - Direct loot history tracking via CHAT_MSG_LOOT ([#24](https://github.com/DragonAddons/DragonLoot/issues/24)) ([684b615](https://github.com/DragonAddons/DragonLoot/commit/684b615c05cb2f45258068dc48c8c03ec7c8890d))
* polish config wiring, edge cases, DragonToast detection, and AGENTS.md ([#10](https://github.com/DragonAddons/DragonLoot/issues/10)) ([4edc838](https://github.com/DragonAddons/DragonLoot/commit/4edc83821cf6ed520034c2d4941d06940631d954))


### 🐛 Bug Fixes

* add contents:write permission to release workflow ([#5](https://github.com/DragonAddons/DragonLoot/issues/5)) ([6a41b59](https://github.com/DragonAddons/DragonLoot/commit/6a41b5906b880e1faba48513870746460ecb2ffd))
* add permissions to caller workflow ([#3](https://github.com/DragonAddons/DragonLoot/issues/3)) ([746393a](https://github.com/DragonAddons/DragonLoot/commit/746393aed63938357dae1062e094bc6d423ae8e3))
* center close button and use TBC test items ([#21](https://github.com/DragonAddons/DragonLoot/issues/21)) ([8211ef6](https://github.com/DragonAddons/DragonLoot/commit/8211ef6e7f8fabb482cf3cc82dedc17ffdc33a2d))
* profile reset refresh, toast suppression, roll frame width ([#20](https://github.com/DragonAddons/DragonLoot/issues/20)) ([2e68b1d](https://github.com/DragonAddons/DragonLoot/commit/2e68b1d4c2df7e8156d5822816d45ce1228296f0))
* render hover highlight under icon using ARTWORK sublevel ([#23](https://github.com/DragonAddons/DragonLoot/issues/23)) ([c901f05](https://github.com/DragonAddons/DragonLoot/commit/c901f050839de85990f5d0e10b1edf1ebc962cc3))
* resolve runtime errors in Config and RollListener ([#17](https://github.com/DragonAddons/DragonLoot/issues/17)) ([7e0dc2c](https://github.com/DragonAddons/DragonLoot/commit/7e0dc2c7c898e21980567c4fef5400d6f3a843c4))
* restructure TOC to eliminate duplicate listener file loads ([#16](https://github.com/DragonAddons/DragonLoot/issues/16)) ([7b0c881](https://github.com/DragonAddons/DragonLoot/commit/7b0c88131c1c7ea1565581638d1715238d28cf5e))
* slot icon border draw layer and hover highlight ([#22](https://github.com/DragonAddons/DragonLoot/issues/22)) ([3238927](https://github.com/DragonAddons/DragonLoot/commit/323892757177ee887eb4d330b7b377dfb9915273))
* UI improvements and test roll support ([#19](https://github.com/DragonAddons/DragonLoot/issues/19)) ([d240516](https://github.com/DragonAddons/DragonLoot/commit/d240516327acdf2d3ce7dfba90fdaf2c738f4e2d))
* wrap LOOT_HISTORY_CLEAR_HISTORY in pcall for TBC Anniversary ([#18](https://github.com/DragonAddons/DragonLoot/issues/18)) ([e5f5215](https://github.com/DragonAddons/DragonLoot/commit/e5f5215f23e126e25d137071139060d9965d963a))


### 📚 Documentation

* add README with features, commands, and integration guide ([#14](https://github.com/DragonAddons/DragonLoot/issues/14)) ([7e415ab](https://github.com/DragonAddons/DragonLoot/commit/7e415aba7f789d5d0fe4284e1b55d984ac7f0fae))


### ⚙️ Miscellaneous Tasks

* add nul to gitignore (Windows reserved name artifact) ([#7](https://github.com/DragonAddons/DragonLoot/issues/7)) ([c05733c](https://github.com/DragonAddons/DragonLoot/commit/c05733c624a2b0ac9953bfd1324409e402b9575c))
* migrate to shared release workflows ([#2](https://github.com/DragonAddons/DragonLoot/issues/2)) ([0d830d9](https://github.com/DragonAddons/DragonLoot/commit/0d830d9926c48ca4ec2576a43bb7a6ee53a035d3))
* scaffold dragonloot addon ([d741991](https://github.com/DragonAddons/DragonLoot/commit/d741991dcd16f95340fa9cadebe7731a722176e4))

## Changelog
