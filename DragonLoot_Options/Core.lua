-------------------------------------------------------------------------------
-- Core.lua
-- DragonLoot_Options bootstrap - bridges DragonWidgets for DragonLoot config
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local tinsert = table.insert

-------------------------------------------------------------------------------
-- DragonWidgets bridge
-------------------------------------------------------------------------------

local DW = DragonWidgetsNS
if not DW then
    error("[DragonLoot_Options] DragonWidgets is not loaded. Ensure DragonWidgets is installed and enabled.", 2)
end

ns.DW = DW

-------------------------------------------------------------------------------
-- Tab registry (populated by subsequent tab files)
-------------------------------------------------------------------------------

ns.Tabs = {}

-------------------------------------------------------------------------------
-- Shared dropdown values (used by multiple tab files)
-------------------------------------------------------------------------------

ns.QualityValues = {
    { value = "0", text = "|cff9d9d9dPoor|r" },
    { value = "1", text = "|cffffffffCommon|r" },
    { value = "2", text = "|cff1eff00Uncommon|r" },
    { value = "3", text = "|cff0070ddRare|r" },
    { value = "4", text = "|cffa335eeEpic|r" },
    { value = "5", text = "|cffff8000Legendary|r" },
}

-------------------------------------------------------------------------------
-- Appearance-change listener
--
-- When DragonWidgets fires OnAppearanceChanged, propagate to all DragonLoot
-- display modules that are currently loaded.
-------------------------------------------------------------------------------

DW.On("OnAppearanceChanged", function()
    local dl = ns.dlns
    if not dl then return end
    if dl.LootFrame and dl.LootFrame.ApplySettings then dl.LootFrame.ApplySettings() end
    if dl.RollManager and dl.RollManager.ApplySettings then dl.RollManager.ApplySettings() end
    if dl.HistoryFrame and dl.HistoryFrame.ApplySettings then dl.HistoryFrame.ApplySettings() end
end)

-------------------------------------------------------------------------------
-- Panel state
-------------------------------------------------------------------------------

local panelResult

-------------------------------------------------------------------------------
-- Create the options panel (called lazily on first Open)
-------------------------------------------------------------------------------

local function CreateOptionsPanel()
    ns.dlns = _G.DragonLootNS
    if not ns.dlns then
        print("|cffff6600[DragonLoot_Options]|r DragonLoot namespace not found.")
        return
    end

    local tabDefs = {}
    for i = 1, #ns.Tabs do
        tinsert(tabDefs, ns.Tabs[i])
    end

    panelResult = DW.CreateOptionsPanel({
        name = "DragonLootOptionsFrame",
        title = "DragonLoot Options",
        width = 800,
        height = 600,
        tabs = tabDefs,
    })
end

-------------------------------------------------------------------------------
-- Global API
-------------------------------------------------------------------------------

DragonLoot_Options = {}

function DragonLoot_Options.Open()
    if not panelResult then
        CreateOptionsPanel()
    end
    if not panelResult then return end
    panelResult.Open()
end

function DragonLoot_Options.Close()
    if not panelResult then return end
    panelResult.Close()
end

function DragonLoot_Options.Toggle()
    if not panelResult then
        CreateOptionsPanel()
    end
    if not panelResult then return end
    panelResult.Toggle()
end
