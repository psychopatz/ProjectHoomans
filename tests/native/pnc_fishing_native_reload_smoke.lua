-- Target-owned native fishing restart fixture, phase two.
-- Read bounded fishing zone/job state after a fresh JVM loads ModData.

local ZONE_ID = "fishing_zone_pzharness_native_restart"
local NPC_ID = "npc_pzharness_fishing_restart"
local JOB_ID = "fishing_job_pzharness_native_restart"
local MARKER = "fishing-restart"

PZHarnessNativeTest = function()
    local service = PNC and PNC.FishingService or nil
    PZHarness.assertTrue(
        service and service.GetZone and service.GetJob
            and service.Loaded == true and service.Data,
        "native FishingService was not loaded after the JVM restart"
    )

    local zone = service.GetZone(ZONE_ID)
    local job = service.GetJob(NPC_ID)
    PZHarness.assertTrue(
        type(zone) == "table",
        "native FishingService did not reload the written zone"
    )
    PZHarness.assertEqual(
        zone and zone.id,
        ZONE_ID,
        "native fishing zone identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        zone and zone.revision,
        4,
        "native fishing zone revision did not survive the JVM restart"
    )
    PZHarness.assertTrue(
        zone and zone.enabled == true
            and type(zone.fishingSpots) == "table"
            and #zone.fishingSpots == 1
            and zone.fishingSpots[1].id == "100:100:0",
        "native fishing zone spots did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        zone and zone.loot and zone.loot[1],
        "Base.FishFillet",
        "native fishing zone loot did not survive the JVM restart"
    )

    PZHarness.assertTrue(
        type(job) == "table",
        "native FishingService did not reload the written job"
    )
    PZHarness.assertEqual(
        job and job.id,
        JOB_ID,
        "native fishing job identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        job and job.nativeMarker,
        MARKER,
        "native fishing job marker did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        job and job.leaseId,
        nil,
        "native fishing runtime lease was not cleared on reload"
    )
    PZHarness.assertEqual(
        job and job.spotClaimNeedsRebind,
        true,
        "native fishing job did not request a fresh spot claim"
    )
    PZHarness.assertEqual(
        job and job.previousOrderCaptured,
        nil,
        "native fishing runtime previous order was not cleared"
    )

    local raw = ModData.get(service.MODDATA_KEY)
    local rawZone = raw and raw.zones and raw.zones[ZONE_ID]
    local rawJob = raw and raw.jobs and raw.jobs[NPC_ID]
    PZHarness.assertTrue(
        type(rawZone) == "table"
            and rawZone.id == ZONE_ID
            and type(rawJob) == "table"
            and rawJob.id == JOB_ID,
        "native fishing ModData was not reloaded"
    )
end
