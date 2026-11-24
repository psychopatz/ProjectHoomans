-- Contextual multi-turn dialogue beats between a rescuer NPC and an
-- incapacitated teammate (scavenging rags from corpses, stabilizing wounds,
-- and post-rescue relief).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local VARIANT_COUNTS = {
    no_rags_notice = 3,
    no_rags_curtain = 3,
    no_rags_drawer = 3,
    no_rags_reply = 3,
    scavenge_open = 3,
    scavenge_curtain_open = 3,
    scavenge_drawer_open = 3,
    scavenge_reply = 3,
    approach_burn_open = 3,
    approach_bleed_open = 3,
    approach_reply = 3,
    stabilized_open = 3,
    stabilized_reply = 3,
}

local FALLBACKS = {
    no_rags_notice = "Out of bandages... better check that corpse for some cloth to rip.",
    no_rags_curtain = "No bandages left... I'll pull down that curtain and rip it into rags.",
    no_rags_drawer = "Running empty on rags... let me grab some clothes out of that drawer to rip.",
    no_rags_reply = "Good thinking, {addressee.name}. Never hurts to keep extra rags on hand.",
    scavenge_open = "Hold on, {addressee.name}! I'm out of bandages—I'll rip some rags off a corpse right here!",
    scavenge_curtain_open = "Hold on, {addressee.name}! I'm pulling down that curtain to rip into bandages right now!",
    scavenge_drawer_open = "Stay with me, {addressee.name}! Grabbing some clothes from that drawer to rip for bandages!",
    scavenge_reply = "Hurry, {addressee.name}... I'm losing too much blood!",
    approach_burn_open = "Stay still, {addressee.name}—those burns look bad, I'm wrapping your {slot.wound.part} now.",
    approach_bleed_open = "Hang in there, {addressee.name}, I've got bandages—I'm patching your {slot.wound.part} right now!",
    approach_reply = "Thank god, {addressee.name}... don't let me bleed out here.",
    stabilized_open = "That should hold, {addressee.name}. Catch your breath—we've got you.",
    stabilized_reply = "You saved my skin, {addressee.name}. Thought I was done for.",
}

local function pickTemplateID(role, speaker, now)
    local count = VARIANT_COUNTS[role] or 1
    local seed = tonumber(speaker and speaker.identitySeed) or 1
    local idx = (math.abs(math.floor(seed + math.floor((tonumber(now) or 0) / 1000))) % count) + 1
    return "convo.world.medical_rescue." .. tostring(role) .. "." .. tostring(idx)
end

local function partLabelFor(partId)
    local wounds = PNC.NPCWounds
    local pDef = wounds and wounds.Parts and wounds.Parts[tostring(partId or "")] or nil
    if pDef and pDef.label then return string.lower(tostring(pDef.label)) end
    return string.lower(string.gsub(tostring(partId or "wound"), "_", " "))
end

local function hasBurnWound(patient, partId)
    local wounds = patient and patient.health and patient.health.body
        and patient.health.body.wounds or nil
    if type(wounds) ~= "table" then return false end
    local w = partId and wounds[partId] or nil
    if w and (w.type == "burn" or w.burned == true) then return true end
    for _, wound in pairs(wounds) do
        if type(wound) == "table" and (wound.type == "burn" or wound.burned == true) then
            return true
        end
    end
    return false
end

local function makeTurn(speaker, addressee, role, opts)
    opts = opts or {}
    return {
        speaker = speaker,
        addressee = addressee,
        eventType = "medical_rescue_beat",
        domain = "medical",
        channel = "social",
        topic = "medical",
        act = opts.act or "REASSURE",
        role = role,
        templateID = pickTemplateID(role, speaker, opts.now),
        fallback = FALLBACKS[role] or "",
        family = opts.family or ("medical_rescue_" .. tostring(role)),
        delayMs = tonumber(opts.delayMs) or 0,
        priority = tonumber(opts.priority) or 74,
        priorityHoldMs = 500,
        holdMs = 800,
        ttlMs = 12000,
        cooldownMs = 1500,
        familyCooldownMs = 1500,
        eventRef = tostring(opts.refPrefix or "med_rescue") .. ":" .. tostring(role) .. ":" .. tostring(speaker and speaker.id or "npc"),
        tokens = opts.tokens,
    }
end

-- 0. NPC notices they have no bandages/rags left and checks nearby corpses/curtains/drawers.
Beats.RegisterHook("medical_rescue.no_rags_notice", {
    eventTypes = { "medical_rescue.no_rags_notice" },
    priority = 42,
    cooldownMs = 25000,
    evaluate = function(_, payload)
        local speaker = payload.speaker or payload.anchor
        if type(speaker) ~= "table" or speaker.alive == false then return nil end
        local partner = payload.partner or payload.addressee
        local now = tonumber(payload.now) or 0
        local src = tostring(payload.sourceType or "")
        local openRole = src == "curtain" and "no_rags_curtain"
            or (src == "container" and "no_rags_drawer" or "no_rags_notice")
        local ref = "med_rescue:no_rags:" .. tostring(speaker.id) .. ":" .. tostring(math.floor(now / 1000))
        local replies = {}
        if type(partner) == "table" and partner.alive ~= false and partner.id ~= speaker.id then
            replies[1] = makeTurn(partner, speaker, "no_rags_reply", {
                refPrefix = ref, family = "medical_rescue_no_rags", priority = 40,
                delayMs = 1500, act = "ACK", now = now + 1,
            })
        end
        return {
            threadID = ref,
            family = "medical_rescue_no_rags",
            ttlMs = 10000,
            opening = makeTurn(speaker, partner, openRole, {
                refPrefix = ref, family = "medical_rescue_no_rags", priority = 42,
                act = "INFORM", now = now,
            }),
            replies = replies,
        }
    end,
})

-- 1. Rescuer has no bandages and runs to rip rags from a nearby corpse/curtain/drawer.
Beats.RegisterHook("medical_rescue.scavenge_rags", {
    eventTypes = { "medical_rescue.scavenge_rags" },
    priority = 76,
    cooldownMs = 12000,
    evaluate = function(_, payload)
        local rescuer = payload.rescuer or payload.anchor
        local patient = payload.patient or payload.partner
        if type(rescuer) ~= "table" or rescuer.alive == false then return nil end
        if type(patient) ~= "table" or patient.alive == false then return nil end
        local now = tonumber(payload.now) or 0
        local src = tostring(payload.sourceType or "")
        local openRole = src == "curtain" and "scavenge_curtain_open"
            or (src == "container" and "scavenge_drawer_open" or "scavenge_open")
        local ref = "med_rescue:scavenge:" .. tostring(payload.taskId or patient.id)
        return {
            threadID = ref,
            family = "medical_rescue_scavenge",
            ttlMs = 12000,
            opening = makeTurn(rescuer, patient, openRole, {
                refPrefix = ref, family = "medical_rescue_scavenge", priority = 76, now = now,
            }),
            replies = {
                makeTurn(patient, rescuer, "scavenge_reply", {
                    refPrefix = ref, family = "medical_rescue_scavenge", priority = 74,
                    delayMs = 1400, act = "PLEAD", now = now + 1,
                }),
            },
        }
    end,
})

-- 2. Rescuer begins patching an incapacitated teammate (burn- vs bleeding-aware).
Beats.RegisterHook("medical_rescue.approach", {
    eventTypes = { "medical_rescue.approach" },
    priority = 76,
    cooldownMs = 8000,
    evaluate = function(_, payload)
        local rescuer = payload.rescuer or payload.anchor
        local patient = payload.patient or payload.partner
        if type(rescuer) ~= "table" or rescuer.alive == false then return nil end
        if type(patient) ~= "table" or patient.alive == false then return nil end
        local now = tonumber(payload.now) or 0
        local partId = payload.partId
        local openRole = hasBurnWound(patient, partId) and "approach_burn_open" or "approach_bleed_open"
        local tokens = { ["slot.wound.part"] = partLabelFor(partId) }
        local ref = "med_rescue:approach:" .. tostring(patient.id) .. ":" .. tostring(math.floor(now / 1000))
        return {
            threadID = ref,
            family = "medical_rescue_approach",
            ttlMs = 12000,
            opening = makeTurn(rescuer, patient, openRole, {
                refPrefix = ref, family = "medical_rescue_approach", priority = 76,
                tokens = tokens, now = now,
            }),
            replies = {
                makeTurn(patient, rescuer, "approach_reply", {
                    refPrefix = ref, family = "medical_rescue_approach", priority = 74,
                    delayMs = 1400, act = "REACT", tokens = tokens, now = now + 1,
                }),
            },
        }
    end,
})

-- 3. Rescuer finishes stabilizing the incapacitated teammate.
Beats.RegisterHook("medical_rescue.stabilized", {
    eventTypes = { "medical_rescue.stabilized" },
    priority = 74,
    cooldownMs = 8000,
    evaluate = function(_, payload)
        local rescuer = payload.rescuer or payload.anchor
        local patient = payload.patient or payload.partner
        if type(rescuer) ~= "table" or rescuer.alive == false then return nil end
        if type(patient) ~= "table" or patient.alive == false then return nil end
        local now = tonumber(payload.now) or 0
        local ref = "med_rescue:stabilized:" .. tostring(patient.id) .. ":" .. tostring(math.floor(now / 1000))
        return {
            threadID = ref,
            family = "medical_rescue_stabilized",
            ttlMs = 12000,
            opening = makeTurn(rescuer, patient, "stabilized_open", {
                refPrefix = ref, family = "medical_rescue_stabilized", priority = 74, now = now,
            }),
            replies = {
                makeTurn(patient, rescuer, "stabilized_reply", {
                    refPrefix = ref, family = "medical_rescue_stabilized", priority = 72,
                    delayMs = 1400, act = "THANK", now = now + 1,
                }),
            },
        }
    end,
})

return Beats
