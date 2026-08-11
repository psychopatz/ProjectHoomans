local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"
package.path = ROOT .. "shared/?.lua;" .. ROOT .. "server/?.lua;"
    .. ROOT .. "client/?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "assert") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy", 2) end
end

local function near(actual, expected, label)
    if math.abs((tonumber(actual) or 0) - expected) > 0.000001 then
        error((label or "assert near") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = deepCopy(entry) end
    return output
end

isClient = function() return false end
isServer = function() return true end
local nowMs = 0
local worldHour = 10
PNC = {
    Core = { DeepCopy = deepCopy, Now = function() return nowMs end },
    NeedsUtils = { WorldAgeHours = function() return worldHour end },
}

dofile(ROOT .. "shared/PNC/Core/Provision/PNC_ProvisionRuleRegistry.lua")
dofile(ROOT .. "shared/PNC/Core/Provision/Rules/PNC_FoodProvisionRule.lua")
dofile(ROOT .. "shared/PNC/Core/Provision/Rules/PNC_HydrationProvisionRule.lua")
dofile(ROOT .. "shared/PNC/Core/Provision/Rules/PNC_BandageProvisionRule.lua")
dofile(ROOT .. "shared/PNC/Core/Provision/PNC_ProvisionPolicy.lua")
dofile(ROOT .. "server/PNC/Supply/PNC_SupplyMetrics.lua")

equal(#PNC.ProvisionRuleRegistry.List(), 3, "proof rules registered")
local defaults = PNC.ProvisionPolicy.Defaults()
equal(defaults.schemaVersion, 2, "policy schema")
equal(defaults.revision, 1, "initial revision")
equal(defaults.policies.default.food.target, 0.80, "food default")
equal(defaults.policies.default.hydration.target, 0.70, "hydration default")
equal(defaults.policies.default.bandage.target, 3, "bandage default")

local migrated = PNC.ProvisionPolicy.Normalize({
    schemaVersion = 1,
    revision = 4,
    policies = {
        default = {
            food = { enabled = true, refillBelow = 30, target = 80 },
            hydration = { enabled = true, refillBelow = 25, target = 70 },
            bandage = { enabled = true, refillBelow = 1, target = 3 },
        },
    },
})
equal(migrated.schemaVersion, 2, "legacy policy migrated to schema two")
near(migrated.policies.default.food.refillBelow, 0.30,
    "legacy food threshold migrated")
near(migrated.policies.default.food.target, 0.80,
    "legacy food target migrated")
near(migrated.policies.default.hydration.target, 0.70,
    "legacy hydration target migrated")

local invalid, reason = PNC.ProvisionPolicy.ValidateRule("food", {
    enabled = true, refillBelow = 0.90, target = 0.80,
}, true)
equal(invalid, nil, "threshold above target rejected")
equal(reason, "target_below_refill", "threshold validation reason")
invalid, reason = PNC.ProvisionPolicy.ValidateRule("food", {
    enabled = true, refillBelow = -1, target = 0.80,
}, true)
equal(reason, "field_out_of_range", "negative rejected")
invalid, reason = PNC.ProvisionPolicy.ValidateRule("food", {
    enabled = true, refillBelow = 0.30, target = 0.80, surprise = 1,
}, true)
equal(reason, "unknown_field", "unknown field rejected")
invalid, reason = PNC.ProvisionPolicy.ValidateSubmission({
    schemaVersion = 2, policyId = "default", rules = { unknown = {} },
})
equal(reason, "unknown_rule", "unknown rule rejected")

local faction = {
    id = "faction_player", ownerPlayerKey = "player:owner",
    provision = defaults, memberIDs = {},
}
local records = {}
PNC.Registry = {
    Get = function(id) return records[id] end,
}
PNC.Factions = {
    GetNPCFaction = function(id)
        return records[id] and faction or nil, "unaffiliated"
    end,
}
dofile(ROOT .. "server/PNC/Provision/PNC_ProvisionResolver.lua")

local npc = {
    id = "npc_one", alive = true,
    affiliation = { factionID = faction.id, role = "resident" },
}
records[npc.id] = npc
local effective = PNC.ProvisionResolver.GetEffectivePolicy(npc)
equal(effective.rules.food.target, 0.80, "faction default resolved")
equal(npc.provision, nil, "policy not copied to npc")

local candidates = {}
PNC.SupplyInventory = {
    FindPersonal = function(record, request)
        return candidates[record.id]
            and candidates[record.id][request.resourceKind] or {}
    end,
}
dofile(ROOT .. "server/PNC/Provision/PNC_ProvisionEvaluator.lua")

local function candidate(descriptor)
    return { descriptor = descriptor, item = { id = tostring(descriptor) } }
end

candidates[npc.id] = {
    FOOD = { candidate({ hunger = 0.10, thirst = 0, quantity = 2 }) },
    HYDRATION = { candidate({ thirst = 0.10, remainingUses = 3,
        quantity = 1 }) },
    MEDICAL = { candidate({ quantity = 2 }) },
}
local food = PNC.ProvisionEvaluator.Evaluate(npc, "food")
near(food.onHand, 0.20, "food measured by vanilla utility and stack")
near(food.deficit, 0.60, "food deficit targets vanilla utility")
local hydration = PNC.ProvisionEvaluator.Evaluate(npc, "hydration")
near(hydration.onHand, 0.30, "hydration remaining uses measured")
local bandage = PNC.ProvisionEvaluator.Evaluate(npc, "bandage")
equal(bandage.onHand, 2, "usable bandages counted")
equal(bandage.satisfied, true, "bandage above strict threshold")

candidates[npc.id].FOOD = {
    candidate({ hunger = 0.10, thirst = 0, quantity = 4 }),
}
food = PNC.ProvisionEvaluator.Evaluate(npc, "food")
near(food.deficit, 0.40, "refill latch continues above threshold")
candidates[npc.id].FOOD = {
    candidate({ hunger = 0.10, thirst = 0, quantity = 8 }),
}
food = PNC.ProvisionEvaluator.Evaluate(npc, "food")
equal(food.satisfied, true, "target clears refill latch")
candidates[npc.id].FOOD = {
    candidate({ hunger = 0.10, thirst = 0, quantity = 3 }),
}
food = PNC.ProvisionEvaluator.Evaluate(npc, "food")
equal(food.satisfied, true, "equal threshold does not trigger")
candidates[npc.id].FOOD = {
    candidate({ hunger = 0.29, thirst = 0, quantity = 1 }),
}
food = PNC.ProvisionEvaluator.Evaluate(npc, "food")
near(food.deficit, 0.51, "strictly below threshold triggers")
local request = PNC.ProvisionEvaluator.BuildRequest(
    npc, PNC.ProvisionRuleRegistry.Get("food"), food)
equal(request.purpose, "PROVISION", "provision request purpose")
near(request.required.hunger, 0.51, "request carries utility deficit")

PNC.NPCSupplyService = {
    Process = function(raw, options)
        truthy(options.acquireOnly, "provision acquires only")
        truthy(options.ignorePersonal, "measured personal inventory skipped")
        local record = records[raw.requesterId]
        record.processed = (record.processed or 0) + 1
        if record.shortage then
            record.runtime.supply = { byKind = {
                [raw.resourceKind] = { nextRetry = worldHour + 0.25 },
            } }
            return false, "no_supply"
        end
        return true, "acquired"
    end,
    HasRecentNeedRequest = function(record) return record.recentNeed == true end,
}
dofile(ROOT .. "server/PNC/Provision/PNC_ProvisionScheduler.lua")

local bootstrapRecord = {
    id = "npc_bootstrap", alive = true,
    affiliation = { factionID = faction.id },
}
records[bootstrapRecord.id] = bootstrapRecord
candidates[bootstrapRecord.id] = {
    FOOD = {}, HYDRATION = {}, MEDICAL = {},
}
PNC.Factions.List = function() return { faction } end
PNC.Factions.GetMembers = function()
    return { { npcID = bootstrapRecord.id, alive = true } }
end
PNC.ProvisionScheduler.Queue = {}
PNC.ProvisionScheduler.Queued = {}
PNC.ProvisionScheduler.Bootstrapped = false
PNC.ProvisionScheduler.LastPumpAt = 0
nowMs = 1001
equal(PNC.ProvisionScheduler.Pump(nowMs), 2,
    "bootstrap schedules existing faction members")
equal(bootstrapRecord.processed, 2,
    "bootstrap provisions an existing saved colonist")
PNC.Factions.List = function() return {} end
PNC.ProvisionScheduler.Queue = {}
PNC.ProvisionScheduler.Queued = {}
PNC.ProvisionScheduler.LastPumpAt = 0

for index = 1, 5 do
    local record = {
        id = "npc_queue_" .. index, alive = true,
        affiliation = { factionID = faction.id },
    }
    records[record.id] = record
    candidates[record.id] = { FOOD = {}, HYDRATION = {}, MEDICAL = {} }
    PNC.ProvisionScheduler.MarkDirty(record, "bandage")
end
nowMs = 2002
equal(PNC.ProvisionScheduler.Pump(nowMs), 2, "bounded scheduler slice")
equal(PNC.SupplyMetrics.provisionSchedulerQueueSize, 5,
    "successful deficits requeued for target verification")

PNC.ProvisionScheduler.Queue = {}
PNC.ProvisionScheduler.Queued = {}
local blocked = {
    id = "npc_need", alive = true, recentNeed = true,
    affiliation = { factionID = faction.id },
}
records[blocked.id] = blocked
candidates[blocked.id] = { FOOD = {}, HYDRATION = {}, MEDICAL = {} }
PNC.ProvisionScheduler.MarkDirty(blocked, "food")
nowMs = 3003
PNC.ProvisionScheduler.Pump(nowMs)
equal(blocked.processed, nil, "recent need suppresses provision request")
equal(PNC.SupplyMetrics.provisionRequestsSuppressedByNeedRequest, 1,
    "need suppression metric")

PNC.ProvisionScheduler.Queue = {}
PNC.ProvisionScheduler.Queued = {}
local shortage = {
    id = "npc_shortage", alive = true, shortage = true,
    affiliation = { factionID = faction.id },
}
records[shortage.id] = shortage
candidates[shortage.id] = { FOOD = {}, HYDRATION = {}, MEDICAL = {} }
PNC.ProvisionScheduler.MarkDirty(shortage, "bandage")
nowMs = 4004
PNC.ProvisionScheduler.Pump(nowMs)
equal(shortage.processed, 1, "storage shortage attempted once")
equal(PNC.ProvisionScheduler.Queue[1].readyAt, worldHour + 0.25,
    "storage shortage waits for supply retry deadline")
nowMs = 5005
PNC.ProvisionScheduler.Pump(nowMs)
equal(shortage.processed, 1, "retry deadline prevents query spam")

local saved = 0
PNC.PlayerCharacters = {
    GetEntityKey = function(player) return player.key end,
}
PNC.Factions.GetPlayerFaction = function(player)
    if player.factionID ~= faction.id then return nil, "unaffiliated" end
    return deepCopy(faction)
end
PNC.Factions.SetProvisionPolicy = function(id, value)
    if id ~= faction.id then return false, "faction_not_found" end
    faction.provision = deepCopy(value)
    return true, "updated"
end
PNC.Factions.Save = function() saved = saved + 1 return true end
PNC.ProvisionScheduler.MarkFactionDirty = function() return 0 end
GlobalModData = { save = function() end }
dofile(ROOT .. "server/PNC/Provision/PNC_ProvisionPolicyService.lua")

local submission = {
    schemaVersion = 2, policyId = "default", expectedRevision = 1,
    rules = deepCopy(defaults.policies.default),
}
submission.rules.parentPolicyId = nil
submission.rules.bandage.target = 5
local ok
ok, reason = PNC.ProvisionPolicyService.Apply({
    key = "player:intruder", factionID = faction.id,
}, submission)
equal(ok, false, "other faction member cannot modify owner policy")
equal(reason, "not_faction_owner", "ownership rejection")
ok, reason = PNC.ProvisionPolicyService.Apply({
    key = "player:owner", factionID = faction.id,
}, submission)
equal(ok, true, "owner applies policy")
equal(faction.provision.revision, 2, "revision increments once")
equal(faction.provision.policies.default.bandage.target, 5,
    "authoritative policy persisted")
equal(saved, 1, "faction registry saved")

PNC.ProvisionRuleRegistry.Register({
    id = "dummy_radio", category = "utility", mode = "EXACT",
    selector = "RADIO", measure = "COUNT", defaults = {
        enabled = false, target = 1,
    }, ui = { labelKey = "dummy", descriptionKey = "dummy_desc",
        measureKey = "dummy_measure", fields = {
            { id = "target", type = "number", min = 0, max = 1, step = 1 },
        } },
})
PNC.Client = {
    RequestColonyAction = function(action, args)
        equal(action, "provision_set", "model submits colony action")
        truthy(args.submission.rules.dummy_radio,
            "dummy registry rule submitted without UI special case")
        return true, "sent"
    end,
}
local UIModel = dofile(ROOT
    .. "client/PNC/UI/Provision/PNC_ProvisionSettingsModel.lua")
local model = UIModel.New({ provision = faction.provision,
    policyId = "default", canEdit = true })
truthy(model:Get("dummy_radio"), "new registry rule appears in model")
model:Set("bandage", "target", 7)
equal(faction.provision.policies.default.bandage.target, 5,
    "working copy does not mutate authoritative policy")
model:ResetDefaults()
equal(model:Get("bandage").target, 3, "reset uses registry defaults")
ok = model:Submit()
equal(ok, true, "valid working copy submits")

print("pnc_provision_smoke: ok")
