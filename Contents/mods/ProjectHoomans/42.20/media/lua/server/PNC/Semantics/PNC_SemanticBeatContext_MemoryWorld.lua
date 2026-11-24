-- Bounded memory, world-event, knowledge/place, and live posture/job providers for BeatContext.
-- Zero OnTick loops, zero world scans; reuses cached utilities & 2s TTL world-event cache.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local BC = PNC.Semantics.BeatContext or {}
PNC.Semantics.BeatContext = BC

local Patience = require "PNC/ConvoEngine/PatienceTracker"

local WORLD_EVENT_TTL_MS = 2000
local worldEventCache = { expiresAt = -1, factionKey = nil, data = nil }

local JOB_LABELS = {
    farming = "tending the crops",
    farm = "tending the crops",
    guard = "standing guard",
    patrol = "patrolling the perimeter",
    cooking = "cooking food",
    cook = "cooking food",
    fishing = "fishing",
    foraging = "foraging for supplies",
    scavenging = "scavenging for supplies",
    scavenge = "scavenging for supplies",
    medical = "tending the wounded",
    medic = "tending the wounded",
    carpentry = "working on repairs",
    builder = "building and reinforcing",
    hauling = "hauling supplies",
    corpse_haul = "clearing bodies",
    woodcutting = "chopping wood",
    lumber = "chopping wood",
    water = "hauling water",
    mechanic = "working on vehicles",
    tailoring = "mending gear",
}

local function normalizeJob(rec)
    if type(rec) ~= "table" then return nil, nil end
    local rt = type(rec.runtime) == "table" and rec.runtime or {}
    local fj = type(rec.facilityJob) == "table" and rec.facilityJob or nil
    local raw = (fj and (fj.jobID or fj.type or fj.role))
        or rec.currentJob or rec.jobID or rt.currentJob or rt.jobID
        or rec.tacticalRole or nil
    if not raw or tostring(raw) == "" then return nil, nil end
    local key = string.lower(tostring(raw))
    return key, JOB_LABELS[key] or ("working on " .. key)
end

local function resolveLiveState(rec)
    if type(rec) ~= "table" then
        return { posture = "standing", activity = "idle", isSitting = false, isSleeping = false, isWorking = false }
    end
    local rt = type(rec.runtime) == "table" and rec.runtime or {}
    local rawPosture = string.lower(tostring(rec.posture or rt.posture or ""))
    local rawScene = string.lower(tostring(rec.animationScene or rt.animationScene or ""))
    local rawBeh = string.lower(tostring(rec.activeBehavior or rec.behavior or rt.currentTask or ""))

    local isSleeping = rec.sleeping == true or rt.sleeping == true
        or rawPosture == "sleeping" or string.find(rawScene, "sleep", 1, true) ~= nil
        or string.find(rawBeh, "sleep", 1, true) ~= nil
    local isSitting = (not isSleeping) and (
        rec.sitting == true or rt.sitting == true
        or rawPosture == "sitting" or rawPosture == "sit"
        or string.find(rawScene, "sit", 1, true) ~= nil
        or string.find(rawBeh, "sit", 1, true) ~= nil
    )

    local posture = "standing"
    if isSleeping then posture = "sleeping"
    elseif isSitting then posture = "sitting"
    elseif rawPosture == "crouching" or rawPosture == "resting" then posture = rawPosture end

    local jobKey, jobLabel = normalizeJob(rec)
    local isCombat = rt.target ~= nil or rt.attackAction ~= nil
        or string.find(rawBeh, "combat", 1, true) ~= nil
        or string.find(rawBeh, "attack", 1, true) ~= nil
    local isFishing = jobKey == "fishing" or string.find(rawBeh, "fish", 1, true) ~= nil
    local isTraveling = string.find(rawBeh, "travel", 1, true) ~= nil
        or string.find(rawBeh, "excursion", 1, true) ~= nil
        or string.find(rawBeh, "follow", 1, true) ~= nil
    local isWorking = (not isSleeping) and (not isCombat) and (
        jobKey ~= nil
        or string.find(rawBeh, "work", 1, true) ~= nil
        or string.find(rawBeh, "job", 1, true) ~= nil
        or string.find(rawBeh, "facility", 1, true) ~= nil
    )

    local activity = "idle"
    if isCombat then activity = "combat"
    elseif isSleeping then activity = "sleeping"
    elseif isSitting then activity = "sitting"
    elseif isFishing then activity = "fishing"
    elseif isWorking then activity = "working"
    elseif isTraveling then activity = "traveling"
    elseif rawPosture == "resting" or string.find(rawBeh, "rest", 1, true) ~= nil then activity = "resting" end

    local rawOrder = string.lower(tostring(
        rec.orderKind or rt.orderKind
        or (type(rec.order) == "table" and (rec.order.kind or rec.order.type))
        or (type(rt.order) == "table" and (rt.order.kind or rt.order.type))
        or ""
    ))
    if rawOrder == "" and string.find(rawBeh, "follow", 1, true) ~= nil then
        rawOrder = "follow"
    elseif rawOrder == "" and string.find(rawBeh, "guard", 1, true) ~= nil then
        rawOrder = "guard"
    elseif rawOrder == "" and string.find(rawBeh, "patrol", 1, true) ~= nil then
        rawOrder = "patrol"
    elseif rawOrder == "" and string.find(rawBeh, "camp", 1, true) ~= nil then
        rawOrder = "camp"
    elseif rawOrder == "" then
        rawOrder = "none"
    end

    return {
        posture = posture,
        activity = activity,
        job = jobKey,
        jobLabel = jobLabel,
        orderKind = rawOrder,
        alreadyFollowing = rawOrder == "follow",
        isSitting = isSitting,
        isSleeping = isSleeping,
        isWorking = isWorking,
    }
end

BC.ResolveLiveState = resolveLiveState

local function inspectMemories(speaker, partnerKey)
    local out = { hasAny = false, savedMe = false, foughtTogether = false, treatedMe = false, betrayed = false, lastType = nil }
    if type(speaker) ~= "table" or speaker.id == nil or not partnerKey then return out end
    local relSvc = PNC.Relationships
    if not relSvc or type(relSvc.Get) ~= "function" then return out end
    local ok, rel = pcall(relSvc.Get, speaker.id, partnerKey)
    if not ok or type(rel) ~= "table" then return out end

    local function scanEntry(m)
        if type(m) ~= "table" then return end
        local t = tostring(m.type or m.interactionType or "")
        if t == "" then return end
        out.hasAny = true
        out.lastType = t
        if t == "protected_from_attacker" or t == "saved_from_incapacitation" then
            out.savedMe = true
        elseif t == "survived_combat_together" or t == "survived_horde_attack" then
            out.foughtTogether = true
        elseif t == "treated_wound" then
            out.treatedMe = true
        elseif t == "abandoned_in_combat" or t == "player_damaged_npc" then
            out.betrayed = true
        end
    end

    if type(rel.memories) == "table" then
        for _, m in pairs(rel.memories) do scanEntry(m) end
    end
    if type(rel.interactionJournal) == "table" then
        local j = rel.interactionJournal
        for i = math.max(1, #j - 8), #j do scanEntry(j[i]) end
    end
    return out
end

local function inspectWorldEvents(speaker, now)
    local fKey = tostring(speaker and speaker.factionID or "global")
    if worldEventCache.data and worldEventCache.factionKey == fKey
        and now < (tonumber(worldEventCache.expiresAt) or 0)
    then
        return worldEventCache.data
    end
    local data = { hasActiveEvent = false, activeType = nil, hasFoodCrisis = false, hasRaiderSurge = false }
    local swe = PsychopatzCore and PsychopatzCore.ScopedWorldEvents or nil
    local dir = PNC.ScopedWorldEventDirector or nil
    local agg = nil
    if dir and type(dir.AggregateEffectsForFaction) == "function" then
        local ok, res = pcall(dir.AggregateEffectsForFaction, speaker and { id = speaker.factionID } or nil)
        if ok and type(res) == "table" then agg = res end
    elseif swe and type(swe.AggregateEffects) == "function" then
        local ok, res = pcall(swe.AggregateEffects, { factionID = speaker and speaker.factionID or nil, includeGlobal = true })
        if ok and type(res) == "table" then agg = res end
    end
    if type(agg) == "table" then
        local effects = type(agg.effects) == "table" and agg.effects or {}
        if effects.foodScarcity or effects.food_scarcity or effects.starvationPressure then
            data.hasFoodCrisis = true
            data.hasActiveEvent = true
            data.activeType = data.activeType or "food_crisis"
        end
        if effects.raiderSurge or effects.raider_surge or effects.hostileActivity then
            data.hasRaiderSurge = true
            data.hasActiveEvent = true
            data.activeType = data.activeType or "raider_surge"
        end
        if type(agg.events) == "table" and #agg.events > 0 then
            data.hasActiveEvent = true
            local first = agg.events[1]
            data.activeType = data.activeType or (type(first) == "table" and tostring(first.type or first.eventID or "") or nil)
        end
    end
    worldEventCache.data = data
    worldEventCache.factionKey = fKey
    worldEventCache.expiresAt = now + WORLD_EVENT_TTL_MS
    return data
end

local function resolveActorIdentityAxes(speaker, rel)
    speaker = type(speaker) == "table" and speaker or {}
    rel = type(rel) == "table" and rel or {}
    local rawRole = string.lower(tostring(speaker.npcType or speaker.role or speaker.archetype or ""))
    local role = "survivor"
    if rawRole == "trader" or speaker.isTrader == true then role = "trader"
    elseif rawRole == "bandit" or rawRole == "raider" or speaker.isHostile == true then role = "bandit"
    elseif rawRole == "looter" then role = "looter"
    elseif rawRole == "guard" or rawRole == "soldier" then role = "guard"
    elseif speaker.colonist == true or rawRole == "colonist" then role = "colonist"
    elseif speaker.isCompanion == true or speaker.isPlayerCompanion == true or rawRole == "companion" then role = "companion"
    elseif rawRole ~= "" then role = rawRole end

    local rawBond = string.lower(tostring(rel.bond or rel.familyRole or rel.kinRole or rel.state or ""))
    local bond = "stranger"
    local kinTitle = nil
    if rawBond == "lover" or rawBond == "partner" or rawBond == "romantic" then
        bond = "lover"
    elseif rawBond == "spouse" or rawBond == "wife" or rawBond == "husband" then
        bond = "spouse"
    elseif rawBond == "father" or rawBond == "dad" then
        bond = "parent"
        kinTitle = "Dad"
    elseif rawBond == "mother" or rawBond == "mom" then
        bond = "parent"
        kinTitle = "Mom"
    elseif rawBond == "parent" then
        bond = "parent"
        kinTitle = (speaker.isFemale == true or speaker.female == true) and "Mom" or "Dad"
    elseif rawBond == "son" or rawBond == "daughter" or rawBond == "child" then
        bond = "child"
    elseif rawBond == "brother" or rawBond == "sister" or rawBond == "sibling" then
        bond = "sibling"
    elseif rawBond == "family" or rawBond == "relative" then
        bond = "family"
    elseif rawBond == "hostile" or rawBond == "enemy" or rawBond == "rival" then
        bond = "rival"
    elseif rawBond == "ally" or rawBond == "trusted" or rawBond == "friendly" or rawBond == "friend" or rawBond == "member" then
        bond = "friend"
    end

    local age = tonumber(speaker.age)
    local ageBand = string.lower(tostring(speaker.ageBand or ""))
    if ageBand == "" then
        if age ~= nil then
            if age < 22 then ageBand = "youth"
            elseif age >= 55 then ageBand = "elder"
            else ageBand = "adult" end
        else
            ageBand = "adult"
        end
    end

    return { role = role, bond = bond, kinTitle = kinTitle, ageBand = ageBand }
end

BC.ResolveActorIdentityAxes = resolveActorIdentityAxes

BC.RegisterProvider("memory_and_world", function(ctx, speaker, _, opts)
    local partnerKey = (ctx.relationship and ctx.relationship.partnerKey)
        or (opts and opts.partnerKey) or nil
    ctx.memory = inspectMemories(speaker, partnerKey)
    ctx.worldEvents = inspectWorldEvents(speaker, ctx.now)
    ctx.state = resolveLiveState(speaker)

    local placeName = speaker and (speaker.settlementName or speaker.zoneName or speaker.locationName or speaker.roomName) or nil
    local inSettlement = speaker and (speaker.settlementID ~= nil or (speaker.settlementName ~= nil and tostring(speaker.settlementName) ~= "")) == true
    local gossipTopic = nil
    if type(speaker) == "table" and type(speaker.knowledge) == "table" then
        gossipTopic = speaker.knowledge.latestGossipTopic or speaker.knowledge.gossipTopic
    end
    ctx.place = { name = placeName, inSettlement = inSettlement }
    ctx.knowledge = { hasGossip = gossipTopic ~= nil and tostring(gossipTopic) ~= "", gossipTopic = gossipTopic }

    local pat = Patience.Inspect(speaker and speaker.id, partnerKey, ctx.now)
    ctx.patience = pat
    ctx.mood = Patience.ResolveMood(speaker, pat)
    ctx.identityAxes = resolveActorIdentityAxes(speaker, ctx.relationship)
    local reqAction = opts and (opts.commandAction or opts.action) or nil
    ctx.command = {
        action = reqAction,
        redundant = reqAction ~= nil and Patience.IsRedundantCommand(reqAction, ctx.state.orderKind) == true,
    }

    if type(ctx.tokens) == "table" then
        if placeName then ctx.tokens["place.name"] = tostring(placeName) end
        if ctx.state.jobLabel then ctx.tokens["state.job"] = ctx.state.jobLabel end
        if ctx.state.posture then ctx.tokens["state.posture"] = ctx.state.posture end
        if ctx.state.orderKind then ctx.tokens["state.order_kind"] = ctx.state.orderKind end
        if ctx.worldEvents.activeType then ctx.tokens["world.event"] = ctx.worldEvents.activeType end
        if gossipTopic then ctx.tokens["know.gossip_topic"] = tostring(gossipTopic) end
        if ctx.mood and ctx.mood.primary then ctx.tokens["mood.primary"] = ctx.mood.primary end
        if ctx.identityAxes and ctx.identityAxes.kinTitle then
            ctx.tokens["rel.kin_title"] = ctx.identityAxes.kinTitle
        end
    end
end)

local origFlatten = BC.FlattenForSpeech
function BC.FlattenForSpeech(ctx)
    local flat = type(origFlatten) == "function" and origFlatten(ctx) or {}
    local m = type(ctx and ctx.memory) == "table" and ctx.memory or {}
    local w = type(ctx and ctx.worldEvents) == "table" and ctx.worldEvents or {}
    local st = type(ctx and ctx.state) == "table" and ctx.state or {}
    local pl = type(ctx and ctx.place) == "table" and ctx.place or {}
    local kn = type(ctx and ctx.knowledge) == "table" and ctx.knowledge or {}
    local e = type(ctx and ctx.env) == "table" and ctx.env or {}

    flat.memHasAny = m.hasAny == true
    flat.memSavedMe = m.savedMe == true
    flat.memFoughtTogether = m.foughtTogether == true
    flat.memTreatedMe = m.treatedMe == true
    flat.memBetrayed = m.betrayed == true

    flat.worldPowerOff = e.powerOn == false
    flat.worldWaterOff = e.waterOn == false
    flat.worldHasEvent = w.hasActiveEvent == true
    flat.worldFoodCrisis = w.hasFoodCrisis == true
    flat.worldRaiderSurge = w.hasRaiderSurge == true
    flat.worldEventType = w.activeType

    flat.knowHasGossip = kn.hasGossip == true
    flat.placeInSettlement = pl.inSettlement == true

    flat.statePosture = st.posture or "standing"
    flat.stateJob = st.job
    flat.stateOrderKind = st.orderKind or "none"
    flat.stateAlreadyFollowing = st.alreadyFollowing == true
    flat.stateSitting = st.isSitting == true
    flat.stateSleeping = st.isSleeping == true
    flat.stateWorking = st.isWorking == true
    flat.activity = st.activity or "idle"

    local md = type(ctx and ctx.mood) == "table" and ctx.mood or {}
    local pt = type(ctx and ctx.patience) == "table" and ctx.patience or {}
    local cmd = type(ctx and ctx.command) == "table" and ctx.command or {}
    flat.moodPrimary = md.primary or "calm"
    flat.moodPanicked = md.panicked == true
    flat.moodInPain = md.inPain == true
    flat.moodStressed = md.stressed == true
    flat.moodTired = md.tired == true
    flat.moodUnhappy = md.unhappy == true
    flat.moodBored = md.bored == true
    flat.moodHungry = md.hungry == true
    flat.moodCheerful = md.cheerful == true
    flat.npcAnnoyance = pt.level or md.annoyanceLevel or "calm"
    flat.npcAnnoyed = pt.annoyed == true or md.annoyed == true
    flat.npcFedUp = pt.fedUp == true or md.fedUp == true
    flat.convoRepeatCount = tonumber(pt.repeatCount or md.repeatCount) or 0
    flat.commandRedundant = cmd.redundant == true

    local ax = type(ctx and ctx.identityAxes) == "table" and ctx.identityAxes or {}
    flat.actorRole = ax.role or "survivor"
    flat.relBond = ax.bond or "stranger"
    flat.actorAgeBand = ax.ageBand or "adult"
    return flat
end

local origReset = BC.ResetRuntime
function BC.ResetRuntime()
    worldEventCache.expiresAt = -1
    worldEventCache.factionKey = nil
    worldEventCache.data = nil
    if type(origReset) == "function" then origReset() end
end

return BC
