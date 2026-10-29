local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
}

local records = {}
local spatialQueries = 0
local deliveredPackets = {}
local excursionListener

local function player(id, x)
    return {
        getOnlineID = function() return id end,
        getX = function() return x end,
        getY = function() return 10 end,
        getZ = function() return 0 end,
    }
end

local combatObserver = player(101, 10)
local newsObserver = player(102, 500)
local tripObserver = player(103, 900)

local function record(id, x, factionID, bravery, sociability, facts)
    local value = {
        id = id,
        alive = true,
        x = x,
        y = 10,
        z = 0,
        affiliation = { factionID = factionID },
        personality = {
            aggression = 0.25,
            bravery = bravery or 0.5,
            compassion = 0.5,
            sociability = sociability or 0.5,
            forgiveness = 0.5,
        },
        conditionStats = { stress = 0.1, panic = 5 },
        needs = { hunger = 0.1, thirst = 0.1, fatigue = 0.1 },
        social = { relationships = {} },
        knowledgeFactRefs = facts or {},
    }
    records[id] = value
    return value
end

local combatA = record("npc-combat-a", 10, "faction-red", 0.5, 0.5)
local combatB = record("npc-combat-b", 11, "faction-red", 0.9, 0.5)
local followerA = record("npc-follow-a", 50, "faction-follow-a", 0.5, 0.5)
local followerB = record("npc-follow-b", 51, "faction-follow-b", 0.7, 0.5)
followerA.ownerOnlineID = 77
followerB.ownerOnlineID = 77
local soloA = record("npc-solo-a", 80, "faction-solo", 0.5, 0.5)
local newsFact = "wkg:death:scene-s6"
local newsA = record(
    "npc-news-a", 500, "faction-blue", 0.5, 0.5, { newsFact }
)
local newsB = record("npc-news-b", 501, "faction-blue", 0.5, 0.9)
local tripA = record("npc-trip-a", 900, "faction-green", 0.5, 0.5)
local tripB = record("npc-trip-b", 901, "faction-green", 0.5, 0.5)

local function hasFact(recordValue, factID)
    for _, value in ipairs(recordValue.knowledgeFactRefs or {}) do
        if value == factID then return true end
    end
    return false
end

PNC = {
    Registry = {
        Get = function(id)
            return records[tostring(id or "")]
        end,
    },
    SpatialIndex = {
        QueryActors = function(x, _y, _radius)
            spatialQueries = spatialQueries + 1
            if x < 30 then
                return {
                    npcs = { combatA, combatB },
                    players = { combatObserver },
                }
            end
            if x < 65 then
                return {
                    npcs = { followerA, followerB },
                    players = {},
                }
            end
            if x < 100 then
                return {
                    npcs = { soloA },
                    players = {},
                }
            end
            if x < 800 then
                return {
                    npcs = { newsA, newsB },
                    players = { newsObserver },
                }
            end
            return {
                npcs = { tripA, tripB },
                players = { tripObserver },
            }
        end,
    },
    Const = {
        CMD_SEMANTIC_SCENE_SPEECH = "SemanticSceneSpeech",
    },
    Network = {
        Internal = {
            SendToPlayer = function(playerValue, command, payload)
                deliveredPackets[#deliveredPackets + 1] = {
                    player = playerValue,
                    command = command,
                    payload = payload,
                }
                return true
            end,
        },
    },
    Factions = {
        GetFactionID = function(recordValue)
            return recordValue and recordValue.affiliation
                and recordValue.affiliation.factionID or nil
        end,
        GetRelation = function()
            return { state = "neutral" }
        end,
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    Relationships = {
        Get = function(observerID, targetKey)
            local source = records[observerID]
            return source and source.social
                and source.social.relationships[targetKey] or nil
        end,
    },
    RelationshipGraph = {
        ResolveNPCPersonality = function(recordValue)
            return recordValue.personality or {}
        end,
    },
    WorldKnowledge = {
        BuildConversationContext = function(recordValue)
            return {
                npcGossip = {
                    factRefs = recordValue.knowledgeFactRefs or {},
                    statements = {},
                },
            }
        end,
        Explain = function(recordValue, factID)
            if hasFact(recordValue, factID) then
                return {
                    factID = factID,
                    provenance = "faction",
                    confidence = 1,
                }
            end
            return nil
        end,
    },
    CommunityExcursionService = {
        RegisterListener = function(listener)
            excursionListener = listener
            return true
        end,
        Get = function(factionID)
            if factionID ~= "faction-green" then
                return nil, "excursion_not_found"
            end
            return {
                id = "excursion-s6",
                state = "PREPARING",
                revision = 1,
                participants = { "npc-trip-a", "npc-trip-b" },
            }
        end,
    },
}

local Opportunity = require
    "PNC/Semantics/PNC_SemanticInteractionOpportunity"
local Runtime = require
    "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"
local Banter = require "PNC/Semantics/PNC_SemanticCombatBanterArbiter"
local Adopters = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticInteractionSceneAdopters.lua"
)

local runtime = Runtime.ResetForTests({
    maxActiveScenes = 8,
    maxParticipants = 4,
    maxTurns = 8,
    clock = function() return 1000 end,
})
Adopters.ResetForTests(runtime)
Banter.ResetRuntime()

local providerIDs = {}
for _, item in ipairs(Opportunity.ListProviders()) do
    providerIDs[item.id] = true
end
T.truthy(providerIDs["projecthoomans.scene.combat_horde"],
    "combat horde production provider registered")
T.truthy(providerIDs["projecthoomans.scene.grounded_news"],
    "grounded news production provider registered")
T.truthy(providerIDs["projecthoomans.scene.community_excursion"],
    "community excursion production provider registered")
T.equal(excursionListener, Adopters.OnExcursionChanged,
    "adopter hub registers through existing excursion listener API")

local beforeCombatQueries = spatialQueries
local combatAccepted, combat = Adopters.OnHordeTransition(combatA, {
    phase = "started",
    episodeID = "horde:episode:s6",
    eventID = "horde:event:s6",
    pressureBand = "horde",
    nearbyCount = 9,
    source = "perception",
    now = 1000,
    spatial = {
        targetKind = "zombie_group",
        targetRef = "horde:episode:s6",
        targetPositionSource = "combat_centroid",
        headingSource = "live_body",
        clockHour = 8,
        clockToken = "CLOCK_08",
        relativeSector8 = "REAR_LEFT",
        distance = 10,
        sameArea = false,
        freshnessMs = 0,
        presentationMode = "clock",
        presentationReason = "tactical_role:guard",
    },
})
T.truthy(combatAccepted, combat and combat.reason or "combat scene admitted")
T.equal(spatialQueries - beforeCombatQueries, 1,
    "combat admission uses exactly one combined local actor query")
T.equal(#combat.proposal.audience, 1,
    "nearby player is observer of NPC combat exchange")
T.equal(#deliveredPackets, 2,
    "one resolved two-turn combat exchange fans out twice to observer")
T.truthy(deliveredPackets[1].payload.observerOnly,
    "combat observer packet is presentation-only")
T.equal(deliveredPackets[1].payload.sceneHandoff, nil,
    "combat observer gets no semantic response authority")
T.equal(combat.proposal.providerID, "projecthoomans.scene.combat_horde",
    "combat event routes through generic Opportunity provider")
T.equal(combat.initialResult.stimulus.type, "DANGER_CHANGED",
    "combat scene starts from canonical DANGER_CHANGED")
T.equal(combat.initialResult.interactionPlan.behaviorID,
    "behavior.scene_horde_prompt",
    "first speaker uses generated horde prompt behavior")
T.equal(combat.proposal.world.danger.spatial.clockToken, "CLOCK_08",
    "scene world receives canonical tactical spatial snapshot")
T.contains(combat.initialResult.presentation.speech.fallback, "8 o'clock",
    "initial semantic scene warning is spatially grounded")
T.equal(
    combat.initialResult.presentation.speech.tacticalSpatialPresentation.mode,
    "clock",
    "scene presentation records tactical clock mode"
)
T.equal(combat.finalResult.interactionPlan.behaviorID,
    "behavior.scene_horde_reply_brave",
    "brave teammate selects trait-sensitive engage reply")
T.equal(combat.finalResult.stimulus.source.actorID, "npc-combat-a",
    "semantic continuation source is actual first speaker")
T.equal(combat.finalResult.stimulus.targets[1], "npc-combat-b",
    "event continuation targets real teammate")
T.equal(combat.finalResult.interactionPlan.dialogueAct, "PROPOSE_ENGAGE",
    "brave reply expresses engage proposal without mutating combat authority")

local repeatAccepted, repeatReason = Adopters.OnHordeTransition(combatA, {
    phase = "escalated",
    episodeID = "horde:episode:s6",
    nearbyCount = 12,
    now = 1100,
})
T.falsy(repeatAccepted,
    "non-initial horde transition does not create another group scene")
T.equal(repeatReason, "scene_horde_not_initial_transition",
    "horde scene start is episode-bounded")

Banter.ResetRuntime()
local followerAccepted, followerScene = Adopters.OnHordeTransition(followerA, {
    phase = "started",
    episodeID = "horde:episode:follower-s6",
    eventID = "horde:event:follower-s6",
    pressureBand = "horde",
    nearbyCount = 7,
    source = "perception",
    now = 2000,
})
T.truthy(followerAccepted,
    followerScene and followerScene.reason
        or "same-owner followers form a combat conversation cohort")
T.equal(#followerScene.proposal.participants, 2,
    "same-owner follower cohort does not require matching faction IDs")

Banter.ResetRuntime()
local soloAccepted, soloReason = Adopters.OnHordeTransition(soloA, {
    phase = "started",
    episodeID = "horde:episode:solo-s6",
    eventID = "horde:event:solo-s6",
    pressureBand = "horde",
    nearbyCount = 7,
    source = "perception",
    now = 3000,
})
T.falsy(soloAccepted,
    "solo combatant does not fabricate a second scene participant")
T.equal(soloReason, "scene_horde_no_local_teammate",
    "solo cohort rejection is explicit and non-mutating")

local beforeNewsQueries = spatialQueries
local newsAccepted, news = Adopters.OnWorldKnowledgeFact({
    factID = newsFact,
    eventID = "death:event:s6",
    kind = "npc.death",
    factionID = "faction-blue",
    x = 500,
    y = 10,
    z = 0,
})
T.truthy(newsAccepted, news and news.reason or "grounded news scene admitted")
T.equal(spatialQueries - beforeNewsQueries, 1,
    "grounded news admission uses exactly one combined local actor query")
T.equal(#news.proposal.audience, 1,
    "nearby player can overhear grounded NPC news without joining scene")
T.equal(news.proposal.providerID, "projecthoomans.scene.grounded_news",
    "known fact routes through generic grounded-news provider")
T.equal(news.initialResult.interactionPlan.behaviorID,
    "behavior.scene_grounded_news_share",
    "known fact produces generated grounded disclosure")
T.equal(news.initialResult.interactionPlan.groundedFactRefs[1], newsFact,
    "initial disclosure remains grounded in real WorldKnowledge fact")
T.equal(news.finalResult.interactionPlan.behaviorID,
    "behavior.scene_news_followup_answer",
    "sociable listener follow-up returns to knowledgeable speaker")
T.equal(news.finalResult.interactionPlan.groundedFactRefs[1], newsFact,
    "follow-up answer retains original grounded fact")
T.equal(news.finalResult.stimulus.source.actorID, "npc-news-b",
    "listener becomes semantic follow-up source")
T.equal(news.finalResult.stimulus.targets[1], "npc-news-a",
    "follow-up returns to original knowledgeable speaker")

local unknownAccepted, unknownReason = Adopters.OnWorldKnowledgeFact({
    factID = "wkg:unknown:s6",
    eventID = "unknown:event:s6",
    kind = "npc.death",
    factionID = "faction-blue",
    x = 500,
    y = 10,
    z = 0,
})
T.falsy(unknownAccepted,
    "speaker cannot open grounded-news scene for unknown fact")
T.equal(unknownReason, "scene_fact_no_local_pair",
    "unknown fact fails before semantic disclosure")

local excursionAccepted, excursionReason = excursionListener({
    reason = "phase_changed",
    factionID = "faction-green",
    id = "excursion-s6",
    state = "PREPARING",
    revision = 1,
})
T.truthy(excursionAccepted,
    excursionReason or "excursion listener remains nonblocking")
local excursion = Adopters.Manager():Snapshot().lastAdmission
T.truthy(excursion and excursion.accepted,
    "real excursion listener admits a generic Scene opportunity")
T.equal(excursion.providerID,
    "projecthoomans.scene.community_excursion",
    "excursion routes through same Opportunity manager")

local runtimeSnapshot = runtime:Snapshot()
T.truthy(runtimeSnapshot.metrics.admissionAccepted >= 3,
    "one global Scene Runtime admitted all three production domains")
T.equal(Adopters.Manager():Snapshot().providers[1].id,
    "projecthoomans.scene.combat_horde",
    "provider ordering remains deterministic")

local source = T.read(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticInteractionSceneAdopters.lua"
)
T.falsy(string.find(source, "Events.OnTick", 1, true),
    "production adopter hub has no polling tick")
T.falsy(string.find(source, "Registry.ForEachLive", 1, true),
    "production adopter hub never scans all live NPCs")
T.falsy(string.find(source, "getZombieList", 1, true),
    "production adopter hub never scans global zombies")
T.contains(source, "SpatialIndex",
    "combat/news admission reuses bounded spatial index")
T.falsy(string.find(source, "ModData", 1, true),
    "production adopter hub owns no persistence")
T.falsy(string.find(source, "PsychopatzSemantic.Parse", 1, true),
    "production adopter hub never reparses rendered dialogue")

T.finish("pnc_semantic_scene_runtime_s6_adopters_smoke")
