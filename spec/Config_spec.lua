-------------------------------------------------------------------------------
-- Config_spec.lua
-- Tests for Config.lua schema migration via ns.InitializeDB
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

describe("Config", function()
    local ns

    before_each(function()
        mock.Reset()
        ns = mock.CreateNamespace()
    end)

    -- Helper: load Config.lua and run InitializeDB on a mock addon
    local function initWithSeed(currentNs, profileSeed)
        mock._profileSeed = profileSeed
        mock.LoadConfig(currentNs)
        local addon = { db = nil }
        currentNs.InitializeDB(addon)
        return addon.db
    end

    ---------------------------------------------------------------------------
    -- Fresh profile (all defaults)
    ---------------------------------------------------------------------------

    describe("fresh profile", function()
        it("has all default keys after InitializeDB", function()
            local db = initWithSeed(ns, nil)

            assert.is_true(db.profile.enabled)
            assert.are.equal(1.0, db.profile.lootWindow.scale)
            assert.are.equal(12, db.profile.rollFrame.timerBarHeight)
            assert.are.equal("Friz Quadrata TT", db.profile.appearance.font)
            assert.are.equal(100, db.profile.history.maxEntries)
        end)

        it("sets schemaVersion to 3", function()
            local db = initWithSeed(ns, nil)

            assert.are.equal(3, db.profile.schemaVersion)
        end)

        it("has lootIconSize in a fresh profile", function()
            local db = initWithSeed(ns, nil)

            assert.is_not_nil(db.profile.appearance.lootIconSize)
            assert.are.equal(36, db.profile.appearance.lootIconSize)
        end)
    end)

    ---------------------------------------------------------------------------
    -- FillMissingDefaults (tested through InitializeDB)
    ---------------------------------------------------------------------------

    describe("FillMissingDefaults", function()
        it("back-fills missing rollFrame.frameWidth", function()
            local db = initWithSeed(ns, {
                rollFrame = {
                    enabled = true,
                    -- frameWidth intentionally missing
                },
            })

            assert.are.equal(328, db.profile.rollFrame.frameWidth)
        end)

        it("resets wrong-type timerBarHeight to default number", function()
            local db = initWithSeed(ns, {
                rollFrame = {
                    timerBarHeight = "bad",
                },
            })

            assert.are.equal(12, db.profile.rollFrame.timerBarHeight)
        end)

        it("preserves valid non-default history.maxEntries", function()
            local db = initWithSeed(ns, {
                history = {
                    maxEntries = 50,
                },
            })

            assert.are.equal(50, db.profile.history.maxEntries)
        end)
    end)

    ---------------------------------------------------------------------------
    -- MigrateProfile: borderTexture fix
    ---------------------------------------------------------------------------

    describe("borderTexture migration", function()
        it("resets borderTexture from Solid to None", function()
            local db = initWithSeed(ns, {
                appearance = {
                    borderTexture = "Solid",
                },
            })

            assert.are.equal("None", db.profile.appearance.borderTexture)
        end)
    end)

    ---------------------------------------------------------------------------
    -- MigrateProfile: iconSize split
    ---------------------------------------------------------------------------

    describe("iconSize split migration", function()
        it("clears old iconSize field after migration", function()
            local db = initWithSeed(ns, {
                appearance = {
                    iconSize = 48,
                },
            })

            -- FillMissingDefaults runs first and fills lootIconSize/rollIconSize
            -- with defaults (36), so iconSize=48 does NOT propagate. The old
            -- iconSize field is cleared regardless.
            assert.is_nil(db.profile.appearance.iconSize)
            assert.are.equal(36, db.profile.appearance.lootIconSize)
            assert.are.equal(36, db.profile.appearance.rollIconSize)
        end)

        it("preserves existing lootIconSize when iconSize is also present", function()
            local db = initWithSeed(ns, {
                appearance = {
                    iconSize = 48,
                    lootIconSize = 42,
                    rollIconSize = 44,
                },
            })

            -- Existing values survive: FillMissingDefaults does not overwrite
            -- them (they're not nil), and iconSize migration skips them too.
            assert.are.equal(42, db.profile.appearance.lootIconSize)
            assert.are.equal(44, db.profile.appearance.rollIconSize)
            assert.is_nil(db.profile.appearance.iconSize)
        end)

        it(
            "copies iconSize to lootIconSize when lootIconSize is absent (skips FillMissingDefaults at schema v3)",
            function()
                local db = initWithSeed(ns, {
                    schemaVersion = 3,
                    appearance = {
                        iconSize = 48,
                        -- lootIconSize intentionally absent to test migration propagation
                    },
                })

                assert.are.equal(48, db.profile.appearance.lootIconSize)
                assert.is_nil(db.profile.appearance.iconSize)
            end
        )
    end)

    ---------------------------------------------------------------------------
    -- Schema version
    ---------------------------------------------------------------------------

    describe("schemaVersion", function()
        it("is set to 3 after migration from version 0", function()
            local db = initWithSeed(ns, {
                -- schemaVersion intentionally missing (defaults to 0)
            })

            assert.are.equal(3, db.profile.schemaVersion)
        end)
    end)
end)
