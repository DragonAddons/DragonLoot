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
}

globals = {
    "DragonLootDB",
    "SLASH_DRAGONLOOT1",
    "SLASH_DRAGONLOOT2",
    "SlashCmdList",
}

read_globals = {
    -- Lua
    "table", "string", "math", "pairs", "ipairs", "type", "tostring", "tonumber",
    "select", "unpack", "wipe", "strsplit", "strmatch", "strtrim", "format",

    -- WoW API - General
    "CreateFrame", "GetTime", "IsInInstance", "UnitName", "UnitClass",
    "GetItemInfo", "GetItemQualityColor", "C_Timer", "C_Item", "C_Container",
    "GameTooltip", "UIParent", "PlaySound", "PlaySoundFile",
    "ChatFrame_OpenChat", "IsShiftKeyDown",
    "InCombatLockdown", "hooksecurefunc",
    "InterfaceOptionsFrame_OpenToCategory", "Settings",
    "_G",

    -- WoW API - Loot
    "GetNumLootItems", "GetLootSlotInfo", "GetLootSlotLink", "GetLootSlotType",
    "LootSlot", "CloseLoot", "IsFishingLoot",

    -- WoW API - Loot Roll
    "GetLootRollItemInfo", "GetLootRollItemLink", "RollOnLoot", "GetLootRollTimeLeft",

    -- WoW API - Loot History
    "C_LootHistory",

    -- WoW Frames - Loot
    "LootFrame",
    "GroupLootFrame1", "GroupLootFrame2", "GroupLootFrame3", "GroupLootFrame4",
    "GroupLootContainer",

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

    -- Ace3
    "LibStub",
}
