local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "server" } })

package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return {}
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {}
end

local builder = {
    getPlayerNum = function() return 0 end,
    getInventory = function() return nil end,
    isBuildCheat = function() return false end,
    getPerkLevel = function() return 0 end,
}
local createdCursor
ISBuildIsoEntity = {
    new = function(_, character, info, nSprite, containers, logic)
        createdCursor = {
            character = character,
            info = info,
            nSprite = nSprite,
            logic = logic,
            create = function(self)
                self.created = true
                return true
            end,
            getSprite = function() end,
        }
        return createdCursor
    end,
}
package.preload["BuildingObjects/ISBuildIsoEntity"] = function()
    return ISBuildIsoEntity
end

local completionHandler
local xpCalls = 0
PNC = {
    BuildRecipeCatalog = {
        Get = function(name)
            return {
                objectInfoName = name,
                displayName = "Log Fence",
                nativeObjectInfo = {},
                nativeRecipe = {},
                xpAwards = { { skillId = "Woodwork", amount = 4.5 } },
                requirements = {},
            }
        end,
    },
    WorkRepository = {
        MarkDirty = function() end,
    },
    WorkDefinitions = {},
    WorkService = {
        CancellationHandlers = {},
        RegisterTargetProvider = function() end,
        RegisterPreparation = function() end,
        RegisterCompletion = function(operation, handler)
            if operation == "BUILD_OBJECT" then completionHandler = handler end
        end,
    },
    BaseService = { Get = function() return nil end },
    WorkInputService = { Commit = function() return true end },
    Registry = {
        GetLiveZombie = function() return builder end,
        Get = function() return { id = "npc-1", recruited = true } end,
    },
    Skills = {
        AddXP = function(record, skillID, amount)
            xpCalls = xpCalls + 1
            record.awardedSkill, record.awardedXP = skillID, amount
            return true
        end,
    },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_BuildingService.lua")
T.truthy(Service, "building service loads")
T.truthy(completionHandler, "building completion handler is registered")

local order = {
    id = "build-order-1", status = "WORKING",
    requiredWork = 100, progress = 100,
    workerId = "npc-1",
    payload = { blueprint = {
        objectInfoName = "crafted_04_116", nSprite = 1,
        x = 10, y = 10, z = 0,
    } },
}
local ok, reason = completionHandler(order)
T.equal(ok, true, "building completion succeeds: " .. tostring(reason))
T.falsy(reason, "building completion has no failure reason")
T.equal(createdCursor.character, builder,
    "vanilla build cursor retains the live NPC character")
T.equal(createdCursor.player, 0,
    "vanilla build cursor receives a valid player context")
T.equal(createdCursor.created, true, "vanilla build cursor reaches create")
T.equal(order.payload.placed, true, "completion marks the blueprint placed")
T.equal(order.payload.xpGranted, true,
    "completion marks recipe XP as granted")
T.equal(order.payload.xpAwarded["1"], true,
    "completion persists the awarded recipe entry")
completionHandler(order)
T.equal(xpCalls, 1, "recipe XP is not duplicated on completion retry")

T.finish("pnc_building_completion_smoke")
