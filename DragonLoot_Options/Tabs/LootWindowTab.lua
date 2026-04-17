-------------------------------------------------------------------------------
-- LootWindowTab.lua
-- Loot window settings tab: enable, lock, scale, dimensions, spacing
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

local L = ns.L
-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local ipairs = ipairs

-------------------------------------------------------------------------------
-- DragonWidgets references
-------------------------------------------------------------------------------

local W = ns.DW.Widgets
local LC = ns.DW.LayoutConstants

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- Helper: call LootFrame.ApplySettings if available
-------------------------------------------------------------------------------

local function ApplyLootSettings()
    if dlns.LootFrame and dlns.LootFrame.ApplySettings then
        dlns.LootFrame.ApplySettings()
    end
end

-------------------------------------------------------------------------------
-- Build the Loot Window tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local db = dlns.Addon.db
    local yOffset = LC.PADDING_TOP
    local layoutWidgets = {}

    ---------------------------------------------------------------------------
    -- Section: Loot Window
    ---------------------------------------------------------------------------
    local lootSection = W.CreateSection(parent, L["Loot Window"])
    local lootContent = lootSection.content
    local lootY = -LC.SECTION_PADDING_TOP

    -- Toggle: Enable Custom Loot Window
    local enableToggle = W.CreateToggle(lootContent, {
        label = L["Enable Custom Loot Window"],
        tooltip = L["Replace the default loot window with DragonLoot's custom frame"],
        get = function()
            return db.profile.lootWindow.enabled
        end,
        set = function(value)
            db.profile.lootWindow.enabled = value
            ApplyLootSettings()
            for _, widget in ipairs(layoutWidgets) do
                widget:SetDisabled(not value)
            end
        end,
    })
    lootY = LC.AnchorWidget(enableToggle, lootContent, lootY) - LC.SPACING_BETWEEN_WIDGETS

    -- Toggle: Lock Position
    local lockToggle = W.CreateToggle(lootContent, {
        label = L["Lock Position"],
        tooltip = L["Prevent the loot window from being moved"],
        get = function()
            return db.profile.lootWindow.lock
        end,
        set = function(value)
            db.profile.lootWindow.lock = value
        end,
    })
    layoutWidgets[#layoutWidgets + 1] = lockToggle
    lootY = LC.AnchorWidget(lockToggle, lootContent, lootY) - LC.SPACING_BETWEEN_WIDGETS

    -- Toggle: Position at Cursor
    local cursorToggle = W.CreateToggle(lootContent, {
        label = L["Position at Cursor"],
        tooltip = L["Open the loot window at the mouse cursor instead of the saved position"],
        get = function()
            return db.profile.lootWindow.positionAtCursor
        end,
        set = function(value)
            db.profile.lootWindow.positionAtCursor = value
        end,
    })
    layoutWidgets[#layoutWidgets + 1] = cursorToggle
    lootY = LC.AnchorWidget(cursorToggle, lootContent, lootY) - LC.SPACING_BETWEEN_WIDGETS

    lootSection:SetContentHeight(math_abs(lootY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(lootSection, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    ---------------------------------------------------------------------------
    -- Section: Layout
    ---------------------------------------------------------------------------
    local layoutSection = W.CreateSection(parent, L["Layout"])
    local layoutContent = layoutSection.content
    local layoutY = -LC.SECTION_PADDING_TOP

    -- Slider: Scale
    local scaleSlider = W.CreateSlider(layoutContent, {
        label = L["Scale"],
        min = 0.5,
        max = 2,
        step = 0.05,
        get = function()
            return db.profile.lootWindow.scale
        end,
        set = function(value)
            db.profile.lootWindow.scale = value
            ApplyLootSettings()
        end,
    })
    layoutWidgets[#layoutWidgets + 1] = scaleSlider
    layoutY = LC.AnchorWidget(scaleSlider, layoutContent, layoutY) - LC.SPACING_BETWEEN_WIDGETS

    -- Slider: Width
    local widthSlider = W.CreateSlider(layoutContent, {
        label = L["Width"],
        min = 150,
        max = 400,
        step = 10,
        format = "%d",
        get = function()
            return db.profile.lootWindow.width
        end,
        set = function(value)
            db.profile.lootWindow.width = value
            ApplyLootSettings()
        end,
    })
    layoutWidgets[#layoutWidgets + 1] = widthSlider
    layoutY = LC.AnchorWidget(widthSlider, layoutContent, layoutY) - LC.SPACING_BETWEEN_WIDGETS

    -- Slider: Height
    local heightSlider = W.CreateSlider(layoutContent, {
        label = L["Height"],
        min = 150,
        max = 600,
        step = 10,
        format = "%d",
        get = function()
            return db.profile.lootWindow.height
        end,
        set = function(value)
            db.profile.lootWindow.height = value
            ApplyLootSettings()
        end,
    })
    layoutWidgets[#layoutWidgets + 1] = heightSlider
    layoutY = LC.AnchorWidget(heightSlider, layoutContent, layoutY) - LC.SPACING_BETWEEN_WIDGETS

    -- Slider: Slot Spacing
    local slotSpacingSlider = W.CreateSlider(layoutContent, {
        label = L["Slot Spacing"],
        min = 0,
        max = 12,
        step = 1,
        format = "%d",
        get = function()
            return db.profile.lootWindow.slotSpacing
        end,
        set = function(value)
            db.profile.lootWindow.slotSpacing = value
            ApplyLootSettings()
        end,
    })
    layoutWidgets[#layoutWidgets + 1] = slotSpacingSlider
    layoutY = LC.AnchorWidget(slotSpacingSlider, layoutContent, layoutY) - LC.SPACING_BETWEEN_WIDGETS

    -- Slider: Content Padding
    local contentPaddingSlider = W.CreateSlider(layoutContent, {
        label = L["Content Padding"],
        min = 0,
        max = 12,
        step = 1,
        format = "%d",
        get = function()
            return db.profile.lootWindow.contentPadding
        end,
        set = function(value)
            db.profile.lootWindow.contentPadding = value
            ApplyLootSettings()
        end,
    })
    layoutWidgets[#layoutWidgets + 1] = contentPaddingSlider
    layoutY = LC.AnchorWidget(contentPaddingSlider, layoutContent, layoutY) - LC.SPACING_BETWEEN_WIDGETS

    layoutSection:SetContentHeight(math_abs(layoutY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(layoutSection, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    ---------------------------------------------------------------------------
    -- Apply initial disabled state
    ---------------------------------------------------------------------------
    if not db.profile.lootWindow.enabled then
        for _, widget in ipairs(layoutWidgets) do
            widget:SetDisabled(true)
        end
    end

    ---------------------------------------------------------------------------
    -- Set content height for scroll frame
    ---------------------------------------------------------------------------
    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "lootWindow",
    label = L["Loot Window"],
    order = 2,
    createFunc = CreateContent,
}
