-------------------------------------------------------------------------------
-- NotificationsTab.lua
-- Roll notification settings: roll won, roll results, instance filters
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local tostring = tostring
local tonumber = tonumber

-------------------------------------------------------------------------------
-- DragonWidgets references
-------------------------------------------------------------------------------

local W  = ns.DW.Widgets
local LC = ns.DW.LayoutConstants

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- Section: Roll Notifications
-------------------------------------------------------------------------------

local function CreateNotificationSection(parent, db, yOffset)
    local section = W.CreateSection(parent, "Roll Notifications")
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    -- Forward declarations for cross-widget disable logic
    local groupWinsToggle, selfRollsToggle, groupRollsToggle

    local showRollWon = W.CreateToggle(content, {
        label = "Show Roll Won",
        tooltip = "Show a notification when someone wins a roll",
        get = function() return db.profile.rollNotifications.showRollWon end,
        set = function(value)
            db.profile.rollNotifications.showRollWon = value
            if groupWinsToggle then groupWinsToggle:SetDisabled(not value) end
        end,
    })
    innerY = LC.AnchorWidget(showRollWon, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    groupWinsToggle = W.CreateToggle(content, {
        label = "Show Group Wins",
        tooltip = "Show notifications when other group members win rolls",
        get = function() return db.profile.rollNotifications.showGroupWins end,
        set = function(value) db.profile.rollNotifications.showGroupWins = value end,
        disabled = not db.profile.rollNotifications.showRollWon,
    })
    innerY = LC.AnchorWidget(groupWinsToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local showRollResults = W.CreateToggle(content, {
        label = "Show Roll Results",
        tooltip = "Show individual roll result notifications",
        get = function() return db.profile.rollNotifications.showRollResults end,
        set = function(value)
            db.profile.rollNotifications.showRollResults = value
            if selfRollsToggle then selfRollsToggle:SetDisabled(not value) end
            if groupRollsToggle then groupRollsToggle:SetDisabled(not value) end
        end,
    })
    innerY = LC.AnchorWidget(showRollResults, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    selfRollsToggle = W.CreateToggle(content, {
        label = "Show My Rolls",
        tooltip = "Show notifications for your own roll results",
        get = function() return db.profile.rollNotifications.showSelfRolls end,
        set = function(value) db.profile.rollNotifications.showSelfRolls = value end,
        disabled = not db.profile.rollNotifications.showRollResults,
    })
    innerY = LC.AnchorWidget(selfRollsToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    groupRollsToggle = W.CreateToggle(content, {
        label = "Show Group Rolls",
        tooltip = "Show notifications for other group members' roll results",
        get = function() return db.profile.rollNotifications.showGroupRolls end,
        set = function(value) db.profile.rollNotifications.showGroupRolls = value end,
        disabled = not db.profile.rollNotifications.showRollResults,
    })
    innerY = LC.AnchorWidget(groupRollsToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local qualityDropdown = W.CreateDropdown(content, {
        label = "Minimum Quality",
        values = ns.QualityValues,
        get = function() return tostring(db.profile.rollNotifications.minQuality) end,
        set = function(value)
            db.profile.rollNotifications.minQuality = tonumber(value) or 0
        end,
    })
    innerY = LC.AnchorWidget(qualityDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Section: Instance Filters
-------------------------------------------------------------------------------

local function CreateInstanceFilterSection(parent, db, yOffset)
    local section = W.CreateSection(parent, "Instance Filters")
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local worldToggle = W.CreateToggle(content, {
        label = "Show in Open World",
        tooltip = "Show roll notifications while in the open world",
        get = function() return db.profile.rollNotifications.showInWorld end,
        set = function(value) db.profile.rollNotifications.showInWorld = value end,
    })
    innerY = LC.AnchorWidget(worldToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local dungeonToggle = W.CreateToggle(content, {
        label = "Show in Dungeons",
        tooltip = "Show roll notifications while in dungeons",
        get = function() return db.profile.rollNotifications.showInDungeon end,
        set = function(value) db.profile.rollNotifications.showInDungeon = value end,
    })
    innerY = LC.AnchorWidget(dungeonToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local raidToggle = W.CreateToggle(content, {
        label = "Show in Raids",
        tooltip = "Show roll notifications while in raids",
        get = function() return db.profile.rollNotifications.showInRaid end,
        set = function(value) db.profile.rollNotifications.showInRaid = value end,
    })
    innerY = LC.AnchorWidget(raidToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Notifications tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local db = dlns.Addon.db
    local yOffset = LC.PADDING_TOP

    yOffset = CreateNotificationSection(parent, db, yOffset)
    yOffset = CreateInstanceFilterSection(parent, db, yOffset)

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "notifications",
    label = "Notifications",
    order = 5,
    createFunc = CreateContent,
}
