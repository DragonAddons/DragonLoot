-------------------------------------------------------------------------------
-- RollListener_Retail.lua
-- Loot roll event handling for Retail (The War Within, Midnight)
--
-- Supported versions: Retail
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on Retail
-------------------------------------------------------------------------------

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetActiveLootRollIDs = GetActiveLootRollIDs
local GetLootRollTimeLeft = GetLootRollTimeLeft
local StaticPopup_Show = StaticPopup_Show

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
    ns.RollManager.CancelRoll(rollID)
    ns.DebugPrint("CANCEL_LOOT_ROLL: rollID=" .. tostring(rollID))
end

local function OnCancelAllLootRolls()
    if not isRollActive then return end
    ns.RollManager.CancelAllRolls()
    ns.DebugPrint("CANCEL_ALL_LOOT_ROLLS")
end

local function OnConfirmRoll(_, rollID, rollType)
    local dialog = StaticPopup_Show("DRAGONLOOT_CONFIRM_LOOT_ROLL")
    if dialog then
        dialog.data = { rollID = rollID, rollType = rollType }
    end
end

local function OnLootRollsComplete(_, lootHandle)
    if not isRollActive then return end
    ns.RollManager.OnRollComplete(lootHandle)
    ns.DebugPrint("LOOT_ROLLS_COMPLETE: handle=" .. tostring(lootHandle))
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
        local timeLeft = GetLootRollTimeLeft(rollID)
        if timeLeft and timeLeft > 0 then
            local totalDuration = GetRollDuration and GetRollDuration(rollID) or timeLeft
            ns.RollManager.RecoverRoll(rollID, totalDuration or timeLeft, timeLeft)
            ns.DebugPrint("Recovered active roll: " .. tostring(rollID))
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
    addon:RegisterEvent("CANCEL_ALL_LOOT_ROLLS", OnCancelAllLootRolls)
    addon:RegisterEvent("CONFIRM_LOOT_ROLL", OnConfirmRoll)
    addon:RegisterEvent("CONFIRM_DISENCHANT_ROLL", OnConfirmRoll)
    addon:RegisterEvent("LOOT_ROLLS_COMPLETE", OnLootRollsComplete)

    RecoverActiveRolls()

    ns.DebugPrint("Retail Roll Listener initialized")
end

function ns.RollListener.Shutdown()
    isRollActive = false

    if addon then
        addon:UnregisterEvent("START_LOOT_ROLL")
        addon:UnregisterEvent("CANCEL_LOOT_ROLL")
        addon:UnregisterEvent("CANCEL_ALL_LOOT_ROLLS")
        addon:UnregisterEvent("CONFIRM_LOOT_ROLL")
        addon:UnregisterEvent("CONFIRM_DISENCHANT_ROLL")
        addon:UnregisterEvent("LOOT_ROLLS_COMPLETE")
    end

    ns.DebugPrint("Retail Roll Listener shut down")
end
