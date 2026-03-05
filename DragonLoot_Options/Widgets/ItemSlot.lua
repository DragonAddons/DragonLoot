-------------------------------------------------------------------------------
-- ItemSlot.lua
-- Drag-and-drop item slot with quality border and tooltip
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local GetCursorInfo = GetCursorInfo
local ClearCursor = ClearCursor
local GetItemInfo = GetItemInfo
local C_Timer = C_Timer
local GameTooltip = GameTooltip

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local DEFAULT_SIZE = 36
local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"
local EMPTY_ICON = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
local EMPTY_BORDER_COLOR = { 0.4, 0.4, 0.4, 1 }
local MAX_RETRIES = 3
local RETRY_DELAY = 0.5

-------------------------------------------------------------------------------
-- Update the border color based on item quality
-------------------------------------------------------------------------------

local function UpdateSlotBorder(slot, quality)
    local dlns = ns.dlns
    if quality and dlns and dlns.QUALITY_COLORS and dlns.QUALITY_COLORS[quality] then
        local qc = dlns.QUALITY_COLORS[quality]
        slot._border:SetBackdropBorderColor(qc.r, qc.g, qc.b, 1)
    else
        slot._border:SetBackdropBorderColor(
            EMPTY_BORDER_COLOR[1], EMPTY_BORDER_COLOR[2],
            EMPTY_BORDER_COLOR[3], EMPTY_BORDER_COLOR[4]
        )
    end
end

-------------------------------------------------------------------------------
-- Query item info with retry on nil
-------------------------------------------------------------------------------

local function QueryItemInfo(slot, itemID, attempt)
    attempt = attempt or 1
    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
    if itemName and itemTexture then
        slot._icon:SetTexture(itemTexture)
        slot._icon:Show()
        slot._itemQuality = itemQuality
        UpdateSlotBorder(slot, itemQuality)
        return
    end
    if attempt < MAX_RETRIES then
        C_Timer.After(RETRY_DELAY, function()
            QueryItemInfo(slot, itemID, attempt + 1)
        end)
    end
end

-------------------------------------------------------------------------------
-- Handle cursor drop onto the slot
-------------------------------------------------------------------------------

local function HandleDrop(slot, opts)
    local infoType, itemID = GetCursorInfo()
    if infoType ~= "item" or not itemID then return end
    ClearCursor()
    slot:SetItem(itemID)
    if opts.onAccept then opts.onAccept(itemID) end
end

-------------------------------------------------------------------------------
-- Tooltip handlers
-------------------------------------------------------------------------------

local function OnEnterSlot(slot)
    if not slot._itemID then return end
    if slot._opts and slot._opts.showTooltip == false then return end
    GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(slot._itemID)
    GameTooltip:Show()
end

local function OnLeaveSlot()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- Factory: CreateItemSlot
-------------------------------------------------------------------------------

function ns.Widgets.CreateItemSlot(parent, opts)
    local size = opts.size or DEFAULT_SIZE

    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(size, size)
    frame._opts = opts
    frame._itemID = nil
    frame._itemQuality = nil

    -- Border frame
    frame._border = frame
    frame:SetBackdrop({ bgFile = WHITE8x8, edgeFile = WHITE8x8, edgeSize = 1 })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    frame:SetBackdropBorderColor(
        EMPTY_BORDER_COLOR[1], EMPTY_BORDER_COLOR[2],
        EMPTY_BORDER_COLOR[3], EMPTY_BORDER_COLOR[4]
    )

    -- Icon texture (inset 1px for border)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    icon:SetTexture(EMPTY_ICON)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame._icon = icon

    -- Enable drag-and-drop receive
    frame:EnableMouse(true)
    frame:SetScript("OnReceiveDrag", function(self)
        HandleDrop(self, opts)
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            HandleDrop(self, opts)
        elseif button == "RightButton" and self._itemID then
            local removedID = self._itemID
            self:ClearItem()
            if opts.onRemove then opts.onRemove(removedID) end
        end
    end)

    -- Tooltip
    frame:SetScript("OnEnter", OnEnterSlot)
    frame:SetScript("OnLeave", OnLeaveSlot)

    -- Public API: SetItem
    function frame:SetItem(itemID)
        if not itemID then
            self:ClearItem()
            return
        end
        self._itemID = itemID
        QueryItemInfo(self, itemID)
    end

    -- Public API: GetItem
    function frame:GetItem()
        return self._itemID
    end

    -- Public API: ClearItem
    function frame:ClearItem()
        self._itemID = nil
        self._itemQuality = nil
        self._icon:SetTexture(EMPTY_ICON)
        self._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        UpdateSlotBorder(self, nil)
    end

    -- Public API: GetValue / SetValue / SetDisabled / Refresh for consistency
    function frame:GetValue()
        return self._itemID
    end

    function frame:SetValue(v)
        if v then
            self:SetItem(v)
        else
            self:ClearItem()
        end
    end

    function frame:SetDisabled(state)
        if state then
            self:SetAlpha(0.5)
            self:EnableMouse(false)
        else
            self:SetAlpha(1)
            self:EnableMouse(true)
        end
    end

    function frame:Refresh()
        if self._itemID then
            QueryItemInfo(self, self._itemID)
        end
    end

    return frame
end
