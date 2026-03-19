-------------------------------------------------------------------------------
-- HistoryListener_Retail.lua
-- Loot history event handling for Retail using encounter-based C_LootHistory
--
-- Supported versions: Retail
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on Retail
-------------------------------------------------------------------------------

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

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
local processedDrops = {}
local notifiedRollResults = {}
local isInitializing = false

-------------------------------------------------------------------------------
-- Item quality helper
-------------------------------------------------------------------------------

local function GetItemQuality(itemLink)
    if not itemLink then return 1 end
    local _, _, quality = GetItemInfo(itemLink)
    return quality or 1
end

-------------------------------------------------------------------------------
-- Roll state conversion
-- Retail C_LootHistory uses enumerated roll states that differ from classic
-------------------------------------------------------------------------------

local ROLL_STATE_MAP = {
    [0] = 1,  -- NeedMainSpec -> Need
    [1] = 1,  -- NeedOffSpec -> Need
    [2] = 2,  -- Transmog -> Greed
    [3] = 2,  -- Greed
    [4] = 0,  -- NoRoll -> Pass
    [5] = 0,  -- Pass
}

local function ConvertRollState(state)
    if state == nil then return nil end
    return ROLL_STATE_MAP[state] or 0
end

-------------------------------------------------------------------------------
-- Process individual roll results for notifications
-------------------------------------------------------------------------------

local function ProcessRollResults(encounterID, drop)
    if isInitializing then return end
    if not drop or not drop.rollInfos then return end

    local stateMap = ns.NOTIFICATION_STATE_MAP
    if not stateMap then return end

    local itemLink = drop.itemHyperlink
    local itemName = itemLink and itemLink:match("%[(.-)%]")
    local itemQuality = GetItemQuality(itemLink)
    local itemIcon = GetItemTexture(itemLink)

    for _, rollInfo in ipairs(drop.rollInfos) do
        if rollInfo.playerName and rollInfo.state then
            local dedupKey = encounterID .. "-" .. drop.lootListID .. "-"
                .. (rollInfo.playerGUID or rollInfo.playerName)
            if not notifiedRollResults[dedupKey] then
                notifiedRollResults[dedupKey] = true
                local rollType = stateMap[rollInfo.state]
                local rollValue = rollInfo.roll
                ns.RollManager.SendRollResultNotification(
                    itemLink, itemName, itemQuality, itemIcon,
                    rollInfo.playerName, rollInfo.playerClass,
                    rollType, rollValue
                )
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Process a single drop into a history entry
-------------------------------------------------------------------------------

local function ProcessDrop(encounterID, drop)
    if not drop then return end

    local itemLink = drop.itemHyperlink
    if not itemLink then return end

    local dropKey = encounterID .. "-" .. drop.lootListID

    local winner = drop.winner
    local leader = drop.currentLeader

    -- Build per-player roll results for history detail expansion
    local rollResults
    if drop.rollInfos then
        rollResults = {}
        for _, rollInfo in ipairs(drop.rollInfos) do
            if rollInfo.playerName then
                rollResults[#rollResults + 1] = {
                    playerName = rollInfo.playerName,
                    playerClass = rollInfo.playerClass,
                    rollType = ConvertRollState(rollInfo.state),
                    roll = rollInfo.roll,
                }
            end
        end
        if #rollResults == 0 then rollResults = nil end
    end

    local entry = {
        itemLink = itemLink,
        itemTexture = GetItemTexture(itemLink),
        quality = GetItemQuality(itemLink),
        winner = winner and winner.playerName or nil,
        winnerClass = winner and winner.playerClass or nil,
        rollType = leader and ConvertRollState(leader.state) or nil,
        roll = leader and leader.roll or nil,
        timestamp = GetTime(),
        isComplete = drop.allPassed or (winner ~= nil),
        encounterID = encounterID,
        dropKey = dropKey,
        rollResults = rollResults,
    }

    if processedDrops[dropKey] then
        -- Already tracked - update existing entry
        ns.HistoryFrame.UpdateEntryByKey(dropKey, entry)
    else
        processedDrops[dropKey] = true
        ns.HistoryFrame.AddEntry(entry)
    end

    local db = ns.Addon.db.profile
    if db.history.autoShow then
        ns.HistoryFrame.Show()
    end

    -- Process individual roll results for notifications
    ProcessRollResults(encounterID, drop)
end

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------

local function OnHistoryUpdateEncounter(_, encounterID)
    if not encounterID then return end
    -- Drops arrive individually via LOOT_HISTORY_UPDATE_DROP; just refresh display
    ns.HistoryFrame.Refresh()
    ns.DebugPrint("LOOT_HISTORY_UPDATE_ENCOUNTER: " .. tostring(encounterID))
end

local function OnHistoryUpdateDrop(_, encounterID, lootListID)
    if not encounterID or not lootListID then return end
    local dropInfo = C_LootHistory.GetSortedInfoForDrop(encounterID, lootListID)
    ProcessDrop(encounterID, dropInfo)
    ns.DebugPrint("LOOT_HISTORY_UPDATE_DROP: encounter="
        .. tostring(encounterID) .. " drop=" .. tostring(lootListID))
end

local function OnHistoryClear()
    wipe(processedDrops)
    wipe(notifiedRollResults)
    ns.HistoryFrame.ClearHistory()
    ns.DebugPrint("LOOT_HISTORY_CLEAR_HISTORY")
end

-------------------------------------------------------------------------------
-- Populate existing history on load
-------------------------------------------------------------------------------

local function PopulateExistingHistory()
    if not C_LootHistory.GetAllEncounterInfos then return end
    local encounters = C_LootHistory.GetAllEncounterInfos()
    if not encounters then return end
    for _, encounter in ipairs(encounters) do
        local drops = C_LootHistory.GetSortedDropsForEncounter(encounter.encounterID)
        if drops then
            for _, drop in ipairs(drops) do
                ProcessDrop(encounter.encounterID, drop)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Public Interface: ns.HistoryListener
-------------------------------------------------------------------------------

function ns.HistoryListener.Initialize(addonRef)
    addon = addonRef

    addon:RegisterEvent("LOOT_HISTORY_UPDATE_ENCOUNTER", OnHistoryUpdateEncounter)
    addon:RegisterEvent("LOOT_HISTORY_UPDATE_DROP", OnHistoryUpdateDrop)
    addon:RegisterEvent("LOOT_HISTORY_CLEAR_HISTORY", OnHistoryClear)

    isInitializing = true
    PopulateExistingHistory()
    isInitializing = false

    ns.DebugPrint("Retail History Listener initialized")
end

function ns.HistoryListener.Shutdown()
    if addon then
        addon:UnregisterEvent("LOOT_HISTORY_UPDATE_ENCOUNTER")
        addon:UnregisterEvent("LOOT_HISTORY_UPDATE_DROP")
        addon:UnregisterEvent("LOOT_HISTORY_CLEAR_HISTORY")
    end

    wipe(notifiedRollResults)

    ns.DebugPrint("Retail History Listener shut down")
end
