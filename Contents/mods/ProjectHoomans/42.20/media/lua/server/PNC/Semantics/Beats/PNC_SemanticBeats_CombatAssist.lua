-- Post-combat assist, companion-to-survivor exchange, and proactive identity beats.
-- Purely event-driven from SocialEncounterTracker; zero OnTick loops or full scans.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local IdentityBeat = require "PNC/Semantics/Beats/PNC_SemanticBeats_CombatAssist_Identity"

local PAIR_COOLDOWN_MS = 45000
local ENCOUNTER_DEDUPE_MS = 30000
local HEAR_RADIUS = 16
local MAX_TRACKED = 64

local pairCooldowns, pairOrder = {}, {}
local seenEncounters, encounterOrder = {}, {}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function setBounded(map, order, key, value)
    if map[key] == nil then
        while #order >= MAX_TRACKED do
            local oldest = table.remove(order, 1)
            map[oldest] = nil
        end
        order[#order + 1] = key
    end
    map[key] = value
end

local function isLiveCalmNPC(rec)
    if type(rec) ~= "table" or rec.id == nil or rec.alive == false then return false end
    if rec.departed == true or rec.removed == true then return false end
    local live = tostring(PNC.Const and PNC.Const.PRESENCE_LIVE or "live")
    if rec.presenceState ~= nil and tostring(rec.presenceState) ~= live then return false end
    local b = tostring(rec.activeBehavior or rec.behavior or "")
    if b == "hostile" or rec.isHostile == true then return false end
    return true
end

local function isCompanion(rec)
    if type(rec) ~= "table" then return false end
    if rec.isCompanion == true or rec.isPlayerCompanion == true or rec.colonist == true then
        return true
    end
    local owner = rec.ownerKey or rec.owner or rec.playerOwner
    if owner ~= nil and tostring(owner) ~= "" then return true end
    local fac = PNC.Factions
    if fac and type(fac.IsPlayerFaction) == "function" and rec.factionID ~= nil then
        local ok, res = pcall(fac.IsPlayerFaction, rec.factionID)
        if ok and res == true then return true end
    end
    return false
end

local function resolveNPCByKey(entityKey)
    if not entityKey then return nil end
    local s = tostring(entityKey)
    local npcID = string.match(s, "^npc:(.+)$") or s
    local reg = PNC.Registry
    if reg and type(reg.Get) == "function" then
        return reg.Get(npcID)
    end
    return nil
end

local function resolvePlayerByKey(entityKey)
    if not entityKey then return nil end
    local core = PNC.Core
    if not core or type(core.ForEachPlayer) ~= "function" then return nil end
    local hooks = PNC.SocialEventHooks
    local target = tostring(entityKey)
    local found = nil
    core.ForEachPlayer(function(p)
        if found or not p then return end
        if hooks and type(hooks.ResolvePlayerKey) == "function" then
            local ok, key = pcall(hooks.ResolvePlayerKey, p)
            if ok and tostring(key or "") == target then
                found = p
                return
            end
        end
        local uid = p.getUsername and p:getUsername() or nil
        if uid and ("player:" .. tostring(uid)) == target then
            found = p
        end
    end)
    return found
end

local function anyPlayerCanHear(rec)
    local core = PNC.Core
    if not core or type(core.ForEachPlayer) ~= "function" then return false end
    local nx, ny = tonumber(rec and rec.x), tonumber(rec and rec.y)
    if not nx or not ny then return true end
    local rSq = HEAR_RADIUS * HEAR_RADIUS
    local heard = false
    core.ForEachPlayer(function(p)
        if heard or not p then return end
        local px = p.getX and tonumber(p:getX())
        local py = p.getY and tonumber(p:getY())
        if px and py then
            local dx, dy = px - nx, py - ny
            if (dx * dx + dy * dy) <= rSq then heard = true end
        end
    end)
    return heard
end

local function reservePairAndEncounter(encounterID, speakerID, partnerKey, now)
    if encounterID and tostring(encounterID) ~= "" then
        local lastEnc = seenEncounters[tostring(encounterID)]
        if lastEnc and now >= lastEnc and (now - lastEnc) < ENCOUNTER_DEDUPE_MS then
            return false, "encounter_already_celebrated"
        end
    end
    local pKey = tostring(speakerID) .. "|" .. tostring(partnerKey)
    local lastPair = pairCooldowns[pKey]
    if lastPair and now >= lastPair and (now - lastPair) < PAIR_COOLDOWN_MS then
        return false, "pair_on_cooldown"
    end
    if encounterID and tostring(encounterID) ~= "" then
        setBounded(seenEncounters, encounterOrder, tostring(encounterID), now)
    end
    setBounded(pairCooldowns, pairOrder, pKey, now)
    return true, nil
end

local function buildAssistPlan(eventName, payload, ctx)
    local speaker = payload.anchor or payload.speaker
    local partner = payload.partner or payload.addressee
    if not isLiveCalmNPC(speaker) or partner == nil then return nil end

    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    local flat = (BC and type(BC.FlattenForSpeech) == "function")
        and BC.FlattenForSpeech(ctx) or {}
    flat.assistKind = payload.assistKind or "protected"
    flat.hordeAttack = payload.hordeAttack == true
    flat.threatCount = tonumber(payload.threatCount) or 1

    local isCrossGroup = flat.isCrossGroup == true
    local partnerIsPlayer = payload.addresseeIsPlayer == true or flat.partnerIsPlayer == true
    local refBase = "assist:" .. tostring(payload.encounterID or speaker.id) .. ":" .. tostring(speaker.id)

    local openPool = isCrossGroup and "semantic.combat.assist.companion_exchange"
        or "semantic.combat.assist.gratitude"
    local openRole
    if isCrossGroup then
        openRole = flat.hordeAttack and "companion_exchange_horde_open" or "companion_exchange_open"
    elseif flat.hordeAttack then
        openRole = "assist_gratitude_horde"
    elseif flat.isNightOrDusk then
        openRole = "assist_gratitude_night"
    elseif flat.anyInjured or flat.anyExhausted then
        openRole = "assist_gratitude_shaken"
    elseif flat.relationshipTier == "wary" then
        openRole = "assist_gratitude_wary"
    elseif flat.relationshipTier == "friendly" or flat.relationshipTier == "trusted" or flat.relationshipTier == "ally" then
        openRole = "assist_gratitude_warm"
    else
        openRole = "assist_gratitude_general"
    end

    local replies = {}
    local shouldAsk = IdentityBeat.ShouldAskName(ctx, { partnerKey = payload.partnerKey })

    if isCrossGroup and not partnerIsPlayer then
        -- Companion ↔ nearby external NPC reply
        replies[#replies + 1] = {
            speaker = partner,
            addressee = speaker,
            poolID = "semantic.combat.assist.companion_exchange",
            eventType = "combat_assist_beat",
            domain = "social",
            channel = "social",
            topic = "combat_assist",
            act = "REACT",
            role = (flat.anyInjured or flat.anyExhausted) and "companion_exchange_checkin"
                or (flat.isNightOrDusk and "companion_exchange_night" or "companion_exchange_reply"),
            family = "combat_assist_companion_exchange",
            delayMs = 1050,
            priority = 54,
            eventRef = refBase .. ":cx1",
            context = flat,
        }
    end

    if shouldAsk then
        IdentityBeat.MarkAsked(speaker.id, payload.partnerKey, ctx.now)
        if partnerIsPlayer then
            replies[#replies + 1] = IdentityBeat.BuildPlayerAskTurn(speaker, partner, flat, {
                eventRef = refBase .. ":ask_name",
                delayMs = 1450,
                priority = 58,
            })
        elseif type(partner) == "table" and partner.id ~= nil then
            -- External NPC asks colonist (or colonist asks external NPC)
            local askTurns = IdentityBeat.BuildColonistAskReplies(speaker, partner, ctx, flat, {
                eventRef = refBase .. ":npc_ask",
                delayMs = isCrossGroup and 2200 or 1400,
                priority = 54,
            })
            for i = 1, #askTurns do
                replies[#replies + 1] = askTurns[i]
            end
        end
    elseif not isCrossGroup and (flat.anyInjured or flat.anyExhausted) and not partnerIsPlayer then
        -- State-driven aftermath check-in when they already know each other
        replies[#replies + 1] = {
            speaker = partner,
            addressee = speaker,
            poolID = "semantic.combat.assist.gratitude",
            eventType = "combat_assist_beat",
            domain = "social",
            channel = "social",
            topic = "combat_assist",
            act = "REACT",
            role = "aftermath_checkin",
            family = "combat_assist_gratitude",
            delayMs = 1150,
            priority = 50,
            eventRef = refBase .. ":chk",
            context = flat,
        }
    end

    return {
        threadID = refBase,
        family = isCrossGroup and "combat_assist_companion_exchange" or "combat_assist_gratitude",
        eventRef = refBase,
        ttlMs = 16000,
        opening = {
            speaker = speaker,
            addressee = partner,
            addresseeIsPlayer = partnerIsPlayer,
            poolID = openPool,
            eventType = "combat_assist_beat",
            domain = "social",
            channel = "social",
            topic = "combat_assist",
            inCombat = false,
            act = "THANK",
            role = openRole,
            family = isCrossGroup and "combat_assist_companion_exchange" or "combat_assist_gratitude",
            priority = 55,
            priorityHoldMs = 700,
            holdMs = 800,
            eventRef = refBase .. ":open",
            context = flat,
        },
        replies = replies,
    }
end

Beats.RegisterHook("combat.assist.post_clear", {
    eventTypes = { "combat.assist.protected", "combat.assist.cleared" },
    priority = 55,
    cooldownMs = 5000,
    evaluate = buildAssistPlan,
})

function Beats.OnCombatAssistProtected(spec)
    if type(spec) ~= "table" then return false, "invalid_spec" end
    local targetNPC = resolveNPCByKey(spec.targetKey)
    if not isLiveCalmNPC(targetNPC) then return false, "target_unavailable" end
    if not anyPlayerCanHear(targetNPC) then return false, "not_audible" end

    local er = PNC.EntityRef
    local isRescuerNPC = (er and type(er.IsNPC) == "function")
        and er.IsNPC(spec.actorKey) == true
        or (string.sub(tostring(spec.actorKey or ""), 1, 4) == "npc:")

    local partner, partnerIsPlayer
    if isRescuerNPC then
        partner = resolveNPCByKey(spec.actorKey)
        if not isLiveCalmNPC(partner) then return false, "rescuer_unavailable" end
        partnerIsPlayer = false
    else
        partner = resolvePlayerByKey(spec.actorKey)
        if not partner then return false, "player_unavailable" end
        partnerIsPlayer = true
    end

    local now = nowMs(spec.now)
    local ok, reason = reservePairAndEncounter(spec.encounterID, targetNPC.id, spec.actorKey, now)
    if not ok then return false, reason end

    return Beats.Emit("combat.assist.protected", {
        anchor = targetNPC,
        partner = partner,
        partnerKey = tostring(spec.actorKey),
        addresseeIsPlayer = partnerIsPlayer,
        encounterID = spec.encounterID,
        assistKind = "protected",
        hordeAttack = spec.hordeAttack == true,
        threatCount = tonumber(spec.threatCount) or 1,
        earnedDelta = tonumber(spec.earnedDelta) or 1,
        inCombat = false,
    }, now)
end

function Beats.OnCombatEncounterCleared(spec)
    if type(spec) ~= "table" then return false, "invalid_spec" end
    local er = PNC.EntityRef
    local isLeftNPC = (er and type(er.IsNPC) == "function")
        and er.IsNPC(spec.actorKey) == true
        or (string.sub(tostring(spec.actorKey or ""), 1, 4) == "npc:")
    local isRightNPC = (er and type(er.IsNPC) == "function")
        and er.IsNPC(spec.targetKey) == true
        or (string.sub(tostring(spec.targetKey or ""), 1, 4) == "npc:")

    local speaker, partner, partnerKey, partnerIsPlayer
    if isLeftNPC and isRightNPC then
        local a = resolveNPCByKey(spec.actorKey)
        local b = resolveNPCByKey(spec.targetKey)
        if not isLiveCalmNPC(a) or not isLiveCalmNPC(b) then return false, "pair_unavailable" end
        -- Prefer the external (non-companion) NPC to open if it's a cross-group fight!
        if isCompanion(a) and not isCompanion(b) then
            speaker, partner, partnerKey = b, a, tostring(spec.actorKey)
        else
            speaker, partner, partnerKey = a, b, tostring(spec.targetKey)
        end
        partnerIsPlayer = false
    elseif isLeftNPC then
        speaker = resolveNPCByKey(spec.actorKey)
        partner = resolvePlayerByKey(spec.targetKey)
        partnerKey = tostring(spec.targetKey)
        partnerIsPlayer = true
    elseif isRightNPC then
        speaker = resolveNPCByKey(spec.targetKey)
        partner = resolvePlayerByKey(spec.actorKey)
        partnerKey = tostring(spec.actorKey)
        partnerIsPlayer = true
    else
        return false, "no_npc_participant"
    end

    if not isLiveCalmNPC(speaker) or partner == nil then return false, "actors_unavailable" end
    if not anyPlayerCanHear(speaker) then return false, "not_audible" end

    local now = nowMs(spec.now)
    local ok, reason = reservePairAndEncounter(spec.encounterID, speaker.id, partnerKey, now)
    if not ok then return false, reason end

    return Beats.Emit("combat.assist.cleared", {
        anchor = speaker,
        partner = partner,
        partnerKey = partnerKey,
        addresseeIsPlayer = partnerIsPlayer,
        encounterID = spec.encounterID,
        assistKind = spec.hordeAttack and "horde_cleared" or "cleared",
        hordeAttack = spec.hordeAttack == true,
        threatCount = tonumber(spec.threatCount) or 2,
        earnedDelta = tonumber(spec.earnedDelta) or 1,
        inCombat = false,
    }, now)
end

function Beats.ResetCombatAssistRuntime()
    pairCooldowns, pairOrder = {}, {}
    seenEncounters, encounterOrder = {}, {}
    IdentityBeat.ResetRuntime()
end

return Beats
