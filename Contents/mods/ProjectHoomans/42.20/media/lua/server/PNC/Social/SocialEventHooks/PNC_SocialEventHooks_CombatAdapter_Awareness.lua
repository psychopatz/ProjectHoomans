-- Social callbacks consumed by PsychopatzCore's zombie-kill detector.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Registry = PNC.Registry
local Perception = PNC.Perception
local Const = PNC.Const
local Network = PNC.Network
local EncounterIntent = PNC.Semantics
    and PNC.Semantics.CombatEncounterIntent
    or require "PNC/Semantics/PNC_SemanticCombatEncounterIntent"
local CombatReactionProfile = PNC.Semantics
    and PNC.Semantics.CombatReactionProfile
    or require "PNC/Semantics/PNC_SemanticCombatReactionProfile"
local CombatMoment = PNC.Semantics
    and PNC.Semantics.CombatMoment
    or require "PNC/Semantics/PNC_SemanticCombatMoment"
local BanterArbiter = PNC.Semantics
    and PNC.Semantics.CombatBanterArbiter
    or require "PNC/Semantics/PNC_SemanticCombatBanterArbiter"
local TacticalSpatial = PNC.TacticalSpatialProjection
    or require "PNC/Core/Spatial/PNC_TacticalSpatialProjection"
local TacticalLanguage = PNC.Semantics
    and PNC.Semantics.TacticalSpatialLanguage
    or require "PNC/Semantics/PNC_SemanticTacticalSpatialLanguage"
local SocialReactions = PNC.Semantics
    and PNC.Semantics.SocialReactions or nil
if not SocialReactions then
    local ok, loaded = pcall(
        require,
        "PNC/Semantics/PNC_SemanticSocialReaction"
    )
    SocialReactions = ok and loaded or nil
end
local ContextProviders = PNC.Semantics
    and PNC.Semantics.SocialContext or nil
if type(ContextProviders) ~= "table" then
    local ok, loaded = pcall(
        require,
        "PNC/Core/Social/PNC_SemanticSocialContext"
    )
    ContextProviders = ok and loaded or nil
end
local WITNESS_RADIUS = tonumber(Const and Const.ZOMBIE_TARGET_RADIUS) or 12
local ZOMBIE_AWARENESS_PRESENTATION_COOLDOWN_MS = 12000

local ZOMBIE_HORDE_MEMORY = "zombie_horde_encounter"
local ZOMBIE_STAMINA_MEMORY = "zombie_stamina_retreat"

local function sendEncounterIntentState(record, state, reason)
    if not record or type(state) ~= "table"
        or not Core or type(Core.ForEachPlayer) ~= "function"
        or not Network
        or type(Network.SendCombatEncounterIntentState) ~= "function"
        or not EncounterIntent
        or type(EncounterIntent.MatchesOwner) ~= "function"
    then
        return false
    end
    local eventRef = state.promptEventRef or state.lastPromptEventRef
    if eventRef == nil or tostring(eventRef) == "" then return false end
    local sent = false
    Core.ForEachPlayer(function(player)
        if player and EncounterIntent.MatchesOwner(record, player) == true then
            if Network.SendCombatEncounterIntentState(player, {
                npcID = tostring(state.promptNPCID or record.id or ""),
                eventRef = tostring(eventRef),
                active = state.active == true,
                intent = tostring(state.intent or "undecided"),
                revision = tonumber(state.revision) or 0,
                reason = tostring(reason or "state_changed"),
                resolvedBy = state.resolvedBy,
            }) == true then
                sent = true
            end
        end
    end)
    return sent
end

if EncounterIntent and type(EncounterIntent.SetNotifier) == "function" then
    EncounterIntent.SetNotifier(sendEncounterIntentState)
end

local function call(object, method, ...)
    if not object or not object[method] then
        return nil
    end
    local ok, value = pcall(object[method], object, ...)
    if ok then
        return value
    end
    return nil
end

local function audit(fields)
    if not (PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.DebugCombatCallbacks == true)
    then
        return
    end
    local message = "[ZombieKillAudit] " .. table.concat(fields, " ")
    if Core and Core.LogInfo then
        Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
end

local function coordinate(object, method, fallback)
    local value = call(object, method)
    if value == nil then
        value = fallback
    end
    return tonumber(value)
end

local function distanceSq(x1, y1, x2, y2)
    if Core and Core.DistanceSq then
        return Core.DistanceSq(x1, y1, x2, y2)
    end
    local dx = x2 - x1
    local dy = y2 - y1
    return (dx * dx) + (dy * dy)
end

local function canSee(record, target)
    if not Perception or type(Perception.CanSeeWorldObject) ~= "function" then
        return false
    end
    return Perception.CanSeeWorldObject(record, target) == true
end

local function relationshipDelta(before, after)
    return {
        approval = (tonumber(after and after.approval) or 0)
            - (tonumber(before and before.approval) or 0),
        respect = (tonumber(after and after.respect) or 0)
            - (tonumber(before and before.respect) or 0),
        familiarity = (tonumber(after and after.familiarity) or 0)
            - (tonumber(before and before.familiarity) or 0),
    }
end

local function relationshipState(relationship)
    return tostring(relationship and (
        relationship.state or relationship.category
    ) or "unknown")
end

local function relationshipTier(relationship)
    local state = relationshipState(relationship)
    if state == "enemy" or state == "rival" then return "reserved" end
    local approval = tonumber(relationship and relationship.approval) or 0
    local familiarity = tonumber(relationship and relationship.familiarity) or 0
    if state == "friend" or approval >= 30 then return "warm" end
    if approval >= 10 or familiarity >= 5 then return "familiar" end
    return "reserved"
end

local function socialRole(record)
    if ContextProviders and type(ContextProviders.ResolveNPCType) == "function" then
        local value = ContextProviders.ResolveNPCType(record)
        if value then return tostring(value) end
    end
    return "neutral"
end

local function dayIndex(worldAgeHours)
    local interactions = PNC and PNC.VanillaEmoteInteractions
    if interactions and type(interactions.DayIndex) == "function" then
        local value = interactions.DayIndex(worldAgeHours)
        if tonumber(value) then
            return math.max(0, math.floor(tonumber(value)))
        end
    end
    return math.floor(math.max(0, tonumber(worldAgeHours) or 0) / 24)
end

local function memoryToday(relationship, memoryType, worldAgeHours)
    local interactions = PNC and PNC.VanillaEmoteInteractions
    local memories = relationship and relationship.memories or {}
    local targetDay = dayIndex(worldAgeHours)
    local hasToday
    local memory
    local createdAt
    local index
    if interactions and type(interactions.HasMemoryToday) == "function" then
        local value = interactions.HasMemoryToday(
            relationship,
            memoryType,
            worldAgeHours
        )
        hasToday = value == true
    end
    if hasToday == false then
        return nil, false
    end
    for index = 1, #memories do
        memory = memories[index]
        createdAt = tonumber(memory and memory.createdAt)
        if memory and memory.type == memoryType
            and createdAt ~= nil
            and dayIndex(createdAt) == targetDay
        then
            return tostring(memory.id or ""), true
        end
    end
    return nil, hasToday == true
end

local function rememberZombieAwareness(
    record,
    playerKey,
    memoryType,
    worldAgeHours,
    countSize,
    source
)
    local relationships = PNC and PNC.Relationships
    local relationship = record.social
        and record.social.relationships
        and record.social.relationships[playerKey] or nil
    local memoryID
    local alreadyRecorded
    local tags = {
        combat = true,
        witnessed = true,
        zombie_threat = true,
    }
    local day = dayIndex(worldAgeHours)
    if memoryType == ZOMBIE_HORDE_MEMORY then
        tags.zombie_horde = true
    elseif memoryType == ZOMBIE_STAMINA_MEMORY then
        tags.stamina_retreat = true
    end
    if countSize then
        tags["horde_size_" .. countSize] = true
    end
    if source == "follow" or source == "combat" then
        tags["detected_by_" .. source] = true
    end
    memoryID, alreadyRecorded = memoryToday(
        relationship,
        memoryType,
        worldAgeHours
    )
    if alreadyRecorded then
        return memoryID ~= "" and memoryID or nil
    end
    if not relationships or type(relationships.AddMemory) ~= "function" then
        return nil
    end
    memoryID = "zombie-awareness:" .. memoryType .. ":"
        .. tostring(record.id) .. ":" .. tostring(day)
    local added = relationships.AddMemory(record.id, playerKey, {
        id = memoryID,
        type = memoryType,
        aboutKey = playerKey,
        createdAt = worldAgeHours,
        approvalEffect = 0,
        respectEffect = 0,
        moraleEffect = 0,
        strength = 0.55,
        decayPerDay = 0.04,
        permanent = false,
        shareable = false,
        knowledgeSource = "experienced",
        tags = tags,
    })
    return added == true and memoryID or nil
end

local function countBand(count)
    local classifier = PNC and PNC.ZombieObservation
    if classifier and type(classifier.Classify) == "function" then
        local classified = classifier.Classify(count)
        return classified and classified.socialBand or nil
    end
    count = math.max(0, tonumber(count) or 0)
    if count < 3 then return nil end
    if count >= 8 then return "large" end
    if count >= 5 then return "several" end
    return "few"
end

local function pressureBand(count)
    local classifier = PNC and PNC.ZombieObservation
    if classifier and type(classifier.Classify) == "function" then
        local classified = classifier.Classify(count)
        return classified and classified.band or "none"
    end
    count = math.max(0, tonumber(count) or 0)
    if count <= 0 then return "none" end
    if count <= 2 then return "few" end
    if count <= 5 then return "several" end
    if count <= 11 then return "horde" end
    return "massive_horde"
end

local PRESSURE_RANK = {
    none = 0,
    few = 1,
    several = 2,
    horde = 3,
    massive_horde = 4,
}

local function pressureRank(band)
    return PRESSURE_RANK[tostring(band or "none")] or 0
end

local function quantityText(count, band)
    count = math.max(0, math.floor(tonumber(count) or 0))
    if count > 0 then
        return tostring(count) .. " zombies are close enough to matter."
    end
    if band == "massive_horde" then return "A massive horde is nearby." end
    if band == "horde" then return "A horde is nearby." end
    if band == "several" then return "Several zombies are nearby." end
    if band == "few" then return "A few zombies are nearby." end
    return "The immediate area looks clear."
end

local function hordeSummary(phase)
    if phase == "escalated" then
        return "the nearby zombie horde grew more dangerous"
    end
    if phase == "deescalated" then
        return "the nearby zombie horde is thinning out"
    end
    if phase == "cleared" then
        return "the nearby zombie horde cleared"
    end
    return "a zombie horde was detected"
end

local function locationFact(record)
    local x = tonumber(record and record.x)
    local y = tonumber(record and record.y)
    local z = tonumber(record and record.z)
    if x and y and z then
        return { x = x, y = y, z = z }
    end
    return tostring(
        record and (record.locationLabel or record.location)
            or "nearby"
    )
end

local function buildHordeSpatial(record, now, episodeID)
    local tactics = PNC.CombatTactics
    local internal = tactics and tactics.Internal or nil
    if not internal
        or type(internal.BuildZombieThreatCentroid) ~= "function"
        or not TacticalSpatial
        or type(TacticalSpatial.Project) ~= "function"
    then
        return nil, "tactical_spatial_unavailable"
    end

    local radius = tonumber(Const and Const.ZOMBIE_TARGET_RADIUS) or 12
    local x, y, count = internal.BuildZombieThreatCentroid(record, radius)
    if not x or not y or (tonumber(count) or 0) <= 0 then
        return nil, "horde_centroid_unavailable"
    end

    local spatial, reason = TacticalSpatial.Project(record, {
        kind = "zombie_group",
        id = episodeID,
        x = x,
        y = y,
        z = tonumber(record and record.z) or 0,
        observedAt = now,
        positionSource = "combat_centroid",
    }, {
        now = now,
        sameAreaThreshold = 0.5,
        maxThreatAgeMs = 2000,
    })
    if not spatial then return nil, reason end

    local profile = CombatReactionProfile
        and type(CombatReactionProfile.Build) == "function"
        and CombatReactionProfile.Build(record, "", {
            role = "witness",
            actorKind = "npc",
            inCombat = true,
            zombieObservation = record.runtime
                and record.runtime.zombieObservation,
        }) or nil
    local mode, modeReason = TacticalLanguage.SelectMode(
        record, profile, spatial
    )
    spatial.presentationMode = mode
    spatial.presentationReason = modeReason
    return spatial
end

local function awarenessFacts(
    record,
    eventID,
    eventType,
    band,
    count,
    reason,
    phase,
    episodeID,
    tacticalSpatial
)
    local pressure = pressureBand(count)
    local fact = {
        eventRef = eventID,
        authoritative = true,
        disclosure = "player",
        location = locationFact(record),
        countBand = band,
        count = count ~= nil and math.max(
            0, math.floor(tonumber(count) or 0)
        ) or nil,
        pressureBand = pressure,
        quantity = quantityText(count, pressure),
        summary = eventType == ZOMBIE_HORDE_MEMORY
            and hordeSummary(phase)
            or "the group retreated to recover stamina",
        retreatReason = reason,
        hordePhase = phase,
        hordeEpisodeID = episodeID,
        spatial = tacticalSpatial,
    }
    if count ~= nil then fact.countBand = countBand(count) end
    return { [tostring(eventID)] = fact }
end

local function currentHordeCount(record)
    local runtime = record and record.runtime or nil
    local observation = runtime and runtime.zombieObservation or nil
    local assessment = runtime and runtime.combatThreatAssessment or nil
    return tonumber(observation and observation.hordeCount)
        or tonumber(assessment and assessment.hordeCount)
        or tonumber(runtime and runtime.hordeCount)
end

-- Re-observe volatile event facts from the owning NPC/combat authority when a
-- player opens a conversation after the event packet was delivered. No event
-- transcript or second event registry is created; the stable lifecycle only
-- supplies the event reference and the current record is authoritative.
local function observeEventFacts(eventRef, npcID, record)
    eventRef = tostring(eventRef or "")
    if eventRef == "" then return nil end
    local eventType
    if string.find(eventRef, "social:zombie_horde_encounter:", 1, true) then
        eventType = ZOMBIE_HORDE_MEMORY
    elseif string.find(eventRef, "social:zombie_stamina_retreat:", 1, true) then
        eventType = ZOMBIE_STAMINA_MEMORY
    else
        return nil
    end
    record = record or Registry and Registry.Get
        and Registry.Get(npcID) or nil
    if not record then return nil end
    local count = currentHordeCount(record)
    local episode = record.runtime
        and record.runtime.zombieHordeAwareness or nil
    return awarenessFacts(
        record,
        eventRef,
        eventType,
        countBand(count),
        count,
        record.runtime and record.runtime.retreatReason,
        episode and episode.lastPhase,
        episode and episode.episodeID
    )
end

local function playerCanHearNPC(player, record, radiusSq)
    local px = coordinate(player, "getX")
    local py = coordinate(player, "getY")
    local pz = coordinate(player, "getZ")
    local nx = tonumber(record and record.x)
    local ny = tonumber(record and record.y)
    local nz = tonumber(record and record.z)
    if not px or not py or not pz or not nx or not ny or not nz then
        return false
    end
    if math.abs(pz - nz) >= 1
        or distanceSq(px, py, nx, ny) > radiusSq
    then
        return false
    end
    return canSee(record, player)
end

local function newZombieAwarenessEventID(record, eventType, now)
    local runtime = record.runtime or {}
    local sequence = math.floor(
        tonumber(runtime.zombieAwarenessEventSequence) or 0
    ) + 1
    record.runtime = runtime
    runtime.zombieAwarenessEventSequence = sequence
    return "social:" .. eventType .. ":" .. tostring(record.id) .. ":"
        .. tostring(math.floor(tonumber(now) or 0)) .. ":"
        .. tostring(sequence)
end

local function emitZombieAwareness(
    record,
    eventType,
    speechEventID,
    eventID,
    source,
    now,
    count,
    reason,
    phase,
    episodeID,
    tacticalPrompt,
    tacticalSpatial
)
    local npcID = tostring(record and record.id or "")
    local radiusSq = WITNESS_RADIUS * WITNESS_RADIUS
    local role = socialRole(record)
    local worldAgeHours = H.WorldAgeHours()
    local band = countBand(count)
    local emitted = 0
    if npcID == "" or not Core
        or type(Core.ForEachPlayer) ~= "function"
    then
        return 0
    end
    Core.ForEachPlayer(function(player)
        local playerKey
        local memoryID
        local relationship
        local state
        local speakerRole
        local tier
        local context
        local result
        local ok
        local sent
        if not player or not playerCanHearNPC(player, record, radiusSq) then
            return
        end
        if tacticalPrompt == true
            and EncounterIntent
            and type(EncounterIntent.MatchesOwner) == "function"
            and EncounterIntent.MatchesOwner(record, player) ~= true
        then
            return
        end
        playerKey = Hooks.ResolvePlayerKey(player)
        if not playerKey then return end
        if not Network
            or type(Network.SendConversationRelationshipForNPC)
                ~= "function"
        then
            return
        end
        relationship = record.social
            and record.social.relationships
            and record.social.relationships[playerKey] or nil
        state = relationshipState(relationship)
        speakerRole = (state == "enemy" or state == "rival")
            and "hostile" or role
        tier = relationshipTier(relationship)
        local combatProfile = CombatReactionProfile
            and type(CombatReactionProfile.Build) == "function"
            and CombatReactionProfile.Build(record, playerKey, {
                role = "witness",
                actorKind = "player",
                zombieObservation = record.runtime
                    and record.runtime.zombieObservation,
            }) or nil
        local encounter = EncounterIntent
            and type(EncounterIntent.Snapshot) == "function"
            and EncounterIntent.Snapshot(record) or nil
        local presentationClass = tacticalPrompt == true
            and "TACTICAL_PROMPT" or "BARK"
        local momentKind = tacticalPrompt == true
            and "tactical_prompt"
            or eventType == ZOMBIE_HORDE_MEMORY
                and "horde_warning" or "combat_warning"
        local combatMoment = CombatMoment.Build({
            kind = momentKind,
            eventType = eventType,
            actorKind = "npc",
            actorID = npcID,
            targetKind = "zombie_group",
            outcome = "observed",
            pressureBand = pressureBand(count),
            nearbyCount = math.max(
                0, math.floor(tonumber(count) or 0)
            ),
            reactionMood = combatProfile
                and combatProfile.combatReactionMood or "steady",
            reactionStyle = combatProfile
                and combatProfile.combatReactionStyle or "practical",
            relationshipState = state,
            relationshipTier = tier,
            encounterID = episodeID,
            encounterIntent = encounter and encounter.intent,
            presentationClass = presentationClass,
            source = source,
            occurredAt = now,
        })
        local awarenessFamily = tacticalPrompt == true
            and "horde_tactical_prompt" or tostring(eventType)
        local allowed = BanterArbiter.Reserve({
            streamKey = "awareness:" .. tostring(playerKey)
                .. ":" .. awarenessFamily,
            now = now,
            cooldownMs = ZOMBIE_AWARENESS_PRESENTATION_COOLDOWN_MS,
            maxSpeakers = 1,
            speakerID = npcID,
            audienceKey = tostring(playerKey),
            family = awarenessFamily,
            speakerCooldownMs = 0,
            familyCooldownMs = ZOMBIE_AWARENESS_PRESENTATION_COOLDOWN_MS,
            priorityHoldMs = tacticalPrompt == true and 5000 or 3000,
            priority = combatMoment.priority,
            moment = combatMoment,
        })
        if allowed ~= true then return end
        memoryID = rememberZombieAwareness(
            record,
            playerKey,
            eventType,
            worldAgeHours,
            band,
            source
        )
        context = {
            eventType = eventType,
            memoryID = memoryID,
            memoryType = eventType,
            source = source,
            zombieCountBand = band,
            combatPressure = pressureBand(count),
            nearbyZombieCount = math.max(
                0, math.floor(tonumber(count) or 0)
            ),
            hordePhase = phase,
            hordeEpisodeID = episodeID,
            combatTacticalPrompt = tacticalPrompt == true,
            tacticalSpatial = tacticalSpatial,
            tacticalPresentationMode = tacticalSpatial
                and tacticalSpatial.presentationMode or "omitted",
            tacticalPresentationReason = tacticalSpatial
                and tacticalSpatial.presentationReason or "spatial_unavailable",
            presentationClass = presentationClass,
            combatMoment = CombatMoment.Snapshot(combatMoment),
            combatReactionStyle = combatProfile
                and combatProfile.combatReactionStyle or "practical",
            combatReactionMood = combatProfile
                and combatProfile.combatReactionMood or "steady",
            factRefs = { eventID },
            semanticEventFacts = awarenessFacts(
                record,
                eventID,
                eventType,
                band,
                count,
                reason,
                phase,
                episodeID,
                tacticalSpatial
            ),
            retreatReason = reason,
            npcType = role,
            socialRole = speakerRole,
            relationshipState = state,
            relationshipTier = tier,
        }
        if memoryID then context.factRefs[#context.factRefs + 1] = memoryID end
        context.factRefs[#context.factRefs + 1] =
            tostring(eventID) .. ":location"
        context.factRefs[#context.factRefs + 1] =
            tostring(eventID) .. ":quantity"
        local realization = SocialReactions
            and type(SocialReactions.Resolve) == "function"
            and SocialReactions.Resolve({
                eventType = eventType,
                act = "REACT",
                topic = "combat",
                context = context,
                eventID = eventID,
                npcID = npcID,
            }) or nil
        if realization and tacticalSpatial then
            local decorated, spatialReason, spatialMetadata =
                TacticalLanguage.Decorate(
                    realization.fallback,
                    "zombie_group",
                    tacticalSpatial,
                    tacticalSpatial.presentationMode
                )
            if spatialMetadata then
                realization.fallback = decorated
                realization.tacticalSpatialPresentation = spatialMetadata
                context.tacticalSpatialPresentation = spatialMetadata
            else
                context.tacticalPresentationReason =
                    spatialReason or context.tacticalPresentationReason
            end
        end
        if not realization
            or type(realization.fallback) ~= "string"
            or realization.fallback == ""
        then
            if BanterArbiter
                and type(BanterArbiter.RecordPresentation) == "function"
            then
                BanterArbiter.RecordPresentation({
                    accepted = false,
                    reason = "semantic_realization_unavailable",
                    at = now,
                    speakerID = npcID,
                    audienceKey = tostring(playerKey),
                    family = awarenessFamily,
                    moment = combatMoment,
                    eventRef = eventID,
                    tacticalSpatial = tacticalSpatial,
                    tacticalPresentation = {
                        mode = tacticalSpatial
                            and tacticalSpatial.presentationMode or "omitted",
                        reason = context.tacticalPresentationReason,
                    },
                })
            end
            audit({
                "luaSide=server",
                "event=SemanticAwarenessPresentation",
                "phase=selection",
                "result=false",
                "reason=semantic_realization_unavailable",
                "eventID=" .. tostring(eventID),
                "npcID=" .. tostring(npcID),
            })
            return
        end
        presentationClass = realization.presentationClass
            or presentationClass
        context.presentationClass = presentationClass
        context.eventRef = eventID
        context.offerIDs = realization.offerIDs or {}
        result = {
            source = eventType,
            eventID = eventID,
            npcID = npcID,
            meaningful = false,
            transientInteraction = true,
            interactionTTLHours = tacticalPrompt == true and 15 / 3600
                or 10 / 3600,
            ambientFlavor = {
                eventID = eventID,
                eventRef = eventID,
                speechEventID = realization.realizationID,
                text = realization.fallback,
                semanticOwned = true,
                eventType = eventType,
                act = realization and realization.semanticAct or "REACT",
                topic = realization and realization.topic or "combat",
                responsePlanID = realization.responsePlanID,
                poolID = realization.realizationFamily,
                realizationFamily = realization.realizationFamily,
                realizationID = realization.realizationID,
                factRefs = realization.groundedFactRefs,
                offerIDs = realization.offerIDs,
                semanticEventFacts = context.semanticEventFacts,
                family = "zombie_awareness",
                priority = combatMoment.priority,
                weight = 0.25,
                llmEligible = false,
                memoryEligible = false,
                npcID = npcID,
                npcType = role,
                socialRole = speakerRole,
                relationshipState = state,
                relationshipTier = tier,
                mergeKey = eventID,
                cooldowns = {
                    familyMs = ZOMBIE_AWARENESS_PRESENTATION_COOLDOWN_MS,
                    speakerMs = 0,
                    ambientMs = 4500,
                    mergeWindowMs = 0,
                },
                ttlMs = 8000,
                holdMs = 1800,
                context = context,
                presentationClass = presentationClass,
                combatMoment = CombatMoment.Snapshot(combatMoment),
                source = {
                    kind = "semantic_speech",
                    channel = "combat",
                    eventType = eventType,
                },
            },
        }
        ok, sent = pcall(
            Network.SendConversationRelationshipForNPC,
            player,
            npcID,
            eventType,
            result
        )
        local delivered = ok and sent == true
        if BanterArbiter
            and type(BanterArbiter.RecordPresentation) == "function"
        then
            BanterArbiter.RecordPresentation({
                accepted = delivered,
                reason = delivered and "presentation_sent"
                    or ok and "presentation_transport_refused"
                    or "presentation_transport_error",
                at = now,
                speakerID = npcID,
                audienceKey = tostring(playerKey),
                family = awarenessFamily,
                moment = combatMoment,
                eventRef = eventID,
                responsePlanID = realization.responsePlanID,
                realizationID = realization.realizationID,
                presentationClass = presentationClass,
                offerIDs = realization.offerIDs,
                tacticalSpatial = tacticalSpatial,
                tacticalPresentation = context.tacticalSpatialPresentation
                    or {
                        mode = tacticalSpatial
                            and tacticalSpatial.presentationMode or "omitted",
                        reason = context.tacticalPresentationReason,
                    },
            })
        end
        if delivered then emitted = emitted + 1 end
    end)
    return emitted
end

function Hooks.ObserveZombieHorde(record, count, threshold, now, source)
    local runtime
    local state
    local eventType = ZOMBIE_HORDE_MEMORY
    local eventID
    local band
    local previousBand
    local phase
    local previousRank
    local currentRank
    count = math.max(0, math.floor(tonumber(count) or 0))
    threshold = math.max(1, math.floor(tonumber(threshold) or 4))
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    if not record or record.alive == false or not record.id then
        return false, "invalid_observer"
    end

    runtime = record.runtime or {}
    state = runtime.zombieHordeAwareness or {
        active = false,
        sequence = 0,
    }
    record.runtime = runtime
    runtime.zombieHordeAwareness = state

    band = pressureBand(count)
    previousBand = tostring(state.lastBand or "none")
    state.lastObservedAt = now
    state.lastCount = count

    if count < threshold then
        state.lastBand = band
        if state.active == true then
            state.active = false
            state.lastPhase = "cleared"
            state.clearedAt = now
            state.lastEpisodeID = state.episodeID
            local clearedEpisodeID = state.episodeID
            state.episodeID = nil
            if EncounterIntent
                and type(EncounterIntent.OnHordeTransition) == "function"
            then
                EncounterIntent.OnHordeTransition(
                    record, "cleared", clearedEpisodeID, now
                )
            end
            return false, "horde_episode_cleared"
        end
        state.lastPhase = "clear"
        return false, "below_horde_threshold"
    end

    if state.active ~= true then
        state.active = true
        state.sequence = math.max(
            0, math.floor(tonumber(state.sequence) or 0)
        ) + 1
        state.startedAt = now
        state.lastBand = band
        state.lastPhase = "started"
        eventID = newZombieAwarenessEventID(record, eventType, now)
        state.episodeID = eventID
        if EncounterIntent
            and type(EncounterIntent.OnHordeTransition) == "function"
        then
            EncounterIntent.OnHordeTransition(
                record, "started", state.episodeID, now
            )
        end
        local tacticalPrompt = EncounterIntent
            and type(EncounterIntent.IsPromptSpeaker) == "function"
            and EncounterIntent.IsPromptSpeaker(
                record, state.episodeID
            ) == true
        local tacticalSpatial = buildHordeSpatial(
            record, now, state.episodeID
        )
        local sceneAdopters = PNC.Semantics
            and PNC.Semantics.InteractionSceneAdopters or nil
        if sceneAdopters
            and type(sceneAdopters.OnHordeTransition) == "function"
        then
            sceneAdopters.OnHordeTransition(record, {
                phase = "started",
                episodeID = state.episodeID,
                eventID = eventID,
                pressureBand = band,
                nearbyCount = count,
                source = source or "zombie_observation",
                now = now,
                spatial = tacticalSpatial,
            })
        end
        emitZombieAwareness(
            record,
            eventType,
            "social.zombie_horde_detected",
            eventID,
            source or "zombie_observation",
            now,
            count,
            nil,
            "started",
            state.episodeID,
            tacticalPrompt,
            tacticalSpatial
        )
        return true, eventID, "started"
    end

    previousRank = pressureRank(previousBand)
    currentRank = pressureRank(band)
    state.lastBand = band
    if currentRank > previousRank then
        phase = "escalated"
    elseif currentRank < previousRank then
        phase = "deescalated"
    else
        state.lastPhase = "stable"
        return false, "horde_episode_stable"
    end

    state.lastPhase = phase
    if EncounterIntent
        and type(EncounterIntent.OnHordeTransition) == "function"
    then
        EncounterIntent.OnHordeTransition(
            record, phase, state.episodeID, now
        )
    end
    eventID = newZombieAwarenessEventID(record, eventType, now)
    local tacticalSpatial = buildHordeSpatial(
        record, now, state.episodeID
    )
    emitZombieAwareness(
        record,
        eventType,
        "social.zombie_horde_detected",
        eventID,
        source or "zombie_observation",
        now,
        count,
        nil,
        phase,
        state.episodeID,
        nil,
        tacticalSpatial
    )
    return true, eventID, phase
end

function Hooks.RecordZombieStaminaRetreat(record, reason, now)
    local count
    local eventType = ZOMBIE_STAMINA_MEMORY
    local eventID
    if not record or record.alive == false or not record.id then
        return false, "invalid_observer"
    end
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    count = record.runtime
        and record.runtime.combatThreatAssessment
        and record.runtime.combatThreatAssessment.hordeCount or 0
    eventID = newZombieAwarenessEventID(record, eventType, now)
    return emitZombieAwareness(
        record,
        eventType,
        "social.zombie_stamina_retreat",
        eventID,
        "combat",
        now,
        count,
        tostring(reason or "recovering_stamina")
    ) > 0, eventID
end


H.CombatCall = call
H.CombatAudit = audit
H.CombatCoordinate = coordinate
H.CombatDistanceSq = distanceSq
H.CombatCanSee = canSee
H.CombatRelationshipDelta = relationshipDelta
H.CombatRelationshipState = relationshipState
H.CombatRelationshipTier = relationshipTier
H.CombatSocialRole = socialRole
H.CombatDayIndex = dayIndex
H.CombatMemoryToday = memoryToday
H.CombatRememberZombieAwareness = rememberZombieAwareness
H.CombatCountBand = countBand
H.CombatPlayerCanHearNPC = playerCanHearNPC
H.CombatNewZombieAwarenessEventID = newZombieAwarenessEventID
H.CombatEmitZombieAwareness = emitZombieAwareness
H.ObserveSemanticEventFacts = observeEventFacts

return Hooks
