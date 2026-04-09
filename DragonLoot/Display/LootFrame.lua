-------------------------------------------------------------------------------
-- LootFrame.lua
-- Replacement loot window that intercepts LOOT_OPENED and displays items
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local UIParent = UIParent
local GetNumLootItems = GetNumLootItems
local GetLootSlotInfo = GetLootSlotInfo
local GetLootSlotType = GetLootSlotType
local LootSlot = LootSlot
local CloseLoot = CloseLoot
local IsFishingLoot = IsFishingLoot
local UNKNOWN = UNKNOWN
local GetLootSlotLink = GetLootSlotLink
local CreateColor = CreateColor
local GetCursorPosition = GetCursorPosition

local L = ns.L
local DU = ns.DisplayUtils

-------------------------------------------------------------------------------
-- Version detection
-------------------------------------------------------------------------------

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

-------------------------------------------------------------------------------
-- Slot type constants (from GetLootSlotType)
-------------------------------------------------------------------------------

local LOOT_SLOT_ITEM = 1
local LOOT_SLOT_MONEY = 2
local LOOT_SLOT_CURRENCY = 3

local BIND_LABELS = {
    [1] = L["BoP"],
    [2] = L["BoE"],
    [3] = L["BoU"],
    [4] = L["Quest"],
}

-------------------------------------------------------------------------------
-- Layout constants
-------------------------------------------------------------------------------

local TITLE_BAR_HEIGHT = 24
local MIN_QUALITY_RARE = 3
local ICON_GLOW_PADDING = 25
local SLOT_ICON_LEFT_INSET = 4 -- icon frame left offset from slot LEFT edge
local ICON_BORDER_INSET = 2 -- icon border bleed beyond icon frame edge (each side)
local SLOT_TEXT_LEFT_GAP = 6 -- gap between icon right edge and item name left
local SLOT_TEXT_TOP_OFFSET = 2 -- item name top inset below icon frame top
local SLOT_SUBTEXT_GAP = 1 -- vertical gap between item name bottom and sub-text top
local SLOT_TEXT_RIGHT_INSET = 4 -- text right offset from slot RIGHT edge
local SLOT_QUANTITY_OFFSET = 2 -- quantity badge bleed beyond icon frame corner

local function GetSlotSpacing()
    return ns.Addon.db.profile.lootWindow.slotSpacing or 2
end

local function GetContentPadding()
    return ns.Addon.db.profile.lootWindow.contentPadding or 4
end

-------------------------------------------------------------------------------
-- Slot frame pool
-------------------------------------------------------------------------------

local slotPool = {}
local slotCount = 0
local activeSlots = {}

-------------------------------------------------------------------------------
-- Container frame reference
-------------------------------------------------------------------------------

local containerFrame

-------------------------------------------------------------------------------
-- Normalize GetLootSlotInfo returns across versions
--
-- Retail: icon, name, quantity, currencyID, quality, locked, isQuestItem,
--         questID, isActive, isCoin (10 returns)
-- Classic: icon, name, quantity, currencyID, quality, locked (6 returns)
-- Both versions return currencyID at position 4; strip it for a normalized
-- return of: icon, name, quantity, quality, locked, isQuestItem
-------------------------------------------------------------------------------

local function GetNormalizedSlotInfo(slotIndex)
    if isRetail then
        local icon, name, quantity, _, quality, locked, isQuestItem = GetLootSlotInfo(slotIndex)
        return icon, name, quantity, quality, locked, isQuestItem
    end
    -- Classic/TBC/MoP: 6 returns with currencyID at position 4, no isQuestItem
    local icon, name, quantity, _, quality, locked = GetLootSlotInfo(slotIndex)
    return icon, name, quantity, quality, locked, nil
end

-------------------------------------------------------------------------------
-- Item detail helpers
-------------------------------------------------------------------------------

local function GetItemDetails(slotIndex)
    local lootType = GetLootSlotType(slotIndex)
    if lootType ~= LOOT_SLOT_ITEM then
        return nil, nil, nil
    end

    local itemLink = GetLootSlotLink(slotIndex)
    if not itemLink then
        return nil, nil, nil
    end

    local _, _, _, itemLevel, _, _, itemSubType, _, _, _, _, _, _, bindType = C_Item.GetItemInfo(itemLink)

    local bindText = bindType and BIND_LABELS[bindType] or nil
    return itemLevel, bindText, itemSubType
end

local function ApplySlotBackground(slot, quality)
    local style = ns.Addon.db.profile.appearance.slotBackground or "gradient"

    -- Only show quality-tinted backgrounds for Rare+ items (quality >= 3)
    if not quality or quality < MIN_QUALITY_RARE or style == "none" then
        slot.rowBg:Hide()
        slot.accentStripe:Hide()
        return
    end

    local r, g, b = DU.GetQualityColor(quality)

    if style == "gradient" then
        slot.rowBg:SetColorTexture(1, 1, 1)
        slot.rowBg:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0.4), CreateColor(r, g, b, 0.1))
        slot.rowBg:Show()
        slot.accentStripe:Hide()
    elseif style == "flat" then
        slot.rowBg:SetColorTexture(r, g, b, 0.08)
        slot.rowBg:Show()
        slot.accentStripe:Hide()
    elseif style == "stripe" then
        slot.rowBg:Hide()
        slot.accentStripe:SetColorTexture(r, g, b, 0.6)
        slot.accentStripe:Show()
    end
end

local function BuildSubText(slotIndex, lootType)
    if lootType == LOOT_SLOT_CURRENCY then
        return L["Currency"]
    elseif lootType == LOOT_SLOT_MONEY then
        return L["Money"]
    elseif lootType == LOOT_SLOT_ITEM then
        local itemLevel, bindText, itemSubType = GetItemDetails(slotIndex)
        local parts = {}
        if itemLevel and itemLevel > 0 then
            parts[#parts + 1] = L["iLvl"] .. " " .. itemLevel
        end
        if bindText then
            parts[#parts + 1] = bindText
        end
        if itemSubType then
            parts[#parts + 1] = itemSubType
        end
        if #parts > 0 then
            return table.concat(parts, "  \194\183  ")
        end
    end
    return nil
end

-------------------------------------------------------------------------------
-- Backdrop and font wrappers (delegate to DisplayUtils)
-------------------------------------------------------------------------------

local function GetFont()
    return DU.GetFont(ns.Addon.db)
end

local function ApplyBackdrop(frame)
    DU.ApplyBackdrop(frame, ns.Addon.db)
end

local function ApplyLayoutOffsets(frame)
    local borderSize = ns.Addon.db.profile.appearance.borderSize or 1

    -- Title text
    frame.title:ClearAllPoints()
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 8 + borderSize, -(6 + borderSize))

    -- Close button
    frame.closeBtn:ClearAllPoints()
    frame.closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -borderSize, -borderSize)

    -- Fishing hint text
    frame.fishingText:ClearAllPoints()
    frame.fishingText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8 + borderSize, 4 + borderSize)

    -- Title separator
    if frame.titleSeparator then
        frame.titleSeparator:ClearAllPoints()
        frame.titleSeparator:SetPoint("TOPLEFT", frame, "TOPLEFT", 6 + borderSize, -(TITLE_BAR_HEIGHT + borderSize))
        frame.titleSeparator:SetPoint(
            "TOPRIGHT",
            frame,
            "TOPRIGHT",
            -(6 + borderSize),
            -(TITLE_BAR_HEIGHT + borderSize)
        )
    end
end

-------------------------------------------------------------------------------
-- Position persistence
-------------------------------------------------------------------------------

local function SaveFramePosition()
    if not containerFrame then
        return
    end
    local db = ns.Addon.db.profile.lootWindow
    local point, _, relativePoint, x, y = containerFrame:GetPoint()
    if point then
        db.point = point
        db.relativePoint = relativePoint
        db.x = x
        db.y = y
    end
end

local function RestoreFramePosition()
    if not containerFrame then
        return
    end
    local db = ns.Addon.db.profile.lootWindow
    containerFrame:ClearAllPoints()
    if db.point then
        containerFrame:SetPoint(db.point, UIParent, db.relativePoint, db.x or 0, db.y or 0)
    else
        containerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

local function PositionAtCursor()
    if not containerFrame then
        return
    end
    local x, y = GetCursorPosition()
    local scale = containerFrame:GetEffectiveScale()
    containerFrame:ClearAllPoints()
    containerFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

-------------------------------------------------------------------------------
-- Named slot interaction scripts (reusable / restorable after test mode)
-------------------------------------------------------------------------------

local function OnSlotClick(self)
    if self.slotIndex then
        LootSlot(self.slotIndex)
    end
end

local function OnSlotEnter(self)
    -- Tooltip
    if self.slotIndex then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetLootItem(self.slotIndex)
        GameTooltip:Show()
    end

    -- Visual hover effects
    local r = self._qr or 1
    local g = self._qg or 1
    local b = self._qb or 1

    -- Brighten icon border
    if self.iconBorder:IsShown() then
        self.iconBorder:SetColorTexture(r, g, b, 1.0)
    end

    -- Intensify icon glow
    if self.iconGlow:IsShown() then
        self.iconGlow:SetAlpha(0.9)
    end

    -- Brighten item name
    self.itemName:SetTextColor(math.min(r + 0.15, 1), math.min(g + 0.15, 1), math.min(b + 0.15, 1))
end

local function OnSlotLeave(self)
    GameTooltip:Hide()

    -- Restore visual state
    local r = self._qr or 1
    local g = self._qg or 1
    local b = self._qb or 1

    -- Restore icon border alpha
    if self.iconBorder:IsShown() then
        self.iconBorder:SetColorTexture(r, g, b, 0.8)
    end

    -- Restore glow alpha
    if self.iconGlow:IsShown() then
        self.iconGlow:SetAlpha(0.6)
    end

    -- Restore item name color
    self.itemName:SetTextColor(r, g, b)
end

local function OnSlotUpdateTooltip(self)
    if self.slotIndex then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetLootItem(self.slotIndex)
        GameTooltip:Show()
    end
end

-------------------------------------------------------------------------------
-- Slot frame creation
-------------------------------------------------------------------------------

local function CreateSlotFrame()
    slotCount = slotCount + 1
    local frameName = "DragonLootSlot" .. slotCount

    local slot = CreateFrame("Button", frameName, containerFrame)
    slot:SetHeight(44)
    slot:EnableMouse(true)
    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Row background (quality-tinted, configurable style)
    slot.rowBg = slot:CreateTexture(nil, "BACKGROUND")
    slot.rowBg:SetAllPoints()
    slot.rowBg:Hide()

    -- Accent stripe (left edge, for "stripe" mode)
    slot.accentStripe = slot:CreateTexture(nil, "BACKGROUND", nil, 1)
    slot.accentStripe:SetWidth(3)
    slot.accentStripe:SetPoint("TOPLEFT", slot, "TOPLEFT", 0, 0)
    slot.accentStripe:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 0, 0)
    slot.accentStripe:Hide()

    -- Icon container (child frame renders above parent's HIGHLIGHT layer)
    slot.iconFrame = CreateFrame("Frame", nil, slot)
    slot.iconFrame:SetSize(36, 36)
    slot.iconFrame:SetPoint("LEFT", slot, "LEFT", SLOT_ICON_LEFT_INSET, 0)
    slot.iconFrame:SetFrameLevel(slot:GetFrameLevel() + 2)
    slot.iconFrame:EnableMouse(false)

    -- Icon glow (on parent slot, behind iconFrame, ADD blend for visible halo)
    slot.iconGlow = slot:CreateTexture(nil, "ARTWORK", nil, 0)
    slot.iconGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    slot.iconGlow:SetBlendMode("ADD")
    slot.iconGlow:SetAlpha(0.6)
    slot.iconGlow:Hide()

    -- Icon border (quality-colored frame, draws UNDER icon via sublevel)
    slot.iconBorder = slot.iconFrame:CreateTexture(nil, "ARTWORK")
    slot.iconBorder:SetDrawLayer("ARTWORK", 0)
    slot.iconBorder:SetPoint("TOPLEFT", slot.iconFrame, "TOPLEFT", -ICON_BORDER_INSET, ICON_BORDER_INSET)
    slot.iconBorder:SetPoint("BOTTOMRIGHT", slot.iconFrame, "BOTTOMRIGHT", ICON_BORDER_INSET, -ICON_BORDER_INSET)
    slot.iconBorder:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    -- Icon (draws ON TOP of border at sublevel 1)
    slot.icon = slot.iconFrame:CreateTexture(nil, "ARTWORK")
    slot.icon:SetDrawLayer("ARTWORK", 1)
    slot.icon:SetAllPoints(slot.iconFrame)
    slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Quantity badge
    slot.quantity = slot.iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    slot.quantity:SetPoint("BOTTOMRIGHT", slot.iconFrame, "BOTTOMRIGHT", SLOT_QUANTITY_OFFSET, -SLOT_QUANTITY_OFFSET)
    slot.quantity:SetJustifyH("RIGHT")
    slot.quantity:SetTextColor(1, 1, 1)

    -- Item name (top-aligned to leave room for sub-text)
    slot.itemName = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slot.itemName:SetPoint("TOPLEFT", slot.iconFrame, "TOPRIGHT", SLOT_TEXT_LEFT_GAP, -SLOT_TEXT_TOP_OFFSET)
    slot.itemName:SetPoint("RIGHT", slot, "RIGHT", -SLOT_TEXT_RIGHT_INSET, 0)
    slot.itemName:SetJustifyH("LEFT")
    slot.itemName:SetWordWrap(false)

    -- Sub-text (iLvl, bind type, item type / or Currency / Money)
    slot.subText = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slot.subText:SetPoint("TOPLEFT", slot.itemName, "BOTTOMLEFT", 0, -SLOT_SUBTEXT_GAP)
    slot.subText:SetPoint("RIGHT", slot, "RIGHT", -SLOT_TEXT_RIGHT_INSET, 0)
    slot.subText:SetJustifyH("LEFT")
    slot.subText:SetWordWrap(false)
    slot.subText:SetTextColor(0.6, 0.6, 0.6)

    -- Hover highlight (auto-shows on mouse enter via HIGHLIGHT layer)
    slot.highlight = slot:CreateTexture(nil, "HIGHLIGHT")
    slot.highlight:SetAllPoints()
    slot.highlight:SetColorTexture(1, 1, 1, 0.15)

    -- Interaction scripts
    slot:SetScript("OnClick", OnSlotClick)
    slot:SetScript("OnEnter", OnSlotEnter)
    slot:SetScript("OnLeave", OnSlotLeave)
    slot:SetScript("UpdateTooltip", OnSlotUpdateTooltip)

    return slot
end

-------------------------------------------------------------------------------
-- Slot pool management
-------------------------------------------------------------------------------

local function AcquireSlot()
    local slot = table.remove(slotPool)
    if not slot then
        slot = CreateSlotFrame()
    end
    slot._isPooled = false
    return slot
end

local function ReleaseSlot(slot)
    if slot._isPooled then
        return
    end
    slot._isPooled = true

    slot.iconBorder:Hide()
    slot.iconGlow:Hide()
    slot.rowBg:Hide()
    slot.accentStripe:Hide()
    slot:Hide()
    slot:ClearAllPoints()
    slot.slotIndex = nil
    slot.icon:SetTexture(nil)
    slot.icon:SetDesaturated(false)
    slot.icon:SetVertexColor(1, 1, 1)
    slot.icon:SetAlpha(1)
    slot.itemName:SetText("")
    slot.quantity:Hide()
    slot.subText:SetText("")
    slot.subText:Hide()
    slot.highlight:SetColorTexture(1, 1, 1, 0.15)
    slot._qr, slot._qg, slot._qb = nil, nil, nil
    slot._quality = nil

    -- Restore real interaction scripts (test mode may have overridden them)
    slot:SetScript("OnClick", OnSlotClick)
    slot:SetScript("OnEnter", OnSlotEnter)
    slot:SetScript("OnLeave", OnSlotLeave)
    slot:SetScript("UpdateTooltip", OnSlotUpdateTooltip)

    table.insert(slotPool, slot)
end

local function ReleaseAllSlots()
    for i = #activeSlots, 1, -1 do
        ReleaseSlot(activeSlots[i])
        activeSlots[i] = nil
    end
end

-------------------------------------------------------------------------------
-- Boundary parsing: normalize loot data into a SlotData table
--
-- SlotData = {
--     icon,          -- texture path/ID
--     name,          -- item name string
--     quantity,      -- stack count
--     quality,       -- quality enum (0-7)
--     isQuestItem,   -- boolean
--     slotType,      -- number (loot slot type)
--     subText,       -- formatted sub-text string
--     locked,        -- boolean
-- }
-------------------------------------------------------------------------------

local function BuildSlotData(slotIndex)
    local icon, name, quantity, quality, locked, isQuestItem = GetNormalizedSlotInfo(slotIndex)
    if not icon then
        return nil
    end

    local lootType = GetLootSlotType(slotIndex)
    local subText = BuildSubText(slotIndex, lootType)

    return {
        icon = icon,
        name = name or UNKNOWN,
        quantity = quantity,
        quality = quality,
        isQuestItem = isQuestItem or false,
        slotType = lootType,
        subText = subText,
        locked = locked or false,
    }
end

local function BuildTestSlotData(testItem, _)
    local subText
    if testItem.slotType == LOOT_SLOT_CURRENCY then
        subText = L["Currency"]
    elseif testItem.slotType == LOOT_SLOT_MONEY then
        subText = L["Money"]
    elseif testItem.slotType == LOOT_SLOT_ITEM then
        local parts = {}
        if testItem.itemLevel and testItem.itemLevel > 0 then
            parts[#parts + 1] = L["iLvl"] .. " " .. testItem.itemLevel
        end
        local bindText = testItem.bindType and BIND_LABELS[testItem.bindType] or nil
        if bindText then
            parts[#parts + 1] = bindText
        end
        if testItem.itemSubType then
            parts[#parts + 1] = testItem.itemSubType
        end
        if #parts > 0 then
            subText = table.concat(parts, "  \194\183  ")
        end
    end

    return {
        icon = testItem.icon,
        name = testItem.name,
        quantity = testItem.quantity,
        quality = testItem.quality,
        isQuestItem = testItem.isQuestItem or false,
        slotType = testItem.slotType,
        subText = subText,
        locked = false,
    }
end

-------------------------------------------------------------------------------
-- Unified slot rendering (visual output identical for real and test data)
-------------------------------------------------------------------------------

local function RenderSlot(slot, data, isTest)
    local db = ns.Addon.db.profile
    local iconSize = db.appearance.lootIconSize or 36
    local fontPath, fontSize, fontOutline = GetFont()

    -- Icon
    slot.icon:SetTexture(data.icon)
    slot.iconFrame:SetSize(iconSize, iconSize)
    slot.icon:SetDesaturated(false)
    slot.icon:SetVertexColor(1, 1, 1)
    slot.icon:SetAlpha(1)

    -- Quality color
    local r, g, b = DU.GetQualityColor(data.quality)
    slot._qr, slot._qg, slot._qb = r, g, b
    slot._quality = data.quality

    -- Quality border
    if db.appearance.qualityBorder then
        slot.iconBorder:SetColorTexture(r, g, b, 0.8)
        slot.iconBorder:Show()
    else
        slot.iconBorder:Hide()
    end

    -- Quest item override for border
    if data.isQuestItem then
        slot.iconBorder:SetColorTexture(1, 0.82, 0, 0.9)
        slot.iconBorder:Show()
    end

    -- Icon glow for Rare+ items (quality >= 3)
    if data.quality and data.quality >= MIN_QUALITY_RARE then
        slot.iconGlow:SetVertexColor(r, g, b, 0.6)
        slot.iconGlow:SetSize(iconSize + ICON_GLOW_PADDING, iconSize + ICON_GLOW_PADDING)
        slot.iconGlow:ClearAllPoints()
        slot.iconGlow:SetPoint("CENTER", slot.iconFrame, "CENTER", 0, 0)
        slot.iconGlow:Show()
    else
        slot.iconGlow:Hide()
    end

    -- Item name
    slot.itemName:SetFont(fontPath, fontSize, fontOutline)
    DU.ApplyFontShadow(slot.itemName, ns.Addon.db)
    slot.itemName:SetText(data.name)
    slot.itemName:SetTextColor(r, g, b)

    -- Quantity badge
    if data.quantity and data.quantity > 1 then
        slot.quantity:SetText(data.quantity)
        slot.quantity:Show()
    else
        slot.quantity:Hide()
    end

    -- Sub-text (item details or slot type)
    if data.subText then
        local subFontSize = math.max(fontSize - 2, 8)
        slot.subText:SetFont(fontPath, subFontSize, fontOutline)
        DU.ApplyFontShadow(slot.subText, ns.Addon.db)
        slot.subText:SetText(data.subText)
        slot.subText:SetTextColor(0.6, 0.6, 0.6)
        slot.subText:Show()
    else
        slot.subText:Hide()
    end

    -- Row background (quality-tinted, configurable)
    ApplySlotBackground(slot, data.quality)

    -- Quality-tinted hover highlight
    slot.highlight:SetColorTexture(r, g, b, 0.15)

    -- Slot height
    slot:SetHeight(iconSize + 8)

    -- Interaction scripts differ by mode
    if isTest then
        slot:SetScript("OnClick", function()
            ns.Print(L["Test slot clicked: "] .. data.name)
        end)
        slot:SetScript("OnEnter", function(self)
            -- Tooltip
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(data.name, r, g, b)
            if data.subText then
                GameTooltip:AddLine(data.subText, 0.6, 0.6, 0.6)
            end
            GameTooltip:Show()

            -- Visual hover effects
            if self.iconBorder:IsShown() then
                self.iconBorder:SetColorTexture(r, g, b, 1.0)
            end
            if self.iconGlow:IsShown() then
                self.iconGlow:SetAlpha(0.9)
            end
            self.itemName:SetTextColor(math.min(r + 0.15, 1), math.min(g + 0.15, 1), math.min(b + 0.15, 1))
        end)
        slot:SetScript("OnLeave", function(self)
            GameTooltip:Hide()

            -- Restore visual state
            if self.iconBorder:IsShown() then
                self.iconBorder:SetColorTexture(r, g, b, 0.8)
            end
            if self.iconGlow:IsShown() then
                self.iconGlow:SetAlpha(0.6)
            end
            self.itemName:SetTextColor(r, g, b)
        end)
    else
        slot:SetScript("OnClick", OnSlotClick)
        slot:SetScript("OnEnter", OnSlotEnter)
        slot:SetScript("OnLeave", OnSlotLeave)
        slot:SetScript("UpdateTooltip", OnSlotUpdateTooltip)
    end

    slot:Show()
end

-------------------------------------------------------------------------------
-- Populate a single slot with loot data
-------------------------------------------------------------------------------

local function PopulateSlot(slot, slotIndex)
    local data = BuildSlotData(slotIndex)
    if not data then
        slot:Hide()
        return
    end
    RenderSlot(slot, data, false)
    slot.slotIndex = slotIndex
end

-------------------------------------------------------------------------------
-- Title bar close button creation
-------------------------------------------------------------------------------

local function CreateCloseButton(parent)
    local ok, btn = pcall(CreateFrame, "Button", nil, parent, "UIPanelCloseButtonNoScripts")
    if not ok or not btn then
        btn = CreateFrame("Button", nil, parent)
        btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    end
    btn:SetSize(24, 24)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    btn:SetScript("OnClick", function()
        CloseLoot()
        ns.LootFrame.Hide()
    end)

    return btn
end

-------------------------------------------------------------------------------
-- Container frame creation
-------------------------------------------------------------------------------

local function CreateContainerFrame()
    local frame = CreateFrame("Frame", "DragonLootFrame", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    frame:SetClampedToScreen(true)
    frame:Hide()

    -- Backdrop
    ApplyBackdrop(frame)

    -- Title text
    local fontPath, fontSize, fontOutline = GetFont()
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
    frame.title:SetFont(fontPath, fontSize, fontOutline)
    DU.ApplyFontShadow(frame.title, ns.Addon.db)
    frame.title:SetText(L["Loot"])
    frame.title:SetTextColor(1, 0.82, 0)

    -- Close button
    frame.closeBtn = CreateCloseButton(frame)

    -- Dragging
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        local db = ns.Addon.db.profile.lootWindow
        if not db.lock then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveFramePosition()
    end)

    -- Fishing hint
    frame.fishingText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.fishingText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 4)
    frame.fishingText:SetTextColor(0.5, 0.5, 0.5)
    frame.fishingText:Hide()

    -- Title separator
    frame.titleSeparator = frame:CreateTexture(nil, "ARTWORK")
    frame.titleSeparator:SetHeight(1)
    frame.titleSeparator:SetColorTexture(0.6, 0.5, 0.2, 0.4)

    -- Offset child elements to account for border thickness
    ApplyLayoutOffsets(frame)

    return frame
end

-------------------------------------------------------------------------------
-- Layout slots inside container
-------------------------------------------------------------------------------

local function LayoutSlots()
    if not containerFrame then
        return
    end
    local db = ns.Addon.db.profile
    local iconSize = db.appearance.lootIconSize or 36
    local borderSize = db.appearance.borderSize or 1
    local padding = GetContentPadding()
    local slotSpacing = GetSlotSpacing()
    local slotHeight = iconSize + 8
    local yOffset = -(TITLE_BAR_HEIGHT + padding + borderSize)

    for i = 1, #activeSlots do
        local slot = activeSlots[i]
        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", padding + borderSize, yOffset)
        slot:SetPoint("RIGHT", containerFrame, "RIGHT", -(padding + borderSize), 0)
        yOffset = yOffset - slotHeight - slotSpacing
    end

    -- Auto-resize container height to fit slots
    local totalHeight = TITLE_BAR_HEIGHT
        + padding
        + (#activeSlots * (slotHeight + slotSpacing))
        + padding
        + (borderSize * 2)
    local minHeight = db.lootWindow.height or 300
    if totalHeight < minHeight then
        totalHeight = minHeight
    end
    containerFrame:SetHeight(totalHeight)
end

local function ShowWithAnimation()
    if ns.LootAnimations.PlayOpen then
        ns.LootAnimations.PlayOpen(containerFrame)
    else
        containerFrame:Show()
    end
end

-------------------------------------------------------------------------------
-- Public Interface: ns.LootFrame
-------------------------------------------------------------------------------

function ns.LootFrame.Initialize()
    if containerFrame then
        return
    end
    containerFrame = CreateContainerFrame()
    ns.LootFrame.ApplySettings()
    RestoreFramePosition()
    ns.DebugPrint("LootFrame initialized")
end

function ns.LootFrame.Shutdown()
    if not containerFrame then
        return
    end
    ReleaseAllSlots()
    containerFrame:Hide()
    ns.DebugPrint("LootFrame shut down")
end

-------------------------------------------------------------------------------
-- Smart Auto-Loot Evaluation
-------------------------------------------------------------------------------

local function EvaluateSlot(slotIndex)
    local db = ns.Addon.db
    if not db then
        return false
    end

    local autoLootCfg = db.profile.autoLoot
    if not autoLootCfg then
        return false
    end

    local slotType = GetLootSlotType(slotIndex)

    -- Money and currency always qualify
    if slotType == LOOT_SLOT_MONEY or slotType == LOOT_SLOT_CURRENCY then
        return true
    end

    -- Item evaluation
    if slotType == LOOT_SLOT_ITEM then
        local link = GetLootSlotLink(slotIndex)
        if not link then
            return false
        end

        local itemID = tonumber(link:match("item:(%d+)"))
        if not itemID then
            return false
        end

        -- Whitelist always qualifies
        if autoLootCfg.whitelist[itemID] then
            return true
        end

        -- Blacklist never qualifies
        if autoLootCfg.blacklist[itemID] then
            return false
        end

        -- Quality check
        local _, _, _, quality = GetLootSlotInfo(slotIndex)
        if quality and quality >= autoLootCfg.minQuality then
            return true
        end
    end

    return false
end

function ns.LootFrame.Show(autoLoot)
    if not containerFrame then
        return
    end

    ReleaseAllSlots()

    local numItems = GetNumLootItems()
    if numItems == 0 then
        return
    end

    -- Auto-loot: skip UI entirely
    if autoLoot then
        for i = 1, numItems do
            LootSlot(i)
        end
        return
    end

    -- Smart auto-loot: evaluate each slot and auto-pick qualifying items
    local db = ns.Addon.db
    if db and db.profile.autoLoot and db.profile.autoLoot.enabled then
        local qualifying = {}
        local allQualify = true
        for i = 1, numItems do
            if EvaluateSlot(i) then
                qualifying[#qualifying + 1] = i
            else
                allQualify = false
            end
        end

        -- All qualify: loot everything, skip UI entirely
        if allQualify and #qualifying > 0 then
            for i = 1, numItems do
                LootSlot(i)
            end
            return
        end

        -- Some qualify: loot them in reverse order (preserves lower indices)
        if #qualifying > 0 then
            for i = #qualifying, 1, -1 do
                LootSlot(qualifying[i])
            end
            -- Fall through to show UI for remaining items
            -- Re-read numItems since some were looted
            numItems = GetNumLootItems()
            if numItems == 0 then
                return
            end
        end
    end

    -- Only acquire and populate slots when NOT auto-looting
    for i = 1, numItems do
        local icon = GetNormalizedSlotInfo(i)
        if icon then
            local slot = AcquireSlot()
            PopulateSlot(slot, i)
            activeSlots[#activeSlots + 1] = slot
        end
    end

    LayoutSlots()

    -- Position at cursor if enabled
    local lootDb = ns.Addon.db.profile.lootWindow
    if lootDb.positionAtCursor then
        PositionAtCursor()
    end

    -- Fishing indicator
    if IsFishingLoot and IsFishingLoot() then
        containerFrame.fishingText:SetText(L["Fishing"])
        containerFrame.fishingText:Show()
    else
        containerFrame.fishingText:Hide()
    end

    -- Animate or just show
    ShowWithAnimation()
end

function ns.LootFrame.Hide()
    if not containerFrame then
        return
    end

    local function DoHide()
        ReleaseAllSlots()
        containerFrame:Hide()
        containerFrame.fishingText:Hide()
    end

    if ns.LootAnimations.PlayClose then
        ns.LootAnimations.PlayClose(containerFrame, DoHide)
    else
        DoHide()
    end
end

function ns.LootFrame.UpdateSlot(slotIndex)
    if not containerFrame or not containerFrame:IsShown() then
        return
    end

    -- Find the active slot matching this index
    for i = #activeSlots, 1, -1 do
        local slot = activeSlots[i]
        if slot.slotIndex == slotIndex then
            -- Check if slot is now empty
            local icon = GetNormalizedSlotInfo(slotIndex)
            if not icon then
                ReleaseSlot(slot)
                table.remove(activeSlots, i)
            else
                PopulateSlot(slot, slotIndex)
            end
            break
        end
    end

    -- Skip re-layout during close animation to prevent mid-animation resizing
    if not ns.LootAnimations.isClosing then
        LayoutSlots()
    end

    -- Close if all slots gone
    if #activeSlots == 0 then
        ns.LootFrame.Hide()
    end
end

function ns.LootFrame.ApplySettings()
    if not containerFrame then
        return
    end
    local db = ns.Addon.db.profile

    containerFrame:SetSize(db.lootWindow.width or 250, db.lootWindow.height or 300)
    containerFrame:SetScale(db.lootWindow.scale or 1.0)

    -- Update backdrop
    ApplyBackdrop(containerFrame)

    -- Update layout offsets for border thickness
    ApplyLayoutOffsets(containerFrame)

    -- Update title font
    local fontPath, fontSize, fontOutline = GetFont()
    containerFrame.title:SetFont(fontPath, fontSize, fontOutline)
    DU.ApplyFontShadow(containerFrame.title, ns.Addon.db)

    -- Update visible slots
    for _, slot in ipairs(activeSlots) do
        if slot:IsShown() then
            slot.itemName:SetFont(fontPath, fontSize, fontOutline)
            DU.ApplyFontShadow(slot.itemName, ns.Addon.db)
            -- Refresh quality border visibility
            if slot.slotIndex then
                local _, _, _, quality = GetNormalizedSlotInfo(slot.slotIndex)
                if db.appearance.qualityBorder then
                    local r, g, b = DU.GetQualityColor(quality)
                    slot._qr, slot._qg, slot._qb = r, g, b
                    slot._quality = quality
                    slot.iconBorder:SetColorTexture(r, g, b, 0.8)
                    slot.iconBorder:Show()
                else
                    slot.iconBorder:Hide()
                end
                -- Update sub-text font
                local subFontSize = math.max(fontSize - 2, 8)
                slot.subText:SetFont(fontPath, subFontSize, fontOutline)
                DU.ApplyFontShadow(slot.subText, ns.Addon.db)
                -- Refresh row background and highlight
                ApplySlotBackground(slot, quality)
                slot.highlight:SetColorTexture(slot._qr or 1, slot._qg or 1, slot._qb or 1, 0.15)
            end
        end
    end

    -- Re-layout if visible
    if containerFrame:IsShown() then
        LayoutSlots()
    end
end

function ns.LootFrame.ResetAnchor()
    if not containerFrame then
        return
    end
    local db = ns.Addon.db.profile.lootWindow
    db.point = nil
    db.relativePoint = nil
    db.x = nil
    db.y = nil
    containerFrame:ClearAllPoints()
    containerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

function ns.LootFrame.SaveAnchor()
    SaveFramePosition()
end

-------------------------------------------------------------------------------
-- Test loot data
-------------------------------------------------------------------------------

local TEST_ITEMS = {
    {
        icon = 134762,
        name = "Super Mana Potion",
        quantity = 3,
        quality = 1,
        slotType = LOOT_SLOT_ITEM,
        isQuestItem = false,
        itemLevel = 0,
        bindType = 0,
        itemSubType = "Potion",
    },
    {
        icon = 132608,
        name = "Bog Walker's Bands",
        quantity = 1,
        quality = 2,
        slotType = LOOT_SLOT_ITEM,
        isQuestItem = false,
        itemLevel = 115,
        bindType = 2,
        itemSubType = "Leather",
    },
    {
        icon = 132447,
        name = "Gorehowl",
        quantity = 1,
        quality = 4,
        slotType = LOOT_SLOT_ITEM,
        isQuestItem = false,
        itemLevel = 226,
        bindType = 1,
        itemSubType = "Swords",
    },
    {
        icon = 133784,
        name = "15 Gold 32 Silver",
        quantity = 1,
        quality = 1,
        slotType = LOOT_SLOT_MONEY,
        isQuestItem = false,
        itemLevel = 0,
        bindType = 0,
        itemSubType = nil,
    },
    {
        icon = 132798,
        name = "Cenarion Spirits",
        quantity = 1,
        quality = 3,
        slotType = LOOT_SLOT_ITEM,
        isQuestItem = true,
        itemLevel = 200,
        bindType = 1,
        itemSubType = "Quest",
    },
}

local function PopulateTestSlot(slot, testData, index)
    local data = BuildTestSlotData(testData, index)
    RenderSlot(slot, data, true)
    slot.slotIndex = index
    slot.testData = testData
end

function ns.LootFrame.ShowTestLoot()
    if not containerFrame then
        ns.LootFrame.Initialize()
    end

    ReleaseAllSlots()

    for i, testData in ipairs(TEST_ITEMS) do
        local slot = AcquireSlot()
        PopulateTestSlot(slot, testData, i)
        activeSlots[#activeSlots + 1] = slot
    end

    LayoutSlots()
    local lootDb = ns.Addon.db.profile.lootWindow
    if lootDb.positionAtCursor then
        PositionAtCursor()
    end
    containerFrame.fishingText:Hide()

    ShowWithAnimation()

    ns.Print(L["Showing test loot window."])
end
