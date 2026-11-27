local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 50000
local ripRequests = {}
local emittedBeats = {}
local fulfilledTasks = {}

local rescuer = {
    id = "npc_rescuer",
    name = "Elton",
    alive = true,
    presenceState = "live",
    identitySeed = 11,
    inventory = { items = {} },
    runtime = {},
}

local patient = {
    id = "npc_downed",
    name = "Tod",
    alive = true,
    presenceState = "live",
    identitySeed = 22,
    health = {
        state = "incapacitated",
        body = {
            wounds = {
                Torso_Upper = { type = "burn", burned = true, severity = 18 },
            },
        },
    },
    runtime = {},
}

local task = {
    id = "med_task_1",
    status = "WAITING_FOR_SUPPLY",
    supplyRequesterId = "npc_rescuer",
    supplyRequestId = "medical-bandage:med_task_1:1",
    revision = 1,
    policy = { requireItem = true },
}

PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Core = { Now = function() return nowMs end },
    Registry = {
        Get = function(id)
            if tostring(id) == "npc_rescuer" then return rescuer end
            if tostring(id) == "npc_downed" then return patient end
            return nil
        end,
        ForEach = function(fn) fn(rescuer); fn(patient) end,
        MarkDirty = function() end,
    },
    Treatment = {
        GetNPCBandagePlan = function() return nil end,
        RequiresNPCMedicalItem = function() return true end,
        IsBandageType = function(t) return t == "Base.RippedSheets" end,
    },
    NPCWounds = {
        Parts = { Torso_Upper = { id = "Torso_Upper", label = "Upper Torso" } },
        FindTreatableWound = function() return nil end,
    },
    WorldItemService = {
        RequestBandageRip = function(rec, opts)
            ripRequests[#ripRequests + 1] = { npcId = rec.id, opts = opts }
            return true, "queued", { id = "wi:1", medicalTaskId = opts.medicalTaskId }
        end,
    },
    Semantics = {
        DialogueBeats = {
            _hooks = {},
            RegisterHook = function(id, spec)
                PNC.Semantics.DialogueBeats._hooks[id] = spec
            end,
            Emit = function(eventName, payload, at)
                emittedBeats[#emittedBeats + 1] = { event = eventName, payload = payload, at = at }
                return true, eventName
            end,
        },
    },
    MedicalCareExecutor = {
        Internal = {
            Service = {
                Get = function(id) return id == task.id and task or nil end,
                SetPhase = function() return true end,
                Complete = function() return true end,
            },
            Status = {
                WAITING_FOR_SUPPLY = "WAITING_FOR_SUPPLY",
                WAITING_FOR_DOCTOR = "WAITING_FOR_DOCTOR",
            },
            Registry = nil,
            Treatment = nil,
            combatActive = function() return false end,
            groupDoctors = function() return { rescuer } end,
            requesterForTask = function() return rescuer end,
            Patient = function() return patient end,
            CurrentPart = function() return "Torso_Upper" end,
            SameCareGroup = function() return true end,
            sendSupplyState = function() return true end,
            LastSupplyAttemptAt = {},
            SUPPLY_RETRY_MS = 2000,
        },
    },
}
PNC.MedicalCareExecutor.Internal.Registry = PNC.Registry
PNC.MedicalCareExecutor.Internal.Treatment = PNC.Treatment

T.load("ProjectHoomans", "server", "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_SupplyActions.lua")
T.load("ProjectHoomans", "server", "PNC/Semantics/Beats/PNC_SemanticBeats_MedicalRescue.lua")

-- 1. RequestBandageSupport dispatches urgent corpse-rip and emits scavenge_rags beat.
local ok, status = PNC.MedicalCareExecutor.RequestBandageSupport(task.id)
T.truthy(ok, "RequestBandageSupport should succeed when corpse-rip is dispatched")
T.equal(status, "ripping_bandage", "expected ripping_bandage status")
T.equal(#ripRequests, 1, "expected 1 RequestBandageRip call")
T.equal(ripRequests[1].npcId, "npc_rescuer", "wrong rescuer dispatched for rag rip")
T.equal(ripRequests[1].opts.medicalTaskId, task.id, "medicalTaskId was not attached to rip request")
T.truthy(ripRequests[1].opts.urgent, "rescue rag rip should be urgent")
T.equal(#emittedBeats, 1, "expected scavenge_rags beat to fire")
T.equal(emittedBeats[1].event, "medical_rescue.scavenge_rags", "wrong beat event")

-- 2. Verify all 3 MedicalRescue beat hooks build two-way contextual plans (burn-aware).
local hooks = PNC.Semantics.DialogueBeats._hooks
local scavPlan = hooks["medical_rescue.scavenge_rags"].evaluate("medical_rescue.scavenge_rags", {
    rescuer = rescuer, patient = patient, taskId = task.id, now = nowMs,
})
T.equal(scavPlan.opening.speaker.id, "npc_rescuer", "rescuer should open scavenge_rags")
T.equal(scavPlan.replies[1].speaker.id, "npc_downed", "incapacitated teammate should reply to scavenge_rags")

local burnPlan = hooks["medical_rescue.approach"].evaluate("medical_rescue.approach", {
    rescuer = rescuer, patient = patient, partId = "Torso_Upper", now = nowMs,
})
T.equal(burnPlan.opening.role, "approach_burn_open", "burn-wounded patient should select burn-aware approach line")
T.equal(burnPlan.replies[1].speaker.id, "npc_downed", "patient should reply to approach beat")

local stabPlan = hooks["medical_rescue.stabilized"].evaluate("medical_rescue.stabilized", {
    rescuer = rescuer, patient = patient, partId = "Torso_Upper", now = nowMs,
})
T.equal(stabPlan.opening.speaker.id, "npc_rescuer", "rescuer should open stabilized beat")
T.equal(stabPlan.replies[1].speaker.id, "npc_downed", "patient should thank rescuer in stabilized beat")

-- 3. CommitAction for rip_bandage with medicalTaskId immediately wakes up FulfillBandageSupport.
PNC.MedicalCareExecutor.FulfillBandageSupport = function(taskId)
    fulfilledTasks[#fulfilledTasks + 1] = taskId
    return true
end
PNC.Inventory = {
    AddItems = function() return true, "ok", { "item_1" } end,
}
PNC.WorldItemExecutor = { Internal = { IsCandidateStillValid = function() return true end } }
T.load("ProjectHoomans", "server", "PNC/WorldItems/PNC_WorldItemExecutor_Commit.lua")

local commitOk = PNC.WorldItemExecutor.Internal.CommitAction({
    action = "rip_bandage",
    collectedCount = 0,
    medicalTaskId = task.id,
    candidate = {
        sourceType = "corpse",
        container = { DoRemoveItem = function() end },
        item = {},
        itemCtx = { rippable = { outputType = "Base.RippedSheets", outputCount = 2 } },
    },
}, rescuer, nil)
T.truthy(commitOk, "CommitAction for rip_bandage failed")
T.equal(#fulfilledTasks, 1, "CommitAction did not wake up FulfillBandageSupport")
T.equal(fulfilledTasks[1], task.id, "wrong taskId passed to FulfillBandageSupport")

-- 4. Verify no_rags_notice beat (with partner reply) and rip hand-prop + RestoreRipHandProp.
local noRagsPlan = hooks["medical_rescue.no_rags_notice"].evaluate("medical_rescue.no_rags_notice", {
    speaker = rescuer, partner = patient, now = nowMs,
})
T.equal(noRagsPlan.opening.role, "no_rags_notice", "no_rags_notice opening role mismatch")
T.equal(noRagsPlan.replies[1].role, "no_rags_reply", "no_rags_notice reply role mismatch")

PNC.WorldItemContext = { Zones = { IsRestrictedSquare = function() return false end } }
PNC.AnimationScenes = {
    _requested = {},
    _options = {},
    Request = function(rec, body, sceneId, opts)
        PNC.AnimationScenes._requested[#PNC.AnimationScenes._requested + 1] = sceneId
        PNC.AnimationScenes._options[#PNC.AnimationScenes._options + 1] = opts
    end,
}
T.load("ProjectHoomans", "server", "PNC/WorldItems/PNC_WorldItemExecutor_Actions.lua")

local prevWeapon = { _type = "Base.Crowbar" }
local handState = { primary = prevWeapon, secondary = nil }
local mockBody = {
    getPrimaryHandItem = function() return handState.primary end,
    getSecondaryHandItem = function() return handState.secondary end,
    setPrimaryHandItem = function(_, item) handState.primary = item end,
    setSecondaryHandItem = function(_, item) handState.secondary = item end,
    faceLocation = function() end,
}
local ripIntent = {
    npcId = rescuer.id,
    action = "rip_bandage",
    purpose = "wounded_no_bandage",
    candidate = { x = 10, y = 10, z = 0, sourceType = "corpse", itemCtx = { fullType = "Base.Tshirt_DefaultTEXTURE" } },
}
PNC.WorldItemExecutor.Internal.BeginInteract(ripIntent, rescuer, mockBody, nowMs)
local lastOpts = PNC.AnimationScenes._options[#PNC.AnimationScenes._options]
T.equal(PNC.AnimationScenes._requested[#PNC.AnimationScenes._requested], "scavenge.rip", "scavenge.rip scene was not requested")
T.equal(lastOpts and lastOpts.propSecondary, "Base.Tshirt_DefaultTEXTURE", "actual clothing item was not passed as secondary ActionProp while ripping")
T.equal(handState.primary, prevWeapon, "persistent primary hand weapon should not be mutated by rip action prop")

PNC.WorldItemExecutor.Internal.RestoreRipHandProp(ripIntent, rescuer, mockBody)
T.equal(rescuer.runtime and rescuer.runtime.sceneActionProps, nil, "sceneActionProps was not cleared after ripping")

-- 5. Dedicated curtain & drawer beats + curtain removal via CommitAction + base-zone guard.
local curtainBeat = hooks["medical_rescue.no_rags_notice"].evaluate("medical_rescue.no_rags_notice", {
    speaker = rescuer, partner = patient, sourceType = "curtain", now = nowMs,
})
T.equal(curtainBeat.opening.role, "no_rags_curtain", "curtain sourceType should select no_rags_curtain beat")

local drawerBeat = hooks["medical_rescue.no_rags_notice"].evaluate("medical_rescue.no_rags_notice", {
    speaker = rescuer, partner = patient, sourceType = "container", now = nowMs,
})
T.equal(drawerBeat.opening.role, "no_rags_drawer", "container sourceType should select no_rags_drawer beat")

local curtainRescue = hooks["medical_rescue.scavenge_rags"].evaluate("medical_rescue.scavenge_rags", {
    rescuer = rescuer, patient = patient, sourceType = "curtain", taskId = task.id, now = nowMs,
})
T.equal(curtainRescue.opening.role, "scavenge_curtain_open", "curtain rescue should select scavenge_curtain_open")

local drawerRescue = hooks["medical_rescue.scavenge_rags"].evaluate("medical_rescue.scavenge_rags", {
    rescuer = rescuer, patient = patient, sourceType = "container", taskId = task.id, now = nowMs,
})
T.equal(drawerRescue.opening.role, "scavenge_drawer_open", "drawer rescue should select scavenge_drawer_open")

local curtainRemoved = false
local curtainObj = { isCurtain = true }
local curtainSq = {
    getObjects = function() return { curtainObj } end,
    transmitRemoveItemFromSquare = function(_, obj)
        if obj == curtainObj then curtainRemoved = true end
    end,
}
local curtainCommitOk = PNC.WorldItemExecutor.Internal.CommitAction({
    action = "rip_bandage",
    collectedCount = 0,
    candidate = {
        sourceType = "curtain",
        square = curtainSq,
        object = curtainObj,
        item = curtainObj,
        itemCtx = { fullType = "Base.Sheet", rippable = { outputType = "Base.RippedSheets", outputCount = 4 } },
    },
}, rescuer, nil)
T.truthy(curtainCommitOk, "CommitAction for curtain rip failed")
T.truthy(curtainRemoved, "curtain was not removed from square via transmitRemoveItemFromSquare")

-- Base-zone restriction check on IsCandidateStillValid.
PNC.WorldItemContext.Zones.IsRestrictedSquare = function() return true end
local validInBase, baseReason = PNC.WorldItemExecutor.Internal.IsCandidateStillValid({
    allowRestrictedZones = false,
    candidate = { sourceType = "curtain", square = curtainSq, object = curtainObj, item = curtainObj, x = 10, y = 10, z = 0 },
})
T.falsy(validInBase, "curtain inside restricted base zone should be rejected")
T.equal(baseReason, "restricted_zone", "expected restricted_zone rejection reason")

-- 6. Fundamental cross-NPC care-group & incapacitated rescue eligibility (mobile groups, DT caravans, non-doctors).
PNC.MedicalCareService = {}
PNC.MedicalCareRepository = { STATUS = {} }
PNC.WorkPolicy = { IsEnabled = function() return true end }
PNC.MedicalCareExecutor = { Internal = {} }
PNC.Treatment.GetNPCFirstAidLevel = function() return 0 end
T.load("ProjectHoomans", "server", "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_Core.lua")

local caravanRescuer = { id = "dt_1", alive = true, mobileGroupId = "caravan_alpha", archetypeID = "scavenger" }
local caravanDowned = { id = "dt_2", alive = true, mobileGroupId = "caravan_alpha", health = { state = "incapacitated" } }
local stranger = { id = "stranger_1", alive = true, mobileGroupId = "other_group" }

T.truthy(PNC.MedicalCareExecutor.SameCareGroup(caravanRescuer, caravanDowned),
    "mobile-group / caravan teammates must share a care group")
T.truthy(PNC.MedicalCareExecutor.CanAssistPatient(caravanRescuer, caravanDowned, "npc"),
    "non-doctor mobile-group teammate must be allowed to rescue incapacitated teammate")
T.falsy(PNC.MedicalCareExecutor.SameCareGroup(stranger, caravanDowned),
    "unrelated stranger from another group must not match care group")

T.finish("pnc_medical_rescue_rip_and_beats_smoke")
