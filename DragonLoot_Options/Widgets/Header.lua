-------------------------------------------------------------------------------
-- Header.lua
-- Section header with bold gold text and horizontal separator
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...
local WC = ns.WidgetConstants

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FONT_PATH = WC.FONT_PATH
local FONT_SIZE = 14
local SEPARATOR_HEIGHT = 1
local FRAME_HEIGHT = 28

-------------------------------------------------------------------------------
-- Factory: CreateHeader
-------------------------------------------------------------------------------

function ns.Widgets.CreateHeader(parent, text)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(FRAME_HEIGHT)

    -- Accent background bar
    local accent = frame:CreateTexture(nil, "BACKGROUND")
    accent:SetAllPoints()
    accent:SetColorTexture(
        WC.HEADER_ACCENT[1], WC.HEADER_ACCENT[2], WC.HEADER_ACCENT[3], WC.HEADER_ACCENT[4]
    )

    -- Gold bold text with left padding
    local fontString = frame:CreateFontString(nil, "OVERLAY")
    fontString:SetFont(FONT_PATH, FONT_SIZE, "OUTLINE")
    fontString:SetTextColor(WC.GOLD_COLOR[1], WC.GOLD_COLOR[2], WC.GOLD_COLOR[3])
    fontString:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, 0)
    fontString:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    fontString:SetJustifyH("LEFT")
    fontString:SetText(text)

    -- Gold separator below text
    local separator = frame:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(SEPARATOR_HEIGHT)
    separator:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    separator:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    separator:SetColorTexture(WC.GOLD_COLOR[1], WC.GOLD_COLOR[2], WC.GOLD_COLOR[3], 0.3)

    frame._fontString = fontString
    frame._separator = separator
    frame._accent = accent

    return frame
end
