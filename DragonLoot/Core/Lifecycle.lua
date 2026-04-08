-------------------------------------------------------------------------------
-- Lifecycle.lua
-- Lightweight lifecycle guards for delayed callbacks
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local C_Timer = C_Timer

-------------------------------------------------------------------------------
-- Public Interface: ns.LifecycleUtil
-------------------------------------------------------------------------------

ns.LifecycleUtil = ns.LifecycleUtil or {}

local LifecycleUtil = ns.LifecycleUtil

function LifecycleUtil.CreateState()
    return {
        token = 0,
        isLive = false,
    }
end

function LifecycleUtil.Activate(state)
    state.token = (state.token or 0) + 1
    state.isLive = true
    return state.token
end

function LifecycleUtil.Invalidate(state)
    state.token = (state.token or 0) + 1
    state.isLive = false
    return state.token
end

function LifecycleUtil.CaptureToken(state)
    if not state then
        return nil
    end
    return state.token
end

function LifecycleUtil.IsTokenCurrent(state, token)
    if not state then
        return false
    end
    return state.isLive and state.token == token
end

function LifecycleUtil.Guard(state, token, callback)
    if type(callback) ~= "function" then
        return function() end
    end

    return function(...)
        if not LifecycleUtil.IsTokenCurrent(state, token) then
            return
        end
        callback(...)
    end
end

function LifecycleUtil.After(state, delay, callback)
    local token = LifecycleUtil.CaptureToken(state)
    if token == nil then
        return nil
    end

    C_Timer.After(delay, LifecycleUtil.Guard(state, token, callback))
    return token
end
