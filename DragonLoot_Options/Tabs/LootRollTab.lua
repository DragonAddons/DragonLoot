-------------------------------------------------------------------------------
-- LootRollTab.lua
-- Loot Roll settings tab: roll frame layout, notifications, instance filters
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local table_sort = table.sort
local LibStub = LibStub

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------

local L = ns.L

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

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
-- Section: Roll Frame (basic settings)
-------------------------------------------------------------------------------

local function CreateRollFrameSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Roll Frame"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Enable Custom Roll Frame"],
        tooltip = L["Replace the default Blizzard roll frame with DragonLoot's custom version"],
        get = function() return db.profile.rollFrame.enabled end,
        set = function(value)
            db.profile.rollFrame.enabled = value
            NotifyRollManager()
        end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Lock Position"],
        tooltip = L["Prevent the roll frame from being dragged"],
        get = function() return db.profile.rollFrame.lock end,
        set = function(value) db.profile.rollFrame.lock = value end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Section: Layout (sliders + texture dropdown)
-------------------------------------------------------------------------------

local function AddLayoutSlider(stack, parent, db, label, tooltip, key, min, max, step, fmt)
    stack:AddChild(LDF.CreateSlider(parent, {
        label = label, tooltip = tooltip,
        min = min, max = max, step = step, format = fmt,
        get = function() return db.profile.rollFrame[key] end,
        set = function(value) db.profile.rollFrame[key] = value; NotifyRollManager() end,
    }))
end

local function CreateLayoutSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Layout"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    AddLayoutSlider(stack, section.content, db,
        L["Scale"], L["Roll frame scale"], "scale", 0.5, 2, 0.05, "%.2f")
    AddLayoutSlider(stack, section.content, db,
        L["Frame Width"], L["Width of the roll frame"], "frameWidth", 200, 500, 10, "%d")
    AddLayoutSlider(stack, section.content, db,
        L["Row Spacing"], L["Vertical spacing between roll rows"], "rowSpacing", 0, 16, 1, "%d")
    AddLayoutSlider(stack, section.content, db,
        L["Timer Bar Height"], L["Height of the countdown timer bar"],
        "timerBarHeight", 6, 24, 1, "%d")
    AddLayoutSlider(stack, section.content, db,
        L["Timer Bar Spacing"], L["Space between item row and timer bar"],
        "timerBarSpacing", 0, 16, 1, "%d")
    AddLayoutSlider(stack, section.content, db,
        L["Content Padding"], L["Inner padding of the roll frame"],
        "contentPadding", 0, 12, 1, "%d")
    AddLayoutSlider(stack, section.content, db,
        L["Button Size"], L["Size of Need/Greed/Pass buttons"], "buttonSize", 16, 36, 1, "%d")
    AddLayoutSlider(stack, section.content, db,
        L["Button Spacing"], L["Spacing between roll buttons"], "buttonSpacing", 0, 12, 1, "%d")
    AddLayoutSlider(stack, section.content, db,
        L["Frame Spacing"], L["Spacing between multiple roll frames"],
        "frameSpacing", 0, 16, 1, "%d")

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Timer Bar Texture"],
        values = GetStatusBarValues,
        sort = true,
        mediaType = "statusbar",
        get = function() return db.profile.rollFrame.timerBarTexture end,
        set = function(value)
            db.profile.rollFrame.timerBarTexture = value
            NotifyRollManager()
        end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Section: Roll Notifications
-------------------------------------------------------------------------------

local function CreateNotificationSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Roll Notifications"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    -- Forward declarations for cross-widget disable logic
    local groupWinsToggle, selfRollsToggle, groupRollsToggle

    local showRollWonToggle = LDF.CreateToggle(section.content, {
        label = L["Show Roll Won"],
        tooltip = L["Show a notification when someone wins a roll"],
        get = function() return db.profile.rollNotifications.showRollWon end,
        set = function(value)
            db.profile.rollNotifications.showRollWon = value
            if groupWinsToggle then groupWinsToggle:SetDisabled(not value) end
        end,
    })
    stack:AddChild(showRollWonToggle)

    groupWinsToggle = LDF.CreateToggle(section.content, {
        label = L["Show Group Wins"],
        tooltip = L["Show notifications when other group members win rolls"],
        get = function() return db.profile.rollNotifications.showGroupWins end,
        set = function(value) db.profile.rollNotifications.showGroupWins = value end,
        disabled = not db.profile.rollNotifications.showRollWon,
    })
    stack:AddChild(groupWinsToggle)

    local showRollResultsToggle = LDF.CreateToggle(section.content, {
        label = L["Show Roll Results"],
        tooltip = L["Show individual roll result notifications"],
        get = function() return db.profile.rollNotifications.showRollResults end,
        set = function(value)
            db.profile.rollNotifications.showRollResults = value
            if selfRollsToggle then selfRollsToggle:SetDisabled(not value) end
            if groupRollsToggle then groupRollsToggle:SetDisabled(not value) end
        end,
    })
    stack:AddChild(showRollResultsToggle)

    selfRollsToggle = LDF.CreateToggle(section.content, {
        label = L["Show My Rolls"],
        tooltip = L["Show notifications for your own roll results"],
        get = function() return db.profile.rollNotifications.showSelfRolls end,
        set = function(value) db.profile.rollNotifications.showSelfRolls = value end,
        disabled = not db.profile.rollNotifications.showRollResults,
    })
    stack:AddChild(selfRollsToggle)

    groupRollsToggle = LDF.CreateToggle(section.content, {
        label = L["Show Group Rolls"],
        tooltip = L["Show notifications for other group members' roll results"],
        get = function() return db.profile.rollNotifications.showGroupRolls end,
        set = function(value) db.profile.rollNotifications.showGroupRolls = value end,
        disabled = not db.profile.rollNotifications.showRollResults,
    })
    stack:AddChild(groupRollsToggle)

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Minimum Quality"],
        values = ns.QualityValues,
        get = function() return tostring(db.profile.rollNotifications.minQuality) end,
        set = function(value) db.profile.rollNotifications.minQuality = tonumber(value) or 0 end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Section: Instance Filters
-------------------------------------------------------------------------------

local function CreateInstanceFilterSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["Instance Filters"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show in Open World"],
        tooltip = L["Show roll notifications while in the open world"],
        get = function() return db.profile.rollNotifications.showInWorld end,
        set = function(value) db.profile.rollNotifications.showInWorld = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show in Dungeons"],
        tooltip = L["Show roll notifications while in dungeons"],
        get = function() return db.profile.rollNotifications.showInDungeon end,
        set = function(value) db.profile.rollNotifications.showInDungeon = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show in Raids"],
        tooltip = L["Show roll notifications while in raids"],
        get = function() return db.profile.rollNotifications.showInRaid end,
        set = function(value) db.profile.rollNotifications.showInRaid = value end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Build the Loot Roll tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local stack = LDF.CreateStackLayout(parent, "vertical")

    stack:AddChild(CreateRollFrameSection(parent))
    stack:AddChild(CreateLayoutSection(parent))
    stack:AddChild(CreateNotificationSection(parent))
    stack:AddChild(CreateInstanceFilterSection(parent))
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
