-------------------------------------------------------------------------------
-- Header.lua
-- Sub-header with gold text and subtle horizontal separator
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
local FONT_SIZE = 12
local SEPARATOR_HEIGHT = 1
local FRAME_HEIGHT = 20

-------------------------------------------------------------------------------
-- Factory: CreateHeader
-------------------------------------------------------------------------------

function ns.Widgets.CreateHeader(parent, text)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(FRAME_HEIGHT)

    -- Gold text with left padding, vertically centered
    local fontString = frame:CreateFontString(nil, "OVERLAY")
    fontString:SetFont(FONT_PATH, FONT_SIZE)
    fontString:SetTextColor(WC.GOLD_COLOR[1], WC.GOLD_COLOR[2], WC.GOLD_COLOR[3])
    fontString:SetPoint("LEFT", frame, "LEFT", 4, 0)
    fontString:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    fontString:SetJustifyH("LEFT")
    fontString:SetText(text)

    -- Subtle gold separator below text
    local separator = frame:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(SEPARATOR_HEIGHT)
    separator:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    separator:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    separator:SetColorTexture(WC.GOLD_COLOR[1], WC.GOLD_COLOR[2], WC.GOLD_COLOR[3], 0.2)

    frame._fontString = fontString
    frame._separator = separator

    return frame
end
