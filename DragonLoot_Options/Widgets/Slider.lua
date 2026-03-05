-------------------------------------------------------------------------------
-- Slider.lua
-- Horizontal slider with label, min/max labels, and editable value display
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local pcall = pcall
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local tonumber = tonumber
local format = string.format

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local LABEL_FONT_SIZE = 12
local VALUE_FONT_SIZE = 11
local MIN_MAX_FONT_SIZE = 10
local WHITE_COLOR = { 1, 1, 1 }
local GRAY_COLOR = { 0.7, 0.7, 0.7 }
local DISABLED_COLOR = { 0.5, 0.5, 0.5 }
local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"
local THUMB_TEXTURE = "Interface\\Buttons\\UI-SliderBar-Button-Horizontal"
local EDITBOX_WIDTH = 50
local FRAME_HEIGHT = 55
local SLIDER_HEIGHT = 17
local TRACK_BG = { 0.15, 0.15, 0.15, 0.9 }
local TRACK_BORDER = { 0.3, 0.3, 0.3, 1 }

-------------------------------------------------------------------------------
-- Utility: round to step
-------------------------------------------------------------------------------

local function RoundToStep(value, step)
    if not step or step <= 0 then return value end
    return math_floor(value / step + 0.5) * step
end

-------------------------------------------------------------------------------
-- Utility: clamp value
-------------------------------------------------------------------------------

local function Clamp(value, minVal, maxVal)
    return math_max(minVal, math_min(maxVal, value))
end

-------------------------------------------------------------------------------
-- Format the display value
-------------------------------------------------------------------------------

local function FormatValue(value, opts)
    local fmt = opts.format or "%.1f"
    if opts.isPercent then
        return format(fmt, value * 100) .. "%"
    end
    return format(fmt, value)
end

-------------------------------------------------------------------------------
-- Build a custom slider frame (fallback when template is unavailable)
-------------------------------------------------------------------------------

local function CreateCustomSlider(parent)
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    slider:SetHeight(SLIDER_HEIGHT)
    slider:SetBackdrop({
        bgFile = WHITE8x8,
        edgeFile = WHITE8x8,
        edgeSize = 1,
    })
    slider:SetBackdropColor(TRACK_BG[1], TRACK_BG[2], TRACK_BG[3], TRACK_BG[4])
    slider:SetBackdropBorderColor(TRACK_BORDER[1], TRACK_BORDER[2], TRACK_BORDER[3], TRACK_BORDER[4])

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(THUMB_TEXTURE)
    thumb:SetSize(16, 24)
    slider:SetThumbTexture(thumb)

    return slider
end

-------------------------------------------------------------------------------
-- Try the built-in template, fall back to custom
-------------------------------------------------------------------------------

local function CreateSliderFrame(parent)
    local ok, slider = pcall(CreateFrame, "Slider", nil, parent, "OptionsSliderTemplate")
    if ok and slider then
        -- Remove default template text elements that may interfere
        if slider.Text then slider.Text:Hide() end
        if slider.Low then slider.Low:Hide() end
        if slider.High then slider.High:Hide() end
        return slider
    end
    return CreateCustomSlider(parent)
end

-------------------------------------------------------------------------------
-- Factory: CreateSlider
-------------------------------------------------------------------------------

function ns.Widgets.CreateSlider(parent, opts)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(FRAME_HEIGHT)

    local disabled = false
    local minVal = opts.min or 0
    local maxVal = opts.max or 100
    local step = opts.step or 1
    local currentValue = minVal

    -- Label at top
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_PATH, LABEL_FONT_SIZE, "")
    label:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetText(opts.label or "")

    -- Slider below label
    local slider = CreateSliderFrame(frame)
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    slider:SetPoint("RIGHT", frame, "RIGHT", -(EDITBOX_WIDTH + 8), 0)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")

    -- Min label (bottom-left of slider)
    local minLabel = frame:CreateFontString(nil, "OVERLAY")
    minLabel:SetFont(FONT_PATH, MIN_MAX_FONT_SIZE, "")
    minLabel:SetTextColor(GRAY_COLOR[1], GRAY_COLOR[2], GRAY_COLOR[3])
    minLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -1)
    minLabel:SetText(FormatValue(minVal, opts))

    -- Max label (bottom-right of slider)
    local maxLabel = frame:CreateFontString(nil, "OVERLAY")
    maxLabel:SetFont(FONT_PATH, MIN_MAX_FONT_SIZE, "")
    maxLabel:SetTextColor(GRAY_COLOR[1], GRAY_COLOR[2], GRAY_COLOR[3])
    maxLabel:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -1)
    maxLabel:SetText(FormatValue(maxVal, opts))

    -- EditBox for typed value entry
    local editBox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    editBox:SetSize(EDITBOX_WIDTH, 20)
    editBox:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    editBox:SetBackdrop({
        bgFile = WHITE8x8,
        edgeFile = WHITE8x8,
        edgeSize = 1,
    })
    editBox:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    editBox:SetFont(FONT_PATH, VALUE_FONT_SIZE, "")
    editBox:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
    editBox:SetJustifyH("CENTER")
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(10)

    -- Suppress tab key to avoid focus issues
    editBox:SetScript("OnTabPressed", function(self)
        self:ClearFocus()
    end)

    -- Track whether slider update is internal to avoid feedback loops
    local isInternal = false

    -- Update the editbox text from a value
    local function UpdateEditBoxText(value)
        editBox:SetText(FormatValue(value, opts))
    end

    -- Slider OnValueChanged
    slider:SetScript("OnValueChanged", function(_, value)
        local rounded = RoundToStep(value, step)
        currentValue = rounded
        if not isInternal then
            UpdateEditBoxText(rounded)
            if opts.set then opts.set(rounded) end
        end
    end)

    -- EditBox OnEnterPressed
    editBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        -- Strip percent sign if present
        text = text:gsub("%%", "")
        local parsed = tonumber(text)
        if parsed then
            if opts.isPercent then parsed = parsed / 100 end
            parsed = Clamp(RoundToStep(parsed, step), minVal, maxVal)
            isInternal = true
            slider:SetValue(parsed)
            isInternal = false
            currentValue = parsed
            UpdateEditBoxText(parsed)
            if opts.set then opts.set(parsed) end
        else
            UpdateEditBoxText(currentValue)
        end
        self:ClearFocus()
    end)

    -- EditBox OnEscapePressed: revert
    editBox:SetScript("OnEscapePressed", function(self)
        UpdateEditBoxText(currentValue)
        self:ClearFocus()
    end)

    -- Initialize
    if opts.get then
        currentValue = opts.get() or minVal
    end
    isInternal = true
    slider:SetValue(currentValue)
    isInternal = false
    UpdateEditBoxText(currentValue)

    -- Public API
    function frame:GetValue()
        return currentValue
    end

    function frame:SetValue(v)
        local clamped = Clamp(RoundToStep(v, step), minVal, maxVal)
        currentValue = clamped
        isInternal = true
        slider:SetValue(clamped)
        isInternal = false
        UpdateEditBoxText(clamped)
    end

    function frame:SetDisabled(state)
        disabled = state
        slider:EnableMouse(not disabled)
        editBox:EnableMouse(not disabled)
        if disabled then
            label:SetTextColor(DISABLED_COLOR[1], DISABLED_COLOR[2], DISABLED_COLOR[3])
            slider:SetAlpha(0.5)
            editBox:SetAlpha(0.5)
        else
            label:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
            slider:SetAlpha(1)
            editBox:SetAlpha(1)
        end
    end

    function frame:Refresh()
        if opts.get then
            local v = opts.get() or minVal
            local clamped = Clamp(RoundToStep(v, step), minVal, maxVal)
            currentValue = clamped
            isInternal = true
            slider:SetValue(clamped)
            isInternal = false
            UpdateEditBoxText(clamped)
        end
    end

    frame._slider = slider
    frame._editBox = editBox
    frame._label = label
    frame.order = opts.order

    return frame
end
