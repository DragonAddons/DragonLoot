-------------------------------------------------------------------------------
-- ProfilesTab.lua
-- Profile management tab: switch, create, copy, reset, delete profiles
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local table_sort = table.sort
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs

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
local NEW_PROFILE_INPUT_WIDTH = 250

-------------------------------------------------------------------------------
-- Static popup dialogs (defined at file scope)
-------------------------------------------------------------------------------

StaticPopupDialogs["DRAGONLOOT_RESET_PROFILE"] = {
    text = "Are you sure you want to reset the current profile to defaults?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        local db = dlns.Addon.db
        db:ResetProfile()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["DRAGONLOOT_DELETE_PROFILE"] = {
    text = "Are you sure you want to delete profile \"%s\"?",
    button1 = "Yes",
    button2 = "No",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-------------------------------------------------------------------------------
-- Anchor a widget to the parent at the current yOffset
-------------------------------------------------------------------------------

local function AnchorWidget(widget, parent, yOffset, xLeft, xRight)
    xLeft = xLeft or PADDING_SIDE
    xRight = xRight or -PADDING_SIDE
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", xLeft, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", xRight, yOffset)
    return yOffset - widget:GetHeight()
end

-------------------------------------------------------------------------------
-- Build sorted profile values from AceDB
-------------------------------------------------------------------------------

local function GetProfileValues(db)
    local profiles = db:GetProfiles({})
    table_sort(profiles)
    local values = {}
    for i = 1, #profiles do
        values[#values + 1] = { value = profiles[i], text = profiles[i] }
    end
    return values
end

-------------------------------------------------------------------------------
-- Build profile values excluding the current profile
-------------------------------------------------------------------------------

local function GetOtherProfileValues(db)
    local current = db:GetCurrentProfile()
    local profiles = db:GetProfiles({})
    table_sort(profiles)
    local values = {}
    for i = 1, #profiles do
        if profiles[i] ~= current then
            values[#values + 1] = { value = profiles[i], text = profiles[i] }
        end
    end
    return values
end

-------------------------------------------------------------------------------
-- Section: Current Profile header + active dropdown + new profile input
-------------------------------------------------------------------------------

local function CreateCurrentProfileSection(parent, W, db, yOffset, refreshAll)
    local header = W.CreateHeader(parent, "Current Profile")
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    local activeDropdown = W.CreateDropdown(parent, {
        label = "Active Profile",
        values = function() return GetProfileValues(db) end,
        get = function() return db:GetCurrentProfile() end,
        set = function(value)
            db:SetProfile(value)
            refreshAll()
        end,
    })
    yOffset = AnchorWidget(activeDropdown, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    -- New profile: text input on the left, create button to its right
    local newProfileInput = W.CreateTextInput(parent, {
        label = "New Profile",
        width = NEW_PROFILE_INPUT_WIDTH,
        maxLength = 64,
    })
    newProfileInput:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    newProfileInput:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)

    local createBtn = W.CreateButton(parent, {
        text = "Create",
        width = 80,
        tooltip = "Create a new profile with the entered name and switch to it",
        onClick = function()
            local name = newProfileInput:GetValue()
            if not name or name == "" then return end
            db:SetProfile(name)
            newProfileInput:SetValue("")
            refreshAll()
        end,
    })
    createBtn:ClearAllPoints()
    createBtn:SetPoint("LEFT", newProfileInput._editBox, "RIGHT", 8, 0)

    yOffset = yOffset - newProfileInput:GetHeight() - SPACING_BETWEEN_SECTIONS

    return yOffset, activeDropdown
end

-------------------------------------------------------------------------------
-- Section: Profile Actions - copy, reset, delete
-------------------------------------------------------------------------------

local function CreateActionsSection(parent, W, db, yOffset, refreshAll)
    local header = W.CreateHeader(parent, "Profile Actions")
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    -- Copy From dropdown
    local copyDropdown = W.CreateDropdown(parent, {
        label = "Copy From",
        values = function() return GetOtherProfileValues(db) end,
        get = function() return nil end,
        set = function(value)
            db:CopyProfile(value)
            refreshAll()
        end,
    })
    yOffset = AnchorWidget(copyDropdown, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    -- Reset Current Profile button
    local resetBtn = W.CreateButton(parent, {
        text = "Reset Current Profile",
        width = 160,
        tooltip = "Reset all settings in the current profile to their default values",
        onClick = function()
            StaticPopup_Show("DRAGONLOOT_RESET_PROFILE")
        end,
    })
    resetBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    yOffset = yOffset - resetBtn:GetHeight() - SPACING_BETWEEN_WIDGETS

    -- Delete Profile dropdown
    local deleteDropdown = W.CreateDropdown(parent, {
        label = "Delete Profile",
        values = function() return GetOtherProfileValues(db) end,
        get = function() return nil end,
        set = function(value)
            StaticPopupDialogs["DRAGONLOOT_DELETE_PROFILE"].OnAccept = function()
                db:DeleteProfile(value)
                refreshAll()
            end
            StaticPopup_Show("DRAGONLOOT_DELETE_PROFILE", value)
        end,
    })
    yOffset = AnchorWidget(deleteDropdown, parent, yOffset) - SPACING_BETWEEN_WIDGETS

    return yOffset, copyDropdown, deleteDropdown
end

-------------------------------------------------------------------------------
-- Build the Profiles tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local W = ns.Widgets
    local db = dlns.Addon.db
    local yOffset = PADDING_TOP

    -- Forward-declare widget refs for refresh closure
    local activeDropdown, copyDropdown, deleteDropdown

    local function RefreshProfileWidgets()
        if activeDropdown then activeDropdown:Refresh() end
        if copyDropdown then copyDropdown:Refresh() end
        if deleteDropdown then deleteDropdown:Refresh() end
    end

    -- Header + description
    local header = W.CreateHeader(parent, "Profiles")
    yOffset = AnchorWidget(header, parent, yOffset) - SPACING_AFTER_HEADER

    local desc = W.CreateDescription(parent,
        "Profiles allow you to save different settings configurations. You can switch between"
        .. " profiles, copy settings from another profile, or reset to defaults.")
    yOffset = AnchorWidget(desc, parent, yOffset) - SPACING_BETWEEN_SECTIONS

    -- Current Profile section
    yOffset, activeDropdown = CreateCurrentProfileSection(
        parent, W, db, yOffset, RefreshProfileWidgets
    )

    -- Profile Actions section
    yOffset, copyDropdown, deleteDropdown = CreateActionsSection(
        parent, W, db, yOffset, RefreshProfileWidgets
    )

    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "profiles",
    label = "Profiles",
    order = 8,
    createFunc = CreateContent,
}
