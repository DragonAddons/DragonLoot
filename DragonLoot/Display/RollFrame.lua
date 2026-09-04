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
local GameTooltip_ShowCompareItem = GameTooltip_ShowCompareItem
local GetCVarBool = GetCVarBool
local IsModifiedClick = IsModifiedClick
local ShoppingTooltip1 = ShoppingTooltip1
local ShoppingTooltip2 = ShoppingTooltip2
local UIParent = UIParent
local GetLootRollItemInfo = GetLootRollItemInfo
local GetLootRollItemLink = GetLootRollItemLink
local HandleModifiedItemClick = HandleModifiedItemClick
local C_Texture = C_Texture
local C_Item = C_Item
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local string_format = string.format
local math_floor = math.floor
local math_max = math.max

local LSM = LibStub("LibSharedMedia-3.0")
local L = ns.L
local DU = ns.DisplayUtils

-------------------------------------------------------------------------------
-- Safe config accessor
-------------------------------------------------------------------------------

local function GetRollFrameDB()
    return ns.Addon.db and ns.Addon.db.profile and ns.Addon.db.profile.rollFrame
end

-------------------------------------------------------------------------------
-- Timer bar border helper
-------------------------------------------------------------------------------

local function ApplyTimerBarBorder(container)
    local rollCfg = GetRollFrameDB()
    if not rollCfg then
        return
    end
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
    local db = GetRollFrameDB()
    local hasBorder = db and db.timerBarBorder
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
        texture = 132447, -- Gorehowl
        name = "Gorehowl",
        count = 1,
        quality = 4, -- Epic
        bindOnPickUp = true,
        canNeed = true,
        canGreed = true,
        canDisenchant = true,
        canTransmog = false,
        duration = 15,
    },
    {
        texture = 135506, -- Sunfury Bow of the Phoenix
        name = "Sunfury Bow of the Phoenix",
        count = 1,
        quality = 4, -- Epic
        bindOnPickUp = true,
        canNeed = true,
        canGreed = true,
        canDisenchant = true,
        canTransmog = false,
        duration = 20,
    },
    {
        texture = 133280, -- Blazefury, Reborn (fire sword icon)
        name = "Blazefury, Reborn",
        count = 1,
        quality = 4, -- Epic
        bindOnPickUp = true,
        canNeed = true,
        canGreed = false, -- Greed disabled when Transmog available
        canDisenchant = true,
        canTransmog = true,
        duration = 15,
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
local ROLL_TEXT_LEFT_GAP = 6 -- gap between icon right edge and text/timer-bar left
local ROLL_TIMER_RIGHT_GAP = 2 -- timer bar right inset from frame RIGHT edge
local TALLY_ROW_PADDING = 4 -- extra height the tally row adds on top of the font size
local TALLY_ENTRY_GAP = 6 -- horizontal gap between two tally entries
local TALLY_ICON_TEXT_GAP = 1 -- gap between a tally entry's icon and its count

-- Returns the left content inset (icon width + padding + text gap + border thickness).
-- Used by both ApplyTextLayoutOffsets and ApplyTimerBarOffsets to keep the left
-- edge of text and the timer bar aligned to the same column.
local function GetRollContentLeftInset(iconSize, padding, borderSize)
    local db = GetRollFrameDB()
    local iconPosition = db and db.iconPosition or "inside"
    local iconSide = db and db.iconSide or "left"
    if iconPosition == "outside" or iconSide == "right" then
        return padding + borderSize
    end
    return iconSize + padding + ROLL_TEXT_LEFT_GAP + borderSize
end

-- Returns the right content inset (reserves space for icon when inside-right).
-- Used by ApplyTextLayoutOffsets to prevent text/button overlap with the icon.
local function GetRollContentRightInset(iconSize, padding, borderSize)
    local db = GetRollFrameDB()
    local iconPosition = db and db.iconPosition or "inside"
    local iconSide = db and db.iconSide or "left"
    if iconPosition == "inside" and iconSide == "right" then
        return iconSize + padding + ROLL_TEXT_LEFT_GAP + borderSize
    end
    return padding + borderSize
end

-------------------------------------------------------------------------------
-- Roll frame pool
-------------------------------------------------------------------------------

local rollFramePool = {}
local rollFrameCount = 0
local anchorFrame
local loopTicker
local loopRollIndex = 0

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
    local db = GetRollFrameDB() or {}
    return db.frameWidth or 328
end

local function GetContentPadding()
    local db = GetRollFrameDB() or {}
    return db.contentPadding or 4
end

local function GetButtonSize()
    local db = GetRollFrameDB() or {}
    return db.buttonSize or 24
end

local function GetButtonSpacing()
    local db = GetRollFrameDB() or {}
    return db.buttonSpacing or 4
end

local function GetFrameSpacing()
    local db = GetRollFrameDB() or {}
    return db.frameSpacing or 4
end

local function GetRowSpacing()
    local db = GetRollFrameDB() or {}
    return db.rowSpacing or 4
end

local function GetTimerBarSpacing()
    local db = GetRollFrameDB() or {}
    return db.timerBarSpacing or 4
end

local function GetFrameMinHeight()
    local db = GetRollFrameDB() or {}
    return db.frameMinHeight or 68
end

local function GetTimerBarStyle()
    local db = GetRollFrameDB() or {}
    return db.timerBarStyle or "normal"
end

local function GetTimerBarMinimalHeight()
    local db = GetRollFrameDB() or {}
    return db.timerBarMinimalHeight or 3
end

-- Height the tally row currently claims at the bottom of a frame. Owned by the
-- frame itself so the layout helpers never have to ask whether the tally
-- feature is on; UpdateTally is the only writer.
local function GetFrameTallyHeight(frame)
    return (frame and frame.tallyRowHeight) or 0
end

local function CalculateFrameHeight(iconSize, frame)
    local db = ns.Addon.db.profile
    local rollFrameDB = GetRollFrameDB()
    if not rollFrameDB then
        return GetFrameMinHeight()
    end
    local tallyHeight = GetFrameTallyHeight(frame)
    local effectiveIconSize = (rollFrameDB.iconPosition == "outside") and 0 or iconSize
    if rollFrameDB.compactTextLayout then
        local padding = GetContentPadding()
        local borderSize = db.appearance.borderSize or 1
        local buttonSize = GetButtonSize()
        local timerBarSpacing = GetTimerBarSpacing()
        local timerBarHeight
        if GetTimerBarStyle() == "minimal" then
            timerBarHeight = GetTimerBarMinimalHeight()
        else
            timerBarHeight = (rollFrameDB.timerBarHeight or 12)
        end
        -- Content row must fit buttons or icon (inside only), whichever is taller
        local contentRow = math_max(buttonSize, effectiveIconSize)
        -- Top padding + content + spacing + timer bar + tally row + bottom padding
        local fromContent = (padding + borderSize)
            + contentRow
            + timerBarSpacing
            + timerBarHeight
            + tallyHeight
            + borderSize
        -- Icon must also fit (vertically centered) -- only relevant when inside
        local fromIcon = effectiveIconSize + (padding + borderSize) + borderSize
        return math_max(fromContent, fromIcon)
    end
    return math_max(GetFrameMinHeight(), effectiveIconSize + ROLL_FRAME_EXTRA_HEIGHT) + tallyHeight
end

local function ApplyTextLayoutOffsets(frame, compact, iconSize, padding, borderSize, rowSpacing)
    local contentLeftInset = GetRollContentLeftInset(iconSize, padding, borderSize)
    -- Item name top-left anchor (shared by both modes)
    frame.itemName:ClearAllPoints()
    frame.itemName:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeftInset, -(padding + borderSize))

    if compact then
        -- Compact: buttons sit on the same row as the item name
        frame.passButton:ClearAllPoints()
        frame.passButton:SetPoint(
            "RIGHT",
            frame,
            "RIGHT",
            -(GetRollContentRightInset(iconSize, padding, borderSize)),
            0
        )
        frame.passButton:SetPoint("TOP", frame, "TOP", 0, -(padding + borderSize))

        -- needButton is always the leftmost button (transmog occupies greed's slot to the right).
        local leftmostButton = frame.needButton

        if frame.bindText:IsShown() then
            -- bindText sits to the left of the buttons
            frame.bindText:ClearAllPoints()
            frame.bindText:SetPoint("RIGHT", leftmostButton, "LEFT", -4, 0)
            frame.bindText:SetPoint("TOP", frame, "TOP", 0, -(padding + borderSize))

            -- itemName fills remaining space, stopping before bindText
            frame.itemName:SetPoint("RIGHT", frame.bindText, "LEFT", -2, 0)
        else
            -- No BoP text; itemName extends directly to the leftmost button
            frame.itemName:SetPoint("RIGHT", leftmostButton, "LEFT", -4, 0)
        end
    else
        -- Normal: stacked rows
        frame.itemName:SetPoint("RIGHT", frame, "RIGHT", -(GetRollContentRightInset(iconSize, padding, borderSize)), 0)

        frame.bindText:ClearAllPoints()
        frame.bindText:SetPoint("TOPLEFT", frame.itemName, "BOTTOMLEFT", 0, -rowSpacing)

        frame.passButton:ClearAllPoints()
        frame.passButton:SetPoint("TOPRIGHT", frame.itemName, "BOTTOMRIGHT", 0, -rowSpacing)
    end
end

local function ApplyTimerBarOffsets(frame, rollFrameDB, iconSize, padding, borderSize, timerBarSpacing)
    local contentLeftInset = GetRollContentLeftInset(iconSize, padding, borderSize)
    local timerBarAnchor = frame.timerBar.container or frame.timerBar
    -- The tally row occupies the very bottom of the frame, so the timer bar
    -- floats above it by exactly that much whenever it is shown.
    local bottomInset = borderSize + GetFrameTallyHeight(frame)
    timerBarAnchor:ClearAllPoints()

    if GetTimerBarStyle() == "minimal" then
        -- Minimal: full width at very bottom, thin bar, no text
        local minimalHeight = GetTimerBarMinimalHeight()
        timerBarAnchor:SetHeight(minimalHeight)
        timerBarAnchor:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", borderSize, bottomInset)
        timerBarAnchor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, bottomInset)
        frame.timerBar.text:Hide()
    else
        -- Normal: indented past icon, configurable height, text visible
        local barHeight = (rollFrameDB and rollFrameDB.timerBarHeight) or 12
        timerBarAnchor:SetHeight(barHeight)
        timerBarAnchor:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", contentLeftInset, timerBarSpacing + bottomInset)
        timerBarAnchor:SetPoint(
            "BOTTOMRIGHT",
            frame,
            "BOTTOMRIGHT",
            -(padding + ROLL_TIMER_RIGHT_GAP + borderSize),
            timerBarSpacing + bottomInset
        )
        frame.timerBar.text:Show()
    end
end

local function ApplyTallyRowOffsets(frame, iconSize, padding, borderSize)
    local row = frame.tallyRow
    if not row then
        return
    end
    row:SetHeight(math_max(1, GetFrameTallyHeight(frame)))
    row:ClearAllPoints()
    row:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", GetRollContentLeftInset(iconSize, padding, borderSize), borderSize)
    row:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(padding + ROLL_TIMER_RIGHT_GAP + borderSize), borderSize)
end

local function ApplyLayoutOffsets(frame)
    local db = ns.Addon.db.profile
    local rollFrameDB = GetRollFrameDB()
    local borderSize = db.appearance.borderSize or 1
    local iconSize = db.appearance.rollIconSize or 36
    local padding = GetContentPadding()
    local rowSpacing = GetRowSpacing()
    local timerBarSpacing = GetTimerBarSpacing()
    local compact = rollFrameDB and rollFrameDB.compactTextLayout
    local iconPosition = (rollFrameDB and rollFrameDB.iconPosition) or "inside"
    local iconSide = (rollFrameDB and rollFrameDB.iconSide) or "left"
    local offsetX = (rollFrameDB and rollFrameDB.iconOffsetX) or 0
    local offsetY = (rollFrameDB and rollFrameDB.iconOffsetY) or 0
    local outsideGap = (rollFrameDB and rollFrameDB.iconOutsideGap) or 4

    -- Icon position (vertically centered by default, adjusted by offsetY).
    -- inset = padding + borderSize clears the backdrop border on both sides.
    local inset = padding + borderSize
    frame.iconFrame:ClearAllPoints()
    if iconPosition == "outside" then
        if iconSide == "right" then
            frame.iconFrame:SetPoint("LEFT", frame, "RIGHT", outsideGap + offsetX, offsetY)
        else
            frame.iconFrame:SetPoint("RIGHT", frame, "LEFT", -outsideGap + offsetX, offsetY)
        end
    else
        if iconSide == "right" then
            frame.iconFrame:SetPoint("RIGHT", frame, "RIGHT", -inset + offsetX, offsetY)
        else
            frame.iconFrame:SetPoint("LEFT", frame, "LEFT", inset + offsetX, offsetY)
        end
    end

    ApplyTextLayoutOffsets(frame, compact, iconSize, padding, borderSize, rowSpacing)
    ApplyTimerBarOffsets(frame, rollFrameDB, iconSize, padding, borderSize, timerBarSpacing)
    ApplyTallyRowOffsets(frame, iconSize, padding, borderSize)
end

-------------------------------------------------------------------------------
-- Timer bar color interpolation (green -> yellow -> red)
-------------------------------------------------------------------------------

local function GetTimerBarColor(timeLeft, rollTime)
    local db = GetRollFrameDB()
    if db and db.timerBarColorMode == "custom" then
        local c = db.timerBarColor
        return c.r, c.g, c.b
    end

    -- Gradient: green -> yellow -> red
    if rollTime <= 0 then
        return 1, 0, 0
    end
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
    if not anchorFrame then
        return
    end
    local db = GetRollFrameDB()
    if not db then
        return
    end
    local point, _, relativePoint, x, y = anchorFrame:GetPoint()
    if point then
        db.point = point
        db.relativePoint = relativePoint
        db.x = x
        db.y = y
    end
end

local function RestoreFramePosition()
    if not anchorFrame then
        return
    end
    local db = GetRollFrameDB()
    if not db then
        return
    end
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
        ns.RollManager.RequestRollSelection(frame.rollID, self.rollType)
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
-- Item comparison tooltip helpers
-------------------------------------------------------------------------------

local function ShowCompareItem(self)
    if not self._comparing then
        self._comparing = true
        GameTooltip_ShowCompareItem()
    end
end

local function HideCompareItem(self)
    if self._comparing then
        self._comparing = false
        if ShoppingTooltip1 then
            ShoppingTooltip1:Hide()
        end
        if ShoppingTooltip2 then
            ShoppingTooltip2:Hide()
        end
    end
end

local function ShouldShowCompareItem()
    return IsModifiedClick("COMPAREITEMS") or GetCVarBool("alwaysCompareItems")
end

local function OnIconCompareUpdate(self)
    if ShouldShowCompareItem() then
        -- Re-show if shopping tooltips were hidden externally (e.g. modifier state change)
        if self._comparing and ShoppingTooltip1 and not ShoppingTooltip1:IsShown() then
            self._comparing = false
        end
        ShowCompareItem(self)
    else
        HideCompareItem(self)
    end
end

-------------------------------------------------------------------------------
-- Icon tooltip handlers
-------------------------------------------------------------------------------

-- SetLootRollItem stops resolving once the client considers the roll answered,
-- so a frame held open after voting falls back to the item link RollManager
-- cached while the roll was still fresh.
local function SetRollItemTooltip(rollID)
    local roll = ns.RollManager.GetActiveRolls()[rollID]
    if roll and roll.heldAfterVote and roll.itemLink then
        GameTooltip:SetHyperlink(roll.itemLink)
        return
    end
    GameTooltip:SetLootRollItem(rollID)
end

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
        SetRollItemTooltip(frame.rollID)
        GameTooltip:Show()

        if ShouldShowCompareItem() then
            ShowCompareItem(self)
        end
        self:SetScript("OnUpdate", OnIconCompareUpdate)
    end
end

local function OnIconLeave(self)
    self:SetScript("OnUpdate", nil)
    HideCompareItem(self)
    GameTooltip:Hide()
end

local function OnIconClick(self, button)
    local frame = self:GetParent()
    if frame.isTestMode then
        ns.Print(L["Test item: "] .. (frame.testItemName or L["Test Item"]))
        return
    end
    if not frame.rollID then
        return
    end
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

    if texture then
        btn:SetHighlightTexture(texture, "ADD")
    end

    btn:SetScript("OnClick", OnRollButtonClick)
    btn:SetScript("OnEnter", OnRollButtonEnter)
    btn:SetScript("OnLeave", OnRollButtonLeave)

    return btn
end

-------------------------------------------------------------------------------
-- Create timer bar
-------------------------------------------------------------------------------

local function CreateTimerBar(parent)
    local rollFrameDB = GetRollFrameDB() or {}
    local barHeight = rollFrameDB.timerBarHeight or 12
    local barTexture = LSM:Fetch("statusbar", rollFrameDB.timerBarTexture) or "Interface\\TargetingFrame\\UI-StatusBar"

    -- Container (creation-time stubs; real position set by ApplyTimerBarOffsets)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetHeight(barHeight)
    container:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- StatusBar fills the container (inset when border is enabled)
    local bar = CreateFrame("StatusBar", nil, container)
    ApplyTimerBarInset(bar, container)
    bar:SetStatusBarTexture(barTexture)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetStatusBarColor(0, 1, 0)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    local bgColor = rollFrameDB.timerBarBackgroundColor or { r = 0.1, g = 0.1, b = 0.1 }
    bar.bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, rollFrameDB.timerBarBackgroundAlpha or 0.5)

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

    -- Drag: propagate movement to the shared anchor frame
    frame:EnableMouse(true)
    frame:SetMovable(false) -- frame itself doesn't move; anchor does
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function()
        local db = GetRollFrameDB()
        if db and not db.lock and anchorFrame then
            anchorFrame:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function()
        if anchorFrame then
            anchorFrame:StopMovingOrSizing()
            SaveFramePosition()
        end
    end)

    -- Item icon
    frame.iconFrame = CreateRollIcon(frame)

    -- Item name (creation-time stub; real position set by ApplyLayoutOffsets)
    frame.itemName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.itemName:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
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
    -- Use Blizzard's loot roll transmog atlas; fall back to disenchant icon if atlas missing (Classic)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("lootroll-toast-icon-transmog-up") then
        frame.transmogButton.icon:SetAtlas("lootroll-toast-icon-transmog-up")
        frame.transmogButton:SetHighlightAtlas("lootroll-toast-icon-transmog-up", "ADD")
        local hl = frame.transmogButton:GetHighlightTexture()
        hl:ClearAllPoints()
        hl:SetAllPoints(frame.transmogButton.icon)
    else
        frame.transmogButton.icon:SetTexture("Interface\\ICONS\\INV_Enchant_Disenchant")
        frame.transmogButton:SetHighlightTexture("Interface\\ICONS\\INV_Enchant_Disenchant", "ADD")
    end
    frame.transmogButton:Hide()

    frame.frameIndex = index
    frame.tallyRowHeight = 0
    return frame
end

-------------------------------------------------------------------------------
-- Configure roll button state (enabled/disabled with reason)
-------------------------------------------------------------------------------

local function SetButtonState(btn, canUse, reason)
    if not btn then
        return
    end
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
-- Configure roll button state for a frame held open after voting
-------------------------------------------------------------------------------

local VOTED_UNCHOSEN_ALPHA = 0.25

-- The chosen button keeps full colour so the player can read their own choice
-- off a frame that no longer accepts input; every button locks so a held-open
-- frame cannot be voted on twice.
local function SetVotedButtonState(btn, isChosen)
    if not btn then
        return
    end
    btn:Disable()
    btn.icon:SetDesaturated(not isChosen)
    btn.icon:SetAlpha(isChosen and 1 or VOTED_UNCHOSEN_ALPHA)
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
    -- stylua: ignore
    local texture, name, count, quality, bindOnPickUp, canNeed, canGreed, canDisenchant,
        reasonNeed, reasonGreed, reasonDisenchant, _, canTransmog =
        GetLootRollItemInfo(rollID)

    if not texture then
        return nil
    end

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
-- Re-anchor the roll button chain based on current greed/transmog visibility.
-- When transmog is shown (greed's slot), the chain is:
--   need <- transmog <- disenchant <- pass
-- When greed is shown (normal), the chain is:
--   need <- greed <- disenchant <- pass
-------------------------------------------------------------------------------

local function RebuildButtonChain(frame)
    local btnSpacing = GetButtonSpacing()
    -- disenchant always anchors off pass
    frame.disenchantButton:ClearAllPoints()
    frame.disenchantButton:SetPoint("RIGHT", frame.passButton, "LEFT", -btnSpacing, 0)

    -- greed/transmog share the slot between disenchant and need
    -- transmogButton is always created in CreateRollFrame; nil guard is unnecessary.
    -- IsShown() (not IsVisible()) is intentional: parent frame may be hidden,
    -- but we need to know whether transmog was set for this roll's data.
    if frame.transmogButton:IsShown() then
        -- transmog occupies greed's slot
        frame.transmogButton:ClearAllPoints()
        frame.transmogButton:SetPoint("RIGHT", frame.disenchantButton, "LEFT", -btnSpacing, 0)
        frame.needButton:ClearAllPoints()
        frame.needButton:SetPoint("RIGHT", frame.transmogButton, "LEFT", -btnSpacing, 0)
    else
        -- greed in its normal slot
        frame.greedButton:ClearAllPoints()
        frame.greedButton:SetPoint("RIGHT", frame.disenchantButton, "LEFT", -btnSpacing, 0)
        frame.needButton:ClearAllPoints()
        frame.needButton:SetPoint("RIGHT", frame.greedButton, "LEFT", -btnSpacing, 0)
    end
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
    frame:SetHeight(CalculateFrameHeight(iconSize, frame))

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
    frame.bindText:SetFont(fontPath, fontSize, fontOutline)
    frame.timerBar.text:SetFont(fontPath, fontSize, fontOutline)
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

    -- Item level overlay on icon (bottom-left corner)
    if ns.Addon.db.profile.appearance.showItemLevel and not isTest then
        local link = GetLootRollItemLink(rollID)
        local ilvl = link and C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(link)
        if not frame.iconFrame.ilvl then
            frame.iconFrame.ilvl = frame.iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            frame.iconFrame.ilvl:SetPoint("BOTTOMLEFT", frame.iconFrame, "BOTTOMLEFT", 2, 2)
        end
        if ilvl then
            frame.iconFrame.ilvl:SetText(ilvl)
            frame.iconFrame.ilvl:Show()
        else
            -- Item data not cached yet; retry after a short delay
            frame.iconFrame.ilvl:Hide()
            local capturedRollID = rollID
            C_Timer.After(0.5, function()
                if not frame or not frame:IsShown() then
                    return
                end
                if frame.rollID ~= capturedRollID then
                    return
                end
                local retryLink = GetLootRollItemLink(capturedRollID)
                local retryIlvl = retryLink
                    and C_Item
                    and C_Item.GetDetailedItemLevelInfo
                    and C_Item.GetDetailedItemLevelInfo(retryLink)
                if retryIlvl and frame.iconFrame.ilvl then
                    frame.iconFrame.ilvl:SetText(retryIlvl)
                    frame.iconFrame.ilvl:Show()
                end
            end)
        end
    elseif frame.iconFrame.ilvl then
        frame.iconFrame.ilvl:Hide()
    end

    -- Button states
    SetButtonState(frame.needButton, data.canNeed, data.reasonNeed)
    SetButtonState(frame.greedButton, data.canGreed, data.reasonGreed)
    SetButtonState(frame.disenchantButton, data.canDisenchant, data.reasonDisenchant)
    SetButtonState(frame.passButton, true, nil)

    -- Toggle transmog/greed visibility and rebuild the button chain accordingly.
    -- transmogButton is always created; when canTransmog is true it occupies greed's slot.
    if data.canTransmog then
        frame.transmogButton:Show()
        SetButtonState(frame.transmogButton, true, nil)
        -- Match Blizzard: Transmog replaces Greed
        frame.greedButton:Hide()
    else
        frame.transmogButton:Hide()
        frame.greedButton:Show()
    end
    RebuildButtonChain(frame)

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
    if not data then
        return
    end
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
-- Roll tally row
--
-- A compact strip at the bottom of the frame: one small icon + count per roll
-- type on the right, and the winner / own-roll overview on the left once the
-- roll has resolved. Populated exclusively by ns.RollFrame.UpdateTally.
-------------------------------------------------------------------------------

local TALLY_ROLL_TYPE_ORDER = { ROLL_NEED, ROLL_GREED, ROLL_DISENCHANT, ROLL_PASS }

local TALLY_ROLL_TYPE_ICONS = {
    [ROLL_NEED] = NEED_ICON,
    [ROLL_GREED] = GREED_ICON,
    [ROLL_DISENCHANT] = DE_ICON,
    [ROLL_PASS] = PASS_ICON,
}

-- Single source for the tally's text metric: row height and icon size are
-- derived from it, so they cannot drift apart.
local function GetTallyFontSize()
    return ns.Addon.db.profile.appearance.fontSize or 12
end

local function GetTallyRowHeight()
    return GetTallyFontSize() + TALLY_ROW_PADDING
end

-- Entry icons are squared to the text height so the strip reads as one line.
local function GetTallyIconSize()
    return GetTallyFontSize()
end

local function CreateTallyRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(1)
    row.entries = {}

    row.resultText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.resultText:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.resultText:SetJustifyH("LEFT")
    row.resultText:SetWordWrap(false)

    row:Hide()
    return row
end

local function AcquireTallyEntry(row, index)
    local entry = row.entries[index]
    if entry then
        return entry
    end
    entry = {
        icon = row:CreateTexture(nil, "ARTWORK"),
        text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"),
    }
    row.entries[index] = entry
    return entry
end

local function ApplyTallyAppearance(frame)
    local row = frame.tallyRow
    if not row then
        return
    end
    local fontPath, fontSize, fontOutline = GetFont()
    local iconSize = GetTallyIconSize()
    row.resultText:SetFont(fontPath, fontSize, fontOutline)
    DU.ApplyFontShadow(row.resultText, ns.Addon.db)
    for _, entry in ipairs(row.entries) do
        entry.text:SetFont(fontPath, fontSize, fontOutline)
        DU.ApplyFontShadow(entry.text, ns.Addon.db)
        entry.icon:SetSize(iconSize, iconSize)
    end
end

-- Ordered list of { texture, label } strips. Roll types the group has not
-- picked at all are omitted so the strip stays as short as the data allows;
-- players who have not answered yet share one trailing text-only "?" entry.
local function BuildTallyEntries(view)
    local entries = {}
    for _, rollType in ipairs(TALLY_ROLL_TYPE_ORDER) do
        local count = view.counts and view.counts[rollType]
        if count and count > 0 then
            entries[#entries + 1] = { texture = TALLY_ROLL_TYPE_ICONS[rollType], label = tostring(count) }
        end
    end
    if view.pending and view.pending > 0 then
        entries[#entries + 1] = { label = "?" .. view.pending }
    end
    return entries
end

-- Positions only; icon sizing and fonts belong to ApplyTallyAppearance.
local function LayoutTallyEntries(row, entries)
    -- Anchored right-to-left so the strip always hugs the frame's bottom-right.
    local previous
    for i = #entries, 1, -1 do
        local entry = entries[i]
        local widget = AcquireTallyEntry(row, i)

        widget.text:SetText(entry.label)
        widget.text:ClearAllPoints()
        if previous then
            widget.text:SetPoint("RIGHT", previous, "LEFT", -TALLY_ENTRY_GAP, 0)
        else
            widget.text:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        end
        widget.text:Show()

        widget.icon:ClearAllPoints()
        if entry.texture then
            widget.icon:SetTexture(entry.texture)
            widget.icon:SetPoint("RIGHT", widget.text, "LEFT", -TALLY_ICON_TEXT_GAP, 0)
            widget.icon:Show()
            previous = widget.icon
        else
            widget.icon:Hide()
            previous = widget.text
        end
    end

    for i = #entries + 1, #row.entries do
        row.entries[i].icon:Hide()
        row.entries[i].text:Hide()
    end

    -- Bound the non-wrapping result text against the leftmost entry so a long
    -- winner name truncates instead of drawing over the strip. Re-anchored on
    -- every layout because the bounding widget changes as entries come and go.
    row.resultText:ClearAllPoints()
    row.resultText:SetPoint("LEFT", row, "LEFT", 0, 0)
    if previous then
        row.resultText:SetPoint("RIGHT", previous, "LEFT", -TALLY_ENTRY_GAP, 0)
    end
end

local function ColorizePlayerName(name, class)
    local r, g, b = 0.7, 0.7, 0.7
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local cc = RAID_CLASS_COLORS[class]
        r, g, b = cc.r, cc.g, cc.b
    end
    return string_format(
        "|cff%02x%02x%02x%s|r",
        math_floor(r * 255 + 0.5),
        math_floor(g * 255 + 0.5),
        math_floor(b * 255 + 0.5),
        name
    )
end

local function FormatRollChoice(rollType, rollValue)
    local label = ns.RollTypeNames[rollType] or L["Unknown"]
    if rollValue then
        return label .. " " .. rollValue
    end
    return label
end

local function FormatResultText(result)
    local text = ColorizePlayerName(result.winnerName, result.winnerClass)
        .. " "
        .. FormatRollChoice(result.winnerRollType, result.winnerRoll)
    if result.selfRoll then
        text = text
            .. "  "
            .. ns.COLOR_GRAY
            .. L["You"]
            .. ns.COLOR_RESET
            .. " "
            .. FormatRollChoice(result.selfRollType, result.selfRoll)
    end
    return text
end

-- Re-runs the layout pass that depends on the tally row's height, then restacks
-- the visible frames because this frame just grew or shrank.
local function RelayoutForTallyRow(frame)
    frame:SetHeight(CalculateFrameHeight(GetRollIconSize(), frame))
    ApplyLayoutOffsets(frame)
    LayoutRollFrames()
end

local function HideTallyRow(frame)
    if not frame.tallyRow or frame.tallyRowHeight == 0 then
        return
    end
    frame.tallyRow:Hide()
    frame.tallyRowHeight = 0
    RelayoutForTallyRow(frame)
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
    if not frame then
        return
    end
    if frame.testTimer then
        frame.testTimer:Cancel()
        frame.testTimer = nil
    end
    frame.isTestMode = false
    frame.testItemName = nil
    frame.testQuality = nil
    frame.rollID = nil
    frame.iconFrame._comparing = nil
    frame.iconFrame:SetScript("OnUpdate", nil)
    HideTallyRow(frame)
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
        local db = GetRollFrameDB()
        if db and not db.lock then
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
    if not frame or not frame:IsShown() then
        return
    end

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
-- Spawn a single random test roll into the next available slot
-------------------------------------------------------------------------------

local function SpawnOneTestRoll()
    local freeIndex
    for i = 1, MAX_VISIBLE_ROLLS do
        local f = rollFramePool[i]
        if not f or not f:IsShown() then
            freeIndex = i
            break
        end
    end
    if not freeIndex then
        return
    end

    loopRollIndex = loopRollIndex + 1
    local testData = TEST_ROLLS[((loopRollIndex - 1) % #TEST_ROLLS) + 1]

    local frame = AcquireRollFrame(freeIndex)
    PopulateTestRollFrame(frame, testData)
    frame:SetAlpha(0)
    frame:Show()
    LayoutRollFrames()
    ns.RollAnimations.PlayShow(frame)

    local duration = 8 + math.random() * 12
    StartTestTimer(freeIndex, duration)
end

-- Returns the vertical component of a WoW anchor point string (strips LEFT/RIGHT).
-- Used by CenterHorizontally to normalize the saved anchor before zeroing x.
local function VerticalComponent(p)
    if p:find("TOP") then
        return "TOP"
    elseif p:find("BOTTOM") then
        return "BOTTOM"
    else
        return "CENTER"
    end
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
    if not anchorFrame then
        return
    end
    ns.RollFrame.HideAllRolls()
    anchorFrame:Hide()
    ns.DebugPrint("RollFrame shut down")
end

function ns.RollFrame.ShowRoll(frameIndex, rollID)
    if not anchorFrame then
        return
    end

    local frame = AcquireRollFrame(frameIndex)
    PopulateRollFrame(frame, rollID)

    -- Show and layout BEFORE animation so anchor points are set
    frame:SetAlpha(0)
    frame:Show()
    LayoutRollFrames()

    ns.RollAnimations.PlayShow(frame)
end

--- Switch a visible roll frame into its "voted, awaiting result" state.
--- @param frameIndex number Pool index of the frame to update
--- @param rollType number The roll type the local player chose
function ns.RollFrame.MarkVoted(frameIndex, rollType)
    local frame = rollFramePool[frameIndex]
    if not frame or not frame:IsShown() then
        return
    end

    SetVotedButtonState(frame.needButton, rollType == ROLL_NEED)
    SetVotedButtonState(frame.greedButton, rollType == ROLL_GREED)
    SetVotedButtonState(frame.disenchantButton, rollType == ROLL_DISENCHANT)
    SetVotedButtonState(frame.transmogButton, rollType == ROLL_TRANSMOG)
    SetVotedButtonState(frame.passButton, rollType == ROLL_PASS)
end

--- Render, or remove, the group vote tally and result overview on a roll frame.
--- @param frameIndex number Pool index of the frame to update
--- @param view table|nil Tally view built by ns.RollTally, shaped as
---        { counts = { [rollType] = count }, pending = number, result = table|nil }.
---        Pass nil to remove the tally row and shrink the frame back.
function ns.RollFrame.UpdateTally(frameIndex, view)
    local frame = rollFramePool[frameIndex]
    if not frame then
        return
    end
    if not view then
        HideTallyRow(frame)
        return
    end

    -- Nothing to say yet: no group member has been reported and no winner is
    -- known. Claim no space rather than reserving an empty strip.
    local entries = BuildTallyEntries(view)
    if #entries == 0 and not view.result then
        HideTallyRow(frame)
        return
    end

    frame.tallyRow = frame.tallyRow or CreateTallyRow(frame)

    LayoutTallyEntries(frame.tallyRow, entries)
    frame.tallyRow.resultText:SetText(view.result and FormatResultText(view.result) or "")
    ApplyTallyAppearance(frame)
    frame.tallyRow:Show()

    local rowHeight = GetTallyRowHeight()
    if frame.tallyRowHeight ~= rowHeight then
        frame.tallyRowHeight = rowHeight
        RelayoutForTallyRow(frame)
    end
end

function ns.RollFrame.HideRoll(frameIndex, onComplete)
    local frame = rollFramePool[frameIndex]
    if not frame or not frame:IsShown() then
        ReleaseRollFrame(frameIndex)
        if onComplete then
            onComplete()
        end
        return
    end

    ns.RollAnimations.StopAll(frame)
    ns.RollAnimations.PlayHide(frame, function()
        ReleaseRollFrame(frameIndex)
        LayoutRollFrames()
        if onComplete then
            onComplete()
        end
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
    if not frame or not frame:IsShown() then
        return
    end

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
    if not anchorFrame then
        return
    end
    local db = ns.Addon.db.profile
    if not db then
        return
    end

    local appearance = db.appearance or {}
    local rollFrame = db.rollFrame or {}

    anchorFrame:SetScale(rollFrame.scale or 1.0)
    anchorFrame:SetWidth(GetFrameWidth())

    local barHeight = rollFrame.timerBarHeight or 12
    local barTexture = LSM:Fetch("statusbar", rollFrame.timerBarTexture) or "Interface\\TargetingFrame\\UI-StatusBar"
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
            frame.transmogButton:SetSize(btnSize, btnSize) -- always created in CreateRollFrame

            -- Re-anchor button chain based on current greed/transmog IsShown() state.
            -- Safe on unrendered frames: greedButton defaults to shown,
            -- transmogButton defaults to hidden, matching CreateRollFrame state.
            RebuildButtonChain(frame)

            -- Refresh the tally row's height first: the frame height and every
            -- bottom-anchored offset below depend on it.
            if frame.tallyRow and frame.tallyRow:IsShown() then
                frame.tallyRowHeight = GetTallyRowHeight()
                ApplyTallyAppearance(frame)
            end

            -- Adjust frame height based on icon size
            frame:SetHeight(CalculateFrameHeight(iconSize, frame))

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
            local bgColor = rollFrame.timerBarBackgroundColor or { r = 0.1, g = 0.1, b = 0.1 }
            frame.timerBar.bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, rollFrame.timerBarBackgroundAlpha or 0.5)

            -- Update fonts
            frame.itemName:SetFont(fontPath, fontSize, fontOutline)
            frame.bindText:SetFont(fontPath, fontSize, fontOutline)
            frame.timerBar.text:SetFont(fontPath, fontSize, fontOutline)
            DU.ApplyFontShadow(frame.itemName, ns.Addon.db)
            DU.ApplyFontShadow(frame.bindText, ns.Addon.db)
            DU.ApplyFontShadow(frame.timerBar.text, ns.Addon.db)

            -- RollManager's cache is the reliable source of item data for a
            -- frame still on screen: GetLootRollItemInfo and GetLootRollItemLink
            -- both stop answering once the player has voted, which a held-open
            -- frame outlives.
            local activeRoll = frame.rollID and ns.RollManager.GetActiveRolls()[frame.rollID]

            -- Update quality border
            if frame.rollID and frame:IsShown() then
                if appearance.qualityBorder then
                    local r, g, b = DU.GetQualityColor(activeRoll and activeRoll.itemQuality)
                    frame.iconFrame.border:SetColorTexture(r, g, b, 0.8)
                    frame.iconFrame.border:Show()
                else
                    frame.iconFrame.border:Hide()
                end
            end

            -- Update item level overlay visibility
            if frame.iconFrame.ilvl then
                if appearance.showItemLevel and frame.rollID and frame:IsShown() then
                    local link = (activeRoll and activeRoll.itemLink) or GetLootRollItemLink(frame.rollID)
                    local ilvl = link
                        and C_Item
                        and C_Item.GetDetailedItemLevelInfo
                        and C_Item.GetDetailedItemLevelInfo(link)
                    if ilvl then
                        frame.iconFrame.ilvl:SetText(ilvl)
                        frame.iconFrame.ilvl:Show()
                    else
                        frame.iconFrame.ilvl:Hide()
                    end
                else
                    frame.iconFrame.ilvl:Hide()
                end
            end
        end
    end

    LayoutRollFrames()
end

function ns.RollFrame.ResetAnchor()
    if not anchorFrame then
        return
    end
    local db = GetRollFrameDB()
    if not db then
        return
    end
    db.point = nil
    db.relativePoint = nil
    db.x = nil
    db.y = nil
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint("TOP", UIParent, "TOP", 0, DEFAULT_ROLL_ANCHOR_Y)
end

function ns.RollFrame.CenterHorizontally()
    if not anchorFrame then
        return
    end
    local db = GetRollFrameDB()
    if not db then
        return
    end
    local y = db.y or DEFAULT_ROLL_ANCHOR_Y
    -- Normalize anchor to strip any LEFT/RIGHT component so x=0 truly centers
    local newPoint = VerticalComponent(db.point or "TOP")
    local newRelPoint = VerticalComponent(db.relativePoint or "TOP")
    db.point = newPoint
    db.relativePoint = newRelPoint
    db.x = 0
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint(newPoint, UIParent, newRelPoint, 0, y)
    SaveFramePosition()
end

function ns.RollFrame.CenterVertically()
    if not anchorFrame then
        return
    end
    local db = GetRollFrameDB()
    if not db then
        return
    end
    local x = db.x or 0
    -- Normalize anchor to CENTER/CENTER so y=0 is truly vertical center
    db.point = "CENTER"
    db.relativePoint = "CENTER"
    db.y = 0
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", x, 0)
    SaveFramePosition()
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

function ns.RollFrame.ShowTestRollLoop()
    if loopTicker then
        ns.RollFrame.StopTestRollLoop()
        return
    end

    if not anchorFrame then
        ns.RollFrame.Initialize()
    end

    SpawnOneTestRoll()

    loopTicker = C_Timer.NewTicker(4, function()
        SpawnOneTestRoll()
    end)

    ns.Print(L["Test roll loop started. Type /dl testroll stop to end."])
end

function ns.RollFrame.StopTestRollLoop()
    if loopTicker then
        loopTicker:Cancel()
        loopTicker = nil
    end

    for i = 1, MAX_VISIBLE_ROLLS do
        local f = rollFramePool[i]
        if f and f.isTestMode then
            if f.testTimer then
                f.testTimer:Cancel()
                f.testTimer = nil
            end
            ReleaseRollFrame(i)
        end
    end
    LayoutRollFrames()

    loopRollIndex = 0
    ns.Print(L["Test roll loop stopped."])
end
