-- Target-owned native social-event restart fixture, phase one.
-- Exercise one bounded synthetic-NPC SocialEvents.Process transaction.

local ACTOR_ID = "npc_pzharness_social_event_process_actor"
local TARGET_ID = "npc_pzharness_social_event_process_target"
local ACTOR_KEY = "npc:" .. ACTOR_ID
local TARGET_KEY = "npc:" .. TARGET_ID
local EVENT_ID = "social:pzharness:social-event-process"
local EVENT_TYPE = "faction_member_attacked"
local OCCURRED_AT = 1040
local MEMORY_ID = "memory:" .. EVENT_ID .. ":"
    .. TARGET_ID .. ":target"

local function buildRecord(id, displayName, identitySeed)
    return PNC.Types.NewRecord({
        id = id,
        displayName = displayName,
        identitySeed = identitySeed,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 280,
        y = 380,
        z = 0,
        identity = {
            seed = identitySeed,
            displayName = displayName,
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

local function assertRelationship(relationship, message)
    local memory = relationship and relationship.memories
        and relationship.memories[1]
    local interaction = relationship and relationship.interactionJournal
        and relationship.interactionJournal[1]
    PZHarness.assertTrue(
        relationship
            and relationship.targetKind == "npc"
            and relationship.targetID == ACTOR_ID
            and relationship.baselineApproval == 0
            and relationship.baselineRespect == 0
            and relationship.approval == -2
            and relationship.respect == -3
            and relationship.familiarity == 0
            and relationship.state == "unknown"
            and relationship.previousState == "unknown"
            and relationship.revision == 1
            and relationship.lastInteractionAt == OCCURRED_AT
            and relationship.lastEvaluatedAt == OCCURRED_AT
            and #relationship.memories == 1
            and memory and memory.id == MEMORY_ID
            and memory.type == EVENT_TYPE
            and memory.aboutKey == ACTOR_KEY
            and memory.createdAt == OCCURRED_AT
            and memory.lastEvaluatedAt == OCCURRED_AT
            and memory.approvalEffect == -2
            and memory.respectEffect == -3
            and memory.moraleEffect == -1
            and memory.strength == 1
            and memory.permanent == false
            and memory.shareable == true
            and memory.knowledgeSource == "community_rumor"
            and memory.sourceKey == nil
            and memory.tags.combat == true
            and memory.tags.faction == true
            and memory.tags.retaliation == true
            and memory.tags.hostility == true
            and #relationship.interactionJournal == 1
            and relationship.interactionRevision == 1
            and interaction and interaction.kind == EVENT_TYPE
            and interaction.source == "combat"
            and interaction.interactionType == EVENT_TYPE
            and interaction.at == OCCURRED_AT
            and interaction.worldAgeHours == OCCURRED_AT
            and interaction.applied == true,
        message
    )
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local types = PNC and PNC.Types or nil
    local entityRef = PNC and PNC.EntityRef or nil
    local relationships = PNC and PNC.Relationships or nil
    local socialEvents = PNC and PNC.SocialEvents or nil
    PZHarness.assertTrue(
        registry and registry.AddRecord and registry.Get
            and registry.GetStorageDirectory,
        "native NPC registry social-event API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC social-event record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(ACTOR_ID) == ACTOR_KEY
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY,
        "native social-event entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get,
        "native relationship query API was not available"
    )
    PZHarness.assertTrue(
        socialEvents and socialEvents.GetDefinition
            and socialEvents.Process,
        "native social-event process API was not available"
    )
    local definition = socialEvents.GetDefinition(EVENT_TYPE)
    PZHarness.assertTrue(
        definition and definition.id == EVENT_TYPE
            and definition.allowedSourceSystems.combat == true
            and definition.targetMemory
            and definition.targetMemory.type == EVENT_TYPE
            and PNC.ConductDefinitions[EVENT_TYPE].required == false,
        "native conduct-optional social-event definition was not available"
    )
    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )

    local actorOK, actor = pcall(
        buildRecord,
        ACTOR_ID,
        "PZ Harness Social Event Actor",
        8181
    )
    local targetOK, target = pcall(
        buildRecord,
        TARGET_ID,
        "PZ Harness Social Event Target",
        8282
    )
    PZHarness.assertTrue(
        actorOK and type(actor) == "table" and actor.id == ACTOR_ID
            and actor.social and actor.social.relationships
            and targetOK and type(target) == "table"
            and target.id == TARGET_ID
            and target.social and target.social.relationships,
        "native synthetic social-event NPC records were not constructed"
    )
    local actorAddOK, actorAdded = pcall(registry.AddRecord, actor)
    local targetAddOK, targetAdded = pcall(registry.AddRecord, target)
    PZHarness.assertTrue(
        actorAddOK and actorAdded and targetAddOK and targetAdded,
        "native synthetic social-event NPC records were not registered"
    )

    local processOK, result = pcall(socialEvents.Process, buildEvent())
    PZHarness.assertTrue(
        processOK and result and result.ok == true
            and result.eventID == EVENT_ID
            and result.eventType == EVENT_TYPE
            and result.actorKey == ACTOR_KEY
            and result.targetKey == TARGET_KEY
            and result.memoriesCreated == 1
            and result.relationshipsChanged == 1
            and result.conductEvidenceCreated == 0
            and result.details and #result.details == 1
            and result.details[1].observerNPCID == TARGET_ID
            and result.details[1].aboutKey == ACTOR_KEY
            and result.details[1].memoryID == MEMORY_ID
            and result.details[1].relationshipAfter,
        "native social-event process failed: "
            .. tostring(result and result.reason or result)
    )
    assertRelationship(
        result and result.details and result.details[1].relationshipAfter,
        "native social-event process did not normalize its relationship"
    )

    local relationship = relationships.Get(TARGET_ID, ACTOR_KEY)
    assertRelationship(
        relationship,
        "native social-event process relationship was not readable"
    )
    PZHarness.assertTrue(
        target.social.recentEventIDs
            and #target.social.recentEventIDs == 1
            and target.social.recentEventIDs[1] == EVENT_ID
            and target.social.morale == -1
            and target.social.relationships[TARGET_KEY] == nil
            and target.social.relationships[ACTOR_KEY] ~= nil
            and registry.DirtyByID
            and registry.DirtyByID[TARGET_ID] == true,
        "native social-event process did not retain target state"
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
        "native social-event process did not reject duplicate events"
    )
    assertRelationship(
        relationships.Get(TARGET_ID, ACTOR_KEY),
        "native social-event duplicate changed authoritative state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_social_event_process_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native social-event process commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save social-event NPC state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[TARGET_ID] == nil,
        "native social-event target record remained dirty after commit"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[TARGET_ID]
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[ACTOR_KEY]
    local rawMemory = rawRelationship and rawRelationship.memories
        and rawRelationship.memories[1]
    local rawInteraction = rawRelationship
        and rawRelationship.interactionJournal
        and rawRelationship.interactionJournal[1]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1
            and type(raw) == "table"
            and raw.id == TARGET_ID
            and raw.identity and raw.identity.seed == 8282
            and raw.social and raw.social.morale == -1
            and raw.social.recentEventIDs
            and #raw.social.recentEventIDs == 1
            and raw.social.recentEventIDs[1] == EVENT_ID
            and type(rawRelationship) == "table"
            and rawRelationship.approval == -2
            and rawRelationship.respect == -3
            and rawRelationship.familiarity == 0
            and rawRelationship.state == "unknown"
            and rawRelationship.revision == 1
            and rawRelationship.lastInteractionAt == OCCURRED_AT
            and rawRelationship.lastEvaluatedAt == OCCURRED_AT
            and type(rawMemory) == "table"
            and rawMemory.id == MEMORY_ID
            and rawMemory.type == EVENT_TYPE
            and rawMemory.aboutKey == ACTOR_KEY
            and rawMemory.approvalEffect == -2
            and rawMemory.respectEffect == -3
            and rawMemory.moraleEffect == -1
            and rawMemory.permanent == false
            and rawMemory.shareable == true
            and rawMemory.knowledgeSource == "community_rumor"
            and type(rawInteraction) == "table"
            and rawInteraction.kind == EVENT_TYPE
            and rawInteraction.source == "combat"
            and rawInteraction.interactionType == EVENT_TYPE
            and rawInteraction.at == OCCURRED_AT
            and rawInteraction.applied == true,
        "native social-event ModData did not contain committed state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native social-event OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print(
                "PZ_HARNESS_SOCIAL_EVENT_PROCESS_WRITE_ON_SAVE:"
                    .. TARGET_ID
            )
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native social-event GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native social-event GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native social-event GameWindow.save did not trigger OnSave"
        )
    end
end
