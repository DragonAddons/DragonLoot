-------------------------------------------------------------------------------
-- Config.lua
-- DragonLoot configuration: AceDB defaults, AceConfig options, GUI panel
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- Database Defaults
-------------------------------------------------------------------------------

local defaults = {
    profile = {
        enabled = true,
        debug = false,

        minimap = {
            hide = false,
        },

        lootWindow = {
            enabled = true,
            scale = 1.0,
            lock = false,
            width = 220,
            height = 300,
        },

        rollFrame = {
            enabled = true,
            scale = 1.0,
            lock = false,
            timerBarHeight = 12,
        },

        history = {
            enabled = true,
            maxEntries = 100,
            autoShow = false,
            lock = false,
        },

        appearance = {
            font = "Friz Quadrata TT",
            fontSize = 12,
            iconSize = 36,
        },

        animation = {
            enabled = true,
            openDuration = 0.3,
            closeDuration = 0.5,
        },

        rollNotifications = {
            showRollWon = true,
            showGroupWins = false,
        },

    },
}

-------------------------------------------------------------------------------
-- Profile Migration
-------------------------------------------------------------------------------

local CURRENT_SCHEMA = 1

local function FillMissingDefaults(profile)
    for section, sectionDefaults in pairs(defaults.profile) do
        if type(sectionDefaults) == "table" then
            if not profile[section] then
                profile[section] = {}
            end
            for key, value in pairs(sectionDefaults) do
                if profile[section][key] == nil then
                    profile[section][key] = value
                end
            end
        end
    end
end

local function MigrateProfile(db)
    local profile = db.profile
    local version = profile.schemaVersion or 0

    if version < 1 then
        FillMissingDefaults(profile)
    end

    profile.schemaVersion = CURRENT_SCHEMA
end

-------------------------------------------------------------------------------
-- Options Table: Helper Builders
-------------------------------------------------------------------------------

local function SetMasterEnabled(_, val)
    ns.Addon.db.profile.enabled = val
    if val then
        ns.Addon:OnEnable()
    else
        ns.Addon:OnDisable()
    end
end

local function SetMinimapVisible(_, val)
    ns.Addon.db.profile.minimap.hide = not val
    if ns.MinimapIcon.Refresh then
        ns.MinimapIcon.Refresh()
    end
end

local function BuildGeneralArgs(db)
    return {
        desc = {
            name = "General settings for DragonLoot.",
            type = "description",
            order = 0,
            fontSize = "medium",
        },
        headerControls = {
            name = "Controls",
            type = "header",
            order = 1,
        },
        enabled = {
            name = "Enable DragonLoot",
            desc = "Master toggle for the loot replacement.",
            type = "toggle",
            order = 2,
            width = "full",
            get = function() return db.enabled end,
            set = SetMasterEnabled,
        },
        minimapIcon = {
            name = "Show Minimap Icon",
            desc = "Show or hide the DragonLoot minimap button.",
            type = "toggle",
            order = 3,
            get = function() return not db.minimap.hide end,
            set = SetMinimapVisible,
        },
        debug = {
            name = "Debug Mode",
            desc = "Enable debug output in chat.",
            type = "toggle",
            order = 4,
            get = function() return db.debug end,
            set = function(_, val) db.debug = val end,
        },
    }
end

local function BuildGeneralOptions(db)
    return {
        name = "General",
        type = "group",
        order = 1,
        args = BuildGeneralArgs(db),
    }
end

local function SetLootWindowEnabled(_, val)
    ns.Addon.db.profile.lootWindow.enabled = val
    if ns.LootFrame.ApplySettings then
        ns.LootFrame.ApplySettings()
    end
end

local function BuildLootWindowArgs(db)
    return {
        desc = {
            name = "Configure the replacement loot window.",
            type = "description",
            order = 0,
            fontSize = "medium",
        },
        headerLoot = {
            name = "Loot Window",
            type = "header",
            order = 1,
        },
        enabled = {
            name = "Replace Loot Window",
            desc = "Use DragonLoot's loot window instead of the default.",
            type = "toggle",
            order = 2,
            width = "full",
            get = function() return db.lootWindow.enabled end,
            set = SetLootWindowEnabled,
        },
        scale = {
            name = "Scale",
            desc = "Scale of the loot window.",
            type = "range",
            order = 3,
            min = 0.5, max = 2.0, step = 0.05,
            get = function() return db.lootWindow.scale end,
            set = function(_, val)
                db.lootWindow.scale = val
                if ns.LootFrame.ApplySettings then
                    ns.LootFrame.ApplySettings()
                end
            end,
        },
        lock = {
            name = "Lock Position",
            desc = "Prevent the loot window from being dragged.",
            type = "toggle",
            order = 4,
            get = function() return db.lootWindow.lock end,
            set = function(_, val) db.lootWindow.lock = val end,
        },
    }
end

local function BuildLootWindowSizeArgs(db)
    return {
        width = {
            name = "Width",
            desc = "Width of the loot window in pixels.",
            type = "range",
            order = 5,
            min = 150, max = 400, step = 10,
            get = function() return db.lootWindow.width end,
            set = function(_, val)
                db.lootWindow.width = val
                if ns.LootFrame.ApplySettings then
                    ns.LootFrame.ApplySettings()
                end
            end,
        },
        height = {
            name = "Height",
            desc = "Height of the loot window in pixels.",
            type = "range",
            order = 6,
            min = 150, max = 600, step = 10,
            get = function() return db.lootWindow.height end,
            set = function(_, val)
                db.lootWindow.height = val
                if ns.LootFrame.ApplySettings then
                    ns.LootFrame.ApplySettings()
                end
            end,
        },
    }
end

local function BuildLootWindowOptions(db)
    local args = BuildLootWindowArgs(db)
    local sizeArgs = BuildLootWindowSizeArgs(db)
    for k, v in pairs(sizeArgs) do
        args[k] = v
    end
    return {
        name = "Loot Window",
        type = "group",
        order = 2,
        args = args,
    }
end

local function SetRollEnabled(_, val)
    ns.Addon.db.profile.rollFrame.enabled = val
    if ns.RollManager.ApplySettings then
        ns.RollManager.ApplySettings()
    end
end

local function BuildLootRollArgs(db)
    return {
        desc = {
            name = "Configure the replacement loot roll frame.",
            type = "description",
            order = 0,
            fontSize = "medium",
        },
        headerRoll = {
            name = "Loot Roll",
            type = "header",
            order = 1,
        },
        enabled = {
            name = "Replace Roll Frame",
            desc = "Use DragonLoot's roll frame instead of the default.",
            type = "toggle",
            order = 2,
            width = "full",
            get = function() return db.rollFrame.enabled end,
            set = SetRollEnabled,
        },
        scale = {
            name = "Scale",
            desc = "Scale of the roll frame.",
            type = "range",
            order = 3,
            min = 0.5, max = 2.0, step = 0.05,
            get = function() return db.rollFrame.scale end,
            set = function(_, val)
                db.rollFrame.scale = val
                if ns.RollManager.ApplySettings then
                    ns.RollManager.ApplySettings()
                end
            end,
        },
        lock = {
            name = "Lock Position",
            desc = "Prevent the roll frame from being dragged.",
            type = "toggle",
            order = 4,
            get = function() return db.rollFrame.lock end,
            set = function(_, val) db.rollFrame.lock = val end,
        },
    }
end

local function BuildLootRollOptions(db)
    local args = BuildLootRollArgs(db)
    args.timerBarHeight = {
        name = "Timer Bar Height",
        desc = "Height of the roll timer bar in pixels.",
        type = "range",
        order = 5,
        min = 6, max = 24, step = 1,
        get = function() return db.rollFrame.timerBarHeight end,
        set = function(_, val)
            db.rollFrame.timerBarHeight = val
            if ns.RollManager.ApplySettings then
                ns.RollManager.ApplySettings()
            end
        end,
    }
    args.headerRollWon = {
        name = "Roll Won Notifications",
        type = "header",
        order = 10,
    }
    args.showRollWon = {
        name = "Show Roll Won Toasts",
        desc = "Send a DragonToast notification when you win a loot roll.",
        type = "toggle",
        order = 11,
        width = "full",
        get = function() return db.rollNotifications.showRollWon end,
        set = function(_, val) db.rollNotifications.showRollWon = val end,
    }
    args.showGroupWins = {
        name = "Show Group Roll Wins",
        desc = "Also show DragonToast notifications when other group members win rolls.",
        type = "toggle",
        order = 12,
        get = function() return db.rollNotifications.showGroupWins end,
        set = function(_, val) db.rollNotifications.showGroupWins = val end,
        disabled = function() return not db.rollNotifications.showRollWon end,
    }
    return {
        name = "Loot Roll",
        type = "group",
        order = 3,
        args = args,
    }
end

local function BuildHistoryArgs(db)
    return {
        desc = {
            name = "Configure the loot history panel.",
            type = "description",
            order = 0,
            fontSize = "medium",
        },
        headerHistory = {
            name = "Loot History",
            type = "header",
            order = 1,
        },
        enabled = {
            name = "Enable History",
            desc = "Track looted items in a history panel.",
            type = "toggle",
            order = 2,
            width = "full",
            get = function() return db.history.enabled end,
            set = function(_, val)
                db.history.enabled = val
                if ns.HistoryFrame.ApplySettings then
                    ns.HistoryFrame.ApplySettings()
                end
            end,
        },
        maxEntries = {
            name = "Max Entries",
            desc = "Maximum number of loot entries to keep.",
            type = "range",
            order = 3,
            min = 10, max = 500, step = 10,
            get = function() return db.history.maxEntries end,
            set = function(_, val) db.history.maxEntries = val end,
        },
        autoShow = {
            name = "Auto Show",
            desc = "Automatically show the history panel when loot is received.",
            type = "toggle",
            order = 4,
            get = function() return db.history.autoShow end,
            set = function(_, val) db.history.autoShow = val end,
        },
        lock = {
            name = "Lock Position",
            desc = "Prevent the history panel from being dragged.",
            type = "toggle",
            order = 5,
            get = function() return db.history.lock end,
            set = function(_, val) db.history.lock = val end,
        },
    }
end

local function BuildHistoryOptions(db)
    return {
        name = "History",
        type = "group",
        order = 4,
        args = BuildHistoryArgs(db),
    }
end

local function NotifyAppearanceChange()
    if ns.LootFrame and ns.LootFrame.ApplySettings then ns.LootFrame.ApplySettings() end
    if ns.RollManager and ns.RollManager.ApplySettings then ns.RollManager.ApplySettings() end
    if ns.HistoryFrame and ns.HistoryFrame.ApplySettings then ns.HistoryFrame.ApplySettings() end
end

local function BuildAppearanceArgs(db)
    return {
        desc = {
            name = "Customize fonts and icon sizing.",
            type = "description",
            order = 0,
            fontSize = "medium",
        },
        headerFont = {
            name = "Font",
            type = "header",
            order = 1,
        },
        font = {
            name = "Font Face",
            desc = "Font for all DragonLoot text.",
            type = "select",
            order = 2,
            dialogControl = "LSM30_Font",
            values = function() return LSM:HashTable("font") end,
            get = function() return db.appearance.font end,
            set = function(_, val)
                db.appearance.font = val
                NotifyAppearanceChange()
            end,
        },
        fontSize = {
            name = "Font Size",
            desc = "Size of text in loot frames.",
            type = "range",
            order = 3,
            min = 8, max = 20, step = 1,
            get = function() return db.appearance.fontSize end,
            set = function(_, val)
                db.appearance.fontSize = val
                NotifyAppearanceChange()
            end,
        },
        headerIcon = {
            name = "Icon",
            type = "header",
            order = 10,
        },
        iconSize = {
            name = "Icon Size",
            desc = "Size of item icons in pixels.",
            type = "range",
            order = 11,
            min = 16, max = 64, step = 2,
            get = function() return db.appearance.iconSize end,
            set = function(_, val)
                db.appearance.iconSize = val
                NotifyAppearanceChange()
            end,
        },
    }
end

local function BuildAppearanceOptions(db)
    return {
        name = "Appearance",
        type = "group",
        order = 5,
        args = BuildAppearanceArgs(db),
    }
end

local function BuildAnimationOptions(db)
    return {
        name = "Animation",
        type = "group",
        order = 6,
        args = {
            desc = {
                name = "Configure open and close animation timing.",
                type = "description",
                order = 0,
                fontSize = "medium",
            },
            headerAnimation = {
                name = "Animation",
                type = "header",
                order = 1,
            },
            enabled = {
                name = "Enable Animations",
                desc = "Toggle open and close animations.",
                type = "toggle",
                order = 2,
                width = "full",
                get = function() return db.animation.enabled end,
                set = function(_, val) db.animation.enabled = val end,
            },
            openDuration = {
                name = "Open Duration",
                desc = "How long the open animation takes (seconds).",
                type = "range",
                order = 3,
                min = 0.1, max = 1.0, step = 0.05,
                get = function() return db.animation.openDuration end,
                set = function(_, val) db.animation.openDuration = val end,
            },
            closeDuration = {
                name = "Close Duration",
                desc = "How long the close animation takes (seconds).",
                type = "range",
                order = 4,
                min = 0.1, max = 1.0, step = 0.05,
                get = function() return db.animation.closeDuration end,
                set = function(_, val) db.animation.closeDuration = val end,
            },
        },
    }
end

-------------------------------------------------------------------------------
-- Options Table
-------------------------------------------------------------------------------

local function GetOptions()
    local db = ns.Addon.db.profile

    local options = {
        name = "DragonLoot",
        handler = ns.Addon,
        type = "group",
        args = {
            general = BuildGeneralOptions(db),
            lootWindow = BuildLootWindowOptions(db),
            lootRoll = BuildLootRollOptions(db),
            history = BuildHistoryOptions(db),
            appearance = BuildAppearanceOptions(db),
            animation = BuildAnimationOptions(db),
            profiles = AceDBOptions:GetOptionsTable(ns.Addon.db),
        },
    }

    options.args.profiles.order = 7

    return options
end

-------------------------------------------------------------------------------
-- Initialization (called from Init.lua OnInitialize)
-------------------------------------------------------------------------------

function ns.InitializeDB(addon)
    addon.db = LibStub("AceDB-3.0"):New("DragonLootDB", defaults, true)

    -- Migrate active profile
    MigrateProfile(addon.db)

    -- Re-migrate on profile changes
    addon.db:RegisterCallback(addon, "OnProfileChanged", function() MigrateProfile(addon.db) end)
    addon.db:RegisterCallback(addon, "OnProfileCopied", function() MigrateProfile(addon.db) end)
    addon.db:RegisterCallback(addon, "OnProfileReset", function() MigrateProfile(addon.db) end)

    -- Register options
    AceConfig:RegisterOptionsTable(ADDON_NAME, GetOptions)
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "DragonLoot")
end
