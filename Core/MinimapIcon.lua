-------------------------------------------------------------------------------
-- MinimapIcon.lua
-- Minimap button via LibDBIcon-1.0 and LibDataBroker-1.1
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local IsShiftKeyDown = IsShiftKeyDown

-------------------------------------------------------------------------------
-- Minimap Icon Module
-------------------------------------------------------------------------------

ns.MinimapIcon = {}

local function OnMinimapClick(_, button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            ns.Print("Shift-click test: DragonLoot is working.")
        else
            if ns.ToggleConfigWindow then
                ns.ToggleConfigWindow()
            end
        end
    elseif button == "RightButton" then
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
end

local function OnMinimapTooltipShow(tooltip)
    tooltip:AddDoubleLine(
        "DragonLoot",
        ns.VERSION or "",
        1, 0.82, 0, 0.6, 0.6, 0.6
    )
    tooltip:AddLine(" ")

    local db = ns.Addon.db.profile
    local status = db.enabled
        and (ns.COLOR_GREEN .. "Enabled" .. ns.COLOR_RESET)
        or (ns.COLOR_RED .. "Disabled" .. ns.COLOR_RESET)
    tooltip:AddLine("Status: " .. status)
    tooltip:AddLine(" ")

    tooltip:AddLine(ns.COLOR_WHITE .. "Left-Click" .. ns.COLOR_RESET .. " - Open settings")
    tooltip:AddLine(ns.COLOR_WHITE .. "Shift-Left-Click" .. ns.COLOR_RESET .. " - Test message")
    tooltip:AddLine(ns.COLOR_WHITE .. "Right-Click" .. ns.COLOR_RESET .. " - Toggle on/off")
end

function ns.MinimapIcon.Initialize()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub("LibDBIcon-1.0", true)

    if not LDB or not LDBIcon then
        ns.DebugPrint("LibDataBroker or LibDBIcon not found, minimap icon disabled")
        return
    end

    local dataObject = LDB:NewDataObject("DragonLoot", {
        type = "launcher",
        icon = "Interface\\AddOns\\DragonLoot\\DragonLoot_Icon",
        label = "DragonLoot",
        text = "DragonLoot",
        OnClick = OnMinimapClick,
        OnTooltipShow = OnMinimapTooltipShow,
    })

    LDBIcon:Register("DragonLoot", dataObject, ns.Addon.db.profile.minimap)

    ns.DebugPrint("Minimap icon initialized")
end

function ns.MinimapIcon.Toggle()
    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LDBIcon then return end

    local db = ns.Addon.db.profile.minimap
    if db.hide then
        LDBIcon:Show("DragonLoot")
        db.hide = false
    else
        LDBIcon:Hide("DragonLoot")
        db.hide = true
    end
end

function ns.MinimapIcon.Refresh()
    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LDBIcon then return end

    LDBIcon:Refresh("DragonLoot", ns.Addon.db.profile.minimap)
end
