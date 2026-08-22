-------------------------------------------------------------------------------
-- RollTally.lua
-- Live vote tally and post-resolution result overview for active loot rolls.
--
-- Reads the roll-item indexed C_LootHistory API, matches its rollID against
-- RollManager's active rolls, and pushes a render-ready view to RollFrame.
-- Holds no state of its own: every view is derived on demand, so retiring a
-- roll or releasing its frame is all the cleanup there is.
--
-- Retail dropped C_LootHistory.GetItem/GetPlayerInfo in 10.1.0, and its
-- replacement is keyed by encounter and loot list with no way back to a
-- rollID, so the whole feature is gated to Classic clients.
--
-- Supported versions: MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

if not ns.IsClassic then
    return
end

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local C_LootHistory = C_LootHistory

-------------------------------------------------------------------------------
-- Settings
-------------------------------------------------------------------------------

local function IsTallyEnabled()
    local db = ns.Addon and ns.Addon.db and ns.Addon.db.profile
    return (db and db.rollFrame and db.rollFrame.showRollTally) or false
end

local function IsHistoryQueryable()
    return C_LootHistory ~= nil
        and C_LootHistory.GetNumItems ~= nil
        and C_LootHistory.GetItem ~= nil
        and C_LootHistory.GetPlayerInfo ~= nil
end

-------------------------------------------------------------------------------
-- Boundary parsing: normalize C_LootHistory player rows into a scan
--
-- Scan = {
--     counts,       -- table: rollType -> number of players who chose it
--     pending,      -- number of players who have not chosen yet
--     selfRollType, -- roll type the local player chose, or nil
--     selfRoll,     -- numeric roll the local player got, or nil
--     isSelfWinner, -- boolean
-- }
--
-- A nil rollType means the player has not chosen yet (Blizzard renders "...").
-- A rollType with a nil roll means chosen but not yet rolled, which still
-- counts towards its type.
-------------------------------------------------------------------------------

local function ScanPlayers(itemIndex, numPlayers)
    local scan = { counts = {}, pending = 0, isSelfWinner = false }

    for playerIndex = 1, numPlayers do
        local name, _, rollType, roll, isWinner, isMe = C_LootHistory.GetPlayerInfo(itemIndex, playerIndex)
        if name then
            if rollType == nil then
                scan.pending = scan.pending + 1
            else
                scan.counts[rollType] = (scan.counts[rollType] or 0) + 1
            end
            if isMe then
                scan.selfRollType = rollType
                scan.selfRoll = roll
                scan.isSelfWinner = isWinner and true or false
            end
        end
    end

    return scan
end

-------------------------------------------------------------------------------
-- Result overview
--
-- Result = {
--     winnerName, winnerClass, winnerRollType, winnerRoll,
--     selfRollType, selfRoll,  -- only when the local player rolled and lost
-- }
--
-- Returns nil whenever the client has not published a winner yet, which is the
-- graceful-degradation path: the tally strip stays, the overview stays absent.
-------------------------------------------------------------------------------

local function BuildResult(itemIndex, winnerIndex, scan)
    if not winnerIndex or winnerIndex <= 0 then
        return nil
    end

    local winnerName, winnerClass, winnerRollType, winnerRoll = C_LootHistory.GetPlayerInfo(itemIndex, winnerIndex)
    if not winnerName then
        return nil
    end

    local result = {
        winnerName = winnerName,
        winnerClass = winnerClass,
        winnerRollType = winnerRollType,
        winnerRoll = winnerRoll,
    }

    if scan.selfRoll and not scan.isSelfWinner then
        result.selfRollType = scan.selfRollType
        result.selfRoll = scan.selfRoll
    end

    return result
end

-------------------------------------------------------------------------------
-- Public Interface: ns.RollTally
-------------------------------------------------------------------------------

--- Hide the tally on every roll frame that is currently on screen.
function ns.RollTally.ClearAll()
    for _, roll in pairs(ns.RollManager.GetActiveRolls()) do
        if roll.frameIndex then
            ns.RollFrame.UpdateTally(roll.frameIndex, nil)
        end
    end
end

--- Recompute the tally for every visible active roll and push it to its frame.
--- Safe to call at any point in a roll's life: it reads only C_LootHistory,
--- never the post-vote-unreliable GetLootRoll* APIs. Clears every tally instead
--- when the feature is switched off, so toggling the setting takes effect at once.
function ns.RollTally.Refresh()
    if not IsTallyEnabled() then
        ns.RollTally.ClearAll()
        return
    end
    if not IsHistoryQueryable() then
        return
    end

    local activeRolls = ns.RollManager.GetActiveRolls()
    local numItems = C_LootHistory.GetNumItems() or 0

    for itemIndex = 1, numItems do
        local rollID, _, numPlayers, isDone, winnerIndex = C_LootHistory.GetItem(itemIndex)
        local roll = rollID and activeRolls[rollID]
        if roll and roll.frameIndex and numPlayers and numPlayers > 0 then
            local scan = ScanPlayers(itemIndex, numPlayers)
            ns.RollFrame.UpdateTally(roll.frameIndex, {
                counts = scan.counts,
                pending = scan.pending,
                result = isDone and BuildResult(itemIndex, winnerIndex, scan) or nil,
            })
        end
    end
end
