-- Target-owned native lumber restart fixture, phase two.
-- Read bounded zone/tree/job state after a fresh JVM loads ModData.

local ZONE_ID = "lumber_zone_pzharness_native_restart"
local TREE_KEY = "tree_pzharness_native_restart"
local NPC_ID = "npc_pzharness_lumber_restart"
local JOB_ID = "lumber_job_pzharness_native_restart"

PZHarnessNativeTest = function()
    local service = PNC and PNC.LumberService or nil
    PZHarness.assertTrue(
        service and service.GetZone and service.GetTree
            and service.GetJob and service.Loaded == true,
        "native LumberService was not loaded after the JVM restart"
    )
    PZHarness.assertEqual(
        service.MODDATA_KEY,
        "PNC_LumberWorld_V1",
        "native LumberService ModData key was not available after restart"
    )

    local zone = service.GetZone(ZONE_ID)
    local tree = service.GetTree(TREE_KEY)
    local job = service.GetJob(NPC_ID)
    PZHarness.assertTrue(
        type(zone) == "table" and type(tree) == "table"
            and type(job) == "table",
        "native LumberService did not reload bounded zone/tree/job state"
    )
    PZHarness.assertTrue(
        zone.ownerType == "npc"
            and zone.ownerId == NPC_ID
            and zone.workers[NPC_ID] == true
            and zone.treeIndex[TREE_KEY] == true
            and zone.scan.complete == true,
        "native lumber zone runtime indexes were not rebuilt"
    )
    PZHarness.assertTrue(
        tree.key == TREE_KEY
            and tree.status == "DISCOVERED"
            and tree.remainingWork == 4
            and tree.maxWork == 10
            and tree.logYield == 2,
        "native lumber tree state was not normalized after restart"
    )
    PZHarness.assertTrue(
        job.id == JOB_ID
            and job.npcId == NPC_ID
            and job.zoneId == ZONE_ID
            and job.targetKey == TREE_KEY
            and job.active == true
            and job.leaseId == nil,
        "native lumber job state or transient lease was not recovered"
    )
    PZHarness.assertTrue(
        service.Dirty == false,
        "native LumberService was unexpectedly dirty after reload"
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
            and rawTree.status == "DISCOVERED"
            and rawJob.leaseId == nil,
        "native lumber ModData was not reloaded with recovered state"
    )
end
