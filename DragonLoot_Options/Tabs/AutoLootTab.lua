-------------------------------------------------------------------------------
-- AutoLootTab.lua
-- Smart auto-loot settings tab: enable, quality filter, whitelist, blacklist
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

local tostring = tostring
local tonumber = tonumber
local L = ns.L
local dlns

local ITEM_LIST_HEIGHT = 220

-------------------------------------------------------------------------------
-- Section: Smart Auto-Loot settings
-------------------------------------------------------------------------------

local function CreateSettingsSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Smart Auto-Loot"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateDescription(section.content,
        L["Automatically loot items that meet your criteria. Items on the whitelist are always"
        .. " picked up. Items on the blacklist are never auto-looted. Everything else is evaluated"
        .. " against the minimum quality threshold."]))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Enable Smart Auto-Loot"],
        tooltip = L["When enabled, qualifying items are automatically looted based on your filter rules"],
        get = function() return db.profile.autoLoot.enabled end,
        set = function(value) db.profile.autoLoot.enabled = value end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Minimum Quality"],
        values = ns.QualityValues,
        get = function() return tostring(db.profile.autoLoot.minQuality) end,
        set = function(value) db.profile.autoLoot.minQuality = tonumber(value) end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Section: Whitelist
-------------------------------------------------------------------------------

local function CreateWhitelistSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Whitelist"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateDescription(section.content,
        L["Items on this list are always looted automatically, regardless of quality."
        .. " Drag an item from your bags onto an empty slot to add it."]))

    local itemList = LDF.CreateItemList(section.content, {
        getItems = function() return db.profile.autoLoot.whitelist end,
        setItems = function(t) db.profile.autoLoot.whitelist = t end,
        emptyText = L["No items - drag items here to add"],
    })
    itemList:SetHeight(ITEM_LIST_HEIGHT)
    stack:AddChild(itemList)

    return section
end

-------------------------------------------------------------------------------
-- Section: Blacklist
-------------------------------------------------------------------------------

local function CreateBlacklistSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Blacklist"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateDescription(section.content,
        L["Items on this list are never auto-looted, even if they meet the quality threshold."
        .. " They will remain in the loot window for manual pickup."]))

    local itemList = LDF.CreateItemList(section.content, {
        getItems = function() return db.profile.autoLoot.blacklist end,
        setItems = function(t) db.profile.autoLoot.blacklist = t end,
        emptyText = L["No items - drag items here to add"],
    })
    itemList:SetHeight(ITEM_LIST_HEIGHT)
    stack:AddChild(itemList)

    return section
end

-------------------------------------------------------------------------------
-- Build the Auto-Loot tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local stack = LDF.CreateStackLayout(parent, "vertical")
    stack:AddChild(CreateSettingsSection(parent))
    stack:AddChild(CreateWhitelistSection(parent))
    stack:AddChild(CreateBlacklistSection(parent))
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "autoLoot",
    label = L["Auto-Loot"],
    order = 5,
    createFunc = CreateContent,
}
