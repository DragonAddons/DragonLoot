-------------------------------------------------------------------------------
-- ItemList.lua
-- Grid of ItemSlot widgets with drag-and-drop add and right-click remove
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
local pairs = pairs
local math_floor = math.floor

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 12
local LABEL_FONT_SIZE = 11
local SLOT_SIZE = 36
local SLOT_SPACING = 4
local SLOTS_PER_ROW = 6
local WHITE_COLOR = { 1, 1, 1 }
local GRAY_COLOR = { 0.7, 0.7, 0.7 }
local HEADER_HEIGHT = 18
local COUNT_HEIGHT = 16
local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"
local DASHED_BORDER_COLOR = { 0.6, 0.6, 0.6, 0.5 }
local ADD_SLOT_BG = { 0.08, 0.08, 0.08, 0.6 }

-------------------------------------------------------------------------------
-- Count items in a set table
-------------------------------------------------------------------------------

local function CountItems(items)
    local count = 0
    for _ in pairs(items) do
        count = count + 1
    end
    return count
end

-------------------------------------------------------------------------------
-- Collect sorted item IDs from a set table
-------------------------------------------------------------------------------

local function CollectSortedIDs(items)
    local ids = {}
    for id in pairs(items) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    return ids
end

-------------------------------------------------------------------------------
-- Handle adding an item via drag-and-drop
-------------------------------------------------------------------------------

local function HandleAddDrop(frame, opts)
    local infoType, itemID = GetCursorInfo()
    if infoType ~= "item" or not itemID then return end

    local maxItems = opts.maxItems
    local items = opts.getItems and opts.getItems() or {}
    if maxItems and CountItems(items) >= maxItems then return end
    if items[itemID] then return end -- already present

    ClearCursor()
    items[itemID] = true
    if opts.setItems then opts.setItems(items) end
    frame:Refresh()
end

-------------------------------------------------------------------------------
-- Create the "add" placeholder slot with a "+" overlay
-------------------------------------------------------------------------------

local function CreateAddSlot(parent, frame, opts)
    local slot = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    slot:SetSize(SLOT_SIZE, SLOT_SIZE)
    slot:SetBackdrop({ bgFile = WHITE8x8, edgeFile = WHITE8x8, edgeSize = 1 })
    slot:SetBackdropColor(ADD_SLOT_BG[1], ADD_SLOT_BG[2], ADD_SLOT_BG[3], ADD_SLOT_BG[4])
    slot:SetBackdropBorderColor(
        DASHED_BORDER_COLOR[1], DASHED_BORDER_COLOR[2],
        DASHED_BORDER_COLOR[3], DASHED_BORDER_COLOR[4]
    )

    local plusText = slot:CreateFontString(nil, "OVERLAY")
    plusText:SetFont(FONT_PATH, 18, "OUTLINE")
    plusText:SetTextColor(GRAY_COLOR[1], GRAY_COLOR[2], GRAY_COLOR[3])
    plusText:SetPoint("CENTER", slot, "CENTER", 0, 0)
    plusText:SetText("+")

    slot:EnableMouse(true)
    slot:SetScript("OnReceiveDrag", function()
        HandleAddDrop(frame, opts)
    end)
    slot:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            HandleAddDrop(frame, opts)
        end
    end)

    return slot
end

-------------------------------------------------------------------------------
-- Position a slot in the grid
-------------------------------------------------------------------------------

local function PositionSlot(slot, index, contentFrame)
    local row = math_floor(index / SLOTS_PER_ROW)
    local col = index - (row * SLOTS_PER_ROW)
    local x = col * (SLOT_SIZE + SLOT_SPACING)
    local y = -(row * (SLOT_SIZE + SLOT_SPACING))
    slot:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", x, y)
end

-------------------------------------------------------------------------------
-- Build the grid of item slots
-------------------------------------------------------------------------------

local function BuildGrid(frame, opts)
    -- Hide previous slots
    for _, slot in ipairs(frame._slots) do
        slot:Hide()
    end
    if frame._addSlot then frame._addSlot:Hide() end

    local items = opts.getItems and opts.getItems() or {}
    local ids = CollectSortedIDs(items)
    local maxItems = opts.maxItems
    local contentFrame = frame._gridContent

    for i, itemID in ipairs(ids) do
        local slot = frame._slots[i]
        if not slot then
            slot = ns.Widgets.CreateItemSlot(contentFrame, {
                size = SLOT_SIZE,
                onAccept = function(newID)
                    local currentItems = opts.getItems and opts.getItems() or {}
                    currentItems[newID] = true
                    if opts.setItems then opts.setItems(currentItems) end
                    frame:Refresh()
                end,
                onRemove = function(removedID)
                    local currentItems = opts.getItems and opts.getItems() or {}
                    currentItems[removedID] = nil
                    if opts.setItems then opts.setItems(currentItems) end
                    frame:Refresh()
                end,
            })
            frame._slots[i] = slot
        end

        slot:SetItem(itemID)
        PositionSlot(slot, i - 1, contentFrame)
        slot:Show()
    end

    -- Add slot after last item (if under max or no max set)
    local count = #ids
    if not maxItems or count < maxItems then
        if not frame._addSlot then
            frame._addSlot = CreateAddSlot(contentFrame, frame, opts)
        end
        PositionSlot(frame._addSlot, count, contentFrame)
        frame._addSlot:Show()
    end

    -- Update content height
    local totalSlots
    if maxItems then
        totalSlots = count < maxItems and count + 1 or count
    else
        totalSlots = count + 1
    end
    local rows = math_floor((totalSlots - 1) / SLOTS_PER_ROW) + 1
    if totalSlots == 0 then rows = 1 end
    contentFrame:SetHeight(rows * (SLOT_SIZE + SLOT_SPACING))

    -- Update count display
    if maxItems then
        frame._countText:SetText(count .. " / " .. maxItems .. " items")
    else
        frame._countText:SetText(count .. " items")
    end

    -- Empty text visibility
    frame._emptyText:SetShown(count == 0)
end

-------------------------------------------------------------------------------
-- Factory: CreateItemList
-------------------------------------------------------------------------------

function ns.Widgets.CreateItemList(parent, opts)
    local frame = CreateFrame("Frame", nil, parent)

    -- Header label
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_PATH, LABEL_FONT_SIZE, "")
    label:SetTextColor(WHITE_COLOR[1], WHITE_COLOR[2], WHITE_COLOR[3])
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetText(opts.label or "")

    -- Item count
    local countText = frame:CreateFontString(nil, "OVERLAY")
    countText:SetFont(FONT_PATH, LABEL_FONT_SIZE, "")
    countText:SetTextColor(GRAY_COLOR[1], GRAY_COLOR[2], GRAY_COLOR[3])
    countText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame._countText = countText

    -- Scroll wrapper for the grid
    local scrollArea = CreateFrame("Frame", nil, frame)
    scrollArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(HEADER_HEIGHT + 2))
    scrollArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, COUNT_HEIGHT)

    local scrollWrapper = ns.Widgets.CreateScrollFrame(scrollArea)
    scrollWrapper:SetPoint("TOPLEFT", scrollArea, "TOPLEFT", 0, 0)
    scrollWrapper:SetPoint("BOTTOMRIGHT", scrollArea, "BOTTOMRIGHT", 0, 0)
    frame._gridContent = scrollWrapper.scrollChild
    frame._scrollWrapper = scrollWrapper

    -- Empty text
    local emptyText = scrollWrapper.scrollChild:CreateFontString(nil, "OVERLAY")
    emptyText:SetFont(FONT_PATH, FONT_SIZE, "")
    emptyText:SetTextColor(GRAY_COLOR[1], GRAY_COLOR[2], GRAY_COLOR[3])
    emptyText:SetPoint("CENTER", scrollWrapper.scrollChild, "CENTER", 0, 0)
    emptyText:SetText(opts.emptyText or "Drop item here to add")
    emptyText:Hide()
    frame._emptyText = emptyText

    -- Drop zone on the scroll content
    scrollWrapper.scrollChild:EnableMouse(true)
    scrollWrapper.scrollChild:SetScript("OnReceiveDrag", function()
        HandleAddDrop(frame, opts)
    end)
    scrollWrapper.scrollChild:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            HandleAddDrop(frame, opts)
        end
    end)

    -- Slot pool
    frame._slots = {}
    frame._addSlot = nil

    -- Public API: Refresh
    function frame:Refresh()
        BuildGrid(self, opts)
        if self._scrollWrapper then
            self._scrollWrapper:UpdateScrollRange()
        end
    end

    -- Public API: GetValue / SetValue / SetDisabled for consistency
    function frame:GetValue()
        return opts.getItems and opts.getItems() or {}
    end

    function frame:SetValue(items)
        if opts.setItems then opts.setItems(items) end
        self:Refresh()
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

    frame._label = label
    frame.order = opts.order

    -- Initial build
    BuildGrid(frame, opts)

    return frame
end
