-------------------------------------------------------------------------------
-- RollListener_Retail.lua
-- Loot roll event handling for Retail (The War Within, Midnight)
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

local GetActiveLootRollIDs = GetActiveLootRollIDs
local GetLootRollTimeLeft = GetLootRollTimeLeft
local C_LootHistory = C_LootHistory
local LifecycleUtil = ns.LifecycleUtil

-------------------------------------------------------------------------------
-- Shared listener utilities
-------------------------------------------------------------------------------

local LS = ns.ListenerShared

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local addon
local isRollActive = false
local lifecycleState = LifecycleUtil.CreateState()

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local function OnStartLootRoll(_, rollID, rollTime, lootHandle)
    LS.OnStartLootRoll(isRollActive, rollID, rollTime, LS.MILLISECONDS_PER_SECOND, "Retail", lootHandle)
end

local function OnCancelLootRoll(_, rollID)
    LS.OnCancelLootRoll(isRollActive, rollID)
end

local function OnCancelAllLootRolls()
    if not isRollActive then return end

    ns.RollManager.CancelAllRolls()
    ns.DebugPrint("CANCEL_ALL_LOOT_ROLLS")
end

local function OnConfirmRoll(_, rollID, rollType)
    LS.OnConfirmRoll(rollID, rollType)
end

local function OnLootRollsComplete(_, lootHandle)
    LS.OnLootRollsComplete(isRollActive, lootHandle)
end

local function OnLootItemRollWon(_, itemLink, _, rollType, rollValue)
    LS.OnLootItemRollWon(isRollActive, itemLink, rollType, rollValue)
end

-------------------------------------------------------------------------------
-- Pending roll recovery (handles /reload during active rolls)
-------------------------------------------------------------------------------

local function RecoverActiveRolls()
    if not GetActiveLootRollIDs then return end

    local activeRollIDs = GetActiveLootRollIDs()
    if not activeRollIDs then return end

    local GetRollDuration = C_Loot and C_Loot.GetLootRollDuration
    for _, rollID in ipairs(activeRollIDs) do
        local timeLeftMs = GetLootRollTimeLeft(rollID)
        if timeLeftMs and timeLeftMs > 0 then
            local totalDurationMs = GetRollDuration and GetRollDuration(rollID) or timeLeftMs
            -- Retail returns milliseconds; convert to seconds for RollManager
            local totalDuration = (totalDurationMs or timeLeftMs) / LS.MILLISECONDS_PER_SECOND
            local timeLeft = timeLeftMs / LS.MILLISECONDS_PER_SECOND
            ns.RollManager.RecoverRoll(rollID, totalDuration, timeLeft)
            ns.DebugPrint("Recovered active roll: " .. tostring(rollID) .. " (" .. tostring(timeLeft) .. "s left)")
        end
    end
end

-------------------------------------------------------------------------------
-- Winner resolution via C_LootHistory (for group member wins)
-------------------------------------------------------------------------------

local function ResolveWinnerFromHistory(rollID)
    local activeRolls = ns.RollManager.GetActiveRolls()

    local roll = activeRolls[rollID]
    if not roll or not roll.itemLink then return end

    local encounters = C_LootHistory and C_LootHistory.GetAllEncounterInfos
        and C_LootHistory.GetAllEncounterInfos()
    if not encounters then return end

    for i = #encounters, 1, -1 do
        local encounter = encounters[i]
        local drops = C_LootHistory.GetSortedDropsForEncounter(encounter.encounterID)
        for _, drop in ipairs(drops or {}) do
            if drop and drop.itemHyperlink == roll.itemLink and drop.winner then
                local leader = drop.currentLeader
                ns.RollManager.NotifyRollWinner(
                    rollID,
                    drop.winner.playerName,
                    drop.winner.playerClass,
                    leader and leader.state or nil,
                    leader and leader.roll or nil
                )
                return
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Public Interface: ns.RollListener
-------------------------------------------------------------------------------

function ns.RollListener.Initialize(addonRef)
    addon = addonRef
    isRollActive = true
    LifecycleUtil.Activate(lifecycleState)

    addon:RegisterEvent("START_LOOT_ROLL", OnStartLootRoll)
    addon:RegisterEvent("CANCEL_LOOT_ROLL", OnCancelLootRoll)
    addon:RegisterEvent("CANCEL_ALL_LOOT_ROLLS", OnCancelAllLootRolls)
    addon:RegisterEvent("CONFIRM_LOOT_ROLL", OnConfirmRoll)
    addon:RegisterEvent("CONFIRM_DISENCHANT_ROLL", OnConfirmRoll)
    addon:RegisterEvent("LOOT_ROLLS_COMPLETE", OnLootRollsComplete)
    addon:RegisterEvent("LOOT_ITEM_ROLL_WON", OnLootItemRollWon)

    RecoverActiveRolls()

    ns.DebugPrint("Retail Roll Listener initialized")
end

function ns.RollListener.Shutdown()
    isRollActive = false
    LifecycleUtil.Invalidate(lifecycleState)

    if addon then
        addon:UnregisterEvent("START_LOOT_ROLL")
        addon:UnregisterEvent("CANCEL_LOOT_ROLL")
        addon:UnregisterEvent("CANCEL_ALL_LOOT_ROLLS")
        addon:UnregisterEvent("CONFIRM_LOOT_ROLL")
        addon:UnregisterEvent("CONFIRM_DISENCHANT_ROLL")
        addon:UnregisterEvent("LOOT_ROLLS_COMPLETE")
        addon:UnregisterEvent("LOOT_ITEM_ROLL_WON")
    end

    addon = nil

    ns.DebugPrint("Retail Roll Listener shut down")
end

function ns.RollListener.ResolveWinner(rollID, completionToken)
    LS.ResolveWinner(function() return isRollActive end, lifecycleState, rollID, completionToken,
        ResolveWinnerFromHistory)
end
