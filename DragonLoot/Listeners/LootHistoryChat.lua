-------------------------------------------------------------------------------
-- LootHistoryChat.lua
-- Tracks directly looted items via CHAT_MSG_LOOT parsing for loot history
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetTime = GetTime
local UnitName = UnitName
local UnitClass = UnitClass
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetItemInfo = GetItemInfo
local pairs = pairs
local LifecycleUtil = ns.LifecycleUtil

-------------------------------------------------------------------------------
-- Shared listener utilities
-------------------------------------------------------------------------------

local GetItemTexture = ns.ListenerShared.GetItemTexture

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local addon
local recentEntries = {}
local lifecycleState = LifecycleUtil.CreateState()

local DEDUP_WINDOW = 2
local DEDUP_CLEANUP_AGE = 5
local QUALITY_RETRY_DELAY = 0.5

-------------------------------------------------------------------------------
-- Pattern building (at load time)
--
-- Converts GlobalString format strings (e.g. LOOT_ITEM) into Lua patterns.
-- %s -> (.+) for player/item captures, %d -> (%d+) for quantity.
-- Match order: multi first (has quantity), then single.
-------------------------------------------------------------------------------

local LUA_MAGIC_CHARS = "().%+-*?[^$"

local function EscapeLuaMagic(str)
    local escaped = str:gsub(".", function(c)
        if LUA_MAGIC_CHARS:find(c, 1, true) then
            return "%" .. c
        end
        return c
    end)
    return escaped
end

local function BuildPattern(globalString)
    if not globalString then
        return nil
    end
    local pattern = EscapeLuaMagic(globalString)
    pattern = pattern:gsub("%%%%s", "(.+)")
    pattern = pattern:gsub("%%%%d", "(%%d+)")
    return pattern
end

-- Self-loot patterns (no player capture, just item and optional quantity)
local selfPatterns = {}
-- Other-player patterns (player capture, item, optional quantity)
local otherPatterns = {}

local function BuildAllPatterns()
    -- Self patterns: multi first, then single, then pushed variants
    if LOOT_ITEM_SELF_MULTIPLE then
        selfPatterns[#selfPatterns + 1] = { pattern = BuildPattern(LOOT_ITEM_SELF_MULTIPLE), hasQuantity = true }
    end
    if LOOT_ITEM_SELF then
        selfPatterns[#selfPatterns + 1] = { pattern = BuildPattern(LOOT_ITEM_SELF), hasQuantity = false }
    end
    if LOOT_ITEM_PUSHED_SELF_MULTIPLE then
        selfPatterns[#selfPatterns + 1] = { pattern = BuildPattern(LOOT_ITEM_PUSHED_SELF_MULTIPLE), hasQuantity = true }
    end
    if LOOT_ITEM_PUSHED_SELF then
        selfPatterns[#selfPatterns + 1] = { pattern = BuildPattern(LOOT_ITEM_PUSHED_SELF), hasQuantity = false }
    end

    -- Other-player patterns: multi first, then single, then pushed variants
    if LOOT_ITEM_MULTIPLE then
        otherPatterns[#otherPatterns + 1] = { pattern = BuildPattern(LOOT_ITEM_MULTIPLE), hasQuantity = true }
    end
    if LOOT_ITEM then
        otherPatterns[#otherPatterns + 1] = { pattern = BuildPattern(LOOT_ITEM), hasQuantity = false }
    end
    if LOOT_ITEM_PUSHED_MULTIPLE then
        otherPatterns[#otherPatterns + 1] = { pattern = BuildPattern(LOOT_ITEM_PUSHED_MULTIPLE), hasQuantity = true }
    end
    if LOOT_ITEM_PUSHED then
        otherPatterns[#otherPatterns + 1] = { pattern = BuildPattern(LOOT_ITEM_PUSHED), hasQuantity = false }
    end
end

BuildAllPatterns()

-------------------------------------------------------------------------------
-- Dedup cleanup
-------------------------------------------------------------------------------

local function CleanRecentEntries()
    local now = GetTime()
    for key, timestamp in pairs(recentEntries) do
        if now - timestamp > DEDUP_CLEANUP_AGE then
            recentEntries[key] = nil
        end
    end
end

-------------------------------------------------------------------------------
-- Item info retrieval with retry
-------------------------------------------------------------------------------

local function ScheduleQualityRetry(entry, itemLink)
    entry.qualityRetryToken = (entry.qualityRetryToken or 0) + 1
    local retryToken = entry.qualityRetryToken

    LifecycleUtil.After(lifecycleState, QUALITY_RETRY_DELAY, function()
        if entry.qualityRetryToken ~= retryToken then
            return
        end

        local _, _, quality = GetItemInfo(itemLink)
        if not quality then
            return
        end

        entry.quality = quality
        entry.qualityRetryToken = nil

        -- Refresh history display if visible
        local historyFrame = ns.HistoryFrame
        if historyFrame and historyFrame.Refresh then
            historyFrame.Refresh()
        end
    end)
end

-------------------------------------------------------------------------------
-- Add loot entry to history
-------------------------------------------------------------------------------

local function AddLootEntry(playerName, playerClass, itemLink, _)
    local db = ns.Addon.db
    if not db or not db.profile then
        return
    end

    -- Config checks
    if not db.profile.history.trackDirectLoot then
        return
    end

    local icon = GetItemTexture(itemLink)
    local _, _, quality = GetItemInfo(itemLink)

    -- Quality filter (only for direct loot, rolled items are always tracked)
    local minQuality = db.profile.history.minQuality or 2
    if quality and quality < minQuality then
        return
    end

    local entry = {
        itemLink = itemLink,
        itemTexture = icon,
        quality = quality,
        winner = playerName,
        winnerClass = playerClass,
        rollType = nil,
        roll = nil,
        timestamp = GetTime(),
        isComplete = true,
        isDirectLoot = true,
    }

    -- If quality was nil (item not cached), retry after a short delay
    if not quality then
        ScheduleQualityRetry(entry, itemLink)
    end

    if ns.HistoryFrame and ns.HistoryFrame.AddEntry then
        ns.HistoryFrame.AddEntry(entry)
    end

    -- Auto-show history if configured
    if db.profile.history.autoShow then
        if ns.HistoryFrame and ns.HistoryFrame.Show then
            ns.HistoryFrame.Show()
        end
    end
end

-------------------------------------------------------------------------------
-- Match self-loot patterns (no player name capture)
-------------------------------------------------------------------------------

local function TryMatchSelf(message)
    for _, info in ipairs(selfPatterns) do
        if info.hasQuantity then
            local itemLink, quantity = message:match(info.pattern)
            if itemLink then
                return itemLink, tonumber(quantity) or 1
            end
        else
            local itemLink = message:match(info.pattern)
            if itemLink then
                return itemLink, 1
            end
        end
    end
    return nil, nil
end

-------------------------------------------------------------------------------
-- Match other-player patterns (has player name capture)
-------------------------------------------------------------------------------

local function TryMatchOther(message)
    for _, info in ipairs(otherPatterns) do
        if info.hasQuantity then
            local player, itemLink, quantity = message:match(info.pattern)
            if player then
                return player, itemLink, tonumber(quantity) or 1
            end
        else
            local player, itemLink = message:match(info.pattern)
            if player then
                return player, itemLink, 1
            end
        end
    end
    return nil, nil, nil
end

-------------------------------------------------------------------------------
-- Process a CHAT_MSG_LOOT message
-------------------------------------------------------------------------------

local function ProcessLootMessage(message, _, guid)
    -- Try self patterns first
    local itemLink, quantity = TryMatchSelf(message)
    local playerName, playerClass

    if itemLink then
        playerName = UnitName("player")
        local _, englishClass = UnitClass("player")
        playerClass = englishClass
    else
        -- Try other-player patterns
        local otherPlayer, otherItemLink, otherQuantity = TryMatchOther(message)
        if otherPlayer then
            playerName = otherPlayer
            itemLink = otherItemLink
            quantity = otherQuantity

            -- Get class from GUID
            if type(guid) == "string" then
                local _, englishClass = GetPlayerInfoByGUID(guid)
                playerClass = englishClass
            end
        end
    end

    if not itemLink then
        return
    end

    -- Dedup check
    CleanRecentEntries()
    local dedupKey = (playerName or "") .. itemLink
    local now = GetTime()
    if recentEntries[dedupKey] and (now - recentEntries[dedupKey]) < DEDUP_WINDOW then
        return
    end
    recentEntries[dedupKey] = now

    AddLootEntry(playerName, playerClass, itemLink, quantity)
end

-------------------------------------------------------------------------------
-- Event handler
-- CHAT_MSG_LOOT args: message, playerName, languageName, channelName,
--   playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName,
--   languageID, lineID, guid (arg12)
-------------------------------------------------------------------------------

local function OnChatMsgLoot(_, message, _, _, _, _, _, _, _, _, _, _, guid)
    ProcessLootMessage(message, nil, guid)
end

-------------------------------------------------------------------------------
-- Public Interface: ns.LootHistoryChat
-------------------------------------------------------------------------------

function ns.LootHistoryChat.Initialize(addonRef)
    addon = addonRef
    LifecycleUtil.Activate(lifecycleState)
    addon:RegisterEvent("CHAT_MSG_LOOT", OnChatMsgLoot)
    ns.DebugPrint("LootHistoryChat initialized")
end

function ns.LootHistoryChat.Shutdown()
    LifecycleUtil.Invalidate(lifecycleState)

    if addon then
        addon:UnregisterEvent("CHAT_MSG_LOOT")
    end

    addon = nil
    wipe(recentEntries)
    ns.DebugPrint("LootHistoryChat shut down")
end
