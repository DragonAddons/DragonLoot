-------------------------------------------------------------------------------
-- Core.lua
-- Entry point for DragonLoot_Options companion addon
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Locale bridge from main addon
-------------------------------------------------------------------------------

ns.L = LibStub("AceLocale-3.0"):GetLocale("DragonLoot")

-------------------------------------------------------------------------------
-- Tab registry (populated by subsequent files)
-------------------------------------------------------------------------------

ns.Tabs = {}

-------------------------------------------------------------------------------
-- Shared dropdown values (used by multiple tab files)
-------------------------------------------------------------------------------

local L = ns.L

ns.QualityValues = {
    { value = "0", text = "|cff9d9d9d" .. L["Poor"] .. "|r" },
    { value = "1", text = "|cffffffff" .. L["Common"] .. "|r" },
    { value = "2", text = "|cff1eff00" .. L["Uncommon"] .. "|r" },
    { value = "3", text = "|cff0070dd" .. L["Rare"] .. "|r" },
    { value = "4", text = "|cffa335ee" .. L["Epic"] .. "|r" },
    { value = "5", text = "|cffff8000" .. L["Legendary"] .. "|r" },
}

-------------------------------------------------------------------------------
-- Panel state
-------------------------------------------------------------------------------

local optionsPanel
local tabGroup

-------------------------------------------------------------------------------
-- Refresh all visible widget values from db
-------------------------------------------------------------------------------

local function RefreshVisibleWidgets()
    if not tabGroup then return end
    local selectedId = tabGroup:GetSelectedTab()
    if not selectedId then return end
    for _, tab in ipairs(ns.Tabs) do
        if tab.id == selectedId and tab.refreshFunc then
            tab.refreshFunc()
            break
        end
    end
end

-------------------------------------------------------------------------------
-- Create the options panel (called lazily on first Open)
-------------------------------------------------------------------------------

local function CreateOptionsPanel()
    ns.dlns = _G.DragonLootNS
    if not ns.dlns then
        print("|cffff6600[DragonLoot_Options]|r " .. L["DragonLoot namespace not found."])
        return
    end

    local panel = LDF.CreateWindow({
        name = "DragonLootOptionsFrame",
        title = "DragonLoot",
        width = 800,
        height = 600,
    })

    tabGroup = LDF.CreateTabGroup(panel.content, ns.Tabs)

    optionsPanel = panel
end

-------------------------------------------------------------------------------
-- Global API
-------------------------------------------------------------------------------

DragonLoot_Options = {}

function DragonLoot_Options.Open()
    if not optionsPanel then
        CreateOptionsPanel()
    end
    if not optionsPanel then return end
    optionsPanel:Show()
    RefreshVisibleWidgets()
end

function DragonLoot_Options.Close()
    if not optionsPanel then return end
    optionsPanel:Hide()
end

function DragonLoot_Options.Toggle()
    if optionsPanel and optionsPanel:IsShown() then
        DragonLoot_Options.Close()
    else
        DragonLoot_Options.Open()
    end
end

-------------------------------------------------------------------------------
-- Expose namespace bridge for widgets/tabs
-------------------------------------------------------------------------------

ns.RefreshVisibleWidgets = RefreshVisibleWidgets
