-------------------------------------------------------------------------------
-- LootWindowTab.lua
-- Loot window settings tab: enable, lock, scale, dimensions, spacing
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------

local L = ns.L

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- Helper: call LootFrame.ApplySettings if available
-------------------------------------------------------------------------------

local function ApplyLootSettings()
    if dlns.LootFrame and dlns.LootFrame.ApplySettings then
        dlns.LootFrame.ApplySettings()
    end
end

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateLootWindowSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Loot Window"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Enable Custom Loot Window"],
        tooltip = L["Replace the default loot window with DragonLoot's custom frame"],
        get = function() return db.profile.lootWindow.enabled end,
        set = function(value)
            db.profile.lootWindow.enabled = value
            ApplyLootSettings()
        end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Lock Position"],
        tooltip = L["Prevent the loot window from being moved"],
        get = function() return db.profile.lootWindow.lock end,
        set = function(value)
            db.profile.lootWindow.lock = value
        end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Position at Cursor"],
        tooltip = L["Open the loot window at the mouse cursor instead of the saved position"],
        get = function() return db.profile.lootWindow.positionAtCursor end,
        set = function(value)
            db.profile.lootWindow.positionAtCursor = value
        end,
    }))

    return section
end

local function CreateLayoutSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Layout"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Scale"],
        min = 0.5, max = 2, step = 0.05,
        get = function() return db.profile.lootWindow.scale end,
        set = function(value)
            db.profile.lootWindow.scale = value
            ApplyLootSettings()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Width"],
        min = 150, max = 400, step = 10,
        format = "%d",
        get = function() return db.profile.lootWindow.width end,
        set = function(value)
            db.profile.lootWindow.width = value
            ApplyLootSettings()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Height"],
        min = 150, max = 600, step = 10,
        format = "%d",
        get = function() return db.profile.lootWindow.height end,
        set = function(value)
            db.profile.lootWindow.height = value
            ApplyLootSettings()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Slot Spacing"],
        min = 0, max = 12, step = 1,
        format = "%d",
        get = function() return db.profile.lootWindow.slotSpacing end,
        set = function(value)
            db.profile.lootWindow.slotSpacing = value
            ApplyLootSettings()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Content Padding"],
        min = 0, max = 12, step = 1,
        format = "%d",
        get = function() return db.profile.lootWindow.contentPadding end,
        set = function(value)
            db.profile.lootWindow.contentPadding = value
            ApplyLootSettings()
        end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Build the Loot Window tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local stack = LDF.CreateStackLayout(parent, "vertical")
    stack:AddChild(CreateLootWindowSection(parent))
    stack:AddChild(CreateLayoutSection(parent))
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "lootWindow",
    label = L["Loot Window"],
    order = 2,
    createFunc = CreateContent,
}
