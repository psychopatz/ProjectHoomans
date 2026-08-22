local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "root", "")
T.addPackagePaths()

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

T.load(ROOT .. "shared/PNC/Core/Provision/PNC_ProvisionRuleRegistry.lua")
T.load(ROOT .. "shared/PNC/Core/Provision/Rules/PNC_FoodProvisionRule.lua")
T.load(ROOT .. "shared/PNC/Core/Provision/Rules/PNC_HydrationProvisionRule.lua")
T.load(ROOT .. "shared/PNC/Core/Provision/Rules/PNC_BandageProvisionRule.lua")
T.load(ROOT .. "shared/PNC/Core/Provision/PNC_ProvisionPolicy.lua")
T.load(ROOT .. "server/PNC/Supply/PNC_SupplyMetrics.lua")

T.equal(#PNC.ProvisionRuleRegistry.List(), 3, "proof rules registered")
local defaults = PNC.ProvisionPolicy.Defaults()
T.equal(defaults.schemaVersion, 2, "policy schema")
T.equal(defaults.revision, 1, "initial revision")
T.equal(defaults.policies.default.food.target, 0.80, "food default")
T.equal(defaults.policies.default.hydration.target, 0.70, "hydration default")
T.equal(defaults.policies.default.bandage.target, 3, "bandage default")

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
T.equal(migrated.schemaVersion, 2, "legacy policy migrated to schema two")
T.near(migrated.policies.default.food.refillBelow, 0.30, 0.000001, "legacy food threshold migrated")
T.near(migrated.policies.default.food.target, 0.80, 0.000001, "legacy food target migrated")
T.near(migrated.policies.default.hydration.target, 0.70, 0.000001, "legacy hydration target migrated")

local invalid, reason = PNC.ProvisionPolicy.ValidateRule("food", {
    enabled = true, refillBelow = 0.90, target = 0.80,
}, true)
T.equal(invalid, nil, "threshold above target rejected")
T.equal(reason, "target_below_refill", "threshold validation reason")
invalid, reason = PNC.ProvisionPolicy.ValidateRule("food", {
    enabled = true, refillBelow = -1, target = 0.80,
}, true)
T.equal(reason, "field_out_of_range", "negative rejected")
invalid, reason = PNC.ProvisionPolicy.ValidateRule("food", {
    enabled = true, refillBelow = 0.30, target = 0.80, surprise = 1,
}, true)
T.equal(reason, "unknown_field", "unknown field rejected")
invalid, reason = PNC.ProvisionPolicy.ValidateSubmission({
    schemaVersion = 2, policyId = "default", rules = { unknown = {} },
})
T.equal(reason, "unknown_rule", "unknown rule rejected")

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
T.load(ROOT .. "server/PNC/Provision/PNC_ProvisionResolver.lua")

local npc = {
    id = "npc_one", alive = true,
    affiliation = { factionID = faction.id, role = "resident" },
}
records[npc.id] = npc
local effective = PNC.ProvisionResolver.GetEffectivePolicy(npc)
T.equal(effective.rules.food.target, 0.80, "faction default resolved")
T.equal(npc.provision, nil, "policy not copied to npc")

local candidates = {}
PNC.SupplyInventory = {
    FindPersonal = function(record, request)
        return candidates[record.id]
            and candidates[record.id][request.resourceKind] or {}
    end,
}
PNC.StorageAccessPolicy = {
    Resolve = function() return nil, "storage_not_at_base" end,
}
PNC.SupplySelector = {
    SelectFromStorage = function() return {}, 0, {} end,
}
PNC.SupplyIndex = {
    Query = function(_, request)
        if request.resourceKind == "FOOD" then
            return {{ descriptor = {
                fullType = "Base.Apple", hunger = 0.10, thirst = 0,
                calories = 95, quantity = 2, remainingUses = 1,
            } }}
        end
        if request.resourceKind == "HYDRATION" then
            return {{ descriptor = {
                fullType = "Base.WaterBottleFull", hunger = 0,
                thirst = 0.10, calories = 0, quantity = 1,
                remainingUses = 3,
            } }}
        end
        return {{ descriptor = {
            fullType = "Base.Bandage", hunger = 0, thirst = 0,
            calories = 0, quantity = 2, remainingUses = 1,
        } }}
    end,
}
PNC.Inventory = {
    GetPersistenceMode = function() return "SEED_ONLY" end,
}
T.load(ROOT .. "server/PNC/Provision/PNC_ProvisionEvaluator.lua")

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
T.near(food.onHand, 0.20, 0.000001, "food measured by vanilla utility and stack")
T.near(food.deficit, 0.60, 0.000001, "food deficit targets vanilla utility")
local hydration = PNC.ProvisionEvaluator.Evaluate(npc, "hydration")
T.near(hydration.onHand, 0.30, 0.000001, "hydration remaining uses measured")
local bandage = PNC.ProvisionEvaluator.Evaluate(npc, "bandage")
T.equal(bandage.onHand, 2, "usable bandages counted")
T.equal(bandage.satisfied, true, "bandage above strict threshold")
local inspected = PNC.ProvisionEvaluator.Inspect(npc)
T.equal(inspected.storageAccess, false, "diagnostics storage access state")
T.equal(inspected.storageAccessReason, "storage_not_at_base",
    "diagnostics exposes provision access blocker")
T.equal(#inspected.rules, 3, "diagnostics includes every provision rule")
T.near(inspected.rules[1].onHand, 0.20, 0.000001, "diagnostics exposes measured carried food")
local storageMeasurement = PNC.ProvisionEvaluator.MeasureStorage({
    inventory = {},
})
T.near(storageMeasurement.food.amount, 0.20, 0.000001, "diagnostics exposes colony storage hunger utility")
T.near(storageMeasurement.food.calories, 190, 0.000001, "diagnostics exposes colony storage calories")
T.near(storageMeasurement.hydration.amount, 0.30, 0.000001, "diagnostics exposes colony storage hydration utility")
T.equal(storageMeasurement.bandage.amount, 2,
    "diagnostics exposes usable medicine count")

candidates[npc.id].FOOD = {
    candidate({ hunger = 0.10, thirst = 0, quantity = 4 }),
}
food = PNC.ProvisionEvaluator.Evaluate(npc, "food")
T.near(food.deficit, 0.40, 0.000001, "refill latch continues above threshold")
candidates[npc.id].FOOD = {
    candidate({ hunger = 0.10, thirst = 0, quantity = 8 }),
}
food = PNC.ProvisionEvaluator.Evaluate(npc, "food")
T.equal(food.satisfied, true, "target clears refill latch")
candidates[npc.id].FOOD = {
    candidate({ hunger = 0.10, thirst = 0, quantity = 3 }),
}
food = PNC.ProvisionEvaluator.Evaluate(npc, "food")
T.equal(food.satisfied, true, "equal threshold does not trigger")
candidates[npc.id].FOOD = {
    candidate({ hunger = 0.29, thirst = 0, quantity = 1 }),
}
food = PNC.ProvisionEvaluator.Evaluate(npc, "food")
T.near(food.deficit, 0.51, 0.000001, "strictly below threshold triggers")
local request = PNC.ProvisionEvaluator.BuildRequest(
    npc, PNC.ProvisionRuleRegistry.Get("food"), food)
T.equal(request.purpose, "PROVISION", "provision request purpose")
T.near(request.required.hunger, 0.51, 0.000001, "request carries utility deficit")

PNC.NPCSupplyService = {
    Process = function(raw, options)
        T.truthy(options.acquireOnly, "provision acquires only")
        T.truthy(options.ignorePersonal, "measured personal inventory skipped")
        T.truthy(options.force, "provision bypasses need-consumption cooldown")
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
T.load(ROOT .. "server/PNC/Provision/PNC_ProvisionScheduler.lua")

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
T.equal(PNC.ProvisionScheduler.Pump(nowMs), 2,
    "bootstrap schedules existing faction members")
T.equal(bootstrapRecord.processed, 2,
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
T.equal(PNC.ProvisionScheduler.Pump(nowMs), 2, "bounded scheduler slice")
T.equal(PNC.SupplyMetrics.provisionSchedulerQueueSize, 5,
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
T.equal(blocked.processed, 1,
    "recent hunger check does not suppress reserve provisioning")

PNC.ProvisionScheduler.Queue = {}
PNC.ProvisionScheduler.Queued = {}
local forced = {
    id = "npc_forced", alive = true,
    affiliation = { factionID = faction.id },
}
records[forced.id] = forced
candidates[forced.id] = { FOOD = {}, HYDRATION = {}, MEDICAL = {} }
local forcedCount, forcedResults =
    PNC.ProvisionScheduler.ReconcileRecord(forced)
T.equal(forcedCount, 3, "forced provision evaluates every configured rule")
T.equal(#forcedResults, 3, "forced provision returns one result per rule")
T.equal(forcedResults[1].ruleId, "food", "forced result identifies food rule")
T.equal(forcedResults[1].attempted, true,
    "forced result distinguishes an actual storage acquisition attempt")
T.equal(forcedResults[1].reason, "acquired",
    "forced result exposes the acquisition outcome")

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
T.equal(shortage.processed, 1, "storage shortage attempted once")
T.equal(PNC.ProvisionScheduler.Queue[1].readyAt, worldHour + 0.25,
    "storage shortage waits for supply retry deadline")
nowMs = 5005
PNC.ProvisionScheduler.Pump(nowMs)
T.equal(shortage.processed, 1, "retry deadline prevents query spam")

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
T.load(ROOT .. "server/PNC/Provision/PNC_ProvisionPolicyService.lua")

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
T.equal(ok, false, "other faction member cannot modify owner policy")
T.equal(reason, "not_faction_owner", "ownership rejection")
ok, reason = PNC.ProvisionPolicyService.Apply({
    key = "player:owner", factionID = faction.id,
}, submission)
T.equal(ok, true, "owner applies policy")
T.equal(faction.provision.revision, 2, "revision increments once")
T.equal(faction.provision.policies.default.bandage.target, 5,
    "authoritative policy persisted")
T.equal(saved, 1, "faction registry saved")

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
    RequestColonyManagement = function()
        return true, "snapshot_requested"
    end,
    RequestColonyAction = function(action, args)
        T.equal(action, "provision_set", "model submits colony action")
        T.truthy(args.submission.rules.dummy_radio,
            "dummy registry rule submitted without UI special case")
        return true, "sent"
    end,
}
local UIModel = T.load(ROOT
    .. "client/PNC/UI/Provision/PNC_ProvisionSettingsModel.lua")
local model = UIModel.New({ provision = faction.provision,
    policyId = "default", canEdit = true })
T.truthy(model:Get("dummy_radio"), "new registry rule appears in model")
model:Set("bandage", "target", 7)
T.equal(faction.provision.policies.default.bandage.target, 5,
    "working copy does not mutate authoritative policy")
model:ResetDefaults()
T.equal(model:Get("bandage").target, 3, "reset uses registry defaults")
ok = model:Submit()
T.equal(ok, true, "valid working copy submits")

local injectedSubmission
local injectedClient = {
    Submit = function(submission)
        injectedSubmission = submission
        return true, "injected"
    end,
}
local injectedModel = UIModel.New({ provision = faction.provision,
    policyId = "default", canEdit = true }, injectedClient)
injectedModel:Set("bandage", "target", 6)
ok, reason = injectedModel:Submit()
T.equal(ok, true, "injected client submits")
T.equal(reason, "injected", "injected client reason")
T.equal(injectedSubmission.rules.bandage.target, 6,
    "model passes validated submission to client boundary")

PNC.Network = { ClientState = {
    lastColonyManagementReceiveAt = 12,
    colonyManagement = {
        provisionSettings = { marker = "snapshot" },
        actionResult = { action = "provision_set", ok = true },
    },
} }
T.equal(PNC.ProvisionSettingsClient.CurrentSnapshot().marker, "snapshot",
    "client boundary current snapshot")
local update = PNC.ProvisionSettingsClient.ReadUpdate(11)
T.equal(update.receivedAt, 12, "client boundary receive time")
T.equal(update.result.action, "provision_set", "client boundary result")
T.equal(PNC.ProvisionSettingsClient.ReadUpdate(12), nil,
    "client boundary ignores stale state")
ok, reason = PNC.ProvisionSettingsClient.RequestSnapshot()
T.equal(ok, true, "client boundary requests snapshot")
T.equal(reason, "snapshot_requested", "client boundary snapshot reason")

local windowSource = T.read(
    "ProjectHoomans", "client", "PNC/UI/Provision/PNC_ProvisionSettingsWindow.lua"
)
T.equal(windowSource:find("PNC.Client.", 1, true), nil,
    "Provision window bypasses client boundary")
T.equal(windowSource:find("PNC.Network.ClientState", 1, true), nil,
    "Provision window reads raw network state")
T.truthy(windowSource:find("Client.ReadUpdate", 1, true),
    "Provision window consumes client update boundary")
T.finish("pnc_provision_smoke")

T.finish("pnc_provision_smoke")
