local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })
local loadSource = T.load

local function makeZombie(opts)
    opts = opts or {}
    local zx = tonumber(opts.x) or 0
    local zy = tonumber(opts.y) or 0
    local zz = tonumber(opts.z) or 0
    local md = opts.modData or {}
    local target = opts.target
    local attackedBy = opts.attackedBy
    local banditVar = opts.bandit == true
    local pfb = {
        cancel = function() end,
        reset = function() end,
        setTarget = function() end,
        clearTarget = function() end,
        pathToLocationF = function() end,
    }
    return {
        getX = function() return zx end,
        getY = function() return zy end,
        getZ = function() return zz end,
        setX = function(_, v) zx = v end,
        setY = function(_, v) zy = v end,
        isDead = function() return opts.dead == true end,
        isAlive = function() return opts.dead ~= true end,
        getSquare = function()
            return { isSomethingTo = function() return false end }
        end,
        getOnlineID = function() return opts.onlineID or -1 end,
        getPersistentOutfitID = function() return opts.outfitID or 1 end,
        getModData = function() return md end,
        getVariableBoolean = function(_, k)
            return k == "Bandit" and banditVar
        end,
        setVariable = function() end,
        getTarget = function() return target end,
        setTarget = function(_, v) target = v end,
        getAttackedBy = function() return attackedBy end,
        setAttackedBy = function(_, v) attackedBy = v end,
        clearAggroList = function() end,
        setTargetSeenTime = function() end,
        getActionStateName = function() return "" end,
        getPathFindBehavior2 = function() return pfb end,
    }
end

-- =========================================================================
-- Test 1 & Test 2: Zero extra zombie scans + 3-tier WorldCensus cadence
-- =========================================================================
do
    local now = 1000
    local nextId = 0
    local getZombieListCalls = 0
    local managedEnforced = 0
    local managedZombie = makeZombie({ x = 5, y = 5, modData = { PNC_NPC = true } })
    local banditZombie = makeZombie({ x = 8, y = 5, modData = { Bandit = true } })
    local ordinaryZombies = {}
    for i = 1, 20 do
        ordinaryZombies[i] = makeZombie({ x = 10 + i, y = 5 })
    end
    local cellList = { managedZombie, banditZombie }
    for i = 1, #ordinaryZombies do
        cellList[#cellList + 1] = ordinaryZombies[i]
    end

    Events = {}
    isServer = function() return true end
    isClient = function() return false end
    getCell = function()
        return {
            getZombieList = function()
                getZombieListCalls = getZombieListCalls + 1
                return {
                    size = function() return #cellList end,
                    get = function(_, idx) return cellList[idx + 1] end,
                }
            end,
        }
    end

    PNC = {
        Const = {
            PRESENCE_LIVE = "live",
            PRESENCE_CORPSE = "corpse",
            WORLD_CENSUS_REFRESH_MS = 100,
            WORLD_CENSUS_CALM_REFRESH_MS = 250,
            WORLD_CENSUS_IDLE_REFRESH_MS = 1000,
            BODY_SHELL_MAINTENANCE_MS = 1000,
            BODY_SHELL_STARTUP_PASSES = 3,
            BODY_SHELL_STARTUP_SETTLE_MS = 1500,
            BODY_SHELL_STARTUP_MAX_WAIT_MS = 10000,
        },
        Core = {
            Now = function() return now end,
            IsAuthority = function() return true end,
            GenerateID = function(prefix)
                nextId = nextId + 1
                return tostring(prefix) .. "_" .. tostring(nextId)
            end,
            IsManagedNPCBody = function(z)
                return z == managedZombie
            end,
        },
        Registry = {
            Data = {},
            LiveByID = {},
            EnsureLoaded = function() end,
            ForEach = function() end,
        },
        LiveBodyControl = {
            EnforceManagedSafety = function(z)
                if z == managedZombie then
                    managedEnforced = managedEnforced + 1
                    return true
                end
                return false
            end,
        },
        BodyLifecycle = {
            Internal = {
                registry = function() return PNC.Registry end,
                IsProtectedBody = function() return false end,
                GetLiveShellIdentity = function() return nil, false, false end,
                IsNakedStartupShell = function() return false end,
            },
            StartupCleanup = {
                begun = true,
                active = false,
                complete = true,
                nextMaintenanceAt = 0,
            },
            HuskLedgerCount = function() return 0 end,
        },
    }

    loadSource("ProjectHoomans", "shared", "PNC/Core/World/PNC_WorldCensus.lua")
    loadSource(
        "ProjectHoomans",
        "shared",
        "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Access.lua"
    )
    loadSource(
        "ProjectHoomans",
        "shared",
        "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Targeting.lua"
    )
    PNC.Registry.GetLiveZombie = function() return managedZombie end
    PNC.Registry.GetByPopulationID = function() return nil end
    local originalStubs = PNC.BodyLifecycle.Internal
    originalStubs.registry = function() return PNC.Registry end
    originalStubs.IsProtectedBody = function(z) return z == managedZombie end
    originalStubs.GetLiveShellIdentity = function() return nil, false, false end
    originalStubs.IsNakedStartupShell = function() return false end
    originalStubs.clearBodyCombat = function() end
    originalStubs.removeZombie = function() end
    loadSource(
        "ProjectHoomans",
        "shared",
        "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup.lua"
    )
    PNC.BodyLifecycle.StartupCleanup = {
        begun = true,
        active = false,
        complete = true,
        nextMaintenanceAt = 0,
        lastStats = {},
    }
    PNC.BodyLifecycle.HuskLedgerCount = function() return 0 end
    loadSource(
        "ProjectHoomans",
        "shared",
        "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Events.lua"
    )

    -- 1. Single census refresh executes 1 cell:getZombieList() scan.
    T.equal(PNC.WorldCensus.Refresh(now, false), true, "initial census refresh")
    T.equal(getZombieListCalls, 1, "initial census performed 1 engine scan")

    -- Consumers use the shared census without calling getCell():getZombieList().
    local targets = PNC.Compatibility.Bandits.Targeting.EnumerateTargets({
        source = { x = 8, y = 5 },
        radius = 20,
    })
    T.equal(#targets, 1, "Bandits targeting discovered the loaded bandit via census")
    T.equal(getZombieListCalls, 1, "Bandits EnumerateTargets added 0 extra zombie scans")

    local repaired = PNC.LiveBodyControl.ScanLoadedManagedBodies("test_scan")
    T.equal(repaired, 1, "LiveBodyControl scanned managed body via census")
    T.equal(managedEnforced, 1, "managed safety invoked once via census")
    T.equal(getZombieListCalls, 1, "ScanLoadedManagedBodies added 0 extra zombie scans")

    -- Real post-startup maintenance runs SweepPersistedLiveShells -> BuildStartupBodyBatch
    -- via shared WorldCensus with 0 extra getZombieList() calls.
    local maintManaged = PNC.BodyLifecycle.PumpStartupBodyCleanup(now, false)
    T.truthy(maintManaged and maintManaged.available == true,
        "post-startup maintenance completed using shared census")
    T.equal(getZombieListCalls, 1,
        "post-startup SweepPersistedLiveShells added 0 extra zombie scans")

    -- When zero managed/lifecycle candidates exist, maintenance skips the batch cleanly.
    cellList = { banditZombie }
    for i = 1, #ordinaryZombies do cellList[#cellList + 1] = ordinaryZombies[i] end
    T.equal(PNC.WorldCensus.Refresh(now, true), true, "refresh without managed candidates")
    T.equal(getZombieListCalls, 2, "forced census executed 1 scan")
    PNC.BodyLifecycle.StartupCleanup.nextMaintenanceAt = 0
    local maint = PNC.BodyLifecycle.PumpStartupBodyCleanup(now, false)
    T.equal(maint.skipped, true, "post-startup maintenance skips cleanly when empty/idle")
    T.equal(getZombieListCalls, 2, "skipped maintenance added 0 extra zombie scans")

    -- 2. Zero-live idle interval = 1000ms.
    now = 1500
    T.equal(PNC.WorldCensus.Refresh(now, false), false,
        "zero-live census holds idle throttle at +500ms")
    T.equal(getZombieListCalls, 2, "zero-live census did not rescan at +500ms")
    now = 2000
    T.equal(PNC.WorldCensus.Refresh(now, false), true,
        "zero-live census refreshes at 1000ms")
    T.equal(getZombieListCalls, 3, "zero-live census scan count after 1000ms")

    -- 3. Calm live body tier = 250ms.
    local npcRec = { id = "npc_1", runtime = {} }
    PNC.Registry.Data["npc_1"] = npcRec
    PNC.Registry.LiveByID["npc_1"] = managedZombie
    now = 2100
    T.equal(PNC.WorldCensus.Refresh(now, false), false,
        "calm live body holds 250ms throttle at +100ms")
    now = 2250
    T.equal(PNC.WorldCensus.Refresh(now, false), true,
        "calm live body refreshes at +250ms")
    T.equal(getZombieListCalls, 4, "calm live body census scan count")

    -- 4. Combat / MarkUrgent drops interval to fast 100ms + urgent wake invalidates throttle.
    npcRec.runtime.attackAction = { active = true }
    now = 2350
    T.equal(PNC.WorldCensus.Refresh(now, false), true,
        "combat state wakes census at 100ms")
    T.equal(getZombieListCalls, 5, "combat census scan count")
    npcRec.runtime.attackAction = nil

    now = 2375
    PNC.WorldCensus.MarkUrgent(now, 1500, true)
    T.equal(PNC.WorldCensus.Refresh(now, false), true,
        "MarkUrgent invalidates throttle immediately")
    T.equal(getZombieListCalls, 6, "urgent census scan count")
end

-- =========================================================================
-- Test 3: ZombieAggro deduplication, per-entry cadence & urgent wake
-- =========================================================================
do
    local now = 1000
    local isServerOrig = isServer
    isServer = function() return false end

    local npc1 = makeZombie({ x = 0, y = 0, modData = { PNC_NPC = true } })
    local npc2 = makeZombie({ x = 1, y = 0, modData = { PNC_NPC = true } })
    local npc3 = makeZombie({ x = 2, y = 0, modData = { PNC_NPC = true } })
    local liveByID = { n1 = npc1, n2 = npc2, n3 = npc3 }
    local records = {
        n1 = { id = "n1", alive = true, x = 0, y = 0, z = 0, presenceState = "live", runtime = {} },
        n2 = { id = "n2", alive = true, x = 1, y = 0, z = 0, presenceState = "live", runtime = {} },
        n3 = { id = "n3", alive = true, x = 2, y = 0, z = 0, presenceState = "live", runtime = {} },
    }
    local zombies = {}
    for i = 1, 10 do
        zombies[i] = makeZombie({ x = 8, y = 0, modData = { PNC_ZombieID = "z_" .. i } })
    end
    local foreignChecks = 0
    local spatialQueries = 0

    PNC = {
        Const = {
            PRESENCE_LIVE = "live",
            ZOMBIE_AGGRO_RADIUS = 14,
            ZOMBIE_AGGRO_KEEP_RADIUS = 2.4,
            ZOMBIE_AGGRO_ACTIVE_REFRESH_MS = 250,
            ZOMBIE_AGGRO_ACTIVE_TTL_MS = 1500,
            ZOMBIE_AGGRO_MAX_PER_TICK = 64,
            ZOMBIE_AGGRO_PATH_REQUESTS_PER_TICK = 16,
            ZOMBIE_AGGRO_PURSUIT_INTERVAL_MS = 150,
            ZOMBIE_AGGRO_IDLE_INTERVAL_MS = 250,
            ZOMBIE_NPC_AGGRO_LEASE_MS = 1500,
            ZOMBIE_NPC_PATH_REFRESH_MS = 350,
            ZOMBIE_NPC_PATH_REFRESH_DISTANCE = 0.6,
            ZOMBIE_NPC_PATH_STABLE_RETRY_MS = 1500,
            ZOMBIE_BITE_DISTANCE = 1.2,
            CLIENT_ZOMBIE_AGGRO_CELL_SIZE = 8,
        },
        Core = {
            Now = function() return now end,
            IsAuthority = function() return true end,
            GenerateID = function(p) return tostring(p) .. "_id" end,
            DistanceSq = function(x1, y1, x2, y2)
                local dx, dy = x2 - x1, y2 - y1
                return dx * dx + dy * dy
            end,
            IsManagedNPCBody = function(b)
                return b == npc1 or b == npc2 or b == npc3
            end,
            ForEachPlayer = function() end,
        },
        Sandbox = { CanZombieTargetRecord = function() return true end },
        Stealth = {},
        CombatZombieReaction = {},
        PerformanceScalingDiagnostics = {
            Increment = function() end,
            IsZombieAggroAuditEnabled = function() return false end,
        },
        Registry = {
            Data = records,
            LiveByID = liveByID,
            Get = function(id) return records[id] end,
            GetLiveZombie = function(id) return liveByID[id] end,
            FindRecordByZombie = function(body)
                for id, b in pairs(liveByID) do
                    if b == body then return records[id] end
                end
                return nil
            end,
            ForEachLive = function(cb)
                for id, body in pairs(liveByID) do
                    cb(records[id], body)
                end
            end,
        },
        SpatialIndex = {
            QueryZombies = function()
                spatialQueries = spatialQueries + 1
                return zombies
            end,
        },
        Compatibility = {
            ActorOwnership = {
                IsForeignOwned = function()
                    foreignChecks = foreignChecks + 1
                    return false
                end,
                AcquirePursuitLease = function() return true end,
                ShouldYieldToPursuitOwner = function() return false end,
                CanWriteNativeControl = function() return true end,
                RefreshPursuitLease = function() return true end,
                GetPursuitLease = function() return nil end,
                GetNativeControlOwner = function() return nil end,
            },
        },
    }

    for _, k in ipairs({
        "PNC/Core/Zombies/PNC_ZombieAggro_Update_Core",
        "PNC/Core/Zombies/PNC_ZombieAggro_Update_Multiplayer",
        "PNC/Core/Zombies/PNC_ZombieAggro_Update_Path",
        "PNC/Core/Zombies/PNC_ZombieAggro_Update_Pursuit",
        "PNC/Core/Zombies/PNC_ZombieAggro_Update_Targets",
        "PNC/Core/Zombies/PNC_ZombieAggro_Update_Loop",
    }) do
        package.loaded[k] = nil
    end

    loadSource("ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_State.lua")
    loadSource("ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_ActiveSet.lua")
    PNC.ZombieAggro.UpdateBiteState = PNC.ZombieAggro.UpdateBiteState
        or function() return false end
    PNC.ZombieAggro.ClearBiteEntryForZombie = PNC.ZombieAggro.ClearBiteEntryForZombie
        or function() end
    PNC.ZombieAggro.ClearBiteEntriesForNPCBody =
        PNC.ZombieAggro.ClearBiteEntriesForNPCBody or function() end
    loadSource("ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_Update.lua")

    -- Explicit RefreshActiveSet across 3 NPCs sharing 10 zombies must check
    -- ActorOwnership.IsForeignOwned once per unique zombie (= 10, not 30).
    T.equal(PNC.ZombieAggro.RefreshActiveSet(now, true), true,
        "explicit active set refresh succeeded")
    T.equal(foreignChecks, 10,
        "RefreshActiveSet deduplicated IsForeignOwned across 3 NPCs")

    -- Initial Pump processes all 10 newly active zombies.
    local processed0 = PNC.ZombieAggro.Pump(now)
    T.equal(processed0, 10, "initial aggro pump processed all 10 newly active zombies")

    -- Cooldown holds on next 2 50ms ticks (now=1050, 1100) for initial target zombies
    -- Wait: initial acquireNearestTarget returns cooldown 0 so first pursuit step runs next tick;
    -- after pursuing at dist=8 (mid-range > bite+1.5), entry enters 150ms cooldown.
    now = 1050
    local processed1 = PNC.ZombieAggro.Pump(now)
    T.equal(processed1, 10, "first pursuit step ran immediately after acquisition")

    now = 1100
    local processed2 = PNC.ZombieAggro.Pump(now)
    T.equal(processed2, 0, "mid-range zombies respected 150ms cooldown at +50ms")

    now = 1150
    local processed3 = PNC.ZombieAggro.Pump(now)
    T.equal(processed3, 0, "mid-range zombies respected 150ms cooldown at +100ms")

    -- Urgent wakes during cooldown (+100ms < +150ms):
    -- (a) Zombie 1 moves into close range (dist = 1.5 <= bite 1.2 + 1.5).
    zombies[1]:setX(1.5)
    -- (b) Zombie 2 acquires a native target.
    zombies[2]:setTarget({ __player = true })
    -- (c) Zombie 3 receives OnZombieProvoked.
    PNC.ZombieAggro.OnZombieProvoked(zombies[3], npc1)

    now = 1175
    local urgentProcessed = PNC.ZombieAggro.Pump(now)
    T.equal(urgentProcessed, 3,
        "close-range, native target, and OnZombieProvoked each woke immediately during cooldown")

    -- Zero live bodies fast-exit when active set expires.
    liveByID.n1, liveByID.n2, liveByID.n3 = nil, nil, nil
    PNC.ZombieAggro.ActiveSet.order = {}
    PNC.ZombieAggro.ActiveSet.byID = {}
    local queriesBeforeEmpty = spatialQueries
    now = 5000
    T.equal(PNC.ZombieAggro.Pump(now), 0, "zero-live Pump returned 0 immediately")
    T.equal(spatialQueries, queriesBeforeEmpty, "zero-live Pump skipped Spatial queries")

    isServer = isServerOrig
end

-- =========================================================================
-- Test 4: Presence candidate priority (forceLive > follower > closer bystander)
--         & non-thrashing materializeRetryAt / materializeWakeAt guard
-- =========================================================================
do
    local now = 1000
    local scheduledOrder = {}
    local scheduledTimes = {}
    local player = {
        getX = function() return 0 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    }
    local bystanderClose = {
        id = "bystander_close",
        x = 2,
        y = 0,
        z = 0,
        alive = true,
        presenceState = "abstract",
        runtime = {},
    }
    local followerFar = {
        id = "follower_far",
        x = 20,
        y = 0,
        z = 0,
        alive = true,
        presenceState = "abstract",
        orderSpec = { kind = "follow" },
        runtime = {},
    }
    local forcedFar = {
        id = "forced_far",
        x = 25,
        y = 0,
        z = 0,
        alive = true,
        presenceState = "abstract",
        runtime = { forceLive = true },
    }
    local backedOff = {
        id = "backed_off",
        x = 3,
        y = 0,
        z = 0,
        alive = true,
        presenceState = "abstract",
        runtime = { materializeRetryAt = 2500 },
    }

    PNC = {
        Const = {
            MATERIALIZE_DISTANCE = 28,
            MATERIALIZE_MAX_PER_TICK = 2,
            PRESENCE_INTEREST_REFRESH_MS = 250,
            PRESENCE_ABSTRACT = "abstract",
            ORDER_FOLLOW = "follow",
        },
        Core = {
            Now = function() return now end,
            DistanceSq = function(x1, y1, x2, y2)
                local dx, dy = x2 - x1, y2 - y1
                return dx * dx + dy * dy
            end,
            ForEachPlayer = function(cb) cb(player) end,
        },
        Registry = {},
        SpatialIndex = {
            NPCInitialized = true,
            QueryNPCs = function()
                return { bystanderClose, backedOff, followerFar, forcedFar }
            end,
            Rebuild = function() return true end,
        },
        SimulationClock = { Wake = function() end },
        Scheduler = {
            SLOT_MS = 50,
            Schedule = function(rec, dueAt)
                scheduledOrder[#scheduledOrder + 1] = rec.id
                scheduledTimes[rec.id] = dueAt
            end,
        },
    }

    loadSource("ProjectHoomans", "shared", "PNC/Core/Presence/PNC_Presence.lua")

    local count = PNC.Presence.RefreshMaterializationCandidates(now, true)
    T.equal(count, 4, "all 4 nearby abstract candidates discovered")
    T.equal(#scheduledOrder, 3, "backed-off candidate was NOT rescheduled early")
    T.equal(scheduledOrder[1], "forced_far", "forceLive candidate prioritized 1st")
    T.equal(scheduledOrder[2], "follower_far", "active follower prioritized ahead of closer bystander")
    T.equal(scheduledOrder[3], "bystander_close", "bystander prioritized 3rd")

    -- Re-running interest refresh while materializeWakeAt is still in the future
    -- must not overwrite/re-schedule already-pending candidates.
    now = 1010
    local count2 = PNC.Presence.RefreshMaterializationCandidates(now, true)
    T.equal(count2, 4, "2nd refresh still reports candidates")
    T.equal(#scheduledOrder, 3, "already-pending wakes were not thrashed by repeat refresh")
end

T.finish("pnc_lightweight_runtime_cadence_smoke")
