std = "lua51"
max_line_length = 120
codes = true

ignore = {
    "212/self",
    "211/ADDON_NAME",
    "211/_.*",
    "212/_.*",
    "213/_.*",
}

globals = {
    "DragonLoot_Options",
    "StaticPopupDialogs",
    "ColorPickerFrame",
}

read_globals = {
    -- Lua
    "table", "string", "math", "pairs", "ipairs", "type", "tostring", "tonumber",
    "select", "unpack", "wipe", "strsplit", "strmatch", "strtrim", "format",
    "pcall",

    -- WoW API - General
    "CreateFrame", "GetTime", "UIParent", "GameTooltip",
    "PlaySound", "SOUNDKIT", "ShowUIPanel",
    "GetCursorInfo", "ClearCursor", "GetItemInfo", "C_Timer",
    "StaticPopup_Show",
    "_G",

    -- Libraries
    "LibStub",

    -- WoW Globals
    "STANDARD_TEXT_FONT", "UISpecialFrames",
    "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge",
    "GameFontHighlight", "GameFontHighlightSmall",

    -- DragonLoot bridge
    "DragonLootNS",
}
