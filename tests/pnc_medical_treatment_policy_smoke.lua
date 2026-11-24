local T = require "tests/support/test"

local treatmentPath = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_Treatment.lua"
)

local now = 1000
local consumed = 0
local xpActor
local applied = {}
local treatmentDebugMessages = {}

local function deepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, entry in pairs(value) do
        output[deepCopy(key, seen)] = deepCopy(entry, seen)
    end
    return output
end

PNC = {
    Const = {
        BANDAGE_TYPE = "Base.Bandage",
        BANDAGE_TYPES = { "Base.Bandage" },
        ABSTRACT_MEDICAL_TREATMENT_TYPE = "PNC.AbstractMedical",
        ABSTRACT_MEDICAL_TREATMENT_NAME = "Abstract medical treatment",
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        DeepCopy = deepCopy,
        IsRecordDebugEnabled = function(record)
            return record and record.runtime
                and record.runtime.debug == true
        end,
        LogRecordDebug = function(_, message)
            treatmentDebugMessages[#treatmentDebugMessages + 1] = message
        end,
    },
    Types = {
        IsColonist = function(record)
            return record and record.tacticalClass == "colonist"
        end,
    },
    Inventory = {
        EnsureRecordInventory = function(record)
            return record.inventory
        end,
    },
    Skills = {
        GetLevel = function() return 4 end,
        AddXP = function(record)
            xpActor = record
        end,
    },
    Registry = {},
    NPCWounds = {
        Bandage = function(record, partId, _, options)
            applied[#applied + 1] = {
                actorTarget = record.id,
                partId = partId,
                bandageType = options.bandageType,
                firstAidLevel = options.firstAidLevel,
            }
            return true, "bandaged"
        end,
    },
    SupplyInventory = {
        Consume = function(record, itemID)
            local item = record.inventory.items[itemID]
            if not item then return false end
            local before = item.stack
            item.stack = before - 1
            consumed = consumed + 1
            return true, nil, {
                undo = function()
                    item.stack = before
                    consumed = consumed - 1
                    return true
                end,
            }
        end,
    },
}

T.load(treatmentPath)

local colonist = {
    id = "colonist-doctor",
    tacticalClass = "colonist",
    alive = true,
    inventory = { items = {
        bandage = { id = "bandage", type = "Base.Bandage", stack = 1 },
    } },
    runtime = { debug = true },
}
local neutralDoctor = {
    id = "neutral-doctor",
    tacticalClass = "neutral",
    alive = true,
    inventory = { items = {} },
    runtime = {},
}
local abstract = {
    id = "abstract-doctor",
    tacticalClass = "hostile",
    alive = true,
    inventory = { items = {} },
    runtime = {},
}
local patient = {
    id = "patient",
    tacticalClass = "colonist",
    alive = true,
    inventory = { items = {} },
    runtime = {},
}

T.truthy(PNC.Treatment.RequiresNPCMedicalItem(colonist),
    "colonist medical care requires a real item")
T.truthy(PNC.Treatment.RequiresNPCMedicalItem(neutralDoctor),
    "neutral NPCs now require a real medical item (no unlimited bandages)")
T.falsy(PNC.Treatment.RequiresNPCMedicalItem(abstract),
    "hostile abstract medical care does not require an item")
T.falsy(PNC.Treatment.RequiresNPCMedicalItem(neutralDoctor, { allowAbstract = true }),
    "explicit allowAbstract option permits abstract medical mode")
T.equal(PNC.Treatment.GetNPCBandagePlan(abstract).mode,
    "abstract", "abstract treatment plan mode")

local before = consumed
T.equal(PNC.Treatment.TryNPCBandage(colonist, "ForeArm_L"), true,
    "colonist self-treatment")
T.equal(consumed, before + 1,
    "colonist treatment consumed one actual bandage")
T.equal(colonist.inventory.items.bandage.stack, 0,
    "colonist bandage stack decremented")
T.equal(applied[1].bandageType, "Base.Bandage",
    "colonist wound retains actual bandage type")
T.contains(treatmentDebugMessages[1],
    "health.treatment event=apply_bandage route=npc_self")
T.contains(treatmentDebugMessages[2],
    "health.treatment event=complete route=npc_self")
T.contains(treatmentDebugMessages[2],
    "status=applied reason=bandaged")

local neutralApplied, neutralReason = PNC.Treatment.TryNPCBandage(neutralDoctor, "Hand_L")
T.falsy(neutralApplied, "neutral NPC with 0 bandages cannot use unlimited abstract bandages")
T.equal(neutralReason, "missing_bandage", "neutral empty inventory rejects with missing_bandage")

before = consumed
T.equal(PNC.Treatment.TryNPCBandage(abstract, "Hand_L"), true,
    "abstract self-treatment")
T.equal(consumed, before,
    "abstract treatment consumed no item")
T.equal(applied[2].bandageType, "PNC.AbstractMedical",
    "abstract wound records non-inventory treatment")

colonist.inventory.items.bandage.stack = 1
before = consumed
patient.runtime.debug = true
T.equal(PNC.Treatment.TryNPCMedicalTreatment(
    colonist, patient, "UpperArm_L"), true,
    "colonist doctor treats another NPC")
T.equal(consumed, before + 1,
    "colonist doctor consumed its own bandage")
T.equal(xpActor, colonist,
    "First Aid XP belongs to the doctor")
T.equal(applied[3].actorTarget, "patient",
    "doctor treatment applied to the patient")
T.contains(treatmentDebugMessages[#treatmentDebugMessages],
    "health.treatment event=complete route=npc_assist")
T.contains(treatmentDebugMessages[#treatmentDebugMessages],
    "actor=colonist-doctor target=patient")

before = consumed
T.equal(PNC.Treatment.TryNPCMedicalTreatment(
    abstract, patient, "UpperArm_R"), true,
    "abstract doctor treats a colonist patient")
T.equal(consumed, before,
    "abstract doctor did not consume the patient's item")
T.equal(applied[4].bandageType, "PNC.AbstractMedical",
    "abstract doctor treatment remains item-free")

local travelingSnapshot = PNC.Treatment.BuildMedicalCareSnapshot({
    runtime = {
        medicalCare = {
            phase = "traveling",
            taskId = "medical:travel",
            patientId = "patient",
        },
    },
})
T.equal(travelingSnapshot.phase, "traveling",
    "medical-care snapshot exposes the traveling phase")
T.equal(travelingSnapshot.patientId, "patient",
    "medical-care snapshot keeps its patient target")

local appliedCount = #applied
PNC.Core.IsAuthority = function() return false end
local rejectedBandage, rejectedBandageReason = PNC.Treatment.ApplyBandage(
    patient, "ForeArm_R", {})
T.equal(rejectedBandage, false,
    "direct bandage application rejects a non-authoritative caller")
T.equal(rejectedBandageReason, "not_authority",
    "direct bandage rejection has an explicit reason")
T.equal(#applied, appliedCount,
    "non-authoritative bandage does not mutate wound state")
T.contains(treatmentDebugMessages[#treatmentDebugMessages],
    "route=direct")
T.contains(treatmentDebugMessages[#treatmentDebugMessages],
    "status=rejected reason=not_authority")

PNC.Treatment.Internal.LogDebug(
    patient,
    "complete\n" .. string.rep("e", 100),
    "player",
    "rejected",
    "bad\nreason",
    { unsafe = true },
    "patient",
    "UpperArm_L",
    "Base.Bandage",
    "policy",
    4
)
local boundedMessage = treatmentDebugMessages[#treatmentDebugMessages]
T.contains(boundedMessage, "actor=unsupported")
T.contains(boundedMessage, "reason=bad reason")
T.truthy(not string.find(boundedMessage, "\n", 1, true),
    "treatment diagnostics strip control characters")
T.truthy(#boundedMessage < 700,
    "treatment diagnostic fields are length bounded")

do
    PNC.Core.IsAuthority = function() return true end
    local consumedKinds = {}
    local original = PNC.SupplyInventory.Consume
    PNC.SupplyInventory.Consume = function(actor, itemID, request)
        consumedKinds[#consumedKinds + 1] = request.treatment
        return original(actor, itemID, request)
    end
    local actor = {
        id = "fracture-patient", alive = true,
        health = { body = { wounds = { ForeArm_L = { type = "fracture" } } } },
        inventory = { items = {
            stick = { id = "stick", type = "Base.WoodenStick2", stack = 1 },
            rag = { id = "rag", type = "Base.RippedSheets", stack = 1 },
        } },
    }
    PNC.NPCWounds.Splint = function(_, part, _, options)
        T.equal(part, "ForeArm_L")
        T.equal(options.splintItem, "Base.WoodenStick2")
        T.equal(options.firstAidLevel, 4)
        return true, "splinted"
    end
    T.truthy(PNC.Treatment.TryNPCSplint(actor, "ForeArm_L"))
    T.equal(actor.inventory.items.stick.stack, 0)
    T.equal(actor.inventory.items.rag.stack, 0)
    T.equal(consumedKinds[1], "SPLINT")
    T.equal(consumedKinds[2], "SPLINT")
    PNC.SupplyInventory.Consume = original
end

do
    local received, broadcasts = {}, {}
    local position = 20
    patient.x, patient.y, patient.z = 0, 0, 0
    PNC.Registry.Get = function(id) return id == patient.id and patient or nil end
    PNC.Registry.GetLiveZombie = function() return nil end
    PNC.Core.DistanceSq = function(x1, y1, x2, y2)
        return (x1 - x2) ^ 2 + (y1 - y2) ^ 2
    end
    PNC.Network = { BroadcastRecord = function(_, event) broadcasts[#broadcasts + 1] = event end }
    local hasSplint = true
    PNC.NPCWounds.RemoveSplint = function(target, part)
        T.equal(target, patient)
        T.equal(part, "ForeArm_L")
        if not hasSplint then return false, "not_splinted" end
        hasSplint = false
        return true, "splint_removed", "Base.WoodenStick2", "Base.RippedSheets"
    end
    local inventory = { AddItem = function(_, fullType) received[#received + 1] = fullType end }
    local player = {
        getX = function() return position end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
        getInventory = function() return inventory end,
    }
    local permitted, reason = PNC.Treatment.TryBandage(player, patient.id, "ForeArm_L", { removeSplint = true })
    T.falsy(permitted)
    T.equal(reason, "too_far")
    T.equal(#received, 0)
    position = 1
    T.truthy(PNC.Treatment.TryBandage(player, patient.id, "ForeArm_L", { removeSplint = true }))
    T.equal(received[1], "Base.WoodenStick2")
    T.equal(received[2], "Base.RippedSheets")
    T.equal(broadcasts[1], "splint_removed")
    T.falsy(PNC.Treatment.TryBandage(player, patient.id, "ForeArm_L", { removeSplint = true }))
    T.equal(#received, 2)
    T.equal(#broadcasts, 1)
end

T.finish("pnc_medical_treatment_policy_smoke")
