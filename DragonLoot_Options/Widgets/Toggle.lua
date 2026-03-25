-------------------------------------------------------------------------------
-- Toggle.lua
-- Checkbox toggle with label and optional tooltip
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
local FONT_SIZE = WC.FONT_SIZE
local BOX_SIZE = 20
local WHITE_COLOR = WC.WHITE_COLOR
local DISABLED_COLOR = WC.DISABLED_COLOR
local WHITE8x8 = WC.WHITE8x8
local CHECK_TEXTURE = "Interface\\Buttons\\UI-CheckBox-Check"
local FRAME_HEIGHT = 24
local LABEL_OFFSET = 6

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
    box:SetBackdropColor(WC.WIDGET_BG[1], WC.WIDGET_BG[2], WC.WIDGET_BG[3], WC.WIDGET_BG[4])
    box:SetBackdropBorderColor(
        WC.SECTION_BORDER[1], WC.SECTION_BORDER[2], WC.SECTION_BORDER[3], WC.SECTION_BORDER[4]
    )

    -- Check mark
    local checkMark = box:CreateTexture(nil, "OVERLAY")
    checkMark:SetTexture(CHECK_TEXTURE)
    checkMark:SetPoint("CENTER", box, "CENTER", 0, 0)
    checkMark:SetSize(BOX_SIZE + 4, BOX_SIZE + 4)
    checkMark:Hide()

    box._checkMark = checkMark
    return box
end

-------------------------------------------------------------------------------
-- Update border color: gold tint when checked, default when unchecked
-------------------------------------------------------------------------------

local function UpdateCheckBorder(box, isChecked)
    if isChecked then
        box:SetBackdropBorderColor(WC.GOLD_COLOR[1], WC.GOLD_COLOR[2], WC.GOLD_COLOR[3], 0.5)
    else
        box:SetBackdropBorderColor(
            WC.SECTION_BORDER[1], WC.SECTION_BORDER[2],
            WC.SECTION_BORDER[3], WC.SECTION_BORDER[4]
        )
    end
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

    -- Hover state on checkbox
    box:SetScript("OnEnter", function()
        if disabled then return end
        box:SetBackdropColor(
            WC.WIDGET_BG_HOVER[1], WC.WIDGET_BG_HOVER[2],
            WC.WIDGET_BG_HOVER[3], WC.WIDGET_BG_HOVER[4]
        )
    end)
    box:SetScript("OnLeave", function()
        box:SetBackdropColor(WC.WIDGET_BG[1], WC.WIDGET_BG[2], WC.WIDGET_BG[3], WC.WIDGET_BG[4])
    end)

    -- Click handler on the entire frame
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", WC.ShowTooltip)
    frame:SetScript("OnLeave", WC.HideTooltip)
    frame:SetScript("OnMouseUp", function()
        if disabled then return end
        checked = not checked
        box._checkMark:SetShown(checked)
        UpdateCheckBorder(box, checked)
        if opts.set then opts.set(checked) end
    end)

    -- Initialize from opts.get
    if opts.get then
        checked = not not opts.get()
        box._checkMark:SetShown(checked)
        UpdateCheckBorder(box, checked)
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
        UpdateCheckBorder(box, checked)
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
            UpdateCheckBorder(box, checked)
        end
    end

    frame._box = box
    frame._label = label
    frame.order = opts.order

    return frame
end
