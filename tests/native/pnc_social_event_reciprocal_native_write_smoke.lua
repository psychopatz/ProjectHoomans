-- Target-owned native social-event restart fixture, phase one.
-- Exercise reciprocal synthetic-NPC observers and conduct evidence.

local ACTOR_ID = "npc_pzharness_social_event_reciprocal_actor"
local TARGET_ID = "npc_pzharness_social_event_reciprocal_target"
local ACTOR_KEY = "npc:" .. ACTOR_ID
local TARGET_KEY = "npc:" .. TARGET_ID
local EVENT_ID = "social:pzharness:social-event-reciprocal"
local EVENT_TYPE = "survived_combat_together"
local OCCURRED_AT = 1080
local ACTOR_MEMORY_ID = "memory:" .. EVENT_ID .. ":"
    .. ACTOR_ID .. ":actor"
local TARGET_MEMORY_ID = "memory:" .. EVENT_ID .. ":"
    .. TARGET_ID .. ":target"
local ACTOR_EVIDENCE_ID = "conduct:" .. EVENT_ID .. ":"
    .. ACTOR_KEY .. ":participant"
local TARGET_EVIDENCE_ID = "conduct:" .. EVENT_ID .. ":"
    .. TARGET_KEY .. ":participant"

local function buildRecord(id, displayName, identitySeed)
    return PNC.Types.NewRecord({
        id = id,
        displayName = displayName,
        identitySeed = identitySeed,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 300,
        y = 400,
        z = 0,
        identity = {
            seed = identitySeed,
            displayName = displayName,
        },
        social = {
            personalityOverrides = {
                bravery = 0.5,
                loyalty = 0.5,
            },
        },
    })
end

local function buildEvent()
    return {
        id = EVENT_ID,
        type = EVENT_TYPE,
        actorKey = ACTOR_KEY,
        targetKey = TARGET_KEY,
        occurredAt = OCCURRED_AT,
        sourceSystem = "combat",
        context = {
            nativeHarness = true,
        },
    }
end

local function assertRelationship(
    relationship,
    observerID,
    memoryID,
    message
)
    local memory = relationship and relationship.memories
        and relationship.memories[1]
    local interaction = relationship and relationship.interactionJournal
        and relationship.interactionJournal[1]
    PZHarness.assertTrue(
        relationship
            and relationship.targetKind == "npc"
            and relationship.targetID == observerID
            and relationship.baselineApproval == 0
            and relationship.baselineRespect == 0
            and relationship.approval == 3
            and relationship.respect == 6
            and relationship.familiarity == 4
            and relationship.state == "unknown"
            and relationship.previousState == "unknown"
            and relationship.revision == 1
            and relationship.lastInteractionAt == OCCURRED_AT
            and relationship.lastEvaluatedAt == OCCURRED_AT
            and relationship.saturation[EVENT_TYPE].approval == 3
            and relationship.saturation[EVENT_TYPE].respect == 6
            and #relationship.memories == 1
            and memory and memory.id == memoryID
            and memory.type == EVENT_TYPE
            and memory.createdAt == OCCURRED_AT
            and memory.lastEvaluatedAt == OCCURRED_AT
            and memory.approvalEffect == 3
            and memory.respectEffect == 6
            and memory.moraleEffect == 3
            and memory.strength == 1
            and memory.decayPerDay == 0.035
            and memory.permanent == false
            and memory.shareable == false
            and memory.knowledgeSource == "experienced"
            and memory.tags.combat == true
            and memory.tags.shared_danger == true
            and memory.tags.teamwork == true
            and #relationship.interactionJournal == 1
            and relationship.interactionRevision == 1
            and interaction and interaction.eventID == EVENT_ID
            and interaction.kind == EVENT_TYPE
            and interaction.source == "combat"
            and interaction.interactionType == EVENT_TYPE
            and interaction.memoryID == nil
            and interaction.at == OCCURRED_AT
            and interaction.worldAgeHours == OCCURRED_AT
            and interaction.applied == true,
        message
    )
end

local function assertConduct(
    conduct,
    entityKey,
    subjectKey,
    evidenceID,
    message
)
    local evidence = conduct and conduct.evidence
        and conduct.evidence[1]
    PZHarness.assertTrue(
        conduct
            and conduct.schemaVersion == 1
            and conduct.revision == 1
            and conduct.scores.reliability == 2
            and conduct.scores.courage == 2
            and conduct.scores.groupLoyalty == 1
            and #conduct.evidence == 1
            and #conduct.recentEvidenceIDs == 1
            and conduct.recentEvidenceIDs[1] == evidenceID
            and evidence and evidence.id == evidenceID
            and evidence.eventID == EVENT_ID
            and evidence.eventType == EVENT_TYPE
            and evidence.actorKey == entityKey
            and evidence.subjectKey == subjectKey
            and evidence.createdAt == OCCURRED_AT
            and evidence.lastEvaluatedAt == OCCURRED_AT
            and evidence.effects.reliability == 2
            and evidence.effects.courage == 2
            and evidence.effects.groupLoyalty == 1
            and evidence.strength == 1
            and evidence.decayPerDay == 0.015
            and evidence.permanent == false
            and evidence.visibility == "direct"
            and evidence.shareable == false
            and evidence.tags.combat == true
            and evidence.tags.teamwork == true
            and evidence.tags.shared_danger == true,
        message
    )
end

local function findDetail(details, observerID)
    local index
    for index = 1, #(details or {}) do
        if details[index].observerNPCID == observerID then
            return details[index]
        end
    end
    return nil
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local types = PNC and PNC.Types or nil
    local entityRef = PNC and PNC.EntityRef or nil
    local relationships = PNC and PNC.Relationships or nil
    local socialEvents = PNC and PNC.SocialEvents or nil
    local conduct = PNC and PNC.Conduct or nil
    PZHarness.assertTrue(
        registry and registry.AddRecord and registry.Get
            and registry.GetStorageDirectory,
        "native NPC registry reciprocal social-event API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native reciprocal social-event record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(ACTOR_ID) == ACTOR_KEY
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY,
        "native reciprocal social-event entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native reciprocal relationship API was not available"
    )
    PZHarness.assertTrue(
        socialEvents and socialEvents.GetDefinition
            and socialEvents.Process,
        "native reciprocal social-event process API was not available"
    )
    PZHarness.assertTrue(
        conduct and conduct.GetForNPC,
        "native social-event conduct query API was not available"
    )
    local definition = socialEvents.GetDefinition(EVENT_TYPE)
    local conductDefinition = PNC.ConductDefinitions[EVENT_TYPE]
    PZHarness.assertTrue(
        definition and definition.id == EVENT_TYPE
            and definition.allowedSourceSystems.combat == true
            and definition.reciprocalNPCObservers == true
            and definition.targetMemory
            and definition.targetMemory.type == EVENT_TYPE
            and conductDefinition
            and conductDefinition.participants == "actor_and_target"
            and conductDefinition.effects.reliability == 2,
        "native reciprocal social-event definition was not available"
    )
    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )

    local actorOK, actor = pcall(
        buildRecord,
        ACTOR_ID,
        "PZ Harness Reciprocal Social Event Actor",
        8383
    )
    local targetOK, target = pcall(
        buildRecord,
        TARGET_ID,
        "PZ Harness Reciprocal Social Event Target",
        8484
    )
    PZHarness.assertTrue(
        actorOK and type(actor) == "table" and actor.id == ACTOR_ID
            and actor.social and actor.social.relationships
            and targetOK and type(target) == "table"
            and target.id == TARGET_ID
            and target.social and target.social.relationships,
        "native reciprocal social-event NPC records were not constructed"
    )
    local actorAddOK, actorAdded = pcall(registry.AddRecord, actor)
    local targetAddOK, targetAdded = pcall(registry.AddRecord, target)
    PZHarness.assertTrue(
        actorAddOK and actorAdded and targetAddOK and targetAdded,
        "native reciprocal social-event NPC records were not registered"
    )

    local processOK, result = pcall(socialEvents.Process, buildEvent())
    local targetDetail = result and findDetail(result.details, TARGET_ID)
    local actorDetail = result and findDetail(result.details, ACTOR_ID)
    PZHarness.assertTrue(
        processOK and result and result.ok == true
            and result.eventID == EVENT_ID
            and result.eventType == EVENT_TYPE
            and result.actorKey == ACTOR_KEY
            and result.targetKey == TARGET_KEY
            and result.memoriesCreated == 2
            and result.relationshipsChanged == 2
            and result.conductEvidenceCreated == 2
            and result.details and #result.details == 2
            and targetDetail and targetDetail.aboutKey == ACTOR_KEY
            and targetDetail.memoryID == TARGET_MEMORY_ID
            and actorDetail and actorDetail.aboutKey == TARGET_KEY
            and actorDetail.memoryID == ACTOR_MEMORY_ID
            and result.conductDetails and #result.conductDetails == 2,
        "native reciprocal social-event process failed: "
            .. tostring(result and result.reason or result)
    )
    assertRelationship(
        targetDetail and targetDetail.relationshipAfter,
        ACTOR_ID,
        TARGET_MEMORY_ID,
        "native reciprocal target relationship was not normalized"
    )
    assertRelationship(
        actorDetail and actorDetail.relationshipAfter,
        TARGET_ID,
        ACTOR_MEMORY_ID,
        "native reciprocal actor relationship was not normalized"
    )
    local actorConduct = conduct.GetForNPC(ACTOR_ID)
    local targetConduct = conduct.GetForNPC(TARGET_ID)
    assertConduct(
        actorConduct,
        ACTOR_KEY,
        TARGET_KEY,
        ACTOR_EVIDENCE_ID,
        "native reciprocal actor conduct was not normalized"
    )
    assertConduct(
        targetConduct,
        TARGET_KEY,
        ACTOR_KEY,
        TARGET_EVIDENCE_ID,
        "native reciprocal target conduct was not normalized"
    )
    PZHarness.assertTrue(
        actor.social.recentEventIDs
            and #actor.social.recentEventIDs == 1
            and actor.social.recentEventIDs[1] == EVENT_ID
            and target.social.recentEventIDs
            and #target.social.recentEventIDs == 1
            and target.social.recentEventIDs[1] == EVENT_ID
            and registry.DirtyByID
            and registry.DirtyByID[ACTOR_ID] == true
            and registry.DirtyByID[TARGET_ID] == true,
        "native reciprocal social-event state was not retained"
    )

    local duplicateOK, duplicate = pcall(
        socialEvents.Process,
        buildEvent()
    )
    PZHarness.assertTrue(
        duplicateOK and duplicate and duplicate.ok == false
            and duplicate.reason == "duplicate_event"
            and duplicate.memoriesCreated == 0
            and duplicate.relationshipsChanged == 0,
        "native reciprocal social-event process did not reject duplicates"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_social_event_reciprocal_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native reciprocal social-event commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save reciprocal state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[ACTOR_ID] == nil
            and registry.DirtyByID[TARGET_ID] == nil,
        "native reciprocal social-event records remained dirty after commit"
    )

    local directory = registry.GetStorageDirectory()
    local actorPointer = directory and directory.records
        and directory.records[ACTOR_ID]
    local targetPointer = directory and directory.records
        and directory.records[TARGET_ID]
    local actorRaw = actorPointer and ModData.get(actorPointer.storageKey)
        or nil
    local targetRaw = targetPointer and ModData.get(targetPointer.storageKey)
        or nil
    local actorRawRelationship = actorRaw and actorRaw.social
        and actorRaw.social.relationships[TARGET_KEY]
    local targetRawRelationship = targetRaw and targetRaw.social
        and targetRaw.social.relationships[ACTOR_KEY]
    local actorRawEvidence = actorRaw and actorRaw.social
        and actorRaw.social.conduct and actorRaw.social.conduct.evidence[1]
    local targetRawEvidence = targetRaw and targetRaw.social
        and targetRaw.social.conduct and targetRaw.social.conduct.evidence[1]
    PZHarness.assertTrue(
        type(actorPointer) == "table"
            and actorPointer.recordRevision == 1
            and type(targetPointer) == "table"
            and targetPointer.recordRevision == 1
            and type(actorRaw) == "table"
            and actorRaw.id == ACTOR_ID
            and actorRaw.identity and actorRaw.identity.seed == 8383
            and type(targetRaw) == "table"
            and targetRaw.id == TARGET_ID
            and targetRaw.identity and targetRaw.identity.seed == 8484
            and type(actorRawRelationship) == "table"
            and actorRawRelationship.approval == 3
            and actorRawRelationship.respect == 6
            and actorRawRelationship.familiarity == 4
            and type(targetRawRelationship) == "table"
            and targetRawRelationship.approval == 3
            and targetRawRelationship.respect == 6
            and targetRawRelationship.familiarity == 4
            and actorRaw.social and actorRaw.social.conduct
            and actorRaw.social.conduct.revision == 1
            and actorRaw.social.conduct.scores.reliability == 2
            and actorRaw.social.conduct.scores.courage == 2
            and actorRaw.social.conduct.scores.groupLoyalty == 1
            and actorRawEvidence and actorRawEvidence.id == ACTOR_EVIDENCE_ID
            and targetRaw.social and targetRaw.social.conduct
            and targetRaw.social.conduct.revision == 1
            and targetRaw.social.conduct.scores.reliability == 2
            and targetRaw.social.conduct.scores.courage == 2
            and targetRaw.social.conduct.scores.groupLoyalty == 1
            and targetRawEvidence
            and targetRawEvidence.id == TARGET_EVIDENCE_ID,
        "native reciprocal social-event ModData did not contain committed state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native reciprocal social-event OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print(
                "PZ_HARNESS_SOCIAL_EVENT_RECIPROCAL_WRITE_ON_SAVE:"
                    .. TARGET_ID
            )
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native reciprocal social-event GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native reciprocal social-event GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native reciprocal social-event GameWindow.save did not trigger OnSave"
        )
    end
end
