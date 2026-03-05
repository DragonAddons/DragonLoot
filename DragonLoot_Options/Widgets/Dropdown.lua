-------------------------------------------------------------------------------
-- Dropdown.lua
-- Custom dropdown selector with scrollable list (no UIDropDownMenu)
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local PlaySound = PlaySound
local SOUNDKIT = SOUNDKIT
local table_sort = table.sort
local LibStub = LibStub

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 12
local LABEL_FONT_SIZE = 11
local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"
local WHITE_COLOR = { 1, 1, 1 }
local GRAY_COLOR = { 0.7, 0.7, 0.7 }
local DISABLED_COLOR = { 0.5, 0.5, 0.5 }

local BUTTON_WIDTH = 200
local BUTTON_HEIGHT = 24
local ITEM_HEIGHT = 20
local MAX_LIST_HEIGHT = 200
local FRAME_HEIGHT = 42

local BG_COLOR = { 0.1, 0.1, 0.1, 0.9 }
local BORDER_COLOR = { 0.4, 0.4, 0.4, 1 }
local LIST_BG_COLOR = { 0.08, 0.08, 0.08, 0.95 }
local HIGHLIGHT_COLOR = { 1, 1, 1, 0.08 }
local SELECTED_COLOR = { 1, 0.82, 0, 0.15 }

local PREVIEW_WIDTH = 40
local PREVIEW_HEIGHT = 14
local PREVIEW_INSET = 6
local PREVIEW_TINT = { 1, 0.82, 0, 0.9 }
local TEXT_OFFSET_WITH_PREVIEW = 52

-------------------------------------------------------------------------------
-- Module-level: track the currently open dropdown for mutual exclusion
-------------------------------------------------------------------------------

local activeDropdown = nil

-------------------------------------------------------------------------------
-- Close the currently open dropdown
-------------------------------------------------------------------------------

local function CloseActiveDropdown()
    if not activeDropdown then return end
    activeDropdown._listFrame:Hide()
    activeDropdown._overlay:Hide()
    activeDropdown = nil
end

-------------------------------------------------------------------------------
-- Resolve the values table (may be a function)
-------------------------------------------------------------------------------

local function ResolveValues(opts)
    local vals = opts.values
    if type(vals) == "function" then vals = vals() end
    if opts.sort then
        table_sort(vals, function(a, b) return (a.text or "") < (b.text or "") end)
    end
    return vals
end

-------------------------------------------------------------------------------
-- Find display text for a value key
-------------------------------------------------------------------------------

local function FindDisplayText(values, key)
    for _, entry in ipairs(values) do
        if entry.value == key then return entry.text end
    end
    return ""
end

-------------------------------------------------------------------------------
-- Apply texture preview to a button (statusbar, background, border)
-------------------------------------------------------------------------------

local function ApplyTexturePreview(btn, mediaType, value, lsm)
    if not btn._preview then
        btn._preview = btn:CreateTexture(nil, "ARTWORK")
        btn._preview:SetSize(PREVIEW_WIDTH, PREVIEW_HEIGHT)
        btn._preview:SetPoint("LEFT", btn, "LEFT", PREVIEW_INSET, 0)
        btn._preview:SetVertexColor(
            PREVIEW_TINT[1], PREVIEW_TINT[2], PREVIEW_TINT[3], PREVIEW_TINT[4]
        )
    end
    local texPath = lsm:Fetch(mediaType, value)
    if texPath then
        btn._preview:SetTexture(texPath)
        btn._preview:Show()
    else
        btn._preview:Hide()
    end
    btn._text:ClearAllPoints()
    btn._text:SetPoint("LEFT", btn, "LEFT", TEXT_OFFSET_WITH_PREVIEW, 0)
    btn._text:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
end

-------------------------------------------------------------------------------
-- Apply font preview to a button's text
-------------------------------------------------------------------------------

local function ApplyFontPreview(btn, value, lsm)
    local fontPath = lsm:Fetch("font", value)
    if fontPath then
        btn._text:SetFont(fontPath, FONT_SIZE, "")
    end
end

-------------------------------------------------------------------------------
-- Reset preview state on a recycled button
-------------------------------------------------------------------------------

local function ResetPreview(btn)
    if btn._preview then
        btn._preview:Hide()
    end
    btn._text:ClearAllPoints()
    btn._text:SetFont(FONT_PATH, FONT_SIZE, "")
    btn._text:SetPoint("LEFT", btn, "LEFT", 6, 0)
    btn._text:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
end

-------------------------------------------------------------------------------
-- Update the selected-value button preview
-------------------------------------------------------------------------------

local function UpdateSelectedPreview(dropdown, opts, value)
    local mediaType = opts.mediaType
    if not mediaType then
        if dropdown._selPreview then dropdown._selPreview:Hide() end
        dropdown._selectedText:ClearAllPoints()
        dropdown._selectedText:SetFont(FONT_PATH, FONT_SIZE, "")
        dropdown._selectedText:SetPoint("LEFT", dropdown._button, "LEFT", 6, 0)
        dropdown._selectedText:SetPoint("RIGHT", dropdown._button, "RIGHT", -20, 0)
        return
    end

    local lsm = LibStub("LibSharedMedia-3.0", true)
    if not lsm then return end

    if mediaType == "font" then
        local fontPath = lsm:Fetch("font", value)
        if fontPath then
            dropdown._selectedText:SetFont(fontPath, FONT_SIZE, "")
        end
        return
    end

    -- Texture preview for statusbar/background/border
    if not dropdown._selPreview then
        dropdown._selPreview = dropdown._button:CreateTexture(nil, "ARTWORK")
        dropdown._selPreview:SetSize(PREVIEW_WIDTH, PREVIEW_HEIGHT)
        dropdown._selPreview:SetPoint("LEFT", dropdown._button, "LEFT", PREVIEW_INSET, 0)
        dropdown._selPreview:SetVertexColor(
            PREVIEW_TINT[1], PREVIEW_TINT[2], PREVIEW_TINT[3], PREVIEW_TINT[4]
        )
    end
    local texPath = lsm:Fetch(mediaType, value)
    if texPath then
        dropdown._selPreview:SetTexture(texPath)
        dropdown._selPreview:Show()
    else
        dropdown._selPreview:Hide()
    end
    dropdown._selectedText:ClearAllPoints()
    dropdown._selectedText:SetPoint("LEFT", dropdown._button, "LEFT", TEXT_OFFSET_WITH_PREVIEW, 0)
    dropdown._selectedText:SetPoint("RIGHT", dropdown._button, "RIGHT", -20, 0)
end

-------------------------------------------------------------------------------
-- Build item buttons inside the list content frame
-------------------------------------------------------------------------------

local function BuildListItems(dropdown, opts)
    local listContent = dropdown._listContent
    local values = ResolveValues(opts)
    local mediaType = opts.mediaType
    local lsm = mediaType and LibStub("LibSharedMedia-3.0", true) or nil

    -- Recycle old buttons
    for _, btn in ipairs(dropdown._itemButtons) do
        btn:Hide()
        ResetPreview(btn)
    end

    local yOffset = 0
    for i, entry in ipairs(values) do
        local btn = dropdown._itemButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, listContent)
            btn:SetHeight(ITEM_HEIGHT)

            local text = btn:CreateFontString(nil, "OVERLAY")
            text:SetFont(FONT_PATH, FONT_SIZE, "")
            text:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
            text:SetPoint("LEFT", btn, "LEFT", 6, 0)
            text:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
            text:SetJustifyH("LEFT")
            btn._text = text

            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(
                HIGHLIGHT_COLOR[1], HIGHLIGHT_COLOR[2], HIGHLIGHT_COLOR[3], HIGHLIGHT_COLOR[4]
            )

            btn._selected = btn:CreateTexture(nil, "BACKGROUND")
            btn._selected:SetAllPoints()
            btn._selected:SetColorTexture(
                SELECTED_COLOR[1], SELECTED_COLOR[2], SELECTED_COLOR[3], SELECTED_COLOR[4]
            )
            btn._selected:Hide()

            dropdown._itemButtons[i] = btn
        end

        btn._text:SetText(entry.text or "")
        btn._entryValue = entry.value

        -- Highlight current selection
        local current = opts.get and opts.get() or nil
        btn._selected:SetShown(entry.value == current)

        -- Apply media preview
        if lsm and mediaType ~= "font" then
            ApplyTexturePreview(btn, mediaType, entry.value, lsm)
        elseif lsm and mediaType == "font" then
            ApplyFontPreview(btn, entry.value, lsm)
        end

        btn:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, -yOffset)
        btn:SetPoint("TOPRIGHT", listContent, "TOPRIGHT", 0, -yOffset)
        btn:Show()

        btn:SetScript("OnClick", function()
            if opts.set then opts.set(entry.value) end
            dropdown._selectedText:SetText(entry.text or "")
            UpdateSelectedPreview(dropdown, opts, entry.value)
            if PlaySound and SOUNDKIT then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
            CloseActiveDropdown()
        end)

        yOffset = yOffset + ITEM_HEIGHT
    end

    listContent:SetHeight(math.max(1, yOffset))
end

-------------------------------------------------------------------------------
-- Toggle the dropdown list open/closed
-------------------------------------------------------------------------------

local function ToggleList(dropdown, opts)
    if activeDropdown == dropdown then
        CloseActiveDropdown()
        return
    end

    -- Close any other open dropdown first
    CloseActiveDropdown()

    BuildListItems(dropdown, opts)

    local listFrame = dropdown._listFrame
    local contentHeight = dropdown._listContent:GetHeight()
    local listHeight = math.min(contentHeight, MAX_LIST_HEIGHT)
    listFrame:SetHeight(listHeight + 2)
    listFrame:Show()
    dropdown._overlay:Show()
    activeDropdown = dropdown
end

-------------------------------------------------------------------------------
-- Create the fullscreen overlay for outside-click closing
-------------------------------------------------------------------------------

local function CreateOverlay(_dropdown)
    local overlay = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    overlay:SetAllPoints(UIParent)
    overlay:SetFrameStrata("FULLSCREEN")
    overlay:SetFrameLevel(199)
    overlay:EnableMouse(true)
    overlay:Hide()
    overlay:SetScript("OnClick", CloseActiveDropdown)
    return overlay
end

-------------------------------------------------------------------------------
-- Create the dropdown list frame with optional scroll
-------------------------------------------------------------------------------

local function CreateListFrame(dropdown)
    local listFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    listFrame:SetPoint("TOPLEFT", dropdown._button, "BOTTOMLEFT", 0, -1)
    listFrame:SetPoint("TOPRIGHT", dropdown._button, "BOTTOMRIGHT", 0, -1)
    listFrame:SetFrameStrata("FULLSCREEN")
    listFrame:SetFrameLevel(200)
    listFrame:SetBackdrop({ bgFile = WHITE8x8, edgeFile = WHITE8x8, edgeSize = 1 })
    listFrame:SetBackdropColor(LIST_BG_COLOR[1], LIST_BG_COLOR[2], LIST_BG_COLOR[3], LIST_BG_COLOR[4])
    listFrame:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
    listFrame:Hide()

    -- Scroll frame for the list
    local scrollWrapper = ns.Widgets.CreateScrollFrame(listFrame)
    scrollWrapper:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 1, -1)
    scrollWrapper:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -1, 1)

    dropdown._listContent = scrollWrapper.scrollChild
    return listFrame
end

-------------------------------------------------------------------------------
-- Factory: CreateDropdown
-------------------------------------------------------------------------------

function ns.Widgets.CreateDropdown(parent, opts)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(FRAME_HEIGHT)

    local disabled = false

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_PATH, LABEL_FONT_SIZE, "")
    label:SetTextColor(GRAY_COLOR[1], GRAY_COLOR[2], GRAY_COLOR[3])
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetText(opts.label or "")

    -- Main button
    local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
    button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -16)
    button:SetBackdrop({ bgFile = WHITE8x8, edgeFile = WHITE8x8, edgeSize = 1 })
    button:SetBackdropColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], BG_COLOR[4])
    button:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
    frame._button = button

    -- Selected text
    local selectedText = button:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(FONT_PATH, FONT_SIZE, "")
    selectedText:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
    selectedText:SetPoint("LEFT", button, "LEFT", 6, 0)
    selectedText:SetPoint("RIGHT", button, "RIGHT", -20, 0)
    selectedText:SetJustifyH("LEFT")
    frame._selectedText = selectedText

    -- Arrow indicator
    local arrow = button:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(FONT_PATH, FONT_SIZE, "")
    arrow:SetTextColor(GRAY_COLOR[1], GRAY_COLOR[2], GRAY_COLOR[3])
    arrow:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    arrow:SetText("v")

    -- Overlay for outside-click closing
    frame._overlay = CreateOverlay(frame)

    -- Item button pool
    frame._itemButtons = {}

    -- List frame
    frame._listFrame = CreateListFrame(frame)

    -- When the dropdown hides (e.g. parent scroll frame hides), clean up orphaned UIParent children
    frame:SetScript("OnHide", function()
        if activeDropdown == frame then
            CloseActiveDropdown()
        else
            frame._listFrame:Hide()
            frame._overlay:Hide()
        end
    end)

    -- Click toggles dropdown
    button:SetScript("OnClick", function()
        if disabled then return end
        ToggleList(frame, opts)
    end)

    -- Initialize selected text
    local initValues = ResolveValues(opts)
    local initKey = opts.get and opts.get() or nil
    selectedText:SetText(FindDisplayText(initValues, initKey))
    UpdateSelectedPreview(frame, opts, initKey)

    -- Public API
    function frame:GetValue()
        return opts.get and opts.get() or nil
    end

    function frame:SetValue(v)
        if opts.set then opts.set(v) end
        local vals = ResolveValues(opts)
        selectedText:SetText(FindDisplayText(vals, v))
        UpdateSelectedPreview(frame, opts, v)
    end

    function frame:SetDisabled(state)
        disabled = state
        if disabled then
            label:SetTextColor(DISABLED_COLOR[1], DISABLED_COLOR[2], DISABLED_COLOR[3])
            selectedText:SetTextColor(DISABLED_COLOR[1], DISABLED_COLOR[2], DISABLED_COLOR[3])
            arrow:SetTextColor(DISABLED_COLOR[1], DISABLED_COLOR[2], DISABLED_COLOR[3])
            button:SetAlpha(0.5)
            CloseActiveDropdown()
        else
            label:SetTextColor(GRAY_COLOR[1], GRAY_COLOR[2], GRAY_COLOR[3])
            selectedText:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
            arrow:SetTextColor(GRAY_COLOR[1], GRAY_COLOR[2], GRAY_COLOR[3])
            button:SetAlpha(1)
        end
    end

    function frame:Refresh()
        local vals = ResolveValues(opts)
        local key = opts.get and opts.get() or nil
        selectedText:SetText(FindDisplayText(vals, key))
        UpdateSelectedPreview(frame, opts, key)
    end

    frame._label = label
    frame.order = opts.order

    return frame
end
