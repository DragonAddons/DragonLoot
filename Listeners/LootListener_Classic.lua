-------------------------------------------------------------------------------
-- LootListener_Classic.lua
-- Classic (TBC Anniversary + MoP Classic) loot window event listener
--
-- Supported versions: MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Version guard: skip on Retail (Classic listener runs on everything else)
-------------------------------------------------------------------------------

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local addon
local isLootOpen = false

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local function OnLootOpened(_, autoLoot)
    if isLootOpen then return end

    local db = ns.Addon.db.profile
    if not db.lootWindow.enabled then return end

    isLootOpen = true
    ns.SuppressBlizzardLootFrame()
    ns.LootFrame.Show(autoLoot)

    -- Only suppress DragonToast when the loot frame is actually visible.
    -- Auto-loot returns early from Show() without displaying UI.
    if not autoLoot then
        ns.Addon:SendMessage("DRAGONTOAST_SUPPRESS", "DragonLoot")
    end
    ns.DebugPrint("LOOT_OPENED fired (Classic)")
end

local function OnLootSlotCleared(_, slotIndex)
    if isLootOpen and ns.LootFrame.UpdateSlot then
        ns.LootFrame.UpdateSlot(slotIndex)
    end
end

local function OnLootSlotChanged(_, slotIndex)
    if not isLootOpen then return end
    ns.LootFrame.UpdateSlot(slotIndex)
end

local function OnLootClosed()
    if isLootOpen then
        isLootOpen = false

        -- pcall Hide so UNSUPPRESS always fires even if Hide errors
        local ok, err = pcall(ns.LootFrame.Hide)
        if not ok then
            ns.DebugPrint("LootFrame.Hide error: " .. tostring(err))
        end

        -- Always resume DragonToast item toasts
        ns.Addon:SendMessage("DRAGONTOAST_UNSUPPRESS", "DragonLoot")
        ns.DebugPrint("LOOT_CLOSED fired (Classic)")
    end
end

-------------------------------------------------------------------------------
-- Public Interface: ns.Listeners
-------------------------------------------------------------------------------

function ns.Listeners.Initialize(addonRef)
    addon = addonRef

    addon:RegisterEvent("LOOT_OPENED", OnLootOpened)
    addon:RegisterEvent("LOOT_SLOT_CLEARED", OnLootSlotCleared)
    addon:RegisterEvent("LOOT_SLOT_CHANGED", OnLootSlotChanged)
    addon:RegisterEvent("LOOT_CLOSED", OnLootClosed)

    ns.DebugPrint("Classic Loot Listener initialized")
end

function ns.Listeners.Shutdown()
    if addon then
        addon:UnregisterEvent("LOOT_OPENED")
        addon:UnregisterEvent("LOOT_SLOT_CLEARED")
        addon:UnregisterEvent("LOOT_SLOT_CHANGED")
        addon:UnregisterEvent("LOOT_CLOSED")
    end

    isLootOpen = false
    ns.DebugPrint("Classic Loot Listener shut down")
end
