-------------------------------------------------------------------------------
-- ProfilesTab.lua
-- Profile management tab: switch, create, copy, reset, delete profiles
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local table_sort = table.sort
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs
local YES = YES
local NO = NO

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------

local L = ns.L

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dlns

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local NEW_PROFILE_INPUT_WIDTH = 250

-------------------------------------------------------------------------------
-- Static popup dialogs (defined at file scope)
-------------------------------------------------------------------------------

StaticPopupDialogs["DRAGONLOOT_RESET_PROFILE"] = {
    text = L["Are you sure you want to reset the current profile to defaults?"],
    button1 = YES,
    button2 = NO,
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
    text = L["Are you sure you want to delete profile \"%s\"?"],
    button1 = YES,
    button2 = NO,
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
-- Section: Current Profile
-------------------------------------------------------------------------------

local function CreateCurrentProfileSection(parent, db, refreshAll)
    local section = LDF.CreateSection(parent, L["Current Profile"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateDescription(section.content,
        L["Profiles allow you to save different settings configurations. You can switch between"
        .. " profiles, copy settings from another profile, or reset to defaults."]))

    local activeDropdown = LDF.CreateDropdown(section.content, {
        label = L["Active Profile"],
        values = function() return GetProfileValues(db) end,
        get = function() return db:GetCurrentProfile() end,
        set = function(value)
            db:SetProfile(value)
            refreshAll()
        end,
    })
    stack:AddChild(activeDropdown)

    local newProfileInput = LDF.CreateTextInput(section.content, {
        label = L["New Profile"],
        width = NEW_PROFILE_INPUT_WIDTH,
        maxLength = 64,
        get = function() return "" end,
    })
    stack:AddChild(newProfileInput)

    stack:AddChild(LDF.CreateButton(section.content, {
        text = L["Create"],
        tooltip = L["Create a new profile with the entered name and switch to it"],
        onClick = function()
            local name = newProfileInput:GetValue()
            if not name or name == "" then return end
            db:SetProfile(name)
            newProfileInput:SetValue("")
            refreshAll()
        end,
    }))

    return section, activeDropdown
end

-------------------------------------------------------------------------------
-- Section: Profile Actions
-------------------------------------------------------------------------------

local function CreateActionsSection(parent, db, refreshAll)
    local section = LDF.CreateSection(parent, L["Profile Actions"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    local copyDropdown = LDF.CreateDropdown(section.content, {
        label = L["Copy From"],
        values = function() return GetOtherProfileValues(db) end,
        get = function() return "" end,
        set = function(value)
            db:CopyProfile(value)
            refreshAll()
        end,
    })
    stack:AddChild(copyDropdown)

    stack:AddChild(LDF.CreateButton(section.content, {
        text = L["Reset Current Profile"],
        tooltip = L["Reset all settings in the current profile to their default values"],
        onClick = function()
            StaticPopup_Show("DRAGONLOOT_RESET_PROFILE")
        end,
    }))

    local deleteDropdown = LDF.CreateDropdown(section.content, {
        label = L["Delete Profile"],
        values = function() return GetOtherProfileValues(db) end,
        get = function() return "" end,
        set = function(value)
            StaticPopupDialogs["DRAGONLOOT_DELETE_PROFILE"].OnAccept = function()
                db:DeleteProfile(value)
                refreshAll()
            end
            StaticPopup_Show("DRAGONLOOT_DELETE_PROFILE", value)
        end,
    })
    stack:AddChild(deleteDropdown)

    return section, copyDropdown, deleteDropdown
end

-------------------------------------------------------------------------------
-- Build the Profiles tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dlns = ns.dlns
    local db = dlns.Addon.db
    local mainStack = LDF.CreateStackLayout(parent, "vertical")

    -- Forward-declare widget refs for refresh closure
    local activeDropdown, copyDropdown, deleteDropdown

    local function RefreshProfileWidgets()
        if activeDropdown then activeDropdown:Refresh() end
        if copyDropdown then copyDropdown:Refresh() end
        if deleteDropdown then deleteDropdown:Refresh() end
    end

    -- Current Profile section
    local currentSection
    currentSection, activeDropdown = CreateCurrentProfileSection(
        parent, db, RefreshProfileWidgets
    )
    mainStack:AddChild(currentSection)

    -- Profile Actions section
    local actionsSection
    actionsSection, copyDropdown, deleteDropdown = CreateActionsSection(
        parent, db, RefreshProfileWidgets
    )
    mainStack:AddChild(actionsSection)

    -- Register AceDB profile callbacks
    db.RegisterCallback(db, "OnProfileChanged", RefreshProfileWidgets)
    db.RegisterCallback(db, "OnProfileCopied", RefreshProfileWidgets)
    db.RegisterCallback(db, "OnProfileReset", RefreshProfileWidgets)
    db.RegisterCallback(db, "OnNewProfile", RefreshProfileWidgets)
    db.RegisterCallback(db, "OnProfileDeleted", RefreshProfileWidgets)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "profiles",
    label = L["Profiles"],
    order = 8,
    createFunc = CreateContent,
}
