-------------------------------------------------------------------------------
-- ConfigWindow.lua
-- Configuration window management for DragonLoot
-- Loads DragonLoot_Options companion addon on demand
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

local C_AddOns = C_AddOns
local IsAddOnLoaded = IsAddOnLoaded

local L = ns.L

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function IsOptionsLoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("DragonLoot_Options")
    elseif IsAddOnLoaded then
        return IsAddOnLoaded("DragonLoot_Options")
    end
    return false
end

local function LoadOptions()
    if IsOptionsLoaded() then
        return true
    end

    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("DragonLoot_Options")
    elseif LoadAddOn then
        LoadAddOn("DragonLoot_Options")
    end

    return IsOptionsLoaded()
end

-------------------------------------------------------------------------------
-- Config Window Management
-------------------------------------------------------------------------------

function ns.OpenConfigWindow()
    if not LoadOptions() then
        ns.Print(L["DragonLoot_Options addon not found. Please ensure it is installed."])
        return
    end

    if DragonLoot_Options and DragonLoot_Options.Open then
        DragonLoot_Options.Open()
    end
end

function ns.CloseConfigWindow()
    if DragonLoot_Options and DragonLoot_Options.Close then
        DragonLoot_Options.Close()
    end
end

function ns.ToggleConfigWindow()
    if DragonLoot_Options and DragonLoot_Options.Toggle then
        DragonLoot_Options.Toggle()
    else
        ns.OpenConfigWindow()
    end
end
