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
local C_Timer = C_Timer
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

local ROLL_TYPE_NAMES = {
    [ROLL_PASS] = "Pass",
    [ROLL_NEED] = "Need",
    [ROLL_GREED] = "Greed",
    [ROLL_DISENCHANT] = "Disenchant",
    [ROLL_TRANSMOG] = "Transmog",
}

-------------------------------------------------------------------------------
-- Test roll data
-------------------------------------------------------------------------------

local TEST_ROLLS = {
    {
        texture = 132447,           -- Gorehowl
        name = "Gorehowl",
        count = 1,
        quality = 4,                -- Epic
        bindOnPickUp = true,
        canNeed = true,
        canGreed = true,
        canDisenchant = true,
        canTransmog = false,
        duration = 15,
    },
    {
        texture = 135506,           -- Sunfury Bow of the Phoenix
        name = "Sunfury Bow of the Phoenix",
        count = 1,
        quality = 4,                -- Epic
        bindOnPickUp = true,
        canNeed = true,
        canGreed = true,
        canDisenchant = true,
        canTransmog = false,
        duration = 20,
    },
}

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

local FRAME_WIDTH = 328
local FRAME_BASE_HEIGHT = 54
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

local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"

local function GetRollIconSize()
    return ns.Addon.db.profile.appearance.rollIconSize or 36
end

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
    frame:SetBackdrop(GetBackdropSettings())
    local bg = db.backgroundColor
    frame:SetBackdropColor(bg.r, bg.g, bg.b, db.backgroundAlpha)
    local border = db.borderColor
    -- Border alpha is intentionally fixed at 0.8 for visual consistency
    frame:SetBackdropBorderColor(border.r, border.g, border.b, 0.8)
end

local function ApplyLayoutOffsets(frame)
    local db = ns.Addon.db.profile
    local borderSize = db.appearance.borderSize or 1
    local iconSize = db.appearance.rollIconSize or 36

    -- Icon position
    frame.iconFrame:ClearAllPoints()
    frame.iconFrame:SetPoint("LEFT", frame, "LEFT", 4 + borderSize, 0)

    -- Item name - follows icon, but right edge needs border offset
    frame.itemName:ClearAllPoints()
    frame.itemName:SetPoint("TOPLEFT", frame.iconFrame, "TOPRIGHT", 6, -1)
    frame.itemName:SetPoint("RIGHT", frame, "RIGHT", -(4 + borderSize), 0)

    -- BoP indicator - anchored below item name, clear of roll buttons
    frame.bindText:ClearAllPoints()
    frame.bindText:SetPoint("TOPLEFT", frame.itemName, "BOTTOMLEFT", 0, -1)

    -- Timer bar
    frame.timerBar:ClearAllPoints()
    frame.timerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", iconSize + 10 + borderSize,
        4 + borderSize)
    frame.timerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(6 + borderSize),
        4 + borderSize)

    -- Roll buttons - only reposition the rightmost (pass); others chain from it
    frame.passButton:ClearAllPoints()
    frame.passButton:SetPoint("RIGHT", frame, "RIGHT", -(6 + borderSize), 6)
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
    local frame = self:GetParent()
    if frame.isTestMode then
        ns.Print("Test roll: " .. (ROLL_TYPE_NAMES[self.rollType] or "Unknown"))
        return
    end
    if frame.rollID then
        RollOnLoot(frame.rollID, self.rollType)
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
    local frame = self:GetParent()
    if frame.isTestMode then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(frame.testItemName or "Test Item", 1, 1, 1)
        GameTooltip:Show()
        return
    end
    if frame.rollID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetLootRollItem(frame.rollID)
        GameTooltip:Show()
    end
end

local function OnIconLeave()
    GameTooltip:Hide()
end

local function OnIconClick(self, button)
    local frame = self:GetParent()
    if frame.isTestMode then
        ns.Print("Test item: " .. (frame.testItemName or "Test Item"))
        return
    end
    if not frame.rollID then return end
    if button == "LeftButton" then
        local link = GetLootRollItemLink(frame.rollID)
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
    local defaultIconSize = GetRollIconSize()
    btn:SetSize(defaultIconSize, defaultIconSize)
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
    local barTexture = LSM:Fetch("statusbar", db.rollFrame.timerBarTexture)
        or "Interface\\TargetingFrame\\UI-StatusBar"

    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetHeight(barHeight)
    local iconSize = GetRollIconSize()
    bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", iconSize + 10, 4)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
    bar:SetStatusBarTexture(barTexture)
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
    ApplyBackdrop(frame)
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
    frame.bindText:SetPoint("TOPLEFT", frame.itemName, "BOTTOMLEFT", 0, -1)
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

    local fontPath, fontSize, fontOutline = GetFont()
    local r, g, b = GetQualityColor(quality)

    -- Resize icon to current config value
    local iconSize = GetRollIconSize()
    frame.iconFrame:SetSize(iconSize, iconSize)

    -- Adjust frame height based on icon size
    frame:SetHeight(math.max(FRAME_BASE_HEIGHT, iconSize + 18))

    -- Icon
    frame.iconFrame.icon:SetTexture(texture)

    -- Quality border
    if ns.Addon.db.profile.appearance.qualityBorder then
        frame.iconFrame.border:SetColorTexture(r, g, b, 0.8)
        frame.iconFrame.border:Show()
    else
        frame.iconFrame.border:Hide()
    end

    -- Item name
    frame.itemName:SetFont(fontPath, fontSize, fontOutline)
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

    -- Reposition children for current border thickness
    ApplyLayoutOffsets(frame)
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
    if frame.testTimer then
        frame.testTimer:Cancel()
        frame.testTimer = nil
    end
    frame.isTestMode = false
    frame.testItemName = nil
    frame.testQuality = nil
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
-- Populate a test roll frame with fake data (no real rollID required)
-------------------------------------------------------------------------------

local function PopulateTestRollFrame(frame, testData)
    frame.rollID = nil
    frame.isTestMode = true
    frame.testItemName = testData.name
    frame.testQuality = testData.quality

    local db = ns.Addon.db.profile
    local iconSize = db.appearance.rollIconSize or 36
    local fontPath, fontSize, fontOutline = GetFont()
    local r, g, b = GetQualityColor(testData.quality)

    -- Icon
    frame.iconFrame.icon:SetTexture(testData.texture)
    frame.iconFrame:SetSize(iconSize, iconSize)

    -- Quality border
    if db.appearance.qualityBorder then
        frame.iconFrame.border:SetColorTexture(r, g, b, 0.8)
        frame.iconFrame.border:Show()
    else
        frame.iconFrame.border:Hide()
    end

    -- Item name
    frame.itemName:SetFont(fontPath, fontSize, fontOutline)
    frame.itemName:SetText(testData.name)
    frame.itemName:SetTextColor(r, g, b)

    -- BoP indicator
    if testData.bindOnPickUp then
        frame.bindText:SetText("BoP")
        frame.bindText:Show()
    else
        frame.bindText:Hide()
    end

    -- Timer bar starts full
    frame.timerBar:SetMinMaxValues(0, 1)
    frame.timerBar:SetValue(1)
    frame.timerBar:SetStatusBarColor(0, 1, 0)
    frame.timerBar.text:SetText(string.format("%.0f", testData.duration))

    -- Stack count on icon
    if testData.count and testData.count > 1 then
        if not frame.iconFrame.count then
            frame.iconFrame.count = frame.iconFrame:CreateFontString(
                nil, "OVERLAY", "NumberFontNormal")
            frame.iconFrame.count:SetPoint(
                "BOTTOMRIGHT", frame.iconFrame, "BOTTOMRIGHT", 2, -2)
        end
        frame.iconFrame.count:SetText(testData.count)
        frame.iconFrame.count:Show()
    elseif frame.iconFrame.count then
        frame.iconFrame.count:Hide()
    end

    -- Button states
    SetButtonState(frame.needButton, testData.canNeed, nil)
    SetButtonState(frame.greedButton, testData.canGreed, nil)
    SetButtonState(frame.disenchantButton, testData.canDisenchant, nil)
    SetButtonState(frame.passButton, true, nil)

    if frame.transmogButton then
        if testData.canTransmog then
            frame.transmogButton:Show()
            SetButtonState(frame.transmogButton, true, nil)
        else
            frame.transmogButton:Hide()
        end
    end

    -- Frame height based on icon size
    frame:SetHeight(math.max(FRAME_BASE_HEIGHT, iconSize + 18))

    ApplyLayoutOffsets(frame)
end

-------------------------------------------------------------------------------
-- Start test countdown timer for a single frame
-------------------------------------------------------------------------------

local function StartTestTimer(frameIndex, duration)
    local frame = rollFramePool[frameIndex]
    if not frame or not frame:IsShown() then return end

    local remaining = duration
    local total = duration

    frame.testTimer = C_Timer.NewTicker(0.1, function()
        remaining = remaining - 0.1
        if remaining <= 0 then
            frame.testTimer:Cancel()
            frame.testTimer = nil
            ns.RollFrame.HideRoll(frameIndex)
            return
        end
        local pct = remaining / total
        frame.timerBar:SetValue(pct)
        local r, g, b = GetTimerBarColor(remaining, total)
        frame.timerBar:SetStatusBarColor(r, g, b)
        frame.timerBar.text:SetText(string.format("%.0f", remaining))
    end)
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

    -- Show and layout BEFORE animation so anchor points are set
    frame:SetAlpha(0)
    frame:Show()
    LayoutRollFrames()

    ns.RollAnimations.PlayShow(frame)
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
    if not db then return end

    local appearance = db.appearance or {}
    local rollFrame = db.rollFrame or {}

    anchorFrame:SetScale(rollFrame.scale or 1.0)

    local barHeight = rollFrame.timerBarHeight or 12
    local barTexture = LSM:Fetch("statusbar", rollFrame.timerBarTexture)
        or "Interface\\TargetingFrame\\UI-StatusBar"
    local fontPath, fontSize, fontOutline = GetFont()
    local iconSize = GetRollIconSize()

    for i = 1, MAX_VISIBLE_ROLLS do
        local frame = rollFramePool[i]
        if frame then
            -- Update backdrop
            ApplyBackdrop(frame)

            -- Update icon size
            frame.iconFrame:SetSize(iconSize, iconSize)

            -- Adjust frame height based on icon size
            frame:SetHeight(math.max(FRAME_BASE_HEIGHT, iconSize + 18))

            -- Update layout offsets for border thickness
            ApplyLayoutOffsets(frame)

            -- Update timer bar
            frame.timerBar:SetHeight(barHeight)
            frame.timerBar:SetStatusBarTexture(barTexture)

            -- Update fonts
            frame.itemName:SetFont(fontPath, fontSize, fontOutline)

            -- Update quality border
            if frame.rollID and frame:IsShown() then
                local _, _, _, quality = GetLootRollItemInfo(frame.rollID)
                if appearance.qualityBorder then
                    local r, g, b = GetQualityColor(quality)
                    frame.iconFrame.border:SetColorTexture(r, g, b, 0.8)
                    frame.iconFrame.border:Show()
                else
                    frame.iconFrame.border:Hide()
                end
            end
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

function ns.RollFrame.ShowTestRoll()
    if not anchorFrame then
        ns.RollFrame.Initialize()
    end

    -- Release any existing test rolls
    for i = 1, MAX_VISIBLE_ROLLS do
        local f = rollFramePool[i]
        if f and f.isTestMode then
            ReleaseRollFrame(i)
        end
    end

    -- First pass: acquire, populate, and show all frames (hidden alpha for animation)
    for i, testData in ipairs(TEST_ROLLS) do
        local frame = AcquireRollFrame(i)
        PopulateTestRollFrame(frame, testData)
        frame:SetAlpha(0)
        frame:Show()
    end

    -- Layout BEFORE animation so anchor points are set
    LayoutRollFrames()

    -- Second pass: animate entrance
    for i in ipairs(TEST_ROLLS) do
        local frame = rollFramePool[i]
        if frame then
            ns.RollAnimations.PlayShow(frame)
        end
    end

    -- Start countdown timers
    for i, testData in ipairs(TEST_ROLLS) do
        StartTestTimer(i, testData.duration)
    end

    ns.Print("Showing test roll frames.")
end
