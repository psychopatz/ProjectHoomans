local T = require "tests/support/test"
T.addPackagePaths()

local donor = {
    id = "aid-donor",
    alive = true,
    x = 10,
    y = 10,
    z = 0,
    inventory = { revision = 1, items = {
        bandage = { id = "bandage", type = "Base.Bandage", stack = 1 },
    } },
    social = {
        disposition = {
            compassion = 0.85,
            aggression = 0.15,
            loyalty = 0.8,
            materialism = 0.2,
        },
        demeanor = { scarcityAnxiety = 0.1 },
        relationship = { state = "friend", approval = 70, trust = 70 },
    },
    runtime = {},
}
local patient = {
    id = "aid-patient",
    alive = true,
    x = 11,
    y = 10,
    z = 0,
    inventory = { revision = 1, items = {} },
    wound = {
        type = "laceration",
        bandaged = false,
        bandageDirty = false,
        bleedingRate = 0.02,
        damage = 18,
    },
    runtime = { injuryRevision = 4 },
}

local authority = true
local failAdd = false
local isMedic = false
local firstAidLevel = 3
local treatmentCalls = {}
local materialized = 0
local broadcasts = 0

PNC = {
    Const = { BANDAGE_RANGE = 3 },
    Core = {
        IsAuthority = function() return authority end,
        Now = function() return 1000 end,
        DistanceSq = function(x1, y1, x2, y2)
            return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
        end,
    },
    Registry = {
        Get = function(id)
            if id == donor.id then return donor end
            if id == patient.id then return patient end
            return nil
        end,
        GetLiveZombie = function() return nil end,
    },
    NPCWounds = {
        FindTreatableWound = function(record)
            if not record.wound then return nil end
            return "ForeArm_L", record.wound
        end,
        GetTreatableWounds = function(record)
            if not record.wound then return {} end
            return { { partId = "ForeArm_L", wound = record.wound } }
        end,
    },
    Treatment = {
        GetNPCBandagePlan = function(record)
            local items = record.inventory and record.inventory.items or {}
            for itemID, item in pairs(items) do
                if item and item.stack ~= 0 and item.type == "Base.Bandage" then
                    return {
                        itemID = itemID,
                        fullType = item.type,
                        displayName = "Bandage",
                        requiresItem = true,
                    }
                end
            end
            return nil
        end,
        IsBandageType = function(fullType)
            return fullType == "Base.Bandage"
        end,
        GetNPCFirstAidLevel = function() return firstAidLevel end,
        TryNPCMedicalTreatment = function(helper, injured, partID, options)
            treatmentCalls[#treatmentCalls + 1] = {
                helperID = helper.id,
                injuredID = injured.id,
                partID = partID,
                options = options,
            }
            helper.inventory.items[options.bandageType == "Base.Bandage"
                and "bandage" or ""] = nil
            injured.wound = nil
            return true, "bandaged"
        end,
    },
    ConvoEngine = {
        DispositionProjection = {
            Resolve = function(actor)
                return {
                    effectiveDisposition = actor.social.disposition,
                    temporaryDemeanor = actor.social.demeanor,
                }
            end,
        },
        InteractionActorAdapterProjectHoomans = {
            ProjectRelationship = function(actor)
                return actor.social.relationship
            end,
        },
    },
    MedicalCareExecutor = {
        IsDoctor = function() return isMedic end,
        Internal = {
            InTreatmentRange = function(helper, _, injured)
                local dx = helper.x - injured.x
                local dy = helper.y - injured.y
                return helper.z == injured.z and dx * dx + dy * dy <= 9
            end,
        },
    },
    Inventory = {
        EnsureRecordInventory = function(record) return record.inventory end,
        CanAccept = function() return true end,
        AddItems = function(record, specs)
            if failAdd then return false, "recipient_inventory_rejected" end
            local item = {}
            for key, value in pairs(specs[1]) do item[key] = value end
            item.id = "patient-bandage-" .. tostring(record.inventory.revision + 1)
            record.inventory.items[item.id] = item
            record.inventory.revision = record.inventory.revision + 1
            return true, "added", { item.id }
        end,
        RemoveItems = function(record, itemIDs)
            for _, itemID in ipairs(itemIDs) do
                record.inventory.items[itemID] = nil
            end
            record.inventory.revision = record.inventory.revision + 1
            return true
        end,
        MaterializeItem = function()
            materialized = materialized + 1
            return true
        end,
    },
    SupplyInventory = {
        Consume = function(record, itemID)
            local item = record.inventory.items[tostring(itemID)]
            if not item then return false, "donor_bandage_unavailable" end
            record.inventory.items[tostring(itemID)] = nil
            record.inventory.revision = record.inventory.revision + 1
            return true, nil, {
                undo = function()
                    record.inventory.items[tostring(itemID)] = item
                    record.inventory.revision = record.inventory.revision + 1
                    return true
                end,
            }
        end,
    },
    Network = {
        BroadcastRecord = function() broadcasts = broadcasts + 1 end,
    },
    NeedFacilityAwayRoutes = {
        IsCombatActive = function() return false end,
    },
}

T.load("ProjectHoomans", "server", "PNC/Server/ServerInventory/PNC_ServerInventory_MedicalSupply.lua")
T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticInjuryAid.lua")

local Aid = PNC.Semantics.InjuryAid
local transferOffer, offerReason, transferInspection = Aid.Offer(donor, patient, {
    action = "transfer_bandage",
})
T.truthy(transferOffer, "eligible helper receives a server aid offer")
T.equal(offerReason, nil, "eligible aid offer has no failure reason")
T.equal(transferInspection.inventory.hasBandage, true,
    "inspection reads helper's live physical bandage")
T.equal(transferInspection.reachability.reachable, true,
    "inspection checks same-floor treatment range")
T.equal(transferInspection.social.policy, "supportive",
    "relationship and resolved disposition select supportive policy")
T.equal(transferOffer.action, "bandage_transfer",
    "patient without supplies receives an explicit transfer action")

local transferred, transferReason, transferResult = Aid.Execute(
    donor, patient, transferOffer)
T.equal(transferred, true, "accepted NPC aid transfers a real bandage")
T.equal(transferReason, "bandage_gifted", "transfer returns authoritative result")
T.truthy(transferResult.transfer.itemID, "transfer returns compact patient item ID")
T.equal(donor.inventory.items.bandage, nil, "transfer consumes donor inventory item")
T.equal(next(patient.inventory.items) ~= nil, true,
    "transfer adds item to patient compact inventory")
T.equal(broadcasts, 2, "server broadcasts donor and patient changes")

donor.inventory.items.bandage = { id = "bandage", type = "Base.Bandage", stack = 1 }
patient.inventory.items = {}
patient.inventory.revision = 3
failAdd = true
local rollbackOffer = Aid.Offer(donor, patient, { action = "transfer_bandage" })
local rolledBack, rollbackReason = Aid.Execute(donor, patient, rollbackOffer)
T.equal(rolledBack, false, "failed compact recipient add rejects transfer")
T.equal(rollbackReason, "recipient_inventory_rejected",
    "failed transfer returns compact inventory reason")
T.truthy(donor.inventory.items.bandage,
    "failed transfer restores donor item through consume undo")
T.equal(next(patient.inventory.items), nil,
    "failed transfer leaves patient inventory unchanged")
failAdd = false

local directOffer = Aid.Offer(donor, patient, { action = "treat" })
T.equal(directOffer.action, "npc_bandage",
    "direct treatment remains a distinct accepted aid action")
local treated, treatmentReason = Aid.Execute(donor, patient, directOffer)
T.equal(treated, true, "direct treatment delegates to NPC treatment authority")
T.equal(treatmentReason, "bandaged", "direct treatment returns treatment result")
T.equal(treatmentCalls[#treatmentCalls].partID, "ForeArm_L",
    "treatment uses the currently selected treatable wound")
T.equal(treatmentCalls[#treatmentCalls].options.consumeItem, true,
    "direct treatment requires actual item consumption")

patient.wound = {
    type = "laceration", bandaged = false, bleedingRate = 0.01, damage = 10,
}
donor.inventory.items.bandage = { id = "bandage", type = "Base.Bandage", stack = 1 }
local staleOffer = Aid.Offer(donor, patient, { action = "transfer_bandage" })
donor.inventory.items.bandage = nil
local stale, staleReason = Aid.Execute(donor, patient, staleOffer)
T.equal(stale, false, "execution revalidates the live item")
T.equal(staleReason, "missing_bandage", "stale item is rejected truthfully")

donor.inventory.items.bandage = { id = "bandage", type = "Base.Bandage", stack = 1 }
patient.x = 20
local far = Aid.Inspect(donor, patient, { action = "transfer_bandage" })
T.equal(far.reachability.reachable, false, "inspection rejects unreachable aid")
T.equal(far.reason, "out_of_range", "unreachable reason is explicit")
patient.x = 11

donor.social.relationship = { state = "enemy", approval = -80, trust = -50 }
local refused, refusedReason, refusalInspection = Aid.Offer(
    donor, patient, { action = "transfer_bandage" })
T.equal(refused, nil, "hostile helper does not receive an aid offer")
T.equal(refusedReason, "aid_refused", "social refusal has an explicit reason")
T.equal(refusalInspection.outcome, "refuse",
    "inspection exposes a context-derived refusal outcome")

donor.social.relationship = { state = "neutral", approval = 0, trust = 0 }
donor.social.disposition = {
    compassion = 0.50, aggression = 0.20, loyalty = 0.40, materialism = 0.55,
}
donor.social.demeanor = { scarcityAnxiety = 0.60 }
firstAidLevel = 0
local scarcity = Aid.Inspect(donor, patient, { action = "transfer_bandage" })
T.equal(scarcity.inventory.bandageCount, 1,
    "inspection reports current physical bandage stock")
T.equal(scarcity.social.policy, "disappointed",
    "stock scarcity and materialism affect the social policy")
T.equal(scarcity.outcome, "refuse",
    "scarcity can produce a distinct refusal outcome")

donor.social.disposition.compassion = 0.30
donor.social.demeanor.scarcityAnxiety = 0.10
firstAidLevel = 4
isMedic = true
local clinical = Aid.Inspect(donor, patient, { action = "transfer_bandage" })
T.equal(clinical.social.policy, "clinical",
    "medical role and skill select a distinct clinical policy")
T.equal(clinical.social.role, "medic", "inspection exposes medical role")

authority = false
local unauthorized = Aid.Inspect(donor, patient)
T.equal(unauthorized.reason, "not_authority",
    "inspection is server-authority gated")
local unauthorizedExecution, unauthorizedReason = Aid.Execute(donor, patient, {})
T.equal(unauthorizedExecution, false, "execution is server-authority gated")
T.equal(unauthorizedReason, "not_authority", "unauthorized execution reason is explicit")

T.finish("pnc_semantic_injury_aid_smoke")
