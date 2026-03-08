-------------------------------------------------------------------------------
-- GeneralTab.lua
-- General settings tab: enabled, minimap icon, debug mode
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------

local L = ns.L

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateGeneralSection(parent)
    local db = dlns.Addon.db
    local section = LDF.CreateSection(parent, L["General"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Enable DragonLoot"],
        tooltip = L["Enable or disable the DragonLoot addon"],
        get = function() return db.profile.enabled end,
        set = function(value)
            db.profile.enabled = value
            if value then
                dlns.Addon:OnEnable()
            else
                dlns.Addon:OnDisable()
            end
        end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Minimap Icon"],
        tooltip = L["Show or hide the minimap button"],
        get = function() return not db.profile.minimap.hide end,
        set = function(value)
            db.profile.minimap.hide = not value
            if dlns.MinimapIcon and dlns.MinimapIcon.Refresh then
                dlns.MinimapIcon.Refresh()
            end
        end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Debug Mode"],
        tooltip = L["Enable verbose debug output in chat"],
        get = function() return db.profile.debug end,
        set = function(value) db.profile.debug = value end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Build the General tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local stack = LDF.CreateStackLayout(parent, "vertical")
    stack:AddChild(CreateGeneralSection(parent))
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "general",
    label = L["General"],
    order = 1,
    createFunc = CreateContent,
}
