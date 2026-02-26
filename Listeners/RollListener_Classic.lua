-------------------------------------------------------------------------------
-- RollListener_Classic.lua
-- Loot roll event handling for Classic, TBC Anniversary, Cata, MoP Classic
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

local GetActiveLootRollIDs = GetActiveLootRollIDs
local GetLootRollTimeLeft = GetLootRollTimeLeft
local StaticPopup_Show = StaticPopup_Show
local C_LootHistory = C_LootHistory
local C_Timer = C_Timer

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local addon
local isRollActive = false

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local function OnStartLootRoll(_, rollID, rollTime)
    if not isRollActive then return end
    ns.RollManager.StartRoll(rollID, rollTime)
    ns.DebugPrint("START_LOOT_ROLL: rollID=" .. tostring(rollID) .. " time=" .. tostring(rollTime))
end

local function OnCancelLootRoll(_, rollID)
    if not isRollActive then return end
    local rolls = ns.RollManager.GetActiveRolls()
    if rolls[rollID] and rolls[rollID].completing then return end
    ns.RollManager.CancelRoll(rollID)
    ns.DebugPrint("CANCEL_LOOT_ROLL: rollID=" .. tostring(rollID))
end

local function OnConfirmRoll(_, rollID, rollType)
    local dialog = StaticPopup_Show("DRAGONLOOT_CONFIRM_LOOT_ROLL")
    if dialog then
        dialog.data = { rollID = rollID, rollType = rollType }
    end
end

local function OnLootRollsComplete(_, lootHandle)
    if not isRollActive then return end
    -- Note: LOOT_ROLLS_COMPLETE provides lootHandle which appears to match rollID from
    -- START_LOOT_ROLL in practice. If they ever diverge, a mapping will be needed.
    ns.RollManager.OnRollComplete(lootHandle)
    ns.DebugPrint("LOOT_ROLLS_COMPLETE: handle=" .. tostring(lootHandle))
end

local function OnLootItemRollWon(_, itemLink, _rollQuantity, rollType, rollValue)
    if not isRollActive then return end
    ns.RollManager.OnLootItemRollWon(itemLink, rollType, rollValue)
end

-------------------------------------------------------------------------------
-- Pending roll recovery (handles /reload during active rolls)
-------------------------------------------------------------------------------

local function RecoverActiveRolls()
    if not GetActiveLootRollIDs then return end
    local activeRollIDs = GetActiveLootRollIDs()
    if not activeRollIDs then return end
    for _, rollID in ipairs(activeRollIDs) do
        local timeLeft = GetLootRollTimeLeft(rollID)
        if timeLeft and timeLeft > 0 then
            ns.RollManager.RecoverRoll(rollID, timeLeft, timeLeft)
        end
    end
end

-------------------------------------------------------------------------------
-- Winner resolution via C_LootHistory (for group member wins)
-------------------------------------------------------------------------------

local function ResolveWinnerFromHistory(rollID)
    local roll = ns.RollManager.GetActiveRolls()[rollID]
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

    if addon then
        addon:UnregisterEvent("START_LOOT_ROLL")
        addon:UnregisterEvent("CANCEL_LOOT_ROLL")
        addon:UnregisterEvent("CONFIRM_LOOT_ROLL")
        pcall(addon.UnregisterEvent, addon, "CONFIRM_DISENCHANT_ROLL")
        addon:UnregisterEvent("LOOT_ROLLS_COMPLETE")
        addon:UnregisterEvent("LOOT_ITEM_ROLL_WON")
    end

    ns.DebugPrint("Classic Roll Listener shut down")
end

function ns.RollListener.ResolveWinner(rollID)
    C_Timer.After(0.3, function()
        ResolveWinnerFromHistory(rollID)
    end)
end
