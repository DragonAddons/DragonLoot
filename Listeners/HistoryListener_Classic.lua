-------------------------------------------------------------------------------
-- HistoryListener_Classic.lua
-- Loot history event handling for Classic using roll-item indexed C_LootHistory
--
-- Supported versions: MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Version guard: skip on Retail (Classic listener runs on everything else)
-------------------------------------------------------------------------------

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return end

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local C_LootHistory = C_LootHistory
local GetItemInfoInstant = GetItemInfoInstant
local GetItemInfo = GetItemInfo
local GetTime = GetTime

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local addon

-------------------------------------------------------------------------------
-- Item texture helper
-------------------------------------------------------------------------------

local function GetItemTexture(itemLink)
    if not itemLink then return nil end
    if GetItemInfoInstant then
        local _, _, _, _, icon = GetItemInfoInstant(itemLink)
        return icon
    end
    local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemLink)
    return icon
end

-------------------------------------------------------------------------------
-- Rebuild history from C_LootHistory API
-- Classic C_LootHistory is the source of truth; we mirror its data entirely
-------------------------------------------------------------------------------

local function RefreshFromAPI()
    if not C_LootHistory or not C_LootHistory.GetNumItems then return end
    local numItems = C_LootHistory.GetNumItems()
    if not numItems or numItems == 0 then
        ns.HistoryFrame.SetEntries({})
        return
    end

    local now = GetTime()
    local entries = {}
    for i = 1, numItems do
        local _rollID, itemLink, numPlayers, isDone, winnerIdx, _isMasterLoot, _isCurrency =
            C_LootHistory.GetItem(i)

        local winner, winnerClass, rollType, roll
        if winnerIdx and winnerIdx > 0 and numPlayers and numPlayers > 0 then
            winner, winnerClass, rollType, roll = C_LootHistory.GetPlayerInfo(i, winnerIdx)
        end

        local quality = 1
        if itemLink then
            local _, _, q = GetItemInfo(itemLink)
            quality = q or 1
        end

        entries[#entries + 1] = {
            itemLink = itemLink,
            itemTexture = GetItemTexture(itemLink),
            quality = quality,
            winner = winner,
            winnerClass = winnerClass,
            rollType = rollType,
            roll = roll,
            timestamp = now,
            isComplete = isDone,
        }
    end

    ns.HistoryFrame.SetEntries(entries)
end

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------

local function OnFullUpdate()
    RefreshFromAPI()
    ns.DebugPrint("LOOT_HISTORY_FULL_UPDATE")
end

local function OnRollChanged(_, _historyIndex, _playerIndex)
    RefreshFromAPI()
    ns.DebugPrint("LOOT_HISTORY_ROLL_CHANGED")
end

local function OnRollComplete()
    RefreshFromAPI()
    ns.DebugPrint("LOOT_HISTORY_ROLL_COMPLETE")
end

local function OnAutoShow()
    RefreshFromAPI()
    local db = ns.Addon.db.profile
    if db.history.autoShow then
        ns.HistoryFrame.Show()
    end
    ns.DebugPrint("LOOT_HISTORY_AUTO_SHOW")
end

-------------------------------------------------------------------------------
-- Public Interface: ns.HistoryListener
-------------------------------------------------------------------------------

function ns.HistoryListener.Initialize(addonRef)
    addon = addonRef

    addon:RegisterEvent("LOOT_HISTORY_FULL_UPDATE", OnFullUpdate)
    addon:RegisterEvent("LOOT_HISTORY_ROLL_CHANGED", OnRollChanged)
    addon:RegisterEvent("LOOT_HISTORY_ROLL_COMPLETE", OnRollComplete)
    addon:RegisterEvent("LOOT_HISTORY_AUTO_SHOW", OnAutoShow)

    -- Load any existing data
    RefreshFromAPI()

    ns.DebugPrint("Classic History Listener initialized")
end

function ns.HistoryListener.Shutdown()
    if addon then
        addon:UnregisterEvent("LOOT_HISTORY_FULL_UPDATE")
        addon:UnregisterEvent("LOOT_HISTORY_ROLL_CHANGED")
        addon:UnregisterEvent("LOOT_HISTORY_ROLL_COMPLETE")
        addon:UnregisterEvent("LOOT_HISTORY_AUTO_SHOW")
    end

    ns.DebugPrint("Classic History Listener shut down")
end
