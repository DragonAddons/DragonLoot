-------------------------------------------------------------------------------
-- AutoLootTab.lua
-- Smart auto-loot settings tab: enable, quality filter, whitelist, blacklist
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local tostring = tostring
local tonumber = tonumber

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local PADDING_SIDE = 10
local PADDING_TOP = -10
local SPACING_AFTER_HEADER = 8
local SPACING_BETWEEN_WIDGETS = 6
local SPACING_BETWEEN_SECTIONS = 16
local PADDING_BOTTOM = 20
local ITEM_LIST_HEIGHT = 220

local QUALITY_VALUES = {
    { value = "0", text = "|cff9d9d9dPoor|r" },
    { value = "1", text = "|cffffffffCommon|r" },
    { value = "2", text = "|cff1eff00Uncommon|r" },
    { value = "3", text = "|cff0070ddRare|r" },
    { value = "4", text = "|cffa335eeEpic|r" },
    { value = "5", text = "|cffff8000Legendary|r" },
}

-------------------------------------------------------------------------------
-- Anchor a widget to the parent at the current yOffset
-------------------------------------------------------------------------------

local function AnchorWidget(widget, parent, yOffset, xLeft, xRight)
    xLeft = xLeft or PADDING_SIDE
    xRight = xRight or -PADDING_SIDE
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", xLeft, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", xRight, yOffset)
    return yOffset - widget:GetHeight()
end

-------------------------------------------------------------------------------
-- Section: Smart Auto-Loot header + toggle + quality dropdown
-------------------------------------------------------------------------------

local function CreateSettingsSection(parent, W, db, yOffset)
    local header = W.CreateHeader(parent, "Smart Auto-Loot")
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    local desc = W.CreateDescription(parent,
        "Automatically loot items that meet your criteria. Items on the whitelist are always picked up."
        .. " Items on the blacklist are never auto-looted. Everything else is evaluated against the"
        .. " minimum quality threshold.")
    yOffset = AnchorWidget(desc, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local enableToggle = W.CreateToggle(parent, {
        label = "Enable Smart Auto-Loot",
        tooltip = "When enabled, qualifying items are automatically looted based on your filter rules",
        get = function() return db.profile.autoLoot.enabled end,
        set = function(value) db.profile.autoLoot.enabled = value end,
    })
    yOffset = AnchorWidget(enableToggle, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local qualityDropdown = W.CreateDropdown(parent, {
        label = "Minimum Quality",
        values = QUALITY_VALUES,
        get = function() return tostring(db.profile.autoLoot.minQuality) end,
        set = function(value) db.profile.autoLoot.minQuality = tonumber(value) end,
    })
    yOffset = AnchorWidget(qualityDropdown, parent, yOffset) - SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Whitelist item grid
-------------------------------------------------------------------------------

local function CreateWhitelistSection(parent, W, db, yOffset)
    local header = W.CreateHeader(parent, "Whitelist")
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    local desc = W.CreateDescription(parent,
        "Items on this list are always looted automatically, regardless of quality."
        .. " Drag an item from your bags onto an empty slot to add it.")
    yOffset = AnchorWidget(desc, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local itemList = W.CreateItemList(parent, {
        label = "",
        getItems = function() return db.profile.autoLoot.whitelist end,
        setItems = function(t) db.profile.autoLoot.whitelist = t end,
        emptyText = "No items - drag items here to add",
    })
    itemList:SetHeight(ITEM_LIST_HEIGHT)
    yOffset = AnchorWidget(itemList, parent, yOffset) - SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Blacklist item grid
-------------------------------------------------------------------------------

local function CreateBlacklistSection(parent, W, db, yOffset)
    local header = W.CreateHeader(parent, "Blacklist")
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    local desc = W.CreateDescription(parent,
        "Items on this list are never auto-looted, even if they meet the quality threshold."
        .. " They will remain in the loot window for manual pickup.")
    yOffset = AnchorWidget(desc, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local itemList = W.CreateItemList(parent, {
        label = "",
        getItems = function() return db.profile.autoLoot.blacklist end,
        setItems = function(t) db.profile.autoLoot.blacklist = t end,
        emptyText = "No items - drag items here to add",
    })
    itemList:SetHeight(ITEM_LIST_HEIGHT)
    yOffset = AnchorWidget(itemList, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Auto-Loot tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local W = ns.Widgets
    local db = dlns.Addon.db
    local yOffset = PADDING_TOP

    yOffset = CreateSettingsSection(parent, W, db, yOffset)
    yOffset = CreateWhitelistSection(parent, W, db, yOffset)
    yOffset = CreateBlacklistSection(parent, W, db, yOffset)

    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "autoLoot",
    label = "Auto-Loot",
    order = 5,
    createFunc = CreateContent,
}
