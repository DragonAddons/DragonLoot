-------------------------------------------------------------------------------
-- AppearanceTab.lua
-- Appearance settings tab: font, icons, background, border
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local table_sort = table.sort
local pairs = pairs
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
-- Shared media
-------------------------------------------------------------------------------

local LSM = LibStub("LibSharedMedia-3.0")

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
-- LSM list builders
-------------------------------------------------------------------------------

local function BuildLSMValues(mediaType)
    local hash = LSM:HashTable(mediaType)
    local values = {}
    for key in pairs(hash) do
        values[#values + 1] = { value = key, text = key }
    end
    table_sort(values, function(a, b) return a.text < b.text end)
    return values
end

local function GetFontValues()
    return BuildLSMValues("font")
end

local function GetBackgroundValues()
    return BuildLSMValues("background")
end

local function GetBorderValues()
    return BuildLSMValues("border")
end

-------------------------------------------------------------------------------
-- Font outline dropdown values
-------------------------------------------------------------------------------

local FONT_OUTLINE_VALUES = {
    { value = "", text = L["None"] },
    { value = "OUTLINE", text = L["Outline"] },
    { value = "THICKOUTLINE", text = L["Thick Outline"] },
    { value = "MONOCHROME", text = L["Monochrome"] },
}

-------------------------------------------------------------------------------
-- Slot background dropdown values
-------------------------------------------------------------------------------

local SLOT_BG_VALUES = {
    { value = "gradient", text = L["Gradient"] },
    { value = "flat", text = L["Flat"] },
    { value = "stripe", text = L["Stripe"] },
    { value = "none", text = L["None"] },
}

-------------------------------------------------------------------------------
-- Section: Font
-------------------------------------------------------------------------------

local function CreateFontSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Font"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Font Family"],
        values = GetFontValues,
        sort = true,
        mediaType = "font",
        get = function() return db.profile.appearance.font end,
        set = function(value)
            db.profile.appearance.font = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Font Size"],
        tooltip = L["Base font size for all DragonLoot frames"],
        min = 8,
        max = 20,
        step = 1,
        format = "%d",
        get = function() return db.profile.appearance.fontSize end,
        set = function(value)
            db.profile.appearance.fontSize = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Font Outline"],
        values = FONT_OUTLINE_VALUES,
        get = function() return db.profile.appearance.fontOutline end,
        set = function(value)
            db.profile.appearance.fontOutline = value
            NotifyAppearanceChange()
        end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Section: Icon Sizes
-------------------------------------------------------------------------------

local function CreateIconSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Icon Sizes"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Loot Icon Size"],
        tooltip = L["Icon size in the loot window"],
        min = 16,
        max = 64,
        step = 2,
        format = "%d",
        get = function() return db.profile.appearance.lootIconSize end,
        set = function(value)
            db.profile.appearance.lootIconSize = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Roll Icon Size"],
        tooltip = L["Icon size in the roll frame"],
        min = 16,
        max = 64,
        step = 2,
        format = "%d",
        get = function() return db.profile.appearance.rollIconSize end,
        set = function(value)
            db.profile.appearance.rollIconSize = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["History Icon Size"],
        tooltip = L["Icon size in the history frame"],
        min = 16,
        max = 48,
        step = 2,
        format = "%d",
        get = function() return db.profile.appearance.historyIconSize end,
        set = function(value)
            db.profile.appearance.historyIconSize = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Quality Border"],
        tooltip = L["Show quality-colored borders on item icons"],
        get = function() return db.profile.appearance.qualityBorder end,
        set = function(value)
            db.profile.appearance.qualityBorder = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Slot Background"],
        values = SLOT_BG_VALUES,
        get = function() return db.profile.appearance.slotBackground end,
        set = function(value)
            db.profile.appearance.slotBackground = value
            NotifyAppearanceChange()
        end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Section: Background
-------------------------------------------------------------------------------

local function CreateBackgroundSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Background"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateColorPicker(section.content, {
        label = L["Background Color"],
        hasAlpha = false,
        get = function()
            local c = db.profile.appearance.backgroundColor
            return c.r, c.g, c.b
        end,
        set = function(r, g, b)
            db.profile.appearance.backgroundColor.r = r
            db.profile.appearance.backgroundColor.g = g
            db.profile.appearance.backgroundColor.b = b
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Background Opacity"],
        tooltip = L["Opacity of the frame background"],
        min = 0,
        max = 1,
        step = 0.05,
        isPercent = true,
        get = function() return db.profile.appearance.backgroundAlpha end,
        set = function(value)
            db.profile.appearance.backgroundAlpha = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Background Texture"],
        values = GetBackgroundValues,
        sort = true,
        mediaType = "background",
        get = function() return db.profile.appearance.backgroundTexture end,
        set = function(value)
            db.profile.appearance.backgroundTexture = value
            NotifyAppearanceChange()
        end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Section: Border
-------------------------------------------------------------------------------

local function CreateBorderSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Border"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateColorPicker(section.content, {
        label = L["Border Color"],
        hasAlpha = false,
        get = function()
            local c = db.profile.appearance.borderColor
            return c.r, c.g, c.b
        end,
        set = function(r, g, b)
            db.profile.appearance.borderColor.r = r
            db.profile.appearance.borderColor.g = g
            db.profile.appearance.borderColor.b = b
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Border Size"],
        tooltip = L["Thickness of the frame border"],
        min = 0,
        max = 4,
        step = 1,
        format = "%d",
        get = function() return db.profile.appearance.borderSize end,
        set = function(value)
            db.profile.appearance.borderSize = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Border Texture"],
        values = GetBorderValues,
        sort = true,
        mediaType = "border",
        get = function() return db.profile.appearance.borderTexture end,
        set = function(value)
            db.profile.appearance.borderTexture = value
            NotifyAppearanceChange()
        end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Build the Appearance tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local stack = LDF.CreateStackLayout(parent, "vertical")

    stack:AddChild(CreateFontSection(parent))
    stack:AddChild(CreateIconSection(parent))
    stack:AddChild(CreateBackgroundSection(parent))
    stack:AddChild(CreateBorderSection(parent))
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "appearance",
    label = L["Appearance"],
    order = 6,
    createFunc = CreateContent,
}
