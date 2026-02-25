-------------------------------------------------------------------------------
-- ConfigWindow.lua
-- Standalone AceGUI configuration window for DragonLoot
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-------------------------------------------------------------------------------
-- Config Window Management
-------------------------------------------------------------------------------

function ns.OpenConfigWindow()
    AceConfigDialog:Open(ADDON_NAME)
end

function ns.CloseConfigWindow()
    AceConfigDialog:Close(ADDON_NAME)
end

function ns.ToggleConfigWindow()
    if AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames[ADDON_NAME] then
        ns.CloseConfigWindow()
    else
        ns.OpenConfigWindow()
    end
end
