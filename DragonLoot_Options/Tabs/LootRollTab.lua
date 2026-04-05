-------------------------------------------------------------------------------
-- LootRollTab.lua
-- Loot Roll settings tab: roll frame layout and timer bar
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
-- Notify roll manager helper
-------------------------------------------------------------------------------

local function NotifyRollManager()
    if dlns.RollManager and dlns.RollManager.ApplySettings then
        dlns.RollManager.ApplySettings()
    end
end

-------------------------------------------------------------------------------
-- Timer bar color mode values
-------------------------------------------------------------------------------

local COLOR_MODE_VALUES = {
    { value = "gradient", text = "Gradient" },
    { value = "custom", text = "Custom" },
}

local TIMER_BAR_STYLE_VALUES = {
    { value = "normal", text = "Normal" },
    { value = "minimal", text = "Minimal" },
}

-------------------------------------------------------------------------------
-- Section: Roll Frame (basic settings)
-------------------------------------------------------------------------------

local function CreateRollFrameSection(parent, db, yOffset)
    local section = W.CreateSection(parent, "Roll Frame")
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local enableToggle = W.CreateToggle(content, {
        label = "Enable Custom Roll Frame",
        tooltip = "Replace the default Blizzard roll frame with DragonLoot's custom version",
        get = function() return db.profile.rollFrame.enabled end,
        set = function(value)
            db.profile.rollFrame.enabled = value
            NotifyRollManager()
        end,
    })
    innerY = LC.AnchorWidget(enableToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local lockToggle = W.CreateToggle(content, {
        label = "Lock Position",
        tooltip = "Prevent the roll frame from being dragged",
        get = function() return db.profile.rollFrame.lock end,
        set = function(value) db.profile.rollFrame.lock = value end,
    })
    innerY = LC.AnchorWidget(lockToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local hideOnVoteToggle = W.CreateToggle(content, {
        label = "Hide After Voting",
        tooltip = "Hide the roll frame after you cast your vote. The roll continues in the background"
            .. " and notifications still fire.",
        get = function() return db.profile.rollFrame.hideOnVote end,
        set = function(value) db.profile.rollFrame.hideOnVote = value end,
    })
    innerY = LC.AnchorWidget(hideOnVoteToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local testRollBtn = W.CreateButton(content, {
        text = "Test Roll",
        width = 100,
        tooltip = "Show test roll frames",
        onClick = function()
            if dlns.RollFrame and dlns.RollFrame.ShowTestRoll then
                dlns.RollFrame.ShowTestRoll()
            end
        end,
    })
    testRollBtn:SetPoint("TOPLEFT", content, "TOPLEFT", LC.PADDING_SIDE, innerY)

    local testLoopBtn = W.CreateButton(content, {
        text = "Test Loop",
        width = 100,
        tooltip = "Start or stop continuous test roll spawning",
        onClick = function()
            if dlns.RollFrame and dlns.RollFrame.ShowTestRollLoop then
                dlns.RollFrame.ShowTestRollLoop()
            end
        end,
    })
    testLoopBtn:SetPoint("LEFT", testRollBtn, "RIGHT", 8, 0)

    innerY = innerY - testRollBtn:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Helper: create a roll frame layout slider inside the given content frame
-------------------------------------------------------------------------------

local function CreateLayoutSlider(content, db, innerY, label, tooltip, key, min, max, step, fmt)
    local slider = W.CreateSlider(content, {
        label = label,
        tooltip = tooltip,
        min = min,
        max = max,
        step = step,
        format = fmt,
        get = function() return db.profile.rollFrame[key] end,
        set = function(value)
            db.profile.rollFrame[key] = value
            NotifyRollManager()
        end,
    })
    innerY = LC.AnchorWidget(slider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS
    return innerY
end

-------------------------------------------------------------------------------
-- Section: Layout (sliders + texture dropdown)
-------------------------------------------------------------------------------

local function CreateLayoutSection(parent, db, yOffset)
    local section = W.CreateSection(parent, "Layout")
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local frameMinHeightSlider, rowSpacingSlider  -- forward declare for compact toggle

    local isCompact = db.profile.rollFrame.compactTextLayout

    frameMinHeightSlider = W.CreateSlider(content, {
        label = "Frame Height",
        tooltip = "Minimum height of the roll frame",
        min = 40,
        max = 120,
        step = 1,
        format = "%d",
        get = function() return db.profile.rollFrame.frameMinHeight end,
        set = function(value)
            db.profile.rollFrame.frameMinHeight = value
            NotifyRollManager()
        end,
    })
    frameMinHeightSlider:SetDisabled(isCompact)
    innerY = LC.AnchorWidget(frameMinHeightSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    innerY = CreateLayoutSlider(content, db, innerY,
        "Scale", "Roll frame scale", "scale", 0.5, 2, 0.05, "%.2f")
    innerY = CreateLayoutSlider(content, db, innerY,
        "Frame Width", "Width of the roll frame", "frameWidth", 200, 500, 10, "%d")

    rowSpacingSlider = W.CreateSlider(content, {
        label = "Row Spacing",
        tooltip = "Vertical spacing between roll rows",
        min = 0,
        max = 16,
        step = 1,
        format = "%d",
        get = function() return db.profile.rollFrame.rowSpacing end,
        set = function(value)
            db.profile.rollFrame.rowSpacing = value
            NotifyRollManager()
        end,
    })
    rowSpacingSlider:SetDisabled(isCompact)
    innerY = LC.AnchorWidget(rowSpacingSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Timer Bar Style dropdown + height sliders
    local timerBarHeightSlider, minimalHeightSlider  -- forward declare

    local styleDropdown = W.CreateDropdown(content, {
        label = "Timer Bar Style",
        values = TIMER_BAR_STYLE_VALUES,
        get = function() return db.profile.rollFrame.timerBarStyle end,
        set = function(value)
            db.profile.rollFrame.timerBarStyle = value
            local isMinimal = (value == "minimal")
            if timerBarHeightSlider then timerBarHeightSlider:SetDisabled(isMinimal) end
            if minimalHeightSlider then minimalHeightSlider:SetDisabled(not isMinimal) end
            NotifyRollManager()
        end,
    })
    innerY = LC.AnchorWidget(styleDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    timerBarHeightSlider = W.CreateSlider(content, {
        label = "Timer Bar Height",
        tooltip = "Height of the countdown timer bar",
        min = 6,
        max = 24,
        step = 1,
        format = "%d",
        get = function() return db.profile.rollFrame.timerBarHeight end,
        set = function(value)
            db.profile.rollFrame.timerBarHeight = value
            NotifyRollManager()
        end,
    })
    timerBarHeightSlider:SetDisabled(db.profile.rollFrame.timerBarStyle == "minimal")
    innerY = LC.AnchorWidget(timerBarHeightSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    minimalHeightSlider = W.CreateSlider(content, {
        label = "Minimal Height",
        tooltip = "Height of the minimal timer bar",
        min = 1,
        max = 6,
        step = 1,
        format = "%d",
        get = function() return db.profile.rollFrame.timerBarMinimalHeight end,
        set = function(value)
            db.profile.rollFrame.timerBarMinimalHeight = value
            NotifyRollManager()
        end,
    })
    minimalHeightSlider:SetDisabled(db.profile.rollFrame.timerBarStyle ~= "minimal")
    innerY = LC.AnchorWidget(minimalHeightSlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    innerY = CreateLayoutSlider(content, db, innerY,
        "Timer Bar Spacing", "Space between item row and timer bar",
        "timerBarSpacing", 0, 16, 1, "%d")
    innerY = CreateLayoutSlider(content, db, innerY,
        "Content Padding", "Inner padding of the roll frame",
        "contentPadding", 0, 12, 1, "%d")
    innerY = CreateLayoutSlider(content, db, innerY,
        "Button Size", "Size of Need/Greed/Pass buttons",
        "buttonSize", 16, 36, 1, "%d")
    innerY = CreateLayoutSlider(content, db, innerY,
        "Button Spacing", "Spacing between roll buttons",
        "buttonSpacing", 0, 12, 1, "%d")
    innerY = CreateLayoutSlider(content, db, innerY,
        "Frame Spacing", "Spacing between multiple roll frames",
        "frameSpacing", 0, 16, 1, "%d")

    local compactToggle = W.CreateToggle(content, {
        label = "Compact Text Layout",
        tooltip = "Show item name and bind type on the same line",
        get = function() return db.profile.rollFrame.compactTextLayout end,
        set = function(value)
            db.profile.rollFrame.compactTextLayout = value
            if frameMinHeightSlider then frameMinHeightSlider:SetDisabled(value) end
            if rowSpacingSlider then rowSpacingSlider:SetDisabled(value) end
            NotifyRollManager()
        end,
    })
    innerY = LC.AnchorWidget(compactToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local textureDropdown = W.CreateDropdown(content, {
        label = "Timer Bar Texture",
        values = function() return LC.BuildLSMValues("statusbar") end,
        sort = true,
        mediaType = "statusbar",
        get = function() return db.profile.rollFrame.timerBarTexture end,
        set = function(value)
            db.profile.rollFrame.timerBarTexture = value
            NotifyRollManager()
        end,
    })
    innerY = LC.AnchorWidget(textureDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Timer Bar Appearance sub-header (visual separator inside section)
    local timerBarHeader = W.CreateHeader(content, "Timer Bar Appearance")
    innerY = LC.AnchorWidget(timerBarHeader, content, innerY) - LC.SPACING_AFTER_HEADER

    local borderColorPicker  -- forward declare

    local borderToggle = W.CreateToggle(content, {
        label = "Timer Bar Border",
        tooltip = "Show a border around the timer bar",
        get = function() return db.profile.rollFrame.timerBarBorder end,
        set = function(value)
            db.profile.rollFrame.timerBarBorder = value
            if borderColorPicker then borderColorPicker:SetDisabled(not value) end
            NotifyRollManager()
        end,
    })
    innerY = LC.AnchorWidget(borderToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    borderColorPicker = W.CreateColorPicker(content, {
        label = "Timer Bar Border Color",
        hasAlpha = false,
        get = function()
            local c = db.profile.rollFrame.timerBarBorderColor
            return c.r, c.g, c.b
        end,
        set = function(r, g, b)
            db.profile.rollFrame.timerBarBorderColor.r = r
            db.profile.rollFrame.timerBarBorderColor.g = g
            db.profile.rollFrame.timerBarBorderColor.b = b
            NotifyRollManager()
        end,
    })
    borderColorPicker:SetDisabled(not db.profile.rollFrame.timerBarBorder)
    innerY = LC.AnchorWidget(borderColorPicker, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local barColorPicker  -- forward declare

    local colorModeDropdown = W.CreateDropdown(content, {
        label = "Color Mode",
        values = COLOR_MODE_VALUES,
        get = function() return db.profile.rollFrame.timerBarColorMode end,
        set = function(value)
            db.profile.rollFrame.timerBarColorMode = value
            if barColorPicker then barColorPicker:SetDisabled(value ~= "custom") end
            NotifyRollManager()
        end,
    })
    innerY = LC.AnchorWidget(colorModeDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    barColorPicker = W.CreateColorPicker(content, {
        label = "Bar Color",
        hasAlpha = false,
        get = function()
            local c = db.profile.rollFrame.timerBarColor
            return c.r, c.g, c.b
        end,
        set = function(r, g, b)
            db.profile.rollFrame.timerBarColor.r = r
            db.profile.rollFrame.timerBarColor.g = g
            db.profile.rollFrame.timerBarColor.b = b
            NotifyRollManager()
        end,
    })
    barColorPicker:SetDisabled(db.profile.rollFrame.timerBarColorMode ~= "custom")
    innerY = LC.AnchorWidget(barColorPicker, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local bgColorPicker = W.CreateColorPicker(content, {
        label = "Bar Background",
        hasAlpha = false,
        get = function()
            local c = db.profile.rollFrame.timerBarBackgroundColor
            return c.r, c.g, c.b
        end,
        set = function(r, g, b)
            db.profile.rollFrame.timerBarBackgroundColor.r = r
            db.profile.rollFrame.timerBarBackgroundColor.g = g
            db.profile.rollFrame.timerBarBackgroundColor.b = b
            NotifyRollManager()
        end,
    })
    innerY = LC.AnchorWidget(bgColorPicker, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local bgOpacitySlider = W.CreateSlider(content, {
        label = "Bar Background Opacity",
        min = 0,
        max = 1,
        step = 0.05,
        isPercent = true,
        format = "%.0f",
        get = function() return db.profile.rollFrame.timerBarBackgroundAlpha end,
        set = function(value)
            db.profile.rollFrame.timerBarBackgroundAlpha = value
            NotifyRollManager()
        end,
    })
    innerY = LC.AnchorWidget(bgOpacitySlider, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Loot Roll tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local db = dlns.Addon.db
    local yOffset = LC.PADDING_TOP

    yOffset = CreateRollFrameSection(parent, db, yOffset)
    yOffset = CreateLayoutSection(parent, db, yOffset)

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "lootRoll",
    label = "Loot Roll",
    order = 3,
    createFunc = CreateContent,
}
