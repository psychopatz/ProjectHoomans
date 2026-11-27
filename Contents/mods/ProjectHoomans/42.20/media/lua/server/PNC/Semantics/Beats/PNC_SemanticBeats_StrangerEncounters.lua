-- Unified cross-faction stranger encounters atop ConversationDirector + DialogueBeats.
-- Handles:
--   1. Wary firearm standoffs (gun drawn via CombatStance + AimPistol/AimRifle)
--      scored by group-size ratio, personality/traits, armed posture, and Knox paranoia.
--   2. 3-stance autonomous resolution via ConversationDirector.SelectSuggestionForNPC
--      (comply + exchange names, cautious distance, or defiant pushback).
--   3. Re-encounter reunions and grounded WorldKnowledge/BeatContext road warnings
--      between acquainted NPCs from different factions.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local ENCOUNTER_POOL = "semantic.social.stranger.encounter"
local ENCOUNTER_RADIUS_SQ = 10 * 10
local STANDOFF_COOLDOWN_MS = 180000
local REUNION_COOLDOWN_MS = 240000
local PENDING_ENCOUNTER_TTL_MS = 45000
local MAX_TRACKED_PAIRS = 48
local WARINESS_STANDOFF_THRESHOLD = 0.55

local STANDOFF_FRONTIER = {
    { id = "standoff_comply",   speechAct = "ACCEPT",  decision = "accept",  stance = "stance_positive", priority = 14 },
    { id = "standoff_cautious", speechAct = "CLARIFY", decision = "clarify", stance = "stance_neutral",  priority = 12 },
    { id = "standoff_defiant",  speechAct = "REFUSE",  decision = "refuse",  stance = "stance_negative", priority = 10 },
}

local TERRITORY_FRONTIER = {
    { id = "territory_peaceful", speechAct = "ACCEPT",  decision = "accept",  stance = "stance_positive", priority = 14 },
    { id = "territory_passing",  speechAct = "CLARIFY", decision = "clarify", stance = "stance_neutral",  priority = 12 },
    { id = "territory_defiant",  speechAct = "REFUSE",  decision = "refuse",  stance = "stance_negative", priority = 10 },
}

local AID_FRONTIER = {
    { id = "aid_help",   speechAct = "ACCEPT",  decision = "accept",  stance = "stance_positive", priority = 14 },
    { id = "aid_none",   speechAct = "CLARIFY", decision = "clarify", stance = "stance_neutral",  priority = 12 },
    { id = "aid_refuse", speechAct = "REFUSE",  decision = "refuse",  stance = "stance_negative", priority = 10 },
}

local encounterCooldowns, encounterOrder = {}, {}
local pendingEncounters = {} -- listenerKey -> { kind, speaker, listener, frontier, tokens, createdAt, expiresAt }

local function clamp(val, lo, hi)
    if val < lo then return lo end
    if val > hi then return hi end
    return val
end

local function pairKey(idA, idB)
    local a, b = tostring(idA or ""), tostring(idB or "")
    if a < b then return a .. "|" .. b end
    return b .. "|" .. a
end

local function markCooldown(key, untilAt)
    if encounterCooldowns[key] == nil then
        while #encounterOrder >= MAX_TRACKED_PAIRS do
            local oldest = table.remove(encounterOrder, 1)
            encounterCooldowns[oldest] = nil
        end
        encounterOrder[#encounterOrder + 1] = key
    end
    encounterCooldowns[key] = untilAt
end

local function isHostilePair(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    local h = PNC.Hostility
    if h and type(h.IsHostile) == "function" then
        local ok, res = pcall(h.IsHostile, a, b)
        if ok and res == true then return true end
    end
    local ma = string.lower(tostring(a.hostility and a.hostility.mode or ""))
    local mb = string.lower(tostring(b.hostility and b.hostility.mode or ""))
    return ma == "hostile" or mb == "hostile"
end

local function sameFactionOrGroup(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    if a.groupId ~= nil and b.groupId ~= nil and tostring(a.groupId) ~= "" and a.groupId == b.groupId then
        return true
    end
    local fa = (a.affiliation and a.affiliation.factionID) or a.factionID
    local fb = (b.affiliation and b.affiliation.factionID) or b.factionID
    if fa ~= nil and fb ~= nil and tostring(fa) ~= "" and fa == fb then
        return true
    end
    if a.colonyOwned == true and b.colonyOwned == true then return true end
    return false
end

local function firstNameOf(rec)
    local raw = type(rec) == "table" and (rec.name or rec.fullName or rec.displayName) or nil
    if not raw then return "stranger" end
    local s = string.gsub(tostring(raw), "^%s+", "")
    return string.match(s, "^([^%s]+)") or "stranger"
end

local function hasTrait(rec, traitId)
    local target = string.lower(tostring(traitId or ""))
    if target == "" or type(rec) ~= "table" then return false end
    if PNC.NPCTraitContext and type(PNC.NPCTraitContext.HasTrait) == "function" then
        local ok, res = pcall(PNC.NPCTraitContext.HasTrait, rec, traitId)
        if ok and res == true then return true end
    end
    local traits = rec.traits
    if type(traits) ~= "table" then return false end
    if traits[traitId] == true or traits[target] == true then return true end
    for i = 1, #traits do
        if string.lower(tostring(traits[i] or "")) == target then return true end
    end
    return false
end

local function socialStyleOf(rec)
    if type(rec) ~= "table" then return "neutral" end
    local s = string.lower(tostring(rec.socialStyle or (rec.personality and rec.personality.socialStyle) or ""))
    if s ~= "" then return s end
    if hasTrait(rec, "withdrawn") or hasTrait(rec, "reserved") then return "guarded" end
    if hasTrait(rec, "friendly") or hasTrait(rec, "protective") then return "warm" end
    return "neutral"
end

local function isGuardedStyle(style)
    return style == "hostile" or style == "guarded" or style == "withdrawn"
end

local function isWarmStyle(style)
    return style == "warm" or style == "friendly" or style == "protective"
end

local function liveBodyFor(rec)
    if type(rec) ~= "table" then return nil end
    if rec.zombie ~= nil then return rec.zombie end
    if rec.body ~= nil then return rec.body end
    local reg = PNC.Registry
    if reg and type(reg.GetLiveZombie) == "function" and rec.id ~= nil then
        return reg.GetLiveZombie(rec.id)
    end
    return nil
end

local function findFirearmFor(rec)
    local suicide = PNC.BehaviorSuicide
    if suicide and type(suicide.FindFirearm) == "function" then
        return suicide.FindFirearm(rec)
    end
    return nil
end

local function isCampedOrHome(rec)
    if type(rec) ~= "table" then return false end
    local job = string.lower(tostring(rec.activeJob or rec.activeBehavior or ""))
    if job == "atcamp" or job == "athome" or job == "camp" then return true end
    local orderKind = string.lower(tostring(rec.orderSpec and rec.orderSpec.kind or ""))
    return orderKind == "camp" or orderKind == "guard"
end

local function isMourningActor(rec)
    if type(rec) ~= "table" then return false end
    local job = tostring(rec.activeJob or "")
    if job == "SuicideWitness" then return true end
    return rec.runtime and rec.runtime.suicideWitness ~= nil or false
end

local function detectStrangerNeed(rec)
    if type(rec) ~= "table" then return nil, nil end
    local h = rec.health
    if type(h) == "table" and tonumber(h.current) and tonumber(h.max) and tonumber(h.max) > 0 then
        if (tonumber(h.current) / tonumber(h.max)) < 0.65 then
            return "a bandage", "bandage"
        end
    end
    local thirst = nil
    local hunger = nil
    if PNC.IndividualNeeds and type(PNC.IndividualNeeds.Get) == "function" then
        thirst = tonumber(PNC.IndividualNeeds.Get(rec, "thirst"))
        hunger = tonumber(PNC.IndividualNeeds.Get(rec, "hunger"))
    elseif PNC.WorldHourNeeds and type(PNC.WorldHourNeeds.GetPseudoNeed) == "function" then
        thirst = tonumber(PNC.WorldHourNeeds.GetPseudoNeed(rec, "thirst"))
        hunger = tonumber(PNC.WorldHourNeeds.GetPseudoNeed(rec, "hunger"))
    end
    local needs = type(rec.needs) == "table" and rec.needs or nil
    if thirst == nil and needs then thirst = tonumber(needs.thirst) end
    if hunger == nil and needs then hunger = tonumber(needs.hunger) end
    if (thirst or 0) >= 0.70 then return "some water", "thirst" end
    if (hunger or 0) >= 0.70 then return "some food", "hunger" end
    return nil, nil
end

local function actorTargetKey(actor)
    if type(actor) ~= "table" then return nil end
    if actor.isPlayer == true or actor.kind == "player" or actor.player ~= nil then
        return tostring(actor.key or "player:local")
    end
    return actor.id ~= nil and ("npc:" .. tostring(actor.id)) or nil
end

local function isPlayerActor(actor)
    return type(actor) == "table" and (actor.isPlayer == true or actor.kind == "player" or actor.player ~= nil)
end

local function isActorArmed(actor)
    if isPlayerActor(actor) then
        local p = actor.player
        if p and type(p.getPrimaryHandItem) == "function" then
            local ok, item = pcall(p.getPrimaryHandItem, p)
            if ok and item and type(item.isRanged) == "function" then
                local okR, r = pcall(item.isRanged, item)
                if okR and r == true then return true end
            end
        end
        return actor.armed == true
    end
    local stance = PNC.CombatStance
    return stance and type(stance.IsArmed) == "function" and stance.IsArmed(actor) == true
end

-- Computes encounter wariness [0, 1] from personality, traits, group-size ratio,
-- armed posture, and visible Knox symptoms.
function Beats.ComputeEncounterWariness(actorA, actorB, ctx)
    ctx = type(ctx) == "table" and ctx or {}
    local score = 0.35
    local styleA = socialStyleOf(actorA)

    if isGuardedStyle(styleA) then
        score = score + 0.25
    elseif isWarmStyle(styleA) then
        score = score - 0.18
    end

    if hasTrait(actorA, "frayed_nerves") or hasTrait(actorA, "cowardly") then
        score = score + 0.15
    elseif hasTrait(actorA, "iron_nerves") or hasTrait(actorA, "brave") then
        score = score - 0.08
    end

    local pA = type(actorA) == "table" and type(actorA.personality) == "table" and actorA.personality or nil
    if pA then
        local trust = tonumber(pA.trust or pA.altruism) or 0.5
        if trust < 0.40 then
            score = score + 0.10
        elseif trust >= 0.65 then
            score = score - 0.10
        end
    end

    -- Group size ratio: outnumbered raises caution; outnumbering makes guarded
    -- NPCs bolder to challenge and warm NPCs relaxed enough to greet.
    local sizeA = math.max(1, tonumber(ctx.groupSizeA) or 1)
    local sizeB = math.max(1, tonumber(ctx.groupSizeB) or 1)
    if sizeB > sizeA then
        score = score + 0.12 * math.min(3, sizeB - sizeA)
    elseif sizeA > sizeB then
        if isGuardedStyle(styleA) then
            score = score + 0.08
        elseif isWarmStyle(styleA) then
            score = score - 0.10
        end
    end

    -- Armed posture of other party (actor-agnostic: NPC or Player)
    if isActorArmed(actorB) then
        score = score + 0.18
    end
    if ctx.hasFirearmA == true then
        score = score + 0.06
    end

    -- Visible Knox symptoms on stranger trigger strong paranoia
    local bBody = type(actorB) == "table" and (actorB.health and actorB.health.body or actorB.bodyHealth) or nil
    local bInf = type(bBody) == "table" and type(bBody.infection) == "table" and bBody.infection or nil
    if bInf and bInf.active == true and (tonumber(bInf.progress) or 0) >= 0.45 then
        score = score + 0.30
    end

    return clamp(score, 0.0, 1.0)
end

local function buildGroundedRumor(now)
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    local util = BC and type(BC.GetWorldUtilities) == "function" and BC.GetWorldUtilities(now) or nil
    if util then
        if util.powerOn == false and util.waterOn == false then
            return "both power and water are out across the grid—stock up while you can"
        elseif util.powerOn == false then
            return "the power grid's dead in this area—don't get caught indoors without a light"
        elseif util.waterOn == false then
            return "water's shut off around here—keep your bottles topped off"
        end
    end
    local weather = BC and type(BC.GetWorldWeather) == "function" and BC.GetWorldWeather(now) or nil
    if weather then
        if weather.isRaining == true then
            return "this rain's covering up footsteps—deadheads sneak right up on you"
        elseif weather.isNight == true then
            return "visibility's awful tonight—stick to clear sightlines"
        end
    end
    return nil
end

local function applyEncounterRelationship(a, b, famDelta, appDelta, resDelta, memType, now)
    local relSvc = PNC.Relationships or PNC.RelationshipService
    if not relSvc or type(relSvc.ApplyConversationEffect) ~= "function" then return false end
    local worldHours = PNC.Core and type(PNC.Core.NowWorldAgeHours) == "function"
        and PNC.Core.NowWorldAgeHours() or 0
    local spec = {
        familiarityDelta = famDelta,
        approvalDelta = appDelta,
        respectDelta = resDelta,
        memoryType = memType,
        worldHours = worldHours,
        at = now,
    }
    local keyB = actorTargetKey(b)
    if type(a) == "table" and a.id ~= nil and not isPlayerActor(a) and keyB then
        pcall(relSvc.ApplyConversationEffect, tostring(a.id), keyB, spec)
    end
    local keyA = actorTargetKey(a)
    if type(b) == "table" and b.id ~= nil and not isPlayerActor(b) and keyA then
        pcall(relSvc.ApplyConversationEffect, tostring(b.id), keyA, spec)
    end
    return true
end

if type(Beats.RegisterHook) == "function" then
    Beats.RegisterHook("ambient.stranger_standoff", {
        eventTypes = { "ambient.stranger_standoff" },
        priority = 62,
        cooldownMs = 0,
        evaluate = function(_, payload)
            if type(Beats.BuildWorldThread) ~= "function" then return nil end
            local a, b = payload and payload.anchor, payload and payload.partner
            if type(a) ~= "table" or type(b) ~= "table" then return nil end
            return Beats.BuildWorldThread(a, b, {
                refPrefix = "standoff:" .. pairKey(a.id, b.id),
                family = "npc_stranger_standoff",
                poolID = ENCOUNTER_POOL,
                eventType = "ambient_stranger_standoff",
                domain = "social",
                channel = "social",
                topic = "stranger_standoff",
                openAct = "STOP",
                openRole = "standoff_challenge_armed",
                replyAct = tostring(payload.replyAct or "ACCEPT"),
                replyRole = tostring(payload.replyRole or "standoff_reply_comply"),
                chimeAct = tostring(payload.resolveAct or "CHAT"),
                chimeRole = tostring(payload.resolveRole or "standoff_resolve_peaceful"),
                third = a,
                delayMs = 1900,
                priority = 62,
                tokens = payload.tokens,
                context = { topic = "stranger_standoff" },
            })
        end,
    })

    Beats.RegisterHook("ambient.stranger_reunion", {
        eventTypes = { "ambient.stranger_reunion" },
        priority = 54,
        cooldownMs = 0,
        evaluate = function(_, payload)
            if type(Beats.BuildWorldThread) ~= "function" then return nil end
            local a, b = payload and payload.anchor, payload and payload.partner
            if type(a) ~= "table" then return nil end
            return Beats.BuildWorldThread(a, not isPlayerActor(b) and b or nil, {
                refPrefix = "reunion:" .. pairKey(a.id, b and b.id or "player"),
                family = "npc_stranger_reunion",
                poolID = ENCOUNTER_POOL,
                eventType = "ambient_stranger_reunion",
                domain = "social",
                channel = "social",
                topic = "stranger_reunion",
                openAct = "GREET",
                openRole = tostring(payload.openRole or "reunion_open"),
                replyAct = "GREET",
                replyRole = tostring(payload.replyRole or "reunion_reply"),
                delayMs = 1750,
                priority = 54,
                tokens = payload.tokens,
                context = { topic = "stranger_reunion" },
            })
        end,
    })

    Beats.RegisterHook("ambient.stranger_territory", {
        eventTypes = { "ambient.stranger_territory" },
        priority = 60,
        cooldownMs = 0,
        evaluate = function(_, payload)
            if type(Beats.BuildWorldThread) ~= "function" then return nil end
            local a, b = payload and payload.anchor, payload and payload.partner
            if type(a) ~= "table" then return nil end
            local npcB = not isPlayerActor(b) and b or nil
            return Beats.BuildWorldThread(a, npcB, {
                refPrefix = "territory:" .. pairKey(a.id, b and b.id or "player"),
                family = "npc_stranger_territory",
                poolID = ENCOUNTER_POOL,
                eventType = "ambient_stranger_territory",
                domain = "social",
                channel = "social",
                topic = "stranger_territory",
                openAct = "STOP",
                openRole = "territory_challenge_open",
                replyAct = npcB and tostring(payload.replyAct or "ACCEPT") or nil,
                replyRole = npcB and tostring(payload.replyRole or "territory_reply_peaceful") or nil,
                chimeAct = npcB and tostring(payload.resolveAct or "CHAT") or nil,
                chimeRole = npcB and tostring(payload.resolveRole or "territory_resolve_welcome") or nil,
                third = npcB and a or nil,
                delayMs = 1850,
                priority = 60,
                tokens = payload.tokens,
                context = { topic = "stranger_territory" },
            })
        end,
    })

    Beats.RegisterHook("ambient.stranger_aid", {
        eventTypes = { "ambient.stranger_aid" },
        priority = 58,
        cooldownMs = 0,
        evaluate = function(_, payload)
            if type(Beats.BuildWorldThread) ~= "function" then return nil end
            local a, b = payload and payload.anchor, payload and payload.partner
            if type(a) ~= "table" then return nil end
            local npcB = not isPlayerActor(b) and b or nil
            return Beats.BuildWorldThread(a, npcB, {
                refPrefix = "aid:" .. pairKey(a.id, b and b.id or "player"),
                family = "npc_stranger_aid",
                poolID = ENCOUNTER_POOL,
                eventType = "ambient_stranger_aid",
                domain = "social",
                channel = "social",
                topic = "stranger_aid",
                openAct = "REQUEST",
                openRole = "aid_request_open",
                replyAct = npcB and tostring(payload.replyAct or "ACCEPT") or nil,
                replyRole = npcB and tostring(payload.replyRole or "aid_reply_help") or nil,
                chimeAct = npcB and tostring(payload.resolveAct or "THANK") or nil,
                chimeRole = npcB and tostring(payload.resolveRole or "aid_resolve_grateful") or nil,
                third = npcB and a or nil,
                delayMs = 1850,
                priority = 58,
                tokens = payload.tokens,
                context = { topic = "stranger_aid" },
            })
        end,
    })

    Beats.RegisterHook("ambient.mourning_witness", {
        eventTypes = { "ambient.mourning_witness" },
        priority = 56,
        cooldownMs = 0,
        evaluate = function(_, payload)
            if type(Beats.BuildWorldThread) ~= "function" then return nil end
            local a = payload and payload.anchor
            if type(a) ~= "table" then return nil end
            return Beats.BuildWorldThread(a, nil, {
                refPrefix = "mourn_witness:" .. tostring(a.id),
                family = "npc_mourning_witness",
                poolID = ENCOUNTER_POOL,
                eventType = "ambient_mourning_witness",
                domain = "social",
                channel = "social",
                topic = "mourning_witness",
                openAct = "INFORM",
                openRole = "mourning_witness",
                priority = 56,
                tokens = payload.tokens,
                context = { topic = "mourning_witness" },
            })
        end,
    })
end

function Beats.GetPendingStrangerEncounter(listenerKey, at)
    local key = tostring(listenerKey or "")
    local entry = pendingEncounters[key]
    if not entry then return nil end
    if at ~= nil and tonumber(at) > (tonumber(entry.expiresAt) or 0) then
        pendingEncounters[key] = nil
        return nil
    end
    return entry
end

-- Actor-agnostic 3-stance resolution for player responses to standoff, territory,
-- or aid encounters (NPC responders resolve through the exact same stance rules).
function Beats.ResolveStrangerEncounterChoice(listenerKey, decision, opts)
    opts = type(opts) == "table" and opts or {}
    local key = tostring(listenerKey or "")
    local entry = pendingEncounters[key]
    if not entry then return false, "no_pending_encounter" end
    pendingEncounters[key] = nil

    local dec = string.lower(tostring(decision or "clarify"))
    local act = (dec == "accept" or dec == "comply" or dec == "help" or dec == "peaceful") and "ACCEPT"
        or ((dec == "refuse" or dec == "defiant") and "REFUSE" or "CLARIFY")
    local now = tonumber(opts.now) or (PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()) or 0)
    local a, b = entry.speaker, entry.listener

    if entry.kind == "standoff" then
        if act == "ACCEPT" then
            if PNC.CombatStance and type(PNC.CombatStance.Clear) == "function" then
                pcall(PNC.CombatStance.Clear, a)
            end
            applyEncounterRelationship(a, b, 5, 2, 1, "standoff_deescalated", now)
        elseif act == "CLARIFY" then
            applyEncounterRelationship(a, b, 2, 0, 0, "standoff_cautious", now)
        else
            applyEncounterRelationship(a, b, 1, -3, 0, "standoff_friction", now)
        end
    elseif entry.kind == "territory" then
        if act == "ACCEPT" then
            applyEncounterRelationship(a, b, 5, 2, 1, "territory_welcomed", now)
        elseif act == "CLARIFY" then
            applyEncounterRelationship(a, b, 2, 0, 0, "territory_passed", now)
        else
            applyEncounterRelationship(a, b, 1, -3, 0, "territory_friction", now)
        end
    elseif entry.kind == "aid" then
        if act == "ACCEPT" then
            applyEncounterRelationship(a, b, 8, 6, 3, "aid_granted", now)
        elseif act == "CLARIFY" then
            applyEncounterRelationship(a, b, 2, 1, 0, "aid_unavailable", now)
        else
            applyEncounterRelationship(a, b, 0, -4, -1, "aid_refused", now)
        end
    end

    return true, act
end

function Beats.TryCrossFactionEncounter(groups, now, density, audit)
    local ref = PNC.ActorReference or (PNC.Semantics and PNC.Semantics.ActorReference)
    if not ref or type(ref.KnowsName) ~= "function" then return false end
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil

    -- Index group sizes and flatten calm NPCs from already-gathered groups
    local actors = {}
    local groupSizeByActor = {}
    local seen = {}
    for gi = 1, #groups do
        local members = groups[gi] and groups[gi].members or nil
        if type(members) == "table" then
            local gSize = #members
            for mi = 1, gSize do
                local m = members[mi]
                if type(m) == "table" and m.id ~= nil and not seen[tostring(m.id)] then
                    seen[tostring(m.id)] = true
                    actors[#actors + 1] = m
                    groupSizeByActor[tostring(m.id)] = gSize
                end
            end
        end
    end
    if #actors < 2 then return false end

    for i = 1, #actors - 1 do
        local a = actors[i]
        for j = i + 1, #actors do
            local b = actors[j]
            if not sameFactionOrGroup(a, b) and not isHostilePair(a, b) then
                local az, bz = tonumber(a.z) or 0, tonumber(b.z) or 0
                local dx = (tonumber(a.x) or 0) - (tonumber(b.x) or 0)
                local dy = (tonumber(a.y) or 0) - (tonumber(b.y) or 0)
                local pKey = pairKey(a.id, b.id)
                if math.abs(az - bz) < 1 and (dx * dx + dy * dy) <= ENCOUNTER_RADIUS_SQ
                    and now >= (tonumber(encounterCooldowns[pKey]) or 0)
                then
                    local knows = ref.KnowsName(a, b)
                    local cdScale = tonumber(density and density.cooldownScale) or 1.0

                    if knows then
                        -- Re-encounter reunion or grounded road warning
                        local admitted = true
                        if Dir and type(Dir.EvaluateCandidate) == "function" then
                            admitted = Dir.EvaluateCandidate({
                                speaker = a,
                                scopeKey = "reunion:" .. pKey,
                                groupKey = "reunion:" .. pKey,
                                topic = "stranger_reunion",
                                tier = 1,
                                urgency = 28,
                                salience = 55,
                                saturationWindowMs = 60000,
                                silenceThreshold = 40,
                                markOnAdmit = false,
                                now = now,
                            })
                        end
                        if admitted then
                            local rumor = buildGroundedRumor(now)
                            local openRole = rumor and "rumor_warn_open" or "reunion_open"
                            local replyRole = rumor and "rumor_warn_reply" or "reunion_reply"
                            local ok, res = Beats.Emit("ambient.stranger_reunion", {
                                anchor = a,
                                partner = b,
                                openRole = openRole,
                                replyRole = replyRole,
                                tokens = {
                                    ["addressee.name"] = ref.NameFor(a, b, { role = "vocative" }),
                                    ["slot.rumor"] = rumor or "",
                                },
                            }, now)
                            if ok then
                                markCooldown(pKey, now + math.floor(REUNION_COOLDOWN_MS * cdScale))
                                applyEncounterRelationship(a, b, 2, 1, 1, "reunion", now)
                                if Dir and type(Dir.MarkSpoken) == "function" then
                                    Dir.MarkSpoken("reunion:" .. pKey, "stranger_reunion", 1, now, a.id)
                                end
                                if audit then
                                    Beats.AuditLog("stranger_reunion", {
                                        "speaker=" .. tostring(a.id),
                                        "partner=" .. tostring(b.id),
                                        "rumor=" .. tostring(rumor ~= nil),
                                    })
                                end
                                return true, res
                            end
                        end
                    else
                        -- First contact (actor-agnostic: NPC <-> NPC or Stranger NPC <-> Player)
                        if isMourningActor(b) then
                            local ok, res = Beats.Emit("ambient.mourning_witness", {
                                anchor = a,
                                partner = b,
                                tokens = {
                                    ["addressee.name"] = ref.NameFor(a, b, { role = "vocative", unknownAddress = "stranger" }),
                                },
                            }, now)
                            if ok then
                                markCooldown(pKey, now + math.floor(STANDOFF_COOLDOWN_MS * cdScale))
                                return true, res
                            end
                        end

                        local firearmA = findFirearmFor(a)
                        local wariness = Beats.ComputeEncounterWariness(a, b, {
                            groupSizeA = groupSizeByActor[tostring(a.id)] or 1,
                            groupSizeB = groupSizeByActor[tostring(b.id)] or 1,
                            hasFirearmA = firearmA ~= nil,
                        })
                        if firearmA and wariness >= WARINESS_STANDOFF_THRESHOLD then
                            local admitted = true
                            if Dir and type(Dir.EvaluateCandidate) == "function" then
                                admitted = Dir.EvaluateCandidate({
                                    speaker = a,
                                    scopeKey = "standoff:" .. pKey,
                                    groupKey = "standoff:" .. pKey,
                                    topic = "stranger_standoff",
                                    tier = 2,
                                    urgency = 55,
                                    salience = 72,
                                    saturationWindowMs = 45000,
                                    silenceThreshold = 34,
                                    markOnAdmit = false,
                                    now = now,
                                })
                            end
                            if admitted then
                                local bodyA = liveBodyFor(a)
                                if PNC.CombatStance and type(PNC.CombatStance.Maintain) == "function" then
                                    pcall(PNC.CombatStance.Maintain, a, now)
                                end
                                if bodyA and PNC.Equipment and type(PNC.Equipment.Apply) == "function" then
                                    pcall(PNC.Equipment.Apply, bodyA, a)
                                end
                                local Perf = PNC.Semantics and PNC.Semantics.SpeechPerformance or nil
                                if Perf and type(Perf.Perform) == "function" then
                                    Perf.Perform(a, {
                                        anim = firearmA.kind == "handgun" and "PNC_Anim_AimPistol" or "PNC_Anim_AimRifle",
                                        animDurationMs = 3200,
                                        voice = "shout",
                                        reason = "stranger_standoff_aim",
                                    }, now)
                                end

                                local bIsPlayer = isPlayerActor(b)
                                local act = "ACCEPT"
                                local replyRole, resolveRole = "standoff_reply_comply", "standoff_resolve_peaceful"
                                if not bIsPlayer then
                                    local chosen = Dir and type(Dir.SelectSuggestionForNPC) == "function"
                                        and Dir.SelectSuggestionForNPC(b, a, STANDOFF_FRONTIER, {
                                            now = now,
                                            sceneTension = 65,
                                        }) or STANDOFF_FRONTIER[1]
                                    act = tostring(chosen and chosen.speechAct or "ACCEPT")
                                    replyRole = act == "REFUSE" and "standoff_reply_defiant"
                                        or (act == "CLARIFY" and "standoff_reply_cautious" or "standoff_reply_comply")
                                    resolveRole = act == "REFUSE" and "standoff_resolve_cold"
                                        or (act == "CLARIFY" and "standoff_resolve_tense" or "standoff_resolve_peaceful")
                                    if act == "REFUSE" and findFirearmFor(b) then
                                        local bodyB = liveBodyFor(b)
                                        if PNC.CombatStance and type(PNC.CombatStance.Maintain) == "function" then
                                            pcall(PNC.CombatStance.Maintain, b, now)
                                        end
                                        if bodyB and PNC.Equipment and type(PNC.Equipment.Apply) == "function" then
                                            pcall(PNC.Equipment.Apply, bodyB, b)
                                        end
                                    end
                                end

                                local standoffTokens = {
                                    ["addressee.name"] = "stranger",
                                    ["speaker.name"] = firstNameOf(a),
                                    ["claimed.name"] = firstNameOf(b),
                                    ["slot.weapon"] = firearmA.weaponLabel or "gun",
                                }
                                local ok, res = Beats.Emit("ambient.stranger_standoff", {
                                    anchor = a,
                                    partner = b,
                                    replyAct = act,
                                    replyRole = replyRole,
                                    resolveAct = act == "ACCEPT" and "ACCEPT" or "STOP",
                                    resolveRole = resolveRole,
                                    tokens = standoffTokens,
                                }, now)
                                if ok then
                                    markCooldown(pKey, now + math.floor(STANDOFF_COOLDOWN_MS * cdScale))
                                    if bIsPlayer then
                                        pendingEncounters[actorTargetKey(b)] = {
                                            kind = "standoff",
                                            speaker = a,
                                            listener = b,
                                            frontier = STANDOFF_FRONTIER,
                                            tokens = standoffTokens,
                                            createdAt = now,
                                            expiresAt = now + PENDING_ENCOUNTER_TTL_MS,
                                        }
                                    elseif act == "ACCEPT" then
                                        applyEncounterRelationship(a, b, 5, 2, 1, "standoff_deescalated", now)
                                    elseif act == "CLARIFY" then
                                        applyEncounterRelationship(a, b, 2, 0, 0, "standoff_cautious", now)
                                    else
                                        applyEncounterRelationship(a, b, 1, -3, 0, "standoff_friction", now)
                                    end
                                    if Dir and type(Dir.MarkSpoken) == "function" then
                                        Dir.MarkSpoken("standoff:" .. pKey, "stranger_standoff", 2, now, a.id)
                                    end
                                    if audit then
                                        Beats.AuditLog("stranger_standoff", {
                                            "speaker=" .. tostring(a.id),
                                            "partner=" .. tostring(b.id),
                                            string.format("wariness=%.2f", wariness),
                                            "weapon=" .. tostring(firearmA.fullType),
                                            "replyAct=" .. (bIsPlayer and "pending_player" or act),
                                        })
                                    end
                                    return true, res
                                end
                            end
                        elseif isCampedOrHome(a) then
                            -- Territory / camp boundary challenge (actor-agnostic)
                            local bIsPlayer = isPlayerActor(b)
                            local act = "ACCEPT"
                            local replyRole, resolveRole = "territory_reply_peaceful", "territory_resolve_welcome"
                            if not bIsPlayer then
                                local chosen = Dir and type(Dir.SelectSuggestionForNPC) == "function"
                                    and Dir.SelectSuggestionForNPC(b, a, TERRITORY_FRONTIER, { now = now, sceneTension = 35 })
                                    or TERRITORY_FRONTIER[1]
                                act = tostring(chosen and chosen.speechAct or "ACCEPT")
                                replyRole = act == "REFUSE" and "territory_reply_defiant"
                                    or (act == "CLARIFY" and "territory_reply_passing" or "territory_reply_peaceful")
                                resolveRole = act == "REFUSE" and "territory_resolve_cold"
                                    or (act == "CLARIFY" and "territory_resolve_cautious" or "territory_resolve_welcome")
                            end
                            local tTokens = {
                                ["addressee.name"] = "stranger",
                                ["speaker.name"] = firstNameOf(a),
                                ["claimed.name"] = firstNameOf(b),
                            }
                            local ok, res = Beats.Emit("ambient.stranger_territory", {
                                anchor = a,
                                partner = b,
                                replyAct = act,
                                replyRole = replyRole,
                                resolveAct = act == "ACCEPT" and "ACCEPT" or "STOP",
                                resolveRole = resolveRole,
                                tokens = tTokens,
                            }, now)
                            if ok then
                                markCooldown(pKey, now + math.floor(STANDOFF_COOLDOWN_MS * cdScale))
                                if bIsPlayer then
                                    pendingEncounters[actorTargetKey(b)] = {
                                        kind = "territory",
                                        speaker = a,
                                        listener = b,
                                        frontier = TERRITORY_FRONTIER,
                                        tokens = tTokens,
                                        createdAt = now,
                                        expiresAt = now + PENDING_ENCOUNTER_TTL_MS,
                                    }
                                elseif act == "ACCEPT" then
                                    applyEncounterRelationship(a, b, 5, 2, 1, "territory_welcomed", now)
                                elseif act == "CLARIFY" then
                                    applyEncounterRelationship(a, b, 2, 0, 0, "territory_passed", now)
                                else
                                    applyEncounterRelationship(a, b, 1, -3, 0, "territory_friction", now)
                                end
                                return true, res
                            end
                        else
                            -- Mercy / micro-aid request when stranger A is visibly hurt/hungry/thirsty
                            local needLabel, needKind = detectStrangerNeed(a)
                            if needLabel then
                                local bIsPlayer = isPlayerActor(b)
                                local act = "ACCEPT"
                                local replyRole, resolveRole = "aid_reply_help", "aid_resolve_grateful"
                                if not bIsPlayer then
                                    local chosen = Dir and type(Dir.SelectSuggestionForNPC) == "function"
                                        and Dir.SelectSuggestionForNPC(b, a, AID_FRONTIER, { now = now, sceneTension = 20 })
                                        or AID_FRONTIER[1]
                                    act = tostring(chosen and chosen.speechAct or "ACCEPT")
                                    replyRole = act == "REFUSE" and "aid_reply_refuse"
                                        or (act == "CLARIFY" and "aid_reply_none" or "aid_reply_help")
                                    resolveRole = act == "REFUSE" and "aid_resolve_bitter"
                                        or (act == "CLARIFY" and "aid_resolve_understand" or "aid_resolve_grateful")
                                end
                                local aidTokens = {
                                    ["addressee.name"] = "friend",
                                    ["speaker.name"] = firstNameOf(a),
                                    ["claimed.name"] = firstNameOf(b),
                                    ["slot.need"] = needLabel,
                                }
                                local ok, res = Beats.Emit("ambient.stranger_aid", {
                                    anchor = a,
                                    partner = b,
                                    replyAct = act,
                                    replyRole = replyRole,
                                    resolveAct = act == "ACCEPT" and "THANK" or "INFORM",
                                    resolveRole = resolveRole,
                                    tokens = aidTokens,
                                }, now)
                                if ok then
                                    markCooldown(pKey, now + math.floor(STANDOFF_COOLDOWN_MS * cdScale))
                                    if bIsPlayer then
                                        pendingEncounters[actorTargetKey(b)] = {
                                            kind = "aid",
                                            speaker = a,
                                            listener = b,
                                            frontier = AID_FRONTIER,
                                            tokens = aidTokens,
                                            createdAt = now,
                                            expiresAt = now + PENDING_ENCOUNTER_TTL_MS,
                                        }
                                    elseif act == "ACCEPT" then
                                        applyEncounterRelationship(a, b, 8, 6, 3, "aid_granted", now)
                                        if (needKind == "hunger" or needKind == "thirst")
                                            and PNC.WorldHourNeeds and type(PNC.WorldHourNeeds.SatisfyPseudoNeed) == "function"
                                        then
                                            PNC.WorldHourNeeds.SatisfyPseudoNeed(a, needKind, 0.55)
                                        end
                                    elseif act == "CLARIFY" then
                                        applyEncounterRelationship(a, b, 2, 1, 0, "aid_unavailable", now)
                                    else
                                        applyEncounterRelationship(a, b, 0, -4, -1, "aid_refused", now)
                                    end
                                    return true, res
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

function Beats.ResetStrangerEncountersRuntime()
    encounterCooldowns, encounterOrder = {}, {}
    pendingEncounters = {}
end

local EncDir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
if EncDir and type(EncDir.RegisterTopicAxis) == "function" then
    EncDir.RegisterTopicAxis("stranger_standoff", "caution")
    EncDir.RegisterTopicAxis("stranger_territory", "caution")
    EncDir.RegisterTopicAxis("stranger_aid", "compassion")
    EncDir.RegisterTopicAxis("stranger_reunion", "social")
    EncDir.RegisterTopicAxis("mourning_witness", "compassion")
end

return Beats
