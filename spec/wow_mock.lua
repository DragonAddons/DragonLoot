-------------------------------------------------------------------------------
-- wow_mock.lua
-- Lightweight WoW API mock for DragonLoot busted unit tests
-------------------------------------------------------------------------------

local M = {}

-------------------------------------------------------------------------------
-- Mock time (controllable clock)
-------------------------------------------------------------------------------

local mockTime = 0

function M.SetTime(t)
    mockTime = t
end

function M.AdvanceTime(dt)
    mockTime = mockTime + dt
end

-- luacheck: push ignore 111 121 122

-------------------------------------------------------------------------------
-- Core WoW API mocks
-------------------------------------------------------------------------------

function GetTime()
    return mockTime
end

function InCombatLockdown()
    return M._inCombat or false
end

function UnitName()
    return "TestPlayer"
end

function IsInInstance()
    return false, "none"
end

function PlaySound() end
function PlaySoundFile() end
function hooksecurefunc() end

-------------------------------------------------------------------------------
-- Master loot / group composition mocks
--
-- Tests configure these by mutating the M._masterLoot table (candidates by
-- [slot][index] -> name) and the M._group table (counts, master-looter flag,
-- per-unit class info). Defaults assume a solo player who is the master
-- looter, mirroring the simplest test scenario.
-------------------------------------------------------------------------------

M._masterLoot = {
    candidates = {}, -- candidates[slot][index] = "PlayerName"
    given = {}, -- recorded GiveMasterLoot(slot, index) calls
}

M._group = {
    numRaid = 0,
    numParty = 0,
    isMasterLooter = true,
    units = {}, -- units[unitName] = { className = "WARRIOR", classFile = "WARRIOR", classID = 1 }
}

function GetMasterLootCandidate(slot, index)
    local slotTable = M._masterLoot.candidates[slot]
    if not slotTable then
        return nil
    end
    return slotTable[index]
end

function GiveMasterLoot(slot, index)
    M._masterLoot.given[#M._masterLoot.given + 1] = { slot = slot, index = index }
end

function GetNumRaidMembers()
    return M._group.numRaid
end

function GetNumPartyMembers()
    return M._group.numParty
end

function IsMasterLooter()
    return M._group.isMasterLooter and true or false
end

function UnitClass(unit)
    local info = M._group.units[unit]
    if not info then
        return nil, nil, nil
    end
    return info.className, info.classFile, info.classID
end

-------------------------------------------------------------------------------
-- Loot roll API mocks
--
-- RollManager.lua caches these at load time and registers a StaticPopup entry
-- at file scope, so they must exist as globals before the module is loaded.
-------------------------------------------------------------------------------

StaticPopupDialogs = {}

function ConfirmLootRoll() end

function GetLootRollItemInfo()
    return 12345, "Test Item", 1, 4
end

function GetLootRollItemLink(rollID)
    return "|Hitem:1000" .. tostring(rollID) .. "|h[Test Item]|h"
end

-------------------------------------------------------------------------------
-- WoW version constants
-------------------------------------------------------------------------------

WOW_PROJECT_ID = 1
WOW_PROJECT_MAINLINE = 1

-------------------------------------------------------------------------------
-- C_Timer mock (fires immediately in tests)
-------------------------------------------------------------------------------

C_Timer = {
    After = function(_, cb)
        if cb then
            cb()
        end
    end,
    NewTicker = function(_, cb)
        if cb then
            cb()
        end
        return { Cancel = function() end }
    end,
}

-------------------------------------------------------------------------------
-- WoW utility globals
-------------------------------------------------------------------------------

STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"

function wipe(t)
    for k in pairs(t) do
        t[k] = nil
    end
    return t
end

function strsplit(delimiter, str, max)
    local parts = {}
    local pattern = "([^" .. delimiter .. "]*)" .. delimiter .. "?"
    local count = 0
    for part in string.gmatch(str .. delimiter, pattern) do
        count = count + 1
        parts[count] = part
        if max and count >= max then
            break
        end
    end
    return unpack(parts)
end

function strmatch(str, pattern)
    return string.match(str, pattern)
end

function strtrim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

format = string.format

-------------------------------------------------------------------------------
-- Frame mock (minimal)
-------------------------------------------------------------------------------

-- Registry of every mock frame created, so M.FireEvent can dispatch to all
-- frames that registered a given event.
local mockFrames = {}

local function CreateMockFrame()
    local frame = {
        _shown = false,
        _scripts = {},
        _events = {},
    }

    function frame.SetPoint() end
    function frame.ClearAllPoints() end
    function frame:Show()
        self._shown = true
    end
    function frame:Hide()
        self._shown = false
    end
    function frame:IsShown()
        return self._shown
    end
    function frame.SetSize() end
    function frame.SetHeight() end
    function frame.SetWidth() end
    function frame.SetMovable() end
    function frame.EnableMouse() end
    function frame.SetFrameStrata() end
    function frame:SetScript(script, handler)
        self._scripts[script] = handler
    end
    function frame:GetScript(script)
        return self._scripts[script]
    end
    function frame.CreateTexture()
        return {
            SetAllPoints = function() end,
            SetPoint = function() end,
            ClearAllPoints = function() end,
            SetColorTexture = function() end,
            SetTexture = function() end,
            SetVertexColor = function() end,
            SetTexCoord = function() end,
            Hide = function() end,
            Show = function() end,
        }
    end
    function frame.CreateFontString()
        return {
            SetFont = function() end,
            SetText = function() end,
            SetPoint = function() end,
            ClearAllPoints = function() end,
            SetJustifyH = function() end,
            SetJustifyV = function() end,
            SetWordWrap = function() end,
            SetTextColor = function() end,
            SetShadowOffset = function() end,
            SetShadowColor = function() end,
        }
    end
    function frame.RegisterForClicks() end
    function frame.SetBackdrop() end
    function frame.SetBackdropColor() end
    function frame.SetBackdropBorderColor() end
    function frame.SetClampedToScreen() end
    function frame.SetFrameLevel() end
    function frame.SetText(self, text)
        self._text = text
    end
    function frame.GetFontString()
        return {
            SetFont = function() end,
            SetText = function() end,
            SetTextColor = function() end,
            SetShadowOffset = function() end,
            SetShadowColor = function() end,
        }
    end

    function frame:RegisterEvent(event)
        self._events[event] = true
    end
    function frame:UnregisterEvent(event)
        self._events[event] = nil
    end
    function frame:UnregisterAllEvents()
        wipe(self._events)
    end
    function frame:IsEventRegistered(event)
        return self._events[event] or false
    end

    mockFrames[#mockFrames + 1] = frame
    return frame
end

function CreateFrame()
    return CreateMockFrame()
end

UIParent = CreateMockFrame()

RAID_CLASS_COLORS = {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    MAGE = { r = 0.41, g = 0.80, b = 0.94 },
}

UISpecialFrames = {}

_G = _G or {}

-------------------------------------------------------------------------------
-- LibStub mock (dispatches by library name)
-------------------------------------------------------------------------------

local function DeepCopyTable(src)
    if type(src) ~= "table" then
        return src
    end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopyTable(v)
    end
    return copy
end

local aceDBMock = {
    New = function(_, _, defaultsArg, _)
        local profile
        if M._profileSeed then
            -- Use the seeded profile (simulates a saved profile from a
            -- previous schema version). Deep-copy to avoid cross-test leaks.
            profile = DeepCopyTable(M._profileSeed)
        else
            profile = DeepCopyTable(defaultsArg and defaultsArg.profile or {})
        end
        local db = {
            profile = profile,
            RegisterCallback = function() end,
            CancelCallback = function() end,
        }
        return db
    end,
}

local aceAddonMock = {
    NewAddon = function(_, name, ...)
        local addon = {
            _name = name,
            _mixins = { ... },
        }
        function addon.RegisterChatCommand() end
        function addon:RegisterEvent() end
        function addon:UnregisterEvent() end
        function addon.ScheduleTimer(_, func, _)
            if func then
                func()
            end
            return {}
        end
        function addon.ScheduleRepeatingTimer()
            return {}
        end
        function addon.CancelTimer() end
        return addon
    end,
}

local aceLocaleMock = {
    GetLocale = function()
        return setmetatable({}, {
            __index = function(_, key)
                return key
            end,
        })
    end,
}

function LibStub(name)
    if name == "AceDB-3.0" then
        return aceDBMock
    end
    if name == "AceAddon-3.0" then
        return aceAddonMock
    end
    if name == "AceLocale-3.0" then
        return aceLocaleMock
    end
    return nil
end

-- luacheck: pop

-------------------------------------------------------------------------------
-- Namespace builder
-------------------------------------------------------------------------------

function M.CreateNamespace()
    local ns = {}

    ns.ADDON_NAME = "DragonLoot"
    ns.ADDON_TITLE = "DragonLoot"
    ns.VERSION = "test"

    ns.COLOR_GOLD = "|cffffd700"
    ns.COLOR_GREEN = "|cff00ff00"
    ns.COLOR_RED = "|cffff0000"
    ns.COLOR_GRAY = "|cff888888"
    ns.COLOR_WHITE = "|cffffffff"
    ns.COLOR_RESET = "|r"

    ns.LifecycleUtil = {}
    ns.LootFrame = {}
    ns.RollFrame = {}
    ns.RollManager = {}
    ns.HistoryFrame = {}
    ns.HistoryListener = {}
    ns.LootHistoryChat = {}
    ns.ConfigWindow = {}
    ns.MinimapIcon = {}
    ns.Listeners = {}
    ns.Addon = {}

    function ns.Print() end
    function ns.DebugPrint() end

    return ns
end

-------------------------------------------------------------------------------
-- Module loaders
-------------------------------------------------------------------------------

function M.LoadLifecycle(ns)
    local path = "DragonLoot/Core/Lifecycle.lua"
    local chunk, err = loadfile(path)
    if not chunk then
        error("Failed to load " .. path .. ": " .. tostring(err))
    end
    chunk("DragonLoot", ns)
    return ns.LifecycleUtil
end

function M.LoadConfig(ns)
    local path = "DragonLoot/Core/Config.lua"
    local chunk, err = loadfile(path)
    if not chunk then
        error("Failed to load " .. path .. ": " .. tostring(err))
    end
    chunk("DragonLoot", ns)
end

-- Generic loader: load an addon source file with ("DragonLoot", ns) varargs.
function M.LoadFile(ns, relativePath)
    local chunk, err = loadfile(relativePath)
    if not chunk then
        error("Failed to load " .. relativePath .. ": " .. tostring(err))
    end
    chunk("DragonLoot", ns)
end

-- Returns the current count of mock frames; used as a snapshot anchor so
-- tests can iterate only the frames created after a given setup step.
function M.FrameCount()
    return #mockFrames
end

-- Returns all mock frames created after the given snapshot index.
function M.FramesSince(snapshot)
    local out = {}
    for i = snapshot + 1, #mockFrames do
        out[#out + 1] = mockFrames[i]
    end
    return out
end

-------------------------------------------------------------------------------
-- Reset helpers
-------------------------------------------------------------------------------

-- Dispatch a WoW event to every mock frame that has registered for it and
-- has an OnEvent script. Useful for simulating OPEN_MASTER_LOOT_LIST,
-- LOOT_OPENED, etc. in unit tests.
function M.FireEvent(event, ...)
    for _, frame in ipairs(mockFrames) do
        if frame._events[event] then
            local handler = frame._scripts and frame._scripts.OnEvent
            if handler then
                handler(frame, event, ...)
            end
        end
    end
end

function M.Reset()
    mockTime = 0
    M._inCombat = false
    M._profileSeed = nil

    M._masterLoot.candidates = {}
    M._masterLoot.given = {}

    M._group.numRaid = 0
    M._group.numParty = 0
    M._group.isMasterLooter = true
    M._group.units = {}

    -- Detach event handlers on any frames left over from a prior test. We
    -- keep the frames themselves around (UIParent and similar singletons
    -- are created once at module load) but make sure FireEvent cannot
    -- dispatch into the previous test's closures.
    for _, frame in ipairs(mockFrames) do
        wipe(frame._events)
        if frame._scripts then
            frame._scripts.OnEvent = nil
        end
    end

    if type(UISpecialFrames) == "table" then
        wipe(UISpecialFrames)
    else
        UISpecialFrames = {}
    end
end

return M
