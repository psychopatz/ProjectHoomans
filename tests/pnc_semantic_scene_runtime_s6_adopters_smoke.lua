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
local taskListeners = {}
local testNow = 1000

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
local followerC = record("npc-follow-c", 52, "faction-follow-c", 0.6, 0.5)
followerA.ownerOnlineID = 77
followerB.ownerOnlineID = 77
followerC.ownerOnlineID = 77
local soloA = record("npc-solo-a", 80, "faction-solo", 0.5, 0.5)
local raiderA = record("npc-raider-a", 130, "faction-raider", 0.8, 0.6)
local raiderB = record("npc-raider-b", 131, "faction-raider", 0.7, 0.5)
raiderA.npcType = "raider"
raiderB.npcType = "raider"
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
                    npcs = { followerA, followerB, followerC },
                    players = {},
                }
            end
            if x < 100 then
                return {
                    npcs = { soloA },
                    players = {},
                }
            end
            if x < 200 then
                return {
                    npcs = { raiderA, raiderB },
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
    Tasking = {
        Events = {
            Subscribe = function(eventType, listener)
                taskListeners[eventType] = listener
                return true
            end,
        },
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
    clock = function() return testNow end,
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
T.equal(taskListeners.TASK_LEASE_CREATED, Adopters.OnTaskEvent,
    "task assignment social adopter uses existing Tasking listener API")
T.equal(taskListeners.TASK_LEASE_RELEASED, Adopters.OnTaskEvent,
    "task completion social adopter uses existing Tasking listener API")

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

local beforePostCombatQueries = spatialQueries
local postCombatAccepted, postCombat = Adopters.OnHordeTransition(combatA, {
    phase = "cleared",
    episodeID = "horde:episode:s6",
    eventID = "horde:event:s6",
    pressureBand = "few",
    nearbyCount = 1,
    source = "perception",
    now = 4000,
})
T.truthy(postCombatAccepted,
    postCombat and postCombat.reason or "post-combat social scene admitted")
T.equal(spatialQueries - beforePostCombatQueries, 1,
    "post-combat social opportunity performs one bounded local cohort query")
T.equal(postCombat.proposal.providerID,
    "projecthoomans.scene.social_director",
    "post-combat reaction uses generic Social Director")
T.equal(postCombat.initialResult.interactionPlan.behaviorID,
    "behavior.scene_post_combat_clear",
    "cleared horde selects generated decompression behavior")
T.equal(postCombat.initialResult.interactionPlan.dialogueAct, "INFORM",
    "post-combat line is presentation over authoritative cleared state")
T.truthy(postCombat.socialConversation
    and #postCombat.socialConversation.steps >= 1,
    "post-combat line can receive actor-neutral NPC semantic reaction")

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
T.equal(#followerScene.proposal.participants, 3,
    "same-owner followers share one bounded multi-participant cohort")
T.equal(followerScene.scene:Snapshot().participantCount, 3,
    "three followers remain one Scene rather than pairwise sub-scenes")

local beforeTaskQueries = spatialQueries
local taskListener = taskListeners.TASK_LEASE_CREATED
local taskHandled, taskReason, taskScene = taskListener({
    npcId = "npc-follow-a", eventId = "task-event:s6", domain = "TaskLeaseService",
}, {
    id = "task-event:s6",
    type = "TASK_LEASE_CREATED",
    source = "TaskLeaseService",
    npcId = "npc-follow-a",
    entityId = "lease:s6",
    revision = 1,
    cause = "assigned",
    payload = {
        taskId = "work:repair:s6",
        sourceDomain = "WorkTaskProvider",
        phase = "ASSIGNED",
    },
})
T.truthy(taskHandled, taskReason or "task event listener remains nonblocking")
T.equal(spatialQueries - beforeTaskQueries, 1,
    "task social event performs one bounded teammate query")
T.truthy(taskScene and taskScene.accepted,
    "task assignment can admit one social Scene")
T.equal(taskScene.proposal.providerID, "projecthoomans.scene.social_director",
    "task coordination reuses generic Social Director")
T.equal(taskScene.initialResult.interactionPlan.behaviorID,
    "behavior.scene_task_work_assigned",
    "task assignment resolves generated work-status behavior")
T.equal(taskScene.initialResult.stimulus.semantic.modifiers.taskID,
    "work:repair:s6",
    "task dialogue reads authoritative event payload without owning task state")

-- Assignment and completion intentionally share the WORK topic. Advance
-- beyond the ambient topic cooldown before proving completion chatter.
testNow = testNow + 13000
local completionListener = taskListeners.TASK_LEASE_RELEASED
local completionHandled, completionReason, completionScene = completionListener({
    npcId = "npc-follow-c", eventId = "task-complete:s6",
    domain = "TaskLeaseService",
}, {
    id = "task-complete:s6",
    type = "TASK_LEASE_RELEASED",
    source = "TaskLeaseService",
    npcId = "npc-follow-c",
    entityId = "lease:complete:s6",
    revision = 2,
    cause = "complete",
    payload = {
        taskId = "work:haul:s6",
        sourceDomain = "WorkTaskProvider",
        phase = "DONE",
    },
})
T.truthy(completionHandled,
    completionReason or "completed work social event remains nonblocking")
T.truthy(completionScene and completionScene.accepted,
    "completed work can admit a separate social Scene")
T.equal(completionScene.initialResult.interactionPlan.behaviorID,
    "behavior.scene_task_work_completed",
    "completed work selects canonical generated completion behavior")
T.equal(completionScene.proposal.providerID,
    "projecthoomans.scene.social_director",
    "task completion stays on the generic Social Director path")

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

local raiderAccepted, raiderScene = Adopters.OnHordeTransition(raiderA, {
    phase = "cleared",
    episodeID = "horde:episode:raider-s6",
    eventID = "horde:event:raider-s6",
    pressureBand = "few",
    nearbyCount = 1,
    source = "perception",
    now = 5000,
})
T.truthy(raiderAccepted,
    raiderScene and raiderScene.reason
        or "raider teammates can converse without player participation")
T.equal(#raiderScene.proposal.participants, 2,
    "raider social scene uses one bounded same-faction cohort")
T.equal(#raiderScene.proposal.audience, 0,
    "raider conversation does not require a player observer")
T.equal(raiderScene.proposal.providerID,
    "projecthoomans.scene.social_director",
    "hostile-role NPCs use the same generic social machinery")
T.equal(raiderScene.initialResult.interactionPlan.behaviorID,
    "behavior.scene_post_combat_clear",
    "raider decompression uses the same generated semantic behavior")

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
T.equal(news.proposal.providerID, "projecthoomans.scene.social_director",
    "known fact routes through generic Social Director provider")
T.equal(news.initialResult.interactionPlan.behaviorID,
    "behavior.scene_grounded_news_share",
    "known fact produces generated grounded disclosure")
T.equal(news.initialResult.interactionPlan.groundedFactRefs[1], newsFact,
    "initial disclosure remains grounded in real WorldKnowledge fact")
local newsConversation = news.socialConversation
T.truthy(newsConversation and #newsConversation.steps >= 1,
    "grounded news continues through actor-neutral NPC affordances")
local newsStep = newsConversation.steps[1]
T.equal(newsStep.mode, "emit",
    "listener selects one semantic reply instead of generic auto-continuation: "
        .. tostring(newsStep.reason))
T.equal(newsStep.selected.providerID, "projecthoomans.generated_affordances",
    "listener reuses the same generated affordance provider as player choices")
T.equal(newsStep.request.sourceID, "npc-news-b",
    "listener becomes semantic affordance source")
T.equal(newsStep.request.responderID, "npc-news-a",
    "selected affordance returns to original knowledgeable speaker")
T.equal(newsStep.request.factRefs[1], newsFact,
    "selected NPC semantic reply retains the disclosed grounded fact")
T.truthy(newsStep.result.semanticHistoryEvent ~= nil,
    "selected NPC act is accepted into canonical Scene history")
T.truthy(newsStep.terminal == true
    or newsStep.result.interactionPlan ~= nil,
    "addressee may answer or naturally remain silent after NPC reply")

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
    "projecthoomans.scene.social_director",
    "excursion routes through Social Director on the same Opportunity manager")

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
