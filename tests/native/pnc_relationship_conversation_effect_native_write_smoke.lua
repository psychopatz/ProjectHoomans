-- Target-owned native relationship restart fixture, phase one.
-- Exercise one bounded conversation effect through the relationship wrapper.

local NPC_ID = "npc_pzharness_relationship_conversation_effect_restart"
local TARGET_ID = "npc_pzharness_relationship_conversation_effect_target"
local TARGET_KEY = "npc:" .. TARGET_ID
local EVENT_ID =
    "conversation:pzharness_block:pzharness_choice:pzharness_outcome:940000"

local function buildEffect()
    return {
        memoryType = "native_harness_conversation_memory",
        interactionType = "conversation_choice",
        approval = 36,
        respect = 18,
        familiarity = 6,
        morale = 4,
        decayPerDay = 0,
        permanent = true,
        shareable = true,
        tags = {
            native_harness = true,
        },
    }
end

local function buildContext()
    return {
        blockID = "pzharness_block",
        categoryID = "pzharness_category",
        nodeID = "pzharness_node",
        choiceID = "pzharness_choice",
        outcomeID = "pzharness_outcome",
        worldAgeHours = 940,
        cooldownType = "conversation",
        cooldownUntil = 975,
        sourceSystem = "native_harness",
        interactionKind = "choice",
    }
end

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Conversation Effect NPC",
        identitySeed = 7171,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 260,
        y = 360,
        z = 0,
        identity = {
            seed = 7171,
            displayName = "PZ Harness Conversation Effect NPC",
        },
    })
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
            and relationship.approval == 36
            and relationship.respect == 18
            and relationship.familiarity == 6
            and relationship.state == "friend"
            and relationship.previousState == "unknown"
            and relationship.revision == 1
            and relationship.lastInteractionAt == 940
            and relationship.lastEvaluatedAt == 940
            and relationship.cooldowns.conversation == 975
            and #relationship.memories == 1
            and memory and memory.id == EVENT_ID
            and memory.type == "native_harness_conversation_memory"
            and memory.aboutKey == TARGET_KEY
            and memory.createdAt == 940
            and memory.lastEvaluatedAt == 940
            and memory.approvalEffect == 36
            and memory.respectEffect == 18
            and memory.strength == 1
            and memory.decayPerDay == 0
            and memory.permanent == true
            and memory.shareable == true
            and memory.knowledgeSource == "experienced"
            and memory.sourceKey == TARGET_KEY
            and memory.tags.native_harness == true
            and memory.tags.conversation == true
            and #relationship.interactionJournal == 1
            and relationship.interactionRevision == 1
            and interaction and interaction.eventID == EVENT_ID
            and interaction.memoryID == EVENT_ID
            and interaction.kind == "choice"
            and interaction.source == "native_harness"
            and interaction.interactionType == "conversation_choice"
            and interaction.blockID == "pzharness_block"
            and interaction.categoryID == "pzharness_category"
            and interaction.nodeID == "pzharness_node"
            and interaction.choiceID == "pzharness_choice"
            and interaction.outcomeID == "pzharness_outcome"
            and interaction.worldAgeHours == 940
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
        "native NPC registry conversation-effect API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC conversation-effect record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY,
        "native conversation-effect entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get
            and relationships.ApplyConversationEffect,
        "native relationship conversation-effect API was not available"
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
        "native synthetic NPC conversation-effect record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC conversation-effect record was not registered"
    )

    local applied, appliedReason, result =
        relationships.ApplyConversationEffect(
            NPC_ID,
            TARGET_KEY,
            buildEffect(),
            buildContext()
        )
    PZHarness.assertTrue(
        applied == true and appliedReason == "applied"
            and result and result.relationship
            and result.morale == 4
            and result.memoryID == EVENT_ID
            and result.eventID == EVENT_ID
            and result.memoryType == "native_harness_conversation_memory"
            and result.interactionType == "conversation_choice",
        "native relationship conversation effect failed: "
            .. tostring(appliedReason)
    )
    assertRelationship(
        result and result.relationship,
        "native relationship conversation effect was not normalized"
    )

    local duplicate, duplicateReason =
        relationships.ApplyConversationEffect(
            NPC_ID,
            TARGET_KEY,
            buildEffect(),
            buildContext()
        )
    PZHarness.assertTrue(
        duplicate == false and duplicateReason == "duplicate_event",
        "native relationship conversation effect did not reject duplicate events"
    )
    local stored = relationships.Get(NPC_ID, TARGET_KEY)
    assertRelationship(
        stored,
        "native conversation-effect duplicate changed authoritative state"
    )
    PZHarness.assertTrue(
        record.social.recentEventIDs
            and #record.social.recentEventIDs == 1
            and record.social.recentEventIDs[1] == EVENT_ID
            and record.social.morale == 4
            and registry.DirtyByID
            and registry.DirtyByID[NPC_ID] == true,
        "native conversation effect did not retain recent-event or dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_conversation_effect_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native conversation-effect commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save conversation-effect state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native conversation-effect NPC record remained dirty after commit"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1,
        "native conversation-effect directory pointer was not committed"
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
            and raw.identity and raw.identity.seed == 7171
            and raw.social and raw.social.morale == 4
            and raw.social.recentEventIDs
            and #raw.social.recentEventIDs == 1
            and raw.social.recentEventIDs[1] == EVENT_ID
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 36
            and rawRelationship.respect == 18
            and rawRelationship.familiarity == 6
            and rawRelationship.state == "friend"
            and rawRelationship.revision == 1
            and rawRelationship.lastInteractionAt == 940
            and rawRelationship.lastEvaluatedAt == 940
            and rawRelationship.cooldowns.conversation == 975
            and type(rawMemory) == "table"
            and rawMemory.id == EVENT_ID
            and rawMemory.aboutKey == TARGET_KEY
            and rawMemory.sourceKey == TARGET_KEY
            and rawMemory.permanent == true
            and rawMemory.tags.native_harness == true
            and rawMemory.tags.conversation == true
            and type(rawInteraction) == "table"
            and rawInteraction.eventID == EVENT_ID
            and rawInteraction.memoryID == EVENT_ID
            and rawInteraction.kind == "choice"
            and rawInteraction.source == "native_harness"
            and rawInteraction.interactionType == "conversation_choice"
            and rawInteraction.blockID == "pzharness_block"
            and rawInteraction.categoryID == "pzharness_category"
            and rawInteraction.nodeID == "pzharness_node"
            and rawInteraction.choiceID == "pzharness_choice"
            and rawInteraction.outcomeID == "pzharness_outcome"
            and rawInteraction.applied == true,
        "native conversation-effect ModData did not contain the committed state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native conversation-effect OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print(
                "PZ_HARNESS_RELATIONSHIP_CONVERSATION_EFFECT_WRITE_ON_SAVE:"
                    .. NPC_ID
            )
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native conversation-effect GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native conversation-effect GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native conversation-effect GameWindow.save did not trigger OnSave"
        )
    end
end
