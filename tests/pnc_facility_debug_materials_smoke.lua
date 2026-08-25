local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "server" } })

package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {}
end

local deposits = {}
local denied = false
local seen = {}
PNC = {
    SettlementRepository = {
        State = { facilities = {}, components = {} },
        MarkDirty = function() end,
    },
    FacilityValidationService = {},
    BuildRecipeCatalog = {
        Get = function(objectInfoName)
            if objectInfoName ~= "Base.Forge" then return nil end
            return { requirements = {
                { itemTypes = { "Base.IronBar" }, amount = 4 },
            } }
        end,
    },
    FacilityDefinitions = {
        Get = function(id)
            if id == "forge" then
                return { directWorkstation = true,
                    buildRecipeObjectInfoName = "Base.Forge",
                    buildCosts = {} }
            end
            if id ~= "research" then return nil end
            return {
                buildCosts = {
                    { fullType = "Base.Plank", amount = 3 },
                    { itemTypes = { "Base.Nails", "Base.Screws" }, amount = 2 },
                },
            }
        end,
    },
    FacilityCostService = {},
    ColonyStorageService = {
        ResolveForPlayer = function()
            return denied and nil or { id = "storage-1" },
                denied and "debug_required" or nil
        end,
        DebugAction = function(_, args)
            if seen[args.requestId] then return false, "duplicate_request" end
            seen[args.requestId] = true
            if denied then return false, "debug_required" end
            deposits[#deposits + 1] = args
            return true, "added", { id = "storage-1" }, {
                products = args.products,
            }
        end,
    },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Settlement/FacilityService/PNC_FacilityService_Core.lua")
local result, reason = Service.DebugGrantMaterials({ id = "admin" }, {
    definitionId = "research", requestId = "facility-debug-1",
})
T.truthy(result, "facility debug material grant succeeds")
T.equal(reason, "FACILITY_MATERIALS_GRANTED",
    "facility debug grant reason")
T.equal(deposits[1].debugAction, "add_many",
    "facility debug grant uses storage CRUD")
T.equal(deposits[1].storageId, "storage-1",
    "facility debug grant targets colony storage")
T.equal(#deposits[1].products, 2, "all declared build costs are granted")
T.equal(deposits[1].products[1].fullType, "Base.Plank",
    "facility cost full type is preserved")
T.equal(deposits[1].products[1].quantity, 3,
    "facility cost quantity is preserved")
T.equal(deposits[1].products[2].fullType, "Base.Nails",
    "facility cost alternative uses first item type")

local repeated, repeatedReason = Service.DebugGrantMaterials({ id = "admin" }, {
    definitionId = "research", requestId = "facility-debug-1",
})
T.falsy(repeated, "duplicate facility debug request is rejected")
T.equal(repeatedReason, "duplicate_request",
    "storage duplicate response is preserved")

local forge, forgeReason = Service.DebugGrantMaterials({ id = "admin" }, {
    definitionId = "forge", requestId = "facility-debug-forge-1",
})
T.truthy(forge, "direct workstation debug grant succeeds")
T.equal(forgeReason, "FACILITY_MATERIALS_GRANTED",
    "direct workstation debug grant reason")
T.equal(deposits[2].products[1].fullType, "Base.IronBar",
    "direct workstation debug uses native recipe material")
T.equal(deposits[2].products[1].quantity, 4,
    "direct workstation debug uses native recipe quantity")

denied = true
local blocked, blockedReason = Service.DebugGrantMaterials({ id = "guest" }, {
    definitionId = "research", requestId = "facility-debug-2",
})
T.falsy(blocked, "unauthorized facility debug grant is rejected")
T.equal(blockedReason, "debug_required",
    "storage debug gate is preserved")

T.finish("pnc_facility_debug_materials_smoke")
