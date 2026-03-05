-------------------------------------------------------------------------------
-- Description.lua
-- Word-wrapped gray description text block
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
local FONT_SIZE = 11
local GRAY_COLOR = { 0.7, 0.7, 0.7 }
local PADDING_BOTTOM = 4
local DEFAULT_HEIGHT = 20

-------------------------------------------------------------------------------
-- Recalculate frame height from wrapped text
-------------------------------------------------------------------------------

local function UpdateHeight(frame)
    local textHeight = frame._fontString:GetStringHeight() or FONT_SIZE
    frame:SetHeight(textHeight + PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Factory: CreateDescription
-------------------------------------------------------------------------------

function ns.Widgets.CreateDescription(parent, text)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(DEFAULT_HEIGHT)

    local fontString = frame:CreateFontString(nil, "OVERLAY")
    fontString:SetFont(FONT_PATH, FONT_SIZE, "")
    fontString:SetTextColor(GRAY_COLOR[1], GRAY_COLOR[2], GRAY_COLOR[3])
    fontString:SetJustifyH("LEFT")
    fontString:SetWordWrap(true)
    fontString:SetNonSpaceWrap(true)
    fontString:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    fontString:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    fontString:SetText(text)

    frame._fontString = fontString

    -- Recalculate height when parent width changes
    frame:SetScript("OnSizeChanged", function()
        UpdateHeight(frame)
    end)

    -- SetText method
    function frame:SetText(newText)
        fontString:SetText(newText)
        UpdateHeight(self)
    end

    -- Initial height calc (deferred one frame so width is resolved)
    frame:SetScript("OnShow", function(self)
        UpdateHeight(self)
    end)

    return frame
end
