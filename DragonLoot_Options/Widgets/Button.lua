-------------------------------------------------------------------------------
-- Button.lua
-- Styled action button with tooltip support
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local pcall = pcall

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 12
local DEFAULT_WIDTH = 120
local BUTTON_HEIGHT = 24
local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"
local NORMAL_BG = { 0.15, 0.15, 0.15, 0.9 }
local NORMAL_BORDER = { 0.4, 0.4, 0.4, 1 }
local DISABLED_COLOR = { 0.5, 0.5, 0.5 }
local WHITE_COLOR = { 1, 1, 1 }

-------------------------------------------------------------------------------
-- Tooltip handlers
-------------------------------------------------------------------------------

local function OnEnter(self)
    if not self._tooltipText then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self._tooltipText, 1, 1, 1, 1, true)
    GameTooltip:Show()
end

local function OnLeave()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- Build a custom styled button (fallback when template is unavailable)
-------------------------------------------------------------------------------

local function CreateCustomButton(parent, width)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, BUTTON_HEIGHT)
    btn:SetBackdrop({
        bgFile = WHITE8x8,
        edgeFile = WHITE8x8,
        edgeSize = 1,
    })
    btn:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
    btn:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])

    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont(FONT_PATH, FONT_SIZE, "")
    text:SetPoint("CENTER")
    text:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
    btn._text = text

    -- Highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.08)

    -- Pressed visual
    btn:SetScript("OnMouseDown", function(self)
        if self._disabled then return end
        self._text:SetPoint("CENTER", 1, -1)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self._text:SetPoint("CENTER", 0, 0)
    end)

    return btn
end

-------------------------------------------------------------------------------
-- Factory: CreateButton
-------------------------------------------------------------------------------

function ns.Widgets.CreateButton(parent, opts)
    local width = opts.width or DEFAULT_WIDTH
    -- Try template first, fall back to custom
    local ok, btn = pcall(CreateFrame, "Button", nil, parent, "UIPanelButtonTemplate")
    if not ok or not btn then
        btn = CreateCustomButton(parent, width)
    else
        btn:SetSize(width, BUTTON_HEIGHT)
    end

    btn:SetText(opts.text or "")
    btn._tooltipText = opts.tooltip
    btn._disabled = false

    -- Click handler
    btn:SetScript("OnClick", function(self)
        if self._disabled then return end
        if opts.onClick then opts.onClick() end
    end)

    btn:SetScript("OnEnter", OnEnter)
    btn:SetScript("OnLeave", OnLeave)

    -- SetDisabled
    function btn:SetDisabled(state)
        self._disabled = state
        if state then
            self:SetAlpha(0.5)
            if self._text then
                self._text:SetTextColor(DISABLED_COLOR[1], DISABLED_COLOR[2], DISABLED_COLOR[3])
            end
        else
            self:SetAlpha(1)
            if self._text then
                self._text:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
            end
        end
    end

    btn.order = opts.order

    return btn
end
