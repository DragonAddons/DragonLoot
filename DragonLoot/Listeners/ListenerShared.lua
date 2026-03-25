-------------------------------------------------------------------------------
-- ListenerShared.lua
-- Shared utilities and handlers for loot, roll, and history listeners
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetItemInfoInstant = GetItemInfoInstant
local GetItemInfo = GetItemInfo
local GetLootRollItemInfo = GetLootRollItemInfo
local StaticPopup_Show = StaticPopup_Show
local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS

-------------------------------------------------------------------------------
-- Module table
-------------------------------------------------------------------------------

ns.ListenerShared = {}

local LS = ns.ListenerShared

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

LS.MILLISECONDS_PER_SECOND = 1000
LS.WINNER_RESOLVE_DELAY = 0.3

-------------------------------------------------------------------------------
-- lootHandle -> rollID mapping
-- START_LOOT_ROLL provides (rollID, rollTime, lootHandle) but
-- LOOT_ROLLS_COMPLETE fires with (lootHandle), not rollID. This map resolves
-- the mismatch so OnRollComplete receives the correct rollID.
-------------------------------------------------------------------------------

local lootHandleToRollID = {}

-------------------------------------------------------------------------------
-- Item texture helper
-- Used by HistoryListener_Retail, HistoryListener_Classic, LootHistoryChat
-------------------------------------------------------------------------------

function LS.GetItemTexture(itemLink)
    if not itemLink then return nil end
    if GetItemInfoInstant then
        local _, _, _, _, icon = GetItemInfoInstant(itemLink)
        return icon
    end
    local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemLink)
    return icon
end

-------------------------------------------------------------------------------
-- Shared loot handlers
-- Used by LootListener_Retail and LootListener_Classic
-------------------------------------------------------------------------------

function LS.OnLootSlotCleared(isLootOpen, slotIndex)
    if isLootOpen and ns.LootFrame.UpdateSlot then
        ns.LootFrame.UpdateSlot(slotIndex)
    end
end

function LS.OnLootSlotChanged(isLootOpen, slotIndex)
    if not isLootOpen or not ns.LootFrame.UpdateSlot then return end
    ns.LootFrame.UpdateSlot(slotIndex)
end

function LS.OnLootClosed(isLootOpen, versionLabel)
    if not isLootOpen then return false end

    local ok, err = pcall(ns.LootFrame.Hide)
    if not ok then
        ns.DebugPrint("LootFrame.Hide error: " .. tostring(err))
    end

    ns.Addon:SendMessage("DRAGONTOAST_UNSUPPRESS", "DragonLoot")
    ns.DebugPrint("LOOT_CLOSED fired (" .. versionLabel .. ")")
    return false
end

-------------------------------------------------------------------------------
-- Shared roll handlers
-- Used by RollListener_Retail and RollListener_Classic
-------------------------------------------------------------------------------

function LS.OnStartLootRoll(isRollActive, rollID, rollTime, msPerSec, _, lootHandle)
    if not isRollActive then return end
    if lootHandle then
        lootHandleToRollID[lootHandle] = rollID
    end
    local rollTimeSec = rollTime / msPerSec
    ns.RollManager.StartRoll(rollID, rollTimeSec)
    ns.DebugPrint("START_LOOT_ROLL: rollID=" .. tostring(rollID)
        .. " time=" .. tostring(rollTimeSec) .. "s")
end

function LS.OnCancelLootRoll(isRollActive, rollID)
    if not isRollActive then return end
    local rolls = ns.RollManager.GetActiveRolls()
    if rolls[rollID] and rolls[rollID].completing then return end
    for handle, id in pairs(lootHandleToRollID) do
        if id == rollID then
            lootHandleToRollID[handle] = nil
            break
        end
    end
    ns.RollManager.CancelRoll(rollID)
    ns.DebugPrint("CANCEL_LOOT_ROLL: rollID=" .. tostring(rollID))
end

function LS.OnConfirmRoll(rollID, rollType)
    local _, name, _, quality = GetLootRollItemInfo(rollID)
    local coloredName = name or "Unknown"
    if name and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        coloredName = ITEM_QUALITY_COLORS[quality].hex .. name .. "|r"
    end
    local dialog = StaticPopup_Show("DRAGONLOOT_CONFIRM_LOOT_ROLL", coloredName)
    if dialog then
        dialog.data = { rollID = rollID, rollType = rollType }
    end
end

function LS.OnLootRollsComplete(isRollActive, lootHandle)
    if not isRollActive then return end
    local rollID = lootHandleToRollID[lootHandle] or lootHandle
    lootHandleToRollID[lootHandle] = nil
    ns.RollManager.OnRollComplete(rollID)
    ns.DebugPrint("LOOT_ROLLS_COMPLETE: handle=" .. tostring(lootHandle)
        .. " rollID=" .. tostring(rollID))
end

function LS.OnLootItemRollWon(isRollActive, itemLink, rollType, rollValue)
    if not isRollActive then return end
    ns.RollManager.OnLootItemRollWon(itemLink, rollType, rollValue)
end

-------------------------------------------------------------------------------
-- Shared winner resolution
-- Used by RollListener_Retail and RollListener_Classic
-- getIsActive: function returning current isRollActive state
-- resolveFromHistory: version-specific ResolveWinnerFromHistory callback
-------------------------------------------------------------------------------

function LS.ResolveWinner(getIsActive, lifecycleState, rollID, completionToken, resolveFromHistory)
    local LifecycleUtil = ns.LifecycleUtil
    LifecycleUtil.After(lifecycleState, LS.WINNER_RESOLVE_DELAY, function()
        if not getIsActive() then return end
        local activeRolls = ns.RollManager.GetActiveRolls()
        local roll = activeRolls[rollID]
        if not roll or not roll.completing then return end
        if completionToken and roll.completionToken ~= completionToken then return end
        resolveFromHistory(rollID)
    end)
end
