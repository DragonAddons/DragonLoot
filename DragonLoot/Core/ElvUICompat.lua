-------------------------------------------------------------------------------
-- ElvUICompat.lua
-- Detect ElvUI loot/roll conflicts and offer to disable + reload
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

local C_AddOns = C_AddOns
local IsAddOnLoaded = IsAddOnLoaded
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs
local ReloadUI = ReloadUI
local YES, NO = YES, NO

local L = ns.L

ns.ElvUICompat = {}

-------------------------------------------------------------------------------
-- Locale keys (single source of truth: used as both L[...] lookup key and
-- fallback when no translation is registered). Must match enUS.lua verbatim.
-------------------------------------------------------------------------------

local KEY_LOOT = "ElvUI's loot window is enabled and conflicts with DragonLoot."
    .. " Disable ElvUI's loot modules and reload now?"
local KEY_ROLL = "ElvUI's group-loot roll frames are enabled and conflict with DragonLoot."
    .. " Disable ElvUI's roll frames and reload now?"
local KEY_BOTH = "ElvUI's loot window and group-loot roll frames are enabled and conflict with DragonLoot."
    .. " Disable both ElvUI modules and reload now?"

local MESSAGES = {
    ["loot+roll"] = KEY_BOTH,
    ["loot"] = KEY_LOOT,
    ["roll"] = KEY_ROLL,
}

-------------------------------------------------------------------------------
-- Private helpers
-------------------------------------------------------------------------------

local function IsElvUILoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("ElvUI")
    elseif IsAddOnLoaded then
        return IsAddOnLoaded("ElvUI")
    end
    return false
end

--- Resolve ElvUI's core engine table.
--- Returns the E table, or nil on any failure (ElvUI absent, not yet initialized,
--- or an unexpected shape). Nil means "cannot determine - skip prompting".
local function GetElvUI()
    if not IsElvUILoaded() then
        return nil
    end
    local ElvUIContainer = _G.ElvUI
    if type(ElvUIContainer) ~= "table" then
        return nil
    end
    local E = ElvUIContainer[1]
    if type(E) ~= "table" then
        return nil
    end
    if type(E.private) ~= "table" or type(E.private.general) ~= "table" then
        return nil
    end
    return E
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function ns.ElvUICompat.IsPresent()
    return GetElvUI() ~= nil
end

function ns.ElvUICompat.IsLootWindowActive()
    local E = GetElvUI()
    if not E then
        return false
    end
    return E.private.general.loot == true
end

function ns.ElvUICompat.IsGroupLootActive()
    local E = GetElvUI()
    if not E then
        return false
    end
    return E.private.general.lootRoll == true
end

--- Compute which DragonLoot features conflict with active ElvUI modules.
--- Always returns a table - never nil - so callers can index without guarding.
--- @param profile table DragonLoot AceDB profile (ns.Addon.db.profile)
--- @return table conflicts { lootWindow = bool, rollFrame = bool }
function ns.ElvUICompat.GetConflicts(profile)
    local conflicts = { lootWindow = false, rollFrame = false }
    if type(profile) ~= "table" then
        return conflicts
    end

    local lootWindowEnabled = profile.lootWindow and profile.lootWindow.enabled == true
    local rollFrameEnabled = profile.rollFrame and profile.rollFrame.enabled == true

    if lootWindowEnabled and ns.ElvUICompat.IsLootWindowActive() then
        conflicts.lootWindow = true
    end
    if rollFrameEnabled and ns.ElvUICompat.IsGroupLootActive() then
        conflicts.rollFrame = true
    end
    return conflicts
end

--- Flip ElvUI's private flags for the requested modules. AceDB persists
--- E.private to ElvPrivateDB automatically; we must NOT poke ElvPrivateDB directly.
--- @param opts table { lootWindow = bool, rollFrame = bool }
--- @return boolean changed true if any flag was flipped, false otherwise
function ns.ElvUICompat.Disable(opts)
    local E = GetElvUI()
    if not E then
        return false
    end
    if type(opts) ~= "table" then
        return false
    end

    local changed = false
    if opts.lootWindow and E.private.general.loot == true then
        E.private.general.loot = false
        changed = true
    end
    if opts.rollFrame and E.private.general.lootRoll == true then
        E.private.general.lootRoll = false
        changed = true
    end
    return changed
end

-------------------------------------------------------------------------------
-- Conflict detection and prompt
-------------------------------------------------------------------------------

local function BuildSignature(conflicts)
    if conflicts.lootWindow and conflicts.rollFrame then
        return "loot+roll"
    elseif conflicts.lootWindow then
        return "loot"
    elseif conflicts.rollFrame then
        return "roll"
    end
    return ""
end

local function MessageForSignature(signature)
    local key = MESSAGES[signature]
    if not key then
        return ""
    end
    return (L and L[key]) or key
end

local function CheckAndPrompt()
    local addon = ns.Addon
    if not addon or not addon.db or not addon.db.profile then
        if ns.DebugPrint then
            ns.DebugPrint("ElvUICompat: skipped check - addon or db not ready")
        end
        return
    end
    local profile = addon.db.profile

    -- Ensure the compat sub-table exists (defensive - FillMissingDefaults should handle it).
    if type(profile.elvuiCompat) ~= "table" then
        profile.elvuiCompat = { dismissed = false, lastConflictSignature = "" }
    end

    local conflicts = ns.ElvUICompat.GetConflicts(profile)
    local signature = BuildSignature(conflicts)

    if signature == "" then
        -- No active conflicts - clear any prior dismissal so future conflicts re-prompt.
        profile.elvuiCompat.dismissed = false
        profile.elvuiCompat.lastConflictSignature = ""
        return
    end

    if profile.elvuiCompat.dismissed and profile.elvuiCompat.lastConflictSignature == signature then
        return
    end

    local dialog = StaticPopupDialogs["DRAGONLOOT_ELVUI_CONFLICT"]
    if not dialog then
        return
    end
    dialog.text = MessageForSignature(signature)

    local data = {
        lootWindow = conflicts.lootWindow,
        rollFrame = conflicts.rollFrame,
        signature = signature,
    }
    StaticPopup_Show("DRAGONLOOT_ELVUI_CONFLICT", nil, nil, data)
end

-------------------------------------------------------------------------------
-- StaticPopup registration
-------------------------------------------------------------------------------

StaticPopupDialogs["DRAGONLOOT_ELVUI_CONFLICT"] = {
    text = "", -- set dynamically before each show
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if not data then
            return
        end
        self.accepted = true
        local changed = ns.ElvUICompat.Disable({
            lootWindow = data.lootWindow,
            rollFrame = data.rollFrame,
        })
        if changed then
            ReloadUI()
        end
    end,
    -- OnHide fires for every close path (button2 "No", ESC, frame hide);
    -- OnCancel only fires for button2, so we persist dismissal here instead.
    OnHide = function(self)
        if self.accepted then
            return
        end
        local data = self.data
        if not data then
            return
        end
        local profile = ns.Addon and ns.Addon.db and ns.Addon.db.profile
        if profile and profile.elvuiCompat then
            profile.elvuiCompat.dismissed = true
            profile.elvuiCompat.lastConflictSignature = data.signature or ""
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

-------------------------------------------------------------------------------
-- Initialize (called from Addon:OnEnable)
-------------------------------------------------------------------------------

function ns.ElvUICompat.Initialize()
    -- Defer by ~1s so ElvUI's own Initialize phase finishes populating E.private
    -- before we read the loot/lootRoll flags.
    if ns.Addon and ns.Addon.ScheduleTimer then
        ns.Addon:ScheduleTimer(CheckAndPrompt, 1)
    else
        CheckAndPrompt()
    end
end
