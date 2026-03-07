-------------------------------------------------------------------------------
-- HistoryTab.lua
-- History settings tab: enable, auto-show, direct loot tracking, layout
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local L = ns.L

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

-------------------------------------------------------------------------------
-- Helper: call HistoryFrame.ApplySettings if available
-------------------------------------------------------------------------------

local function ApplyHistorySettings()
    if dlns.HistoryFrame and dlns.HistoryFrame.ApplySettings then
        dlns.HistoryFrame.ApplySettings()
    end
end

-------------------------------------------------------------------------------
-- Anchor a widget to parent at the current yOffset
-------------------------------------------------------------------------------

local function AnchorWidget(widget, parent, yOffset)
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
end

-------------------------------------------------------------------------------
-- Build toggles and dropdown section
-------------------------------------------------------------------------------

local function CreateTogglesSection(parent, W, db, yOffset)
    -- Enable History
    local enableToggle = W.CreateToggle(parent, {
        label = L["Enable History"],
        get = function() return db.profile.history.enabled end,
        set = function(value)
            db.profile.history.enabled = value
            ApplyHistorySettings()
        end,
    })
    AnchorWidget(enableToggle, parent, yOffset)
    yOffset = yOffset - enableToggle:GetHeight() - SPACING_BETWEEN_WIDGETS

    -- Auto Show on Loot
    local autoShowToggle = W.CreateToggle(parent, {
        label = L["Auto Show on Loot"],
        get = function() return db.profile.history.autoShow end,
        set = function(value)
            db.profile.history.autoShow = value
        end,
    })
    AnchorWidget(autoShowToggle, parent, yOffset)
    yOffset = yOffset - autoShowToggle:GetHeight() - SPACING_BETWEEN_WIDGETS

    -- Forward-declare so the toggle set closure captures the variable
    local qualityDropdown

    -- Track Direct Loot (set callback updates dropdown disabled state)
    local trackToggle = W.CreateToggle(parent, {
        label = L["Track Direct Loot"],
        tooltip = L["Track items you pick up directly (not from a loot window)"],
        get = function() return db.profile.history.trackDirectLoot end,
        set = function(value)
            db.profile.history.trackDirectLoot = value
            if qualityDropdown then
                qualityDropdown:SetDisabled(not value)
            end
        end,
    })
    AnchorWidget(trackToggle, parent, yOffset)
    yOffset = yOffset - trackToggle:GetHeight() - SPACING_BETWEEN_WIDGETS

    -- Minimum Quality dropdown
    qualityDropdown = W.CreateDropdown(parent, {
        label = L["Minimum Quality"],
        values = ns.QualityValues,
        get = function() return tostring(db.profile.history.minQuality) end,
        set = function(value)
            db.profile.history.minQuality = tonumber(value)
        end,
    })
    AnchorWidget(qualityDropdown, parent, yOffset)
    yOffset = yOffset - qualityDropdown:GetHeight() - SPACING_BETWEEN_WIDGETS

    -- Apply initial disabled state based on current trackDirectLoot value
    qualityDropdown:SetDisabled(not db.profile.history.trackDirectLoot)

    return yOffset
end

-------------------------------------------------------------------------------
-- Build layout sliders section
-------------------------------------------------------------------------------

local function CreateLayoutSection(parent, W, db, yOffset)
    -- Header: Layout
    local layoutHeader = W.CreateHeader(parent, L["Layout"])
    AnchorWidget(layoutHeader, parent, yOffset)
    yOffset = yOffset - layoutHeader:GetHeight() - SPACING_AFTER_HEADER

    -- Slider: Max Entries
    local maxEntriesSlider = W.CreateSlider(parent, {
        label = L["Max Entries"],
        min = 10, max = 500, step = 10,
        format = "%d",
        get = function() return db.profile.history.maxEntries end,
        set = function(value)
            db.profile.history.maxEntries = value
        end,
    })
    AnchorWidget(maxEntriesSlider, parent, yOffset)
    yOffset = yOffset - maxEntriesSlider:GetHeight() - SPACING_BETWEEN_WIDGETS

    -- Slider: Entry Spacing
    local entrySpacingSlider = W.CreateSlider(parent, {
        label = L["Entry Spacing"],
        min = 0, max = 12, step = 1,
        format = "%d",
        get = function() return db.profile.history.entrySpacing end,
        set = function(value)
            db.profile.history.entrySpacing = value
            ApplyHistorySettings()
        end,
    })
    AnchorWidget(entrySpacingSlider, parent, yOffset)
    yOffset = yOffset - entrySpacingSlider:GetHeight() - SPACING_BETWEEN_WIDGETS

    -- Slider: Content Padding
    local contentPaddingSlider = W.CreateSlider(parent, {
        label = L["Content Padding"],
        min = 0, max = 12, step = 1,
        format = "%d",
        get = function() return db.profile.history.contentPadding end,
        set = function(value)
            db.profile.history.contentPadding = value
            ApplyHistorySettings()
        end,
    })
    AnchorWidget(contentPaddingSlider, parent, yOffset)
    yOffset = yOffset - contentPaddingSlider:GetHeight() - SPACING_BETWEEN_WIDGETS

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the History tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local W = ns.Widgets
    local db = dlns.Addon.db
    local yOffset = PADDING_TOP

    -- Header: History
    local header = W.CreateHeader(parent, L["History"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    -- Toggles and dropdown section
    yOffset = CreateTogglesSection(parent, W, db, yOffset)

    -- Section gap before layout
    yOffset = yOffset - SPACING_BETWEEN_SECTIONS + SPACING_BETWEEN_WIDGETS

    -- Layout sliders section
    yOffset = CreateLayoutSection(parent, W, db, yOffset)

    -- Set content height for scroll frame
    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)
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
