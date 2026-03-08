-------------------------------------------------------------------------------
-- AnimationTab.lua
-- Animation settings tab: enable/disable, durations, per-frame animation types
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local ipairs = ipairs
local LibStub = LibStub

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------

local L = ns.L

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- Notify appearance change helper
-------------------------------------------------------------------------------

local function NotifyAppearanceChange()
    local dl = ns.dlns
    if dl.LootFrame and dl.LootFrame.ApplySettings then dl.LootFrame.ApplySettings() end
    if dl.RollManager and dl.RollManager.ApplySettings then dl.RollManager.ApplySettings() end
    if dl.HistoryFrame and dl.HistoryFrame.ApplySettings then dl.HistoryFrame.ApplySettings() end
end

-------------------------------------------------------------------------------
-- Build entrance/exit animation name values from LibAnimate
-------------------------------------------------------------------------------

local function GetEntranceValues()
    local lib = LibStub("LibAnimate", true)
    if not lib then return {} end
    local names = lib:GetEntranceAnimations()
    local values = { { value = "none", text = L["None"] } }
    for _, name in ipairs(names) do
        values[#values + 1] = { value = name, text = name }
    end
    return values
end

local function GetExitValues()
    local lib = LibStub("LibAnimate", true)
    if not lib then return {} end
    local names = lib:GetExitAnimations()
    local values = { { value = "none", text = L["None"] } }
    for _, name in ipairs(names) do
        values[#values + 1] = { value = name, text = name }
    end
    return values
end

-------------------------------------------------------------------------------
-- Helper: create an animation dropdown for a given db key
-------------------------------------------------------------------------------

local function AddAnimDropdown(stack, parent, db, label, key, valuesFn)
    stack:AddChild(LDF.CreateDropdown(parent, {
        label = label,
        values = valuesFn,
        get = function() return db.profile.animation[key] end,
        set = function(value)
            db.profile.animation[key] = value
            NotifyAppearanceChange()
        end,
    }))
end

-------------------------------------------------------------------------------
-- Section: Animation (global toggle + durations)
-------------------------------------------------------------------------------

local function CreateAnimationSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Animation"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Enable Animations"],
        tooltip = L["Enable or disable all DragonLoot animations"],
        get = function() return db.profile.animation.enabled end,
        set = function(value)
            db.profile.animation.enabled = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Open Duration"],
        tooltip = L["Duration of open/show animations in seconds"],
        min = 0.1,
        max = 1,
        step = 0.05,
        format = "%.2f",
        get = function() return db.profile.animation.openDuration end,
        set = function(value)
            db.profile.animation.openDuration = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Close Duration"],
        tooltip = L["Duration of close/hide animations in seconds"],
        min = 0.1,
        max = 1,
        step = 0.05,
        format = "%.2f",
        get = function() return db.profile.animation.closeDuration end,
        set = function(value)
            db.profile.animation.closeDuration = value
            NotifyAppearanceChange()
        end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Section: Loot Window animation types
-------------------------------------------------------------------------------

local function CreateLootAnimSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Loot Window"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    AddAnimDropdown(stack, section.content, db, L["Open Animation"], "lootOpenAnim", GetEntranceValues)
    AddAnimDropdown(stack, section.content, db, L["Close Animation"], "lootCloseAnim", GetExitValues)

    return section
end

-------------------------------------------------------------------------------
-- Section: Roll Frame animation types
-------------------------------------------------------------------------------

local function CreateRollAnimSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Roll Frame"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    AddAnimDropdown(stack, section.content, db, L["Show Animation"], "rollShowAnim", GetEntranceValues)
    AddAnimDropdown(stack, section.content, db, L["Hide Animation"], "rollHideAnim", GetExitValues)

    return section
end

-------------------------------------------------------------------------------
-- Build the Animation tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local stack = LDF.CreateStackLayout(parent, "vertical")

    stack:AddChild(CreateAnimationSection(parent))
    stack:AddChild(CreateLootAnimSection(parent))
    stack:AddChild(CreateRollAnimSection(parent))
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "animation",
    label = L["Animation"],
    order = 7,
    createFunc = CreateContent,
}
