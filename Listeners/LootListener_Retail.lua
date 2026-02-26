-------------------------------------------------------------------------------
-- LootListener_Retail.lua
-- Retail loot window event listener
--
-- Supported versions: Retail
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on Retail
-------------------------------------------------------------------------------

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local addon
local isLootOpen = false
local pendingAutoLoot = false

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local function OnLootOpened(_, autoLoot)
    -- LOOT_OPENED fires first on Retail and carries the autoLoot flag.
    -- Capture it for LOOT_READY which follows immediately after.
    pendingAutoLoot = (autoLoot == 1) or (autoLoot == true)
    ns.DebugPrint("LOOT_OPENED captured autoLoot=" .. tostring(pendingAutoLoot))
end

local function OnLootReady()
    if isLootOpen then return end

    local db = ns.Addon.db.profile
    if not db.lootWindow.enabled then return end

    isLootOpen = true
    ns.SuppressBlizzardLootFrame()
    ns.LootFrame.Show(pendingAutoLoot)

    -- Only suppress DragonToast when the loot frame is actually visible.
    -- Auto-loot returns early from Show() without displaying UI.
    if not pendingAutoLoot then
        ns.Addon:SendMessage("DRAGONTOAST_SUPPRESS", "DragonLoot")
    end
    ns.DebugPrint("LOOT_READY fired (Retail)")
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
        pendingAutoLoot = false

        -- pcall Hide so UNSUPPRESS always fires even if Hide errors
        local ok, err = pcall(ns.LootFrame.Hide)
        if not ok then
            ns.DebugPrint("LootFrame.Hide error: " .. tostring(err))
        end

        -- Always resume DragonToast item toasts
        ns.Addon:SendMessage("DRAGONTOAST_UNSUPPRESS", "DragonLoot")
        ns.DebugPrint("LOOT_CLOSED fired (Retail)")
    end
end

-------------------------------------------------------------------------------
-- Public Interface: ns.Listeners
-------------------------------------------------------------------------------

function ns.Listeners.Initialize(addonRef)
    addon = addonRef

    addon:RegisterEvent("LOOT_READY", function()
        OnLootReady()
    end)
    addon:RegisterEvent("LOOT_OPENED", OnLootOpened)
    addon:RegisterEvent("LOOT_SLOT_CLEARED", OnLootSlotCleared)
    addon:RegisterEvent("LOOT_SLOT_CHANGED", OnLootSlotChanged)
    addon:RegisterEvent("LOOT_CLOSED", OnLootClosed)

    ns.DebugPrint("Retail Loot Listener initialized")
end

function ns.Listeners.Shutdown()
    if addon then
        addon:UnregisterEvent("LOOT_READY")
        addon:UnregisterEvent("LOOT_OPENED")
        addon:UnregisterEvent("LOOT_SLOT_CLEARED")
        addon:UnregisterEvent("LOOT_SLOT_CHANGED")
        addon:UnregisterEvent("LOOT_CLOSED")
    end

    isLootOpen = false
    pendingAutoLoot = false
    ns.DebugPrint("Retail Loot Listener shut down")
end
