-------------------------------------------------------------------------------
-- AppearanceTab.lua
-- Appearance settings tab: font, icons, background, border
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local table_sort = table.sort
local pairs = pairs
local LibStub = LibStub

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
    { value = "", text = "None" },
    { value = "OUTLINE", text = "Outline" },
    { value = "THICKOUTLINE", text = "Thick Outline" },
    { value = "MONOCHROME", text = "Monochrome" },
}

-------------------------------------------------------------------------------
-- Slot background dropdown values
-------------------------------------------------------------------------------

local SLOT_BG_VALUES = {
    { value = "gradient", text = "Gradient" },
    { value = "flat", text = "Flat" },
    { value = "stripe", text = "Stripe" },
    { value = "none", text = "None" },
}

-------------------------------------------------------------------------------
-- Anchor a widget to the parent at the current yOffset
-------------------------------------------------------------------------------

local function AnchorWidget(widget, parent, yOffset)
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    return yOffset - widget:GetHeight()
end

-------------------------------------------------------------------------------
-- Section: Font
-------------------------------------------------------------------------------

local function CreateFontSection(parent, W, db, yOffset)
    local header = W.CreateHeader(parent, "Font")
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    local fontDropdown = W.CreateDropdown(parent, {
        label = "Font Family",
        values = GetFontValues,
        sort = true,
        mediaType = "font",
        get = function() return db.profile.appearance.font end,
        set = function(value)
            db.profile.appearance.font = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(fontDropdown, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local fontSizeSlider = W.CreateSlider(parent, {
        label = "Font Size",
        tooltip = "Base font size for all DragonLoot frames",
        min = 8,
        max = 20,
        step = 1,
        format = "%d",
        get = function() return db.profile.appearance.fontSize end,
        set = function(value)
            db.profile.appearance.fontSize = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(fontSizeSlider, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local outlineDropdown = W.CreateDropdown(parent, {
        label = "Font Outline",
        values = FONT_OUTLINE_VALUES,
        get = function() return db.profile.appearance.fontOutline end,
        set = function(value)
            db.profile.appearance.fontOutline = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(outlineDropdown, parent, yOffset) - SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Icon Sizes
-------------------------------------------------------------------------------

local function CreateIconSection(parent, W, db, yOffset)
    local header = W.CreateHeader(parent, "Icon Sizes")
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    local lootIconSlider = W.CreateSlider(parent, {
        label = "Loot Icon Size",
        tooltip = "Icon size in the loot window",
        min = 16,
        max = 64,
        step = 2,
        format = "%d",
        get = function() return db.profile.appearance.lootIconSize end,
        set = function(value)
            db.profile.appearance.lootIconSize = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(lootIconSlider, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local rollIconSlider = W.CreateSlider(parent, {
        label = "Roll Icon Size",
        tooltip = "Icon size in the roll frame",
        min = 16,
        max = 64,
        step = 2,
        format = "%d",
        get = function() return db.profile.appearance.rollIconSize end,
        set = function(value)
            db.profile.appearance.rollIconSize = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(rollIconSlider, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local historyIconSlider = W.CreateSlider(parent, {
        label = "History Icon Size",
        tooltip = "Icon size in the history frame",
        min = 16,
        max = 48,
        step = 2,
        format = "%d",
        get = function() return db.profile.appearance.historyIconSize end,
        set = function(value)
            db.profile.appearance.historyIconSize = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(historyIconSlider, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local qualityBorderToggle = W.CreateToggle(parent, {
        label = "Quality Border",
        tooltip = "Show quality-colored borders on item icons",
        get = function() return db.profile.appearance.qualityBorder end,
        set = function(value)
            db.profile.appearance.qualityBorder = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(qualityBorderToggle, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local slotBgDropdown = W.CreateDropdown(parent, {
        label = "Slot Background",
        values = SLOT_BG_VALUES,
        get = function() return db.profile.appearance.slotBackground end,
        set = function(value)
            db.profile.appearance.slotBackground = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(slotBgDropdown, parent, yOffset) - SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Background
-------------------------------------------------------------------------------

local function CreateBackgroundSection(parent, W, db, yOffset)
    local header = W.CreateHeader(parent, "Background")
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    local bgColorPicker = W.CreateColorPicker(parent, {
        label = "Background Color",
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
    })
    yOffset = AnchorWidget(bgColorPicker, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local bgAlphaSlider = W.CreateSlider(parent, {
        label = "Background Opacity",
        tooltip = "Opacity of the frame background",
        min = 0,
        max = 1,
        step = 0.05,
        isPercent = true,
        get = function() return db.profile.appearance.backgroundAlpha end,
        set = function(value)
            db.profile.appearance.backgroundAlpha = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(bgAlphaSlider, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local bgTextureDropdown = W.CreateDropdown(parent, {
        label = "Background Texture",
        values = GetBackgroundValues,
        sort = true,
        mediaType = "background",
        get = function() return db.profile.appearance.backgroundTexture end,
        set = function(value)
            db.profile.appearance.backgroundTexture = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(bgTextureDropdown, parent, yOffset) - SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Border
-------------------------------------------------------------------------------

local function CreateBorderSection(parent, W, db, yOffset)
    local header = W.CreateHeader(parent, "Border")
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    local borderColorPicker = W.CreateColorPicker(parent, {
        label = "Border Color",
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
    })
    yOffset = AnchorWidget(borderColorPicker, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local borderSizeSlider = W.CreateSlider(parent, {
        label = "Border Size",
        tooltip = "Thickness of the frame border",
        min = 0,
        max = 4,
        step = 1,
        format = "%d",
        get = function() return db.profile.appearance.borderSize end,
        set = function(value)
            db.profile.appearance.borderSize = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(borderSizeSlider, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local borderTextureDropdown = W.CreateDropdown(parent, {
        label = "Border Texture",
        values = GetBorderValues,
        sort = true,
        mediaType = "border",
        get = function() return db.profile.appearance.borderTexture end,
        set = function(value)
            db.profile.appearance.borderTexture = value
            NotifyAppearanceChange()
        end,
    })
    yOffset = AnchorWidget(borderTextureDropdown, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Appearance tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local W = ns.Widgets
    local db = dlns.Addon.db
    local yOffset = PADDING_TOP

    yOffset = CreateFontSection(parent, W, db, yOffset)
    yOffset = CreateIconSection(parent, W, db, yOffset)
    yOffset = CreateBackgroundSection(parent, W, db, yOffset)
    yOffset = CreateBorderSection(parent, W, db, yOffset)

    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "appearance",
    label = "Appearance",
    order = 6,
    createFunc = CreateContent,
}
