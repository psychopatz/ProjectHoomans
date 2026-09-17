local T = require "tests/support/test"
T.addPackagePaths()

local now = 100
local consumed = {}
local refilled = {}
local source = {
    key = "faucet@5:0:0#1",
    x = 5,
    y = 0,
    z = 0,
    object = { live = true },
}
local records = {
    ["npc:alice"] = {
        id = "npc:alice",
        alive = true,
        x = 0,
        y = 0,
        z = 0,
        inventory = {
            revision = 1,
            items = {
                apple = {
                    id = "apple",
                    type = "Base.Apple",
                    stack = 1,
                },
            },
        },
    },
    ["npc:bob"] = {
        id = "npc:bob",
        alive = true,
        x = 0,
        y = 0,
        z = 0,
        inventory = {
            revision = 2,
            items = {
                bottle = {
                    id = "bottle",
                    type = "Base.EmptyBottle",
                    stack = 1,
                },
            },
        },
    },
}

PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
}
PNC = {
    Core = {
        IsAuthority = function() return true end,
        Now = function() return now end,
    },
    Registry = {
        Get = function(id) return records[tostring(id or "")] end,
        ForEach = function(callback)
            for _, record in pairs(records) do callback(record) end
        end,
        MarkDirty = function() end,
    },
    NearbyResourceLocator = {},
    NearbyWaterService = {
        ResolveFillSource = function(_, key)
            if key and tostring(key) ~= source.key then
                return nil, "WATER_FILL_SOURCE_UNAVAILABLE"
            end
            return source
        end,
        BuildApproach = function() return {
            x = 5.5,
            y = 0.5,
            z = 0,
            interactionFacing = "N",
            approachKey = "5:0:0",
        } end,
    },
    WaterHydrationPolicy = {
        GetContext = function(_, options)
            if options and options.manualOverride == true then
                return { kind = "MANUAL_OVERRIDE", manualOverride = true }
            end
            return nil, "WATER_LOCATION_REQUIRED"
        end,
    },
    WaterContainerService = {
        FindContainer = function(record, itemID)
            local item = record.inventory.items[tostring(itemID or "")]
            if not item or item.id ~= "bottle" then
                return nil, "WATER_CONTAINER_NOT_REFILLABLE"
            end
            return item, { canFill = true, freeCapacity = 2 }
        end,
        Refill = function(record, itemID, foundSource)
            if foundSource ~= source then
                return false, "wrong_source"
            end
            if tostring(itemID) ~= "bottle" then
                return false, "wrong_item"
            end
            refilled[#refilled + 1] = {
                npcID = record.id,
                itemID = itemID,
                sourceKey = foundSource.key,
            }
            return true, 2, itemID
        end,
    },
    NPCSupplyService = {
        ConsumePersonalItem = function(record, itemID, required, kind)
            if tostring(itemID) ~= "apple" or kind ~= "FOOD" then
                return false, "PERSONAL_ITEM_NOT_SUITABLE"
            end
            record.inventory.items[itemID] = nil
            consumed[#consumed + 1] = {
                npcID = record.id,
                itemID = itemID,
                required = required,
                resourceKind = kind,
            }
            return true, "PERSONAL_ITEM_CONSUMED", {
                hunger = 0.25,
                thirst = 0.05,
                consumedFraction = 1,
                undo = function() end,
            }
        end,
    },
    Semantics = {},
    Tasking = { Events = { Emit = function() end } },
}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticTaskRequest.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticActionPlanService.lua"
)
local Plans = PNC.Semantics.ActionPlanService
Plans.PUMP_INTERVAL_MS = 0
Plans.RECONCILE_INTERVAL_MS = 0

T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticWorldTargetResolver.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticWaterTargetResolver.lua"
)

local selectedByRequest = {}
PNC.Semantics.ItemSelector = {
    Find = function(record, request)
        local item
        local classification
        local capabilities = request and request.capabilities or {}
        local required = {}
        for index = 1, #capabilities do
            required[string.lower(tostring(capabilities[index]))] = true
        end
        if request and request.itemID then
            item = record.inventory.items[tostring(request.itemID)]
        elseif required.edible then
            item = record.inventory.items.apple
        elseif required.refillable then
            item = record.inventory.items.bottle
        end
        if not item then return nil, "item_not_found" end
        classification = { capabilities = required }
        selectedByRequest[#selectedByRequest + 1] = {
            itemID = item.id,
            capabilities = required,
        }
        return {
            itemID = item.id,
            fullType = item.type,
            available = item.stack,
            quantity = 1,
            score = 100,
            classification = classification,
        }, "matched"
    end,
}

local WorldTargets = PNC.Semantics.WorldTargetResolver
Plans.RegisterProvider("MOVE_TO", {
    Resolve = function(_, step, record)
        return WorldTargets.Resolve(step.parameters.target, { record = record })
    end,
    Start = function(_, step)
        return { complete = true, result = {
            targetID = step.assignment and step.assignment.targetID,
        } }
    end,
    Tick = function(_, step)
        return { complete = true, result = {
            targetID = step.assignment and step.assignment.targetID,
        } }
    end,
})

T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanItemProvider.lua"
)
local Requests = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticTaskRequestService.lua"
)
local Handler = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/SemanticConsumptionTaskHandler/PNC_SemanticConsumptionTaskHandler.lua"
)

local function request(action, npcID, object, requestID)
    return {
        requestID = requestID,
        intent = "REQUEST",
        speechAct = "REQUEST",
        action = action,
        object = object,
        confidence = 0.96,
        rawText = action,
        normalizedText = string.lower(action),
        recipient = { id = npcID },
    }
end

local eat = request("EAT", "npc:alice", {
    text = "apple",
    unresolved = true,
}, "task:eat:1")
local eatPlan = Handler.BuildPlan(eat, { npcID = "npc:alice" })
T.equal(eatPlan.steps[1].action, "SELECT_ITEM",
    "eat starts with a queued item selection")
T.equal(eatPlan.steps[2].action, "CONSUME_ITEM",
    "eat commits through a separate authoritative step")
T.equal(eatPlan.steps[1].parameters.object.capabilities[1], "edible",
    "the action constraint is carried into selection")
local accepted = Requests.Submit(eat, {
    npcID = "npc:alice",
    internal = true,
})
T.equal(accepted.accepted, true, "eat request is admitted locally")
local eatRuntime = Plans.GetMutable("npc:alice")
now = now + 1
Plans.Pump(now)
T.equal(eatRuntime.steps[1].state, "ASSIGNED",
    "eat selection resolves in the plan pump")
T.equal(eatRuntime.steps[1].assignment.itemID, "apple",
    "eat selects the actual compact inventory item")
now = now + 1
Plans.Pump(now)
T.equal(eatRuntime.steps[2].state, "PENDING",
    "selection completes before consumption starts")
now = now + 1
Plans.Pump(now)
now = now + 1
Plans.Pump(now)
T.equal(eatRuntime.steps[2].state, "ASSIGNED",
    "consumption re-resolves before commit")
now = now + 1
Plans.Pump(now)
T.equal(eatRuntime.state, "COMPLETED",
    "eat completes through the ordered plan")
T.equal(#consumed, 1, "only the authoritative consumption service mutates")
T.equal(consumed[1].itemID, "apple",
    "the exact selected item is passed to the authority")

local refill = request("REFILL", "npc:bob", {
    text = "bottle",
    unresolved = true,
}, "task:refill:1")
local refillResult = Requests.Submit(refill, {
    npcID = "npc:bob",
    internal = true,
})
T.equal(refillResult.accepted, true, "refill request is admitted locally")
local refillRuntime = Plans.GetMutable("npc:bob")
T.equal(refillRuntime.manualOverride, true,
    "semantic refill plan preserves manual override authority")
now = now + 1
Plans.Pump(now)
now = now + 1
Plans.Pump(now)
T.equal(refillRuntime.steps[2].state, "PENDING",
    "refill selection completes before travel")
now = now + 1
Plans.Pump(now)
now = now + 1
Plans.Pump(now)
T.equal(refillRuntime.steps[2].state, "ASSIGNED",
    "water source resolves inside MOVE_TO")
T.equal(refillRuntime.steps[2].assignment.targetID, source.key,
    "movement stores only a stable source key")
T.falsy(refillRuntime.steps[2].assignment.object,
    "live source objects never enter the queued assignment")
now = now + 1
Plans.Pump(now)
T.equal(refillRuntime.steps[3].state, "PENDING",
    "arrival advances the refill queue")
now = now + 1
Plans.Pump(now)
now = now + 1
Plans.Pump(now)
T.equal(refillRuntime.steps[3].state, "ASSIGNED",
    "refill revalidates the selected container")
now = now + 1
Plans.Pump(now)
T.equal(refillRuntime.state, "COMPLETED",
    "refill completes after movement")
T.equal(#refilled, 1, "refill uses the authoritative water service")
T.equal(refilled[1].sourceKey, source.key,
    "refill resolves the live source by the queued stable key")

T.finish("pnc_semantic_consumption_task_smoke")
