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
    if self.slotIndex then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetLootItem(self.slotIndex)
        GameTooltip:Show()
    end
end

local function OnSlotLeave()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- Slot type indicator and quest item highlight helper
-------------------------------------------------------------------------------

local function ApplySlotTypeAndQuest(slot, slotIndex, isQuestItem)
    local lootType = GetLootSlotType(slotIndex)
    if lootType == LOOT_SLOT_CURRENCY then
        slot.slotType:SetText("Currency")
        slot.slotType:Show()
    elseif lootType == LOOT_SLOT_MONEY then
        slot.slotType:SetText("Money")
        slot.slotType:Show()
    else
        slot.slotType:Hide()
    end

    if isQuestItem then
        slot.iconBorder:SetColorTexture(1, 0.82, 0, 0.9)
        slot.iconBorder:Show()
    end
    -- Don't hide for non-quest items - let PopulateSlot handle quality border
end

-------------------------------------------------------------------------------
-- Slot frame creation
-------------------------------------------------------------------------------

local function CreateSlotFrame()
    slotCount = slotCount + 1
    local frameName = "DragonLootSlot" .. slotCount

    local slot = CreateFrame("Button", frameName, containerFrame)
    slot:SetHeight(40)
    slot:EnableMouse(true)
    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Icon
    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetDrawLayer("ARTWORK", 0)
    slot.icon:SetSize(36, 36)
    slot.icon:SetPoint("LEFT", slot, "LEFT", 4, 0)
    slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Icon border (drawn behind icon)
    slot.iconBorder = slot:CreateTexture(nil, "OVERLAY")
    slot.iconBorder:SetPoint("TOPLEFT", slot.icon, "TOPLEFT", -1, 1)
    slot.iconBorder:SetPoint("BOTTOMRIGHT", slot.icon, "BOTTOMRIGHT", 1, -1)
    slot.iconBorder:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    -- Quantity badge
    slot.quantity = slot:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    slot.quantity:SetPoint("BOTTOMRIGHT", slot.icon, "BOTTOMRIGHT", 2, -2)
    slot.quantity:SetJustifyH("RIGHT")
    slot.quantity:SetTextColor(1, 1, 1)

    -- Item name
    slot.itemName = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slot.itemName:SetPoint("LEFT", slot.icon, "RIGHT", 6, 0)
    slot.itemName:SetPoint("RIGHT", slot, "RIGHT", -4, 0)
    slot.itemName:SetJustifyH("LEFT")
    slot.itemName:SetWordWrap(false)

    -- Slot type indicator (small text beneath name for currency/money)
    slot.slotType = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slot.slotType:SetPoint("TOPLEFT", slot.itemName, "BOTTOMLEFT", 0, -1)
    slot.slotType:SetJustifyH("LEFT")
    slot.slotType:SetTextColor(0.6, 0.6, 0.6)

    -- Highlight
    slot.highlight = slot:CreateTexture(nil, "HIGHLIGHT")
    slot.highlight:SetAllPoints()
    slot.highlight:SetColorTexture(1, 1, 1, 0.1)

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
    slot:Hide()
    slot:ClearAllPoints()
    slot.slotIndex = nil
    slot.icon:SetTexture(nil)
    slot.icon:SetDesaturated(false)
    slot.icon:SetVertexColor(1, 1, 1)
    slot.icon:SetAlpha(1)
    slot.itemName:SetText("")
    slot.quantity:Hide()
    slot.slotType:SetText("")

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

    -- Icon - reset all state to ensure proper rendering
    slot.icon:SetTexture(icon)
    slot.icon:SetSize(iconSize, iconSize)
    slot.icon:SetDesaturated(false)

    -- Quality border color - always set but respect qualityBorder setting
    local r, g, b = GetQualityColor(quality)
    if db.appearance.qualityBorder then
        slot.iconBorder:SetColorTexture(r, g, b, 0.8)
        slot.iconBorder:Show()
    else
        slot.iconBorder:Hide()
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

    -- Slot type indicator and quest highlight
    ApplySlotTypeAndQuest(slot, slotIndex, isQuestItem)

    -- Adjust slot height to icon size
    slot:SetHeight(iconSize + 4)
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

    -- Offset child elements to account for border thickness
    ApplyLayoutOffsets(frame)

    return frame
end

-------------------------------------------------------------------------------
-- Layout slots inside container
-------------------------------------------------------------------------------

local TITLE_BAR_HEIGHT = 22
local SLOT_SPACING = 2
local PADDING = 4

local function LayoutSlots()
    if not containerFrame then return end
    local db = ns.Addon.db.profile
    local iconSize = db.appearance.lootIconSize or 36
    local borderSize = db.appearance.borderSize or 1
    local slotHeight = iconSize + 4
    local yOffset = -(TITLE_BAR_HEIGHT + PADDING + borderSize)

    for i = 1, #activeSlots do
        local slot = activeSlots[i]
        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", PADDING + borderSize, yOffset)
        slot:SetPoint("RIGHT", containerFrame, "RIGHT", -(PADDING + borderSize), 0)
        yOffset = yOffset - slotHeight - SLOT_SPACING
    end

    -- Auto-resize container height to fit slots
    local totalHeight = TITLE_BAR_HEIGHT + PADDING
        + (#activeSlots * (slotHeight + SLOT_SPACING)) + PADDING + (borderSize * 2)
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

    containerFrame:SetSize(db.lootWindow.width or 220, db.lootWindow.height or 300)
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
                    slot.iconBorder:SetColorTexture(r, g, b, 0.8)
                    slot.iconBorder:Show()
                else
                    slot.iconBorder:Hide()
                end
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
    },
    {
        icon = 132608, name = "Bog Walker's Bands", quantity = 1, quality = 2,
        slotType = LOOT_SLOT_ITEM, isQuestItem = false,
    },
    {
        icon = 132447, name = "Gorehowl", quantity = 1, quality = 4,
        slotType = LOOT_SLOT_ITEM, isQuestItem = false,
    },
    {
        icon = 133784, name = "15 Gold 32 Silver", quantity = 1, quality = 1,
        slotType = LOOT_SLOT_MONEY, isQuestItem = false,
    },
    {
        icon = 132798, name = "Cenarion Spirits", quantity = 1, quality = 1,
        slotType = LOOT_SLOT_ITEM, isQuestItem = true,
    },
}

local function PopulateTestSlot(slot, testData, index)
    slot.slotIndex = index

    local db = ns.Addon.db.profile
    local iconSize = db.appearance.lootIconSize or 36
    local fontPath, fontSize, fontOutline = GetFont()

    slot.icon:SetTexture(testData.icon)
    slot.icon:SetSize(iconSize, iconSize)
    slot.icon:SetDesaturated(false)
    slot.icon:SetVertexColor(1, 1, 1)  -- Reset any vertex color tinting
    slot.icon:SetAlpha(1)  -- Ensure full opacity

    local r, g, b = GetQualityColor(testData.quality)

    -- Quality border
    if db.appearance.qualityBorder then
        slot.iconBorder:SetColorTexture(r, g, b, 0.8)
        slot.iconBorder:Show()
    else
        slot.iconBorder:Hide()
    end

    slot.itemName:SetFont(fontPath, fontSize, fontOutline)
    slot.itemName:SetText(testData.name)
    slot.itemName:SetTextColor(r, g, b)

    if testData.quantity > 1 then
        slot.quantity:SetText(testData.quantity)
        slot.quantity:Show()
    else
        slot.quantity:Hide()
    end

    if testData.slotType == LOOT_SLOT_CURRENCY then
        slot.slotType:SetText("Currency")
        slot.slotType:Show()
    elseif testData.slotType == LOOT_SLOT_MONEY then
        slot.slotType:SetText("Money")
        slot.slotType:Show()
    else
        slot.slotType:Hide()
    end

    if testData.isQuestItem then
        slot.iconBorder:SetColorTexture(1, 0.82, 0, 0.9)
    end

    slot:SetHeight(iconSize + 4)

    -- Disable real loot interaction for test slots
    slot:SetScript("OnClick", function()
        ns.Print("Test slot clicked: " .. testData.name)
    end)
    slot:SetScript("OnEnter", nil)
    slot:SetScript("OnLeave", nil)

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
