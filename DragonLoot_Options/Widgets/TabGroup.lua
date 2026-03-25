-------------------------------------------------------------------------------
-- TabGroup.lua
-- Horizontal tab bar with lazy content creation and scroll frames
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...
local WC = ns.WidgetConstants

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TAB_HEIGHT = 28
local TAB_MIN_WIDTH = 60
local TAB_PADDING = 16

-------------------------------------------------------------------------------
-- Style a tab button as active or inactive
-------------------------------------------------------------------------------

local function StyleTabActive(btn)
    btn._bg:SetColorTexture(
        WC.SECTION_BG[1], WC.SECTION_BG[2], WC.SECTION_BG[3], WC.SECTION_BG[4]
    )
    btn._text:SetTextColor(WC.GOLD_COLOR[1], WC.GOLD_COLOR[2], WC.GOLD_COLOR[3])
    btn._bottomBorder:Hide()
    if btn._activeBar then btn._activeBar:Show() end
end

local function StyleTabInactive(btn)
    btn._bg:SetColorTexture(
        WC.PANEL_BG[1], WC.PANEL_BG[2], WC.PANEL_BG[3], WC.PANEL_BG[4]
    )
    btn._text:SetTextColor(WC.GRAY_COLOR[1], WC.GRAY_COLOR[2], WC.GRAY_COLOR[3])
    btn._bottomBorder:Show()
    if btn._activeBar then btn._activeBar:Hide() end
end

-------------------------------------------------------------------------------
-- Create a single tab button
-------------------------------------------------------------------------------

local function CreateTabButton(parent, label, tabGroup)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(TAB_HEIGHT)

    -- Background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(WC.PANEL_BG[1], WC.PANEL_BG[2], WC.PANEL_BG[3], WC.PANEL_BG[4])
    btn._bg = bg

    -- Text
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", btn, "CENTER", 0, 0)
    text:SetText(label)
    text:SetTextColor(WC.GRAY_COLOR[1], WC.GRAY_COLOR[2], WC.GRAY_COLOR[3])
    btn._text = text

    -- Auto-width based on text
    local textWidth = text:GetStringWidth() or 40
    local width = math.max(TAB_MIN_WIDTH, textWidth + TAB_PADDING * 2)
    btn:SetWidth(width)

    -- Bottom border (separator for inactive tabs)
    local bottomBorder = btn:CreateTexture(nil, "ARTWORK")
    bottomBorder:SetHeight(1)
    bottomBorder:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    bottomBorder:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    bottomBorder:SetColorTexture(
        WC.SECTION_BORDER[1], WC.SECTION_BORDER[2],
        WC.SECTION_BORDER[3], WC.SECTION_BORDER[4]
    )
    btn._bottomBorder = bottomBorder

    -- Gold underline for active state
    local activeBar = btn:CreateTexture(nil, "ARTWORK")
    activeBar:SetHeight(2)
    activeBar:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    activeBar:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    activeBar:SetColorTexture(WC.GOLD_COLOR[1], WC.GOLD_COLOR[2], WC.GOLD_COLOR[3], 0.8)
    activeBar:Hide()
    btn._activeBar = activeBar

    -- Highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.05)

    -- Click handler delegates to tabGroup
    btn:SetScript("OnClick", function()
        tabGroup:SelectTab(btn._tabId)
    end)

    return btn
end

-------------------------------------------------------------------------------
-- Factory: CreateTabGroup
-------------------------------------------------------------------------------

function ns.Widgets.CreateTabGroup(parent, tabs)
    local tabGroup = CreateFrame("Frame", nil, parent)

    -- Tab bar across the top
    local tabBar = CreateFrame("Frame", nil, tabGroup)
    tabBar:SetHeight(TAB_HEIGHT)
    tabBar:SetPoint("TOPLEFT", tabGroup, "TOPLEFT", 0, 0)
    tabBar:SetPoint("TOPRIGHT", tabGroup, "TOPRIGHT", 0, 0)

    -- Content area below tab bar
    local contentArea = CreateFrame("Frame", nil, tabGroup)
    contentArea:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, 0)
    contentArea:SetPoint("BOTTOMRIGHT", tabGroup, "BOTTOMRIGHT", 0, 0)

    -- Separator line below tab bar
    local separator = contentArea:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(1)
    separator:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 0, 0)
    separator:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", 0, 0)
    separator:SetColorTexture(
        WC.SECTION_BORDER[1], WC.SECTION_BORDER[2],
        WC.SECTION_BORDER[3], WC.SECTION_BORDER[4]
    )

    -- State
    local tabButtons = {}
    local contentFrames = {}
    local selectedTab = nil

    -- Create tab buttons
    local xOffset = 0
    for _, tabDef in ipairs(tabs) do
        local btn = CreateTabButton(tabBar, tabDef.label, tabGroup)
        btn._tabId = tabDef.id
        btn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", xOffset, 0)
        xOffset = xOffset + btn:GetWidth() + 1
        tabButtons[tabDef.id] = btn
    end

    -- SelectTab: switch to a tab, lazy-create content on first visit
    function tabGroup:SelectTab(id)
        if selectedTab == id then return end

        -- Deselect previous
        if selectedTab and tabButtons[selectedTab] then
            StyleTabInactive(tabButtons[selectedTab])
            if contentFrames[selectedTab] then
                contentFrames[selectedTab]:Hide()
            end
        end

        selectedTab = id

        -- Activate new tab button
        if tabButtons[id] then
            StyleTabActive(tabButtons[id])
        end

        -- Lazy-create content frame on first visit
        if not contentFrames[id] then
            local scrollWrapper = ns.Widgets.CreateScrollFrame(contentArea)
            scrollWrapper:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 0, -1)
            scrollWrapper:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)

            -- Find the tab definition and call its createFunc
            for _, tabDef in ipairs(tabs) do
                if tabDef.id == id and tabDef.createFunc then
                    tabDef.createFunc(scrollWrapper.scrollChild)
                    break
                end
            end

            contentFrames[id] = scrollWrapper
        end

        -- Show the content
        contentFrames[id]:Show()
    end

    function tabGroup:GetSelectedTab()
        return selectedTab
    end

    -- Auto-select first tab if available
    if tabs[1] then
        tabGroup:SelectTab(tabs[1].id)
    end

    return tabGroup
end
