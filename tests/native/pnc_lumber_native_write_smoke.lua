-- Target-owned native lumber restart fixture, phase one.
-- Exercise bounded zone/tree/job persistence without live world scanning.

local ZONE_ID = "lumber_zone_pzharness_native_restart"
local TREE_KEY = "tree_pzharness_native_restart"
local NPC_ID = "npc_pzharness_lumber_restart"
local JOB_ID = "lumber_job_pzharness_native_restart"

PZHarnessNativeTest = function()
    local service = PNC and PNC.LumberService or nil
    PZHarness.assertTrue(
        service and service.CreateZone and service.GetZone
            and service.GetTree and service.GetJob
            and service.Load and service.Save,
        "native LumberService API was not available"
    )
    PZHarness.assertTrue(
        service and service.Loaded == true and service.Data,
        "native LumberService was not loaded before the test"
    )
    PZHarness.assertEqual(
        service.MODDATA_KEY,
        "PNC_LumberWorld_V1",
        "native LumberService ModData key was not stable"
    )

    local zone, zoneReason = service.CreateZone({
        id = ZONE_ID,
        ownerType = "npc",
        ownerId = NPC_ID,
        minX = 100,
        minY = 200,
        maxX = 101,
        maxY = 201,
        z = 0,
    })
    PZHarness.assertTrue(
        type(zone) == "table" and zone.id == ZONE_ID,
        "native LumberService did not create the bounded zone: "
            .. tostring(zoneReason)
    )
    PZHarness.assertTrue(
        service.GetZone(ZONE_ID) == zone
            and zone.ownerType == "npc"
            and zone.ownerId == NPC_ID,
        "native lumber zone ownership was not retained"
    )

    local tree = {
        key = TREE_KEY,
        x = 100,
        y = 200,
        z = 0,
        status = "IN_PROGRESS",
        signature = "oak:pzharness",
        maxWork = 10,
        remainingWork = 4,
        logYield = 2,
        revision = 3,
    }
    service.Data.trees[TREE_KEY] = tree
    zone.treeKeys[#zone.treeKeys + 1] = TREE_KEY
    zone.treeIndex[TREE_KEY] = true
    zone.scan.complete = true
    zone.scan.scannedTiles = 4
    zone.workers[NPC_ID] = true
    zone.revision = 3
    service.Data.jobs[NPC_ID] = {
        id = JOB_ID,
        npcId = NPC_ID,
        zoneId = ZONE_ID,
        active = true,
        state = "WORKING",
        phase = "CHOPPING",
        targetKey = TREE_KEY,
        leaseId = "lease-before-restart",
        revision = 5,
    }
    service.Dirty = true

    PZHarness.assertTrue(
        service.GetTree(TREE_KEY) == tree
            and service.GetJob(NPC_ID).id == JOB_ID,
        "native LumberService did not retain bounded tree/job state"
    )
    PZHarness.assertTrue(
        service.Dirty == true,
        "native LumberService did not retain its dirty state"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_lumber_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native lumber commit failed: "
            .. tostring(commitReason or committed)
    )
    local lumberResult = commitDetails
        and commitDetails.results
        and commitDetails.results.lumber
    PZHarness.assertTrue(
        lumberResult and lumberResult.changed == true,
        "native persistence coordinator did not save LumberService"
    )
    PZHarness.assertTrue(
        service.Dirty == false,
        "native LumberService remained dirty after commit"
    )

    local raw = ModData.get(service.MODDATA_KEY)
    local rawZone = raw and raw.zones and raw.zones[ZONE_ID]
    local rawTree = raw and raw.trees and raw.trees[TREE_KEY]
    local rawJob = raw and raw.jobs and raw.jobs[NPC_ID]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.schemaVersion == 1
            and type(rawZone) == "table"
            and type(rawTree) == "table"
            and type(rawJob) == "table"
            and rawTree.status == "IN_PROGRESS"
            and rawJob.leaseId == "lease-before-restart",
        "native lumber ModData did not contain the committed bounded state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native lumber OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_LUMBER_WRITE_ON_SAVE:" .. ZONE_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native lumber GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native lumber GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native lumber GameWindow.save did not trigger OnSave"
        )
    end
end
