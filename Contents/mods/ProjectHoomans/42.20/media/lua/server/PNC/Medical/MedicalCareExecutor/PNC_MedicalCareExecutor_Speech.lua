-- Assisted medical-care semantic speech (open-wound patching, dirty-bandage swaps, thank-you reply).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Executor = PNC.MedicalCareExecutor
local Internal = Executor.Internal

local CARE_OPTS = {
    family = "medical_care_assisted",
    topic = "medical",
    domain = "medical",
    channel = "social",
    priority = 72,
    priorityHoldMs = 400,
    cooldownMs = 1200,
    familyCooldownMs = 1200,
    ttlMs = 8000,
    clientCooldowns = { familyMs = 1000, speakerMs = 1200, ambientMs = 300, mergeWindowMs = 0 },
}

local function resolvePartLabel(partId)
    local wounds = PNC.NPCWounds
    local pDef = wounds and wounds.Parts and wounds.Parts[tostring(partId or "")] or nil
    if pDef and pDef.label then return string.lower(tostring(pDef.label)) end
    local s = string.gsub(tostring(partId or "wound"), "_", " ")
    return string.lower(s)
end

local function addresseeNameFor(patient, patientKind)
    if not patient then return "friend" end
    if patientKind == "player" then
        local desc = patient.getDescriptor and patient:getDescriptor() or nil
        local fore = desc and desc.getForename and tostring(desc:getForename() or "") or ""
        local uname = patient.getUsername and tostring(patient:getUsername() or "") or ""
        return (fore ~= "" and fore) or (uname ~= "" and uname) or "friend"
    end
    return tostring(patient.name or patient.fullName or "friend")
end

local function speakCareLine(speaker, addressee, patientKind, variant, partId, now, suffix, act)
    local Transport = PNC.Semantics and PNC.Semantics.SpeechTransport or nil
    if not Transport or type(Transport.ResolveLine) ~= "function" or type(Transport.Deliver) ~= "function" then
        return false
    end
    if type(speaker) ~= "table" or speaker.alive == false or speaker.id == nil then return false end
    now = tonumber(now) or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    local ref = "medcare:" .. tostring(speaker.id) .. ":" .. tostring(math.floor(now)) .. ":" .. tostring(suffix)
    local toks = {
        ["addressee.name"] = addresseeNameFor(addressee, patientKind),
        ["slot.wound.part"] = resolvePartLabel(partId),
    }
    local ctx = {
        combatReactionRole = variant,
        beatRole = variant,
        medicalCareRole = variant,
        inCombat = false,
    }
    local text, res = Transport.ResolveLine(speaker, {
        eventType = "medical_care_assisted",
        eventID = ref,
        act = act or "REACT",
        topic = "medical",
        poolID = "semantic.medical.care.assisted",
        tokens = toks,
        context = ctx,
        inCombat = false,
        role = variant,
    })
    if not text then return false end
    local sent = Transport.Deliver(speaker, now, {
        eventType = "medical_care_assisted",
        speechEventID = res and res.realizationID or ("semantic.medical.care.assisted." .. variant),
        act = act or "REACT",
        domain = "medical",
        topic = "medical",
        channel = "social",
        family = CARE_OPTS.family,
        priority = CARE_OPTS.priority,
        priorityHoldMs = CARE_OPTS.priorityHoldMs,
        cooldownMs = CARE_OPTS.cooldownMs,
        familyCooldownMs = CARE_OPTS.familyCooldownMs,
        ttlMs = CARE_OPTS.ttlMs,
        clientCooldowns = CARE_OPTS.clientCooldowns,
        responsePlanID = res and res.responsePlanID or nil,
        realizationID = res and res.realizationID or nil,
        poolID = res and res.poolID or nil,
        realizationFamily = res and res.realizationFamily or nil,
        lightweightBark = true,
        observerOnly = true,
        eventRef = ref,
        threadID = ref,
        streamKey = "medcare:" .. tostring(speaker.id),
        text = text,
        presentationClass = res and res.presentationClass or "BARK",
        context = ctx,
    })
    return (tonumber(sent) or 0) > 0, text, variant
end

function Internal.SpeakTreatmentStart(medic, patient, patientKind, partId, isDirty, now)
    local variant = isDirty and "start_change_dirty"
        or (patientKind == "player" and "start_patch_player" or "start_patch_npc")
    return speakCareLine(medic, patient, patientKind, variant, partId, now, "start", "OFFER")
end

function Internal.SpeakTreatmentComplete(medic, patient, patientKind, partId, isDirty, now)
    local variant = isDirty and "complete_change_dirty" or "complete_patch"
    local ok, text, v = speakCareLine(medic, patient, patientKind, variant, partId, now, "done", "INFORM")
    if patientKind == "npc" and type(patient) == "table" and patient.alive ~= false then
        speakCareLine(patient, medic, "npc", "patient_thanks", partId, (tonumber(now) or 0) + 1250, "thanks", "ACK")
        if PNC.Relationships and type(PNC.Relationships.ApplyConversationEffect) == "function" then
            local gt = getGameTime and getGameTime()
            local worldAge = gt and gt.getWorldAgeHours and gt:getWorldAgeHours() or 0
            PNC.Relationships.ApplyConversationEffect(tostring(patient.id), "npc:" .. tostring(medic.id), {
                interactionType = "injury_aid_received", memoryType = "injury_aid_received",
                approval = 3, familiarity = 1, decayPerDay = 0.15, tags = { injury = true, aid = true },
            }, { eventID = "medcare-aid:" .. tostring(medic.id) .. ":" .. tostring(patient.id) .. ":" .. tostring(partId), worldAgeHours = worldAge })
        end
    end
    return ok, text, v
end

return Executor
