-------------------------------------------------------------------------------
-- SlashCommands.lua
-- Slash command handler for DragonLoot
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached references
-------------------------------------------------------------------------------

local print = print
local string_lower = string.lower
local string_match = string.match

local L = ns.L

-------------------------------------------------------------------------------
-- Help Display
-------------------------------------------------------------------------------

local HELP_ENTRIES = {
    { "",             L["Toggle addon on/off"] },
    { " config",      L["Open settings panel"] },
    { " minimap",     L["Toggle minimap icon"] },
    { " enable",      L["Enable addon"] },
    { " disable",     L["Disable addon"] },
    { " reset",       L["Reset loot frame position"] },
    { " test",        L["Show test loot"] },
    { " testroll",    L["Show test roll frames"] },
    { " testroll loop", L["Start continuous test roll spawning"] },
    { " testroll stop", L["Stop continuous test roll spawning"] },
    { " history",     L["Toggle loot history"] },
    { " status",      L["Show current settings"] },
    { " help",        L["Show this help"] },
}

local function PrintHelp()
    print(ns.COLOR_GOLD .. L["--- DragonLoot Commands ---"] .. ns.COLOR_RESET)
    for _, entry in ipairs(HELP_ENTRIES) do
        print("  " .. ns.COLOR_WHITE .. "/dl" .. entry[1] .. ns.COLOR_RESET .. " - " .. entry[2])
    end
end

-------------------------------------------------------------------------------
-- Status Display
-------------------------------------------------------------------------------

local function PrintStatus()
    local db = ns.Addon.db.profile

    print(ns.COLOR_GOLD .. L["--- DragonLoot Status ---"] .. ns.COLOR_RESET)

    local enabledStr = db.enabled
        and (ns.COLOR_GREEN .. L["Yes"] .. ns.COLOR_RESET)
        or (ns.COLOR_RED .. L["No"] .. ns.COLOR_RESET)
    print("  " .. L["Enabled:"] .. " " .. enabledStr)

    print("  " .. L["Loot Window:"] .. " " .. (db.lootWindow.enabled and L["Yes"] or L["No"]))
    print("  " .. L["Roll Frame:"] .. " " .. (db.rollFrame.enabled and L["Yes"] or L["No"]))
    print("  " .. L["History:"] .. " " .. (db.history.enabled and L["Yes"] or L["No"]))
    print("  " .. L["Animations:"] .. " " .. (db.animation.enabled and L["Yes"] or L["No"]))
    print("  " .. L["Minimap Icon:"] .. " " .. (not db.minimap.hide and L["Yes"] or L["No"]))
end

-------------------------------------------------------------------------------
-- Command Router
-------------------------------------------------------------------------------

local function NormalizeCommand(input)
    local trimmedInput = string_match(input or "", "^%s*(.-)%s*$")
    return string_lower(trimmedInput)
end

local function ToggleAddon()
    local db = ns.Addon.db.profile
    db.enabled = not db.enabled

    if db.enabled then
        ns.Addon:OnEnable()
        ns.Print(L["Addon enabled"])
        return
    end

    ns.Addon:OnDisable()
    ns.Print(L["Addon disabled"])
end

function ns.HandleSlashCommand(input)
    local cmd = NormalizeCommand(input)

    if cmd == "" then
        PrintHelp()

    elseif cmd == "config" or cmd == "options" or cmd == "settings" then
        if ns.ToggleConfigWindow then
            ns.ToggleConfigWindow()
        end

    elseif cmd == "minimap" then
        if ns.MinimapIcon.Toggle then
            ns.MinimapIcon.Toggle()
        end

    elseif cmd == "toggle" then
        ToggleAddon()

    elseif cmd == "enable" then
        local db = ns.Addon.db.profile
        if not db.enabled then
            db.enabled = true
            ns.Addon:OnEnable()
        end
        ns.Print(L["Addon enabled"])

    elseif cmd == "disable" then
        local db = ns.Addon.db.profile
        if db.enabled then
            db.enabled = false
            ns.Addon:OnDisable()
        end
        ns.Print(L["Addon disabled"])

    elseif cmd == "reset" then
        if ns.LootFrame.ResetAnchor then
            ns.LootFrame.ResetAnchor()
            ns.Print(L["Loot frame position reset."])
        else
            ns.Print(L["Loot frame not yet available."])
        end

    elseif cmd == "test" then
        if ns.LootFrame.ShowTestLoot then
            ns.LootFrame.ShowTestLoot()
        else
            ns.Print(L["Test loot not yet available."])
        end

    elseif cmd == "testroll loop" then
        if ns.RollFrame.ShowTestRollLoop then
            ns.RollFrame.ShowTestRollLoop()
        else
            ns.Print(L["Test roll not yet available."])
        end

    elseif cmd == "testroll stop" then
        if ns.RollFrame.StopTestRollLoop then
            ns.RollFrame.StopTestRollLoop()
        else
            ns.Print(L["Test roll not yet available."])
        end

    elseif cmd == "testroll" then
        if ns.RollFrame.ShowTestRoll then
            ns.RollFrame.ShowTestRoll()
        else
            ns.Print(L["Test roll not yet available."])
        end

    elseif cmd == "history" then
        if ns.HistoryFrame.Toggle then
            ns.HistoryFrame.Toggle()
        else
            ns.Print(L["Loot history not yet available."])
        end

    elseif cmd == "status" then
        PrintStatus()

    elseif cmd == "help" or cmd == "?" then
        PrintHelp()

    else
        ns.Print(L["Unknown command:"] .. " " .. ns.COLOR_WHITE .. cmd .. ns.COLOR_RESET)
        PrintHelp()
    end
end
