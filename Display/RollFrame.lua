-------------------------------------------------------------------------------
-- RollFrame.lua
-- Loot roll frame replacement with timer bar and roll buttons
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
local GetLootRollItemInfo = GetLootRollItemInfo
local GetLootRollItemLink = GetLootRollItemLink
local RollOnLoot = RollOnLoot
local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local HandleModifiedItemClick = HandleModifiedItemClick

local LSM = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- Roll type constants (values used by RollOnLoot)
-------------------------------------------------------------------------------

local ROLL_PASS = 0
local ROLL_NEED = 1
local ROLL_GREED = 2
local ROLL_DISENCHANT = 3
local ROLL_TRANSMOG = 4

-------------------------------------------------------------------------------
-- Button icon textures
-------------------------------------------------------------------------------

local NEED_ICON = "Interface\\Buttons\\UI-GroupLoot-Dice-Up"
local GREED_ICON = "Interface\\Buttons\\UI-GroupLoot-Coin-Up"
local DE_ICON = "Interface\\Buttons\\UI-GroupLoot-DE-Up"
local PASS_ICON = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"

-------------------------------------------------------------------------------
-- Frame dimensions
-------------------------------------------------------------------------------

local FRAME_WIDTH = 280
local FRAME_BASE_HEIGHT = 54
local ICON_SIZE = 36
local BUTTON_SIZE = 24
local FRAME_SPACING = 4
local MAX_VISIBLE_ROLLS = 4

-------------------------------------------------------------------------------
-- Roll frame pool
-------------------------------------------------------------------------------

local rollFramePool = {}
local rollFrameCount = 0
local anchorFrame

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

local function GetFont()
    local db = ns.Addon.db.profile
    local fontPath = LSM:Fetch("font", db.appearance.font) or STANDARD_TEXT_FONT
    return fontPath, db.appearance.fontSize
end

-------------------------------------------------------------------------------
-- Timer bar color interpolation (green -> yellow -> red)
-------------------------------------------------------------------------------

local function GetTimerBarColor(timeLeft, rollTime)
    if rollTime <= 0 then return 1, 0, 0 end
    local ratio = timeLeft / rollTime

    if ratio > 0.5 then
        -- Green to Yellow
        local t = (ratio - 0.5) / 0.5
        return 1 - t, 1, 0
    else
        -- Yellow to Red
        local t = ratio / 0.5
        return 1, t, 0
    end
end

-------------------------------------------------------------------------------
-- Position persistence
-------------------------------------------------------------------------------

local function SaveFramePosition()
    if not anchorFrame then return end
    local db = ns.Addon.db.profile.rollFrame
    local point, _, relativePoint, x, y = anchorFrame:GetPoint()
    if point then
        db.point = point
        db.relativePoint = relativePoint
        db.x = x
        db.y = y
    end
end

local function RestoreFramePosition()
    if not anchorFrame then return end
    local db = ns.Addon.db.profile.rollFrame
    anchorFrame:ClearAllPoints()
    if db.point then
        anchorFrame:SetPoint(db.point, UIParent, db.relativePoint, db.x or 0, db.y or 0)
    else
        anchorFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    end
end

-------------------------------------------------------------------------------
-- Button click handler
-------------------------------------------------------------------------------

local function OnRollButtonClick(self)
    local rollID = self:GetParent().rollID
    if rollID then
        RollOnLoot(rollID, self.rollType)
    end
end

-------------------------------------------------------------------------------
-- Button tooltip handlers
-------------------------------------------------------------------------------

local ROLL_TOOLTIP_LABELS = {
    [ROLL_NEED] = "Need",
    [ROLL_GREED] = "Greed",
    [ROLL_DISENCHANT] = "Disenchant",
    [ROLL_PASS] = "Pass",
    [ROLL_TRANSMOG] = "Transmog",
}

local function OnRollButtonEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local label = ROLL_TOOLTIP_LABELS[self.rollType] or "Roll"
    GameTooltip:SetText(label)
    if self.disabledReason then
        GameTooltip:AddLine(self.disabledReason, 1, 0.2, 0.2, true)
    end
    GameTooltip:Show()
end

local function OnRollButtonLeave()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- Icon tooltip handlers
-------------------------------------------------------------------------------

local function OnIconEnter(self)
    local rollID = self:GetParent().rollID
    if rollID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetLootRollItem(rollID)
        GameTooltip:Show()
    end
end

local function OnIconLeave()
    GameTooltip:Hide()
end

local function OnIconClick(self, button)
    local rollID = self:GetParent().rollID
    if not rollID then return end
    if button == "LeftButton" then
        local link = GetLootRollItemLink(rollID)
        if link then
            HandleModifiedItemClick(link)
        end
    end
end

-------------------------------------------------------------------------------
-- Create roll icon button
-------------------------------------------------------------------------------

local function CreateRollIcon(parent)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(ICON_SIZE, ICON_SIZE)
    btn:SetPoint("LEFT", parent, "LEFT", 4, 0)
    btn:RegisterForClicks("LeftButtonUp")

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
    btn.border:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    btn.icon:SetDrawLayer("OVERLAY", 1)

    btn:SetScript("OnEnter", OnIconEnter)
    btn:SetScript("OnLeave", OnIconLeave)
    btn:SetScript("OnClick", OnIconClick)

    return btn
end

-------------------------------------------------------------------------------
-- Create generic roll action button
-------------------------------------------------------------------------------

local function CreateRollButton(parent, texture, rollType, size)
    local btnSize = size or BUTTON_SIZE
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(btnSize, btnSize)
    btn.rollType = rollType

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexture(texture)

    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetColorTexture(1, 1, 1, 0.2)

    btn:SetScript("OnClick", OnRollButtonClick)
    btn:SetScript("OnEnter", OnRollButtonEnter)
    btn:SetScript("OnLeave", OnRollButtonLeave)

    return btn
end

-------------------------------------------------------------------------------
-- Create timer bar
-------------------------------------------------------------------------------

local function CreateTimerBar(parent)
    local db = ns.Addon.db.profile
    local barHeight = db.rollFrame.timerBarHeight or 12

    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetHeight(barHeight)
    bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", ICON_SIZE + 10, 4)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetStatusBarColor(0, 1, 0)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar.text:SetTextColor(1, 1, 1)

    return bar
end

-------------------------------------------------------------------------------
-- Create a single roll frame
-------------------------------------------------------------------------------

local function CreateRollFrame(index)
    rollFrameCount = rollFrameCount + 1
    local frameName = "DragonLootRoll" .. rollFrameCount

    local frame = CreateFrame("Frame", frameName, anchorFrame, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_BASE_HEIGHT)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(110)
    frame:Hide()

    -- Item icon
    frame.iconFrame = CreateRollIcon(frame)

    -- Item name
    frame.itemName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.itemName:SetPoint("TOPLEFT", frame.iconFrame, "TOPRIGHT", 6, -1)
    frame.itemName:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    frame.itemName:SetJustifyH("LEFT")
    frame.itemName:SetWordWrap(false)

    -- BoP indicator
    frame.bindText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.bindText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -2)
    frame.bindText:SetTextColor(1, 0.2, 0.2)
    frame.bindText:Hide()

    -- Timer bar
    frame.timerBar = CreateTimerBar(frame)

    -- Roll buttons (anchored right-to-left above timer bar)
    frame.passButton = CreateRollButton(frame, PASS_ICON, ROLL_PASS)
    frame.passButton:SetPoint("RIGHT", frame, "RIGHT", -6, 6)

    frame.disenchantButton = CreateRollButton(frame, DE_ICON, ROLL_DISENCHANT)
    frame.disenchantButton:SetPoint("RIGHT", frame.passButton, "LEFT", -4, 0)

    frame.greedButton = CreateRollButton(frame, GREED_ICON, ROLL_GREED)
    frame.greedButton:SetPoint("RIGHT", frame.disenchantButton, "LEFT", -4, 0)

    frame.needButton = CreateRollButton(frame, NEED_ICON, ROLL_NEED)
    frame.needButton:SetPoint("RIGHT", frame.greedButton, "LEFT", -4, 0)

    -- Transmog button - only functional on Retail where canTransmog is returned
    frame.transmogButton = CreateRollButton(frame, nil, ROLL_TRANSMOG, BUTTON_SIZE)
    local success = pcall(function() frame.transmogButton.icon:SetAtlas("transmog-icon-small") end)
    if not success then
        frame.transmogButton.icon:SetTexture("Interface\\ICONS\\INV_Enchant_Disenchant")
    end
    frame.transmogButton:SetPoint("RIGHT", frame.needButton, "LEFT", -4, 0)
    frame.transmogButton:Hide()

    frame.frameIndex = index
    return frame
end

-------------------------------------------------------------------------------
-- Configure roll button state (enabled/disabled with reason)
-------------------------------------------------------------------------------

local function SetButtonState(btn, canUse, reason)
    if not btn then return end
    if canUse then
        btn:Enable()
        btn.icon:SetDesaturated(false)
        btn.icon:SetAlpha(1)
        btn.disabledReason = nil
    else
        btn:Disable()
        btn.icon:SetDesaturated(true)
        btn.icon:SetAlpha(0.4)
        btn.disabledReason = reason or "Not available for this item"
    end
end

-------------------------------------------------------------------------------
-- Populate a roll frame with item data
-------------------------------------------------------------------------------

local function PopulateRollFrame(frame, rollID)
    frame.rollID = rollID

    local texture, name, count, quality, bindOnPickUp, canNeed, canGreed,
          canDisenchant, reasonNeed, reasonGreed, reasonDisenchant,
          _deSkillRequired, canTransmog = GetLootRollItemInfo(rollID)

    if not texture then return end

    local fontPath, fontSize = GetFont()
    local r, g, b = GetQualityColor(quality)

    -- Icon
    frame.iconFrame.icon:SetTexture(texture)
    frame.iconFrame.border:SetColorTexture(r, g, b, 0.8)

    -- Item name
    frame.itemName:SetFont(fontPath, fontSize, "OUTLINE")
    frame.itemName:SetText(name or "")
    frame.itemName:SetTextColor(r, g, b)

    -- BoP indicator
    if bindOnPickUp then
        frame.bindText:SetText("BoP")
        frame.bindText:Show()
    else
        frame.bindText:Hide()
    end

    -- Timer bar starts full
    frame.timerBar:SetMinMaxValues(0, 1)
    frame.timerBar:SetValue(1)
    frame.timerBar:SetStatusBarColor(0, 1, 0)
    frame.timerBar.text:SetText("")

    -- Count text on icon (for stackable items)
    if count and count > 1 then
        if not frame.iconFrame.count then
            frame.iconFrame.count = frame.iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            frame.iconFrame.count:SetPoint("BOTTOMRIGHT", frame.iconFrame, "BOTTOMRIGHT", 2, -2)
        end
        frame.iconFrame.count:SetText(count)
        frame.iconFrame.count:Show()
    elseif frame.iconFrame.count then
        frame.iconFrame.count:Hide()
    end

    -- Button states
    SetButtonState(frame.needButton, canNeed, reasonNeed)
    SetButtonState(frame.greedButton, canGreed, reasonGreed)
    SetButtonState(frame.disenchantButton, canDisenchant, reasonDisenchant)
    SetButtonState(frame.passButton, true, nil)

    if frame.transmogButton then
        if canTransmog then
            frame.transmogButton:Show()
            SetButtonState(frame.transmogButton, true, nil)
        else
            frame.transmogButton:Hide()
        end
    end
end

-------------------------------------------------------------------------------
-- Layout visible roll frames
-------------------------------------------------------------------------------

local function LayoutRollFrames()
    local yOffset = 0
    for i = 1, MAX_VISIBLE_ROLLS do
        local frame = rollFramePool[i]
        if frame and frame:IsShown() then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, -yOffset)
            yOffset = yOffset + frame:GetHeight() + FRAME_SPACING
        end
    end
end

-------------------------------------------------------------------------------
-- Acquire / Release frames from pool
-------------------------------------------------------------------------------

local function AcquireRollFrame(index)
    if not rollFramePool[index] then
        rollFramePool[index] = CreateRollFrame(index)
    end
    return rollFramePool[index]
end

local function ReleaseRollFrame(index)
    local frame = rollFramePool[index]
    if not frame then return end
    frame.rollID = nil
    frame:Hide()
end

-------------------------------------------------------------------------------
-- Create anchor frame
-------------------------------------------------------------------------------

local function CreateAnchorFrame()
    local frame = CreateFrame("Frame", "DragonLootRollAnchor", UIParent)
    frame:SetSize(FRAME_WIDTH, 1)
    frame:SetClampedToScreen(true)

    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        local db = ns.Addon.db.profile.rollFrame
        if not db.lock then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveFramePosition()
    end)

    return frame
end

-------------------------------------------------------------------------------
-- Public Interface: ns.RollFrame
-------------------------------------------------------------------------------

function ns.RollFrame.Initialize()
    if anchorFrame then return end
    anchorFrame = CreateAnchorFrame()
    ns.RollFrame.ApplySettings()
    RestoreFramePosition()
    ns.DebugPrint("RollFrame initialized")
end

function ns.RollFrame.Shutdown()
    if not anchorFrame then return end
    ns.RollFrame.HideAllRolls()
    anchorFrame:Hide()
    ns.DebugPrint("RollFrame shut down")
end

function ns.RollFrame.ShowRoll(frameIndex, rollID)
    if not anchorFrame then return end

    local frame = AcquireRollFrame(frameIndex)
    PopulateRollFrame(frame, rollID)
    frame:Show()

    ns.RollAnimations.PlayShow(frame)
    LayoutRollFrames()
end

function ns.RollFrame.HideRoll(frameIndex, onComplete)
    local frame = rollFramePool[frameIndex]
    if not frame or not frame:IsShown() then
        ReleaseRollFrame(frameIndex)
        if onComplete then onComplete() end
        return
    end

    ns.RollAnimations.StopAll(frame)
    ns.RollAnimations.PlayHide(frame, function()
        ReleaseRollFrame(frameIndex)
        LayoutRollFrames()
        if onComplete then onComplete() end
    end)
end

function ns.RollFrame.HideAllRolls()
    for i = 1, MAX_VISIBLE_ROLLS do
        local frame = rollFramePool[i]
        if frame and frame:IsShown() then
            ns.RollAnimations.StopAll(frame)
            ReleaseRollFrame(i)
        end
    end
    LayoutRollFrames()
end

function ns.RollFrame.UpdateTimer(frameIndex, timeLeft, rollTime)
    local frame = rollFramePool[frameIndex]
    if not frame or not frame:IsShown() then return end

    local bar = frame.timerBar
    bar:SetMinMaxValues(0, rollTime)
    bar:SetValue(timeLeft)

    local r, g, b = GetTimerBarColor(timeLeft, rollTime)
    bar:SetStatusBarColor(r, g, b)
    bar.text:SetText(string.format("%.0f", timeLeft))
end

function ns.RollFrame.ApplySettings()
    if not anchorFrame then return end
    local db = ns.Addon.db.profile

    anchorFrame:SetScale(db.rollFrame.scale or 1.0)

    local barHeight = db.rollFrame.timerBarHeight or 12
    for i = 1, MAX_VISIBLE_ROLLS do
        local frame = rollFramePool[i]
        if frame then
            frame.timerBar:SetHeight(barHeight)
        end
    end

    LayoutRollFrames()
end

function ns.RollFrame.ResetAnchor()
    if not anchorFrame then return end
    local db = ns.Addon.db.profile.rollFrame
    db.point = nil
    db.relativePoint = nil
    db.x = nil
    db.y = nil
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
end
