-------------------------------------------------------------------------------
-- RollManager.lua
-- Manages active loot rolls, overflow queue, and timer updates
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetTime = GetTime
local GetLootRollItemInfo = GetLootRollItemInfo
local GetLootRollItemLink = GetLootRollItemLink
local UnitName = UnitName
local UnitClass = UnitClass
local C_Timer = C_Timer
local max = math.max

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local MAX_VISIBLE_ROLLS = 4
local TIMER_INTERVAL = 0.05

-- Canonical roll type enum (shared with listeners)
local ROLL_TYPE_PASS = 0
local ROLL_TYPE_NEED = 1
local ROLL_TYPE_GREED = 2
local ROLL_TYPE_DISENCHANT = 3
local ROLL_TYPE_TRANSMOG = 4

-- Human-readable roll type names for toast display
local ROLL_TYPE_NAMES = {
    [ROLL_TYPE_PASS] = "Pass",
    [ROLL_TYPE_NEED] = "Need",
    [ROLL_TYPE_GREED] = "Greed",
    [ROLL_TYPE_DISENCHANT] = "Disenchant",
    [ROLL_TYPE_TRANSMOG] = "Transmog",
}

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local addon
local activeRolls = {}      -- rollID -> { rollID, rollTime, startTime, frameIndex }
local waitingRolls = {}     -- ordered list of { rollID, rollTime }
local usedFrames = {}       -- frameIndex -> true/false
local notifiedRolls = {}    -- rollID -> true (prevent duplicate winner notifications)
local activeRollCount = 0
local timerHandle

-------------------------------------------------------------------------------
-- StaticPopup for roll confirmations (shared by Retail and Classic listeners)
-------------------------------------------------------------------------------

StaticPopupDialogs["DRAGONLOOT_CONFIRM_LOOT_ROLL"] = {
    text = LOOT_NO_DROP,
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        if not self.data then return end
        ConfirmLootRoll(self.data.rollID, self.data.rollType)
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

-------------------------------------------------------------------------------
-- Frame index management
-------------------------------------------------------------------------------

local function AcquireFrameIndex()
    for i = 1, MAX_VISIBLE_ROLLS do
        if not usedFrames[i] then
            usedFrames[i] = true
            return i
        end
    end
    return nil
end

local function ReleaseFrameIndex(frameIndex)
    usedFrames[frameIndex] = nil
end

-------------------------------------------------------------------------------
-- Timer management
-------------------------------------------------------------------------------

local function StopTimer()
    if timerHandle and addon then
        addon:CancelTimer(timerHandle)
        timerHandle = nil
    end
end

local function OnTimerTick()
    local now = GetTime()
    for _rollID, roll in pairs(activeRolls) do
        local elapsed = now - roll.startTime
        local timeLeft = max(0, roll.rollTime - elapsed)
        ns.RollFrame.UpdateTimer(roll.frameIndex, timeLeft, roll.rollTime)
        -- Timer expired - Blizzard will send CANCEL_LOOT_ROLL, don't remove here
        if timeLeft <= 0 then -- luacheck: ignore 542
            -- Wait for the event
        end
    end
end

local function StartTimer()
    if timerHandle then return end
    if not addon then return end
    timerHandle = addon:ScheduleRepeatingTimer(OnTimerTick, TIMER_INTERVAL)
end

-------------------------------------------------------------------------------
-- Waiting queue helpers
-------------------------------------------------------------------------------

local function IsInWaitingQueue(rollID)
    for _, entry in ipairs(waitingRolls) do
        if entry.rollID == rollID then return true end
    end
    return false
end

local function RemoveFromWaitingQueue(rollID)
    for i, entry in ipairs(waitingRolls) do
        if entry.rollID == rollID then
            table.remove(waitingRolls, i)
            return true
        end
    end
    return false
end

-------------------------------------------------------------------------------
-- Queue promotion
-------------------------------------------------------------------------------

local function PromoteFromQueue()
    if #waitingRolls == 0 then return end
    if activeRollCount >= MAX_VISIBLE_ROLLS then return end

    local entry = table.remove(waitingRolls, 1)
    if not entry then return end

    local frameIndex = AcquireFrameIndex()
    if not frameIndex then return end

    activeRolls[entry.rollID] = {
        rollID = entry.rollID,
        rollTime = entry.rollTime,
        startTime = GetTime(),
        frameIndex = frameIndex,
        itemTexture = entry.itemTexture,
        itemName = entry.itemName,
        itemCount = entry.itemCount,
        itemQuality = entry.itemQuality,
        itemLink = entry.itemLink,
    }
    activeRollCount = activeRollCount + 1

    ns.RollFrame.ShowRoll(frameIndex, entry.rollID)
    StartTimer()
end

-------------------------------------------------------------------------------
-- Start timer only when active rolls exist
-------------------------------------------------------------------------------

local function StartTimerIfNeeded()
    if activeRollCount > 0 then
        StartTimer()
    end
end

-------------------------------------------------------------------------------
-- DragonToast integration - notify when a player wins a roll
-------------------------------------------------------------------------------

local function SendRollWonNotification(rollID, winnerName, _winnerClass, rollType, rollValue)
    if notifiedRolls[rollID] then return end
    notifiedRolls[rollID] = true

    local roll = activeRolls[rollID]
    if not roll or not roll.itemName then return end

    local db = ns.Addon.db.profile
    if not db.rollNotifications.showRollWon then return end

    local playerName = UnitName("player")
    local isSelf = (winnerName == playerName)

    -- Check config: skip group wins if not enabled
    if not isSelf and not db.rollNotifications.showGroupWins then return end

    local rollTypeName = ROLL_TYPE_NAMES[rollType] or "Unknown"

    -- Fire generic DragonToast message (fire-and-forget, no detection needed)
    ns.Addon:SendMessage("DRAGONTOAST_QUEUE_TOAST", {
        itemLink = roll.itemLink,
        itemName = roll.itemName,
        itemQuality = roll.itemQuality,
        itemIcon = roll.itemTexture,
        itemID = roll.itemLink and tonumber(roll.itemLink:match("item:(%d+)")),
        quantity = roll.itemCount or 1,
        isRollWin = true,
        isSelf = isSelf,
        looter = winnerName,
        -- Roll details for display
        itemType = rollTypeName .. (rollValue and (" (" .. rollValue .. ")") or ""),
        timestamp = GetTime(),
    })
    ns.DebugPrint(
        "Sent DRAGONTOAST_QUEUE_TOAST (roll won) for " .. (roll.itemName or "unknown")
        .. " won by " .. (winnerName or "unknown")
    )
end

-------------------------------------------------------------------------------
-- Public Interface: ns.RollManager
-------------------------------------------------------------------------------

function ns.RollManager.Initialize(addonRef)
    addon = addonRef or ns.Addon

    local db = addon.db and addon.db.profile
    if not db or not db.rollFrame or not db.rollFrame.enabled then return end

    ns.RollFrame.Initialize()
    ns.RollListener.Initialize(addon)
    ns.DebugPrint("RollManager initialized")
end

function ns.RollManager.Shutdown()
    StopTimer()
    ns.RollManager.CancelAllRolls()
    ns.RollFrame.Shutdown()
    ns.RollListener.Shutdown()
    addon = nil
    ns.DebugPrint("RollManager shut down")
end

function ns.RollManager.StartRoll(rollID, rollTime)
    -- Guard against duplicate events
    if activeRolls[rollID] or IsInWaitingQueue(rollID) then return end

    -- Cache item data now while it is still available
    local texture, name, count, quality = GetLootRollItemInfo(rollID)
    local fullItemLink = GetLootRollItemLink(rollID)

    if activeRollCount < MAX_VISIBLE_ROLLS then
        local frameIndex = AcquireFrameIndex()
        if not frameIndex then return end

        activeRolls[rollID] = {
            rollID = rollID,
            rollTime = rollTime,
            startTime = GetTime(),
            frameIndex = frameIndex,
            itemTexture = texture,
            itemName = name,
            itemCount = count,
            itemQuality = quality,
            itemLink = fullItemLink,
        }
        activeRollCount = activeRollCount + 1

        ns.RollFrame.ShowRoll(frameIndex, rollID)
        StartTimer()
    else
        waitingRolls[#waitingRolls + 1] = {
            rollID = rollID,
            rollTime = rollTime,
            itemTexture = texture,
            itemName = name,
            itemCount = count,
            itemQuality = quality,
            itemLink = fullItemLink,
        }
    end
end

function ns.RollManager.RecoverRoll(rollID, totalDuration, timeLeft)
    if activeRolls[rollID] or IsInWaitingQueue(rollID) then return end

    -- Cache item data now while it is still available
    local texture, name, count, quality = GetLootRollItemInfo(rollID)
    local fullItemLink = GetLootRollItemLink(rollID)

    local frameIndex = AcquireFrameIndex()
    if frameIndex then
        local now = GetTime()
        activeRolls[rollID] = {
            rollID = rollID,
            rollTime = totalDuration,
            startTime = now - (totalDuration - timeLeft),
            frameIndex = frameIndex,
            itemTexture = texture,
            itemName = name,
            itemCount = count,
            itemQuality = quality,
            itemLink = fullItemLink,
        }
        activeRollCount = activeRollCount + 1
        ns.RollFrame.ShowRoll(frameIndex, rollID)
        StartTimerIfNeeded()
    else
        waitingRolls[#waitingRolls + 1] = {
            rollID = rollID,
            rollTime = totalDuration,
            itemTexture = texture,
            itemName = name,
            itemCount = count,
            itemQuality = quality,
            itemLink = fullItemLink,
        }
    end
end

function ns.RollManager.CancelRoll(rollID)
    local roll = activeRolls[rollID]
    if roll then
        local frameIndex = roll.frameIndex
        activeRolls[rollID] = nil
        notifiedRolls[rollID] = nil
        activeRollCount = activeRollCount - 1
        if activeRollCount <= 0 then
            activeRollCount = 0
            StopTimer()
        end
        -- Defer frame release and queue promotion until hide animation completes
        ns.RollFrame.HideRoll(frameIndex, function()
            ReleaseFrameIndex(frameIndex)
            PromoteFromQueue()
        end)
        return
    end

    -- Check waiting queue
    RemoveFromWaitingQueue(rollID)
end

function ns.RollManager.CancelAllRolls()
    for rollID, roll in pairs(activeRolls) do
        activeRolls[rollID] = nil
        ReleaseFrameIndex(roll.frameIndex)
    end
    activeRollCount = 0
    wipe(waitingRolls)
    wipe(notifiedRolls)
    StopTimer()
    ns.RollFrame.HideAllRolls()
end

function ns.RollManager.OnRollComplete(rollID)
    if not rollID then return end
    local roll = activeRolls[rollID]
    if roll then roll.completing = true end

    -- Ask the version-specific listener to resolve the winner
    if ns.RollListener and ns.RollListener.ResolveWinner then
        ns.RollListener.ResolveWinner(rollID)
    end

    -- Delay cancel to keep activeRolls data available for async winner resolution
    C_Timer.After(0.5, function()
        ns.RollManager.CancelRoll(rollID)
    end)
end

function ns.RollManager.ApplySettings()
    ns.RollFrame.ApplySettings()
end

function ns.RollManager.GetActiveRollCount()
    return activeRollCount
end

function ns.RollManager.GetActiveRolls()
    return activeRolls
end

function ns.RollManager.NotifyRollWinner(rollID, winnerName, winnerClass, rollType, rollValue)
    SendRollWonNotification(rollID, winnerName, winnerClass, rollType, rollValue)
end

function ns.RollManager.IsNotified(rollID)
    return notifiedRolls[rollID] or false
end

function ns.RollManager.OnLootItemRollWon(itemLink, rollType, rollValue)
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    for rollID, roll in pairs(activeRolls) do
        if roll.itemLink == itemLink and not notifiedRolls[rollID] then
            SendRollWonNotification(rollID, playerName, playerClass, rollType, rollValue)
            return
        end
    end
end
