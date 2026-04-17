-------------------------------------------------------------------------------
-- AutoLootTab.lua
-- Smart auto-loot settings tab: enable, quality filter, whitelist, blacklist
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

local L = ns.L
-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local tostring = tostring
local tonumber = tonumber

-------------------------------------------------------------------------------
-- DragonWidgets references
-------------------------------------------------------------------------------

local W = ns.DW.Widgets
local LC = ns.DW.LayoutConstants

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local ITEM_LIST_HEIGHT = 220

-------------------------------------------------------------------------------
-- Section: Smart Auto-Loot header + toggle + quality dropdown
-------------------------------------------------------------------------------

local function CreateSettingsSection(parent, db, yOffset)
    local section = W.CreateSection(parent, L["Settings"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    -- stylua: ignore
    local desc = W.CreateDescription(
        content,
        L["Automatically loot items that meet your criteria."
            .. " Items on the whitelist are always picked up."
            .. " Items on the blacklist are never auto-looted."
            .. " Everything else is evaluated against the minimum quality threshold."]
    )
    innerY = LC.AnchorWidget(desc, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Forward-declare so the toggle set closure captures the variable
    local qualityDropdown

    local enableToggle = W.CreateToggle(content, {
        label = L["Enable Smart Auto-Loot"],
        tooltip = L["When enabled, qualifying items are automatically looted based on your filter rules"],
        get = function()
            return db.profile.autoLoot.enabled
        end,
        set = function(value)
            db.profile.autoLoot.enabled = value
            qualityDropdown:SetDisabled(not value)
        end,
    })
    innerY = LC.AnchorWidget(enableToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    qualityDropdown = W.CreateDropdown(content, {
        label = L["Minimum Quality"],
        values = ns.QualityValues,
        get = function()
            return tostring(db.profile.autoLoot.minQuality)
        end,
        set = function(value)
            db.profile.autoLoot.minQuality = tonumber(value) or 0
        end,
    })
    innerY = LC.AnchorWidget(qualityDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Apply initial disabled state
    qualityDropdown:SetDisabled(not db.profile.autoLoot.enabled)

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Whitelist item grid
-------------------------------------------------------------------------------

local function CreateWhitelistSection(parent, db, yOffset)
    local section = W.CreateSection(parent, L["Whitelist"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    -- stylua: ignore
    local desc = W.CreateDescription(
        content,
        L["Items on this list are always looted automatically, regardless of quality."
            .. " Drag an item from your bags onto an empty slot to add it."]
    )
    innerY = LC.AnchorWidget(desc, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local itemList = W.CreateItemList(content, {
        label = "",
        getItems = function()
            return db.profile.autoLoot.whitelist
        end,
        setItems = function(t)
            db.profile.autoLoot.whitelist = t
        end,
        emptyText = L["No items - drag items here to add"],
    })
    itemList:SetHeight(ITEM_LIST_HEIGHT)
    innerY = LC.AnchorWidget(itemList, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Blacklist item grid
-------------------------------------------------------------------------------

local function CreateBlacklistSection(parent, db, yOffset)
    local section = W.CreateSection(parent, L["Blacklist"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    -- stylua: ignore
    local desc = W.CreateDescription(
        content,
        L["Items on this list are never auto-looted, even if they meet the quality threshold."
            .. " They will remain in the loot window for manual pickup."]
    )
    innerY = LC.AnchorWidget(desc, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local itemList = W.CreateItemList(content, {
        label = "",
        getItems = function()
            return db.profile.autoLoot.blacklist
        end,
        setItems = function(t)
            db.profile.autoLoot.blacklist = t
        end,
        emptyText = L["No items - drag items here to add"],
    })
    itemList:SetHeight(ITEM_LIST_HEIGHT)
    innerY = LC.AnchorWidget(itemList, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Auto-Loot tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local db = dlns.Addon.db
    local yOffset = LC.PADDING_TOP

    yOffset = CreateSettingsSection(parent, db, yOffset)
    yOffset = CreateWhitelistSection(parent, db, yOffset)
    yOffset = CreateBlacklistSection(parent, db, yOffset)

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "autoLoot",
    label = L["Auto-Loot"],
    order = 6,
    createFunc = CreateContent,
}
