-------------------------------------------------------------------------------
-- LootWindowTab.lua
-- Loot window settings tab: enable, lock, scale, dimensions, spacing
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
local SPACING_BETWEEN_SECTIONS = 16
local PADDING_BOTTOM = 20

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
    local W = ns.Widgets
    local db = dlns.Addon.db
    local yOffset = PADDING_TOP

    ---------------------------------------------------------------------------
    -- Header: Loot Window
    ---------------------------------------------------------------------------
    local header = W.CreateHeader(parent, "Loot Window")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    ---------------------------------------------------------------------------
    -- Toggle: Enable Custom Loot Window
    ---------------------------------------------------------------------------
    local enableToggle = W.CreateToggle(parent, {
        label = "Enable Custom Loot Window",
        tooltip = "Replace the default loot window with DragonLoot's custom frame",
        get = function() return db.profile.lootWindow.enabled end,
        set = function(value)
            db.profile.lootWindow.enabled = value
            ApplyLootSettings()
        end,
    })
    enableToggle:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    enableToggle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - enableToggle:GetHeight() - SPACING_BETWEEN_WIDGETS

    ---------------------------------------------------------------------------
    -- Toggle: Lock Position
    ---------------------------------------------------------------------------
    local lockToggle = W.CreateToggle(parent, {
        label = "Lock Position",
        tooltip = "Prevent the loot window from being moved",
        get = function() return db.profile.lootWindow.lock end,
        set = function(value)
            db.profile.lootWindow.lock = value
        end,
    })
    lockToggle:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    lockToggle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - lockToggle:GetHeight() - SPACING_BETWEEN_SECTIONS

    ---------------------------------------------------------------------------
    -- Header: Layout
    ---------------------------------------------------------------------------
    local layoutHeader = W.CreateHeader(parent, "Layout")
    layoutHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    layoutHeader:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - layoutHeader:GetHeight() - SPACING_AFTER_HEADER

    ---------------------------------------------------------------------------
    -- Slider: Scale
    ---------------------------------------------------------------------------
    local scaleSlider = W.CreateSlider(parent, {
        label = "Scale",
        min = 0.5, max = 2, step = 0.05,
        get = function() return db.profile.lootWindow.scale end,
        set = function(value)
            db.profile.lootWindow.scale = value
            ApplyLootSettings()
        end,
    })
    scaleSlider:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    scaleSlider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - scaleSlider:GetHeight() - SPACING_BETWEEN_WIDGETS

    ---------------------------------------------------------------------------
    -- Slider: Width
    ---------------------------------------------------------------------------
    local widthSlider = W.CreateSlider(parent, {
        label = "Width",
        min = 150, max = 400, step = 10,
        format = "%d",
        get = function() return db.profile.lootWindow.width end,
        set = function(value)
            db.profile.lootWindow.width = value
            ApplyLootSettings()
        end,
    })
    widthSlider:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    widthSlider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - widthSlider:GetHeight() - SPACING_BETWEEN_WIDGETS

    ---------------------------------------------------------------------------
    -- Slider: Height
    ---------------------------------------------------------------------------
    local heightSlider = W.CreateSlider(parent, {
        label = "Height",
        min = 150, max = 600, step = 10,
        format = "%d",
        get = function() return db.profile.lootWindow.height end,
        set = function(value)
            db.profile.lootWindow.height = value
            ApplyLootSettings()
        end,
    })
    heightSlider:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    heightSlider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - heightSlider:GetHeight() - SPACING_BETWEEN_WIDGETS

    ---------------------------------------------------------------------------
    -- Slider: Slot Spacing
    ---------------------------------------------------------------------------
    local slotSpacingSlider = W.CreateSlider(parent, {
        label = "Slot Spacing",
        min = 0, max = 12, step = 1,
        format = "%d",
        get = function() return db.profile.lootWindow.slotSpacing end,
        set = function(value)
            db.profile.lootWindow.slotSpacing = value
            ApplyLootSettings()
        end,
    })
    slotSpacingSlider:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    slotSpacingSlider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - slotSpacingSlider:GetHeight() - SPACING_BETWEEN_WIDGETS

    ---------------------------------------------------------------------------
    -- Slider: Content Padding
    ---------------------------------------------------------------------------
    local contentPaddingSlider = W.CreateSlider(parent, {
        label = "Content Padding",
        min = 0, max = 12, step = 1,
        format = "%d",
        get = function() return db.profile.lootWindow.contentPadding end,
        set = function(value)
            db.profile.lootWindow.contentPadding = value
            ApplyLootSettings()
        end,
    })
    contentPaddingSlider:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    contentPaddingSlider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
    yOffset = yOffset - contentPaddingSlider:GetHeight() - SPACING_BETWEEN_WIDGETS

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
    id = "lootWindow",
    label = "Loot Window",
    order = 2,
    createFunc = CreateContent,
}
