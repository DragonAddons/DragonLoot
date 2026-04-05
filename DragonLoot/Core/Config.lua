-------------------------------------------------------------------------------
-- Config.lua
-- DragonLoot configuration: AceDB defaults, schema migration
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

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
            width = 250,
            height = 300,
            slotSpacing = 2,
            contentPadding = 4,
            positionAtCursor = false,
        },

        rollFrame = {
            enabled = true,
            scale = 1.0,
            lock = false,
            timerBarHeight = 12,
            timerBarTexture = "Blizzard",
            timerBarBorder = false,
            timerBarBorderColor = { r = 0.3, g = 0.3, b = 0.3 },
            timerBarColorMode = "gradient",
            timerBarColor = { r = 0, g = 1, b = 0 },
            timerBarBackgroundColor = { r = 0.1, g = 0.1, b = 0.1 },
            timerBarBackgroundAlpha = 0.8,
            frameWidth = 328,
            rowSpacing = 4,
            timerBarSpacing = 4,
            contentPadding = 4,
            buttonSize = 24,
            buttonSpacing = 4,
            frameSpacing = 4,
            frameMinHeight = 68,
            compactTextLayout = false,
            hideOnVote = false,
            timerBarStyle = "normal",
            timerBarMinimalHeight = 3,
        },

        history = {
            enabled = true,
            maxEntries = 100,
            autoShow = false,
            lock = false,
            trackDirectLoot = true,
            minQuality = 2,  -- Uncommon
            entrySpacing = 2,
            contentPadding = 6,
            showRollDetails = true,
        },

        appearance = {
            font = "Friz Quadrata TT",
            fontSize = 12,
            fontOutline = "OUTLINE",
            fontShadow = true,
            lootIconSize = 36,
            rollIconSize = 36,
            historyIconSize = 24,
            qualityBorder = true,
            showItemLevel = true,
            slotBackground = "gradient",
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

        autoLoot = {
            enabled = false,
            minQuality = 4,  -- Epic
            whitelist = {},   -- { [itemID] = true }
            blacklist = {},   -- { [itemID] = true }
        },

    },
}

-------------------------------------------------------------------------------
-- Profile Migration
-------------------------------------------------------------------------------

local CURRENT_SCHEMA = 2

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

    -- Always fill missing defaults on any migration
    if version < CURRENT_SCHEMA then
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
-- Notify Appearance Change
-------------------------------------------------------------------------------

local function NotifyAppearanceChange()
    if ns.LootFrame and ns.LootFrame.ApplySettings then ns.LootFrame.ApplySettings() end
    if ns.RollManager and ns.RollManager.ApplySettings then ns.RollManager.ApplySettings() end
    if ns.HistoryFrame and ns.HistoryFrame.ApplySettings then ns.HistoryFrame.ApplySettings() end
end

-------------------------------------------------------------------------------
-- Initialization (called from Init.lua OnInitialize)
-------------------------------------------------------------------------------

function ns.InitializeDB(addon)
    addon.db = LibStub("AceDB-3.0"):New("DragonLootDB", defaults, true)

    -- Migrate active profile
    MigrateProfile(addon.db)

    -- Re-migrate on profile changes and refresh UI
    addon.db.RegisterCallback(addon, "OnProfileChanged", function()
        MigrateProfile(addon.db)
        NotifyAppearanceChange()
    end)
    addon.db.RegisterCallback(addon, "OnProfileCopied", function()
        MigrateProfile(addon.db)
        NotifyAppearanceChange()
    end)
    addon.db.RegisterCallback(addon, "OnProfileReset", function()
        ResetToDefaults(addon.db.profile)
        NotifyAppearanceChange()
    end)
end
