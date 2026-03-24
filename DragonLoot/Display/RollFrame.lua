-------------------------------------------------------------------------------
-- RollFrame.lua
-- Loot roll frame replacement with timer bar and roll buttons
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

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
local HandleModifiedItemClick = HandleModifiedItemClick

local LSM = LibStub("LibSharedMedia-3.0")
local L = ns.L
local DU = ns.DisplayUtils

-------------------------------------------------------------------------------
-- Timer bar border helper
-------------------------------------------------------------------------------

local function ApplyTimerBarBorder(container)
    local db = ns.Addon.db.profile
    local rollCfg = db.rollFrame
    if rollCfg.timerBarBorder then
        container:SetBackdrop({
            edgeFile = DU.WHITE8x8,
            edgeSize = 1,
        })
        local c = rollCfg.timerBarBorderColor or { r = 0.3, g = 0.3, b = 0.3 }
        container:SetBackdropBorderColor(c.r, c.g, c.b, 0.8)
    else
        container:SetBackdrop(nil)
    end
end

local function ApplyTimerBarInset(bar, container)
    local hasBorder = ns.Addon.db.profile.rollFrame.timerBarBorder
    bar:ClearAllPoints()
    if hasBorder then
        bar:SetPoint("TOPLEFT", container, "TOPLEFT", 1, -1)
        bar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -1, 1)
    else
        bar:SetAllPoints(container)
    end
end

-------------------------------------------------------------------------------
-- Roll type constants (values used by RollOnLoot)
-------------------------------------------------------------------------------

local ROLL_PASS = 0
local ROLL_NEED = 1
local ROLL_GREED = 2
local ROLL_DISENCHANT = 3
local ROLL_TRANSMOG = 4

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

local MAX_VISIBLE_ROLLS = 4
local DEFAULT_ROLL_ANCHOR_Y = -200
local ROLL_FRAME_EXTRA_HEIGHT = 18
local TEST_ROLL_TICK_INTERVAL = 0.1

-------------------------------------------------------------------------------
-- Roll frame pool
-------------------------------------------------------------------------------

local rollFramePool = {}
local rollFrameCount = 0
local anchorFrame

-------------------------------------------------------------------------------
-- Backdrop and font wrappers (delegate to DisplayUtils)
-------------------------------------------------------------------------------

local function GetFont()
    return DU.GetFont(ns.Addon.db)
end

local function ApplyBackdrop(frame)
    DU.ApplyBackdrop(frame, ns.Addon.db)
end

local function GetRollIconSize()
    return ns.Addon.db.profile.appearance.rollIconSize or 36
end

local function GetFrameWidth()
    return ns.Addon.db.profile.rollFrame.frameWidth or 328
end

local function GetContentPadding()
    return ns.Addon.db.profile.rollFrame.contentPadding or 4
end

local function GetButtonSize()
    return ns.Addon.db.profile.rollFrame.buttonSize or 24
end

local function GetButtonSpacing()
    return ns.Addon.db.profile.rollFrame.buttonSpacing or 4
end

local function GetFrameSpacing()
    return ns.Addon.db.profile.rollFrame.frameSpacing or 4
end

local function GetRowSpacing()
    return ns.Addon.db.profile.rollFrame.rowSpacing or 4
end

local function GetTimerBarSpacing()
    return ns.Addon.db.profile.rollFrame.timerBarSpacing or 4
end

local function GetFrameMinHeight()
    return ns.Addon.db.profile.rollFrame.frameMinHeight or 68
end

local function GetTimerBarStyle()
    return ns.Addon.db.profile.rollFrame.timerBarStyle or "normal"
end

local function GetTimerBarMinimalHeight()
    return ns.Addon.db.profile.rollFrame.timerBarMinimalHeight or 3
end

local function ApplyTextLayoutOffsets(frame, compact, iconSize, padding, borderSize, rowSpacing)
    -- Item name top-left anchor (shared by both modes)
    frame.itemName:ClearAllPoints()
    frame.itemName:SetPoint("TOPLEFT", frame, "TOPLEFT",
        iconSize + padding + 6 + borderSize, -(padding + borderSize))

    if compact then
        -- Compact: buttons sit on the same row as the item name
        frame.passButton:ClearAllPoints()
        frame.passButton:SetPoint("RIGHT", frame, "RIGHT", -(padding + borderSize), 0)
        frame.passButton:SetPoint("TOP", frame.itemName, "TOP", 0, 0)

        -- Determine leftmost button
        local leftmostButton = frame.needButton
        if frame.transmogButton and frame.transmogButton:IsShown() then
            leftmostButton = frame.transmogButton
        end

        if frame.bindText:IsShown() then
            -- bindText sits to the left of the buttons
            frame.bindText:ClearAllPoints()
            frame.bindText:SetPoint("RIGHT", leftmostButton, "LEFT", -4, 0)
            frame.bindText:SetPoint("TOP", frame.itemName, "TOP", 0, 0)

            -- itemName fills remaining space, stopping before bindText
            frame.itemName:SetPoint("RIGHT", frame.bindText, "LEFT", -2, 0)
        else
            -- No BoP text; itemName extends directly to the leftmost button
            frame.itemName:SetPoint("RIGHT", leftmostButton, "LEFT", -4, 0)
        end
    else
        -- Normal: stacked rows
        frame.itemName:SetPoint("RIGHT", frame, "RIGHT", -(padding + borderSize), 0)

        frame.bindText:ClearAllPoints()
        frame.bindText:SetPoint("TOPLEFT", frame.itemName, "BOTTOMLEFT", 0, -rowSpacing)

        frame.passButton:ClearAllPoints()
        frame.passButton:SetPoint("TOPRIGHT", frame.itemName, "BOTTOMRIGHT", 0, -rowSpacing)
    end
end

local function ApplyTimerBarOffsets(frame, db, iconSize, padding, borderSize, timerBarSpacing)
    local timerBarAnchor = frame.timerBar.container or frame.timerBar
    timerBarAnchor:ClearAllPoints()

    if GetTimerBarStyle() == "minimal" then
        -- Minimal: full width at very bottom, thin bar, no text
        local minimalHeight = GetTimerBarMinimalHeight()
        timerBarAnchor:SetHeight(minimalHeight)
        timerBarAnchor:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", borderSize, borderSize)
        timerBarAnchor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize)
        frame.timerBar.text:Hide()
    else
        -- Normal: indented past icon, configurable height, text visible
        local barHeight = db.rollFrame.timerBarHeight or 12
        timerBarAnchor:SetHeight(barHeight)
        timerBarAnchor:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT",
            iconSize + padding + 6 + borderSize, timerBarSpacing + borderSize)
        timerBarAnchor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
            -(padding + 2 + borderSize), timerBarSpacing + borderSize)
        frame.timerBar.text:Show()
    end
end

local function ApplyLayoutOffsets(frame)
    local db = ns.Addon.db.profile
    local borderSize = db.appearance.borderSize or 1
    local iconSize = db.appearance.rollIconSize or 36
    local padding = GetContentPadding()
    local rowSpacing = GetRowSpacing()
    local timerBarSpacing = GetTimerBarSpacing()
    local compact = db.rollFrame.compactTextLayout

    -- Icon position (vertically centered on left)
    frame.iconFrame:ClearAllPoints()
    frame.iconFrame:SetPoint("LEFT", frame, "LEFT", padding + borderSize, 0)

    ApplyTextLayoutOffsets(frame, compact, iconSize, padding, borderSize, rowSpacing)
    ApplyTimerBarOffsets(frame, db, iconSize, padding, borderSize, timerBarSpacing)
end

-------------------------------------------------------------------------------
-- Timer bar color interpolation (green -> yellow -> red)
-------------------------------------------------------------------------------

local function GetTimerBarColor(timeLeft, rollTime)
    local db = ns.Addon.db.profile.rollFrame
    if db.timerBarColorMode == "custom" then
        local c = db.timerBarColor
        return c.r, c.g, c.b
    end

    -- Gradient: green -> yellow -> red
    if rollTime <= 0 then return 1, 0, 0 end
    local ratio = timeLeft / rollTime

    if ratio > 0.5 then
        local t = (ratio - 0.5) / 0.5
        return 1 - t, 1, 0
    else
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
        anchorFrame:SetPoint("TOP", UIParent, "TOP", 0, DEFAULT_ROLL_ANCHOR_Y)
    end
end

-------------------------------------------------------------------------------
-- Button click handler
-------------------------------------------------------------------------------

local function OnRollButtonClick(self)
    local frame = self:GetParent()
    if frame.isTestMode then
        ns.Print(L["Test roll: "] .. (ns.RollTypeNames[self.rollType] or L["Unknown"]))
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
    [ROLL_NEED] = L["Need"],
    [ROLL_GREED] = L["Greed"],
    [ROLL_DISENCHANT] = L["Disenchant"],
    [ROLL_PASS] = L["Pass"],
    [ROLL_TRANSMOG] = L["Transmog"],
}

local function OnRollButtonEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local label = ROLL_TOOLTIP_LABELS[self.rollType] or L["Roll"]
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
        GameTooltip:AddLine(frame.testItemName or L["Test Item"], 1, 1, 1)
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
        ns.Print(L["Test item: "] .. (frame.testItemName or L["Test Item"]))
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
    local btnSize = size or GetButtonSize()
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

    local iconSize = GetRollIconSize()
    local padding = GetContentPadding()
    local timerBarSpacing = GetTimerBarSpacing()

    -- Container frame owns the optional border
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetHeight(barHeight)
    container:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", iconSize + padding + 6, timerBarSpacing)
    container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -(padding + 2), timerBarSpacing)

    -- StatusBar fills the container (inset when border is enabled)
    local bar = CreateFrame("StatusBar", nil, container)
    ApplyTimerBarInset(bar, container)
    bar:SetStatusBarTexture(barTexture)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetStatusBarColor(0, 1, 0)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    local bgColor = db.rollFrame.timerBarBackgroundColor
    bar.bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, db.rollFrame.timerBarBackgroundAlpha)

    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar.text:SetTextColor(1, 1, 1)

    bar.container = container
    ApplyTimerBarBorder(container)

    return bar
end

-------------------------------------------------------------------------------
-- Create a single roll frame
-------------------------------------------------------------------------------

local function CreateRollFrame(index)
    rollFrameCount = rollFrameCount + 1
    local frameName = "DragonLootRoll" .. rollFrameCount

    local frame = CreateFrame("Frame", frameName, anchorFrame, "BackdropTemplate")
    frame:SetSize(GetFrameWidth(), GetFrameMinHeight())
    ApplyBackdrop(frame)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(110)
    frame:Hide()

    -- Item icon
    frame.iconFrame = CreateRollIcon(frame)

    -- Item name
    frame.itemName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.itemName:SetPoint("TOPLEFT", frame, "TOPLEFT", 42, -(5))
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
    frame.passButton:SetPoint("TOPRIGHT", frame.itemName, "BOTTOMRIGHT", 0, -4)

    frame.disenchantButton = CreateRollButton(frame, DE_ICON, ROLL_DISENCHANT)
    frame.disenchantButton:SetPoint("RIGHT", frame.passButton, "LEFT", -GetButtonSpacing(), 0)

    frame.greedButton = CreateRollButton(frame, GREED_ICON, ROLL_GREED)
    frame.greedButton:SetPoint("RIGHT", frame.disenchantButton, "LEFT", -GetButtonSpacing(), 0)

    frame.needButton = CreateRollButton(frame, NEED_ICON, ROLL_NEED)
    frame.needButton:SetPoint("RIGHT", frame.greedButton, "LEFT", -GetButtonSpacing(), 0)

    -- Transmog button - only functional on Retail where canTransmog is returned
    frame.transmogButton = CreateRollButton(frame, nil, ROLL_TRANSMOG, GetButtonSize())
    local success = pcall(function() frame.transmogButton.icon:SetAtlas("transmog-icon-small") end)
    if not success then
        frame.transmogButton.icon:SetTexture("Interface\\ICONS\\INV_Enchant_Disenchant")
    end
    frame.transmogButton:SetPoint("RIGHT", frame.needButton, "LEFT", -GetButtonSpacing(), 0)
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
        btn.disabledReason = reason or L["Not available for this item"]
    end
end

-------------------------------------------------------------------------------
-- Boundary parsing: normalize roll data into a RollData table
--
-- RollData = {
--     texture,           -- icon texture
--     name,              -- item name
--     count,             -- stack count
--     quality,           -- quality enum
--     bindOnPickUp,      -- boolean (BoP)
--     canNeed,           -- boolean
--     canGreed,          -- boolean
--     canDisenchant,     -- boolean
--     canTransmog,       -- boolean (nil on Classic)
--     reasonNeed,        -- string or nil
--     reasonGreed,       -- string or nil
--     reasonDisenchant,  -- string or nil
--     duration,          -- timer duration in seconds (test only)
-- }
-------------------------------------------------------------------------------

local function BuildRollData(rollID)
    local texture, name, count, quality, bindOnPickUp, canNeed, canGreed,
          canDisenchant, reasonNeed, reasonGreed, reasonDisenchant,
          _, canTransmog = GetLootRollItemInfo(rollID)

    if not texture then return nil end

    return {
        texture = texture,
        name = name or "",
        count = count,
        quality = quality,
        bindOnPickUp = bindOnPickUp or false,
        canNeed = canNeed or false,
        canGreed = canGreed or false,
        canDisenchant = canDisenchant or false,
        canTransmog = canTransmog or false,
        reasonNeed = reasonNeed,
        reasonGreed = reasonGreed,
        reasonDisenchant = reasonDisenchant,
        duration = nil,
    }
end

local function BuildTestRollData(testEntry)
    return {
        texture = testEntry.texture,
        name = testEntry.name,
        count = testEntry.count,
        quality = testEntry.quality,
        bindOnPickUp = testEntry.bindOnPickUp or false,
        canNeed = testEntry.canNeed ~= false,
        canGreed = testEntry.canGreed ~= false,
        canDisenchant = testEntry.canDisenchant or false,
        canTransmog = testEntry.canTransmog or false,
        reasonNeed = nil,
        reasonGreed = nil,
        reasonDisenchant = nil,
        duration = testEntry.duration,
    }
end

-------------------------------------------------------------------------------
-- Unified roll frame rendering (visual output identical for real and test data)
-------------------------------------------------------------------------------

local function RenderRollFrame(frame, data, rollID, isTest)
    local fontPath, fontSize, fontOutline = GetFont()
    local r, g, b = DU.GetQualityColor(data.quality)

    -- Resize icon to current config value
    local iconSize = GetRollIconSize()
    frame.iconFrame:SetSize(iconSize, iconSize)

    -- Adjust frame height based on icon size
    frame:SetHeight(math.max(GetFrameMinHeight(), iconSize + ROLL_FRAME_EXTRA_HEIGHT))

    -- Icon
    frame.iconFrame.icon:SetTexture(data.texture)

    -- Quality border
    if ns.Addon.db.profile.appearance.qualityBorder then
        frame.iconFrame.border:SetColorTexture(r, g, b, 0.8)
        frame.iconFrame.border:Show()
    else
        frame.iconFrame.border:Hide()
    end

    -- Item name
    frame.itemName:SetFont(fontPath, fontSize, fontOutline)
    DU.ApplyFontShadow(frame.itemName, ns.Addon.db)
    DU.ApplyFontShadow(frame.bindText, ns.Addon.db)
    DU.ApplyFontShadow(frame.timerBar.text, ns.Addon.db)
    frame.itemName:SetText(data.name)
    frame.itemName:SetTextColor(r, g, b)

    -- BoP indicator
    if data.bindOnPickUp then
        frame.bindText:SetText(L["BoP"])
        frame.bindText:Show()
    else
        frame.bindText:Hide()
    end

    -- Timer bar starts full
    frame.timerBar:SetMinMaxValues(0, 1)
    frame.timerBar:SetValue(1)
    local ir, ig, ib = GetTimerBarColor(1, 1)
    frame.timerBar:SetStatusBarColor(ir, ig, ib)
    if isTest and data.duration then
        frame.timerBar.text:SetText(string.format("%.0f", data.duration))
    else
        frame.timerBar.text:SetText("")
    end

    -- Count text on icon (for stackable items)
    if data.count and data.count > 1 then
        if not frame.iconFrame.count then
            frame.iconFrame.count = frame.iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            frame.iconFrame.count:SetPoint("BOTTOMRIGHT", frame.iconFrame, "BOTTOMRIGHT", 2, -2)
        end
        frame.iconFrame.count:SetText(data.count)
        frame.iconFrame.count:Show()
    elseif frame.iconFrame.count then
        frame.iconFrame.count:Hide()
    end

    -- Button states
    SetButtonState(frame.needButton, data.canNeed, data.reasonNeed)
    SetButtonState(frame.greedButton, data.canGreed, data.reasonGreed)
    SetButtonState(frame.disenchantButton, data.canDisenchant, data.reasonDisenchant)
    SetButtonState(frame.passButton, true, nil)

    if frame.transmogButton then
        if data.canTransmog then
            frame.transmogButton:Show()
            SetButtonState(frame.transmogButton, true, nil)
        else
            frame.transmogButton:Hide()
        end
    end

    -- Mode-specific frame state
    if isTest then
        frame.isTestMode = true
        frame.testItemName = data.name
        frame.testQuality = data.quality
        frame.rollID = nil
    else
        frame.isTestMode = false
        frame.testItemName = nil
        frame.testQuality = nil
        frame.rollID = rollID
    end

    -- Reposition children for current border thickness
    ApplyLayoutOffsets(frame)
end

-------------------------------------------------------------------------------
-- Populate a roll frame with item data
-------------------------------------------------------------------------------

local function PopulateRollFrame(frame, rollID)
    local data = BuildRollData(rollID)
    if not data then return end
    RenderRollFrame(frame, data, rollID, false)
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
            yOffset = yOffset + frame:GetHeight() + GetFrameSpacing()
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
    frame:SetSize(GetFrameWidth(), 1)
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
    local data = BuildTestRollData(testData)
    RenderRollFrame(frame, data, nil, true)
end

-------------------------------------------------------------------------------
-- Start test countdown timer for a single frame
-------------------------------------------------------------------------------

local function StartTestTimer(frameIndex, duration)
    local frame = rollFramePool[frameIndex]
    if not frame or not frame:IsShown() then return end

    local remaining = duration
    local total = duration

    frame.testTimer = C_Timer.NewTicker(TEST_ROLL_TICK_INTERVAL, function()
        remaining = remaining - TEST_ROLL_TICK_INTERVAL
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
        if GetTimerBarStyle() ~= "minimal" then
            frame.timerBar.text:SetText(string.format("%.0f", remaining))
        end
    end)
end

-------------------------------------------------------------------------------
-- Public Interface: ns.RollFrame
-------------------------------------------------------------------------------

function ns.RollFrame.Initialize()
    if anchorFrame then
        anchorFrame:Show()
        return
    end
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

    if GetTimerBarStyle() ~= "minimal" then
        bar.text:SetText(string.format("%.0f", timeLeft))
    end
end

function ns.RollFrame.ApplySettings()
    if not anchorFrame then return end
    local db = ns.Addon.db.profile
    if not db then return end

    local appearance = db.appearance or {}
    local rollFrame = db.rollFrame or {}

    anchorFrame:SetScale(rollFrame.scale or 1.0)
    anchorFrame:SetWidth(GetFrameWidth())

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

            -- Update frame width
            frame:SetWidth(GetFrameWidth())

            -- Update icon size
            frame.iconFrame:SetSize(iconSize, iconSize)

            -- Update button sizes
            local btnSize = GetButtonSize()
            frame.passButton:SetSize(btnSize, btnSize)
            frame.disenchantButton:SetSize(btnSize, btnSize)
            frame.greedButton:SetSize(btnSize, btnSize)
            frame.needButton:SetSize(btnSize, btnSize)
            if frame.transmogButton then
                frame.transmogButton:SetSize(btnSize, btnSize)
            end

            -- Adjust frame height based on icon size
            frame:SetHeight(math.max(GetFrameMinHeight(), iconSize + ROLL_FRAME_EXTRA_HEIGHT))

            -- Update layout offsets for border thickness
            ApplyLayoutOffsets(frame)

            -- Update timer bar
            frame.timerBar:SetStatusBarTexture(barTexture)

            -- Update timer bar container size and border
            if frame.timerBar.container then
                if GetTimerBarStyle() == "minimal" then
                    frame.timerBar.container:SetHeight(GetTimerBarMinimalHeight())
                else
                    frame.timerBar.container:SetHeight(barHeight)
                end
                ApplyTimerBarBorder(frame.timerBar.container)
                ApplyTimerBarInset(frame.timerBar, frame.timerBar.container)
            end

            -- Update timer bar background color
            local bgColor = db.rollFrame.timerBarBackgroundColor
            frame.timerBar.bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b,
                db.rollFrame.timerBarBackgroundAlpha)

            -- Update fonts
            frame.itemName:SetFont(fontPath, fontSize, fontOutline)
            DU.ApplyFontShadow(frame.itemName, ns.Addon.db)
            DU.ApplyFontShadow(frame.bindText, ns.Addon.db)
            DU.ApplyFontShadow(frame.timerBar.text, ns.Addon.db)

            -- Update quality border
            if frame.rollID and frame:IsShown() then
                local _, _, _, quality = GetLootRollItemInfo(frame.rollID)
                if appearance.qualityBorder then
                    local r, g, b = DU.GetQualityColor(quality)
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
    anchorFrame:SetPoint("TOP", UIParent, "TOP", 0, DEFAULT_ROLL_ANCHOR_Y)
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

    ns.Print(L["Showing test roll frames."])
end
