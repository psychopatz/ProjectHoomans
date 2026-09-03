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
    runtime = {},
}
local abstract = {
    id = "abstract-doctor",
    tacticalClass = "neutral",
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
T.falsy(PNC.Treatment.RequiresNPCMedicalItem(abstract),
    "abstract medical care does not require an item")
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

before = consumed
T.equal(PNC.Treatment.TryNPCBandage(abstract, "Hand_L"), true,
    "abstract self-treatment")
T.equal(consumed, before,
    "abstract treatment consumed no item")
T.equal(applied[2].bandageType, "PNC.AbstractMedical",
    "abstract wound records non-inventory treatment")

colonist.inventory.items.bandage.stack = 1
before = consumed
T.equal(PNC.Treatment.TryNPCMedicalTreatment(
    colonist, patient, "UpperArm_L"), true,
    "colonist doctor treats another NPC")
T.equal(consumed, before + 1,
    "colonist doctor consumed its own bandage")
T.equal(xpActor, colonist,
    "First Aid XP belongs to the doctor")
T.equal(applied[3].actorTarget, "patient",
    "doctor treatment applied to the patient")

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

T.finish("pnc_medical_treatment_policy_smoke")
