local T = require "tests/support/test"
T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "common_lua" },
})

isServer = function() return true end
isClient = function() return false end
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

local worldHours, nowMs = 200.0, 50000
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHours end,
        getWorldAgeDaysSinceBegin = function() return worldHours / 24 end,
        getMinutesPerDay = function() return 60 end,
    }
end

local records, bodies = {}, {}
local tasks, leases = {}, {}
local deliveredSpeech, appliedPlayerBandages, syncBodyPartCalls = {}, {}, {}
local medicalRequests = {}
local taskSeq, nextItemId = 0, 1

syncBodyPart = function(part, mask)
    syncBodyPartCalls[#syncBodyPartCalls + 1] = { part = part, mask = mask }
end

local function makeBody(x, y, z)
    local b = { x = x, y = y, z = z, vars = {}, modData = {}, anim = nil }
    function b:getX() return self.x end
    function b:getY() return self.y end
    function b:getZ() return self.z end
    function b:setVariable(k, v) self.vars[k] = v end
    function b:getModData() return self.modData end
    function b:faceThisObject(t) self.facing = t end
    function b:getEmitter() return { playSound = function(_, s) self.lastSound = s end } end
    return b
end

local playerObj = {
    _x = 12, _y = 10, _z = 0, _dead = false,
    _parts = {},
    getX = function(self) return self._x end,
    getY = function(self) return self._y end,
    getZ = function(self) return self._z end,
    isDead = function(self) return self._dead end,
    getOnlineID = function() return 11 end,
    getUsername = function() return "SurvivorOne" end,
    getDescriptor = function() return { getForename = function() return "Morgan" end } end,
    getBodyDamage = function(self)
        return {
            getBodyParts = function()
                return {
                    size = function() return #self._parts end,
                    get = function(_, i) return self._parts[i + 1] end,
                }
            end,
            SetBandaged = function(_, idx, bandaged, life, sterile, bType)
                local p = self._parts[idx + 1]
                p._bandaged = bandaged
                p._dirty = false
                p._life = life
                p._sterile = sterile
                p._bType = bType
                appliedPlayerBandages[#appliedPlayerBandages + 1] = { idx = idx, life = life, bType = bType }
            end,
        }
    end,
}

PNC = {
    Const = {
        BANDAGE_RANGE = 3,
        BANDAGE_TYPES = { "Base.AlcoholBandage", "Base.Bandage", "Base.RippedSheets", "Base.BandageDirty", "Base.RippedSheetsDirty" },
        TACTICAL_CLASS_COLONIST = "colonist",
        TACTICAL_CLASS_HOSTILE = "hostile",
        PRESENCE_LIVE = "live",
        MEDICAL_CARE_COMPANION_MIN_FIRST_AID = 3,
    },
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return true end,
        IsClientOnly = function() return false end,
        Clamp = function(v, lo, hi) v = tonumber(v) or lo; return math.max(lo, math.min(hi, v)) end,
        DeepCopy = function(v)
            if type(v) ~= "table" then return v end
            local o = {}; for k, c in pairs(v) do o[k] = PNC.Core.DeepCopy(c) end; return o
        end,
        DistanceSq = function(x1, y1, x2, y2) return (x1 - x2) ^ 2 + (y1 - y2) ^ 2 end,
        ForEachPlayer = function(cb) cb(playerObj) end,
    },
    PlayerCharacters = { GetEntityKey = function() return "player:local" end },
    Types = { IsColonist = function(r) return r and r.tacticalClass == "colonist" end },
    Skills = {
        GetLevel = function(r) return r and r.skills and tonumber(r.skills.FirstAid) or 0 end,
        AddXP = function(r, _, xp) r.xpGained = (r.xpGained or 0) + xp end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        ForEach = function(cb) for _, r in pairs(records) do cb(r) end end,
        GetLiveZombie = function(id) return bodies[tostring(id)] end,
        MarkDirty = function() end,
    },
    Perception = { CanSeeWorldObject = function() return true end },
    Inventory = {
        EnsureRecordInventory = function(r)
            r.inventory = r.inventory or { revision = 1, items = {} }
            r.inventory.items = r.inventory.items or {}
            return r.inventory
        end,
        AddItems = function(r, specs)
            local ids = {}
            r.inventory = r.inventory or { revision = 1, items = {} }
            for _, sp in ipairs(specs or {}) do
                local id = "itm-" .. tostring(nextItemId); nextItemId = nextItemId + 1
                r.inventory.items[id] = { id = id, type = sp.type, stack = sp.stack or 1 }
                ids[#ids + 1] = id
            end
            return true, "added", ids
        end,
        ApplyDelta = function(r, ops)
            for _, op in ipairs(ops or {}) do
                if op.op == "remove" then r.inventory.items[op.itemID] = nil
                elseif op.op == "update" and r.inventory.items[op.itemID] then
                    r.inventory.items[op.itemID].stack = op.stack
                end
            end
            return true
        end,
    },
    Network = {
        BroadcastRecord = function() end,
        SendConversationRelationshipForNPC = function(_, npcId, ev, payload)
            deliveredSpeech[#deliveredSpeech + 1] = {
                npcId = npcId, eventType = ev, text = payload.ambientFlavor and payload.ambientFlavor.text,
                speechEventID = payload.ambientFlavor and payload.ambientFlavor.speechEventID,
            }
            return true
        end,
    },
    BehaviorCommon = {
        HaltMovement = function() end,
        MoveRecord = function(rec, b, tx, ty, tz)
            b.x, b.y, b.z = tx, ty, tz; rec.x, rec.y, rec.z = tx, ty, tz
            return true, "moved"
        end,
    },
    Animation = {
        PlayBump = function(b, _, bump) b.anim = bump; return true end,
        MaintainBump = function() end,
        FinishBump = function(b) b.animFinished = true end,
    },
    TaskLeaseService = { SetPhase = function(id, p) if leases[id] then leases[id].phase = p end end },
    Tasking = {
        Commands = {
            RegisterProvider = function() return true end,
            Complete = function(id) leases[id] = nil; return true end,
            CancelForNPC = function(npcId) for k, l in pairs(leases) do if l.npcId == npcId then leases[k] = nil end end end,
        },
        Events = { Emit = function() end },
    },
    Health = {
        Ensure = function(r) r.health = r.health or { current = 100, max = 100, state = "normal" }; return r.health end,
        ApplyDamage = function(r, _, d) r.health.current = math.max(10, (r.health.current or 100) - (d.amount or 0)); return true, r.health.current end,
    },
}

require "PsychopatzCore/Semantics/PsychopatzSemantic"
require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
require "PNC/ConvoEngine/SpeechRealization"
require "PNC/ConvoEngine/Social/Reaction"
require("PNC/ConvoEngine/ConvoDSL/ConvoDSL").EnsureActiveLanguage()
require "PNC/Semantics/PNC_SemanticSpeechTransport"

local Wounds = require "PNC/Core/Health/PNC_NPCWounds"
local Treatment = require "PNC/Core/Health/PNC_Treatment"
local Status = {
    QUEUED = "QUEUED", WAITING_FOR_DOCTOR = "WAITING_FOR_DOCTOR", WAITING_FOR_SUPPLY = "WAITING_FOR_SUPPLY",
    CLAIMED = "CLAIMED", TRAVELING = "TRAVELING", AT_PATIENT = "AT_PATIENT", TREATING = "TREATING",
    COMPLETED = "COMPLETED", CANCELLED = "CANCELLED", FAILED = "FAILED", QUARANTINED = "QUARANTINED",
}
PNC.MedicalCareRepository = { STATUS = Status, TERMINAL = { COMPLETED = true, CANCELLED = true, FAILED = true, QUARANTINED = true } }
PNC.MedicalCareService = {
    STATUS = Status,
    TERMINAL = PNC.MedicalCareRepository.TERMINAL,
    RequestNPC = function(r, opts)
        medicalRequests[#medicalRequests + 1] = { kind = "npc", id = r.id, source = opts and opts.source }
        return { id = "t-npc" }, "created"
    end,
    RequestPlayer = function(key, opts)
        taskSeq = taskSeq + 1
        local t = { id = "t-pl-" .. tostring(taskSeq), patientKind = "player", patientId = key, status = Status.WAITING_FOR_DOCTOR,
            phase = Status.WAITING_FOR_DOCTOR, priority = 50, retryAt = 0, revision = 1, createdAt = nowMs,
            lastProgressAt = nowMs, source = opts.source, policy = opts.policy }
        tasks[t.id] = t
        return t, "created"
    end,
    FindForPatient = function(kind, pid)
        for _, t in pairs(tasks) do if t.patientKind == kind and t.patientId == pid and not PNC.MedicalCareService.TERMINAL[t.status] then return t end end
    end,
    ResolveForPatient = function(kind, pid, rsn)
        local t = PNC.MedicalCareService.FindForPatient(kind, pid)
        if t then t.status, t.phase, t.completionReason = Status.COMPLETED, Status.COMPLETED, rsn; return true end
        return false
    end,
    Get = function(id) return tasks[tostring(id)] end,
    List = function() local o = {}; for _, t in pairs(tasks) do if not PNC.MedicalCareService.TERMINAL[t.status] then o[#o + 1] = t end end; return o end,
    SetPhase = function(id, ph, o) local t = tasks[id]; if t then t.status, t.phase = ph, ph; if o and o.actorId then t.actorId = o.actorId end; return true end end,
    MarkProgress = function() return true end,
    Complete = function(id, r) local t = tasks[id]; if t then t.status, t.phase, t.completionReason = Status.COMPLETED, Status.COMPLETED, r; return true end end,
    Cancel = function(id) local t = tasks[id]; if t then t.status, t.phase = Status.CANCELLED, Status.CANCELLED; return true end end,
    Requeue = function(id) local t = tasks[id]; if t then t.status, t.phase, t.actorId = Status.WAITING_FOR_DOCTOR, Status.WAITING_FOR_DOCTOR, nil; return true end end,
}

package.loaded["PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"] = {
    IsEnabled = function() return true end,
    GetPriority = function() return 50 end,
}
PNC.MedicalCareExecutor = { Internal = {} }
local Executor = require "PNC/Medical/PNC_MedicalCareExecutor"

-- 1. Dirty bandage on splinted fracture is treatable, requests MedicalCare on dirty transition, and healed dressing can be removed.
do
    local frac = { id = "npc-frac", name = "Evan", alive = true, x = 10, y = 10, z = 0, tacticalClass = "colonist",
        inventory = { items = { b1 = { id = "b1", type = "Base.Bandage", stack = 2 } } }, runtime = {} }
    Wounds.Ensure(frac)
    frac.health.body.wounds.LowerLeg_L = { partId = "LowerLeg_L", type = "fracture", fractured = true, splinted = true,
        bandaged = true, bandageDirty = true, damage = 20, severity = 20 }
    T.equal(select(1, Wounds.FindTreatableWound(frac)), "LowerLeg_L", "dirty bandage on splinted fracture is still treatable")

    local swap = { id = "npc-swap", name = "Dana", alive = true, x = 10, y = 10, z = 0, tacticalClass = "colonist",
        inventory = { items = { b1 = { id = "b1", type = "Base.Bandage", stack = 1 } } }, runtime = {} }
    Wounds.Ensure(swap)
    Wounds.ApplyCombatDamage(swap, nil, { amount = 10, partId = "ForeArm_L", woundType = "laceration", attackerKind = "npc" })
    Wounds.Bandage(swap, "ForeArm_L", nowMs, { bandageType = "Base.Bandage", dirtyAfterWorldHours = 1.0 })
    medicalRequests = {}
    worldHours = worldHours + 2.0
    Wounds.Update(swap, nil, nowMs + 2000)
    T.truthy(#medicalRequests >= 1 and medicalRequests[#medicalRequests].source == "bandage_dirty",
        "dirty bandage transition submits MedicalCare request")
    T.truthy(Treatment.TryNPCBandage(swap, "ForeArm_L"), "NPC replaces own dirty bandage")
    T.equal(swap.health.body.wounds.ForeArm_L.bandageDirty, false, "replaced bandage is clean")
    local hasDirtyReturned = false
    for _, it in pairs(swap.inventory.items) do if it.type == "Base.BandageDirty" then hasDirtyReturned = true end end
    T.truthy(hasDirtyReturned, "replaced dirty bandage is returned to NPC inventory")

    -- Healed dressing cleanup check
    swap.health.body.wounds.ForeArm_L.dressingHealed = true
    local hPart, _, hKind = Wounds.FindRemovableHealedDressing(swap)
    T.equal(hPart, "ForeArm_L", "finds healed dressing ready for removal")
    T.equal(hKind, "bandage", "identifies healed dressing kind")
end

-- 2. Eligibility policy: companion needs FirstAid >= 3; non-companion treats same-faction only (even at FA=0).
do
    local lowComp = { id = "comp-fa2", alive = true, tacticalClass = "colonist", skills = { FirstAid = 2 },
        affiliation = { factionID = "colony" }, inventory = { items = { b = { id = "b", type = "Base.Bandage", stack = 1 } } } }
    local hiComp = { id = "comp-fa3", alive = true, tacticalClass = "colonist", skills = { FirstAid = 3 },
        affiliation = { factionID = "colony" }, inventory = { items = { b = { id = "b", type = "Base.Bandage", stack = 2 } } } }
    local colPatient = { id = "comp-pat", name = "Eli", alive = true, tacticalClass = "colonist",
        affiliation = { factionID = "colony" }, health = { body = { wounds = { Hand_R = { partId = "Hand_R", type = "laceration", damage = 12 } } } }, runtime = {} }
    local bandAid = { id = "band-0", alive = true, tacticalClass = "neutral", skills = { FirstAid = 0 },
        affiliation = { factionID = "raiders" }, inventory = { items = { b = { id = "b", type = "Base.Bandage", stack = 1 } } } }
    local raiderAlly = { id = "raider-2", name = "Vex", alive = true, tacticalClass = "neutral",
        affiliation = { factionID = "raiders" }, runtime = {} }
    local otherFaction = { id = "other-1", alive = true, tacticalClass = "neutral",
        affiliation = { factionID = "scavengers" }, runtime = {} }

    T.truthy(Executor.CanAssistPatient(lowComp, colPatient, "npc"), "same-group companion with FirstAid=2 can perform assisted care using First Aid efficiency")
    T.truthy(Executor.CanAssistPatient(hiComp, colPatient, "npc"), "companion with FirstAid=3 can perform assisted care")
    T.truthy(Executor.CanAssistPatient(bandAid, raiderAlly, "npc"), "non-companion with FirstAid=0 can treat same-faction NPC")
    T.falsy(Executor.CanAssistPatient(bandAid, otherFaction, "npc"), "non-companion cannot treat different-faction NPC")
    T.falsy(Executor.CanAssistPatient(bandAid, playerObj, "player"), "non-friendly NPC cannot treat player")
    T.truthy(Executor.CanAssistPatient(lowComp, playerObj, "player"), "friendly companion with FirstAid=2 can treat player")
    T.truthy(Executor.CanAssistPatient(hiComp, playerObj, "player"), "friendly companion with FirstAid>=3 can treat player")
    -- Higher First Aid yields higher vanilla bandage life and faster treatment.
    local Dressing = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Dressing"
    local profile = Dressing.Profile("Base.Bandage") or { power = 4 }
    T.truthy(Dressing.Life(profile, 6) > Dressing.Life(profile, 0), "higher First Aid produces higher bandage life")
    T.truthy(PNC.Treatment.GetNPCBandageDuration(hiComp) < PNC.Treatment.GetNPCBandageDuration(lowComp), "higher First Aid bandages faster")
end

-- 3. Player dirty/open wound detection + live walk + animation + SetBandaged + EN/TL speech.
do
    local dirtyPlayerPart = {
        getIndex = function() return 0 end,
        getType = function() return "ForeArm_L" end,
        bandaged = function(s) return s._bandaged == true end,
        isBandageDirty = function(s) return s._dirty ~= false end,
        getBandageType = function() return "Base.Bandage" end,
        bleeding = function() return false end,
        scratched = function() return false end,
        isCut = function() return false end,
        bitten = function() return false end,
        isDeepWounded = function() return false end,
        getBurnTime = function() return 0 end,
        _bandaged = true,
        _dirty = true,
    }
    playerObj._parts = { dirtyPlayerPart }

    local medic = {
        id = "medic-fa3", name = "Claire", alive = true, tacticalClass = "colonist",
        skills = { FirstAid = 3 }, affiliation = { factionID = "colony" },
        x = 6, y = 10, z = 0, runtime = {},
        inventory = { items = { b = { id = "b", type = "Base.Bandage", stack = 2 } } },
    }
    records["medic-fa3"] = medic
    bodies["medic-fa3"] = makeBody(6, 10, 0)

    local polled = Executor.PollInjuredPlayers(nowMs)
    T.equal(polled, 1, "injured/dirty-bandaged player creates MedicalCare task via coarse poller")
    local cands = Executor.GetCandidates("medic-fa3")
    T.equal(#cands, 1, "FirstAid=3 companion discovers player MedicalCare candidate")
    local assigned = Executor.Assign(cands[1])
    T.truthy(assigned ~= nil, "medic claims player treatment task")
    local lease = { leaseId = "l-pl-1", npcId = "medic-fa3", sourceRef = cands[1].sourceRef }
    leases[lease.leaseId] = lease
    T.truthy(Executor.Start(lease), "medic starts player care lease")

    deliveredSpeech = {}
    -- Step 1: travel into range
    Executor.Tick(lease)
    -- Step 2: already in range -> begins treatment (plays animation, sound, start dialogue)
    nowMs = nowMs + 50
    Executor.Tick(lease)
    T.equal(bodies["medic-fa3"].anim, "Loot", "medic plays bedside Loot animation on player forearm")
    T.equal(bodies["medic-fa3"].lastSound, "FirstAidApplyBandage", "medic plays bandaging SFX")
    T.truthy(#deliveredSpeech >= 1, "medic speaks when beginning player dirty-bandage swap")
    T.contains(deliveredSpeech[1].speechEventID, "start_change_dirty", "selects start_change_dirty dialogue variant")

    -- Step 3: finish treatment after duration
    nowMs = nowMs + 10000
    Executor.Tick(lease)
    T.truthy(#appliedPlayerBandages == 1, "applies clean bandage via Build 42 SetBandaged")
    T.truthy(#syncBodyPartCalls == 1, "syncs player bodyPart in MP")
    T.equal(dirtyPlayerPart._dirty, false, "player bandage is now clean")
    T.truthy(#deliveredSpeech >= 2, "medic speaks completion line for player dirty-bandage swap")
    T.contains(deliveredSpeech[2].speechEventID, "complete_change_dirty", "selects complete_change_dirty variant")

    -- 4. Non-companion same-faction NPC patches another factionmate + patient thanks reply.
    local raiderDoc = {
        id = "raider-helper", name = "Brick", alive = true, tacticalClass = "neutral", skills = { FirstAid = 0 },
        affiliation = { factionID = "raiders" }, x = 10, y = 10, z = 0, runtime = {},
        inventory = { items = { b = { id = "b", type = "Base.Bandage", stack = 2 } } },
    }
    local raiderPat = {
        id = "raider-pat", name = "Nora", alive = true, tacticalClass = "neutral",
        affiliation = { factionID = "raiders" }, x = 11, y = 10, z = 0, runtime = {},
        health = { current = 80, max = 100, state = "injured", body = { wounds = { Hand_L = { partId = "Hand_L", type = "laceration", damage = 12, bleedingRate = 0.02 } } } },
    }
    Wounds.Ensure(raiderPat)
    raiderPat.health.body.wounds.Hand_L = { partId = "Hand_L", type = "laceration", damage = 12, bleedingRate = 0.02 }
    records["raider-helper"], records["raider-pat"] = raiderDoc, raiderPat
    bodies["raider-helper"], bodies["raider-pat"] = makeBody(10, 10, 0), makeBody(11, 10, 0)
    local npcTask = {
        id = "t-npc-raider", patientKind = "npc", patientId = "raider-pat",
        status = Status.WAITING_FOR_DOCTOR, phase = Status.WAITING_FOR_DOCTOR,
        priority = 50, retryAt = 0, revision = 1, createdAt = nowMs, lastProgressAt = nowMs,
        policy = { requireItem = true },
    }
    tasks[npcTask.id] = npcTask
    local npcLease = { leaseId = "l-npc-1", npcId = "raider-helper", sourceRef = npcTask.id }
    leases[npcLease.leaseId] = npcLease
    deliveredSpeech = {}
    nowMs = nowMs + 5000
    T.truthy(Executor.Assign({ npcId = "raider-helper", sourceRef = npcTask.id }), "same-faction non-companion assigns")
    T.truthy(Executor.Start(npcLease), "same-faction non-companion starts lease")
    Executor.Tick(npcLease)
    nowMs = nowMs + 10000
    Executor.Tick(npcLease)
    T.equal(raiderPat.health.body.wounds.Hand_L.bandaged, true, "same-faction helper bandages teammate wound")
    T.truthy(#deliveredSpeech >= 3, "emits start, completion, and patient_thanks speech for NPC patient")
    T.contains(deliveredSpeech[3].speechEventID, "patient_thanks", "patient NPC emits thank-you reply")
end

T.finish("pnc_assisted_medical_care_and_dirty_bandage_smoke")
