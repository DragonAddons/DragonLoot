-------------------------------------------------------------------------------
-- RollSelectionConfirmation_spec.lua
-- Tests for optional confirmation before DragonLoot submits Greed or Pass.
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

local ROLL_PASS = 0
local ROLL_NEED = 1
local ROLL_GREED = 2
local ROLL_DISENCHANT = 3

local function NewRollNamespace(recorder, settings)
    local ns = mock.CreateNamespace()
    ns.L = setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    })
    ns.RollFrame = {
        Initialize = function() end,
        Shutdown = function() end,
        ApplySettings = function() end,
        HideAllRolls = function() end,
        ShowRoll = function() end,
        HideRoll = function(frameIndex, onComplete)
            recorder.hidden[#recorder.hidden + 1] = frameIndex
            if onComplete then
                onComplete()
            end
        end,
        MarkVoted = function(frameIndex, rollType)
            recorder.voted[#recorder.voted + 1] = { frameIndex = frameIndex, rollType = rollType }
        end,
    }
    ns.RollListener = {
        Initialize = function() end,
        Shutdown = function() end,
        ResolveWinner = function() end,
    }

    local rollFrameSettings = {
        enabled = true,
        confirmGreedAndPass = false,
        keepOpenAfterVote = false,
        resultLingerDuration = 3,
    }
    for key, value in pairs(settings or {}) do
        rollFrameSettings[key] = value
    end

    local addon = {
        db = {
            profile = {
                rollFrame = rollFrameSettings,
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
    ns.RollManager.Initialize(addon)
    ns.RollManager.StartRoll(7, 30)
    return ns
end

local function AcceptLatest()
    local dialog = mock._popupDialogs[#mock._popupDialogs]
    mock.AcceptPopup(dialog)
    return dialog
end

local function CancelLatest()
    local dialog = mock._popupDialogs[#mock._popupDialogs]
    mock.CancelPopup(dialog)
    return dialog
end

describe("Greed and Pass selection confirmation", function()
    local recorder

    before_each(function()
        mock.Reset()
        recorder = { hidden = {}, voted = {} }
    end)

    it("submits Greed immediately when disabled", function()
        local ns = NewRollNamespace(recorder)

        ns.RollManager.RequestRollSelection(7, ROLL_GREED)

        assert.are.same({ { rollID = 7, rollType = ROLL_GREED } }, mock._rollSubmissions)
        assert.are.equal(0, #mock._popupDialogs)
        assert.are.equal(1, #recorder.hidden)
    end)

    for _, choice in ipairs({
        { name = "Greed", rollType = ROLL_GREED },
        { name = "Pass", rollType = ROLL_PASS },
    }) do
        it("asks before submitting " .. choice.name, function()
            local ns = NewRollNamespace(recorder, { confirmGreedAndPass = true })

            ns.RollManager.RequestRollSelection(7, choice.rollType)

            assert.are.equal(0, #mock._rollSubmissions)
            assert.are.equal(1, #mock._popupDialogs)
            assert.are.equal(choice.name, mock._popupDialogs[1].textArg1)
            assert.are.equal("Test Item", mock._popupDialogs[1].textArg2)

            AcceptLatest()

            assert.are.same({ { rollID = 7, rollType = choice.rollType } }, mock._rollSubmissions)
        end)
    end

    it("submits no roll when cancelled and allows another choice", function()
        local ns = NewRollNamespace(recorder, { confirmGreedAndPass = true })
        ns.RollManager.RequestRollSelection(7, ROLL_PASS)

        CancelLatest()

        assert.are.equal(0, #mock._rollSubmissions)
        assert.is_not_nil(ns.RollManager.GetActiveRolls()[7].frameIndex)

        ns.RollManager.RequestRollSelection(7, ROLL_NEED)
        assert.are.same({ { rollID = 7, rollType = ROLL_NEED } }, mock._rollSubmissions)
    end)

    it("keeps custom confirmation separate from auto-confirming Blizzard prompts", function()
        local ns = NewRollNamespace(recorder, {
            autoConfirmRolls = true,
            confirmGreedAndPass = true,
        })

        ns.RollManager.RequestRollSelection(7, ROLL_GREED)

        assert.are.equal(1, #mock._popupDialogs)
        assert.are.equal(0, #mock._rollSubmissions)
    end)

    it("replaces a pending prompt when another roll asks for confirmation", function()
        local ns = NewRollNamespace(recorder, { confirmGreedAndPass = true })
        ns.RollManager.StartRoll(8, 30)
        ns.RollManager.RequestRollSelection(7, ROLL_PASS)
        local firstDialog = mock._popupDialogs[1]

        ns.RollManager.RequestRollSelection(8, ROLL_GREED)

        assert.is_true(firstDialog.hidden)
        assert.are.equal(2, #mock._popupDialogs)
        mock.AcceptPopup(firstDialog)
        assert.are.equal(0, #mock._rollSubmissions)

        AcceptLatest()
        assert.are.same({ { rollID = 8, rollType = ROLL_GREED } }, mock._rollSubmissions)
    end)

    it("does not submit twice when an accepted callback repeats", function()
        local ns = NewRollNamespace(recorder, { confirmGreedAndPass = true })
        ns.RollManager.RequestRollSelection(7, ROLL_GREED)
        local dialog = AcceptLatest()

        mock.AcceptPopup(dialog)

        assert.are.equal(1, #mock._rollSubmissions)
    end)

    it("does not change Need or Disenchant selections", function()
        local ns = NewRollNamespace(recorder, { confirmGreedAndPass = true })

        ns.RollManager.RequestRollSelection(7, ROLL_NEED)
        ns.RollManager.StartRoll(8, 30)
        ns.RollManager.RequestRollSelection(8, ROLL_DISENCHANT)

        assert.are.same({
            { rollID = 7, rollType = ROLL_NEED },
            { rollID = 8, rollType = ROLL_DISENCHANT },
        }, mock._rollSubmissions)
        assert.are.equal(0, #mock._popupDialogs)
    end)

    it("dismisses an unanswered prompt when the roll ends", function()
        local ns = NewRollNamespace(recorder, { confirmGreedAndPass = true })
        ns.RollManager.RequestRollSelection(7, ROLL_PASS)
        local dialog = mock._popupDialogs[1]

        ns.RollManager.CancelRoll(7)
        mock.AcceptPopup(dialog)

        assert.is_true(dialog.hidden)
        assert.are.equal(0, #mock._rollSubmissions)
    end)

    it("holds the frame open only after the confirmed vote", function()
        local ns = NewRollNamespace(recorder, {
            confirmGreedAndPass = true,
            keepOpenAfterVote = true,
        })
        ns.RollManager.RequestRollSelection(7, ROLL_GREED)

        assert.are.equal(0, #recorder.voted)

        AcceptLatest()

        assert.are.equal(1, #recorder.voted)
        assert.are.equal(ROLL_GREED, recorder.voted[1].rollType)
        assert.is_true(ns.RollManager.GetActiveRolls()[7].heldAfterVote)
    end)
end)
