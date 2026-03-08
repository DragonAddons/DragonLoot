-------------------------------------------------------------------------------
-- HistoryTab.lua
-- History settings tab: enable, auto-show, direct loot tracking, layout
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

local tostring = tostring
local tonumber = tonumber
local L = ns.L
local dlns

-------------------------------------------------------------------------------
-- Helper: call HistoryFrame.ApplySettings if available
-------------------------------------------------------------------------------

local function ApplyHistorySettings()
    if dlns.HistoryFrame and dlns.HistoryFrame.ApplySettings then
        dlns.HistoryFrame.ApplySettings()
    end
end

-------------------------------------------------------------------------------
-- Section: History toggles and dropdown
-------------------------------------------------------------------------------

local function CreateHistorySection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["History"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Enable History"],
        get = function() return db.profile.history.enabled end,
        set = function(value)
            db.profile.history.enabled = value
            ApplyHistorySettings()
        end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Auto Show on Loot"],
        get = function() return db.profile.history.autoShow end,
        set = function(value) db.profile.history.autoShow = value end,
    }))

    -- Forward-declare for cross-widget disable
    local qualityDropdown

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Track Direct Loot"],
        tooltip = L["Track items you pick up directly (not from a loot window)"],
        get = function() return db.profile.history.trackDirectLoot end,
        set = function(value)
            db.profile.history.trackDirectLoot = value
            if qualityDropdown then qualityDropdown:SetDisabled(not value) end
        end,
    }))

    qualityDropdown = LDF.CreateDropdown(section.content, {
        label = L["Minimum Quality"],
        values = ns.QualityValues,
        get = function() return tostring(db.profile.history.minQuality) end,
        set = function(value) db.profile.history.minQuality = tonumber(value) end,
        disabled = not db.profile.history.trackDirectLoot,
    })
    stack:AddChild(qualityDropdown)

    return section
end

-------------------------------------------------------------------------------
-- Section: Layout sliders
-------------------------------------------------------------------------------

local function CreateLayoutSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Layout"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Max Entries"],
        min = 10, max = 500, step = 10,
        format = "%d",
        get = function() return db.profile.history.maxEntries end,
        set = function(value) db.profile.history.maxEntries = value end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Entry Spacing"],
        min = 0, max = 12, step = 1,
        format = "%d",
        get = function() return db.profile.history.entrySpacing end,
        set = function(value)
            db.profile.history.entrySpacing = value
            ApplyHistorySettings()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Content Padding"],
        min = 0, max = 12, step = 1,
        format = "%d",
        get = function() return db.profile.history.contentPadding end,
        set = function(value)
            db.profile.history.contentPadding = value
            ApplyHistorySettings()
        end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Build the History tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local stack = LDF.CreateStackLayout(parent, "vertical")
    stack:AddChild(CreateHistorySection(parent))
    stack:AddChild(CreateLayoutSection(parent))
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "history",
    label = L["History"],
    order = 4,
    createFunc = CreateContent,
}
