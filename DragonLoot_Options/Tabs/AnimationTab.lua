-------------------------------------------------------------------------------
-- AnimationTab.lua
-- Animation settings tab: enable/disable, durations, per-frame animation types
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local ipairs = ipairs
local LibStub = LibStub

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
-- Build entrance/exit animation name values from LibAnimate
-------------------------------------------------------------------------------

local function GetEntranceValues()
    local lib = LibStub("LibAnimate", true)
    if not lib then return {} end
    local names = lib:GetEntranceAnimations()
    local values = { { value = "none", text = "None" } }
    for _, name in ipairs(names) do
        values[#values + 1] = { value = name, text = name }
    end
    return values
end

local function GetExitValues()
    local lib = LibStub("LibAnimate", true)
    if not lib then return {} end
    local names = lib:GetExitAnimations()
    local values = { { value = "none", text = "None" } }
    for _, name in ipairs(names) do
        values[#values + 1] = { value = name, text = name }
    end
    return values
end

-------------------------------------------------------------------------------
-- Create an animation dropdown for a given db key
-------------------------------------------------------------------------------

local function CreateAnimDropdown(content, db, innerY, label, key, valuesFn)
    local dropdown = W.CreateDropdown(content, {
        label = label,
        values = valuesFn,
        get = function() return db.profile.animation[key] end,
        set = function(value)
            db.profile.animation[key] = value
            LC.NotifyAppearanceChange()
        end,
    })
    return LC.AnchorWidget(dropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS
end

-------------------------------------------------------------------------------
-- Build the Animation tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local db = dlns.Addon.db
    local yOffset = LC.PADDING_TOP

    ---------------------------------------------------------------------------
    -- Section: Animation (global toggle + durations)
    ---------------------------------------------------------------------------
    local animSection = W.CreateSection(parent, "Animation")
    local animContent = animSection.content
    local animY = -LC.SECTION_PADDING_TOP

    local enableToggle = W.CreateToggle(animContent, {
        label = "Enable Animations",
        tooltip = "Enable or disable all DragonLoot animations",
        get = function() return db.profile.animation.enabled end,
        set = function(value)
            db.profile.animation.enabled = value
            LC.NotifyAppearanceChange()
        end,
    })
    animY = LC.AnchorWidget(enableToggle, animContent, animY) - LC.SPACING_BETWEEN_WIDGETS

    local openDuration = W.CreateSlider(animContent, {
        label = "Open Duration",
        tooltip = "Duration of open/show animations in seconds",
        min = 0.1,
        max = 1,
        step = 0.05,
        format = "%.2f",
        get = function() return db.profile.animation.openDuration end,
        set = function(value)
            db.profile.animation.openDuration = value
            LC.NotifyAppearanceChange()
        end,
    })
    animY = LC.AnchorWidget(openDuration, animContent, animY) - LC.SPACING_BETWEEN_WIDGETS

    local closeDuration = W.CreateSlider(animContent, {
        label = "Close Duration",
        tooltip = "Duration of close/hide animations in seconds",
        min = 0.1,
        max = 1,
        step = 0.05,
        format = "%.2f",
        get = function() return db.profile.animation.closeDuration end,
        set = function(value)
            db.profile.animation.closeDuration = value
            LC.NotifyAppearanceChange()
        end,
    })
    animY = LC.AnchorWidget(closeDuration, animContent, animY) - LC.SPACING_BETWEEN_WIDGETS

    animSection:SetContentHeight(math_abs(animY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(animSection, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    ---------------------------------------------------------------------------
    -- Section: Loot Window animation types
    ---------------------------------------------------------------------------
    local lootSection = W.CreateSection(parent, "Loot Window")
    local lootContent = lootSection.content
    local lootY = -LC.SECTION_PADDING_TOP

    lootY = CreateAnimDropdown(
        lootContent, db, lootY, "Open Animation", "lootOpenAnim", GetEntranceValues
    )
    lootY = CreateAnimDropdown(
        lootContent, db, lootY, "Close Animation", "lootCloseAnim", GetExitValues
    )

    lootSection:SetContentHeight(math_abs(lootY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(lootSection, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    ---------------------------------------------------------------------------
    -- Section: Roll Frame animation types
    ---------------------------------------------------------------------------
    local rollSection = W.CreateSection(parent, "Roll Frame")
    local rollContent = rollSection.content
    local rollY = -LC.SECTION_PADDING_TOP

    rollY = CreateAnimDropdown(
        rollContent, db, rollY, "Show Animation", "rollShowAnim", GetEntranceValues
    )
    rollY = CreateAnimDropdown(
        rollContent, db, rollY, "Hide Animation", "rollHideAnim", GetExitValues
    )

    rollSection:SetContentHeight(math_abs(rollY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(rollSection, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    ---------------------------------------------------------------------------
    -- Set content height for scroll frame
    ---------------------------------------------------------------------------
    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "animation",
    label = "Animation",
    order = 8,
    createFunc = CreateContent,
}
