-------------------------------------------------------------------------------
-- Init_spec.lua
-- Tests for DragonLoot addon initialization
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

describe("Init", function()
    before_each(function()
        mock.Reset()
    end)

    local function initialize(profile)
        local ns = mock.CreateNamespace()
        ns.InitializeDB = function(addon)
            addon.db = { profile = profile }
        end

        mock.LoadFile(ns, "DragonLoot/Core/Init.lua")

        local messages = {}
        ns.Print = function(message)
            messages[#messages + 1] = message
        end

        ns.Addon:OnInitialize()
        return messages
    end

    it("prints the login message when enabled", function()
        local messages = initialize({ showLoginMessage = true })

        assert.are.same({ "Loaded. Type /dl help for commands." }, messages)
    end)

    it("does not print the login message when disabled", function()
        local messages = initialize({ showLoginMessage = false })

        assert.are.same({}, messages)
    end)
end)
