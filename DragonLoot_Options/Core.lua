-------------------------------------------------------------------------------
-- Core.lua
-- Entry point for DragonLoot_Options companion addon
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local tinsert = table.insert

-------------------------------------------------------------------------------
-- Locale bridge from main addon
-------------------------------------------------------------------------------

local AceLocale = LibStub and LibStub("AceLocale-3.0", true)
ns.L = AceLocale and AceLocale:GetLocale("DragonLoot", true)
if not ns.L then
    -- Fallback: return key as value (mirrors AceLocale default-locale behavior)
    ns.L = setmetatable({}, { __index = function(_, key) return key end })
end

-------------------------------------------------------------------------------
-- Widget and tab registries (populated by subsequent files)
-------------------------------------------------------------------------------

ns.Widgets = {}
ns.Tabs = {}

-------------------------------------------------------------------------------
-- Shared dropdown values (used by multiple tab files)
-------------------------------------------------------------------------------

local L = ns.L

ns.QualityValues = {
    { value = "0", text = "|cff9d9d9d" .. (L and L["Poor"] or "Poor") .. "|r" },
    { value = "1", text = "|cffffffff" .. (L and L["Common"] or "Common") .. "|r" },
    { value = "2", text = "|cff1eff00" .. (L and L["Uncommon"] or "Uncommon") .. "|r" },
    { value = "3", text = "|cff0070dd" .. (L and L["Rare"] or "Rare") .. "|r" },
    { value = "4", text = "|cffa335ee" .. (L and L["Epic"] or "Epic") .. "|r" },
    { value = "5", text = "|cffff8000" .. (L and L["Legendary"] or "Legendary") .. "|r" },
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
        print("|cffff6600[DragonLoot_Options]|r " .. (L and L["DragonLoot namespace not found."] or "DragonLoot namespace not found."))
        return
    end
    if not ns.dlns.L then
        print("|cffff6600[DragonLoot_Options]|r " .. (L and L["DragonLoot locale table (L) not found."] or "DragonLoot locale table (L) not found."))
        return
    end

    local panel = ns.Widgets.CreatePanel("DragonLootOptionsFrame", 800, 600)

    -- Tab group below title bar
    tabGroup = ns.Widgets.CreateTabGroup(panel, ns.Tabs)
    tabGroup:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -32)
    tabGroup:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 8)

    -- ESC-closable
    tinsert(UISpecialFrames, "DragonLootOptionsFrame")

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
