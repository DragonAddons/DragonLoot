-------------------------------------------------------------------------------
-- ScrollFrame.lua
-- ScrollFrame + child + scrollbar slider for scrollable content areas
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local math_max = math.max

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local SCROLLBAR_WIDTH = 14
local SCROLL_STEP = 20
local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"

-------------------------------------------------------------------------------
-- Scrollbar value changed handler (shared, avoids per-instance closures)
-------------------------------------------------------------------------------

local function OnScrollBarValueChanged(self, value)
    local sf = self._scrollFrame
    if sf then
        sf:SetVerticalScroll(value)
    end
end

-------------------------------------------------------------------------------
-- Update scroll range based on content vs visible height
-------------------------------------------------------------------------------

local function UpdateScrollRange(wrapper)
    local sf = wrapper._scrollFrame
    local bar = wrapper._scrollBar
    if not sf or not bar then return end

    local contentHeight = wrapper.scrollChild:GetHeight() or 0
    local visibleHeight = sf:GetHeight() or 0
    local maxScroll = math_max(0, contentHeight - visibleHeight)

    bar:SetMinMaxValues(0, maxScroll)
    if maxScroll == 0 then
        bar:Hide()
        sf:SetVerticalScroll(0)
    else
        bar:Show()
        -- Clamp current value
        local current = bar:GetValue()
        if current > maxScroll then
            bar:SetValue(maxScroll)
        end
    end
end

-------------------------------------------------------------------------------
-- Factory: CreateScrollFrame
-------------------------------------------------------------------------------

function ns.Widgets.CreateScrollFrame(parent)
    -- Wrapper frame that holds all scroll components
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints(parent)

    -- ScrollFrame for clipping
    local sf = CreateFrame("ScrollFrame", nil, wrapper)
    sf:SetPoint("TOPLEFT", wrapper, "TOPLEFT", 0, 0)
    sf:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", -SCROLLBAR_WIDTH - 2, 0)

    -- Scroll child (content frame)
    local child = CreateFrame("Frame", nil, sf)
    child:SetHeight(1)
    sf:SetScrollChild(child)

    -- Anchor child width to scroll frame width
    sf:SetScript("OnSizeChanged", function(self)
        child:SetWidth(self:GetWidth())
        UpdateScrollRange(wrapper)
    end)

    -- Scrollbar slider
    local bar = CreateFrame("Slider", nil, wrapper, "BackdropTemplate")
    bar:SetWidth(SCROLLBAR_WIDTH)
    bar:SetPoint("TOPRIGHT", wrapper, "TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 0, 0)
    bar:SetOrientation("VERTICAL")
    bar:SetMinMaxValues(0, 0)
    bar:SetValue(0)
    bar:SetValueStep(SCROLL_STEP)
    bar:SetBackdrop({ bgFile = WHITE8x8 })
    bar:SetBackdropColor(0.1, 0.1, 0.1, 0.5)

    -- Thumb texture
    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    thumb:SetSize(SCROLLBAR_WIDTH - 2, 30)
    bar:SetThumbTexture(thumb)

    -- Cross-reference for handler
    bar._scrollFrame = sf

    bar:SetScript("OnValueChanged", OnScrollBarValueChanged)
    bar:Hide()

    -- Mouse wheel scrolling
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(_, delta)
        local current = bar:GetValue()
        bar:SetValue(current - (delta * SCROLL_STEP))
    end)

    -- Store references on wrapper
    wrapper._scrollFrame = sf
    wrapper._scrollBar = bar
    wrapper.scrollChild = child

    function wrapper:UpdateScrollRange()
        UpdateScrollRange(self)
    end

    -- Also update range when child height changes
    child:SetScript("OnSizeChanged", function()
        UpdateScrollRange(wrapper)
    end)

    return wrapper
end
