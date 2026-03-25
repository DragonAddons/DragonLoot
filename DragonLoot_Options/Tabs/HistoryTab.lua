-------------------------------------------------------------------------------
-- HistoryTab.lua
-- History settings tab: enable, auto-show, direct loot tracking, layout
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
local tostring = tostring
local tonumber = tonumber

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

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
-- Section: History (toggles, dropdown, roll details)
-------------------------------------------------------------------------------

local function CreateTogglesSection(parent, W, db, yOffset)
    local section = W.CreateSection(parent, L["History"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    -- Enable History
    local enableToggle = W.CreateToggle(content, {
        label = L["Enable History"],
        get = function() return db.profile.history.enabled end,
        set = function(value)
            db.profile.history.enabled = value
            ApplyHistorySettings()
        end,
    })
    innerY = LC.AnchorWidget(enableToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Auto Show on Loot
    local autoShowToggle = W.CreateToggle(content, {
        label = L["Auto Show on Loot"],
        get = function() return db.profile.history.autoShow end,
        set = function(value)
            db.profile.history.autoShow = value
        end,
    })
    innerY = LC.AnchorWidget(autoShowToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Forward-declare so the toggle set closure captures the variable
    local qualityDropdown

    -- Track Direct Loot (set callback updates dropdown disabled state)
    local trackToggle = W.CreateToggle(content, {
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
    innerY = LC.AnchorWidget(trackToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Minimum Quality dropdown
    qualityDropdown = W.CreateDropdown(content, {
        label = L["Minimum Quality"],
        values = ns.QualityValues,
        get = function() return tostring(db.profile.history.minQuality) end,
        set = function(value)
            db.profile.history.minQuality = tonumber(value)
        end,
    })
    innerY = LC.AnchorWidget(qualityDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Apply initial disabled state based on current trackDirectLoot value
    qualityDropdown:SetDisabled(not db.profile.history.trackDirectLoot)

    -- Roll Details sub-header (visual separator inside section)
    local detailsHeader = W.CreateHeader(content, L["Roll Details"])
    innerY = LC.AnchorWidget(detailsHeader, content, innerY) - LC.SPACING_AFTER_HEADER

    -- Show Roll Details toggle
    local rollDetailsToggle = W.CreateToggle(content, {
        label = L["Show Roll Details"],
        tooltip = L["Click history entries to expand and see all player rolls"],
        get = function() return db.profile.history.showRollDetails end,
        set = function(value)
            db.profile.history.showRollDetails = value
            ApplyHistorySettings()
        end,
    })
    innerY = LC.AnchorWidget(rollDetailsToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Layout (sliders)
-------------------------------------------------------------------------------

local function CreateLayoutSection(parent, W, db, yOffset)
    local section = W.CreateSection(parent, L["Layout"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    -- Slider: Max Entries
    local maxEntriesSlider = W.CreateSlider(content, {
        label = L["Max Entries"],
        min = 10, max = 500, step = 10,
        format = "%d",
        get = function() return db.profile.history.maxEntries end,
        set = function(value)
            db.profile.history.maxEntries = value
        end,
    })
    innerY = LC.AnchorWidget(maxEntriesSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Slider: Entry Spacing
    local entrySpacingSlider = W.CreateSlider(content, {
        label = L["Entry Spacing"],
        min = 0, max = 12, step = 1,
        format = "%d",
        get = function() return db.profile.history.entrySpacing end,
        set = function(value)
            db.profile.history.entrySpacing = value
            ApplyHistorySettings()
        end,
    })
    innerY = LC.AnchorWidget(entrySpacingSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Slider: Content Padding
    local contentPaddingSlider = W.CreateSlider(content, {
        label = L["Content Padding"],
        min = 0, max = 12, step = 1,
        format = "%d",
        get = function() return db.profile.history.contentPadding end,
        set = function(value)
            db.profile.history.contentPadding = value
            ApplyHistorySettings()
        end,
    })
    innerY = LC.AnchorWidget(contentPaddingSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the History tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local W = ns.Widgets
    local db = dlns.Addon.db
    local yOffset = LC.PADDING_TOP

    -- History toggles and dropdown section
    yOffset = CreateTogglesSection(parent, W, db, yOffset)

    -- Layout sliders section
    yOffset = CreateLayoutSection(parent, W, db, yOffset)

    -- Set content height for scroll frame
    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
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
