-------------------------------------------------------------------------------
-- HistoryFrame.lua
-- Loot history display with scrollable list of recent loot events
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
local GetTime = GetTime
local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local HandleModifiedItemClick = HandleModifiedItemClick
local math_floor = math.floor

local LSM = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FRAME_WIDTH = 350
local FRAME_HEIGHT = 400
local TITLE_BAR_HEIGHT = 24
local ENTRY_HEIGHT = 30
local ENTRY_SPACING = 2
local ENTRY_ICON_SIZE = 24
local PADDING = 6
local SCROLL_STEP = 3
local SCROLLBAR_WIDTH = 14

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

-------------------------------------------------------------------------------
-- History data (populated by listeners)
-------------------------------------------------------------------------------

ns.historyData = {}

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

local ROLL_TYPE_TEXT = {
    [0] = "Pass",
    [1] = "Need",
    [2] = "Greed",
    [3] = "Disenchant",
}

local function GetRollTypeText(rollType)
    return ROLL_TYPE_TEXT[rollType] or ""
end

-------------------------------------------------------------------------------
-- Time formatting helper
-------------------------------------------------------------------------------

local function FormatTimeAgo(timestamp)
    if not timestamp then return "" end
    local elapsed = GetTime() - timestamp
    if elapsed < 0 then elapsed = 0 end

    if elapsed < 60 then
        return math_floor(elapsed) .. "s ago"
    elseif elapsed < 3600 then
        return math_floor(elapsed / 60) .. "m ago"
    else
        return math_floor(elapsed / 3600) .. "h ago"
    end
end

-------------------------------------------------------------------------------
-- Entry frame creation
-------------------------------------------------------------------------------

local function CreateEntryFrame()
    entryCount = entryCount + 1
    local frameName = "DragonLootHistoryEntry" .. entryCount

    local entry = CreateFrame("Button", frameName, scrollChild)
    entry:SetHeight(ENTRY_HEIGHT)
    entry:EnableMouse(true)
    entry:RegisterForClicks("LeftButtonUp")

    -- Icon
    entry.icon = entry:CreateTexture(nil, "ARTWORK")
    entry.icon:SetSize(ENTRY_ICON_SIZE, ENTRY_ICON_SIZE)
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

    return entry
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
    entry:Hide()
    entry:ClearAllPoints()
    entry.itemLink = nil
    entry.icon:SetTexture(nil)
    entry.itemName:SetText("")
    entry.winnerName:SetText("")
    entry.rollInfo:SetText("")
    entry.timeText:SetText("")
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

local function OnEntryClick(self)
    if self.itemLink then
        HandleModifiedItemClick(self.itemLink)
    end
end

-------------------------------------------------------------------------------
-- Populate an entry frame with history data
-------------------------------------------------------------------------------

local function PopulateEntry(entry, data)
    entry.itemLink = data.itemLink
    entry.timestampValue = data.timestamp

    -- Icon
    entry.icon:SetTexture(data.itemTexture)

    -- Quality border
    local qr, qg, qb = GetQualityColor(data.quality)
    entry.iconBorder:SetColorTexture(qr, qg, qb, 0.8)

    -- Item name (quality colored)
    local fontPath, fontSize = GetFont()
    entry.itemName:SetFont(fontPath, fontSize - 1, "OUTLINE")
    if data.itemLink then
        -- Extract name from link for display, fallback to link itself
        local name = data.itemLink:match("%[(.-)%]") or data.itemLink
        entry.itemName:SetText(name)
    else
        entry.itemName:SetText("Unknown Item")
    end
    entry.itemName:SetTextColor(qr, qg, qb)

    -- Winner name (class colored)
    entry.winnerName:SetFont(fontPath, fontSize - 2, "OUTLINE")
    if data.winner then
        local cr, cg, cb = GetClassColor(data.winnerClass)
        entry.winnerName:SetText(data.winner)
        entry.winnerName:SetTextColor(cr, cg, cb)
    else
        entry.winnerName:SetText("")
    end

    -- Roll info
    entry.rollInfo:SetFont(fontPath, fontSize - 2, "OUTLINE")
    local rollText = GetRollTypeText(data.rollType)
    if data.roll then
        rollText = rollText .. " " .. data.roll
    end
    entry.rollInfo:SetText(rollText)

    -- Time
    entry.timeText:SetFont(fontPath, fontSize - 2, "OUTLINE")
    entry.timeText:SetText(FormatTimeAgo(data.timestamp))

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

local function RefreshHistory()
    if not containerFrame or not containerFrame:IsShown() then return end

    ReleaseAllEntries()

    local yOffset = 0
    for i, data in ipairs(ns.historyData) do
        local entry = AcquireEntry()
        PopulateEntry(entry, data)
        entry:ClearAllPoints()
        entry:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        entry:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
        activeEntries[i] = entry
        yOffset = yOffset + ENTRY_HEIGHT + ENTRY_SPACING
    end

    -- Resize scroll child to fit all entries
    local totalHeight = #ns.historyData * (ENTRY_HEIGHT + ENTRY_SPACING)
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
        containerFrame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
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

    titleBar.text = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleBar.text:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    titleBar.text:SetText("DragonLoot - Loot History")
    titleBar.text:SetTextColor(1, 0.82, 0)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -4, -4)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
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
        GameTooltip:SetText("Clear History")
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

local function OnScrollBarValueChanged(self, value)
    if scrollFrame then
        scrollFrame:SetVerticalScroll(value)
    end
end

local function CreateScrollComponents(parent)
    -- Scroll frame (clip region)
    local sf = CreateFrame("ScrollFrame", "DragonLootHistoryScroll", parent)
    sf:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, -(TITLE_BAR_HEIGHT + PADDING))
    sf:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -(PADDING + SCROLLBAR_WIDTH + 2), PADDING)

    -- Scroll child
    local child = CreateFrame("Frame", nil, sf)
    child:SetWidth(sf:GetWidth() or (FRAME_WIDTH - PADDING * 2 - SCROLLBAR_WIDTH - 2))
    child:SetHeight(1)
    sf:SetScrollChild(child)

    -- Scroll bar
    local bar = CreateFrame("Slider", "DragonLootHistoryScrollBar", parent, "BackdropTemplate")
    bar:SetWidth(SCROLLBAR_WIDTH)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING, -(TITLE_BAR_HEIGHT + PADDING))
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -PADDING, PADDING)
    bar:SetOrientation("VERTICAL")
    bar:SetMinMaxValues(0, 0)
    bar:SetValue(0)
    bar:SetValueStep(ENTRY_HEIGHT)
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    bar:SetBackdropColor(0.1, 0.1, 0.1, 0.5)

    -- Thumb texture
    bar.thumb = bar:CreateTexture(nil, "OVERLAY")
    bar.thumb:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    bar.thumb:SetSize(SCROLLBAR_WIDTH - 2, 30)
    bar:SetThumbTexture(bar.thumb)

    bar:SetScript("OnValueChanged", OnScrollBarValueChanged)
    bar:Hide()

    -- Mouse wheel scrolling
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(_, delta)
        local current = bar:GetValue()
        local step = ENTRY_HEIGHT * SCROLL_STEP
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
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- Title bar
    frame.titleBar = CreateTitleBar(frame)

    -- Dragging
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
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
        local fontPath, fontSize = GetFont()
        for _, entry in ipairs(activeEntries) do
            if entry.timestampValue then
                entry.timeText:SetFont(fontPath, fontSize - 2, "OUTLINE")
                entry.timeText:SetText(FormatTimeAgo(entry.timestampValue))
            end
        end
    end, 10)
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
    local fontPath, fontSize = GetFont()
    containerFrame.titleBar.text:SetFont(fontPath, fontSize, "OUTLINE")
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
    wipe(ns.historyData)
    if containerFrame and containerFrame:IsShown() then
        RefreshHistory()
    end
end
