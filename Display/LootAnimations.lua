-------------------------------------------------------------------------------
-- LootAnimations.lua
-- Open/close animations for the loot frame using LibAnimate
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- LibAnimate reference
-------------------------------------------------------------------------------

local lib = LibStub("LibAnimate")

-------------------------------------------------------------------------------
-- Public Interface: ns.LootAnimations
-------------------------------------------------------------------------------

function ns.LootAnimations.PlayOpen(frame)
    local db = ns.Addon.db.profile

    if not db.animation.enabled then
        frame:SetAlpha(1)
        frame:SetScale(1)
        frame:Show()
        return
    end

    local duration = db.animation.openDuration or 0.3

    frame:SetAlpha(0)
    frame:Show()

    local animName = db.animation.lootOpenAnim or "fadeIn"
    local ok = pcall(lib.Animate, lib, frame, animName, {
        duration = duration,
        distance = 50,
        onFinished = function()
            local scale = ns.Addon.db and ns.Addon.db.profile.lootWindow.scale or 1.0
            frame:SetScale(scale)
        end,
    })
    if not ok then
        frame:SetAlpha(1)
        frame:SetScale(ns.Addon.db and ns.Addon.db.profile.lootWindow.scale or 1.0)
    end
end

function ns.LootAnimations.PlayClose(frame, onFinished)
    local db = ns.Addon.db.profile

    if not db.animation.enabled then
        if onFinished then onFinished() end
        return
    end

    local duration = db.animation.closeDuration or 0.5

    ns.LootAnimations.StopAll(frame)

    local animName = db.animation.lootCloseAnim or "fadeOut"
    local ok = pcall(lib.Animate, lib, frame, animName, {
        duration = duration,
        distance = 50,
        onFinished = function()
            local scale = ns.Addon.db and ns.Addon.db.profile.lootWindow.scale or 1.0
            frame:SetAlpha(1)
            frame:SetScale(scale)
            frame:Hide()
            if onFinished then onFinished() end
        end,
    })
    if not ok then
        frame:SetAlpha(1)
        frame:SetScale(ns.Addon.db and ns.Addon.db.profile.lootWindow.scale or 1.0)
        frame:Hide()
        if onFinished then onFinished() end
    end
end

function ns.LootAnimations.StopAll(frame)
    lib:ClearQueue(frame)
end
