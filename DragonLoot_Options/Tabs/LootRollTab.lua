-------------------------------------------------------------------------------
-- LootRollTab.lua
-- Loot Roll settings tab: roll frame layout, notifications, instance filters
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local L = ns.L

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local table_sort = table.sort
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local LibStub = LibStub

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local PADDING_SIDE = 10
local PADDING_TOP = -10
local SPACING_AFTER_HEADER = 8
local SPACING_BETWEEN_WIDGETS = 6
local SPACING_BETWEEN_SECTIONS = 16
local PADDING_BOTTOM = 20

-------------------------------------------------------------------------------
-- Shared media
-------------------------------------------------------------------------------

local LSM = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- Notify roll manager helper
-------------------------------------------------------------------------------

local function NotifyRollManager()
    if dlns.RollManager and dlns.RollManager.ApplySettings then
        dlns.RollManager.ApplySettings()
    end
end

-------------------------------------------------------------------------------
-- Build sorted LSM statusbar values for dropdown
-------------------------------------------------------------------------------

local function GetStatusBarValues()
    local hash = LSM:HashTable("statusbar")
    local values = {}
    for key in pairs(hash) do
        values[#values + 1] = { value = key, text = key }
    end
    table_sort(values, function(a, b) return a.text < b.text end)
    return values
end

-------------------------------------------------------------------------------
-- Anchor a widget to the parent at the current yOffset
-------------------------------------------------------------------------------

local function AnchorWidget(widget, parent, yOffset)
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    return yOffset - widget:GetHeight()
end

-------------------------------------------------------------------------------
-- Section: Roll Frame (basic settings)
-------------------------------------------------------------------------------

local function CreateRollFrameSection(parent, W, db, yOffset)
    local header = W.CreateHeader(parent, L["Roll Frame"])
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    local enableToggle = W.CreateToggle(parent, {
        label = L["Enable Custom Roll Frame"],
        tooltip = L["Replace the default Blizzard roll frame with DragonLoot's custom version"],
        get = function() return db.profile.rollFrame.enabled end,
        set = function(value)
            db.profile.rollFrame.enabled = value
            NotifyRollManager()
        end,
    })
    yOffset = AnchorWidget(enableToggle, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local lockToggle = W.CreateToggle(parent, {
        label = L["Lock Position"],
        tooltip = L["Prevent the roll frame from being dragged"],
        get = function() return db.profile.rollFrame.lock end,
        set = function(value) db.profile.rollFrame.lock = value end,
    })
    yOffset = AnchorWidget(lockToggle, parent, yOffset) - SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Layout (sliders + texture dropdown)
-------------------------------------------------------------------------------

local function CreateLayoutSlider(parent, W, db, yOffset, label, tooltip, key, min, max, step, fmt)
    local slider = W.CreateSlider(parent, {
        label = label,
        tooltip = tooltip,
        min = min,
        max = max,
        step = step,
        format = fmt,
        get = function() return db.profile.rollFrame[key] end,
        set = function(value)
            db.profile.rollFrame[key] = value
            NotifyRollManager()
        end,
    })
    yOffset = AnchorWidget(slider, parent, yOffset) - SPACING_BETWEEN_WIDGETS
    return yOffset
end

local function CreateLayoutSection(parent, W, db, yOffset)
    local header = W.CreateHeader(parent, L["Layout"])
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    yOffset = CreateLayoutSlider(parent, W, db, yOffset,
        L["Scale"], L["Roll frame scale"], "scale", 0.5, 2, 0.05, "%.2f")
    yOffset = CreateLayoutSlider(parent, W, db, yOffset,
        L["Frame Width"], L["Width of the roll frame"], "frameWidth", 200, 500, 10, "%d")
    yOffset = CreateLayoutSlider(parent, W, db, yOffset,
        L["Row Spacing"], L["Vertical spacing between roll rows"], "rowSpacing", 0, 16, 1, "%d")
    yOffset = CreateLayoutSlider(parent, W, db, yOffset,
        L["Timer Bar Height"], L["Height of the countdown timer bar"], "timerBarHeight", 6, 24, 1, "%d")
    yOffset = CreateLayoutSlider(parent, W, db, yOffset,
        L["Timer Bar Spacing"], L["Space between item row and timer bar"], "timerBarSpacing", 0, 16, 1, "%d")
    yOffset = CreateLayoutSlider(parent, W, db, yOffset,
        L["Content Padding"], L["Inner padding of the roll frame"], "contentPadding", 0, 12, 1, "%d")
    yOffset = CreateLayoutSlider(parent, W, db, yOffset,
        L["Button Size"], L["Size of Need/Greed/Pass buttons"], "buttonSize", 16, 36, 1, "%d")
    yOffset = CreateLayoutSlider(parent, W, db, yOffset,
        L["Button Spacing"], L["Spacing between roll buttons"], "buttonSpacing", 0, 12, 1, "%d")
    yOffset = CreateLayoutSlider(parent, W, db, yOffset,
        L["Frame Spacing"], L["Spacing between multiple roll frames"], "frameSpacing", 0, 16, 1, "%d")

    local textureDropdown = W.CreateDropdown(parent, {
        label = L["Timer Bar Texture"],
        values = GetStatusBarValues,
        sort = true,
        mediaType = "statusbar",
        get = function() return db.profile.rollFrame.timerBarTexture end,
        set = function(value)
            db.profile.rollFrame.timerBarTexture = value
            NotifyRollManager()
        end,
    })
    yOffset = AnchorWidget(textureDropdown, parent, yOffset) - SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Roll Notifications
-------------------------------------------------------------------------------

local function CreateNotificationSection(parent, W, db, yOffset)
    local header = W.CreateHeader(parent, L["Roll Notifications"])
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    -- Forward declarations for cross-widget disable logic
    local groupWinsToggle, selfRollsToggle, groupRollsToggle

    local showRollWon = W.CreateToggle(parent, {
        label = L["Show Roll Won"],
        tooltip = L["Show a notification when someone wins a roll"],
        get = function() return db.profile.rollNotifications.showRollWon end,
        set = function(value)
            db.profile.rollNotifications.showRollWon = value
            if groupWinsToggle then groupWinsToggle:SetDisabled(not value) end
        end,
    })
    yOffset = AnchorWidget(showRollWon, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    groupWinsToggle = W.CreateToggle(parent, {
        label = L["Show Group Wins"],
        tooltip = L["Show notifications when other group members win rolls"],
        get = function() return db.profile.rollNotifications.showGroupWins end,
        set = function(value) db.profile.rollNotifications.showGroupWins = value end,
        disabled = not db.profile.rollNotifications.showRollWon,
    })
    yOffset = AnchorWidget(groupWinsToggle, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local showRollResults = W.CreateToggle(parent, {
        label = L["Show Roll Results"],
        tooltip = L["Show individual roll result notifications"],
        get = function() return db.profile.rollNotifications.showRollResults end,
        set = function(value)
            db.profile.rollNotifications.showRollResults = value
            if selfRollsToggle then selfRollsToggle:SetDisabled(not value) end
            if groupRollsToggle then groupRollsToggle:SetDisabled(not value) end
        end,
    })
    yOffset = AnchorWidget(showRollResults, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    selfRollsToggle = W.CreateToggle(parent, {
        label = L["Show My Rolls"],
        tooltip = L["Show notifications for your own roll results"],
        get = function() return db.profile.rollNotifications.showSelfRolls end,
        set = function(value) db.profile.rollNotifications.showSelfRolls = value end,
        disabled = not db.profile.rollNotifications.showRollResults,
    })
    yOffset = AnchorWidget(selfRollsToggle, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    groupRollsToggle = W.CreateToggle(parent, {
        label = L["Show Group Rolls"],
        tooltip = L["Show notifications for other group members' roll results"],
        get = function() return db.profile.rollNotifications.showGroupRolls end,
        set = function(value) db.profile.rollNotifications.showGroupRolls = value end,
        disabled = not db.profile.rollNotifications.showRollResults,
    })
    yOffset = AnchorWidget(groupRollsToggle, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local qualityDropdown = W.CreateDropdown(parent, {
        label = L["Minimum Quality"],
        values = ns.QualityValues,
        get = function() return tostring(db.profile.rollNotifications.minQuality) end,
        set = function(value) db.profile.rollNotifications.minQuality = tonumber(value) or 0 end,
    })
    yOffset = AnchorWidget(qualityDropdown, parent, yOffset) - SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Instance Filters
-------------------------------------------------------------------------------

local function CreateInstanceFilterSection(parent, W, db, yOffset)
    local header = W.CreateHeader(parent, L["Instance Filters"])
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    local worldToggle = W.CreateToggle(parent, {
        label = L["Show in Open World"],
        tooltip = L["Show roll notifications while in the open world"],
        get = function() return db.profile.rollNotifications.showInWorld end,
        set = function(value) db.profile.rollNotifications.showInWorld = value end,
    })
    yOffset = AnchorWidget(worldToggle, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local dungeonToggle = W.CreateToggle(parent, {
        label = L["Show in Dungeons"],
        tooltip = L["Show roll notifications while in dungeons"],
        get = function() return db.profile.rollNotifications.showInDungeon end,
        set = function(value) db.profile.rollNotifications.showInDungeon = value end,
    })
    yOffset = AnchorWidget(dungeonToggle, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    local raidToggle = W.CreateToggle(parent, {
        label = L["Show in Raids"],
        tooltip = L["Show roll notifications while in raids"],
        get = function() return db.profile.rollNotifications.showInRaid end,
        set = function(value) db.profile.rollNotifications.showInRaid = value end,
    })
    yOffset = AnchorWidget(raidToggle, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Loot Roll tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local W = ns.Widgets
    local db = dlns.Addon.db
    local yOffset = PADDING_TOP

    yOffset = CreateRollFrameSection(parent, W, db, yOffset)
    yOffset = CreateLayoutSection(parent, W, db, yOffset)
    yOffset = CreateNotificationSection(parent, W, db, yOffset)
    yOffset = CreateInstanceFilterSection(parent, W, db, yOffset)

    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "lootRoll",
    label = L["Loot Roll"],
    order = 3,
    createFunc = CreateContent,
}
