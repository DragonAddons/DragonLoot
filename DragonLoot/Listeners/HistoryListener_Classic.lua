-------------------------------------------------------------------------------
-- HistoryListener_Classic.lua
-- Loot history event handling for Classic using roll-item indexed C_LootHistory
--
-- Supported versions: MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: skip on Retail (Classic listener runs on everything else)
-------------------------------------------------------------------------------

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return end

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local C_LootHistory = C_LootHistory
local GetItemInfo = GetItemInfo
local GetTime = GetTime

-------------------------------------------------------------------------------
-- Shared listener utilities
-------------------------------------------------------------------------------

local GetItemTexture = ns.ListenerShared.GetItemTexture

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local addon
local notifiedRollResults = {}

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
        local _, itemLink, numPlayers, isDone, winnerIdx, _, _ =
            C_LootHistory.GetItem(i)

        local winner, winnerClass, rollType, roll
        if winnerIdx and winnerIdx > 0 and numPlayers and numPlayers > 0 then
            winner, winnerClass, rollType, roll = C_LootHistory.GetPlayerInfo(i, winnerIdx)
        end

        -- Build per-player roll results for history detail expansion
        local rollResults
        if numPlayers and numPlayers > 0 then
            rollResults = {}
            for pi = 1, numPlayers do
                local pName, pClass, pRollType, pRoll = C_LootHistory.GetPlayerInfo(i, pi)
                if pName then
                    rollResults[#rollResults + 1] = {
                        playerName = pName,
                        playerClass = pClass,
                        rollType = pRollType,
                        roll = pRoll,
                    }
                end
            end
            if #rollResults == 0 then rollResults = nil end
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
            rollResults = rollResults,
        }
    end

    ns.HistoryFrame.SetEntries(entries)
end

-------------------------------------------------------------------------------
-- Individual roll result notification
-------------------------------------------------------------------------------

local function ProcessClassicRollResult(historyIndex, playerIndex)
    local rollID, itemLink = C_LootHistory.GetItem(historyIndex)
    if not rollID or not itemLink then return end

    local playerName, _, rollType, roll = C_LootHistory.GetPlayerInfo(historyIndex, playerIndex)
    if not playerName then return end

    -- Classic ROLL_CHANGED can fire before roll number is assigned
    -- For non-Pass rolls (rollType ~= 0), wait until roll value is available
    if roll == nil and rollType and rollType ~= 0 then return end

    local dedupKey = rollID .. "-" .. playerName
    if notifiedRollResults[dedupKey] then return end
    notifiedRollResults[dedupKey] = true

    -- Extract item info (may be cached from earlier GetItemInfo calls)
    local itemName, _, itemQuality, _, _, _, _, _, _, itemIcon = GetItemInfo(itemLink)
    if not itemName then
        itemName = itemLink:match("%[(.-)%]") or "Unknown"
    end

    ns.RollManager.SendRollResultNotification(
        itemLink, itemName, itemQuality or 0, itemIcon or 0,
        playerName, nil, rollType, roll
    )
end

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------

local function OnFullUpdate()
    RefreshFromAPI()
    ns.DebugPrint("LOOT_HISTORY_FULL_UPDATE")
end

local function OnRollChanged(_, historyIndex, playerIndex)
    -- Process the individual roll result notification
    if historyIndex and playerIndex then
        ProcessClassicRollResult(historyIndex, playerIndex)
    end
    -- Still refresh the full history display
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

local function OnHistoryClear()
    wipe(notifiedRollResults)
    ns.DebugPrint("LOOT_HISTORY_CLEAR_HISTORY (Classic)")
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
    pcall(addon.RegisterEvent, addon, "LOOT_HISTORY_CLEAR_HISTORY", OnHistoryClear)

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
        pcall(addon.UnregisterEvent, addon, "LOOT_HISTORY_CLEAR_HISTORY")
    end

    wipe(notifiedRollResults)

    ns.DebugPrint("Classic History Listener shut down")
end
