-------------------------------------------------------------------------------
-- Init.lua
-- DragonLoot addon bootstrap and namespace setup
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

ns.ADDON_NAME = ADDON_NAME
ns.ADDON_TITLE = "DragonLoot"
ns.VERSION = "@project-version@"

-- Color constants
ns.COLOR_GOLD = "|cffffd700"
ns.COLOR_GREEN = "|cff00ff00"
ns.COLOR_RED = "|cffff0000"
ns.COLOR_GRAY = "|cff888888"
ns.COLOR_WHITE = "|cffffffff"
ns.COLOR_RESET = "|r"

-- Quality colors (fallback, also available via ITEM_QUALITY_COLORS)
ns.QUALITY_COLORS = {
    [0] = { r = 0.62, g = 0.62, b = 0.62 }, -- Poor
    [1] = { r = 1.00, g = 1.00, b = 1.00 }, -- Common
    [2] = { r = 0.12, g = 1.00, b = 0.00 }, -- Uncommon
    [3] = { r = 0.00, g = 0.44, b = 0.87 }, -- Rare
    [4] = { r = 0.64, g = 0.21, b = 0.93 }, -- Epic
    [5] = { r = 1.00, g = 0.50, b = 0.00 }, -- Legendary
    [6] = { r = 0.90, g = 0.80, b = 0.50 }, -- Artifact
    [7] = { r = 0.00, g = 0.80, b = 1.00 }, -- Heirloom
}

-------------------------------------------------------------------------------
-- Namespace sub-tables (populated by other files)
-------------------------------------------------------------------------------

ns.LootFrame = {}
ns.LootAnimations = {}
ns.RollFrame = {}
ns.RollAnimations = {}
ns.RollManager = {}
ns.RollListener = {}
ns.HistoryFrame = {}
ns.HistoryListener = {}
ns.ConfigWindow = {}
ns.MinimapIcon = {}
ns.Listeners = {}

-------------------------------------------------------------------------------
-- AceAddon Setup
-------------------------------------------------------------------------------

local Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
ns.Addon = Addon

-------------------------------------------------------------------------------
-- Utility: Print with addon prefix
-------------------------------------------------------------------------------

function ns.Print(msg)
    print(ns.COLOR_GOLD .. "[DragonLoot]|r " .. msg)
end

function ns.DebugPrint(msg)
    local db = ns.Addon.db
    if db and db.profile and db.profile.debug then
        print(ns.COLOR_GRAY .. "[DragonLoot Debug]|r " .. msg)
    end
end

-------------------------------------------------------------------------------
-- Utility: Number formatting (shared across modules)
-------------------------------------------------------------------------------

function ns.FormatNumber(num)
    if num >= 1000000 then
        local divided = num / 1000000
        if math.floor(divided) == divided then
            return string.format("%dM", divided)
        end
        return string.format("%.1fM", divided)
    elseif num >= 1000 then
        local divided = num / 1000
        if math.floor(divided) == divided then
            return string.format("%dK", divided)
        end
        return string.format("%.1fK", divided)
    end
    return tostring(num)
end

-------------------------------------------------------------------------------
-- Blizzard Frame Suppression
-------------------------------------------------------------------------------

-- Events the default group roll frames listen for
local ROLL_FRAME_EVENTS = {
    "START_LOOT_ROLL", "CANCEL_LOOT_ROLL",
}

local function SuppressBlizzardLootFrame()
    if not LootFrame then return end
    LootFrame:UnregisterAllEvents()
    LootFrame:Hide()
end

local function SuppressBlizzardRollFrames()
    for i = 1, 4 do
        local frame = _G["GroupLootFrame" .. i]
        if frame then
            frame:UnregisterAllEvents()
            frame:Hide()
        end
    end
    if GroupLootContainer then
        GroupLootContainer:UnregisterAllEvents()
        GroupLootContainer:Hide()
    end
end

local function RestoreBlizzardLootFrame()
    if not LootFrame then return end
    -- Only restore the base events all versions register at load time.
    -- Dynamic events (LOOT_SLOT_CLEARED, LOOT_SLOT_CHANGED) are re-registered
    -- by Blizzard's own OnShow handler when the frame next shows.
    LootFrame:RegisterEvent("LOOT_OPENED")
    LootFrame:RegisterEvent("LOOT_CLOSED")
end

local function RestoreBlizzardRollFrames()
    for i = 1, 4 do
        local frame = _G["GroupLootFrame" .. i]
        if frame then
            for _, event in ipairs(ROLL_FRAME_EVENTS) do
                frame:RegisterEvent(event)
            end
        end
    end
    if GroupLootContainer then
        GroupLootContainer:RegisterEvent("START_LOOT_ROLL")
        GroupLootContainer:RegisterEvent("CANCEL_LOOT_ROLL")
    end
end

-- Expose for use in other modules
ns.SuppressBlizzardLootFrame = SuppressBlizzardLootFrame
ns.SuppressBlizzardRollFrames = SuppressBlizzardRollFrames
ns.RestoreBlizzardLootFrame = RestoreBlizzardLootFrame
ns.RestoreBlizzardRollFrames = RestoreBlizzardRollFrames

-------------------------------------------------------------------------------
-- AceAddon Lifecycle
-------------------------------------------------------------------------------

function Addon:OnInitialize()
    ns.InitializeDB(self)

    self:RegisterChatCommand("dragonloot", "OnSlashCommand")
    self:RegisterChatCommand("dl", "OnSlashCommand")

    if ns.MinimapIcon.Initialize then
        ns.MinimapIcon.Initialize()
    end

    ns.Print("Loaded. Type " .. ns.COLOR_WHITE .. "/dl help" .. ns.COLOR_RESET .. " for commands.")
end

function Addon:OnEnable()
    local db = self.db and self.db.profile
    if not db or not db.enabled then return end

    -- Suppress Blizzard frames when our replacement is enabled
    if db.lootWindow and db.lootWindow.enabled then
        SuppressBlizzardLootFrame()
    end
    if db.rollFrame and db.rollFrame.enabled then
        SuppressBlizzardRollFrames()
    end

    -- Initialize modules if present
    if ns.LootFrame.Initialize then ns.LootFrame.Initialize() end
    if ns.RollManager.Initialize then ns.RollManager.Initialize() end
    if ns.HistoryFrame.Initialize then ns.HistoryFrame.Initialize() end
    if ns.HistoryListener.Initialize then ns.HistoryListener.Initialize(self) end
    if ns.Listeners.Initialize then ns.Listeners.Initialize(self) end


end

function Addon:OnDisable()
    -- Restore Blizzard frames
    RestoreBlizzardLootFrame()
    RestoreBlizzardRollFrames()

    -- Shutdown modules if present
    if ns.LootFrame.Shutdown then ns.LootFrame.Shutdown() end
    if ns.RollManager.Shutdown then ns.RollManager.Shutdown() end
    if ns.HistoryListener.Shutdown then ns.HistoryListener.Shutdown() end
    if ns.HistoryFrame.Shutdown then ns.HistoryFrame.Shutdown() end
    if ns.Listeners.Shutdown then ns.Listeners.Shutdown() end
end

function Addon:OnSlashCommand(input)
    if ns.HandleSlashCommand then
        ns.HandleSlashCommand(input)
    end
end
