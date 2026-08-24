local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "server" } })

package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return {}
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {}
end

local deposited
local debugCalls = 0
local seenRequests = {}
PNC = {
    BuildingService = {},
    BuildRecipeCatalog = {
        Get = function(key)
            T.equal(key, "TestWall", "debug action resolves selected recipe")
            return {
                recipeKey = "TestWall",
                objectInfoName = "TestWall",
                requirements = {
                    { itemTypes = { "Base.Plank", "Base.Log" }, amount = 2 },
                    { itemTypes = { "Base.Hammer" }, amount = 1,
                        consumed = false },
                },
            }
        end,
        Build = function() return {} end,
    },
    WorkRepository = {},
    WorkDefinitions = {},
    WorkService = {
        CancellationHandlers = {},
        RegisterTargetProvider = function() end,
        RegisterPreparation = function() end,
        RegisterCompletion = function() end,
    },
    ColonyStorageService = {
        ResolveForPlayer = function()
            return { id = "storage-1" }
        end,
        DebugAction = function(player, args)
            debugCalls = debugCalls + 1
            if args.requestId and seenRequests[args.requestId] then
                return false, "duplicate_request"
            end
            if args.requestId then seenRequests[args.requestId] = true end
            deposited = {
                player = player, debugAction = args.debugAction,
                storageID = args.storageId, products = args.products,
                transactionID = args.requestId,
            }
            return true, "ok", { id = "storage-1" }, {
                products = args.products,
            }
        end,
    },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_BuildingService.lua")
local result, reason = Service.DebugGrantMaterials({ id = "admin" }, {
    recipeKey = "TestWall", requestId = "debug-request-1",
})
T.truthy(result, "debug material grant succeeds")
T.equal(reason, "MATERIALS_GRANTED", "debug material grant reason")
T.equal(deposited.storageID, "storage-1", "materials use colony stockpile")
T.equal(deposited.debugAction, "add_many",
    "materials use the storage debug CRUD action")
T.equal(deposited.transactionID, "debug-request-1",
    "debug grant is idempotent through request id")
T.equal(#deposited.products, 2, "all recipe inputs are granted")
T.equal(deposited.products[1].fullType, "Base.Plank",
    "first alternative is selected for recipe input")
T.equal(deposited.products[1].quantity, 2,
    "recipe input quantity is preserved")
T.equal(deposited.products[2].fullType, "Base.Hammer",
    "retained tool input is granted")
T.equal(debugCalls, 1, "debug material grant commits once")

local repeated, repeatedReason = Service.DebugGrantMaterials({ id = "admin" }, {
    recipeKey = "TestWall", requestId = "debug-request-1",
})
T.falsy(repeated, "duplicate debug request is rejected by storage CRUD")
T.equal(repeatedReason, "duplicate_request",
    "duplicate debug request reason is preserved")
T.equal(debugCalls, 2,
    "building service does not hide the storage duplicate response")

PNC.ColonyStorageService.ResolveForPlayer = function()
    return nil, "debug_required"
end
local denied, deniedReason = Service.DebugGrantMaterials({}, {
    recipeKey = "TestWall", requestId = "debug-request-2",
})
T.falsy(denied, "non-debug player cannot grant materials")
T.equal(deniedReason, "debug_required",
    "storage access failure is returned to the building action")

T.finish("pnc_building_debug_items_smoke")
