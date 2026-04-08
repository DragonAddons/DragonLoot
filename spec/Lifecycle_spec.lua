-------------------------------------------------------------------------------
-- Lifecycle_spec.lua
-- Tests for ns.LifecycleUtil (Lifecycle.lua)
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

describe("LifecycleUtil", function()
    local ns, LU

    before_each(function()
        mock.Reset()
        ns = mock.CreateNamespace()
        LU = mock.LoadLifecycle(ns)
    end)

    ---------------------------------------------------------------------------
    -- CreateState
    ---------------------------------------------------------------------------

    describe("CreateState", function()
        it("returns a table with token=0 and isLive=false", function()
            local state = LU.CreateState()

            assert.are.equal(0, state.token)
            assert.is_false(state.isLive)
        end)
    end)

    ---------------------------------------------------------------------------
    -- Activate
    ---------------------------------------------------------------------------

    describe("Activate", function()
        it("sets isLive to true and returns token 1 on first call", function()
            local state = LU.CreateState()

            local token = LU.Activate(state)

            assert.is_true(state.isLive)
            assert.are.equal(1, token)
        end)

        it("increments token to 2 on second call", function()
            local state = LU.CreateState()

            LU.Activate(state)
            local token = LU.Activate(state)

            assert.are.equal(2, token)
            assert.is_true(state.isLive)
        end)
    end)

    ---------------------------------------------------------------------------
    -- Invalidate
    ---------------------------------------------------------------------------

    describe("Invalidate", function()
        it("sets isLive to false", function()
            local state = LU.CreateState()
            LU.Activate(state)

            LU.Invalidate(state)

            assert.is_false(state.isLive)
        end)

        it("increments the token when called", function()
            local state = LU.CreateState()
            LU.Activate(state) -- token = 1

            LU.Invalidate(state) -- token must be 2

            assert.are.equal(2, state.token)
        end)
    end)

    ---------------------------------------------------------------------------
    -- CaptureToken
    ---------------------------------------------------------------------------

    describe("CaptureToken", function()
        it("returns current token value", function()
            local state = LU.CreateState()
            LU.Activate(state)

            assert.are.equal(1, LU.CaptureToken(state))
        end)

        it("returns nil when state is nil", function()
            assert.is_nil(LU.CaptureToken(nil))
        end)
    end)

    ---------------------------------------------------------------------------
    -- IsTokenCurrent
    ---------------------------------------------------------------------------

    describe("IsTokenCurrent", function()
        it("returns false on fresh state (not live)", function()
            local state = LU.CreateState()

            assert.is_false(LU.IsTokenCurrent(state, 0))
        end)

        it("returns true after Activate with matching token", function()
            local state = LU.CreateState()
            local token = LU.Activate(state)

            assert.is_true(LU.IsTokenCurrent(state, token))
        end)

        it("returns false after Invalidate", function()
            local state = LU.CreateState()
            local token = LU.Activate(state)
            LU.Invalidate(state)

            assert.is_false(LU.IsTokenCurrent(state, token))
        end)

        it("returns false with wrong token", function()
            local state = LU.CreateState()
            LU.Activate(state)

            assert.is_false(LU.IsTokenCurrent(state, 999))
        end)

        it("returns false when state is nil", function()
            assert.is_false(LU.IsTokenCurrent(nil, 1))
        end)

        it("returns false with the old token after Invalidate (token was incremented)", function()
            local state = LU.CreateState()
            local token = LU.Activate(state) -- token = 1, captured
            LU.Invalidate(state) -- token becomes 2

            assert.are.equal(2, state.token)
            assert.is_false(LU.IsTokenCurrent(state, token))
        end)
    end)

    ---------------------------------------------------------------------------
    -- Guard
    ---------------------------------------------------------------------------

    describe("Guard", function()
        it("fires callback when token is current", function()
            local state = LU.CreateState()
            local token = LU.Activate(state)
            local wasCalled = false

            local guarded = LU.Guard(state, token, function()
                wasCalled = true
            end)
            guarded()

            assert.is_true(wasCalled)
        end)

        it("does NOT fire callback when state is invalidated after guard creation", function()
            local state = LU.CreateState()
            local token = LU.Activate(state)
            local wasCalled = false

            local guarded = LU.Guard(state, token, function()
                wasCalled = true
            end)
            LU.Invalidate(state)
            guarded()

            assert.is_false(wasCalled)
        end)

        it("returns a no-op function when callback is not a function", function()
            local state = LU.CreateState()
            local token = LU.Activate(state)

            local guarded = LU.Guard(state, token, "not a function")

            assert.is_function(guarded)
            assert.has_no.errors(function()
                guarded()
            end)
        end)
    end)

    ---------------------------------------------------------------------------
    -- After
    ---------------------------------------------------------------------------

    describe("After", function()
        it("fires callback via C_Timer.After (immediately in mock)", function()
            local state = LU.CreateState()
            LU.Activate(state)
            local wasCalled = false

            LU.After(state, 0.5, function()
                wasCalled = true
            end)

            assert.is_true(wasCalled)
        end)

        it("does NOT fire callback after Invalidate", function()
            local state = LU.CreateState()
            LU.Activate(state)
            local wasCalled = false
            local savedAfter = C_Timer.After -- backup before override

            local savedCb
            C_Timer.After = function(_, cb) -- luacheck: ignore 121 122 212
                savedCb = cb
            end

            LU.After(state, 1, function()
                wasCalled = true
            end)
            LU.Invalidate(state)
            if savedCb then
                savedCb()
            end

            C_Timer.After = savedAfter -- luacheck: ignore 122

            assert.is_false(wasCalled)
        end)
    end)
end)
