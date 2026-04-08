-------------------------------------------------------------------------------
-- LootListener_Retail.lua
-- Retail loot window event listener
--
-- Supported versions: Retail
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on Retail
-------------------------------------------------------------------------------

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    return
end

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

    -- Suppress the Blizzard loot frame as early as possible. LOOT_OPENED
    -- fires before LOOT_READY; without this, Blizzard's LootFrame processes
    -- LOOT_OPENED and shows before OnLootReady can suppress it.
    local db = ns.Addon.db and ns.Addon.db.profile
    if db and db.lootWindow and db.lootWindow.enabled then
        ns.SuppressBlizzardLootFrame()
    end

    ns.DebugPrint("LOOT_OPENED captured autoLoot=" .. tostring(pendingAutoLoot))
end

local function OnLootReady()
    if isLootOpen then
        return
    end

    local db = ns.Addon.db.profile
    if not db.lootWindow.enabled then
        return
    end

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
    ns.ListenerShared.OnLootSlotCleared(isLootOpen, slotIndex)
end

local function OnLootSlotChanged(_, slotIndex)
    ns.ListenerShared.OnLootSlotChanged(isLootOpen, slotIndex)
end

local function OnLootClosed()
    pendingAutoLoot = false
    isLootOpen = ns.ListenerShared.OnLootClosed(isLootOpen, "Retail")
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
