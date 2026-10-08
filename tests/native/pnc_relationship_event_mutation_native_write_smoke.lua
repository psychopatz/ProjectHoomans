-- Target-owned native relationship restart fixture, phase one.
-- Exercise one bounded social-event relationship mutation.

local NPC_ID = "npc_pzharness_relationship_event_mutation_restart"
local TARGET_ID = "npc_pzharness_relationship_event_mutation_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local SOURCE_KEY = "npc:" .. NPC_ID
local EVENT_ID = "event:pzharness:relationship-event-mutation"
local MEMORY_ID = "memory:pzharness:relationship-event-mutation"

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Event Mutation NPC",
        identitySeed = 7070,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 250,
        y = 350,
        z = 0,
        identity = {
            seed = 7070,
            displayName = "PZ Harness Event Mutation NPC",
        },
    })
end

local function buildMutation()
    return {
        eventID = EVENT_ID,
        interactionType = "greeting",
        worldAgeHours = 930,
        familiarityDelta = 6,
        moraleDelta = 5,
        cooldownType = "greeting",
        cooldownUntil = 960,
        saturationType = "greeting",
        saturation = {
            approval = 4,
            respect = 2,
        },
        sourceSystem = "native_harness",
        memory = {
            id = MEMORY_ID,
            type = "native_harness_event_memory",
            aboutKey = TARGET_KEY,
            createdAt = 930,
            lastEvaluatedAt = 930,
            approvalEffect = 42,
            respectEffect = 24,
            moraleEffect = 0,
            strength = 1,
            decayPerDay = 0,
            permanent = true,
            shareable = true,
            knowledgeSource = "experienced",
            sourceKey = SOURCE_KEY,
            tags = {
                native_harness = true,
                event_mutation = true,
            },
        },
        interaction = {
            kind = "native_harness_event",
            source = "native_harness",
            interactionType = "greeting",
            eventID = EVENT_ID,
            memoryID = MEMORY_ID,
            at = 930,
            worldAgeHours = 930,
            applied = true,
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
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 0
            and relationship.baselineRespect == 0
            and relationship.approval == 42
            and relationship.respect == 24
            and relationship.familiarity == 6
            and relationship.state == "friend"
            and relationship.previousState == "unknown"
            and relationship.revision == 1
            and relationship.lastInteractionAt == 930
            and relationship.lastEvaluatedAt == 930
            and relationship.cooldowns.greeting == 960
            and relationship.saturation.greeting.approval == 4
            and relationship.saturation.greeting.respect == 2
            and #relationship.memories == 1
            and memory and memory.id == MEMORY_ID
            and memory.type == "native_harness_event_memory"
            and memory.aboutKey == TARGET_KEY
            and memory.createdAt == 930
            and memory.lastEvaluatedAt == 930
            and memory.approvalEffect == 42
            and memory.respectEffect == 24
            and memory.strength == 1
            and memory.decayPerDay == 0
            and memory.permanent == true
            and memory.shareable == true
            and memory.knowledgeSource == "experienced"
            and memory.sourceKey == SOURCE_KEY
            and memory.tags.native_harness == true
            and memory.tags.event_mutation == true
            and #relationship.interactionJournal == 1
            and relationship.interactionRevision == 1
            and interaction and interaction.eventID == EVENT_ID
            and interaction.memoryID == MEMORY_ID
            and interaction.interactionType == "greeting"
            and interaction.worldAgeHours == 930
            and interaction.applied == true,
        message
    )
end

PZHarnessNativeTest = function()
    local registry = PNC and PNC.Registry or nil
    local types = PNC and PNC.Types or nil
    local entityRef = PNC and PNC.EntityRef or nil
    local relationships = PNC and PNC.Relationships or nil
    PZHarness.assertTrue(
        registry and registry.AddRecord and registry.Get
            and registry.GetStorageDirectory,
        "native NPC registry event-mutation API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC event-mutation record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY
            and entityRef.ForNPC(NPC_ID) == SOURCE_KEY,
        "native relationship event-mutation entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get
            and relationships.ApplyEventMutation,
        "native relationship event-mutation API was not available"
    )
    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )

    local recordOK, record = pcall(buildRecord, types)
    PZHarness.assertTrue(
        recordOK and type(record) == "table" and record.id == NPC_ID
            and record.social and record.social.relationships,
        "native synthetic NPC event-mutation record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC event-mutation record was not registered"
    )

    local applied, appliedReason, result = relationships.ApplyEventMutation(
        NPC_ID,
        TARGET_KEY,
        buildMutation()
    )
    PZHarness.assertTrue(
        applied == true and appliedReason == "applied"
            and result and result.relationship
            and result.morale == 5
            and result.memoryID == MEMORY_ID
            and result.eventID == EVENT_ID
            and result.memoryType == "native_harness_event_memory"
            and result.interactionType == "greeting",
        "native relationship event mutation failed: "
            .. tostring(appliedReason)
    )
    assertRelationship(
        result and result.relationship,
        "native relationship event mutation was not normalized"
    )

    local duplicate, duplicateReason = relationships.ApplyEventMutation(
        NPC_ID,
        TARGET_KEY,
        buildMutation()
    )
    PZHarness.assertTrue(
        duplicate == false and duplicateReason == "duplicate_event",
        "native relationship event mutation did not reject duplicate events"
    )
    local stored = relationships.Get(NPC_ID, TARGET_KEY)
    assertRelationship(
        stored,
        "native relationship event mutation duplicate changed authoritative state"
    )
    PZHarness.assertTrue(
        record.social.recentEventIDs
            and #record.social.recentEventIDs == 1
            and record.social.recentEventIDs[1] == EVENT_ID
            and record.social.morale == 5
            and registry.DirtyByID
            and registry.DirtyByID[NPC_ID] == true,
        "native event mutation did not retain recent-event or dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_event_mutation_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native event-mutation commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save event-mutation NPC state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native event-mutation NPC record remained dirty after commit"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1,
        "native event-mutation directory pointer was not committed"
    )
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    local rawMemory = rawRelationship and rawRelationship.memories
        and rawRelationship.memories[1]
    local rawInteraction = rawRelationship
        and rawRelationship.interactionJournal
        and rawRelationship.interactionJournal[1]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.id == NPC_ID
            and raw.identity and raw.identity.seed == 7070
            and raw.social and raw.social.morale == 5
            and raw.social.recentEventIDs
            and #raw.social.recentEventIDs == 1
            and raw.social.recentEventIDs[1] == EVENT_ID
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 42
            and rawRelationship.respect == 24
            and rawRelationship.familiarity == 6
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 1
            and rawRelationship.lastInteractionAt == 930
            and rawRelationship.lastEvaluatedAt == 930
            and rawRelationship.cooldowns.greeting == 960
            and rawRelationship.saturation.greeting.approval == 4
            and rawRelationship.saturation.greeting.respect == 2
            and type(rawMemory) == "table"
            and rawMemory.id == MEMORY_ID
            and rawMemory.aboutKey == TARGET_KEY
            and rawMemory.sourceKey == SOURCE_KEY
            and rawMemory.permanent == true
            and rawMemory.tags.native_harness == true
            and rawMemory.tags.event_mutation == true
            and type(rawInteraction) == "table"
            and rawInteraction.eventID == EVENT_ID
            and rawInteraction.memoryID == MEMORY_ID
            and rawInteraction.interactionType == "greeting"
            and rawInteraction.applied == true,
        "native event-mutation ModData did not contain the committed state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native event-mutation OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print(
                "PZ_HARNESS_RELATIONSHIP_EVENT_MUTATION_WRITE_ON_SAVE:"
                    .. NPC_ID
            )
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native event-mutation GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native event-mutation GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native event-mutation GameWindow.save did not trigger OnSave"
        )
    end
end
