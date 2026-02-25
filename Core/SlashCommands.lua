-------------------------------------------------------------------------------
-- SlashCommands.lua
-- Slash command handler for DragonLoot
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local print = print
local strtrim = strtrim

-------------------------------------------------------------------------------
-- Help Display
-------------------------------------------------------------------------------

local function PrintHelp()
    print(ns.COLOR_GOLD .. "--- DragonLoot Commands ---" .. ns.COLOR_RESET)
    print("  " .. ns.COLOR_WHITE .. "/dl" .. ns.COLOR_RESET .. " - Toggle addon on/off")
    print("  " .. ns.COLOR_WHITE .. "/dl config" .. ns.COLOR_RESET .. " - Open settings panel")
    print("  " .. ns.COLOR_WHITE .. "/dl minimap" .. ns.COLOR_RESET .. " - Toggle minimap icon")
    print("  " .. ns.COLOR_WHITE .. "/dl enable" .. ns.COLOR_RESET .. " - Enable addon")
    print("  " .. ns.COLOR_WHITE .. "/dl disable" .. ns.COLOR_RESET .. " - Disable addon")
    print("  " .. ns.COLOR_WHITE .. "/dl reset" .. ns.COLOR_RESET .. " - Reset loot frame position")
    print("  " .. ns.COLOR_WHITE .. "/dl test" .. ns.COLOR_RESET .. " - Show test loot")
    print("  " .. ns.COLOR_WHITE .. "/dl status" .. ns.COLOR_RESET .. " - Show current settings")
    print("  " .. ns.COLOR_WHITE .. "/dl help" .. ns.COLOR_RESET .. " - Show this help")
end

-------------------------------------------------------------------------------
-- Status Display
-------------------------------------------------------------------------------

local function PrintStatus()
    local db = ns.Addon.db.profile

    print(ns.COLOR_GOLD .. "--- DragonLoot Status ---" .. ns.COLOR_RESET)

    local enabledStr = db.enabled
        and (ns.COLOR_GREEN .. "Yes" .. ns.COLOR_RESET)
        or (ns.COLOR_RED .. "No" .. ns.COLOR_RESET)
    print("  Enabled: " .. enabledStr)

    print("  Loot Window: " .. (db.lootWindow.enabled and "Yes" or "No"))
    print("  Roll Frame: " .. (db.rollFrame.enabled and "Yes" or "No"))
    print("  History: " .. (db.history.enabled and "Yes" or "No"))
    print("  Animations: " .. (db.animation.enabled and "Yes" or "No"))
    print("  Sound: " .. (db.sound.enabled and "Yes" or "No"))
    print("  Minimap Icon: " .. (not db.minimap.hide and "Yes" or "No"))
end

-------------------------------------------------------------------------------
-- Command Router
-------------------------------------------------------------------------------

local function ToggleAddon()
    local db = ns.Addon.db.profile
    db.enabled = not db.enabled
    if db.enabled then
        ns.Addon:OnEnable()
        ns.Print("Addon " .. ns.COLOR_GREEN .. "enabled" .. ns.COLOR_RESET)
    else
        ns.Addon:OnDisable()
        ns.Print("Addon " .. ns.COLOR_RED .. "disabled" .. ns.COLOR_RESET)
    end
end

local function SetAddonEnabled(enabled)
    local db = ns.Addon.db.profile
    if db.enabled ~= enabled then
        db.enabled = enabled
        if enabled then
            ns.Addon:OnEnable()
        else
            ns.Addon:OnDisable()
        end
    end
    local color = enabled and ns.COLOR_GREEN or ns.COLOR_RED
    local label = enabled and "enabled" or "disabled"
    ns.Print("Addon " .. color .. label .. ns.COLOR_RESET)
end

local commandHandlers = {
    ["config"]   = function() if ns.ToggleConfigWindow then ns.ToggleConfigWindow() end end,
    ["options"]  = function() if ns.ToggleConfigWindow then ns.ToggleConfigWindow() end end,
    ["settings"] = function() if ns.ToggleConfigWindow then ns.ToggleConfigWindow() end end,
    ["minimap"]  = function() if ns.MinimapIcon.Toggle then ns.MinimapIcon.Toggle() end end,
    ["enable"]   = function() SetAddonEnabled(true) end,
    ["disable"]  = function() SetAddonEnabled(false) end,
    ["status"]   = PrintStatus,
    ["help"]     = PrintHelp,
    ["?"]        = PrintHelp,
    ["reset"] = function()
        if ns.LootFrame.ResetAnchor then
            ns.LootFrame.ResetAnchor()
            ns.Print("Loot frame position reset.")
        else
            ns.Print("Loot frame not yet available.")
        end
    end,
    ["test"] = function()
        if ns.LootFrame.ShowTestLoot then
            ns.LootFrame.ShowTestLoot()
        else
            ns.Print("Test loot not yet available.")
        end
    end,
}

function ns.HandleSlashCommand(input)
    local cmd = strtrim((input or ""):lower())

    if cmd == "" then
        ToggleAddon()
        return
    end

    local handler = commandHandlers[cmd]
    if handler then
        handler()
    else
        ns.Print("Unknown command: " .. ns.COLOR_WHITE .. cmd .. ns.COLOR_RESET)
        PrintHelp()
    end
end
