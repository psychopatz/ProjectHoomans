-- Semantic context assembly from normalized production sources.

local Builder = {}
local Sources = require "worker/Conversation_Context_Sources"
local ActorConversationContext = require
    "PNC/Semantics/PNC_ActorConversationContext"

function Builder.build(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local number = Values.number
    local copy = Values.copy
    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    local world = scenario.world or {}
    local conversation = scenario.conversation or {}
    local player = scenario.player or {}
    local playerNeedSource = type(player.needs) == "table"
        and player.needs or world
    local relationship = context.SemanticAdapters.relationshipFor(
        context, npc.npcID
    )
    local audience = Sources.productionAudience(
        context,
        npc,
        player,
        relationship,
        copy
    )
    local tacticalHostility = Sources.canonicalTacticalHostility(
        context,
        npc,
        audience,
        copy
    )
    local personalRelationship = Sources.canonicalPersonalRelationship(
        context,
        relationship,
        copy
    )
    local factionContext = type(npc.factionContext) == "table"
        and npc.factionContext
        or Runtime.productionFactionContext
    local npcName = context.SemanticAdapters.identityName(context, npc)
    -- The world-level fields remain a legacy scenario fallback. An explicit
    -- npc.needs/conditionStats table is authoritative even when empty (unknown).
    local needSource = type(npc.needs) == "table" and npc.needs or world
    local conditionSource = type(npc.conditionStats) == "table"
        and npc.conditionStats or world
    local needs = Sources.numbersFor(needSource, Sources.NEED_KEYS, number)
    local conditions = Sources.numbersFor(conditionSource, Sources.CONDITION_KEYS, number)
    local bodyHealth = type(npc.bodyHealth) == "table"
        and copy(npc.bodyHealth) or nil
    local hpCurrent = number(npc.hpCurrent, nil)
    local hpMax = number(npc.hpMax, nil)
    local snapshotNeeds = copy(needs)
    -- Preserve the old snapshot.needs condition fields for worker consumers,
    -- while exposing conditionStats to the real production situation resolver.
    for index = 1, #Sources.CONDITION_KEYS do
        local key = Sources.CONDITION_KEYS[index]
        snapshotNeeds[key] = conditions[key]
    end
    local configuredAuthority = type(npc.actorAuthority) == "table"
        and npc.actorAuthority or {}
    local companion = configuredAuthority.companion
    if companion == nil then companion = npc.companion == true end
    local owned = configuredAuthority.owned
    if owned == nil then owned = npc.ownedByPlayer == true end
    local authorityEligible = configuredAuthority.eligible
    if authorityEligible == nil then
        authorityEligible = companion == true and owned == true
    end
    local authorityStatus = configuredAuthority.status
        or (authorityEligible and "eligible"
            or (companion == false and "not_companion"
                or owned == false and "not_owned" or "authority_unknown"))
    local identityKnown = npc.identityState == "known"
        or (owned == true and npc.recruited == true)
    local effectiveIdentityState = identityKnown and "known"
        or (npc.identityState or "unknown")
    local priorContext = Runtime.view and Runtime.view.spec
        and Runtime.view.spec.context or nil
    local output = {
        npcID = npc.npcID,
        campSiteCandidates = copy(
            scenario.campSiteCandidates
                or (priorContext and priorContext.campSiteCandidates)
                or {}
        ),
        locationObservation = copy(scenario.locationObservation
            or (priorContext and priorContext.locationObservation)),
        saveSeed = world.seedString or world.worldSeedString
            or world.worldSeed,
        identityState = effectiveIdentityState,
        identity = copy(npc.identity),
        npcName = npcName,
        npcFullName = npcName,
        npcFirstName = npc.forename,
        npcState = {
            campSiteCandidates = copy(
                scenario.campSiteCandidates
                    or (priorContext and priorContext.npcState and priorContext.npcState.campSiteCandidates)
                    or {}
            ),
            traits = copy(npc.traits or {}),
            startingRelationship = copy(npc.startingRelationship),
            identityState = effectiveIdentityState,
            healthState = npc.healthState,
            activeBehavior = npc.activeBehavior,
            orderKind = npc.orderKind
                or (type(npc.orderSpec) == "table" and npc.orderSpec.kind)
                or "idle",
            followState = copy(npc.followState or { mode = "idle" }),
            hostility = copy(npc.hostility),
            tacticalHostility = copy(tacticalHostility),
            role = npc.role,
            bodyHealth = bodyHealth,
            hpCurrent = hpCurrent,
            hpMax = hpMax,
            needs = copy(needs),
            conditionStats = copy(conditions),
        },
        relationshipState = relationship.relationshipState
            or npc.relationshipState or "unknown",
        identityTrust = relationship.identityTrust,
        relationship = copy(relationship),
        personalRelationship = copy(personalRelationship),
        factionRelationship = copy(factionContext),
        tacticalHostility = copy(tacticalHostility),
        conversationAudience = copy(audience),
        startingRelationship = copy(npc.startingRelationship),
        actorAuthority = {
            eligible = authorityEligible == true,
            companion = companion,
            owned = owned,
            status = authorityStatus,
        },
        npcTraits = copy(npc.traits or {}),
        npcTraitFingerprint = npc.npcTraitFingerprint,
        npcPersonality = copy(
            context.npcPersonality or npc.personality or {}
        ),
        npcPersonalityMode = context.npcPersonalityMode or "generated",
        npcGeneratedPersonality = copy(context.npcGeneratedPersonality),
        playerSocialProfile = copy(context.playerSocialProfile),
        playerTraitConflicts = copy(context.playerTraitConflicts),
        playerTraitFingerprint = context.playerTraitFingerprint,
        semanticFactValues = copy(context.semanticFactValues or {}),
        player = {
            gender = player.gender,
            needs = Sources.numbersFor(playerNeedSource,
                { "hunger", "thirst", "fatigue", "stress", "boredom", "panic" },
                number),
            traits = copy(player.traits or player.socialTraits or {}),
            socialProfile = copy(context.playerSocialProfile),
            traitConflicts = copy(context.playerTraitConflicts),
            traitFingerprint = context.playerTraitFingerprint,
        },
        playerNameKnown = true,
        baseEstablished = scenario.baseEstablished == true,
        -- The production adapter accepts the normalized player record. The
        -- headless engine object deliberately exposes names through its
        -- descriptor, so passing the proxy here leaves playerName empty and
        -- makes the semantic "say your real name" choice unverifiable.
        playerName = context.SemanticAdapters.playerName(
            context, context.playerData or player
        ),
        playerGender = player.gender,
        playerIdentitySeed = player.characterUUID,
        characterUUID = player.characterUUID,
        conversationTopic = conversation.topic
            or priorContext and priorContext.conversationTopic
            or "greeting",
        conversationLifecycleState = { token = conversation.token or "harness-lease" },
        semanticAuthorization = copy(
            conversation.semanticAuthorization
                or npc.semanticAuthorization
        ),
        entry = {
            snapshot = {
                activeBehavior = npc.activeBehavior,
                followState = copy(npc.followState or { mode = "idle" }),
                hostility = copy(npc.hostility),
                role = npc.role,
                healthState = npc.healthState,
                bodyHealth = bodyHealth,
                residence = copy(npc.residence),
                knowledge = copy(npc.knowledge),
                inventorySummary = copy(npc.inventorySummary),
                hpCurrent = hpCurrent,
                hpMax = hpMax,
                needs = snapshotNeeds,
                conditionStats = copy(conditions),
                tacticalClass = npc.tacticalClass,
            },
            relationship = copy(relationship),
            tacticalClass = npc.tacticalClass,
            id = npc.npcID,
            record = Runtime.hydratedNpcRecord,
        },
    }
    -- Preserve the production composer projection across a worker context
    -- refresh. The registry/authority remains the state owner; this is only
    -- the public view projection consumed by semantic suggestions.
    if type(priorContext) == "table" then
        output.activeConversationBlockID =
            priorContext.activeConversationBlockID
        output.conversationBlockContext =
            priorContext.conversationBlockContext
        output.conversationBlock = Values.copy(priorContext.conversationBlock)
        output.categoryDiagnostics = Values.copy(
            priorContext.categoryDiagnostics
        )
        output.semanticSuggestionGroupID =
            priorContext.semanticSuggestionGroupID
    end
    local session = Runtime.view and Runtime.view.session or nil
    local dialogueContext = session and session.semanticDialogueContext
    if dialogueContext then
        output.pendingIdentityExchange = dialogueContext.pendingIdentityExchange
        if type(dialogueContext.ToContext) == "function" then
            output.semanticDialogueContext = Values.copy(
                dialogueContext:ToContext()
            )
        end
    end
    output.currentTopic = output.conversationTopic
    output.actorConversationContext = ActorConversationContext.Build(output)
    return output
end

return Builder
