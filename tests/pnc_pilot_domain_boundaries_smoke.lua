local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function capture(path)
    local calls = {}
    local subscriptions = {}
    local originalRequire = require
    require = function(name)
        calls[#calls + 1] = name
        if name == "PsychopatzCore/Events/PC_EventBus" then
            return {
                subscribe = function(eventType, listener, owner)
                    subscriptions[#subscriptions + 1] = {
                        eventType = eventType,
                        listener = listener,
                        owner = owner,
                    }
                    return true
                end,
            }
        end
        if name == "PNC/Core/Events/PNC_EventDefinitions" then
            return { NPC_INVENTORY_CHANGED = "inventory_changed" }
        end
        return true
    end
    local dirtyRecord
    PNC = {
        SupplyInventory = { Commands = {}, Queries = {} },
        NPCSupplyService = { Process = function() end },
        ProvisionEvaluator = {},
        ProvisionScheduler = {
            MarkInventoryDirty = function(record)
                dirtyRecord = record
            end,
        },
        ProvisionPolicyService = {},
    }
    local loaded = dofile(path)
    require = originalRequire
    return calls, loaded, subscriptions, function() return dirtyRecord end
end

local supplyCalls, supply = capture(
    ROOT .. "server/PNC/Supply/PNC_Supply.lua"
)
local expectedSupply = {
    "PNC/Supply/PNC_SupplyRequest",
    "PNC/Supply/PNC_SupplyMetrics",
    "PNC/Supply/PNC_ItemUtility",
    "PNC/Supply/PNC_SupplyIndex",
    "PNC/Supply/PNC_SupplySelector",
    "PNC/Supply/PNC_StorageAccessPolicy",
    "PNC/Supply/PNC_SupplyInventory",
    "PNC/Supply/PNC_NPCSupplyService",
}
assertEqual(#supplyCalls, #expectedSupply, "Supply require count")
for index = 1, #expectedSupply do
    assertEqual(supplyCalls[index], expectedSupply[index],
        "Supply require order " .. tostring(index))
end
assertEqual(supply.Commands, PNC.SupplyInventory.Commands,
    "Supply command facade")
assertEqual(supply.Queries, PNC.SupplyInventory.Queries,
    "Supply query facade")

local provisionCalls, provision, subscriptions, getDirtyRecord = capture(
    ROOT .. "server/PNC/Provision/PNC_Provision.lua"
)
local expectedProvision = {
    "PNC/Provision/PNC_ProvisionResolver",
    "PNC/Provision/PNC_ProvisionEvaluator",
    "PNC/Provision/PNC_ProvisionScheduler",
    "PNC/Provision/PNC_ProvisionPolicyService",
    "PsychopatzCore/Events/PC_EventBus",
    "PNC/Core/Events/PNC_EventDefinitions",
}
assertEqual(#provisionCalls, #expectedProvision, "Provision require count")
for index = 1, #expectedProvision do
    assertEqual(provisionCalls[index], expectedProvision[index],
        "Provision require order " .. tostring(index))
end
assertEqual(provision.Evaluator, PNC.ProvisionEvaluator,
    "Provision evaluator facade")
assertEqual(provision.Scheduler, PNC.ProvisionScheduler,
    "Provision scheduler facade")
assertEqual(#subscriptions, 1, "Provision inventory subscription count")
assertEqual(subscriptions[1].eventType, "inventory_changed",
    "Provision inventory subscription event")
local changedRecord = { id = "event-npc" }
subscriptions[1].listener(changedRecord)
assertEqual(getDirtyRecord(), changedRecord,
    "Provision inventory invalidation listener")

local mutationPath = ROOT
    .. "shared/PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations.lua"
local mutationFile = assert(io.open(mutationPath, "r"))
local mutationSource = mutationFile:read("*a")
mutationFile:close()
assertEqual(mutationSource:find("PNC.ProvisionScheduler", 1, true), nil,
    "Inventory must not depend directly on Provision")
if not mutationSource:find(
    "Events.emit(EventTypes.NPC_INVENTORY_CHANGED", 1, true
) then
    error("Inventory mutation event publisher missing")
end

local inventoryCalls = {}
PNC = { Inventory = { Internal = {} } }
local originalRequire = require
require = function(name)
    inventoryCalls[#inventoryCalls + 1] = name
    PNC.Inventory.EnsureRecordInventory = function() end
    PNC.Inventory.ApplyDelta = function() end
    PNC.Inventory.AddItems = function() end
    PNC.Inventory.RemoveItems = function() end
    PNC.Inventory.RebuildCaches = function() end
    PNC.Inventory.CanAccept = function() end
    PNC.Inventory.GetPersistenceMode = function() end
    return true
end
dofile(ROOT .. "shared/PNC/Core/Inventory/PNC_Inventory.lua")
require = originalRequire
assertEqual(PNC.Inventory.Commands.ApplyDelta, PNC.Inventory.ApplyDelta,
    "Inventory command compatibility")
assertEqual(PNC.Inventory.Commands.EnsureRecordInventory,
    PNC.Inventory.EnsureRecordInventory, "Inventory initialization command")

print("pnc_pilot_domain_boundaries_smoke: ok")
