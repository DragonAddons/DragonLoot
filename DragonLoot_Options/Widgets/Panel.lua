-------------------------------------------------------------------------------
-- Panel.lua
-- BackdropTemplate container frame with title bar and close button
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local UIParent = UIParent
local pcall = pcall

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TITLE_BAR_HEIGHT = 28
local BG_COLOR = { 0.08, 0.08, 0.08, 0.95 }
local BORDER_COLOR = { 0.3, 0.3, 0.3, 1 }
local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"

-------------------------------------------------------------------------------
-- Title bar creation
-------------------------------------------------------------------------------

local function CreateTitleBar(parent)
    local titleBar = CreateFrame("Frame", nil, parent)
    titleBar:SetHeight(TITLE_BAR_HEIGHT)
    titleBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    -- Title text
    titleBar.text = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleBar.text:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
    titleBar.text:SetText("DragonLoot Options")
    titleBar.text:SetTextColor(1, 0.82, 0)

    -- Make title bar the drag handle
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        parent:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        parent:StopMovingOrSizing()
    end)

    return titleBar
end

-------------------------------------------------------------------------------
-- Close button creation
-------------------------------------------------------------------------------

local function CreateCloseButton(titleBar, parent)
    local ok, closeBtn = pcall(CreateFrame, "Button", nil, titleBar, "UIPanelCloseButton")
    if not ok or not closeBtn then
        closeBtn = CreateFrame("Button", nil, titleBar)
        closeBtn:SetSize(24, 24)

        local normalTex = closeBtn:CreateTexture(nil, "ARTWORK")
        normalTex:SetAllPoints()
        normalTex:SetColorTexture(0.8, 0.2, 0.2, 0.8)
        closeBtn:SetNormalTexture(normalTex)

        local highlightTex = closeBtn:CreateTexture(nil, "HIGHLIGHT")
        highlightTex:SetAllPoints()
        highlightTex:SetColorTexture(1, 0.3, 0.3, 0.9)

        local label = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("CENTER")
        label:SetText("X")
        label:SetTextColor(1, 1, 1)
    end

    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -4, -2)
    closeBtn:SetScript("OnClick", function()
        parent:Hide()
    end)

    return closeBtn
end

-------------------------------------------------------------------------------
-- Factory: CreatePanel
-------------------------------------------------------------------------------

function ns.Widgets.CreatePanel(name, width, height)
    local panel = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    panel:SetSize(width, height)
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    panel:SetFrameStrata("HIGH")
    panel:SetFrameLevel(100)
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:Hide()

    -- Backdrop
    panel:SetBackdrop({
        bgFile = WHITE8x8,
        edgeFile = WHITE8x8,
        edgeSize = 1,
    })
    panel:SetBackdropColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], BG_COLOR[4])
    panel:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])

    -- Title bar (also serves as drag handle)
    panel.titleBar = CreateTitleBar(panel)

    -- Close button
    panel.closeBtn = CreateCloseButton(panel.titleBar, panel)

    return panel
end
