-------------------------------------------------------------------------------
-- RollButtonOrder_spec.lua
-- Tests for configurable roll-action button ordering.
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

local ROLL_PASS = 0
local ROLL_NEED = 1
local ROLL_GREED = 2
local ROLL_DISENCHANT = 3
local ROLL_TRANSMOG = 4

local function OverrideGlobal(name, value)
    local hadValue = rawget(_G, name) ~= nil
    local originalValue = rawget(_G, name)
    rawset(_G, name, value)
    return function()
        if hadValue then
            rawset(_G, name, originalValue)
        else
            rawset(_G, name, nil)
        end
    end
end

local function NewWidget(parent, created)
    local widget = {
        _parent = parent,
        _points = {},
        _shown = true,
        _height = 0,
        _scripts = {},
    }

    function widget:SetPoint(...)
        self._points[#self._points + 1] = { ... }
    end
    function widget:ClearAllPoints()
        self._points = {}
    end
    function widget:SetSize(_, height)
        self._height = height
    end
    function widget:SetHeight(height)
        self._height = height
    end
    function widget:GetHeight()
        return self._height
    end
    function widget:Show()
        self._shown = true
    end
    function widget:Hide()
        self._shown = false
    end
    function widget:IsShown()
        return self._shown
    end
    function widget:GetParent()
        return self._parent
    end
    function widget:SetScript(script, handler)
        self._scripts[script] = handler
    end
    function widget:GetScript(script)
        return self._scripts[script]
    end
    function widget:CreateTexture()
        return NewWidget(self, created)
    end
    function widget:CreateFontString()
        return NewWidget(self, created)
    end
    function widget:SetHighlightTexture()
        self._highlight = self._highlight or NewWidget(self, created)
    end
    function widget:SetHighlightAtlas()
        self._highlight = self._highlight or NewWidget(self, created)
    end
    function widget:GetHighlightTexture()
        return self._highlight
    end

    local noOpMethods = {
        "Disable",
        "Enable",
        "EnableMouse",
        "RegisterForClicks",
        "RegisterForDrag",
        "SetAllPoints",
        "SetAlpha",
        "SetAtlas",
        "SetBackdrop",
        "SetBackdropBorderColor",
        "SetClampedToScreen",
        "SetColorTexture",
        "SetDesaturated",
        "SetDrawLayer",
        "SetFont",
        "SetFrameLevel",
        "SetFrameStrata",
        "SetHighlightAtlas",
        "SetJustifyH",
        "SetMinMaxValues",
        "SetMovable",
        "SetScale",
        "SetShadowColor",
        "SetShadowOffset",
        "SetStatusBarColor",
        "SetStatusBarTexture",
        "SetTexCoord",
        "SetText",
        "SetTextColor",
        "SetTexture",
        "SetValue",
        "SetWidth",
        "SetWordWrap",
    }
    for _, method in ipairs(noOpMethods) do
        if not widget[method] then
            widget[method] = function() end
        end
    end

    created[#created + 1] = widget
    return widget
end

local function NewRollFrameNamespace(settings, rollData)
    local created = {}
    local selections = {}
    local restoreCreateFrame = OverrideGlobal("CreateFrame", function(_, _, parent)
        return NewWidget(parent, created)
    end)
    local restoreGetLootRollItemInfo = OverrideGlobal("GetLootRollItemInfo", function()
        return 12345,
            "Test Item",
            1,
            4,
            false,
            rollData.canNeed,
            rollData.canGreed,
            rollData.canDisenchant,
            nil,
            nil,
            nil,
            nil,
            rollData.canTransmog
    end)
    local originalLibStub = rawget(_G, "LibStub")
    local restoreLibStub = OverrideGlobal("LibStub", function(name)
        if name == "LibSharedMedia-3.0" then
            return {
                Fetch = function(_, _, value)
                    return value
                end,
            }
        end
        return originalLibStub(name)
    end)

    local ns = mock.CreateNamespace()
    ns.L = setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    })
    ns.DisplayUtils = {
        WHITE8x8 = "white",
        ApplyBackdrop = function() end,
        ApplyFontShadow = function() end,
        GetFont = function()
            return "font", 12, ""
        end,
        GetQualityColor = function()
            return 1, 1, 1
        end,
    }
    ns.RollAnimations = {
        PlayShow = function() end,
        PlayHide = function(_, onComplete)
            onComplete()
        end,
        StopAll = function() end,
    }
    ns.RollManager = {
        GetActiveRolls = function()
            return {}
        end,
        RequestRollSelection = function(rollID, rollType)
            selections[#selections + 1] = { rollID = rollID, rollType = rollType }
        end,
    }
    ns.RollTypeNames = {}

    local rollFrameSettings = {
        enabled = true,
        scale = 1,
        reverseButtonOrder = false,
        compactTextLayout = false,
        frameWidth = 328,
        frameMinHeight = 68,
        buttonSize = 24,
        buttonSpacing = 4,
        contentPadding = 4,
        rowSpacing = 4,
        timerBarSpacing = 4,
        timerBarHeight = 12,
        timerBarTexture = "Blizzard",
        timerBarStyle = "normal",
        timerBarMinimalHeight = 3,
        iconPosition = "inside",
        iconSide = "left",
    }
    for key, value in pairs(settings or {}) do
        rollFrameSettings[key] = value
    end
    ns.Addon = {
        db = {
            profile = {
                appearance = {
                    borderSize = 1,
                    qualityBorder = true,
                    rollIconSize = 36,
                    showItemLevel = false,
                },
                rollFrame = rollFrameSettings,
            },
        },
    }

    mock.LoadFile(ns, "DragonLoot/Display/RollFrame.lua")
    restoreCreateFrame()
    restoreGetLootRollItemInfo()
    restoreLibStub()

    ns.RollFrame.Initialize()
    ns.RollFrame.ShowRoll(1, 77)

    local buttons = {}
    for _, widget in ipairs(created) do
        if widget.rollType ~= nil then
            buttons[widget.rollType] = widget
        end
    end
    return ns, buttons, selections
end

local function GetVisibleOrder(buttons)
    local visible = {}
    local target = {}
    for rollType, button in pairs(buttons) do
        if button:IsShown() then
            visible[rollType] = button
            for _, point in ipairs(button._points) do
                local relative = point[2]
                if relative and relative.rollType ~= nil then
                    target[rollType] = relative.rollType
                end
            end
        end
    end

    local isTarget = {}
    for _, rollType in pairs(target) do
        isTarget[rollType] = true
    end
    local current
    for rollType in pairs(visible) do
        if not isTarget[rollType] then
            current = rollType
            break
        end
    end

    local order = {}
    while current ~= nil do
        order[#order + 1] = current
        current = target[current]
    end
    return order
end

describe("Roll action button order", function()
    local standardRoll = {
        canNeed = true,
        canGreed = true,
        canDisenchant = true,
        canTransmog = false,
    }

    before_each(function()
        mock.Reset()
    end)

    it("preserves the default order in normal layout", function()
        local _, buttons = NewRollFrameNamespace({}, standardRoll)

        assert.are.same({ ROLL_NEED, ROLL_GREED, ROLL_DISENCHANT, ROLL_PASS }, GetVisibleOrder(buttons))
    end)

    it("reverses the complete order in normal layout", function()
        local _, buttons = NewRollFrameNamespace({ reverseButtonOrder = true }, standardRoll)

        assert.are.same({ ROLL_PASS, ROLL_DISENCHANT, ROLL_GREED, ROLL_NEED }, GetVisibleOrder(buttons))
    end)

    it("reverses the complete order in compact layout", function()
        local _, buttons = NewRollFrameNamespace({
            reverseButtonOrder = true,
            compactTextLayout = true,
        }, standardRoll)

        assert.are.same({ ROLL_PASS, ROLL_DISENCHANT, ROLL_GREED, ROLL_NEED }, GetVisibleOrder(buttons))
    end)

    it("reverses visible Transmog while leaving hidden Greed out", function()
        local _, buttons, selections = NewRollFrameNamespace({ reverseButtonOrder = true }, {
            canNeed = true,
            canGreed = false,
            canDisenchant = true,
            canTransmog = true,
        })

        assert.is_false(buttons[ROLL_GREED]:IsShown())
        assert.are.same({ ROLL_PASS, ROLL_DISENCHANT, ROLL_TRANSMOG, ROLL_NEED }, GetVisibleOrder(buttons))
        buttons[ROLL_TRANSMOG]:GetScript("OnClick")(buttons[ROLL_TRANSMOG])
        assert.are.same({ { rollID = 77, rollType = ROLL_TRANSMOG } }, selections)
    end)

    it("keeps disabled actions in the complete visible sequence", function()
        local _, buttons = NewRollFrameNamespace({ reverseButtonOrder = true }, {
            canNeed = false,
            canGreed = false,
            canDisenchant = false,
            canTransmog = false,
        })

        assert.are.same({ ROLL_PASS, ROLL_DISENCHANT, ROLL_GREED, ROLL_NEED }, GetVisibleOrder(buttons))
    end)

    it("refreshes a visible frame and preserves each button action", function()
        local ns, buttons, selections = NewRollFrameNamespace({}, standardRoll)
        ns.Addon.db.profile.rollFrame.reverseButtonOrder = true

        ns.RollFrame.ApplySettings()
        for _, rollType in ipairs({ ROLL_PASS, ROLL_NEED, ROLL_GREED, ROLL_DISENCHANT }) do
            buttons[rollType]:GetScript("OnClick")(buttons[rollType])
        end

        assert.are.same({ ROLL_PASS, ROLL_DISENCHANT, ROLL_GREED, ROLL_NEED }, GetVisibleOrder(buttons))
        assert.are.same({
            { rollID = 77, rollType = ROLL_PASS },
            { rollID = 77, rollType = ROLL_NEED },
            { rollID = 77, rollType = ROLL_GREED },
            { rollID = 77, rollType = ROLL_DISENCHANT },
        }, selections)
    end)
end)
