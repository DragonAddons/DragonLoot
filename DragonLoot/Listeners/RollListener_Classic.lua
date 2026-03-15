-------------------------------------------------------------------------------
-- RollListener_Classic.lua
-- Loot roll event handling for Classic, TBC Anniversary, Cata, MoP Classic
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
    LS.OnStartLootRoll(isRollActive, rollID, rollTime, LS.MILLISECONDS_PER_SECOND, "Classic", lootHandle)
end

local function OnCancelLootRoll(_, rollID)
    LS.OnCancelLootRoll(isRollActive, rollID)
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
    for _, rollID in ipairs(activeRollIDs) do
        local timeLeftMs = GetLootRollTimeLeft(rollID)
        if timeLeftMs and timeLeftMs > 0 then
            -- Classic returns milliseconds; convert to seconds for RollManager
            local timeLeft = timeLeftMs / LS.MILLISECONDS_PER_SECOND
            ns.RollManager.RecoverRoll(rollID, timeLeft, timeLeft)
        end
    end
end

-------------------------------------------------------------------------------
-- Winner resolution via C_LootHistory (for group member wins)
-------------------------------------------------------------------------------

local function ResolveWinnerFromHistory(rollID)
    local activeRolls = ns.RollManager.GetActiveRolls()

    local roll = activeRolls[rollID]
    if not roll or not roll.itemName then return end

    local numItems = C_LootHistory and C_LootHistory.GetNumItems
        and C_LootHistory.GetNumItems() or 0
    for i = numItems, 1, -1 do
        local _, itemName = C_LootHistory.GetItem(i)
        if itemName == roll.itemName then
            local winner, winnerClass, rollType, rollValue = C_LootHistory.GetPlayerInfo(i, 1)
            if winner then
                ns.RollManager.NotifyRollWinner(rollID, winner, winnerClass, rollType, rollValue)
            end
            return
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
    addon:RegisterEvent("CONFIRM_LOOT_ROLL", OnConfirmRoll)
    pcall(addon.RegisterEvent, addon, "CONFIRM_DISENCHANT_ROLL", OnConfirmRoll)
    addon:RegisterEvent("LOOT_ROLLS_COMPLETE", OnLootRollsComplete)
    addon:RegisterEvent("LOOT_ITEM_ROLL_WON", OnLootItemRollWon)

    RecoverActiveRolls()

    ns.DebugPrint("Classic Roll Listener initialized")
end

function ns.RollListener.Shutdown()
    isRollActive = false
    LifecycleUtil.Invalidate(lifecycleState)

    if addon then
        addon:UnregisterEvent("START_LOOT_ROLL")
        addon:UnregisterEvent("CANCEL_LOOT_ROLL")
        addon:UnregisterEvent("CONFIRM_LOOT_ROLL")
        pcall(addon.UnregisterEvent, addon, "CONFIRM_DISENCHANT_ROLL")
        addon:UnregisterEvent("LOOT_ROLLS_COMPLETE")
        addon:UnregisterEvent("LOOT_ITEM_ROLL_WON")
    end

    addon = nil

    ns.DebugPrint("Classic Roll Listener shut down")
end

function ns.RollListener.ResolveWinner(rollID, completionToken)
    LS.ResolveWinner(function() return isRollActive end, lifecycleState, rollID, completionToken,
        ResolveWinnerFromHistory)
end
