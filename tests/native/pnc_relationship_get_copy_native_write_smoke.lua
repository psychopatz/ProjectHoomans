-- Target-owned native relationship restart fixture, phase one.
-- Exercise immutable returned-copy behavior of the relationship read API.

local NPC_ID = "npc_pzharness_relationship_get_copy_restart"
local TARGET_ID = "npc_pzharness_relationship_get_copy_target"
local TARGET_KEY = "npc:" .. TARGET_ID

local function buildRecord(types)
    return types.NewRecord({
        id = NPC_ID,
        displayName = "PZ Harness Get Copy NPC",
        identitySeed = 7373,
        archetypeID = "General",
        tacticalClass = "neutral",
        x = 280,
        y = 380,
        z = 0,
        identity = {
            seed = 7373,
            displayName = "PZ Harness Get Copy NPC",
        },
    })
end

local function mutateReturnedCopy(relationship)
    relationship.baselineApproval = 99
    relationship.approval = -99
    relationship.respect = 99
    relationship.familiarity = 0
    relationship.targetID = "mutated_target"
    relationship.state = "enemy"
    relationship.previousState = "rival"
    relationship.memories[1] = {
        id = "memory:pzharness:mutated-copy",
    }
    relationship.saturation.mutated = {
        approval = 99,
        respect = 99,
    }
    relationship.cooldowns.mutated = 999
    relationship.interactionJournal[1] = {
        eventID = "interaction:pzharness:mutated-copy",
    }
end

local function assertCanonical(relationship, message)
    PZHarness.assertTrue(
        relationship
            and relationship.targetKind == "npc"
            and relationship.targetID == TARGET_ID
            and relationship.baselineApproval == 30
            and relationship.baselineRespect == 12
            and relationship.approval == 30
            and relationship.respect == 12
            and relationship.familiarity == 8
            and relationship.state == "neutral"
            and relationship.revision == 1
            and relationship.lastEvaluatedAt == 900
            and #relationship.memories == 0
            and #relationship.interactionJournal == 0
            and relationship.saturation
            and relationship.saturation.mutated == nil
            and relationship.cooldowns
            and relationship.cooldowns.mutated == nil,
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
        "native NPC registry Get-copy API was not available"
    )
    PZHarness.assertTrue(
        types and types.NewRecord,
        "native NPC Get-copy record constructor was not available"
    )
    PZHarness.assertTrue(
        entityRef and entityRef.ForNPC and entityRef.IsValid
            and entityRef.ForNPC(TARGET_ID) == TARGET_KEY,
        "native Get-copy entity-key API was not available"
    )
    PZHarness.assertTrue(
        relationships and relationships.Get
            and relationships.SetInitialBaseline,
        "native relationship Get-copy API was not available"
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
        "native synthetic NPC Get-copy record was not constructed"
    )
    local addOK, added = pcall(registry.AddRecord, record)
    PZHarness.assertTrue(
        addOK and added,
        "native synthetic NPC Get-copy record was not registered"
    )

    local baseline, baselineReason = relationships.SetInitialBaseline(
        NPC_ID,
        TARGET_KEY,
        {
            approval = 30,
            respect = 12,
            familiarity = 8,
        },
        900
    )
    PZHarness.assertTrue(
        baseline and baselineReason == nil and baseline.state == "neutral",
        "native Get-copy baseline failed: " .. tostring(baselineReason)
    )

    local returned = relationships.Get(NPC_ID, TARGET_KEY)
    PZHarness.assertTrue(
        returned
            and returned ~= record.social.relationships[TARGET_KEY]
            and returned.approval == 30
            and returned.respect == 12
            and returned.familiarity == 8,
        "native relationship Get did not return a canonical copy"
    )
    mutateReturnedCopy(returned)
    local reread = relationships.Get(NPC_ID, TARGET_KEY)
    assertCanonical(
        reread,
        "native relationship Get returned copy mutated authoritative state"
    )
    PZHarness.assertTrue(
        record.social.relationships[TARGET_KEY].approval == 30
            and record.social.relationships[TARGET_KEY].state == "neutral"
            and #record.social.relationships[TARGET_KEY].memories == 0
            and registry.DirtyByID
            and registry.DirtyByID[NPC_ID] == true,
        "native Get-copy mutation changed the authoritative relationship"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_relationship_get_copy_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native Get-copy commit failed: "
            .. tostring(commitReason or committed)
    )
    local npcResult = commitDetails
        and commitDetails.results
        and commitDetails.results.npcs
    PZHarness.assertTrue(
        npcResult and npcResult.changed == true,
        "native persistence coordinator did not save Get-copy state"
    )
    PZHarness.assertTrue(
        registry.DirtyByID[NPC_ID] == nil,
        "native Get-copy NPC record remained dirty after commit"
    )

    local directory = registry.GetStorageDirectory()
    local pointer = directory and directory.records
        and directory.records[NPC_ID]
    local raw = pointer and ModData.get(pointer.storageKey) or nil
    local rawRelationship = raw and raw.social and raw.social.relationships
        and raw.social.relationships[TARGET_KEY]
    PZHarness.assertTrue(
        type(pointer) == "table"
            and type(pointer.storageKey) == "string"
            and pointer.recordRevision == 1
            and type(raw) == "table"
            and raw.id == NPC_ID
            and raw.identity and raw.identity.seed == 7373
            and type(rawRelationship) == "table"
            and rawRelationship.approval == 30
            and rawRelationship.respect == 12
            and rawRelationship.familiarity == 8
            and rawRelationship.state == "neutral"
            and rawRelationship.revision == 1
            and rawRelationship.lastEvaluatedAt == 900
            and #rawRelationship.memories == 0
            and #rawRelationship.interactionJournal == 0,
        "native Get-copy ModData did not contain canonical state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native Get-copy OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print(
                "PZ_HARNESS_RELATIONSHIP_GET_COPY_WRITE_ON_SAVE:"
                    .. NPC_ID
            )
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native Get-copy GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native Get-copy GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native Get-copy GameWindow.save did not trigger OnSave"
        )
    end
end
