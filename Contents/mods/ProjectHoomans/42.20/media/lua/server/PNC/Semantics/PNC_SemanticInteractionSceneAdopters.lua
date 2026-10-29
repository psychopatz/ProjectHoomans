-- Production cross-domain adopters for the generic Interaction Scene Runtime.
-- Event owners call this module at authoritative transition boundaries. It
-- owns no polling loop, gameplay mutation, transcript, or parallel scheduler.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Opportunity = require
    "PNC/Semantics/PNC_SemanticInteractionOpportunity"
local Runtime = require
    "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"
local EncounterIntent = require
    "PNC/Semantics/PNC_SemanticCombatEncounterIntent"
local BanterArbiter = require
    "PNC/Semantics/PNC_SemanticCombatBanterArbiter"
local SocialDirector = require
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialDirector"
local SocialConversation = require
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialConversation"
local SocialConsequences = require
    "PNC/Semantics/PNC_SemanticSocialConsequenceService"
local SocialAudit = require
    "PNC/Semantics/PNC_SemanticSocialDirectorAudit"
local SceneTransport = require
    "PNC/Semantics/PNC_SemanticInteractionSceneTransport"

local Adopters = PNC.Semantics.InteractionSceneAdopters or {}
PNC.Semantics.InteractionSceneAdopters = Adopters

Adopters.VERSION = 1
Adopters.COMBAT_RADIUS = 14
Adopters.KNOWLEDGE_RADIUS = 18
Adopters.MAX_PARTICIPANTS = 4
Adopters.COMBAT_COOLDOWN_MS = 12000
Adopters.KNOWLEDGE_COOLDOWN_MS = 20000
Adopters.EXCURSION_COOLDOWN_MS = 5000
Adopters.TASK_SOCIAL_COOLDOWN_MS = 9000
Adopters.POST_COMBAT_COOLDOWN_MS = 15000

Adopters._metrics = Adopters._metrics or {
    actorQueries = 0,
    hordeEvents = 0,
    postCombatEvents = 0,
    knowledgeEvents = 0,
    excursionEvents = 0,
    taskEvents = 0,
}
local metrics = Adopters._metrics

local manager = Adopters._manager
if type(manager) ~= "table" then
    manager = Opportunity.New(Runtime.Default())
    Adopters._manager = manager
end

local function managerClock()
    return type(manager) == "table" and type(manager.Now) == "function"
        and manager:Now() or 0
end

local socialDirector = Adopters._socialDirector
if type(socialDirector) ~= "table" then
    socialDirector = SocialDirector.New(manager, { clock = managerClock })
    Adopters._socialDirector = socialDirector
end
local socialConversation = Adopters._socialConversation
if type(socialConversation) ~= "table" then
    socialConversation = SocialConversation.New({
        effectSink = SocialConsequences.Apply,
    })
    Adopters._socialConversation = socialConversation
end
SocialAudit.Bind(socialDirector, socialConversation)

local function clean(value, maximum)
    value = tostring(value or "")
    if value == "" or string.find(value, "%c") then return nil end
    return string.sub(value, 1, maximum or 128)
end

local function spatialSnapshot(value)
    if type(value) ~= "table" then return nil end
    return {
        targetKind = clean(value.targetKind, 64),
        targetRef = clean(value.targetRef, 128),
        targetPositionSource = clean(value.targetPositionSource, 64),
        headingSource = clean(value.headingSource, 64),
        clockHour = tonumber(value.clockHour),
        clockToken = clean(value.clockToken, 16),
        relativeSector8 = clean(value.relativeSector8, 32),
        distance = tonumber(value.distance),
        distanceBand = clean(value.distanceBand, 32),
        sameArea = value.sameArea == true,
        freshnessMs = tonumber(value.freshnessMs),
        presentationMode = clean(value.presentationMode, 16),
        presentationReason = clean(value.presentationReason, 96),
    }
end

local function distanceSq(first, second)
    local ax = tonumber(first and first.x)
    local ay = tonumber(first and first.y)
    local az = tonumber(first and first.z)
    local bx = tonumber(second and second.x)
    local by = tonumber(second and second.y)
    local bz = tonumber(second and second.z)
    if not ax or not ay or not bx or not by then return math.huge end
    if az and bz and math.abs(az - bz) >= 1 then return math.huge end
    local dx = ax - bx
    local dy = ay - by
    return dx * dx + dy * dy
end

local function coordinate(value, field, method)
    if type(value) ~= "table" and type(value) ~= "userdata" then return nil end
    local direct = type(value) == "table" and tonumber(value[field]) or nil
    if direct ~= nil then return direct end
    local fn = value[method]
    if type(fn) == "function" then
        local ok, result = pcall(fn, value)
        if ok then return tonumber(result) end
    end
    return nil
end

local function observerKey(player)
    if not player then return nil end
    if type(player.getOnlineID) == "function" then
        local ok, value = pcall(player.getOnlineID, player)
        if ok and value ~= nil then return "online:" .. tostring(value) end
    end
    if type(player.getUsername) == "function" then
        local ok, value = pcall(player.getUsername, player)
        value = ok and tostring(value or "") or ""
        if value ~= "" then return "user:" .. value end
    end
    return nil
end

local function audienceFromPlayers(players, x, y, z, radius)
    local output = {}
    local seen = {}
    local radiusSq = radius * radius
    for _, player in ipairs(type(players) == "table" and players or {}) do
        local px = coordinate(player, "x", "getX")
        local py = coordinate(player, "y", "getY")
        local pz = coordinate(player, "z", "getZ")
        local key = observerKey(player)
        if key and not seen[key] and px and py
            and (z == nil or pz == nil or math.abs(z - pz) < 1)
        then
            local dx = px - x
            local dy = py - y
            if dx * dx + dy * dy <= radiusSq then
                output[#output + 1] = {
                    player = player,
                    actorID = key,
                    role = "observer",
                }
                seen[key] = true
                if #output >= Opportunity.MAX_AUDIENCE then break end
            end
        end
    end
    return output
end

local function localActors(x, y, radius)
    local spatial = PNC.SpatialIndex
    if not spatial or type(spatial.QueryActors) ~= "function" then
        return nil, "scene_actor_query_unavailable"
    end
    metrics.actorQueries = metrics.actorQueries + 1
    return spatial.QueryActors(x, y, radius)
end

local function participant(record, requestedFactRefs)
    if type(record) ~= "table" or record.alive == false or not record.id then
        return nil
    end
    local adapterContext = {}
    if type(requestedFactRefs) == "table" and #requestedFactRefs > 0 then
        adapterContext.requestedFactRefs = requestedFactRefs
    end
    return {
        id = tostring(record.id),
        actor = record,
        kind = "npc",
        adapterContext = adapterContext,
    }
end

local function factionID(record)
    if PNC.Factions and type(PNC.Factions.GetFactionID) == "function" then
        return PNC.Factions.GetFactionID(record)
    end
    return record and record.affiliation
        and record.affiliation.factionID or nil
end

local function sameCombatCohort(anchor, candidate)
    if not anchor or not candidate or anchor == candidate
        or candidate.alive == false
    then
        return false
    end
    local owner = EncounterIntent.OwnerKey(anchor)
    if owner and owner == EncounterIntent.OwnerKey(candidate) then
        return true
    end
    local left = factionID(anchor)
    local right = factionID(candidate)
    return left ~= nil and right ~= nil
        and tostring(left) == tostring(right)
end

local function localCombatContext(record)
    local participants = {}
    local first = participant(record)
    if not first then return participants, {} end
    participants[1] = first

    local x = tonumber(record.x) or 0
    local y = tonumber(record.y) or 0
    local z = tonumber(record.z)
    local radius = Adopters.COMBAT_RADIUS
    local area = localActors(x, y, radius)
    if type(area) ~= "table" then return participants, {} end
    local radiusSq = radius * radius
    local ranked = {}
    for _, candidate in ipairs(type(area.npcs) == "table" and area.npcs or {}) do
        if sameCombatCohort(record, candidate) then
            local dsq = distanceSq(record, candidate)
            if dsq <= radiusSq then
                ranked[#ranked + 1] = {
                    record = candidate,
                    distanceSq = dsq,
                    id = tostring(candidate.id or ""),
                }
            end
        end
    end
    table.sort(ranked, function(left, right)
        if left.distanceSq ~= right.distanceSq then
            return left.distanceSq < right.distanceSq
        end
        return left.id < right.id
    end)
    for _, row in ipairs(ranked) do
        local value = participant(row.record)
        if value then
            participants[#participants + 1] = value
            if #participants >= Adopters.MAX_PARTICIPANTS then break end
        end
    end
    return participants, audienceFromPlayers(
        area.players, x, y, z, radius
    )
end

local function localKnowledgeContext(spec)
    local participants = {}
    local world = PNC.WorldKnowledge
    local factID = clean(spec and spec.factID, 128)
    if not factID or not world or type(world.Explain) ~= "function" then
        return participants, {}
    end
    local x = tonumber(spec.x)
    local y = tonumber(spec.y)
    local z = tonumber(spec.z)
    if not x or not y then return participants, {} end
    local radius = Adopters.KNOWLEDGE_RADIUS
    local area = localActors(x, y, radius)
    if type(area) ~= "table" then return participants, {} end
    local radiusSq = radius * radius
    local wantedFaction = clean(spec.factionID, 128)
    local ranked = {}
    for _, record in ipairs(type(area.npcs) == "table" and area.npcs or {}) do
        if record and record.alive ~= false and record.id then
            local sameFaction = wantedFaction == nil
                or tostring(factionID(record) or "") == wantedFaction
            local dz = z ~= nil and tonumber(record.z) ~= nil
                and math.abs(z - tonumber(record.z)) or 0
            local dx = (tonumber(record.x) or x) - x
            local dy = (tonumber(record.y) or y) - y
            local dsq = dx * dx + dy * dy
            if sameFaction and dz < 1 and dsq <= radiusSq then
                ranked[#ranked + 1] = {
                    record = record,
                    distanceSq = dsq,
                    id = tostring(record.id),
                }
            end
        end
    end
    table.sort(ranked, function(left, right)
        if left.distanceSq ~= right.distanceSq then
            return left.distanceSq < right.distanceSq
        end
        return left.id < right.id
    end)

    local speakerIndex
    for index, row in ipairs(ranked) do
        if world.Explain(row.record, factID) ~= nil then
            speakerIndex = index
            break
        end
    end
    if not speakerIndex then
        return participants, audienceFromPlayers(area.players, x, y, z, radius)
    end

    participants[#participants + 1] = participant(
        ranked[speakerIndex].record,
        { factID }
    )
    for index, row in ipairs(ranked) do
        if index ~= speakerIndex then
            participants[#participants + 1] = participant(row.record)
            if #participants >= Adopters.MAX_PARTICIPANTS then break end
        end
    end
    if #participants < 2 then participants = {} end
    return participants, audienceFromPlayers(area.players, x, y, z, radius)
end

local function excursionContext(factionID)
    local service = PNC.CommunityExcursionService
    local registry = PNC.Registry
    if not service or type(service.Get) ~= "function"
        or not registry or type(registry.Get) ~= "function"
    then
        return {}, {}
    end
    local excursion = service.Get(factionID)
    local ids = type(excursion) == "table"
        and type(excursion.participants) == "table"
        and excursion.participants or {}
    local participants = {}
    local anchor
    for index = 1, math.min(#ids, Adopters.MAX_PARTICIPANTS) do
        local record = registry.Get(ids[index])
        local value = participant(record)
        if value then
            participants[#participants + 1] = value
            anchor = anchor or record
        end
    end
    if #participants < 2 then return {}, {} end
    local x = tonumber(anchor and anchor.x)
    local y = tonumber(anchor and anchor.y)
    local z = tonumber(anchor and anchor.z)
    if not x or not y then return participants, {} end
    local area = localActors(x, y, Adopters.KNOWLEDGE_RADIUS)
    local audience = type(area) == "table"
        and audienceFromPlayers(
            area.players, x, y, z, Adopters.KNOWLEDGE_RADIUS
        ) or {}
    return participants, audience
end

local EXCURSION_INTENT = {
    PREPARING = "EXCURSION_PREPARING",
    OUTBOUND = "EXCURSION_DEPARTING",
    RETURNING_HOME = "EXCURSION_RETURNING",
    AT_HOME = "EXCURSION_HOME",
    FAILED = "EXCURSION_FAILED",
}

local function registerProviders()
    Opportunity.RegisterProvider({
        id = "projecthoomans.scene.combat_horde",
        order = 10,
        stimuli = { "DANGER_CHANGED" },
        propose = function(event, context)
            local participants = type(context) == "table"
                and context.participants or nil
            if type(participants) ~= "table" or #participants < 2 then
                return {}
            end
            local speakerID = clean(context.speakerID, 128)
            if not speakerID then return {} end
            local episodeID = clean(event.episodeID or event.id, 128)
            if not episodeID then return {} end
            local spatial = spatialSnapshot(event.spatial)
            return {
                id = "combat-horde:" .. episodeID,
                dedupeKey = "combat-horde:" .. episodeID,
                priority = 90,
                cooldownMs = Adopters.COMBAT_COOLDOWN_MS,
                participants = participants,
                audience = context.audience,
                topic = "COMBAT",
                ttlMs = 12000,
                maxTurns = 3,
                perceived = true,
                autoContinue = true,
                maxContinuationSteps = 2,
                world = {
                    danger = {
                        kind = "zombie_horde",
                        pressureBand = event.pressureBand,
                        nearbyCount = tonumber(event.nearbyCount) or 0,
                        phase = event.phase,
                        spatial = spatial,
                    },
                },
                worldEvents = { episodeID },
                stimulus = {
                    type = "DANGER_CHANGED",
                    responderID = speakerID,
                    intent = "COMBAT_HORDE_ALERT",
                    speechAct = "WARN",
                    subject = "ZOMBIE_HORDE",
                    topic = "COMBAT",
                    eventID = episodeID,
                    eventRefs = { episodeID },
                    worldPatch = {
                        danger = {
                            kind = "zombie_horde",
                            pressureBand = event.pressureBand,
                            nearbyCount = tonumber(event.nearbyCount) or 0,
                            phase = event.phase,
                            spatial = spatial,
                        },
                    },
                },
            }
        end,
    })

    Opportunity.RegisterProvider({
        id = "projecthoomans.scene.grounded_news",
        order = 20,
        stimuli = { "AMBIENT_SOCIAL_OPPORTUNITY" },
        propose = function(event, context)
            if type(context) ~= "table"
                or context.factVerified ~= true
                or type(context.participants) ~= "table"
                or #context.participants < 2
            then
                return {}
            end
            local factID = clean(event.factID, 128)
            local speakerID = clean(context.speakerID, 128)
            if not factID or not speakerID then return {} end
            return {
                id = "grounded-news:" .. factID,
                dedupeKey = "grounded-news:" .. factID,
                priority = 35,
                cooldownMs = Adopters.KNOWLEDGE_COOLDOWN_MS,
                participants = context.participants,
                audience = context.audience,
                topic = "NEWS",
                ttlMs = 15000,
                maxTurns = 4,
                perceived = true,
                autoContinue = true,
                maxContinuationSteps = 3,
                stimulus = {
                    type = "AMBIENT_SOCIAL_OPPORTUNITY",
                    responderID = speakerID,
                    intent = "SHARE_GROUNDED_NEWS",
                    speechAct = "DISCLOSE",
                    subject = clean(event.kind, 96) or "NEWS",
                    topic = "NEWS",
                    factRefs = { factID },
                    eventRefs = event.eventID and { event.eventID } or {},
                },
            }
        end,
    })

    Opportunity.RegisterProvider({
        id = "projecthoomans.scene.community_excursion",
        order = 30,
        stimuli = { "TASK_EVENT" },
        propose = function(event, context)
            local participants = type(context) == "table"
                and context.participants or nil
            local intent = EXCURSION_INTENT[tostring(event.state or "")]
            if not intent or type(participants) ~= "table"
                or #participants < 2
            then
                return {}
            end
            local speakerID = clean(participants[1].id, 128)
            local excursionID = clean(event.excursionID or event.id, 128)
            if not speakerID or not excursionID then return {} end
            local revision = math.max(
                0, math.floor(tonumber(event.revision) or 0)
            )
            local eventRef = table.concat({
                "excursion",
                excursionID,
                tostring(event.state),
                tostring(revision),
            }, ":")
            return {
                id = eventRef,
                dedupeKey = eventRef,
                priority = 20,
                cooldownMs = Adopters.EXCURSION_COOLDOWN_MS,
                participants = participants,
                audience = context.audience,
                topic = "EXCURSION",
                ttlMs = 12000,
                maxTurns = 3,
                perceived = true,
                autoContinue = true,
                maxContinuationSteps = 2,
                stimulus = {
                    type = "TASK_EVENT",
                    responderID = speakerID,
                    intent = intent,
                    speechAct = "INFORM",
                    subject = "COMMUNITY_EXCURSION",
                    topic = "EXCURSION",
                    eventRefs = { eventRef },
                    modifiers = {
                        excursionState = tostring(event.state),
                        excursionRevision = revision,
                    },
                },
            }
        end,
    })
end

function Adopters.Manager()
    return manager
end

function Adopters.SocialDirector()
    return socialDirector
end

function Adopters.SocialConversation()
    return socialConversation
end

local function deliverConversationSteps(scene, social, audience, conversation)
    for _, step in ipairs(
        type(conversation) == "table"
            and type(conversation.steps) == "table"
            and conversation.steps or {}
    ) do
        if step.mode == "emit" and step.selected and step.result then
            SceneTransport.DeliverAffordance(
                scene,
                step.selected,
                {
                    speakerID = step.decision and step.decision.actorID,
                    recipientID = step.decision and step.decision.targetID,
                    topic = social and social.topic,
                    factRefs = step.request and step.request.factRefs,
                    eventRefs = step.request and step.request.eventRefs,
                    sequence = step.result.semanticHistoryEvent
                        and step.result.semanticHistoryEvent.sequence,
                },
                audience
            )
            SceneTransport.Deliver(scene, step.result, audience)
        end
    end
end

function Adopters.SubmitSocial(spec)
    spec = type(spec) == "table" and spec or {}
    if type(socialDirector) ~= "table"
        or type(socialDirector.Submit) ~= "function"
    then
        return false, "social_director_unavailable"
    end
    local result = socialDirector:Submit(spec)
    if not result or result.accepted ~= true then
        return false, result and result.reason or "social_scene_rejected", result
    end
    local social = result.socialOpportunity or spec
    local audience = result.proposal and result.proposal.audience or {}
    if type(socialConversation) == "table"
        and type(socialConversation.RegisterScene) == "function"
    then
        socialConversation:RegisterScene(result.scene, social, audience)
    end

    if spec.runConversation == false
        or type(socialConversation) ~= "table"
        or type(socialConversation.Run) ~= "function"
    then
        return true, "social_scene_admitted", result
    end

    local conversation = socialConversation:Run(
        result.scene,
        result.initialResult,
        social,
        { maxSteps = math.min(3, tonumber(spec.maxSocialSteps) or 3) }
    )
    result.socialConversation = conversation

    -- The Opportunity manager already transported the opening response.
    -- Selected NPC semantic inputs and their resulting Scene responses share
    -- the same canonical Scene speech channel.
    deliverConversationSteps(result.scene, social, audience, conversation)

    if result.scene.status ~= "active"
        and type(socialConversation.ForgetScene) == "function"
    then
        socialConversation:ForgetScene(result.scene.id)
    end
    return true, "social_scene_admitted", result
end

function Adopters.ResumeSocialAfterPlayer(scene, result, playerID)
    if type(socialConversation) ~= "table"
        or type(socialConversation.SceneContext) ~= "function"
        or not scene or not scene.id
    then
        return nil, "social_scene_unregistered"
    end
    local social = socialConversation:SceneContext(scene.id)
    if type(social) ~= "table" then
        return nil, "social_scene_unregistered"
    end

    local audience = socialConversation:SceneAudience(scene.id)
    -- The server Scene-response handler already delivers this immediate NPC
    -- response to the replying player. Fan it out here only to other
    -- registered observers, then continue the social scene if policy allows.
    local otherAudience = {}
    for _, row in ipairs(type(audience) == "table" and audience or {}) do
        if tostring(row.actorID or "") ~= tostring(playerID or "") then
            otherAudience[#otherAudience + 1] = row
        end
    end
    if #otherAudience > 0 then
        SceneTransport.Deliver(scene, result, otherAudience)
    end

    local conversation = socialConversation:Run(
        scene,
        result,
        social,
        { maxSteps = 3 }
    )
    deliverConversationSteps(scene, social, audience, conversation)
    if scene.status ~= "active"
        and type(socialConversation.ForgetScene) == "function"
    then
        socialConversation:ForgetScene(scene.id)
    end
    return conversation, "social_scene_resumed"
end

function Adopters.Snapshot()
    return {
        schemaVersion = Adopters.VERSION,
        metrics = {
            actorQueries = metrics.actorQueries,
            hordeEvents = metrics.hordeEvents,
            postCombatEvents = metrics.postCombatEvents or 0,
            knowledgeEvents = metrics.knowledgeEvents,
            excursionEvents = metrics.excursionEvents,
            taskEvents = metrics.taskEvents or 0,
        },
        social = type(socialDirector) == "table"
            and type(socialDirector.Snapshot) == "function"
            and socialDirector:Snapshot() or nil,
        socialConversation = type(socialConversation) == "table"
            and type(socialConversation.Snapshot) == "function"
            and socialConversation:Snapshot() or nil,
    }
end

function Adopters.ResetForTests(runtime)
    metrics.actorQueries = 0
    metrics.hordeEvents = 0
    metrics.postCombatEvents = 0
    metrics.knowledgeEvents = 0
    metrics.excursionEvents = 0
    metrics.taskEvents = 0
    manager = Opportunity.New(runtime or Runtime.Default())
    Adopters._manager = manager
    socialDirector = SocialDirector.New(manager, { clock = managerClock })
    Adopters._socialDirector = socialDirector
    socialConversation = SocialConversation.New({
        effectSink = SocialConsequences.Apply,
    })
    Adopters._socialConversation = socialConversation
    SocialAudit.Bind(socialDirector, socialConversation)
    return manager
end

function Adopters.OnHordeTransition(record, spec)
    metrics.hordeEvents = metrics.hordeEvents + 1
    spec = type(spec) == "table" and spec or {}
    local phase = tostring(spec.phase or "")
    if phase == "cleared" then
        metrics.postCombatEvents = (metrics.postCombatEvents or 0) + 1
        local participants, audience = localCombatContext(record)
        if #participants < 2 then
            return false, "scene_post_combat_no_local_teammate"
        end
        local episodeID = clean(spec.episodeID or spec.eventID, 128)
        if not episodeID then
            return false, "scene_post_combat_episode_missing"
        end
        local eventRef = episodeID .. ":cleared"
        local teamKey = EncounterIntent.OwnerKey(record)
            or factionID(record)
            or tostring(record.id)
        local accepted, reason, result = Adopters.SubmitSocial({
            id = "post-combat:" .. eventRef,
            motive = "REACT",
            relevance = 0.8,
            priority = 55,
            eventType = "DANGER_CHANGED",
            eventID = eventRef,
            intent = "POST_COMBAT_CLEAR",
            speechAct = "INFORM",
            subject = "ZOMBIE_HORDE",
            topic = "COMBAT",
            speakerID = tostring(record.id),
            recipientID = tostring(participants[2].id),
            participants = participants,
            audience = audience,
            eventRefs = { episodeID, eventRef },
            modifiers = {
                hordePhase = "cleared",
                pressureBand = spec.pressureBand,
                nearbyCount = tonumber(spec.nearbyCount) or 0,
            },
            perceived = true,
            ttlMs = 10000,
            maxTurns = 3,
            cooldownMs = Adopters.POST_COMBAT_COOLDOWN_MS,
            areaKey = "combat-team:" .. tostring(teamKey),
            maxSocialSteps = 2,
        })
        return accepted, result or reason
    end
    if phase ~= "started" then
        return false, "scene_horde_not_initial_transition"
    end
    local participants, audience = localCombatContext(record)
    if #participants < 2 then
        return false, "scene_horde_no_local_teammate"
    end

    local episodeID = clean(spec.episodeID or spec.eventID, 128)
    if not episodeID then return false, "scene_horde_episode_missing" end
    local teamKey = EncounterIntent.OwnerKey(record)
        or factionID(record)
        or tostring(record.id)
    local allowed, banterReason = BanterArbiter.Reserve({
        streamKey = "scene:horde:" .. episodeID,
        now = tonumber(spec.now) or 0,
        cooldownMs = Adopters.COMBAT_COOLDOWN_MS,
        maxSpeakers = 1,
        speakerID = tostring(record.id),
        audienceKey = "scene-team:" .. tostring(teamKey),
        family = "scene_horde_exchange",
        speakerCooldownMs = 4000,
        familyCooldownMs = Adopters.COMBAT_COOLDOWN_MS,
        priorityHoldMs = 5000,
        priority = 90,
        moment = {
            kind = "horde_tactical_scene",
            eventType = "zombie_horde_encounter",
            actorKind = "npc",
            actorID = tostring(record.id),
            targetKind = "zombie_group",
            pressureBand = spec.pressureBand,
            nearbyCount = tonumber(spec.nearbyCount) or 0,
            encounterID = episodeID,
            presentationClass = "TACTICAL_PROMPT",
            source = spec.source or "zombie_observation",
            occurredAt = tonumber(spec.now) or 0,
            priority = 90,
        },
    })
    if allowed ~= true then
        return false, banterReason or "scene_horde_banter_suppressed"
    end

    local result = manager:Admit({
        type = "DANGER_CHANGED",
        id = episodeID,
        episodeID = episodeID,
        phase = "started",
        pressureBand = spec.pressureBand,
        nearbyCount = tonumber(spec.nearbyCount) or 0,
        spatial = spatialSnapshot(spec.spatial),
    }, {
        authority = "combat_horde_awareness",
        participants = participants,
        audience = audience,
        speakerID = tostring(record.id),
    })
    return result.accepted == true, result
end

function Adopters.OnWorldKnowledgeFact(spec)
    metrics.knowledgeEvents = metrics.knowledgeEvents + 1
    spec = type(spec) == "table" and spec or {}
    local factID = clean(spec.factID, 128)
    if not factID then return false, "scene_fact_missing" end
    local participants, audience = localKnowledgeContext(spec)
    if #participants < 2 then
        return false, "scene_fact_no_local_pair"
    end
    local speaker = participants[1]
    local world = PNC.WorldKnowledge
    local speakerRecord = speaker and speaker.actor
    if not world or type(world.Explain) ~= "function"
        or not speakerRecord
        or world.Explain(speakerRecord, factID) == nil
    then
        return false, "scene_fact_speaker_unknown"
    end

    local recipient = participants[2]
    local accepted, reason, result = Adopters.SubmitSocial({
        id = "social-news:" .. tostring(clean(spec.eventID, 128) or factID),
        motive = "INFORM",
        relevance = tonumber(spec.relevance) or 0.8,
        priority = tonumber(spec.priority) or 35,
        eventType = "AMBIENT_SOCIAL_OPPORTUNITY",
        eventID = clean(spec.eventID, 128),
        intent = "SHARE_GROUNDED_NEWS",
        speechAct = "DISCLOSE",
        subject = clean(spec.kind, 96) or "NEWS",
        topic = "NEWS",
        speakerID = tostring(speaker.id),
        recipientID = tostring(recipient.id),
        participants = participants,
        audience = audience,
        factRefs = { factID },
        eventRefs = spec.eventID and { tostring(spec.eventID) } or {},
        perceived = true,
        ttlMs = 15000,
        maxTurns = 4,
        cooldownMs = Adopters.KNOWLEDGE_COOLDOWN_MS,
        areaKey = clean(spec.areaKey, 96)
            or clean(spec.factionID, 96)
            or "knowledge-local",
        maxSocialSteps = 3,
    })
    if not accepted then return false, reason end
    return true, result
end

function Adopters.OnTaskEvent(_, event)
    metrics.taskEvents = (metrics.taskEvents or 0) + 1
    event = type(event) == "table" and event or {}
    local eventType = tostring(event.type or "")
    local intent
    local motive
    local relevance
    if eventType == "TASK_LEASE_CREATED" then
        intent = "TASK_WORK_ASSIGNED"
        motive = "COORDINATE"
        relevance = 0.55
    elseif eventType == "TASK_LEASE_RELEASED"
        and tostring(event.cause or "") == "complete"
    then
        intent = "TASK_WORK_COMPLETED"
        motive = "ACKNOWLEDGE"
        relevance = 0.60
    else
        return true, "scene_task_event_ignored"
    end

    local registry = PNC.Registry
    local record = registry and type(registry.Get) == "function"
        and registry.Get(event.npcId) or nil
    if not record or record.alive == false then
        return true, "scene_task_actor_unavailable"
    end
    local participants, audience = localCombatContext(record)
    if #participants < 2 then
        return true, "scene_task_no_local_teammate"
    end
    local payload = type(event.payload) == "table" and event.payload or {}
    local eventRef = clean(event.id, 128)
        or table.concat({
            "task-social",
            tostring(record.id),
            tostring(eventType),
            tostring(event.revision or 0),
        }, ":")
    local teamKey = EncounterIntent.OwnerKey(record)
        or factionID(record)
        or tostring(record.id)

    local accepted, reason, result = Adopters.SubmitSocial({
        id = "social-task:" .. eventRef,
        motive = motive,
        relevance = relevance,
        priority = eventType == "TASK_LEASE_RELEASED" and 28 or 32,
        eventType = "TASK_EVENT",
        eventID = eventRef,
        intent = intent,
        speechAct = "INFORM",
        subject = "WORK",
        topic = "WORK",
        speakerID = tostring(record.id),
        recipientID = tostring(participants[2].id),
        participants = participants,
        audience = audience,
        eventRefs = { eventRef },
        modifiers = {
            taskEventType = eventType,
            taskID = clean(payload.taskId, 128),
            sourceDomain = clean(payload.sourceDomain, 96),
            taskPhase = clean(payload.phase or payload.to, 64),
        },
        perceived = true,
        ttlMs = 10000,
        maxTurns = 3,
        cooldownMs = Adopters.TASK_SOCIAL_COOLDOWN_MS,
        areaKey = "task-team:" .. tostring(teamKey),
        maxSocialSteps = 2,
    })
    return true, accepted and "scene_task_social_admitted"
        or reason or "scene_task_social_suppressed", result
end

function Adopters.OnExcursionChanged(payload)
    metrics.excursionEvents = metrics.excursionEvents + 1
    payload = type(payload) == "table" and payload or {}
    if tostring(payload.reason or "") ~= "phase_changed" then
        return true, "scene_excursion_non_phase_change"
    end
    local factionID = clean(payload.factionID, 128)
    if not factionID then return false, "scene_excursion_faction_missing" end
    local participants, audience = excursionContext(factionID)
    if #participants < 2 then
        return true, "scene_excursion_no_local_pair"
    end
    local intent = EXCURSION_INTENT[tostring(payload.state or "")]
    if not intent then return true, "scene_excursion_state_ignored" end
    local eventRef = table.concat({
        "excursion",
        tostring(clean(payload.id, 128) or factionID),
        tostring(payload.state or ""),
        tostring(math.max(0, math.floor(tonumber(payload.revision) or 0))),
    }, ":")
    local accepted, reason = Adopters.SubmitSocial({
        id = eventRef,
        motive = "INFORM",
        relevance = 0.7,
        priority = 20,
        eventType = "TASK_EVENT",
        eventID = eventRef,
        intent = intent,
        speechAct = "INFORM",
        subject = "COMMUNITY_EXCURSION",
        topic = "EXCURSION",
        speakerID = tostring(participants[1].id),
        recipientID = tostring(participants[2].id),
        participants = participants,
        audience = audience,
        eventRefs = { eventRef },
        modifiers = {
            excursionState = tostring(payload.state or ""),
            excursionRevision = tonumber(payload.revision) or 0,
        },
        perceived = true,
        ttlMs = 12000,
        maxTurns = 3,
        cooldownMs = Adopters.EXCURSION_COOLDOWN_MS,
        areaKey = factionID,
        maxSocialSteps = 2,
    })
    return true, accepted and "scene_excursion_admitted"
        or reason or "scene_excursion_suppressed"
end

registerProviders()

local excursion = PNC.CommunityExcursionService
if excursion and type(excursion.RegisterListener) == "function" then
    excursion.RegisterListener(Adopters.OnExcursionChanged)
end

local taskEvents = PNC.Tasking and PNC.Tasking.Events or nil
if taskEvents and type(taskEvents.Subscribe) == "function" then
    taskEvents.Subscribe(
        "TASK_LEASE_CREATED",
        Adopters.OnTaskEvent,
        "semantic_social_task_adopter"
    )
    taskEvents.Subscribe(
        "TASK_LEASE_RELEASED",
        Adopters.OnTaskEvent,
        "semantic_social_task_adopter"
    )
end

return Adopters
