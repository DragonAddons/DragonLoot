-------------------------------------------------------------------------------
-- GeneralTab.lua
-- General settings tab: enabled, minimap icon, debug mode
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs

-------------------------------------------------------------------------------
-- DragonWidgets references
-------------------------------------------------------------------------------

local W  = ns.DW.Widgets
local LC = ns.DW.LayoutConstants

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- Build the General tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local db = dlns.Addon.db
    local yOffset = LC.PADDING_TOP

    ---------------------------------------------------------------------------
    -- Section: General
    ---------------------------------------------------------------------------
    local section = W.CreateSection(parent, "General")
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    -- Toggle: Enable DragonLoot
    local enableToggle = W.CreateToggle(content, {
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
    innerY = LC.AnchorWidget(enableToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Toggle: Show Minimap Icon
    local minimapToggle = W.CreateToggle(content, {
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
    innerY = LC.AnchorWidget(minimapToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Toggle: Debug Mode
    local debugToggle = W.CreateToggle(content, {
        label = "Debug Mode",
        tooltip = "Enable verbose debug output in chat",
        get = function() return db.profile.debug end,
        set = function(value)
            db.profile.debug = value
        end,
    })
    innerY = LC.AnchorWidget(debugToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    ---------------------------------------------------------------------------
    -- Set content height for scroll frame
    ---------------------------------------------------------------------------
    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "general",
    label = "General",
    order = 1,
    createFunc = CreateContent,
}
