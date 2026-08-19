-------------------------------------------------------------------------------
-- RollHoldOpen_spec.lua
-- Tests for the "keep roll frame open after voting" state machine in
-- Display/RollManager.lua:
--   vote            -> frame hidden (default) or held open (opt-in)
--   roll resolution -> held frame retired after the result linger
--   timer expiry    -> backstop that retires a held frame with no resolution
--   pool pressure   -> a held frame is evicted rather than queueing a new roll
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

local ROLL_NEED = 1
local ROLL_GREED = 2
local MAX_VISIBLE_ROLLS = 4

-------------------------------------------------------------------------------
-- Recording stand-ins for the frame layer and the version-specific listener
-------------------------------------------------------------------------------

local function StubRollFrame(ns, recorder)
    ns.RollFrame = {
        Initialize = function() end,
        Shutdown = function() end,
        ApplySettings = function() end,
        HideAllRolls = function() end,
        ShowRoll = function(frameIndex, rollID)
            recorder.shown[#recorder.shown + 1] = { frameIndex = frameIndex, rollID = rollID }
        end,
        HideRoll = function(frameIndex, onComplete)
            recorder.hidden[#recorder.hidden + 1] = frameIndex
            if onComplete then
                onComplete()
            end
        end,
        UpdateTimer = function(frameIndex, timeLeft)
            recorder.lastTimer = { frameIndex = frameIndex, timeLeft = timeLeft }
        end,
        MarkVoted = function(frameIndex, rollType)
            recorder.voted[#recorder.voted + 1] = { frameIndex = frameIndex, rollType = rollType }
        end,
    }
end

local function StubRollListener(ns)
    ns.RollListener = {
        Initialize = function() end,
        Shutdown = function() end,
        ResolveWinner = function() end,
    }
end

-------------------------------------------------------------------------------
-- Namespace / addon assembly
-------------------------------------------------------------------------------

local function NewRollNamespace(recorder, rollFrameSettings)
    local ns = mock.CreateNamespace()
    ns.L = setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    })

    StubRollFrame(ns, recorder)
    StubRollListener(ns)

    local settings = { enabled = true, keepOpenAfterVote = false, resultLingerDuration = 3 }
    for key, value in pairs(rollFrameSettings or {}) do
        settings[key] = value
    end

    local addon = {
        db = {
            profile = {
                rollFrame = settings,
                rollNotifications = {},
            },
        },
        ScheduleRepeatingTimer = function(_, callback)
            recorder.tick = callback
            return {}
        end,
        CancelTimer = function()
            recorder.tick = nil
        end,
        SendMessage = function() end,
    }
    ns.Addon = addon

    mock.LoadLifecycle(ns)
    mock.LoadFile(ns, "DragonLoot/Display/RollManager.lua")
    ns.RollManager.Initialize(addon)

    return ns
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function Vote(ns, rollID, rollType)
    ns.RollManager.MarkPendingHide(rollID)
    ns.RollManager.TryHideAfterVote(rollID, rollType)
end

describe("Roll frame hold-open after voting", function()
    local recorder

    before_each(function()
        mock.Reset()
        recorder = { shown = {}, hidden = {}, voted = {} }
    end)

    ---------------------------------------------------------------------------
    -- Default behaviour (opt-in setting off)
    ---------------------------------------------------------------------------

    describe("with keepOpenAfterVote disabled", function()
        it("hides the frame as soon as the player votes", function()
            local ns = NewRollNamespace(recorder)
            ns.RollManager.StartRoll(1, 30)

            Vote(ns, 1, ROLL_NEED)

            assert.are.equal(1, #recorder.hidden)
            assert.are.equal(0, #recorder.voted)
            assert.are.equal(0, ns.RollManager.GetActiveRollCount())
        end)

        it("keeps the roll record alive so the winner can still be resolved", function()
            local ns = NewRollNamespace(recorder)
            ns.RollManager.StartRoll(1, 30)

            Vote(ns, 1, ROLL_NEED)

            local roll = ns.RollManager.GetActiveRolls()[1]
            assert.is_true(roll.votedAndHidden)
            assert.is_nil(roll.frameIndex)
        end)
    end)

    ---------------------------------------------------------------------------
    -- Hold-open behaviour (opt-in setting on)
    ---------------------------------------------------------------------------

    describe("with keepOpenAfterVote enabled", function()
        it("leaves the frame on screen and marks the chosen roll type", function()
            local ns = NewRollNamespace(recorder, { keepOpenAfterVote = true })
            ns.RollManager.StartRoll(1, 30)

            Vote(ns, 1, ROLL_GREED)

            assert.are.equal(0, #recorder.hidden)
            assert.are.equal(1, #recorder.voted)
            assert.are.equal(ROLL_GREED, recorder.voted[1].rollType)
            assert.are.equal(1, ns.RollManager.GetActiveRollCount())
        end)

        it("records the vote on the roll so the result overview can use it", function()
            local ns = NewRollNamespace(recorder, { keepOpenAfterVote = true })
            ns.RollManager.StartRoll(1, 30)

            Vote(ns, 1, ROLL_GREED)

            local roll = ns.RollManager.GetActiveRolls()[1]
            assert.is_true(roll.heldAfterVote)
            assert.are.equal(ROLL_GREED, roll.votedRollType)
            assert.are.equal(1, roll.frameIndex)
        end)

        it("keeps counting the timer down from cached roll data after the vote", function()
            local ns = NewRollNamespace(recorder, { keepOpenAfterVote = true })
            ns.RollManager.StartRoll(1, 30)
            Vote(ns, 1, ROLL_GREED)

            mock.AdvanceTime(10)
            recorder.tick()

            assert.are.equal(1, recorder.lastTimer.frameIndex)
            assert.are.equal(20, recorder.lastTimer.timeLeft)
        end)

        it("retires the held frame when the roll resolves", function()
            local ns = NewRollNamespace(recorder, { keepOpenAfterVote = true })
            ns.RollManager.StartRoll(1, 30)
            Vote(ns, 1, ROLL_GREED)

            -- CANCEL_LOOT_ROLL / LOOT_ROLLS_COMPLETE both land here with a rollID
            ns.RollManager.CancelRoll(1)

            assert.are.equal(1, #recorder.hidden)
            assert.is_nil(ns.RollManager.GetActiveRolls()[1])
            assert.are.equal(0, ns.RollManager.GetActiveRollCount())
        end)

        it("retires the held frame on timer expiry when no resolution arrives", function()
            local ns = NewRollNamespace(recorder, { keepOpenAfterVote = true })
            ns.RollManager.StartRoll(1, 30)
            Vote(ns, 1, ROLL_GREED)

            mock.AdvanceTime(31)
            recorder.tick()

            assert.are.equal(1, #recorder.hidden)
            assert.is_nil(ns.RollManager.GetActiveRolls()[1])
        end)

        it("treats a resolution arriving after the frame was already retired as a no-op", function()
            local ns = NewRollNamespace(recorder, { keepOpenAfterVote = true })
            ns.RollManager.StartRoll(1, 30)
            Vote(ns, 1, ROLL_GREED)

            -- wow_mock's C_Timer.After is synchronous, so the expiry backstop
            -- retires the roll inside this tick. The releaseScheduled guard is
            -- therefore NOT exercised here; only the post-retirement CancelRoll is.
            mock.AdvanceTime(31)
            recorder.tick()
            ns.RollManager.CancelRoll(1)

            assert.are.equal(1, #recorder.hidden)
        end)

        it("releases the pool slot of a held frame when all rolls are cancelled", function()
            local ns = NewRollNamespace(recorder, { keepOpenAfterVote = true })
            ns.RollManager.StartRoll(1, 30)
            Vote(ns, 1, ROLL_GREED)

            ns.RollManager.CancelAllRolls()

            assert.are.equal(0, ns.RollManager.GetActiveRollCount())
            assert.is_nil(ns.RollManager.GetActiveRolls()[1])

            ns.RollManager.StartRoll(2, 30)
            assert.is_not_nil(ns.RollManager.GetActiveRolls()[2].frameIndex)
        end)
    end)

    ---------------------------------------------------------------------------
    -- Frame pool pressure
    ---------------------------------------------------------------------------

    describe("frame pool under hold-open pressure", function()
        it("evicts the oldest held frame so a new roll is not stuck in the queue", function()
            local ns = NewRollNamespace(recorder, { keepOpenAfterVote = true })

            for rollID = 1, MAX_VISIBLE_ROLLS do
                mock.AdvanceTime(1)
                ns.RollManager.StartRoll(rollID, 30)
                Vote(ns, rollID, ROLL_GREED)
            end
            assert.are.equal(MAX_VISIBLE_ROLLS, ns.RollManager.GetActiveRollCount())

            ns.RollManager.StartRoll(99, 30)

            local evicted = ns.RollManager.GetActiveRolls()[1]
            assert.is_true(evicted.votedAndHidden)
            assert.is_nil(evicted.frameIndex)

            local newRoll = ns.RollManager.GetActiveRolls()[99]
            assert.is_not_nil(newRoll)
            assert.is_not_nil(newRoll.frameIndex)
            assert.are.equal(MAX_VISIBLE_ROLLS, ns.RollManager.GetActiveRollCount())
        end)

        it("does not evict a frame the player can still vote on", function()
            local ns = NewRollNamespace(recorder, { keepOpenAfterVote = true })

            for rollID = 1, MAX_VISIBLE_ROLLS do
                ns.RollManager.StartRoll(rollID, 30)
            end

            ns.RollManager.StartRoll(99, 30)

            assert.are.equal(0, #recorder.hidden)
            assert.is_nil(ns.RollManager.GetActiveRolls()[99])
        end)
    end)

    ---------------------------------------------------------------------------
    -- Composition with the auto-confirm setting
    ---------------------------------------------------------------------------

    describe("with autoConfirmRolls and keepOpenAfterVote both enabled", function()
        it("auto-confirms the roll and still holds the frame open", function()
            local ns = NewRollNamespace(recorder, { keepOpenAfterVote = true, autoConfirmRolls = true })
            mock.LoadFile(ns, "DragonLoot/Listeners/ListenerShared.lua")

            ns.RollManager.StartRoll(1, 30)
            ns.RollManager.MarkPendingHide(1)
            ns.ListenerShared.OnConfirmRoll(1, ROLL_NEED)
            ns.RollManager.TryHideAfterVote(1, ROLL_NEED)

            assert.are.equal(0, #recorder.hidden)
            assert.are.equal(1, #recorder.voted)
            assert.is_true(ns.RollManager.GetActiveRolls()[1].heldAfterVote)
        end)
    end)
end)
