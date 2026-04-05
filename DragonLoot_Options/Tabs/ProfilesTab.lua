-------------------------------------------------------------------------------
-- ProfilesTab.lua
-- Profile management tab: switch, create, copy, reset, delete profiles
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local table_sort = table.sort
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs
local YES = YES
local NO = NO

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
-- Pending delete state (avoids mutating StaticPopupDialogs OnAccept closure)
-------------------------------------------------------------------------------

local pendingDeleteProfile = nil
local pendingDeleteDb = nil
local pendingDeleteRefresh = nil

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local NEW_PROFILE_INPUT_WIDTH = 250

-------------------------------------------------------------------------------
-- Static popup dialogs (defined at file scope)
-------------------------------------------------------------------------------

StaticPopupDialogs["DRAGONLOOT_RESET_PROFILE"] = {
    text = "Are you sure you want to reset the current profile to defaults?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        local dl = ns.dlns
        if not dl or not dl.Addon or not dl.Addon.db then return end
        dl.Addon.db:ResetProfile()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["DRAGONLOOT_DELETE_PROFILE"] = {
    text = "Are you sure you want to delete profile \"%s\"?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        if pendingDeleteProfile and pendingDeleteDb then
            pendingDeleteDb:DeleteProfile(pendingDeleteProfile)
            pendingDeleteProfile = nil
            if pendingDeleteRefresh then pendingDeleteRefresh() end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

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
-- Section: Current Profile - active dropdown + new profile input
-------------------------------------------------------------------------------

local function CreateCurrentProfileSection(parent, db, yOffset, refreshAll)
    local section = W.CreateSection(parent, "Current Profile")
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local activeDropdown = W.CreateDropdown(content, {
        label = "Active Profile",
        values = function() return GetProfileValues(db) end,
        get = function() return db:GetCurrentProfile() end,
        set = function(value)
            db:SetProfile(value)
            refreshAll()
        end,
    })
    innerY = LC.AnchorWidget(activeDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- New profile: text input on the left, create button to its right
    local newProfileInput = W.CreateTextInput(content, {
        label = "New Profile",
        width = NEW_PROFILE_INPUT_WIDTH,
        maxLength = 64,
    })
    newProfileInput:SetPoint("TOPLEFT", content, "TOPLEFT", LC.PADDING_SIDE, innerY)
    newProfileInput:SetPoint("TOPRIGHT", content, "TOPRIGHT", -LC.PADDING_SIDE, innerY)

    local createBtn = W.CreateButton(content, {
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

    innerY = innerY - newProfileInput:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset, activeDropdown
end

-------------------------------------------------------------------------------
-- Section: Profile Actions - copy, reset, delete
-------------------------------------------------------------------------------

local function CreateActionsSection(parent, db, yOffset, refreshAll)
    local section = W.CreateSection(parent, "Profile Actions")
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    -- Copy From dropdown
    local copyDropdown = W.CreateDropdown(content, {
        label = "Copy From",
        values = function() return GetOtherProfileValues(db) end,
        get = function() return nil end,
        set = function(value)
            db:CopyProfile(value)
            refreshAll()
        end,
    })
    innerY = LC.AnchorWidget(copyDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    -- Reset Current Profile button
    local resetBtn = W.CreateButton(content, {
        text = "Reset Current Profile",
        width = 160,
        tooltip = "Reset all settings in the current profile to their default values",
        onClick = function()
            StaticPopup_Show("DRAGONLOOT_RESET_PROFILE")
        end,
    })
    resetBtn:SetPoint("TOPLEFT", content, "TOPLEFT", LC.PADDING_SIDE, innerY)
    innerY = innerY - resetBtn:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    -- Delete Profile dropdown
    local deleteDropdown = W.CreateDropdown(content, {
        label = "Delete Profile",
        values = function() return GetOtherProfileValues(db) end,
        get = function() return nil end,
        set = function(value)
            pendingDeleteProfile = value
            pendingDeleteDb = db
            pendingDeleteRefresh = refreshAll
            StaticPopup_Show("DRAGONLOOT_DELETE_PROFILE", value)
        end,
    })
    innerY = LC.AnchorWidget(deleteDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    return yOffset, copyDropdown, deleteDropdown
end

-------------------------------------------------------------------------------
-- Build the Profiles tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local db = dlns.Addon.db
    local yOffset = LC.PADDING_TOP

    -- Forward-declare widget refs for refresh closure
    local activeDropdown, copyDropdown, deleteDropdown

    local function RefreshProfileWidgets()
        if activeDropdown then activeDropdown:Refresh() end
        if copyDropdown then copyDropdown:Refresh() end
        if deleteDropdown then deleteDropdown:Refresh() end
    end

    -- Profiles overview section
    local profilesSection = W.CreateSection(parent, "Profiles")
    local profilesContent = profilesSection.content
    local profilesY = -LC.SECTION_PADDING_TOP

    local desc = W.CreateDescription(profilesContent,
        "Profiles allow you to save different settings configurations. You can switch between"
        .. " profiles, copy settings from another profile, or reset to defaults.")
    profilesY = LC.AnchorWidget(desc, profilesContent, profilesY) - LC.SPACING_BETWEEN_WIDGETS

    profilesSection:SetContentHeight(math_abs(profilesY) + LC.SECTION_PADDING_BOTTOM)
    yOffset = LC.AnchorSection(profilesSection, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS

    -- Current Profile section
    yOffset, activeDropdown = CreateCurrentProfileSection(
        parent, db, yOffset, RefreshProfileWidgets
    )

    -- Profile Actions section
    yOffset, copyDropdown, deleteDropdown = CreateActionsSection(
        parent, db, yOffset, RefreshProfileWidgets
    )

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "profiles",
    label = "Profiles",
    order = 9,
    createFunc = CreateContent,
}
