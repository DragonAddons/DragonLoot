-------------------------------------------------------------------------------
-- Section.lua
-- Card panel container that groups related settings with a header
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
local WHITE8x8 = WC.WHITE8x8
local SECTION_BG = WC.SECTION_BG
local SECTION_BORDER = WC.SECTION_BORDER
local HEADER_ACCENT = WC.HEADER_ACCENT
local GOLD_COLOR = WC.GOLD_COLOR

local HEADER_FONT_SIZE = 13
local HEADER_HEIGHT = 24
local PADDING = 12

-------------------------------------------------------------------------------
-- Factory: CreateSection
-------------------------------------------------------------------------------

function ns.Widgets.CreateSection(parent, headerText)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetHeight(HEADER_HEIGHT + PADDING + PADDING)

    -- Backdrop: subtle card background with thin border
    frame:SetBackdrop({
        bgFile = WHITE8x8,
        edgeFile = WHITE8x8,
        edgeSize = 1,
    })
    frame:SetBackdropColor(SECTION_BG[1], SECTION_BG[2], SECTION_BG[3], SECTION_BG[4])
    frame:SetBackdropBorderColor(
        SECTION_BORDER[1], SECTION_BORDER[2], SECTION_BORDER[3], SECTION_BORDER[4]
    )

    -- Header accent background bar
    local headerBg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    headerBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    headerBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    headerBg:SetHeight(HEADER_HEIGHT)
    headerBg:SetColorTexture(
        HEADER_ACCENT[1], HEADER_ACCENT[2], HEADER_ACCENT[3], HEADER_ACCENT[4]
    )

    -- Header text (bold gold)
    local headerLabel = frame:CreateFontString(nil, "OVERLAY")
    headerLabel:SetFont(FONT_PATH, HEADER_FONT_SIZE, "OUTLINE")
    headerLabel:SetTextColor(GOLD_COLOR[1], GOLD_COLOR[2], GOLD_COLOR[3])
    headerLabel:SetPoint("LEFT", frame, "TOPLEFT", PADDING, -(HEADER_HEIGHT / 2))
    headerLabel:SetJustifyH("LEFT")
    headerLabel:SetText(headerText or "")

    -- Content area below the header
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -(HEADER_HEIGHT + PADDING))
    content:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(HEADER_HEIGHT + PADDING))
    content:SetHeight(1)

    frame._headerBg = headerBg
    frame._headerLabel = headerLabel
    frame.content = content

    -- Public API: size the section after children are placed
    function frame:SetContentHeight(h)
        content:SetHeight(h)
        self:SetHeight(HEADER_HEIGHT + h + PADDING + PADDING)
    end

    return frame
end
