local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local BODY_ROOT = SHARED .. "PNC/Core/Presence/PNC_BodyLifecycle/"

local authority = true
-- The orphan rule is only active in worlds that cannot spawn vanilla zombies,
-- so the ledger-path sections below run with it off.
local spawnsDisabled = false
local nowMs = 5000
local foreignOwned = {}
local managed = {}
local censusBodies = {}
local reapedLogs = 0

PNC = {
    Core = {
        Now = function() return nowMs end,
        LogInfo = function(message)
            if string.find(tostring(message), "husk reaped", 1, true) then
                reapedLogs = reapedLogs + 1
            end
        end,
        LogWarn = function() end,
        LogDebug = function() end,
        IsAuthority = function() return authority end,
        IsManagedNPCBody = function(zombie) return managed[zombie] == true end,
    },
    Const = {
        HUSK_LEDGER_MATCH_RADIUS = 2.0,
        HUSK_REAP_MAX_ATTEMPTS = 2,
        HUSK_REAP_PUMP_INTERVAL_MS = 250,
        HUSK_REAP_SWEEP_INTERVAL_MS = 1000,
        HUSK_REAP_PENDING_MAX = 8,
    },
    WorldCensus = {
        GetAll = function() return censusBodies end,
    },
    LiveBodyControl = {
        ApplyHumanizedBodyFlags = function(zombie) zombie.humanized = true end,
        SuppressZombieSounds = function(zombie) zombie.soundsSuppressed = true end,
    },
}

IsoWorld = {
    getZombiesDisabled = function() return spawnsDisabled end,
}

PNC.Compatibility = {
    ActorOwnership = {
        IsForeignOwned = function(zombie)
            return foreignOwned[zombie] == true
        end,
    },
}

getGameTime = function()
    return {
        getWorldAgeHours = function() return 100 end,
    }
end

local function makeHusk(x, y, z, outfitId, blockRemoval)
    local body
    body = {
        current = { x = x, y = y, z = z },
        modData = {},
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        getCurrentSquare = function() return body.current end,
        getPersistentOutfitID = function() return outfitId end,
        getModData = function() return body.modData end,
        removeFromWorld = function(self)
            self.removedFromWorld = true
        end,
        removeFromSquare = function(self)
            self.removedFromSquare = true
            if not blockRemoval then
                self.current = nil
            end
        end,
    }
    return body
end

local function makeRecord(id, x, y, z, hint)
    return {
        id = id,
        x = x,
        y = y,
        z = z,
        liveBodyInstanceID = hint,
        runtime = {},
    }
end

local function armLoss(id, x, y, z, outfitId)
    local record = makeRecord(id, x, y, z, tostring(outfitId))
    return PNC.BodyLifecycle.NoteLostBody(
        record, makeHusk(x, y, z, outfitId), "removal_after_virtualization")
end

T.load(BODY_ROOT .. "PNC_BodyLifecycle_BodyFactory.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_World.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_HuskLedger.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_HuskReaper.lua")

local Lifecycle = PNC.BodyLifecycle
local Reaper = Lifecycle.HuskReaper
local Internal = Lifecycle.Internal

-- 1. A husk handed back by the population manager is matched, queued and then
-- removed on the next pump.
local entry = armLoss("npc_reap", 100.4, 200.6, 0, 42)
T.truthy(entry, "husk loss was not armed")
local husk = makeHusk(100.4, 200.6, 0, 42)
Lifecycle.OnZombieCreate(husk)
T.equal(#Reaper.pending, 1, "matched husk was not queued")
T.equal(Lifecycle.HuskLedgerCount(), 0,
    "queued husk loss stayed armed for a second reap")

T.equal(Lifecycle.PumpHuskReaper(5000, true), 1, "pump reclaimed no husk")
T.equal(husk.removedFromWorld, true, "husk was not removed from the world")
T.equal(husk.removedFromSquare, true, "husk was not removed from its square")
T.equal(husk.current, nil, "husk still occupies a square")
T.equal(husk.humanized, true, "husk was removed without the safety flags")
T.equal(Reaper.reaped, 1, "reap counter")
T.equal(reapedLogs, 1, "reap was not reported")
T.equal(#Reaper.pending, 0, "pending queue was not drained")

-- 2. Our own body: the factory's spawn window must suppress interception even
-- when a ledger entry would otherwise match.
armLoss("npc_own", 300.4, 400.6, 0, 42)
local own = makeHusk(300.4, 400.6, 0, 42)
Internal.SpawnInProgress = true
Lifecycle.OnZombieCreate(own)
Internal.SpawnInProgress = false
T.equal(#Reaper.pending, 0, "spawn window did not suppress interception")
T.equal(Lifecycle.HuskLedgerCount(), 1, "suppressed match consumed the loss")

-- 3. A marked body belongs to the registry/audit lanes, never the reaper.
local marked = makeHusk(300.4, 400.6, 0, 42)
marked.modData.PNC_UUID = "npc_own"
Lifecycle.OnZombieCreate(marked)
T.equal(#Reaper.pending, 0, "marked body was queued for reaping")

-- 4. An unmarked body with no ledger match is untouched.
local ordinary = makeHusk(500, 500, 0, 7)
Lifecycle.OnZombieCreate(ordinary)
T.equal(#Reaper.pending, 0, "ordinary zombie was queued for reaping")

-- 5. Client side / non-authority instances never reap.
authority = false
local foreign = makeHusk(300.4, 400.6, 0, 42)
Lifecycle.OnZombieCreate(foreign)
T.equal(#Reaper.pending, 0, "non-authority instance queued a reap")
authority = true

-- 6. A removal that does not take keeps the loss so a later pass can retry.
local stuck = makeHusk(300.4, 400.6, 0, 42, true)
Lifecycle.OnZombieCreate(stuck)
T.equal(#Reaper.pending, 1, "stuck husk was not queued")
Lifecycle.PumpHuskReaper(6000, true)
T.equal(#Reaper.pending, 0, "failed removal stayed queued forever")
T.equal(Reaper.failed, 1, "failed removal was not counted")
T.equal(Lifecycle.HuskLedgerCount(), 1,
    "failed removal forgot the husk instead of rearming it")
T.equal(Reaper.abandoned, 0, "unexpected early abandon")

-- 7. Attempts are bounded: an unreapable husk stops being retried and is kept
-- only as an expiring diagnostic record, so a refusal cannot loop forever.
local attempts = 0
while attempts < 6 and Reaper.abandoned == 0 do
    attempts = attempts + 1
    local stuckAgain = makeHusk(300.4, 400.6, 0, 42, true)
    Lifecycle.OnZombieCreate(stuckAgain)
    Lifecycle.PumpHuskReaper(7000 + attempts * 1000, true)
end
T.equal(Reaper.abandoned, 1, "unreapable husk was not abandoned")
T.truthy(Reaper.failed >= 2, "persistent removal failure was not counted")
T.equal(Lifecycle.HuskLedgerCount(), 1,
    "abandoned husk was not kept as a bounded record")
T.falsy(Lifecycle.FindHuskEntry(makeHusk(300.4, 400.6, 0, 42)),
    "abandoned husk was still matchable")

-- 8. The loaded sweep catches husks whose create event was missed. It must not
-- touch the abandoned record either.
local sweepEntry = armLoss("npc_sweep", 800.4, 900.6, 0, 42)
T.truthy(sweepEntry, "sweep loss was not armed")
local sweepHusk = makeHusk(800.4, 900.6, 0, 42)
censusBodies = { sweepHusk }
Reaper.lastSweepAt = 0
Reaper.lastPumpAt = 0
T.truthy(Lifecycle.PumpHuskReaper(20000, true) >= 1,
    "loaded sweep did not reclaim the husk")
T.equal(sweepHusk.removedFromWorld, true, "swept husk was not removed")

-- 9. Orphan rule. In a world that cannot spawn vanilla zombies, ANY unmarked
-- body is an orphaned PNC shell: the reclaim must not depend on a learned
-- outfit id (a Lua-created body cannot set one there) or on a recorded loss.
T.truthy(Lifecycle.NoteShellOutfitID(42), "shell outfit id was not learned")
T.truthy(Lifecycle.IsShellOutfitID(42), "learned shell outfit not recognized")
T.falsy(Lifecycle.IsShellOutfitID(7), "unrelated outfit recognized as a shell")

-- The spawn gate is cached for a short window, so advance the clock past it
-- before changing the configuration.
spawnsDisabled = true
nowMs = nowMs + 2000
censusBodies = {}
local orphan = makeHusk(1500.4, 1600.6, 0, 0)
T.truthy(Lifecycle.IsOrphanedShell(orphan),
    "unmarked body was not an orphan in a zombie-disabled world")
Lifecycle.OnZombieCreate(orphan)
T.equal(#Reaper.pending, 1, "orphaned shell was not queued")
Lifecycle.PumpHuskReaper(30000, true)
T.equal(orphan.removedFromWorld, true, "orphaned shell was not reclaimed")
T.equal(Reaper.orphanReaps, 1, "orphan reclaim was not counted")

-- A foreign-owned body (for example a Bandits NPC shell) is never ours.
local bandit = makeHusk(1550.4, 1650.6, 0, 0)
foreignOwned[bandit] = true
T.falsy(Lifecycle.IsOrphanedShell(bandit),
    "foreign-owned body was treated as an orphan")
Lifecycle.OnZombieCreate(bandit)
T.equal(#Reaper.pending, 0, "foreign-owned body was queued")
foreignOwned[bandit] = nil

-- Marked bodies stay owned by the registry/audit lanes.
local markedOrphan = makeHusk(1560.4, 1660.6, 0, 0)
markedOrphan.modData.PNC_UUID = "someone"
Lifecycle.OnZombieCreate(markedOrphan)
T.equal(#Reaper.pending, 0, "marked body was queued as an orphan")

-- Toggling zombie spawning back on disables the rule entirely.
spawnsDisabled = false
nowMs = nowMs + 2000
local vanillaSafe = makeHusk(1700.4, 1800.6, 0, 42)
T.falsy(Lifecycle.IsOrphanedShell(vanillaSafe),
    "orphan rule stayed active in a vanilla-eligible world")
Lifecycle.OnZombieCreate(vanillaSafe)
T.equal(#Reaper.pending, 0,
    "a vanilla-eligible world queued an unmarked zombie")
Lifecycle.PumpHuskReaper(31000, true)
T.falsy(vanillaSafe.removedFromWorld, "vanilla-eligible body was removed")

local report = Lifecycle.DebugHuskReport()
T.contains(report, "shellOutfits=1", "husk report shell outfit count")
T.contains(report, "orphans=", "husk report orphan census")
T.contains(report, "fingerprint=", "husk report fingerprint census")
T.contains(report, "reaped=", "husk report reap count")

local diagnostics = Lifecycle.BuildHuskReaperDiagnostics()
T.truthy(diagnostics.reaped >= 2, "reaper diagnostics reap count")
T.equal(diagnostics.pending, 0, "reaper diagnostics pending count")
T.equal(diagnostics.abandoned, 1, "reaper diagnostics abandon count")

return T.finish("pnc_husk_reaper_smoke")
