-- Target-owned native fishing restart fixture, phase one.
-- Exercise bounded fishing zone/job persistence without live workers or world scans.

local ZONE_ID = "fishing_zone_pzharness_native_restart"
local NPC_ID = "npc_pzharness_fishing_restart"
local JOB_ID = "fishing_job_pzharness_native_restart"
local MARKER = "fishing-restart"

local function geometry()
    return { levels = { [0] = { rows = { [100] = { 100, 101 } } } } }
end

PZHarnessNativeTest = function()
    local service = PNC and PNC.FishingService or nil
    PZHarness.assertTrue(
        service and service.GetZone and service.GetJob
            and service.Save and service.Load and service.Internal,
        "native FishingService API was not available"
    )
    PZHarness.assertTrue(
        service.Loaded == true,
        "native FishingService was not loaded before the test"
    )
    PZHarness.assertTrue(
        service.MODDATA_KEY,
        "native FishingService ModData key was not available"
    )

    local data = {
        schemaVersion = 1,
        zones = {},
        jobs = {},
        zoneOrder = { ZONE_ID },
    }
    data.zones[ZONE_ID] = {
        schemaVersion = 1,
        id = ZONE_ID,
        ownerType = "pzharness",
        ownerId = "native",
        geometry = geometry(),
        bounds = {
            minX = 100, minY = 100, maxX = 101, maxY = 100,
            minZ = 0, maxZ = 0,
        },
        enabled = true,
        revision = 4,
        workers = { [NPC_ID] = true },
        fishingSpots = {
            {
                id = "100:100:0",
                standX = 100.5, standY = 100.5, standZ = 0,
                waterX = 101.5, waterY = 100.5, waterZ = 0,
                facing = "W",
            },
        },
        loot = { "Base.FishFillet" },
        catchChance = 0.75,
        skillCatchBonus = 0.10,
        workPointsPerSecond = 2,
        requiredWorkPoints = 30,
        valid = true,
        waterCount = 1,
        landCount = 1,
        unloadedTiles = 0,
    }
    data.jobs[NPC_ID] = {
        id = JOB_ID,
        npcId = NPC_ID,
        zoneId = ZONE_ID,
        active = true,
        leaseId = "lease-before-restart",
        spotId = "100:100:0",
        state = "READY",
        phase = "TOOL_CHECK",
        revision = 2,
        nativeMarker = MARKER,
        previousOrder = { kind = "native_previous_order" },
        previousOrderCaptured = true,
    }
    service.Data = data
    service.Internal.MarkDirty()

    local zone = service.GetZone(ZONE_ID)
    local job = service.GetJob(NPC_ID)
    PZHarness.assertTrue(
        type(zone) == "table" and zone.id == ZONE_ID
            and #zone.fishingSpots == 1,
        "native FishingService did not retain the written zone"
    )
    PZHarness.assertTrue(
        type(job) == "table" and job.id == JOB_ID
            and job.nativeMarker == MARKER,
        "native FishingService did not retain the written job"
    )
    PZHarness.assertTrue(
        service.Dirty == true,
        "native FishingService did not retain its dirty state"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_fishing_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native fishing commit failed: "
            .. tostring(commitReason or committed)
    )
    local fishingResult = commitDetails
        and commitDetails.results
        and commitDetails.results.fishing
    PZHarness.assertTrue(
        fishingResult and fishingResult.changed == true,
        "native persistence coordinator did not save FishingService"
    )
    PZHarness.assertTrue(
        service.Dirty == false,
        "native FishingService remained dirty after commit"
    )

    local raw = ModData.get(service.MODDATA_KEY)
    local rawZone = raw and raw.zones and raw.zones[ZONE_ID]
    local rawJob = raw and raw.jobs and raw.jobs[NPC_ID]
    PZHarness.assertTrue(
        type(rawZone) == "table"
            and rawZone.id == ZONE_ID
            and type(rawZone.fishingSpots) == "table"
            and type(rawJob) == "table"
            and rawJob.nativeMarker == MARKER,
        "native fishing ModData did not contain the committed state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native fishing OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_FISHING_WRITE_ON_SAVE:" .. ZONE_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native fishing GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native fishing GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native fishing GameWindow.save did not trigger OnSave"
        )
    end
end
