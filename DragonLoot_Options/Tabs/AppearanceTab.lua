-------------------------------------------------------------------------------
-- AppearanceTab.lua
-- Appearance settings tab: font, icons, background, border
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...
local L = ns.L
local LC = ns.LayoutConstants

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- LSM list wrappers
-------------------------------------------------------------------------------

local function GetFontValues()
    return LC.BuildLSMValues("font")
end

local function GetBackgroundValues()
    return LC.BuildLSMValues("background")
end

local function GetBorderValues()
    return LC.BuildLSMValues("border")
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

local function CreateFontSection(parent, W, db, yOffset)
    local section = W.CreateSection(parent, L["Font"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local fontDropdown = W.CreateDropdown(content, {
        label = L["Font Family"],
        values = GetFontValues,
        sort = true,
        mediaType = "font",
        get = function() return db.profile.appearance.font end,
        set = function(value)
            db.profile.appearance.font = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(fontDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local fontSizeSlider = W.CreateSlider(content, {
        label = L["Font Size"],
        tooltip = L["Base font size for all DragonLoot frames"],
        min = 8,
        max = 20,
        step = 1,
        format = "%d",
        get = function() return db.profile.appearance.fontSize end,
        set = function(value)
            db.profile.appearance.fontSize = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(fontSizeSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local outlineDropdown = W.CreateDropdown(content, {
        label = L["Font Outline"],
        values = FONT_OUTLINE_VALUES,
        get = function() return db.profile.appearance.fontOutline end,
        set = function(value)
            db.profile.appearance.fontOutline = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(outlineDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local fontShadowToggle = W.CreateToggle(content, {
        label = L["Text Shadow"],
        tooltip = L["Enable text shadow on all text elements"],
        get = function() return db.profile.appearance.fontShadow end,
        set = function(value)
            db.profile.appearance.fontShadow = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(fontShadowToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Icon Sizes
-------------------------------------------------------------------------------

local function CreateIconSection(parent, W, db, yOffset)
    local section = W.CreateSection(parent, L["Icon Sizes"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local lootIconSlider = W.CreateSlider(content, {
        label = L["Loot Icon Size"],
        tooltip = L["Icon size in the loot window"],
        min = 16,
        max = 64,
        step = 2,
        format = "%d",
        get = function() return db.profile.appearance.lootIconSize end,
        set = function(value)
            db.profile.appearance.lootIconSize = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(lootIconSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local rollIconSlider = W.CreateSlider(content, {
        label = L["Roll Icon Size"],
        tooltip = L["Icon size in the roll frame"],
        min = 16,
        max = 64,
        step = 2,
        format = "%d",
        get = function() return db.profile.appearance.rollIconSize end,
        set = function(value)
            db.profile.appearance.rollIconSize = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(rollIconSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local historyIconSlider = W.CreateSlider(content, {
        label = L["History Icon Size"],
        tooltip = L["Icon size in the history frame"],
        min = 16,
        max = 48,
        step = 2,
        format = "%d",
        get = function() return db.profile.appearance.historyIconSize end,
        set = function(value)
            db.profile.appearance.historyIconSize = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(historyIconSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local qualityBorderToggle = W.CreateToggle(content, {
        label = L["Quality Border"],
        tooltip = L["Show quality-colored borders on item icons"],
        get = function() return db.profile.appearance.qualityBorder end,
        set = function(value)
            db.profile.appearance.qualityBorder = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(qualityBorderToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local slotBgDropdown = W.CreateDropdown(content, {
        label = L["Slot Background"],
        values = SLOT_BG_VALUES,
        get = function() return db.profile.appearance.slotBackground end,
        set = function(value)
            db.profile.appearance.slotBackground = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(slotBgDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Background
-------------------------------------------------------------------------------

local function CreateBackgroundSection(parent, W, db, yOffset)
    local section = W.CreateSection(parent, L["Background"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local bgColorPicker = W.CreateColorPicker(content, {
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
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(bgColorPicker, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local bgAlphaSlider = W.CreateSlider(content, {
        label = L["Background Opacity"],
        tooltip = L["Opacity of the frame background"],
        min = 0,
        max = 1,
        step = 0.05,
        isPercent = true,
        get = function() return db.profile.appearance.backgroundAlpha end,
        set = function(value)
            db.profile.appearance.backgroundAlpha = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(bgAlphaSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local bgTextureDropdown = W.CreateDropdown(content, {
        label = L["Background Texture"],
        values = GetBackgroundValues,
        sort = true,
        mediaType = "background",
        get = function() return db.profile.appearance.backgroundTexture end,
        set = function(value)
            db.profile.appearance.backgroundTexture = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(bgTextureDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Border
-------------------------------------------------------------------------------

local function CreateBorderSection(parent, W, db, yOffset)
    local section = W.CreateSection(parent, L["Border"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local borderColorPicker = W.CreateColorPicker(content, {
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
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(borderColorPicker, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local borderSizeSlider = W.CreateSlider(content, {
        label = L["Border Size"],
        tooltip = L["Thickness of the frame border"],
        min = 0,
        max = 4,
        step = 1,
        format = "%d",
        get = function() return db.profile.appearance.borderSize end,
        set = function(value)
            db.profile.appearance.borderSize = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(borderSizeSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local borderTextureDropdown = W.CreateDropdown(content, {
        label = L["Border Texture"],
        values = GetBorderValues,
        sort = true,
        mediaType = "border",
        get = function() return db.profile.appearance.borderTexture end,
        set = function(value)
            db.profile.appearance.borderTexture = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(borderTextureDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Appearance tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local W = ns.Widgets
    local db = dlns.Addon.db
    local yOffset = LC.PADDING_TOP

    yOffset = CreateFontSection(parent, W, db, yOffset)
    yOffset = CreateIconSection(parent, W, db, yOffset)
    yOffset = CreateBackgroundSection(parent, W, db, yOffset)
    yOffset = CreateBorderSection(parent, W, db, yOffset)

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "appearance",
    label = L["Appearance"],
    order = 7,
    createFunc = CreateContent,
}
