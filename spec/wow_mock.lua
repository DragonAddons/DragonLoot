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
    function frame.SetScript() end
    function frame.CreateTexture()
        return {}
    end
    function frame.CreateFontString()
        return { SetFont = function() end, SetText = function() end }
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

    return frame
end

function CreateFrame()
    return CreateMockFrame()
end

UIParent = CreateMockFrame()

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

-------------------------------------------------------------------------------
-- Reset helpers
-------------------------------------------------------------------------------

function M.Reset()
    mockTime = 0
    M._inCombat = false
    M._profileSeed = nil
end

return M
