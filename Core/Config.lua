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
            timerBarTexture = "Blizzard",
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
            fontOutline = "OUTLINE",
            lootIconSize = 36,
            rollIconSize = 36,
            historyIconSize = 24,
            qualityBorder = true,
            backgroundColor = { r = 0.05, g = 0.05, b = 0.05 },
            backgroundAlpha = 0.9,
            backgroundTexture = "Solid",
            borderColor = { r = 0.3, g = 0.3, b = 0.3 },
            borderSize = 1,
            borderTexture = "None",
        },

        animation = {
            enabled = true,
            openDuration = 0.3,
            closeDuration = 0.5,
            lootOpenAnim = "fadeIn",
            lootCloseAnim = "fadeOut",
            rollShowAnim = "slideInRight",
            rollHideAnim = "fadeOut",
        },

        rollNotifications = {
            showRollWon = true,
            showGroupWins = true,
            showRollResults = true,
            showSelfRolls = true,
            showGroupRolls = true,
            minQuality = 0,
            showInWorld = true,
            showInDungeon = true,
            showInRaid = true,
        },

    },
}

-------------------------------------------------------------------------------
-- Profile Migration
-------------------------------------------------------------------------------

local CURRENT_SCHEMA = 1

local function DeepCopyValue(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopyValue(v)
    end
    return copy
end

local function FillMissingDefaults(profile)
    for section, sectionDefaults in pairs(defaults.profile) do
        if type(sectionDefaults) == "table" then
            if not profile[section] then
                profile[section] = {}
            end
            for key, defaultValue in pairs(sectionDefaults) do
                local currentValue = profile[section][key]
                -- Fill missing keys
                if currentValue == nil then
                    profile[section][key] = DeepCopyValue(defaultValue)
                -- Validate existing values: reset if type doesn't match or is invalid
                elseif type(currentValue) ~= type(defaultValue) then
                    profile[section][key] = DeepCopyValue(defaultValue)
                -- Handle nested tables (like color values {r,g,b})
                elseif type(defaultValue) == "table" then
                    local isValid = true
                    for k, v in pairs(defaultValue) do
                        if type(currentValue[k]) ~= type(v) then
                            isValid = false
                            break
                        end
                    end
                    if not isValid then
                        profile[section][key] = DeepCopyValue(defaultValue)
                    end
                end
            end
        end
    end
end

local function ResetToDefaults(profile)
    for section, sectionDefaults in pairs(defaults.profile) do
        if type(sectionDefaults) == "table" then
            profile[section] = DeepCopyValue(sectionDefaults)
        end
    end
    profile.schemaVersion = CURRENT_SCHEMA
end

local function MigrateProfile(db)
    local profile = db.profile
    local version = profile.schemaVersion or 0

    if version < 1 then
        FillMissingDefaults(profile)
    end

    -- Clean up invalid values from old defaults
    local appearance = profile.appearance
    if appearance then
        -- "Solid" was the old borderTexture default but is not a valid LSM border name
        if appearance.borderTexture == "Solid" then
            appearance.borderTexture = defaults.profile.appearance.borderTexture
        end
        -- Migrate old single iconSize to per-frame keys
        if appearance.iconSize then
            if not appearance.lootIconSize then
                appearance.lootIconSize = appearance.iconSize
            end
            if not appearance.rollIconSize then
                appearance.rollIconSize = appearance.iconSize
            end
            -- historyIconSize was always 24, don't use old iconSize for it
            appearance.iconSize = nil
        end
    end

    profile.schemaVersion = CURRENT_SCHEMA
end

-------------------------------------------------------------------------------
-- Options Table: Helper Builders
-------------------------------------------------------------------------------

local NotifyAppearanceChange  -- forward declaration; defined after BuildHistoryOptions

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
    args.timerBarTexture = {
        name = "Timer Bar Texture",
        desc = "Texture for the roll timer bar.",
        type = "select",
        order = 6,
        dialogControl = "LSM30_Statusbar",
        values = function() return LSM:HashTable("statusbar") end,
        get = function() return db.rollFrame.timerBarTexture end,
        set = function(_, val)
            db.rollFrame.timerBarTexture = val
            NotifyAppearanceChange()
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
    args.headerRollResults = {
        name = "Individual Roll Results",
        type = "header",
        order = 20,
    }
    args.showRollResults = {
        name = "Show Individual Roll Results",
        desc = "Send a DragonToast notification for each player's roll on an item, not just the winner.",
        type = "toggle",
        order = 21,
        width = "full",
        get = function() return db.rollNotifications.showRollResults end,
        set = function(_, val) db.rollNotifications.showRollResults = val end,
    }
    args.showSelfRolls = {
        name = "Show Your Rolls",
        desc = "Show notifications for your own roll results.",
        type = "toggle",
        order = 22,
        get = function() return db.rollNotifications.showSelfRolls end,
        set = function(_, val) db.rollNotifications.showSelfRolls = val end,
        disabled = function() return not db.rollNotifications.showRollResults end,
    }
    args.showGroupRolls = {
        name = "Show Group Rolls",
        desc = "Show notifications for other group members' roll results.",
        type = "toggle",
        order = 23,
        get = function() return db.rollNotifications.showGroupRolls end,
        set = function(_, val) db.rollNotifications.showGroupRolls = val end,
        disabled = function() return not db.rollNotifications.showRollResults end,
    }
    args.minQuality = {
        name = "Minimum Quality",
        desc = "Only show roll notifications for items at or above this quality.",
        type = "select",
        order = 24,
        values = {
            [0] = ITEM_QUALITY_COLORS[0].hex .. "Poor|r",
            [1] = ITEM_QUALITY_COLORS[1].hex .. "Common|r",
            [2] = ITEM_QUALITY_COLORS[2].hex .. "Uncommon|r",
            [3] = ITEM_QUALITY_COLORS[3].hex .. "Rare|r",
            [4] = ITEM_QUALITY_COLORS[4].hex .. "Epic|r",
            [5] = ITEM_QUALITY_COLORS[5].hex .. "Legendary|r",
        },
        get = function() return db.rollNotifications.minQuality end,
        set = function(_, val) db.rollNotifications.minQuality = val end,
        disabled = function()
            return not db.rollNotifications.showRollResults and not db.rollNotifications.showRollWon
        end,
    }
    args.headerInstanceFilter = {
        name = "Instance Filtering",
        type = "header",
        order = 30,
    }
    args.showInWorld = {
        name = "Show in Open World",
        desc = "Show roll notifications while in the open world.",
        type = "toggle",
        order = 31,
        get = function() return db.rollNotifications.showInWorld end,
        set = function(_, val) db.rollNotifications.showInWorld = val end,
    }
    args.showInDungeon = {
        name = "Show in Dungeons",
        desc = "Show roll notifications while in a dungeon instance.",
        type = "toggle",
        order = 32,
        get = function() return db.rollNotifications.showInDungeon end,
        set = function(_, val) db.rollNotifications.showInDungeon = val end,
    }
    args.showInRaid = {
        name = "Show in Raids",
        desc = "Show roll notifications while in a raid instance.",
        type = "toggle",
        order = 33,
        get = function() return db.rollNotifications.showInRaid end,
        set = function(_, val) db.rollNotifications.showInRaid = val end,
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

NotifyAppearanceChange = function()
    if ns.LootFrame and ns.LootFrame.ApplySettings then ns.LootFrame.ApplySettings() end
    if ns.RollManager and ns.RollManager.ApplySettings then ns.RollManager.ApplySettings() end
    if ns.HistoryFrame and ns.HistoryFrame.ApplySettings then ns.HistoryFrame.ApplySettings() end
end

local function BuildAppearanceArgs(db)
    return {
        desc = {
            name = "Customize fonts, icons, backgrounds, and borders.",
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
        fontOutline = {
            name = "Font Outline",
            desc = "Font outline style for all text.",
            type = "select",
            order = 4,
            values = {
                [""] = "None",
                ["OUTLINE"] = "Outline",
                ["THICKOUTLINE"] = "Thick Outline",
                ["MONOCHROME"] = "Monochrome",
            },
            get = function() return db.appearance.fontOutline end,
            set = function(_, val)
                db.appearance.fontOutline = val
                NotifyAppearanceChange()
            end,
        },
        headerIcon = {
            name = "Icon",
            type = "header",
            order = 10,
        },
        lootIconSize = {
            name = "Loot Icon Size",
            desc = "Size of item icons in the loot window.",
            type = "range",
            order = 11,
            min = 16, max = 64, step = 2,
            get = function() return db.appearance.lootIconSize end,
            set = function(_, val)
                db.appearance.lootIconSize = val
                NotifyAppearanceChange()
            end,
        },
        rollIconSize = {
            name = "Roll Icon Size",
            desc = "Size of item icons in the roll frame.",
            type = "range",
            order = 12,
            min = 16, max = 64, step = 2,
            get = function() return db.appearance.rollIconSize end,
            set = function(_, val)
                db.appearance.rollIconSize = val
                NotifyAppearanceChange()
            end,
        },
        historyIconSize = {
            name = "History Icon Size",
            desc = "Size of item icons in the loot history.",
            type = "range",
            order = 13,
            min = 16, max = 48, step = 2,
            get = function() return db.appearance.historyIconSize end,
            set = function(_, val)
                db.appearance.historyIconSize = val
                NotifyAppearanceChange()
            end,
        },
        qualityBorder = {
            name = "Quality Border",
            desc = "Show quality-colored borders around item icons.",
            type = "toggle",
            order = 14,
            get = function() return db.appearance.qualityBorder end,
            set = function(_, val)
                db.appearance.qualityBorder = val
                NotifyAppearanceChange()
            end,
        },
        headerBackground = {
            name = "Background",
            type = "header",
            order = 20,
        },
        backgroundColor = {
            name = "Background Color",
            desc = "Background color for all frames.",
            type = "color",
            order = 21,
            hasAlpha = false,
            get = function()
                local c = db.appearance.backgroundColor
                return c.r, c.g, c.b
            end,
            set = function(_, r, g, b)
                local c = db.appearance.backgroundColor
                c.r, c.g, c.b = r, g, b
                NotifyAppearanceChange()
            end,
        },
        backgroundAlpha = {
            name = "Background Opacity",
            desc = "Background opacity for all frames.",
            type = "range",
            order = 22,
            min = 0, max = 1, step = 0.05, isPercent = true,
            get = function() return db.appearance.backgroundAlpha end,
            set = function(_, val)
                db.appearance.backgroundAlpha = val
                NotifyAppearanceChange()
            end,
        },
        backgroundTexture = {
            name = "Background Texture",
            desc = "Background texture for all frames.",
            type = "select",
            order = 23,
            dialogControl = "LSM30_Background",
            values = function() return LSM:HashTable("background") end,
            get = function() return db.appearance.backgroundTexture end,
            set = function(_, val)
                db.appearance.backgroundTexture = val
                NotifyAppearanceChange()
            end,
        },
        headerBorder = {
            name = "Border",
            type = "header",
            order = 30,
        },
        borderColor = {
            name = "Border Color",
            desc = "Border color for all frames.",
            type = "color",
            order = 31,
            hasAlpha = false,
            get = function()
                local c = db.appearance.borderColor
                return c.r, c.g, c.b
            end,
            set = function(_, r, g, b)
                local c = db.appearance.borderColor
                c.r, c.g, c.b = r, g, b
                NotifyAppearanceChange()
            end,
        },
        borderSize = {
            name = "Border Size",
            desc = "Border thickness for all frames.",
            type = "range",
            order = 32,
            min = 0, max = 4, step = 1,
            get = function() return db.appearance.borderSize end,
            set = function(_, val)
                db.appearance.borderSize = val
                NotifyAppearanceChange()
            end,
        },
        borderTexture = {
            name = "Border Texture",
            desc = "Border texture for all frames.",
            type = "select",
            order = 33,
            dialogControl = "LSM30_Border",
            values = function() return LSM:HashTable("border") end,
            get = function() return db.appearance.borderTexture end,
            set = function(_, val)
                db.appearance.borderTexture = val
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

local function GetAnimationValues()
    local animLib = LibStub("LibAnimate")
    local names = animLib:GetAnimationNames()
    local values = {}
    for _, name in ipairs(names) do
        values[name] = name
    end
    return values
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
            headerAnimTypes = {
                name = "Animation Types",
                type = "header",
                order = 5,
            },
            lootOpenAnim = {
                name = "Loot Open Animation",
                desc = "Animation when the loot window opens.",
                type = "select",
                order = 6,
                values = GetAnimationValues,
                get = function() return db.animation.lootOpenAnim end,
                set = function(_, val) db.animation.lootOpenAnim = val end,
            },
            lootCloseAnim = {
                name = "Loot Close Animation",
                desc = "Animation when the loot window closes.",
                type = "select",
                order = 7,
                values = GetAnimationValues,
                get = function() return db.animation.lootCloseAnim end,
                set = function(_, val) db.animation.lootCloseAnim = val end,
            },
            rollShowAnim = {
                name = "Roll Show Animation",
                desc = "Animation when a roll frame appears.",
                type = "select",
                order = 8,
                values = GetAnimationValues,
                get = function() return db.animation.rollShowAnim end,
                set = function(_, val) db.animation.rollShowAnim = val end,
            },
            rollHideAnim = {
                name = "Roll Hide Animation",
                desc = "Animation when a roll frame disappears.",
                type = "select",
                order = 9,
                values = GetAnimationValues,
                get = function() return db.animation.rollHideAnim end,
                set = function(_, val) db.animation.rollHideAnim = val end,
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

    -- Re-migrate on profile changes and refresh UI
    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
    addon.db.RegisterCallback(addon, "OnProfileChanged", function()
        MigrateProfile(addon.db)
        NotifyAppearanceChange()
        AceConfigRegistry:NotifyChange(ADDON_NAME)
    end)
    addon.db.RegisterCallback(addon, "OnProfileCopied", function()
        MigrateProfile(addon.db)
        NotifyAppearanceChange()
        AceConfigRegistry:NotifyChange(ADDON_NAME)
    end)
    addon.db.RegisterCallback(addon, "OnProfileReset", function()
        ResetToDefaults(addon.db.profile)
        NotifyAppearanceChange()
        AceConfigRegistry:NotifyChange(ADDON_NAME)
    end)

    -- Register options
    AceConfig:RegisterOptionsTable(ADDON_NAME, GetOptions)
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "DragonLoot")
end
