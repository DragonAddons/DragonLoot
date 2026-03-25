-------------------------------------------------------------------------------
-- WidgetConstants.lua
-- Shared constants and helpers for DragonLoot_Options widgets
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

local GameTooltip = GameTooltip

-------------------------------------------------------------------------------
-- Shared constants used across multiple widget files
-------------------------------------------------------------------------------

ns.WidgetConstants = {
    FONT_PATH = "Fonts\\FRIZQT__.TTF",
    FONT_SIZE = 12,
    WHITE8x8 = "Interface\\Buttons\\WHITE8x8",
    WHITE_COLOR = { 1, 1, 1 },
    DISABLED_COLOR = { 0.5, 0.5, 0.5 },
    GRAY_COLOR = { 0.7, 0.7, 0.7 },
    EMPTY_ICON = "Interface\\PaperDoll\\UI-Backpack-EmptySlot",

    -- Layered UI color palette (deepest -> brightest)
    PANEL_BG = { 0.06, 0.06, 0.06, 0.95 },
    SECTION_BG = { 0.10, 0.10, 0.11, 0.80 },
    SECTION_BORDER = { 0.20, 0.20, 0.22, 0.50 },
    WIDGET_BG = { 0.18, 0.18, 0.18, 1 },
    WIDGET_BG_HOVER = { 0.24, 0.24, 0.24, 1 },
    SLIDER_TRACK = { 0.25, 0.25, 0.25, 1 },
    SLIDER_FILL = { 0.45, 0.45, 0.45, 1 },
    HEADER_ACCENT = { 0.80, 0.70, 0.20, 0.15 },
    GOLD_COLOR = { 1, 0.82, 0 },
}

-------------------------------------------------------------------------------
-- Shared tooltip handlers (used by Toggle, Button)
-------------------------------------------------------------------------------

function ns.WidgetConstants.ShowTooltip(frame)
    if not frame._tooltipText then return end
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText(frame._tooltipText, 1, 1, 1, 1, true)
    GameTooltip:Show()
end

function ns.WidgetConstants.HideTooltip()
    GameTooltip:Hide()
end
