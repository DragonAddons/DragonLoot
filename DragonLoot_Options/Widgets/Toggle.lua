-------------------------------------------------------------------------------
-- Toggle.lua
-- Checkbox toggle with label and optional tooltip
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 12
local BOX_SIZE = 20
local WHITE_COLOR = { 1, 1, 1 }
local DISABLED_COLOR = { 0.5, 0.5, 0.5 }
local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"
local CHECK_TEXTURE = "Interface\\Buttons\\UI-CheckBox-Check"
local BOX_BG = { 0.1, 0.1, 0.1, 0.9 }
local BOX_BORDER = { 0.4, 0.4, 0.4, 1 }
local FRAME_HEIGHT = 24
local LABEL_OFFSET = 6

-------------------------------------------------------------------------------
-- Show tooltip on enter
-------------------------------------------------------------------------------

local function OnEnter(frame)
    if not frame._tooltipText then return end
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText(frame._tooltipText, 1, 1, 1, 1, true)
    GameTooltip:Show()
end

local function OnLeave()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- Create the checkbox box frame
-------------------------------------------------------------------------------

local function CreateCheckBox(parent)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetSize(BOX_SIZE, BOX_SIZE)
    box:SetBackdrop({
        bgFile = WHITE8x8,
        edgeFile = WHITE8x8,
        edgeSize = 1,
    })
    box:SetBackdropColor(BOX_BG[1], BOX_BG[2], BOX_BG[3], BOX_BG[4])
    box:SetBackdropBorderColor(BOX_BORDER[1], BOX_BORDER[2], BOX_BORDER[3], BOX_BORDER[4])

    -- Check mark
    local checkMark = box:CreateTexture(nil, "OVERLAY")
    checkMark:SetTexture(CHECK_TEXTURE)
    checkMark:SetPoint("CENTER", box, "CENTER", 0, 0)
    checkMark:SetSize(BOX_SIZE + 4, BOX_SIZE + 4)
    checkMark:Hide()

    -- Highlight on hover
    local highlight = box:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.08)

    box._checkMark = checkMark
    return box
end

-------------------------------------------------------------------------------
-- Factory: CreateToggle
-------------------------------------------------------------------------------

function ns.Widgets.CreateToggle(parent, opts)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(FRAME_HEIGHT)

    local checked = false
    local disabled = false

    -- Checkbox
    local box = CreateCheckBox(frame)
    box:SetPoint("LEFT", frame, "LEFT", 0, 0)

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_PATH, FONT_SIZE, "")
    label:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
    label:SetPoint("LEFT", box, "RIGHT", LABEL_OFFSET, 0)
    label:SetText(opts.label or "")

    -- Tooltip
    frame._tooltipText = opts.tooltip

    -- Click handler on the entire frame
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", OnEnter)
    frame:SetScript("OnLeave", OnLeave)
    frame:SetScript("OnMouseUp", function()
        if disabled then return end
        checked = not checked
        box._checkMark:SetShown(checked)
        if opts.set then opts.set(checked) end
    end)

    -- Initialize from opts.get
    if opts.get then
        checked = not not opts.get()
        box._checkMark:SetShown(checked)
    end

    -- Apply initial disabled state
    if opts.disabled then
        disabled = true
        label:SetTextColor(DISABLED_COLOR[1], DISABLED_COLOR[2], DISABLED_COLOR[3])
        box:SetAlpha(0.5)
    end

    -- Public API
    function frame:GetValue()
        return checked
    end

    function frame:SetValue(v)
        checked = not not v
        box._checkMark:SetShown(checked)
    end

    function frame:SetDisabled(state)
        disabled = state
        if disabled then
            label:SetTextColor(DISABLED_COLOR[1], DISABLED_COLOR[2], DISABLED_COLOR[3])
            box:SetAlpha(0.5)
        else
            label:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
            box:SetAlpha(1)
        end
    end

    function frame:Refresh()
        if opts.get then
            checked = not not opts.get()
            box._checkMark:SetShown(checked)
        end
    end

    frame._box = box
    frame._label = label
    frame.order = opts.order

    return frame
end
