-------------------------------------------------------------------------------
-- TextInput.lua
-- Single-line text input with label and bordered edit box
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
local LABEL_FONT_SIZE = 12
local INPUT_FONT_SIZE = 11
local WHITE_COLOR = { 1, 1, 1 }
local DISABLED_COLOR = { 0.5, 0.5, 0.5 }
local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"
local INPUT_BG = { 0.08, 0.08, 0.08, 0.9 }
local INPUT_BORDER = { 0.3, 0.3, 0.3, 1 }
local DEFAULT_WIDTH = 200
local INPUT_HEIGHT = 22
local FRAME_HEIGHT = 40
local LABEL_GAP = 2

-------------------------------------------------------------------------------
-- Factory: CreateTextInput
-------------------------------------------------------------------------------

function ns.Widgets.CreateTextInput(parent, opts)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(FRAME_HEIGHT)

    local disabled = false
    local inputWidth = opts.width or DEFAULT_WIDTH

    -- Label at top
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_PATH, LABEL_FONT_SIZE, "")
    label:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetText(opts.label or "")

    -- EditBox below label
    local editBox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    editBox:SetSize(inputWidth, INPUT_HEIGHT)
    editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -LABEL_GAP)
    editBox:SetBackdrop({
        bgFile = WHITE8x8,
        edgeFile = WHITE8x8,
        edgeSize = 1,
    })
    editBox:SetBackdropColor(INPUT_BG[1], INPUT_BG[2], INPUT_BG[3], INPUT_BG[4])
    editBox:SetBackdropBorderColor(INPUT_BORDER[1], INPUT_BORDER[2], INPUT_BORDER[3], INPUT_BORDER[4])
    editBox:SetFont(FONT_PATH, INPUT_FONT_SIZE, "")
    editBox:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
    editBox:SetTextInsets(4, 4, 0, 0)
    editBox:SetAutoFocus(false)

    if opts.maxLength then
        editBox:SetMaxLetters(opts.maxLength)
    end

    -- OnEnterPressed: commit value
    editBox:SetScript("OnEnterPressed", function(self)
        if disabled then return end
        if opts.set then opts.set(self:GetText()) end
        self:ClearFocus()
    end)

    -- OnEscapePressed: revert to stored value
    editBox:SetScript("OnEscapePressed", function(self)
        if opts.get then
            self:SetText(opts.get() or "")
        end
        self:ClearFocus()
    end)

    -- Suppress tab key
    editBox:SetScript("OnTabPressed", function(self)
        self:ClearFocus()
    end)

    -- Block focus when disabled
    editBox:SetScript("OnEditFocusGained", function(self)
        if disabled then self:ClearFocus() end
    end)

    -- Initialize from opts.get
    if opts.get then
        editBox:SetText(opts.get() or "")
    end

    -- Public API
    function frame:GetValue()
        return editBox:GetText()
    end

    function frame:SetValue(v)
        editBox:SetText(v or "")
    end

    function frame:SetDisabled(state)
        disabled = state
        if disabled then
            label:SetTextColor(DISABLED_COLOR[1], DISABLED_COLOR[2], DISABLED_COLOR[3])
            editBox:SetAlpha(0.5)
        else
            label:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
            editBox:SetAlpha(1)
        end
    end

    function frame:Refresh()
        if opts.get then
            editBox:SetText(opts.get() or "")
        end
    end

    frame._editBox = editBox
    frame._label = label
    frame.order = opts.order

    return frame
end
