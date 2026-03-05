-------------------------------------------------------------------------------
-- Header.lua
-- Section header with bold gold text and horizontal separator
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 14
local GOLD_COLOR = { 1, 0.82, 0 }
local SEPARATOR_COLOR = { 0.3, 0.3, 0.3, 1 }
local SEPARATOR_HEIGHT = 1
local FRAME_HEIGHT = 28

-------------------------------------------------------------------------------
-- Factory: CreateHeader
-------------------------------------------------------------------------------

function ns.Widgets.CreateHeader(parent, text)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(FRAME_HEIGHT)

    -- Gold bold text
    local fontString = frame:CreateFontString(nil, "OVERLAY")
    fontString:SetFont(FONT_PATH, FONT_SIZE, "OUTLINE")
    fontString:SetTextColor(GOLD_COLOR[1], GOLD_COLOR[2], GOLD_COLOR[3])
    fontString:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    fontString:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    fontString:SetJustifyH("LEFT")
    fontString:SetText(text)

    -- Horizontal separator below text
    local separator = frame:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(SEPARATOR_HEIGHT)
    separator:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    separator:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    separator:SetColorTexture(
        SEPARATOR_COLOR[1], SEPARATOR_COLOR[2], SEPARATOR_COLOR[3], SEPARATOR_COLOR[4]
    )

    frame._fontString = fontString
    frame._separator = separator

    return frame
end
