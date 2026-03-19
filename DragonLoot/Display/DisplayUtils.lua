-------------------------------------------------------------------------------
-- DisplayUtils.lua
-- Shared display utilities for backdrop, font, and quality color helpers
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS

local LSM = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"

-------------------------------------------------------------------------------
-- Module table
-------------------------------------------------------------------------------

local DisplayUtils = {}
ns.DisplayUtils = DisplayUtils

DisplayUtils.WHITE8x8 = WHITE8x8

-------------------------------------------------------------------------------
-- GetQualityColor(quality) - returns r, g, b for an item quality
-------------------------------------------------------------------------------

function DisplayUtils.GetQualityColor(quality)
    if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        local qc = ITEM_QUALITY_COLORS[quality]
        return qc.r, qc.g, qc.b
    end
    if quality and ns.QUALITY_COLORS and ns.QUALITY_COLORS[quality] then
        local qc = ns.QUALITY_COLORS[quality]
        return qc.r, qc.g, qc.b
    end
    return 1, 1, 1
end

-------------------------------------------------------------------------------
-- GetFont(db) - returns fontPath, fontSize, fontOutline
-------------------------------------------------------------------------------

function DisplayUtils.GetFont(db)
    local appearance = db.profile.appearance
    local fontPath = LSM:Fetch("font", appearance.font) or "Fonts\\FRIZQT__.TTF"
    return fontPath, appearance.fontSize, appearance.fontOutline
end

-------------------------------------------------------------------------------
-- ApplyFontShadow(fontString, db) - apply or remove text shadow
-------------------------------------------------------------------------------

function DisplayUtils.ApplyFontShadow(fontString, db)
    if not fontString or not fontString.SetShadowOffset then return end
    local appearance = db and db.profile and db.profile.appearance
    if not appearance then return end
    if appearance.fontShadow then
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 1)
    else
        fontString:SetShadowOffset(0, 0)
    end
end

-------------------------------------------------------------------------------
-- GetBackdropSettings(db) - returns a backdrop table
-------------------------------------------------------------------------------

function DisplayUtils.GetBackdropSettings(db)
    local appearance = db.profile.appearance
    local bgTexture = LSM:Fetch("background", appearance.backgroundTexture) or WHITE8x8
    local settings = { bgFile = bgTexture }
    if (appearance.borderSize or 1) > 0 then
        local edgeFile = LSM:Fetch("border", appearance.borderTexture)
        if edgeFile then
            settings.edgeFile = edgeFile
            settings.edgeSize = appearance.borderSize
        end
    end
    return settings
end

-------------------------------------------------------------------------------
-- ApplyBackdrop(frame, db) - applies backdrop, background color, border color
-------------------------------------------------------------------------------

function DisplayUtils.ApplyBackdrop(frame, db)
    local appearance = db.profile.appearance
    if not appearance then return end

    frame:SetBackdrop(DisplayUtils.GetBackdropSettings(db))

    local bg = appearance.backgroundColor
    if bg then
        frame:SetBackdropColor(
            bg.r or 0.05, bg.g or 0.05, bg.b or 0.05,
            appearance.backgroundAlpha or 0.9)
    else
        frame:SetBackdropColor(0.05, 0.05, 0.05, appearance.backgroundAlpha or 0.9)
    end

    local border = appearance.borderColor
    if border then
        frame:SetBackdropBorderColor(border.r or 0.3, border.g or 0.3, border.b or 0.3, 0.8)
    else
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end
end

-------------------------------------------------------------------------------
-- CaptureVisualState / RestoreVisualState - shared by animation modules
-------------------------------------------------------------------------------

function DisplayUtils.CaptureVisualState(frame)
    local alpha = frame:GetAlpha()
    local scale = frame:GetScale()
    local point, relativeTo, relativePoint, x, y = frame:GetPoint()
    return alpha, scale, point, relativeTo, relativePoint, x, y
end

function DisplayUtils.RestoreVisualState(frame, alpha, scale, point, relativeTo, relativePoint, x, y)
    frame:SetAlpha(alpha)
    frame:SetScale(scale)
    if point then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x, y)
    end
end
