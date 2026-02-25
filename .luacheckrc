std = "lua51"
max_line_length = 120
codes = true
exclude_files = {
    "Libs/",
}

ignore = {
    "212/self",
    "211/ADDON_NAME",
    "211/_.*",  -- unused variables prefixed with underscore
    "213/_.*",  -- unused loop variables prefixed with underscore
}

globals = {
    "DragonLootDB",
    "SLASH_DRAGONLOOT1",
    "SLASH_DRAGONLOOT2",
    "SlashCmdList",
    "StaticPopupDialogs",
}

read_globals = {
    -- Lua
    "table", "string", "math", "pairs", "ipairs", "type", "tostring", "tonumber",
    "select", "unpack", "wipe", "strsplit", "strmatch", "strtrim", "format",

    -- WoW API - General
    "CreateFrame", "GetTime", "IsInInstance", "UnitName", "UnitClass",
    "GetItemInfo", "GetItemInfoInstant", "GetItemQualityColor",
    "C_Timer", "C_Item", "C_Container",
    "GameTooltip", "UIParent", "PlaySound", "PlaySoundFile",
    "ChatFrame_OpenChat", "IsShiftKeyDown",
    "InCombatLockdown", "hooksecurefunc",
    "InterfaceOptionsFrame_OpenToCategory", "Settings",
    "_G",

    -- WoW API - Loot
    "GetNumLootItems", "GetLootSlotInfo", "GetLootSlotLink", "GetLootSlotType",
    "LootSlot", "CloseLoot", "IsFishingLoot", "C_Loot",

    -- WoW API - Loot Roll
    "GetLootRollItemInfo", "GetLootRollItemLink", "RollOnLoot", "GetLootRollTimeLeft",
    "GetActiveLootRollIDs", "ConfirmLootRoll",
    "StaticPopup_Show", "HandleModifiedItemClick",

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
    "Enum", "RAID_CLASS_COLORS", "ITEM_QUALITY_COLORS", "STANDARD_TEXT_FONT",
    "SOUNDKIT",
    "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE",
    "LOOT_ITEM", "LOOT_ITEM_MULTIPLE",
    "LOOT_MONEY", "YOU_LOOT_MONEY",
    "CURRENCY_GAINED", "CURRENCY_GAINED_MULTIPLE",
    "GOLD_AMOUNT", "SILVER_AMOUNT", "COPPER_AMOUNT",
    "GOLD_AMOUNT_TEXTURE", "SILVER_AMOUNT_TEXTURE", "COPPER_AMOUNT_TEXTURE",
    "GetCoinTextureString",
    "UNKNOWN",
    "LOOT_NO_DROP", "YES", "NO",

    -- Ace3
    "LibStub",
}
