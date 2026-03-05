-------------------------------------------------------------------------------
-- GeneralTab.lua
-- General settings tab: enabled, minimap icon, debug mode
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local PADDING_SIDE = 10
local PADDING_TOP = -10
local SPACING_AFTER_HEADER = 8
local SPACING_BETWEEN_WIDGETS = 6
local PADDING_BOTTOM = 20

-------------------------------------------------------------------------------
-- Build the General tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local W = ns.Widgets
    local db = dlns.Addon.db
    local yOffset = PADDING_TOP

    ---------------------------------------------------------------------------
    -- Header: General
    ---------------------------------------------------------------------------
    local header = W.CreateHeader(parent, "General")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    ---------------------------------------------------------------------------
    -- Toggle: Enable DragonLoot
    ---------------------------------------------------------------------------
    local enableToggle = W.CreateToggle(parent, {
        label = "Enable DragonLoot",
        tooltip = "Enable or disable the DragonLoot addon",
        get = function() return db.profile.enabled end,
        set = function(value)
            db.profile.enabled = value
            if value then
                dlns.Addon:OnEnable()
            else
                dlns.Addon:OnDisable()
            end
        end,
    })
    enableToggle:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    enableToggle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - enableToggle:GetHeight() - SPACING_BETWEEN_WIDGETS

    ---------------------------------------------------------------------------
    -- Toggle: Show Minimap Icon
    ---------------------------------------------------------------------------
    local minimapToggle = W.CreateToggle(parent, {
        label = "Show Minimap Icon",
        tooltip = "Show or hide the minimap button",
        get = function() return not db.profile.minimap.hide end,
        set = function(value)
            db.profile.minimap.hide = not value
            if dlns.MinimapIcon and dlns.MinimapIcon.Refresh then
                dlns.MinimapIcon.Refresh()
            end
        end,
    })
    minimapToggle:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    minimapToggle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - minimapToggle:GetHeight() - SPACING_BETWEEN_WIDGETS

    ---------------------------------------------------------------------------
    -- Toggle: Debug Mode
    ---------------------------------------------------------------------------
    local debugToggle = W.CreateToggle(parent, {
        label = "Debug Mode",
        tooltip = "Enable verbose debug output in chat",
        get = function() return db.profile.debug end,
        set = function(value)
            db.profile.debug = value
        end,
    })
    debugToggle:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    debugToggle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - debugToggle:GetHeight() - SPACING_BETWEEN_WIDGETS

    ---------------------------------------------------------------------------
    -- Set content height for scroll frame
    ---------------------------------------------------------------------------
    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "general",
    label = "General",
    order = 1,
    createFunc = CreateContent,
}
