std = "lua51"
max_line_length = 120
codes = true
exclude_files = {
    "DragonLoot/Libs/",
    ".release/",
    ".types.lua",
}

ignore = {
    "212/self",
    "211/ADDON_NAME",
    "211/_.*",  -- unused variables prefixed with underscore
    "212/_.*",  -- unused arguments prefixed with underscore
    "213/_.*",  -- unused loop variables prefixed with underscore
}

read_globals = {
    -- Lua
    "table", "string", "math", "pairs", "ipairs", "type", "tostring", "tonumber",
    "select", "unpack", "wipe", "strsplit", "strmatch", "strtrim", "format", "pcall",

    -- WoW API - General
    "CreateFrame", "GetTime", "UIParent", "GameTooltip", "_G",
    "PlaySound", "SOUNDKIT", "GetItemInfo", "C_Timer", "StaticPopup_Show",

    -- Libraries
    "LibStub",

    -- WoW Globals
    "STANDARD_TEXT_FONT",
}

-----------------------------------------------------------------------
-- DragonLoot (main addon)
-----------------------------------------------------------------------
files["DragonLoot/"] = {
    globals = {
        "DragonLootDB",
        "DragonLootNS",
        "SLASH_DRAGONLOOT1",
        "SLASH_DRAGONLOOT2",
        "SlashCmdList",
        "StaticPopupDialogs",
    },

    read_globals = {
        -- WoW API - General
        "UnitName", "UnitClass", "IsInInstance",
        "GetCursorPosition", "GetItemInfoInstant", "GetItemQualityColor",
        "C_Item", "C_Container", "C_AddOns", "IsAddOnLoaded", "LoadAddOn",
        "CreateColor", "PlaySoundFile",
        "ChatFrame_OpenChat", "IsShiftKeyDown",
        "InCombatLockdown", "hooksecurefunc",
        "InterfaceOptionsFrame_OpenToCategory", "Settings",
        "ShowUIPanel",

        -- WoW API - Loot
        "GetNumLootItems", "GetLootSlotInfo", "GetLootSlotLink", "GetLootSlotType",
        "LootSlot", "CloseLoot", "IsFishingLoot", "C_Loot",

        -- WoW API - Loot Roll
        "GetLootRollItemInfo", "GetLootRollItemLink", "RollOnLoot", "GetLootRollTimeLeft",
        "GetActiveLootRollIDs", "ConfirmLootRoll",
        "HandleModifiedItemClick",
        "C_Texture",

        -- WoW API - Loot History
        "C_LootHistory",

        -- WoW Frames - Loot
        "LootFrame",
        "GroupLootFrame1", "GroupLootFrame2", "GroupLootFrame3", "GroupLootFrame4",
        "GroupLootContainer",

        -- WoW Globals - Version detection
        "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE",
        "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", "WOW_PROJECT_MISTS_CLASSIC",

        -- WoW Globals
        "Enum", "RAID_CLASS_COLORS", "ITEM_QUALITY_COLORS",
        "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE",
        "LOOT_ITEM", "LOOT_ITEM_MULTIPLE",
        "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE",
        "LOOT_ITEM_PUSHED", "LOOT_ITEM_PUSHED_MULTIPLE",
        "GetPlayerInfoByGUID",
        "LOOT_MONEY", "YOU_LOOT_MONEY",
        "CURRENCY_GAINED", "CURRENCY_GAINED_MULTIPLE",
        "GOLD_AMOUNT", "SILVER_AMOUNT", "COPPER_AMOUNT",
        "GOLD_AMOUNT_TEXTURE", "SILVER_AMOUNT_TEXTURE", "COPPER_AMOUNT_TEXTURE",
        "GetCoinTextureString",
        "UNKNOWN",
        "LOOT_NO_DROP", "YES", "NO",

        -- Companion addons
        "DragonLoot_Options",
    },
}

-----------------------------------------------------------------------
-- DragonLoot_Options (companion addon)
-----------------------------------------------------------------------
files["DragonLoot_Options/"] = {
    globals = {
        "DragonLoot_Options",
        "StaticPopupDialogs",
    },

    read_globals = {
        -- WoW Globals
        "YES", "NO",

        -- DragonLoot bridge
        "DragonLootNS",

        -- DragonWidgets shared library
        "DragonWidgetsNS",
    },
}
