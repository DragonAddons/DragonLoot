-------------------------------------------------------------------------------
-- LootFrame.lua
-- Replacement loot window that intercepts LOOT_OPENED and displays items
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

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
local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local UNKNOWN = UNKNOWN
local GetLootSlotLink = GetLootSlotLink
local CreateColor = CreateColor

local LSM = LibStub("LibSharedMedia-3.0")

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
    [1] = "BoP",
    [2] = "BoE",
    [3] = "BoU",
    [4] = "Quest",
}

-------------------------------------------------------------------------------
-- Layout constants
-------------------------------------------------------------------------------

local TITLE_BAR_HEIGHT = 24

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
        local icon, name, quantity, _currencyID, quality, locked, isQuestItem =
            GetLootSlotInfo(slotIndex)
        return icon, name, quantity, quality, locked, isQuestItem
    end
    -- Classic/TBC/MoP: 6 returns with currencyID at position 4, no isQuestItem
    local icon, name, quantity, _currencyID, quality, locked =
        GetLootSlotInfo(slotIndex)
    return icon, name, quantity, quality, locked, nil
end

-------------------------------------------------------------------------------
-- Quality color helper
-------------------------------------------------------------------------------

local function GetQualityColor(quality)
    if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        local qc = ITEM_QUALITY_COLORS[quality]
        return qc.r, qc.g, qc.b
    end
    if quality and ns.QUALITY_COLORS and ns.QUALITY_COLORS[quality] then
        local qc = ns.QUALITY_COLORS[quality]
        return qc.r, qc.g, qc.b
    end
    return 1, 1, 1
end

-------------------------------------------------------------------------------
-- Item detail helpers
-------------------------------------------------------------------------------

local function GetItemDetails(slotIndex)
    local lootType = GetLootSlotType(slotIndex)
    if lootType ~= LOOT_SLOT_ITEM then return nil, nil, nil end

    local itemLink = GetLootSlotLink(slotIndex)
    if not itemLink then return nil, nil, nil end

    local _, _, _, itemLevel, _, _, itemSubType, _,
          _, _, _, _, _, bindType = C_Item.GetItemInfo(itemLink)

    local bindText = bindType and BIND_LABELS[bindType] or nil
    return itemLevel, bindText, itemSubType
end

local function ApplySlotBackground(slot, quality)
    local style = ns.Addon.db.profile.appearance.slotBackground or "gradient"

    -- Only show quality-tinted backgrounds for Rare+ items (quality >= 3)
    if not quality or quality < 3 or style == "none" then
        slot.rowBg:Hide()
        slot.accentStripe:Hide()
        return
    end

    local r, g, b = GetQualityColor(quality)

    if style == "gradient" then
        slot.rowBg:SetColorTexture(1, 1, 1)
        slot.rowBg:SetGradient("HORIZONTAL",
            CreateColor(r, g, b, 0.4),
            CreateColor(r, g, b, 0.1))
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
        return "Currency"
    elseif lootType == LOOT_SLOT_MONEY then
        return "Money"
    elseif lootType == LOOT_SLOT_ITEM then
        local itemLevel, bindText, itemSubType = GetItemDetails(slotIndex)
        local parts = {}
        if itemLevel and itemLevel > 0 then
            parts[#parts + 1] = "iLvl " .. itemLevel
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
-- Font helper
-------------------------------------------------------------------------------

local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"

local function GetFont()
    local db = ns.Addon.db.profile.appearance
    local fontPath = LSM:Fetch("font", db.font) or STANDARD_TEXT_FONT
    return fontPath, db.fontSize, db.fontOutline
end

local function GetBackdropSettings()
    local db = ns.Addon.db.profile.appearance
    local bgTexture = LSM:Fetch("background", db.backgroundTexture) or WHITE8x8
    local settings = { bgFile = bgTexture }
    if (db.borderSize or 1) > 0 then
        local edgeFile = LSM:Fetch("border", db.borderTexture)
        if edgeFile then
            settings.edgeFile = edgeFile
            settings.edgeSize = db.borderSize
        end
    end
    return settings
end

local function ApplyBackdrop(frame)
    local db = ns.Addon.db.profile.appearance
    if not db then return end

    frame:SetBackdrop(GetBackdropSettings())

    local bg = db.backgroundColor
    if bg then
        frame:SetBackdropColor(bg.r or 0.05, bg.g or 0.05, bg.b or 0.05, db.backgroundAlpha or 0.9)
    else
        frame:SetBackdropColor(0.05, 0.05, 0.05, db.backgroundAlpha or 0.9)
    end

    local border = db.borderColor
    if border then
        frame:SetBackdropBorderColor(border.r or 0.3, border.g or 0.3, border.b or 0.3, 0.8)
    else
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end
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
        frame.titleSeparator:SetPoint("TOPRIGHT", frame, "TOPRIGHT",
            -(6 + borderSize), -(TITLE_BAR_HEIGHT + borderSize))
    end
end

-------------------------------------------------------------------------------
-- Position persistence
-------------------------------------------------------------------------------

local function SaveFramePosition()
    if not containerFrame then return end
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
    if not containerFrame then return end
    local db = ns.Addon.db.profile.lootWindow
    containerFrame:ClearAllPoints()
    if db.point then
        containerFrame:SetPoint(db.point, UIParent, db.relativePoint, db.x or 0, db.y or 0)
    else
        containerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
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
    self.itemName:SetTextColor(
        math.min(r + 0.15, 1),
        math.min(g + 0.15, 1),
        math.min(b + 0.15, 1))
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
    slot.iconFrame:SetPoint("LEFT", slot, "LEFT", 4, 0)
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
    slot.iconBorder:SetPoint("TOPLEFT", slot.iconFrame, "TOPLEFT", -2, 2)
    slot.iconBorder:SetPoint("BOTTOMRIGHT", slot.iconFrame, "BOTTOMRIGHT", 2, -2)
    slot.iconBorder:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    -- Icon (draws ON TOP of border at sublevel 1)
    slot.icon = slot.iconFrame:CreateTexture(nil, "ARTWORK")
    slot.icon:SetDrawLayer("ARTWORK", 1)
    slot.icon:SetAllPoints(slot.iconFrame)
    slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Quantity badge
    slot.quantity = slot.iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    slot.quantity:SetPoint("BOTTOMRIGHT", slot.iconFrame, "BOTTOMRIGHT", 2, -2)
    slot.quantity:SetJustifyH("RIGHT")
    slot.quantity:SetTextColor(1, 1, 1)

    -- Item name (top-aligned to leave room for sub-text)
    slot.itemName = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slot.itemName:SetPoint("TOPLEFT", slot.iconFrame, "TOPRIGHT", 6, -2)
    slot.itemName:SetPoint("RIGHT", slot, "RIGHT", -4, 0)
    slot.itemName:SetJustifyH("LEFT")
    slot.itemName:SetWordWrap(false)

    -- Sub-text (iLvl, bind type, item type / or Currency / Money)
    slot.subText = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slot.subText:SetPoint("TOPLEFT", slot.itemName, "BOTTOMLEFT", 0, -1)
    slot.subText:SetPoint("RIGHT", slot, "RIGHT", -4, 0)
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
    if slot._isPooled then return end
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

    table.insert(slotPool, slot)
end

local function ReleaseAllSlots()
    for i = #activeSlots, 1, -1 do
        ReleaseSlot(activeSlots[i])
        activeSlots[i] = nil
    end
end

-------------------------------------------------------------------------------
-- Populate a single slot with loot data
-------------------------------------------------------------------------------

local function PopulateSlot(slot, slotIndex)
    slot.slotIndex = slotIndex

    local icon, name, quantity, quality, _locked, isQuestItem = GetNormalizedSlotInfo(slotIndex)
    if not icon then
        slot:Hide()
        return
    end

    local db = ns.Addon.db.profile
    local iconSize = db.appearance.lootIconSize or 36
    local fontPath, fontSize, fontOutline = GetFont()

    -- Icon
    slot.icon:SetTexture(icon)
    slot.iconFrame:SetSize(iconSize, iconSize)
    slot.icon:SetDesaturated(false)

    -- Quality color
    local r, g, b = GetQualityColor(quality)
    slot._qr, slot._qg, slot._qb = r, g, b
    slot._quality = quality

    -- Quality border
    if db.appearance.qualityBorder then
        slot.iconBorder:SetColorTexture(r, g, b, 0.8)
        slot.iconBorder:Show()
    else
        slot.iconBorder:Hide()
    end

    -- Quest item override for border
    if isQuestItem then
        slot.iconBorder:SetColorTexture(1, 0.82, 0, 0.9)
        slot.iconBorder:Show()
    end

    -- Icon glow for Rare+ items (quality >= 3)
    if quality and quality >= 3 then
        slot.iconGlow:SetVertexColor(r, g, b, 0.6)
        slot.iconGlow:SetSize(iconSize + 25, iconSize + 25)
        slot.iconGlow:ClearAllPoints()
        slot.iconGlow:SetPoint("CENTER", slot.iconFrame, "CENTER", 0, 0)
        slot.iconGlow:Show()
    else
        slot.iconGlow:Hide()
    end

    -- Item name
    slot.itemName:SetFont(fontPath, fontSize, fontOutline)
    slot.itemName:SetText(name or UNKNOWN)
    slot.itemName:SetTextColor(r, g, b)

    -- Quantity badge
    if quantity and quantity > 1 then
        slot.quantity:SetText(quantity)
        slot.quantity:Show()
    else
        slot.quantity:Hide()
    end

    -- Sub-text (item details or slot type)
    local lootType = GetLootSlotType(slotIndex)
    local subTextStr = BuildSubText(slotIndex, lootType)
    if subTextStr then
        local subFontSize = math.max(fontSize - 2, 8)
        slot.subText:SetFont(fontPath, subFontSize, fontOutline)
        slot.subText:SetText(subTextStr)
        slot.subText:SetTextColor(0.6, 0.6, 0.6)
        slot.subText:Show()
    else
        slot.subText:Hide()
    end

    -- Row background (quality-tinted, configurable)
    ApplySlotBackground(slot, quality)

    -- Quality-tinted hover highlight
    slot.highlight:SetColorTexture(r, g, b, 0.15)

    -- Slot height
    slot:SetHeight(iconSize + 8)
    slot:Show()
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
    frame.title:SetText("Loot")
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
    if not containerFrame then return end
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
    local totalHeight = TITLE_BAR_HEIGHT + padding
        + (#activeSlots * (slotHeight + slotSpacing)) + padding + (borderSize * 2)
    local minHeight = db.lootWindow.height or 300
    if totalHeight < minHeight then totalHeight = minHeight end
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
    if containerFrame then return end
    containerFrame = CreateContainerFrame()
    ns.LootFrame.ApplySettings()
    RestoreFramePosition()
    ns.DebugPrint("LootFrame initialized")
end

function ns.LootFrame.Shutdown()
    if not containerFrame then return end
    ReleaseAllSlots()
    containerFrame:Hide()
    ns.DebugPrint("LootFrame shut down")
end

function ns.LootFrame.Show(autoLoot)
    if not containerFrame then return end

    ReleaseAllSlots()

    local numItems = GetNumLootItems()
    if numItems == 0 then return end

    -- Auto-loot: skip UI entirely
    if autoLoot then
        for i = 1, numItems do
            LootSlot(i)
        end
        return
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

    -- Fishing indicator
    if IsFishingLoot and IsFishingLoot() then
        containerFrame.fishingText:SetText("Fishing")
        containerFrame.fishingText:Show()
    else
        containerFrame.fishingText:Hide()
    end

    -- Animate or just show
    ShowWithAnimation()
end

function ns.LootFrame.Hide()
    if not containerFrame then return end

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
    if not containerFrame or not containerFrame:IsShown() then return end

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

    LayoutSlots()

    -- Close if all slots gone
    if #activeSlots == 0 then
        ns.LootFrame.Hide()
    end
end

function ns.LootFrame.ApplySettings()
    if not containerFrame then return end
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

    -- Update visible slots
    for _, slot in ipairs(activeSlots) do
        if slot:IsShown() then
            slot.itemName:SetFont(fontPath, fontSize, fontOutline)
            -- Refresh quality border visibility
            if slot.slotIndex then
                local _, _, _, quality = GetNormalizedSlotInfo(slot.slotIndex)
                if db.appearance.qualityBorder then
                    local r, g, b = GetQualityColor(quality)
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
    if not containerFrame then return end
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
        icon = 134762, name = "Super Mana Potion", quantity = 3, quality = 1,
        slotType = LOOT_SLOT_ITEM, isQuestItem = false,
        itemLevel = 0, bindType = 0, itemSubType = "Potion",
    },
    {
        icon = 132608, name = "Bog Walker's Bands", quantity = 1, quality = 2,
        slotType = LOOT_SLOT_ITEM, isQuestItem = false,
        itemLevel = 115, bindType = 2, itemSubType = "Leather",
    },
    {
        icon = 132447, name = "Gorehowl", quantity = 1, quality = 4,
        slotType = LOOT_SLOT_ITEM, isQuestItem = false,
        itemLevel = 226, bindType = 1, itemSubType = "Swords",
    },
    {
        icon = 133784, name = "15 Gold 32 Silver", quantity = 1, quality = 1,
        slotType = LOOT_SLOT_MONEY, isQuestItem = false,
        itemLevel = 0, bindType = 0, itemSubType = nil,
    },
    {
        icon = 132798, name = "Cenarion Spirits", quantity = 1, quality = 3,
        slotType = LOOT_SLOT_ITEM, isQuestItem = true,
        itemLevel = 200, bindType = 1, itemSubType = "Quest",
    },
}

local function PopulateTestSlot(slot, testData, index)
    slot.slotIndex = index

    local db = ns.Addon.db.profile
    local iconSize = db.appearance.lootIconSize or 36
    local fontPath, fontSize, fontOutline = GetFont()

    -- Icon
    slot.icon:SetTexture(testData.icon)
    slot.iconFrame:SetSize(iconSize, iconSize)
    slot.icon:SetDesaturated(false)
    slot.icon:SetVertexColor(1, 1, 1)
    slot.icon:SetAlpha(1)

    -- Quality color
    local r, g, b = GetQualityColor(testData.quality)
    slot._qr, slot._qg, slot._qb = r, g, b
    slot._quality = testData.quality

    -- Quality border
    if db.appearance.qualityBorder then
        slot.iconBorder:SetColorTexture(r, g, b, 0.8)
        slot.iconBorder:Show()
    else
        slot.iconBorder:Hide()
    end

    -- Quest item override
    if testData.isQuestItem then
        slot.iconBorder:SetColorTexture(1, 0.82, 0, 0.9)
        slot.iconBorder:Show()
    end

    -- Icon glow for Rare+ items
    if testData.quality and testData.quality >= 3 then
        slot.iconGlow:SetVertexColor(r, g, b, 0.6)
        slot.iconGlow:SetSize(iconSize + 25, iconSize + 25)
        slot.iconGlow:ClearAllPoints()
        slot.iconGlow:SetPoint("CENTER", slot.iconFrame, "CENTER", 0, 0)
        slot.iconGlow:Show()
    else
        slot.iconGlow:Hide()
    end

    -- Item name
    slot.itemName:SetFont(fontPath, fontSize, fontOutline)
    slot.itemName:SetText(testData.name)
    slot.itemName:SetTextColor(r, g, b)

    -- Quality-tinted hover highlight
    slot.highlight:SetColorTexture(r, g, b, 0.15)

    -- Quantity
    if testData.quantity and testData.quantity > 1 then
        slot.quantity:SetText(testData.quantity)
        slot.quantity:Show()
    else
        slot.quantity:Hide()
    end

    -- Sub-text
    local subTextStr
    if testData.slotType == LOOT_SLOT_CURRENCY then
        subTextStr = "Currency"
    elseif testData.slotType == LOOT_SLOT_MONEY then
        subTextStr = "Money"
    elseif testData.slotType == LOOT_SLOT_ITEM then
        local parts = {}
        if testData.itemLevel and testData.itemLevel > 0 then
            parts[#parts + 1] = "iLvl " .. testData.itemLevel
        end
        local bindText = testData.bindType and BIND_LABELS[testData.bindType] or nil
        if bindText then
            parts[#parts + 1] = bindText
        end
        if testData.itemSubType then
            parts[#parts + 1] = testData.itemSubType
        end
        if #parts > 0 then
            subTextStr = table.concat(parts, "  \194\183  ")
        end
    end

    if subTextStr then
        local subFontSize = math.max(fontSize - 2, 8)
        slot.subText:SetFont(fontPath, subFontSize, fontOutline)
        slot.subText:SetText(subTextStr)
        slot.subText:SetTextColor(0.6, 0.6, 0.6)
        slot.subText:Show()
    else
        slot.subText:Hide()
    end

    -- Row background
    ApplySlotBackground(slot, testData.quality)

    -- Slot height
    slot:SetHeight(iconSize + 8)

    -- Test slot interaction (no real loot)
    slot:SetScript("OnClick", function()
        ns.Print("Test slot clicked: " .. testData.name)
    end)
    slot:SetScript("OnEnter", function(self)
        -- Tooltip
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(testData.name, r, g, b)
        if subTextStr then
            GameTooltip:AddLine(subTextStr, 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()

        -- Visual hover effects
        if self.iconBorder:IsShown() then
            self.iconBorder:SetColorTexture(r, g, b, 1.0)
        end
        if self.iconGlow:IsShown() then
            self.iconGlow:SetAlpha(0.9)
        end
        self.itemName:SetTextColor(
            math.min(r + 0.15, 1),
            math.min(g + 0.15, 1),
            math.min(b + 0.15, 1))
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

    slot:Show()
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
    containerFrame.fishingText:Hide()

    ShowWithAnimation()

    ns.Print("Showing test loot window.")
end
