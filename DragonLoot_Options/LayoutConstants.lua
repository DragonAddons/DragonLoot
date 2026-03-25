-------------------------------------------------------------------------------
-- LayoutConstants.lua
-- Shared layout constants and helpers for DragonLoot_Options tab files
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

local table_sort = table.sort
local pairs = pairs
local LibStub = LibStub

-------------------------------------------------------------------------------
-- Layout constants shared across all tab files
-------------------------------------------------------------------------------

local LC = {
    PADDING_SIDE = 10,
    PADDING_TOP = -10,
    PADDING_BOTTOM = 20,
    SPACING_AFTER_HEADER = 8,
    SPACING_BETWEEN_WIDGETS = 6,
    SPACING_BETWEEN_SECTIONS = 16,
    SECTION_PADDING_TOP = 8,
    SECTION_PADDING_BOTTOM = 12,
    SECTION_PADDING_SIDE = 12,
    SUB_OPTION_INDENT = 16,
}

-------------------------------------------------------------------------------
-- Anchor a widget to the parent at the current yOffset
--
-- Sets TOPLEFT and TOPRIGHT anchors with PADDING_SIDE insets.
-- Returns the new yOffset (widget bottom edge).
-------------------------------------------------------------------------------

function LC.AnchorWidget(widget, parent, yOffset, xLeft, xRight)
    xLeft = xLeft or LC.PADDING_SIDE
    xRight = xRight or -LC.PADDING_SIDE
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", xLeft, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", xRight, yOffset)
    return yOffset - widget:GetHeight()
end

-------------------------------------------------------------------------------
-- Anchor a Section card to the parent at the current yOffset
--
-- Sets TOPLEFT and TOPRIGHT anchors with PADDING_SIDE insets.
-- Returns the new yOffset (section bottom edge).
-------------------------------------------------------------------------------

function LC.AnchorSection(section, parent, yOffset)
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", LC.PADDING_SIDE, yOffset)
    section:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -LC.PADDING_SIDE, yOffset)
    return yOffset - section:GetHeight()
end

-------------------------------------------------------------------------------
-- Notify all DragonLoot display frames to re-apply their settings
--
-- Safe to call at any time; missing modules are silently skipped.
-------------------------------------------------------------------------------

function LC.NotifyAppearanceChange()
    local dl = ns.dlns
    if not dl then return end
    if dl.LootFrame and dl.LootFrame.ApplySettings then dl.LootFrame.ApplySettings() end
    if dl.RollManager and dl.RollManager.ApplySettings then dl.RollManager.ApplySettings() end
    if dl.HistoryFrame and dl.HistoryFrame.ApplySettings then dl.HistoryFrame.ApplySettings() end
end

-------------------------------------------------------------------------------
-- Build a sorted values table from a LibSharedMedia media type
--
-- Returns a table of { value = key, text = key } suitable for Dropdown.
-------------------------------------------------------------------------------

local LSM = LibStub("LibSharedMedia-3.0")

function LC.BuildLSMValues(mediaType)
    local hash = LSM:HashTable(mediaType)
    local values = {}
    for key in pairs(hash) do
        values[#values + 1] = { value = key, text = key }
    end
    table_sort(values, function(a, b) return a.text < b.text end)
    return values
end

-------------------------------------------------------------------------------
-- Expose on namespace
-------------------------------------------------------------------------------

ns.LayoutConstants = LC
