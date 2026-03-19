-------------------------------------------------------------------------------
-- HistoryFrame.lua
-- Loot history display with scrollable list of recent loot events
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
local GetTime = GetTime
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local HandleModifiedItemClick = HandleModifiedItemClick
local IsShiftKeyDown = IsShiftKeyDown
local math_floor = math.floor
local string_format = string.format
local tostring = tostring

local L = ns.L
local DU = ns.DisplayUtils


-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FRAME_WIDTH = 350
local FRAME_HEIGHT = 400
local TITLE_BAR_HEIGHT = 24
local SCROLL_STEP = 3
local SCROLLBAR_WIDTH = 14
local SCROLLBAR_GAP = 2
local DEFAULT_HISTORY_X_OFFSET = 200
local SCROLLBAR_THUMB_HEIGHT = 30
local TIME_REFRESH_INTERVAL = 10
local DETAIL_ROW_HEIGHT = 16
local DETAIL_PADDING = 4

local function GetEntrySpacing()
    return ns.Addon.db.profile.history.entrySpacing or 2
end

local function GetContentPadding()
    return ns.Addon.db.profile.history.contentPadding or 6
end

-------------------------------------------------------------------------------
-- Frame references
-------------------------------------------------------------------------------

local containerFrame
local scrollFrame
local scrollChild
local scrollBar

-------------------------------------------------------------------------------
-- Entry frame pool
-------------------------------------------------------------------------------

local entryPool = {}
local entryCount = 0
local activeEntries = {}
local expandedEntries = {}
local detailRowPool = {}

-------------------------------------------------------------------------------
-- History data (populated by listeners)
-------------------------------------------------------------------------------

ns.historyData = {}

-- Forward declaration for RefreshHistory (used by OnEntryClick)
local RefreshHistory

-------------------------------------------------------------------------------
-- Backdrop and font wrappers (delegate to DisplayUtils)
-------------------------------------------------------------------------------

local function GetFont()
    return DU.GetFont(ns.Addon.db)
end

local function ApplyBackdrop(frame)
    DU.ApplyBackdrop(frame, ns.Addon.db)
end

local function GetHistoryIconSize()
    return ns.Addon.db.profile.appearance.historyIconSize or 24
end

local function GetEntryHeight()
    return GetHistoryIconSize() + 6
end

local function ApplyLayoutOffsets(frame)
    local borderSize = ns.Addon.db.profile.appearance.borderSize or 1
    local padding = GetContentPadding()

    -- Title bar spans across the top, inset by border
    local titleBar = frame.titleBar
    titleBar:ClearAllPoints()
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", borderSize, -borderSize)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -borderSize, -borderSize)

    -- Scroll frame and scrollbar insets
    if scrollFrame then
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT",
            padding + borderSize, -(TITLE_BAR_HEIGHT + padding + borderSize))
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
            -(padding + SCROLLBAR_WIDTH + SCROLLBAR_GAP + borderSize), padding + borderSize)
    end
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT",
            -(padding + borderSize), -(TITLE_BAR_HEIGHT + padding + borderSize))
        scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
            -(padding + borderSize), padding + borderSize)
    end
end

-------------------------------------------------------------------------------
-- Class color helper
-------------------------------------------------------------------------------

local function GetClassColor(class)
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local cc = RAID_CLASS_COLORS[class]
        return cc.r, cc.g, cc.b
    end
    return 0.7, 0.7, 0.7
end

-------------------------------------------------------------------------------
-- Roll type text helper
-------------------------------------------------------------------------------

local function GetRollTypeText(rollType)
    return ns.RollTypeNames[rollType] or ""
end

-------------------------------------------------------------------------------
-- Time formatting helper
-------------------------------------------------------------------------------

local function FormatTimeAgo(timestamp)
    if not timestamp then return "" end
    local elapsed = GetTime() - timestamp
    if elapsed < 0 then elapsed = 0 end

    if elapsed < 60 then
        return string_format(L["%ds ago"], math_floor(elapsed))
    elseif elapsed < 3600 then
        return string_format(L["%dm ago"], math_floor(elapsed / 60))
    else
        return string_format(L["%dh ago"], math_floor(elapsed / 3600))
    end
end

-------------------------------------------------------------------------------
-- Entry frame creation
-------------------------------------------------------------------------------

local function CreateEntryFrame()
    entryCount = entryCount + 1
    local frameName = "DragonLootHistoryEntry" .. entryCount

    local entry = CreateFrame("Button", frameName, scrollChild)
    local entryHeight = GetEntryHeight()
    entry:SetHeight(entryHeight)
    entry:EnableMouse(true)
    entry:RegisterForClicks("LeftButtonUp")

    -- Icon
    entry.icon = entry:CreateTexture(nil, "ARTWORK")
    local iconSize = GetHistoryIconSize()
    entry.icon:SetSize(iconSize, iconSize)
    entry.icon:SetPoint("LEFT", entry, "LEFT", 2, 0)
    entry.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Icon border
    entry.iconBorder = entry:CreateTexture(nil, "OVERLAY")
    entry.iconBorder:SetPoint("TOPLEFT", entry.icon, "TOPLEFT", -1, 1)
    entry.iconBorder:SetPoint("BOTTOMRIGHT", entry.icon, "BOTTOMRIGHT", 1, -1)
    entry.iconBorder:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    entry.icon:SetDrawLayer("OVERLAY", 1)

    -- Item name
    entry.itemName = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.itemName:SetPoint("TOPLEFT", entry.icon, "TOPRIGHT", 4, -1)
    entry.itemName:SetPoint("RIGHT", entry, "RIGHT", -60, 0)
    entry.itemName:SetJustifyH("LEFT")
    entry.itemName:SetWordWrap(false)

    -- Winner name
    entry.winnerName = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.winnerName:SetPoint("BOTTOMLEFT", entry.icon, "BOTTOMRIGHT", 4, 1)
    entry.winnerName:SetJustifyH("LEFT")
    entry.winnerName:SetWordWrap(false)

    -- Roll info (e.g. "Need 87")
    entry.rollInfo = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.rollInfo:SetPoint("LEFT", entry.winnerName, "RIGHT", 6, 0)
    entry.rollInfo:SetJustifyH("LEFT")
    entry.rollInfo:SetTextColor(0.8, 0.8, 0.8)

    -- Time text
    entry.timeText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.timeText:SetPoint("RIGHT", entry, "RIGHT", -4, 0)
    entry.timeText:SetJustifyH("RIGHT")
    entry.timeText:SetTextColor(0.5, 0.5, 0.5)

    -- Highlight
    entry.highlight = entry:CreateTexture(nil, "HIGHLIGHT")
    entry.highlight:SetAllPoints()
    entry.highlight:SetColorTexture(1, 1, 1, 0.05)

    -- Detail container for expanded roll results
    entry.detailContainer = CreateFrame("Frame", nil, entry)
    entry.detailContainer:SetPoint("TOPLEFT", entry.icon, "BOTTOMLEFT", 0, -2)
    entry.detailContainer:SetPoint("RIGHT", entry, "RIGHT", 0, 0)
    entry.detailContainer:Hide()

    -- Expand indicator
    entry.expandIndicator = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.expandIndicator:SetPoint("BOTTOMRIGHT", entry.icon, "BOTTOMRIGHT", -1, 1)
    entry.expandIndicator:SetTextColor(1, 0.82, 0)
    entry.expandIndicator:Hide()

    entry.detailRows = {}

    return entry
end

-------------------------------------------------------------------------------
-- Detail row creation and pool management
-------------------------------------------------------------------------------

local function CreateDetailRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(DETAIL_ROW_HEIGHT)

    local fontPath, fontSize, fontOutline = GetFont()

    row.playerName = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.playerName:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.playerName:SetFont(fontPath, fontSize - 2, fontOutline)
    row.playerName:SetJustifyH("LEFT")

    row.rollType = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.rollType:SetPoint("CENTER", row, "CENTER", 0, 0)
    row.rollType:SetFont(fontPath, fontSize - 2, fontOutline)
    row.rollType:SetJustifyH("CENTER")
    row.rollType:SetTextColor(0.8, 0.8, 0.8)

    row.rollValue = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.rollValue:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.rollValue:SetFont(fontPath, fontSize - 2, fontOutline)
    row.rollValue:SetJustifyH("RIGHT")
    row.rollValue:SetTextColor(0.9, 0.9, 0.9)

    return row
end

local function AcquireDetailRow(parent)
    local row = table.remove(detailRowPool)
    if not row then
        row = CreateDetailRow(parent)
    else
        row:SetParent(parent)
    end
    row:Show()
    return row
end

local function ReleaseDetailRow(row)
    row:Hide()
    row:ClearAllPoints()
    row.playerName:SetText("")
    row.rollType:SetText("")
    row.rollValue:SetText("")
    table.insert(detailRowPool, row)
end

local function ReleaseEntryDetails(entry)
    if entry.detailRows then
        for i = #entry.detailRows, 1, -1 do
            ReleaseDetailRow(entry.detailRows[i])
            entry.detailRows[i] = nil
        end
    end
    if entry.detailContainer then
        entry.detailContainer:Hide()
    end
end

local function GetEntryKey(data)
    if data.dropKey then
        return data.dropKey
    end
    return (data.timestamp or 0) .. "|" .. (data.itemLink or "") .. "|" .. (data.winner or "")
end

-------------------------------------------------------------------------------
-- Entry pool management
-------------------------------------------------------------------------------

local function AcquireEntry()
    local entry = table.remove(entryPool)
    if not entry then
        entry = CreateEntryFrame()
    end
    entry._isPooled = false
    return entry
end

local function ReleaseEntry(entry)
    if entry._isPooled then return end
    entry._isPooled = true
    ReleaseEntryDetails(entry)
    entry:Hide()
    entry:ClearAllPoints()
    entry.itemLink = nil
    entry.quality = nil
    entry._entryKey = nil
    entry._rollResults = nil
    entry.icon:SetTexture(nil)
    entry.itemName:SetText("")
    entry.winnerName:SetText("")
    entry.rollInfo:SetText("")
    entry.timeText:SetText("")
    if entry.expandIndicator then entry.expandIndicator:Hide() end
    entry:SetScript("OnClick", nil)
    entry:SetScript("OnEnter", nil)
    entry:SetScript("OnLeave", nil)
    table.insert(entryPool, entry)
end

local function ReleaseAllEntries()
    for i = #activeEntries, 1, -1 do
        ReleaseEntry(activeEntries[i])
        activeEntries[i] = nil
    end
end

-------------------------------------------------------------------------------
-- Entry interaction handlers (shared across all entries to avoid closures)
-------------------------------------------------------------------------------

local function OnEntryEnter(self)
    if self.itemLink then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.itemLink)
        GameTooltip:Show()
    end
end

local function OnEntryLeave()
    GameTooltip:Hide()
end

local function OnEntryClick(self, _button)
    if not self.itemLink then return end

    local db = ns.Addon.db.profile
    local canExpand = db.history.showRollDetails and self._rollResults
        and #self._rollResults > 0

    -- Shift-click always inserts item link
    if IsShiftKeyDown() then
        HandleModifiedItemClick(self.itemLink)
        return
    end

    -- Toggle expand/collapse if roll details are available
    if canExpand then
        local key = self._entryKey
        if expandedEntries[key] then
            expandedEntries[key] = nil
        else
            expandedEntries[key] = true
        end
        RefreshHistory()
        return
    end

    -- Default: insert item link
    HandleModifiedItemClick(self.itemLink)
end

-------------------------------------------------------------------------------
-- Populate detail rows for an expanded entry
-------------------------------------------------------------------------------

local function PopulateEntryDetails(entry, rollResults)
    ReleaseEntryDetails(entry)

    if not rollResults or #rollResults == 0 then
        entry.detailContainer:Hide()
        return
    end

    local fontPath, fontSize, fontOutline = GetFont()
    entry.detailRows = {}

    for idx, result in ipairs(rollResults) do
        local row = AcquireDetailRow(entry.detailContainer)
        row:SetPoint("TOPLEFT", entry.detailContainer, "TOPLEFT", 0,
            -((idx - 1) * DETAIL_ROW_HEIGHT))
        row:SetPoint("RIGHT", entry.detailContainer, "RIGHT", 0, 0)

        -- Font
        row.playerName:SetFont(fontPath, fontSize - 2, fontOutline)
        DU.ApplyFontShadow(row.playerName, ns.Addon.db)
        row.rollType:SetFont(fontPath, fontSize - 2, fontOutline)
        DU.ApplyFontShadow(row.rollType, ns.Addon.db)
        row.rollValue:SetFont(fontPath, fontSize - 2, fontOutline)
        DU.ApplyFontShadow(row.rollValue, ns.Addon.db)

        -- Player name (class colored)
        local cr, cg, cb = GetClassColor(result.playerClass)
        row.playerName:SetText(result.playerName or "")
        row.playerName:SetTextColor(cr, cg, cb)

        -- Roll type
        row.rollType:SetText(GetRollTypeText(result.rollType))

        -- Roll value
        row.rollValue:SetText(result.roll and tostring(result.roll) or "-")

        entry.detailRows[idx] = row
    end

    local containerHeight = #rollResults * DETAIL_ROW_HEIGHT + DETAIL_PADDING
    entry.detailContainer:SetHeight(containerHeight)
    entry.detailContainer:Show()
end

-------------------------------------------------------------------------------
-- Populate an entry frame with history data
-------------------------------------------------------------------------------

local function PopulateEntry(entry, data)
    entry.itemLink = data.itemLink
    entry.timestampValue = data.timestamp
    entry.quality = data.quality

    -- Icon
    entry.icon:SetTexture(data.itemTexture)

    -- Quality border
    local qr, qg, qb = DU.GetQualityColor(data.quality)
    if ns.Addon.db.profile.appearance.qualityBorder then
        entry.iconBorder:SetColorTexture(qr, qg, qb, 0.8)
        entry.iconBorder:Show()
    else
        entry.iconBorder:Hide()
    end

    -- Item name (quality colored)
    local fontPath, fontSize, fontOutline = GetFont()
    entry.itemName:SetFont(fontPath, fontSize - 1, fontOutline)
    DU.ApplyFontShadow(entry.itemName, ns.Addon.db)
    if data.itemLink then
        -- Extract name from link for display, fallback to link itself
        local name = data.itemLink:match("%[(.-)%]") or data.itemLink
        entry.itemName:SetText(name)
    else
        entry.itemName:SetText(L["Unknown Item"])
    end
    entry.itemName:SetTextColor(qr, qg, qb)

    -- Winner name (class colored)
    entry.winnerName:SetFont(fontPath, fontSize - 2, fontOutline)
    DU.ApplyFontShadow(entry.winnerName, ns.Addon.db)
    if data.winner then
        local cr, cg, cb = GetClassColor(data.winnerClass)
        entry.winnerName:SetText(data.winner)
        entry.winnerName:SetTextColor(cr, cg, cb)
    else
        entry.winnerName:SetText("")
    end

    -- Roll info
    entry.rollInfo:SetFont(fontPath, fontSize - 2, fontOutline)
    DU.ApplyFontShadow(entry.rollInfo, ns.Addon.db)
    if data.isDirectLoot then
        entry.rollInfo:SetText(L["Looted"])
        entry.rollInfo:SetTextColor(0.6, 0.6, 0.6)
    else
        local rollText = GetRollTypeText(data.rollType)
        if data.roll then
            rollText = rollText .. " " .. data.roll
        end
        entry.rollInfo:SetText(rollText)
        entry.rollInfo:SetTextColor(0.8, 0.8, 0.8)
    end

    -- Time
    entry.timeText:SetFont(fontPath, fontSize - 2, fontOutline)
    DU.ApplyFontShadow(entry.timeText, ns.Addon.db)
    entry.timeText:SetText(FormatTimeAgo(data.timestamp))

    -- Roll details expand/collapse
    local db = ns.Addon.db.profile
    local entryKey = GetEntryKey(data)
    entry._entryKey = entryKey
    entry._rollResults = data.rollResults

    if db.history.showRollDetails and data.rollResults and #data.rollResults > 0 then
        local fontPath2, fontSize2, fontOutline2 = GetFont()
        entry.expandIndicator:SetFont(fontPath2, fontSize2 - 3, fontOutline2)
        DU.ApplyFontShadow(entry.expandIndicator, ns.Addon.db)
        if expandedEntries[entryKey] then
            entry.expandIndicator:SetText("-")
            entry.expandIndicator:Show()
            PopulateEntryDetails(entry, data.rollResults)
        else
            entry.expandIndicator:SetText("+")
            entry.expandIndicator:Show()
            ReleaseEntryDetails(entry)
        end
    else
        entry.expandIndicator:Hide()
        ReleaseEntryDetails(entry)
    end

    -- Interaction scripts (named functions, no per-entry closures)
    entry:SetScript("OnEnter", OnEntryEnter)
    entry:SetScript("OnLeave", OnEntryLeave)
    entry:SetScript("OnClick", OnEntryClick)

    entry:Show()
end

-------------------------------------------------------------------------------
-- Scroll bar update helper
-------------------------------------------------------------------------------

local function UpdateScrollBar()
    if not scrollBar or not scrollFrame then return end
    local contentHeight = scrollChild:GetHeight()
    local visibleHeight = scrollFrame:GetHeight()
    local maxScroll = contentHeight - visibleHeight
    if maxScroll < 0 then maxScroll = 0 end

    scrollBar:SetMinMaxValues(0, maxScroll)
    if maxScroll == 0 then
        scrollBar:Hide()
    else
        scrollBar:Show()
    end
end

-------------------------------------------------------------------------------
-- Refresh history display
-------------------------------------------------------------------------------

RefreshHistory = function()
    if not containerFrame or not containerFrame:IsShown() then return end

    ReleaseAllEntries()

    local db = ns.Addon.db.profile
    local entryHeight = GetEntryHeight()
    local entrySpacing = GetEntrySpacing()
    local yOffset = 0
    for i, data in ipairs(ns.historyData) do
        local entry = AcquireEntry()
        PopulateEntry(entry, data)
        entry:ClearAllPoints()
        entry:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        entry:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
        activeEntries[i] = entry

        -- Variable height: base + expanded detail rows
        local thisHeight = entryHeight
        local entryKey = GetEntryKey(data)
        if db.history.showRollDetails and expandedEntries[entryKey]
            and data.rollResults and #data.rollResults > 0 then
            thisHeight = entryHeight + (#data.rollResults * DETAIL_ROW_HEIGHT)
                + DETAIL_PADDING
        end
        entry:SetHeight(thisHeight)
        yOffset = yOffset + thisHeight + entrySpacing
    end

    -- Resize scroll child to fit all entries (use accumulated yOffset)
    local totalHeight = yOffset
    if totalHeight < 1 then totalHeight = 1 end
    scrollChild:SetHeight(totalHeight)

    UpdateScrollBar()
end

-------------------------------------------------------------------------------
-- Position persistence
-------------------------------------------------------------------------------

local function SaveFramePosition()
    if not containerFrame then return end
    local db = ns.Addon.db.profile
    if not db.history then return end
    local point, _, relativePoint, x, y = containerFrame:GetPoint()
    if point then
        db.history.point = point
        db.history.relativePoint = relativePoint
        db.history.x = x
        db.history.y = y
    end
end

local function RestoreFramePosition()
    if not containerFrame then return end
    local db = ns.Addon.db.profile
    if not db.history then return end
    containerFrame:ClearAllPoints()
    if db.history.point then
        containerFrame:SetPoint(db.history.point, UIParent, db.history.relativePoint,
            db.history.x or 0, db.history.y or 0)
    else
        containerFrame:SetPoint("CENTER", UIParent, "CENTER", DEFAULT_HISTORY_X_OFFSET, 0)
    end
end

-------------------------------------------------------------------------------
-- Title bar creation
-------------------------------------------------------------------------------

local function CreateTitleBar(parent)
    local titleBar = CreateFrame("Frame", nil, parent)
    titleBar:SetHeight(TITLE_BAR_HEIGHT)
    titleBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    local fontPath, fontSize, fontOutline = GetFont()
    titleBar.text = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleBar.text:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    titleBar.text:SetFont(fontPath, fontSize, fontOutline)
    DU.ApplyFontShadow(titleBar.text, ns.Addon.db)
    titleBar.text:SetText(L["DragonLoot - Loot History"])
    titleBar.text:SetTextColor(1, 0.82, 0)

    -- Close button
    local ok, closeBtn = pcall(CreateFrame, "Button", nil, titleBar,
        "UIPanelCloseButtonNoScripts")
    if not ok or not closeBtn then
        closeBtn = CreateFrame("Button", nil, titleBar)
        closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        closeBtn:SetHighlightTexture(
            "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    end
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        ns.HistoryFrame.Hide()
    end)

    -- Clear button
    local clearBtn = CreateFrame("Button", nil, titleBar)
    clearBtn:SetSize(16, 16)
    clearBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
    clearBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
    clearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    clearBtn:SetScript("OnClick", function()
        ns.HistoryFrame.ClearHistory()
    end)
    clearBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Clear History"])
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return titleBar
end

-------------------------------------------------------------------------------
-- Scroll frame creation
-------------------------------------------------------------------------------

local function OnScrollBarValueChanged(_, value)
    if scrollFrame then
        scrollFrame:SetVerticalScroll(value)
    end
end

local function CreateScrollComponents(parent)
    local padding = GetContentPadding()

    -- Scroll frame (clip region)
    local sf = CreateFrame("ScrollFrame", "DragonLootHistoryScroll", parent)
    sf:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -(TITLE_BAR_HEIGHT + padding))
    sf:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -(padding + SCROLLBAR_WIDTH + SCROLLBAR_GAP), padding)

    -- Scroll child
    local child = CreateFrame("Frame", nil, sf)
    child:SetWidth(sf:GetWidth() or (FRAME_WIDTH - padding * 2 - SCROLLBAR_WIDTH - SCROLLBAR_GAP))
    child:SetHeight(1)
    sf:SetScrollChild(child)

    -- Scroll bar
    local bar = CreateFrame("Slider", "DragonLootHistoryScrollBar", parent, "BackdropTemplate")
    bar:SetWidth(SCROLLBAR_WIDTH)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -padding, -(TITLE_BAR_HEIGHT + padding))
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -padding, padding)
    bar:SetOrientation("VERTICAL")
    bar:SetMinMaxValues(0, 0)
    bar:SetValue(0)
    bar:SetValueStep(GetEntryHeight())
    bar:SetBackdrop({
        bgFile = DU.WHITE8x8,
    })
    bar:SetBackdropColor(0.1, 0.1, 0.1, 0.5)

    -- Thumb texture
    bar.thumb = bar:CreateTexture(nil, "OVERLAY")
    bar.thumb:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    bar.thumb:SetSize(SCROLLBAR_WIDTH - SCROLLBAR_GAP, SCROLLBAR_THUMB_HEIGHT)
    bar:SetThumbTexture(bar.thumb)

    bar:SetScript("OnValueChanged", OnScrollBarValueChanged)
    bar:Hide()

    -- Mouse wheel scrolling
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(_, delta)
        local current = bar:GetValue()
        local step = GetEntryHeight() * SCROLL_STEP
        bar:SetValue(current - (delta * step))
    end)

    -- Update child width when scroll frame resizes
    sf:SetScript("OnSizeChanged", function(self)
        child:SetWidth(self:GetWidth())
    end)

    return sf, child, bar
end

-------------------------------------------------------------------------------
-- Container frame creation
-------------------------------------------------------------------------------

local function CreateContainerFrame()
    local frame = CreateFrame("Frame", "DragonLootHistoryFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    frame:SetClampedToScreen(true)
    frame:Hide()

    -- Backdrop
    ApplyBackdrop(frame)

    -- Title bar
    frame.titleBar = CreateTitleBar(frame)

    -- Dragging
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        local db = ns.Addon.db.profile
        if db.history.lock then return end
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveFramePosition()
    end)

    return frame
end

-------------------------------------------------------------------------------
-- Time refresh ticker
-------------------------------------------------------------------------------

local timeRefreshHandle

local function StartTimeRefresh()
    if timeRefreshHandle then return end
    timeRefreshHandle = ns.Addon:ScheduleRepeatingTimer(function()
        if not containerFrame or not containerFrame:IsShown() then return end
        for _, entry in ipairs(activeEntries) do
            if entry.timestampValue then
                entry.timeText:SetText(FormatTimeAgo(entry.timestampValue))
            end
        end
    end, TIME_REFRESH_INTERVAL)
end

local function StopTimeRefresh()
    if timeRefreshHandle and ns.Addon then
        ns.Addon:CancelTimer(timeRefreshHandle)
        timeRefreshHandle = nil
    end
end

-------------------------------------------------------------------------------
-- Public Interface: ns.HistoryFrame
-------------------------------------------------------------------------------

function ns.HistoryFrame.Initialize()
    if containerFrame then return end
    containerFrame = CreateContainerFrame()
    scrollFrame, scrollChild, scrollBar = CreateScrollComponents(containerFrame)
    ApplyLayoutOffsets(containerFrame)
    ns.HistoryFrame.ApplySettings()
    RestoreFramePosition()
    ns.DebugPrint("HistoryFrame initialized")
end

function ns.HistoryFrame.Shutdown()
    StopTimeRefresh()
    if not containerFrame then return end
    ReleaseAllEntries()
    containerFrame:Hide()
    ns.DebugPrint("HistoryFrame shut down")
end

function ns.HistoryFrame.Show()
    if not containerFrame then return end
    local db = ns.Addon.db.profile
    if not db.history.enabled then return end
    containerFrame:Show()
    RefreshHistory()
    StartTimeRefresh()
end

function ns.HistoryFrame.Hide()
    if not containerFrame then return end
    StopTimeRefresh()
    containerFrame:Hide()
end

function ns.HistoryFrame.Toggle()
    if not containerFrame then return end
    if containerFrame:IsShown() then
        ns.HistoryFrame.Hide()
    else
        ns.HistoryFrame.Show()
    end
end

function ns.HistoryFrame.Refresh()
    RefreshHistory()
end

function ns.HistoryFrame.ApplySettings()
    if not containerFrame then return end

    -- Update backdrop
    ApplyBackdrop(containerFrame)

    -- Update layout offsets for border thickness
    ApplyLayoutOffsets(containerFrame)

    -- Update title font
    local fontPath, fontSize, fontOutline = GetFont()
    containerFrame.titleBar.text:SetFont(fontPath, fontSize, fontOutline)
    DU.ApplyFontShadow(containerFrame.titleBar.text, ns.Addon.db)

    -- Update visible entries with current icon size and entry height
    local db = ns.Addon.db.profile
    local iconSize = GetHistoryIconSize()
    local entryHeight = GetEntryHeight()
    for _, entry in ipairs(activeEntries) do
        if entry:IsShown() then
            entry:SetHeight(entryHeight)
            entry.icon:SetSize(iconSize, iconSize)
            entry.itemName:SetFont(fontPath, fontSize - 1, fontOutline)
            DU.ApplyFontShadow(entry.itemName, ns.Addon.db)
            entry.winnerName:SetFont(fontPath, fontSize - 2, fontOutline)
            DU.ApplyFontShadow(entry.winnerName, ns.Addon.db)
            entry.rollInfo:SetFont(fontPath, fontSize - 2, fontOutline)
            DU.ApplyFontShadow(entry.rollInfo, ns.Addon.db)
            entry.timeText:SetFont(fontPath, fontSize - 2, fontOutline)
            DU.ApplyFontShadow(entry.timeText, ns.Addon.db)

            -- Update detail rows if expanded
            if entry.detailRows then
                for _, row in ipairs(entry.detailRows) do
                    row.playerName:SetFont(fontPath, fontSize - 2, fontOutline)
                    DU.ApplyFontShadow(row.playerName, ns.Addon.db)
                    row.rollType:SetFont(fontPath, fontSize - 2, fontOutline)
                    DU.ApplyFontShadow(row.rollType, ns.Addon.db)
                    row.rollValue:SetFont(fontPath, fontSize - 2, fontOutline)
                    DU.ApplyFontShadow(row.rollValue, ns.Addon.db)
                end
            end

            -- Refresh quality border visibility
            if entry.itemLink and db.appearance.qualityBorder then
                if entry.quality then
                    local qr, qg, qb = DU.GetQualityColor(entry.quality)
                    entry.iconBorder:SetColorTexture(qr, qg, qb, 0.8)
                end
                entry.iconBorder:Show()
            elseif entry.itemLink then
                entry.iconBorder:Hide()
            end
        end
    end

    -- Re-layout entries if visible
    if containerFrame:IsShown() then
        RefreshHistory()
    end
end

function ns.HistoryFrame.AddEntry(data)
    local db = ns.Addon.db.profile
    local maxEntries = db.history.maxEntries or 100

    -- Insert at front (newest first)
    table.insert(ns.historyData, 1, data)

    -- Trim to maxEntries
    while #ns.historyData > maxEntries do
        table.remove(ns.historyData)
    end

    -- Refresh display if visible
    if containerFrame and containerFrame:IsShown() then
        RefreshHistory()
    end
end

function ns.HistoryFrame.UpdateEntryByKey(dropKey, newData)
    for i, data in ipairs(ns.historyData) do
        if data.dropKey == dropKey then
            ns.historyData[i] = newData
            if containerFrame and containerFrame:IsShown() then
                RefreshHistory()
            end
            return
        end
    end
    -- Not found, treat as new
    ns.HistoryFrame.AddEntry(newData)
end

function ns.HistoryFrame.SetEntries(entries)
    local db = ns.Addon.db.profile
    local maxEntries = db.history.maxEntries or 100

    -- Replace all data
    wipe(ns.historyData)
    for i, entry in ipairs(entries) do
        if i > maxEntries then break end
        ns.historyData[i] = entry
    end

    -- Refresh display if visible
    if containerFrame and containerFrame:IsShown() then
        RefreshHistory()
    end
end

function ns.HistoryFrame.ClearHistory()
    wipe(expandedEntries)
    wipe(ns.historyData)
    if containerFrame and containerFrame:IsShown() then
        RefreshHistory()
    end
end
