-------------------------------------------------------------------------------
-- RollTally_spec.lua
-- Tests for Display/RollTally.lua: the live per-roll vote tally and the
-- post-resolution result overview, both sourced from the Classic roll-item
-- indexed C_LootHistory API.
--
--   live roll  -> counts per roll type plus a "not chosen yet" count
--   resolved   -> winner name/class/roll, and the local player's losing roll
--   Retail     -> the module installs nothing at all
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

local ROLL_PASS = 0
local ROLL_NEED = 1
local ROLL_GREED = 2
local ROLL_DISENCHANT = 3

-------------------------------------------------------------------------------
-- Namespace / addon assembly
-------------------------------------------------------------------------------

local function StubRollFrame(ns, recorder)
    ns.RollFrame = {
        Initialize = function() end,
        Shutdown = function() end,
        ApplySettings = function() end,
        HideAllRolls = function() end,
        ShowRoll = function() end,
        HideRoll = function(_, onComplete)
            if onComplete then
                onComplete()
            end
        end,
        UpdateTimer = function() end,
        MarkVoted = function() end,
        UpdateTally = function(frameIndex, view)
            recorder.updates[#recorder.updates + 1] = { frameIndex = frameIndex, view = view }
        end,
    }
end

local function NewTallyNamespace(recorder, options)
    options = options or {}

    local ns = mock.CreateNamespace()
    ns.L = setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    })
    ns.IsRetail = options.isRetail or false
    ns.IsClassic = not ns.IsRetail

    StubRollFrame(ns, recorder)
    ns.RollListener = {
        Initialize = function() end,
        Shutdown = function() end,
        ResolveWinner = function() end,
    }

    local addon = {
        db = {
            profile = {
                rollFrame = {
                    enabled = true,
                    showRollTally = options.showRollTally ~= false,
                    keepOpenAfterVote = options.keepOpenAfterVote or false,
                    resultLingerDuration = 3,
                },
                rollNotifications = {},
            },
        },
        ScheduleRepeatingTimer = function()
            return {}
        end,
        CancelTimer = function() end,
        SendMessage = function() end,
    }
    ns.Addon = addon

    mock.LoadLifecycle(ns)
    mock.LoadFile(ns, "DragonLoot/Display/RollManager.lua")
    mock.LoadFile(ns, "DragonLoot/Display/RollTally.lua")
    ns.RollManager.Initialize(addon)

    return ns
end

-------------------------------------------------------------------------------
-- Loot history fixtures
-------------------------------------------------------------------------------

local function SeedHistoryItem(item, players)
    mock._lootHistory.items[1] = item
    mock._lootHistory.players[1] = players
end

local function LastView(recorder)
    local last = recorder.updates[#recorder.updates]
    return last and last.view
end

-- RollManager shows at most 4 rolls at once, so the 5th waits in the queue
-- until a visible roll is retired. Returns the rollID left waiting.
local VISIBLE_ROLL_LIMIT = 4

local function StartRollsPastVisibleLimit(ns)
    for rollID = 1, VISIBLE_ROLL_LIMIT + 1 do
        ns.RollManager.StartRoll(rollID, 30)
    end
    return VISIBLE_ROLL_LIMIT + 1
end

describe("Roll tally", function()
    local recorder

    before_each(function()
        mock.Reset()
        recorder = { updates = {} }
    end)

    ---------------------------------------------------------------------------
    -- Live counting
    ---------------------------------------------------------------------------

    describe("while the roll is live", function()
        it("counts each roll type the group has picked", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 4, isDone = false, winnerIndex = 0 }, {
                { name = "Ana", rollType = ROLL_NEED, roll = 91 },
                { name = "Bo", rollType = ROLL_NEED, roll = 12 },
                { name = "Cy", rollType = ROLL_GREED, roll = 40 },
                { name = "Di", rollType = ROLL_DISENCHANT, roll = 3 },
            })

            ns.RollTally.Refresh()

            local view = LastView(recorder)
            assert.are.equal(2, view.counts[ROLL_NEED])
            assert.are.equal(1, view.counts[ROLL_GREED])
            assert.are.equal(1, view.counts[ROLL_DISENCHANT])
            assert.are.equal(0, view.pending)
        end)

        it("counts Pass as its own visible roll type", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 2, isDone = false, winnerIndex = 0 }, {
                { name = "Ana", rollType = ROLL_PASS },
                { name = "Bo", rollType = ROLL_PASS },
            })

            ns.RollTally.Refresh()

            assert.are.equal(2, LastView(recorder).counts[ROLL_PASS])
        end)

        it("treats a nil rollType as a player who has not chosen yet", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 3, isDone = false, winnerIndex = 0 }, {
                { name = "Ana", rollType = ROLL_NEED, roll = 91 },
                { name = "Bo" },
                { name = "Cy" },
            })

            ns.RollTally.Refresh()

            local view = LastView(recorder)
            assert.are.equal(1, view.counts[ROLL_NEED])
            assert.are.equal(2, view.pending)
            assert.is_nil(view.counts[ROLL_PASS])
        end)

        it("counts a chosen roll type that has no numeric roll value yet", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 1, isDone = false, winnerIndex = 0 }, {
                { name = "Ana", rollType = ROLL_GREED },
            })

            ns.RollTally.Refresh()

            local view = LastView(recorder)
            assert.are.equal(1, view.counts[ROLL_GREED])
            assert.are.equal(0, view.pending)
        end)

        it("carries no result overview before the roll is done", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 1, isDone = false, winnerIndex = 1 }, {
                { name = "Ana", rollType = ROLL_NEED, roll = 91, isWinner = true },
            })

            ns.RollTally.Refresh()

            assert.is_nil(LastView(recorder).result)
        end)

        it("ignores history rows whose rollID is not an active roll", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 99, numPlayers = 1, isDone = false, winnerIndex = 0 }, {
                { name = "Ana", rollType = ROLL_NEED, roll = 91 },
            })

            ns.RollTally.Refresh()

            assert.are.equal(0, #recorder.updates)
        end)

        it("keeps updating a frame the player already voted on and held open", function()
            local ns = NewTallyNamespace(recorder, { keepOpenAfterVote = true })
            ns.RollManager.StartRoll(7, 30)
            ns.RollManager.MarkPendingHide(7)
            ns.RollManager.TryHideAfterVote(7, ROLL_GREED)
            SeedHistoryItem({ rollID = 7, numPlayers = 2, isDone = false, winnerIndex = 0 }, {
                { name = "Ana", rollType = ROLL_NEED, roll = 91 },
                { name = "TestPlayer", rollType = ROLL_GREED, roll = 42, isMe = true },
            })

            ns.RollTally.Refresh()

            local view = LastView(recorder)
            assert.are.equal(1, view.counts[ROLL_NEED])
            assert.are.equal(1, view.counts[ROLL_GREED])
        end)

        it("stops updating a frame that was hidden on voting", function()
            local ns = NewTallyNamespace(recorder, { keepOpenAfterVote = false })
            ns.RollManager.StartRoll(7, 30)
            ns.RollManager.MarkPendingHide(7)
            ns.RollManager.TryHideAfterVote(7, ROLL_GREED)
            SeedHistoryItem({ rollID = 7, numPlayers = 1, isDone = false, winnerIndex = 0 }, {
                { name = "Ana", rollType = ROLL_NEED, roll = 91 },
            })

            ns.RollTally.Refresh()

            assert.are.equal(0, #recorder.updates)
        end)
    end)

    ---------------------------------------------------------------------------
    -- Result overview
    ---------------------------------------------------------------------------

    describe("once the roll is done", function()
        it("reports the winner's name, class, roll type and roll", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 2, isDone = true, winnerIndex = 1 }, {
                { name = "Ana", class = "MAGE", rollType = ROLL_NEED, roll = 91, isWinner = true },
                { name = "Bo", class = "WARRIOR", rollType = ROLL_NEED, roll = 12 },
            })

            ns.RollTally.Refresh()

            local result = LastView(recorder).result
            assert.are.equal("Ana", result.winnerName)
            assert.are.equal("MAGE", result.winnerClass)
            assert.are.equal(ROLL_NEED, result.winnerRollType)
            assert.are.equal(91, result.winnerRoll)
        end)

        it("adds the local player's own roll when they lost", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 2, isDone = true, winnerIndex = 1 }, {
                { name = "Ana", class = "MAGE", rollType = ROLL_NEED, roll = 91, isWinner = true },
                { name = "TestPlayer", class = "WARRIOR", rollType = ROLL_GREED, roll = 42, isMe = true },
            })

            ns.RollTally.Refresh()

            local result = LastView(recorder).result
            assert.are.equal(ROLL_GREED, result.selfRollType)
            assert.are.equal(42, result.selfRoll)
        end)

        it("omits the local player's roll when they won", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 1, isDone = true, winnerIndex = 1 }, {
                {
                    name = "TestPlayer",
                    class = "WARRIOR",
                    rollType = ROLL_NEED,
                    roll = 91,
                    isWinner = true,
                    isMe = true,
                },
            })

            ns.RollTally.Refresh()

            local result = LastView(recorder).result
            assert.are.equal("TestPlayer", result.winnerName)
            assert.is_nil(result.selfRoll)
        end)

        it("omits the local player's roll when they passed", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 2, isDone = true, winnerIndex = 1 }, {
                { name = "Ana", class = "MAGE", rollType = ROLL_NEED, roll = 91, isWinner = true },
                { name = "TestPlayer", class = "WARRIOR", rollType = ROLL_PASS, isMe = true },
            })

            ns.RollTally.Refresh()

            assert.is_nil(LastView(recorder).result.selfRoll)
        end)

        it("degrades to no result overview when the client published no winner", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 1, isDone = true, winnerIndex = 0 }, {
                { name = "Ana", rollType = ROLL_NEED, roll = 91 },
            })

            ns.RollTally.Refresh()

            local view = LastView(recorder)
            assert.is_nil(view.result)
            assert.are.equal(1, view.counts[ROLL_NEED])
        end)
    end)

    ---------------------------------------------------------------------------
    -- Queue promotion
    ---------------------------------------------------------------------------

    describe("when a queued roll takes over a freed frame", function()
        it("fills in its tally without waiting for the next history event", function()
            local ns = NewTallyNamespace(recorder)
            local queuedRollID = StartRollsPastVisibleLimit(ns)
            SeedHistoryItem({ rollID = queuedRollID, numPlayers = 2, isDone = false, winnerIndex = 0 }, {
                { name = "Ana", rollType = ROLL_NEED, roll = 91 },
                { name = "Bo", rollType = ROLL_GREED, roll = 12 },
            })

            ns.RollManager.CancelRoll(1)

            assert.are.equal(1, #recorder.updates)
            local promoted = ns.RollManager.GetActiveRolls()[queuedRollID]
            assert.are.equal(promoted.frameIndex, recorder.updates[1].frameIndex)
            assert.are.equal(1, recorder.updates[1].view.counts[ROLL_NEED])
            assert.are.equal(1, recorder.updates[1].view.counts[ROLL_GREED])
        end)
    end)

    ---------------------------------------------------------------------------
    -- Teardown and opt-out
    ---------------------------------------------------------------------------

    describe("clearing", function()
        it("hides the tally on every visible roll when the setting is off", function()
            local ns = NewTallyNamespace(recorder, { showRollTally = false })
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 1, isDone = false, winnerIndex = 0 }, {
                { name = "Ana", rollType = ROLL_NEED, roll = 91 },
            })

            ns.RollTally.Refresh()

            assert.are.equal(1, #recorder.updates)
            assert.is_nil(recorder.updates[1].view)
        end)

        it("hides the tally on every visible roll on demand", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)

            ns.RollTally.ClearAll()

            assert.are.equal(1, #recorder.updates)
            assert.is_nil(recorder.updates[1].view)
        end)

        it("leaves nothing to clear once the roll has been retired", function()
            local ns = NewTallyNamespace(recorder)
            ns.RollManager.StartRoll(7, 30)
            ns.RollManager.CancelRoll(7)

            ns.RollTally.ClearAll()

            assert.are.equal(0, #recorder.updates)
        end)
    end)

    ---------------------------------------------------------------------------
    -- Flavor gating
    ---------------------------------------------------------------------------

    describe("on Retail", function()
        it("installs no tally entry points at all", function()
            local ns = NewTallyNamespace(recorder, { isRetail = true })

            assert.is_nil(ns.RollTally.Refresh)
            assert.is_nil(ns.RollTally.ClearAll)
        end)

        it("never renders a tally even with history data present", function()
            local ns = NewTallyNamespace(recorder, { isRetail = true })
            ns.RollManager.StartRoll(7, 30)
            SeedHistoryItem({ rollID = 7, numPlayers = 1, isDone = false, winnerIndex = 0 }, {
                { name = "Ana", rollType = ROLL_NEED, roll = 91 },
            })

            local isRefreshCallable = pcall(function()
                ns.RollTally.Refresh()
            end)

            assert.is_false(isRefreshCallable)
            assert.are.equal(0, #recorder.updates)
        end)

        it("promotes a queued roll without reaching for the absent tally module", function()
            local ns = NewTallyNamespace(recorder, { isRetail = true })
            local queuedRollID = StartRollsPastVisibleLimit(ns)

            assert.has_no.errors(function()
                ns.RollManager.CancelRoll(1)
            end)

            assert.is_not_nil(ns.RollManager.GetActiveRolls()[queuedRollID])
            assert.are.equal(0, #recorder.updates)
        end)
    end)
end)
