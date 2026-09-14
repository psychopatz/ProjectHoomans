local T = require "tests/support/test"

local captured

PNC = {
    Core = {
        IsAuthority = function() return true end,
        GenerateID = function(prefix) return tostring(prefix) .. "_1" end,
    },
    Identity = {
        RollSeed = function() return 123 end,
    },
    Const = {
        ORDER_ROAM = "roam",
        ROAM_MODE_AREA = "area",
        ROAM_DEFAULT_RADIUS = 20,
    },
    UniqueNPCs = {
        Get = function(id)
            return {
                id = id,
                displayName = "Gorgon Ramsee",
                isFemale = false,
                archetypeID = "Chef",
            }
        end,
        Resolve = function(definition)
            return {
                id = nil,
                uniqueDefinitionId = definition.id,
                uniqueDefinitionVersion = 1,
                displayName = definition.displayName,
                name = definition.displayName,
                isFemale = definition.isFemale,
                identitySeed = 123,
                appearance = { outfit = { mode = "none" }, slots = {} },
                startingItems = {
                    {
                        type = "Base.Money",
                        stack = 1000,
                        itemState = { modData = { test = true } },
                    },
                },
            }
        end,
    },
    API = {
        Spawn = function(definition)
            captured = definition
            return { id = definition.id, name = definition.name }
        end,
    },
}

T.load("ProjectHoomans", "shared", "PNC/Core/API/PNC_API/UniqueNPCs.lua")

local record, reason = PNC.API.UniqueNPCs.SpawnTest(
    "unique:gorgonramsee",
    {
        getX = function() return 100 end,
        getY = function() return 200 end,
        getZ = function() return 0 end,
    }
)

T.truthy(record, "test spawn returns a runtime record")
T.equal(reason, "spawned", "test spawn reports success")
T.equal(captured.id, "unique_test_1", "test spawn gets a temporary id")
T.equal(captured.uniqueDefinitionId, nil,
    "test spawn does not carry the unique lifecycle id")
T.equal(captured.uniqueDefinitionVersion, nil,
    "test spawn does not carry the unique lifecycle version")
T.equal(captured.persist, false, "test spawn is not persistent")
T.equal(captured.debug, true, "test spawn is marked debug")
T.equal(captured.forceLive, true, "test spawn is immediately live")
T.equal(captured.x, 101.5, "test spawn is offset from the player")
T.equal(captured.startingItems[1].itemState.modData.test, true,
    "test spawn preserves authored item metadata")
T.finish("pnc_unique_npc_test_spawn_smoke")
