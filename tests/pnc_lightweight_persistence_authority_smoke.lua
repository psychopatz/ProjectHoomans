local T = require "tests/support/test"

T.addPackagePaths()

local function makeEnv()
    for name, _ in pairs(package.loaded) do
        if string.sub(name, 1, 4) == "PNC/"
            or string.sub(name, 1, 15) == "PsychopatzCore/"
            or name == "PsychopatzCore"
        then
            package.loaded[name] = nil
        end
    end
    PNC = {}
    PsychopatzCore = {}
    PSYCHOPATZ_PROFILER_MODE = nil

    local stores = {}
    local events = {}
    local nowMs = 10000
    local globalSaveCalls = 0
    local warnings = {}
    local squares = {}

    local function makeList(items)
        return {
            size = function() return #items end,
            get = function(_, i) return items[i + 1] end,
            add = function(_, v) items[#items + 1] = v end,
        }
    end

    local function makeItem(fullType)
        local md = {}
        local cond = 10
        return {
            getFullType = function() return tostring(fullType or "Base.Hammer") end,
            getType = function()
                local dot = string.find(tostring(fullType or ""), ".", 1, true)
                return dot and string.sub(fullType, dot + 1) or tostring(fullType)
            end,
            getModData = function() return md end,
            getCondition = function() return cond end,
            getConditionMax = function() return 10 end,
            setCondition = function(_, v) cond = tonumber(v) or cond end,
            getWeight = function() return 1.0 end,
            getActualWeight = function() return 1.0 end,
            getDisplayName = function() return tostring(fullType) end,
            IsClothing = function() return false end,
            IsWeapon = function() return false end,
            IsInventoryContainer = function() return false end,
            isFavourite = function() return false end,
            setFavorite = function() end,
            getBodyLocation = function() return nil end,
            getAttachmentType = function() return nil end,
            getAmmoType = function() return nil end,
            getCurrentAmmoCount = function() return 0 end,
            getMaxAmmo = function() return 0 end,
            getVisual = function() return nil end,
            setName = function() end,
        }
    end

    local function makeInv()
        local items = {}
        return {
            getItems = function() return makeList(items) end,
            clear = function() items = {} end,
            AddItem = function(_, ft) local it = makeItem(ft); items[#items + 1] = it; return it end,
            Remove = function(_, t)
                for i = #items, 1, -1 do if items[i] == t then table.remove(items, i) end end
            end,
            FindAndReturn = function(_, ft)
                for i = 1, #items do if items[i]:getFullType() == ft then return items[i] end end
                return nil
            end,
        }
    end

    local function getSquare(x, y, z)
        local sx, sy, sz = math.floor(x or 0), math.floor(y or 0), math.floor(z or 0)
        local key = sx .. ":" .. sy .. ":" .. sz
        if not squares[key] then
            squares[key] = {
                getX = function() return sx end,
                getY = function() return sy end,
                getZ = function() return sz end,
                isFree = function() return true end,
                isSolidTrans = function() return false end,
                isSolid = function() return false end,
                HasStairs = function() return false end,
                getObjects = function() return makeList({}) end,
                getMovingObjects = function() return makeList({}) end,
                getDeadBodys = function() return makeList({}) end,
                TreatAsSolidFloor = function() return true end,
            }
        end
        return squares[key]
    end

    local playerModData = {}
    local player = {
        __class = "IsoPlayer",
        getUsername = function() return "TestOwner" end,
        getDisplayName = function() return "TestOwner" end,
        getOnlineID = function() return 1 end,
        getX = function() return 100 end,
        getY = function() return 100 end,
        getZ = function() return 0 end,
        getAccessLevel = function() return "admin" end,
        isDead = function() return false end,
        isSneaking = function() return false end,
        isRunning = function() return false end,
        isSprinting = function() return false end,
        isAiming = function() return false end,
        getModData = function() return playerModData end,
        getCurrentSquare = function() return getSquare(100, 100, 0) end,
        getInventory = function() return makeInv() end,
    }

    local function installGlobals(savedStores)
        stores = savedStores or {}
        events = {}
        Events = setmetatable({}, {
            __index = function(tbl, key)
                local list = {}
                events[key] = list
                tbl[key] = {
                    Add = function(fn) list[#list + 1] = fn end,
                    Remove = function(fn)
                        for i = #list, 1, -1 do if list[i] == fn then table.remove(list, i) end end
                    end,
                }
                return tbl[key]
            end,
        })
        ModData = {
            get = function(k) return stores[k] end,
            getOrCreate = function(k) stores[k] = stores[k] or {}; return stores[k] end,
            remove = function(k) stores[k] = nil end,
            getTableNames = function()
                local out = {}
                for k, _ in pairs(stores) do out[#out + 1] = k end
                table.sort(out)
                return out
            end,
            transmit = function() end,
        }
        GlobalModData = {
            save = function() globalSaveCalls = globalSaveCalls + 1 end,
        }
        SandboxVars = { ProjectHoomans = {} }
        isServer = function() return true end
        isClient = function() return false end
        getTimeInMillis = function() return nowMs end
        getTimestampMs = function() return nowMs end
        getText = function(k) return k end
        ZombRand = function(a, b) if b then return a end return 0 end
        getGameTime = function()
            return {
                getWorldAgeHours = function() return 50 + (nowMs / 3600000) end,
                getServerTimeMills = function() return nowMs end,
                getYear = function() return 1993 end,
                getMonth = function() return 7 end,
                getDay = function() return 9 end,
                getHour = function() return 12 end,
                getMinutes = function() return 0 end,
                getTimeOfDay = function() return 12.0 end,
                getDawn = function() return 6 end,
                getDusk = function() return 20 end,
            }
        end
        getCore = function() return { getOptionFontSize = function() return 1 end } end
        instanceItem = function(ft) return makeItem(ft) end
        InventoryItemFactory = { CreateItem = function(ft) return makeItem(ft) end }
        instanceof = function(o, c) return type(o) == "table" and o.__class == c end
        getCell = function()
            return {
                getZombieList = function() return makeList({}) end,
                getGridSquare = function(_, x, y, z) return getSquare(x, y, z) end,
            }
        end
        getWorld = function() return { getCell = getCell } end
        addZombiesInOutfit = function() return makeList({}) end
        getOnlinePlayers = function() return makeList({ player }) end
        getNumActivePlayers = function() return 1 end
        getSpecificPlayer = function() return nil end
        getPlayer = function() return player end
        sendServerCommand = function() end
        triggerEvent = function() end
        getFileReader = nil
        getFileWriter = nil
    end

    local function resetModuleCache()
        for name, _ in pairs(package.loaded) do
            if string.sub(name, 1, 4) == "PNC/"
                or string.sub(name, 1, 15) == "PsychopatzCore/"
                or name == "PsychopatzCore"
            then
                package.loaded[name] = nil
            end
        end
        PNC = {}
        PsychopatzCore = {}
    end

    return {
        installGlobals = installGlobals,
        resetModuleCache = resetModuleCache,
        now = function() return nowMs end,
        advanceMs = function(dt) nowMs = nowMs + dt end,
        getEvents = function() return events end,
        getStores = function() return stores end,
        getPlayer = function() return player end,
        getGlobalSaveCalls = function() return globalSaveCalls end,
        resetGlobalSaveCalls = function() globalSaveCalls = 0 end,
        recordWarning = function(msg) warnings[#warnings + 1] = tostring(msg) end,
        getWarnings = function() return warnings end,
        clearWarnings = function() warnings = {} end,
    }
end

local function countMap(tbl)
    local c = 0
    for _ in pairs(tbl or {}) do c = c + 1 end
    return c
end

local env = makeEnv()
env.installGlobals(nil)

local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap.Initialize()
require "PsychopatzCore/Runtime/PC_RuntimeRole"
require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local actorReg = Actors.DefaultRegistry

local CORE_APPEARANCE = {
    policySchemaVersion = 1,
    policy = { mode = "generated" },
    resolved = { female = false, skinTexture = "MaleBody01", hairModel = "Short" },
    contract = { source = "core_actor", immutable = true },
}

-- 1. Create clean new-save Core actors with canonical Core appearance envelopes.
for i = 1, 20 do
    local near = i <= 4
    assert(actorReg:Create({
        actorId = "core:l2:" .. tostring(i),
        identitySeed = "l2_seed_" .. tostring(i),
        archetypeID = "core.survivor",
        appearance = CORE_APPEARANCE,
        providerLease = {
            provider = "ProjectHoomans",
            owner = "ProjectHoomans:l2",
            state = "abstract",
        },
        world = { position = { x = near and (105 + i) or (4000 + i * 20), y = near and 100 or 4000, z = 0 } },
        extensions = {
            ["PsychopatzCore.SurvivorWorld"] = { factionID = "fac_l2", role = "member" },
        },
    }))
end

require "PNC/00_PNC_Init"
require "PNC/Composition/PNC_ServerComposition"

local origWarn = PNC.Core.LogWarn
PNC.Core.LogWarn = function(msg)
    env.recordWarning(msg)
    return origWarn(msg)
end

for _, fn in ipairs(env.getEvents().OnInitGlobalModData or {}) do fn() end
for _, fn in ipairs(env.getEvents().OnServerStarted or {}) do fn() end
PNC.Persistence.CoreProvider.SyncAllPromotedCoreActors(PsychopatzCore)

T.equal(countMap(PNC.Registry.DirtyByID), 0, "clean new save must have 0 dirty NPC records")
local nilWarnFound = false
for _, w in ipairs(env.getWarnings()) do
    if string.find(w, "produced no payload", 1, true) then nilWarnFound = true end
end
T.equal(nilWarnFound, false, "clean new save must emit zero legacy nil-payload warnings")
T.equal(env.getGlobalSaveCalls(), 0, "startup must not call GlobalModData.save")

-- 2. Explicit terminal outcome classification (Core-backed & Core-appearance mismatch) with zero retries.
local initialAppearanceSchema = assert(actorReg:Get("core:l2:1").appearance
    and actorReg:Get("core:l2:1").appearance.policySchemaVersion)
local initialPolicyHash = assert(actorReg:Get("core:l2:1").appearance.contract
    and actorReg:Get("core:l2:1").appearance.contract.policyHash)

local coreActorRec = assert(PNC.Persistence.CoreProvider.PromoteCoreActor("core:l2:1", PsychopatzCore))
local serPayload, serOutcome, serReason = PNC.Persistence.SerializeRecord(coreActorRec)
T.equal(serPayload, nil, "Core-backed record must not serialize to legacy payload")
T.equal(serOutcome, "TERMINAL_OR_NOT_APPLICABLE", "Core-backed record outcome must be terminal")
T.equal(serReason, "owned_by_core_extension", "Core-backed terminal reason")

local legacyBadApp = {
    id = "legacy_bad_app",
    name = "Bad App",
    tacticalClass = "neutral",
    persist = true,
    alive = true,
    x = 100,
    y = 100,
    z = 0,
    appearance = CORE_APPEARANCE,
    runtime = {},
}
local badAppPayload, badAppOutcome, badAppReason = PNC.Persistence.SerializeRecord(legacyBadApp)
T.equal(badAppPayload, nil, "Core-appearance record must not down-convert")
T.equal(badAppOutcome, "TERMINAL_OR_NOT_APPLICABLE", "Core-appearance mismatch outcome must be terminal")
T.equal(badAppReason, "core_appearance_authority_mismatch", "Core-appearance mismatch reason")

PNC.Registry.Data["legacy_bad_app"] = legacyBadApp
PNC.Registry.MarkDirty(legacyBadApp, "test_bad_app")
local termBefore = PNC.Registry.PersistenceMetrics.terminal
local flushedBad, summaryBad = PNC.Registry.FlushDirty({ mode = "pump", now = env.now() })
T.equal(flushedBad, 0, "terminal bad-app record must not count as written")
T.equal(summaryBad.terminal, 1, "summary must classify terminal outcome")
T.equal(PNC.Registry.DirtyByID["legacy_bad_app"], nil, "terminal mismatch must clear DirtyByID on attempt 1")
T.equal(PNC.Registry.PersistenceMetrics.terminal, termBefore + 1, "terminal metric incremented")
PNC.Registry.Data["legacy_bad_app"] = nil

-- 3. Retryable failure injection (legacy throw & Core commit conflict): exponential backoff & recovery.
local transientRec = {
    id = "legacy_transient",
    name = "Transient",
    tacticalClass = "neutral",
    persist = true,
    alive = true,
    x = 100,
    y = 100,
    z = 0,
    health = { current = 100, max = 100, state = "normal" },
    runtime = {},
}
PNC.Registry.AddRecord(transientRec)
local flushedInit = PNC.Registry.FlushDirty({ mode = "drain", now = env.now() })
T.equal(flushedInit, 1, "initial legacy record flushed")

local origSerialize = PNC.Persistence.SerializeRecord
local injectLegacyFail = true
PNC.Persistence.SerializeRecord = function(rec)
    if rec and rec.id == "legacy_transient" and injectLegacyFail then
        error("transient_io_failure")
    end
    return origSerialize(rec)
end

PNC.Registry.MarkDirty(transientRec, "test_retry")
local r1, s1 = PNC.Registry.FlushDirty({ mode = "pump", now = env.now() })
T.equal(r1, 0, "failed write not counted as flushed")
T.equal(s1.retryable, 1, "failed write classified RETRYABLE_FAILURE")
T.truthy(PNC.Registry.DirtyByID["legacy_transient"], "retryable failure stays dirty")
local retry1 = PNC.Registry.RetryState["legacy_transient"]
T.truthy(retry1 and retry1.attempts == 1 and retry1.nextRetryAt == env.now() + 1000, "first backoff = 1000ms")

-- Before backoff expires -> deferred, not retried.
env.advanceMs(500)
local rSkip, sSkip = PNC.Registry.FlushDirty({ mode = "pump", now = env.now() })
T.equal(rSkip, 0)
T.equal(sSkip.deferred, 1, "pump respects retry backoff window")
T.equal(retry1.attempts, 1, "attempts unchanged while inside backoff")

-- Second failure doubles backoff to 2000ms.
env.advanceMs(500)
PNC.Registry.FlushDirty({ mode = "pump", now = env.now() })
local retry2 = PNC.Registry.RetryState["legacy_transient"]
T.equal(retry2.attempts, 2, "second attempt recorded")
T.equal(retry2.nextRetryAt, env.now() + 2000, "second backoff = 2000ms")

-- Clear fault & advance past backoff -> recovers cleanly.
injectLegacyFail = false
env.advanceMs(2000)
local rRec, sRec = PNC.Registry.FlushDirty({ mode = "pump", now = env.now() })
T.equal(rRec, 1, "recovered after fault cleared")
T.equal(sRec.written, 1)
T.equal(PNC.Registry.DirtyByID["legacy_transient"], nil, "dirty cleared after recovery")
T.equal(PNC.Registry.RetryState["legacy_transient"], nil, "retry state cleared after recovery")

-- 4. Bounded retry exhaustion quarantines instead of spinning forever, and resets on fresh mutation.
injectLegacyFail = true
PNC.Registry.MarkDirty(transientRec, "test_exhaust")
for attempt = 1, 5 do
    env.advanceMs(35000)
    PNC.Registry.FlushDirty({ mode = "pump", now = env.now() })
end
T.equal(PNC.Registry.DirtyByID["legacy_transient"], nil, "quarantined from DirtyByID after max attempts")
T.truthy(PNC.Registry.RetryState["legacy_transient"] and PNC.Registry.RetryState["legacy_transient"].exhausted == true,
    "marked exhausted after 5 attempts")
local retryMetricBefore = PNC.Registry.PersistenceMetrics.retryable
PNC.Registry.FlushDirty({ mode = "pump", now = env.now() + 60000 })
T.equal(PNC.Registry.PersistenceMetrics.retryable, retryMetricBefore, "quarantined record stops retrying")

-- Fresh mutation clears exhaustion and succeeds once fault clears.
injectLegacyFail = false
PNC.Registry.MarkDirty(transientRec, "test_recovery_after_exhaust")
T.equal(PNC.Registry.RetryState["legacy_transient"], nil, "fresh mutation clears previous exhaustion")
T.equal(PNC.Registry.FlushDirty({ mode = "pump", now = env.now() }), 1, "fresh mutation recovers after quarantine")
PNC.Persistence.SerializeRecord = origSerialize
PNC.Registry.RemoveRecord("legacy_transient")

-- Core-backed SyncPromotedCoreActorToCore retryable failure test:
local origRegCommit = actorReg.Commit
local failCoreCommit = true
actorReg.Commit = function(self, id, patch, expectedRev)
    if failCoreCommit and id == "core:l2:1" then
        return nil, "revision_conflict"
    end
    return origRegCommit(self, id, patch, expectedRev)
end
coreActorRec.x = 123
PNC.Registry.MarkDirty(coreActorRec, "position")
local cFail, cSum = PNC.Registry.FlushDirty({ mode = "pump", now = env.now() })
T.equal(cFail, 0, "Core commit conflict not counted as written")
T.equal(cSum.retryable, 1, "Core commit conflict classified RETRYABLE_FAILURE")
T.truthy(PNC.Registry.DirtyByID["core:l2:1"], "Core retryable failure retains dirty mark")
failCoreCommit = false
env.advanceMs(5000)
local cOk = PNC.Registry.FlushDirty({ mode = "pump", now = env.now(), ignoreBackoff = true })
T.equal(cOk, 1, "Core-backed record recovers after conflict clears")
actorReg.Commit = origRegCommit

-- 5. Coalescing PersistenceCoordinator.Commit vs Pump vs OnSave.
local knowSaveCalls = 0
local origKnowSave = PNC.NPCKnowledge.Save
PNC.NPCKnowledge.Save = function(flushGlobal)
    T.equal(flushGlobal, false, "Coordinator must never request global ModData save inside domain Save")
    knowSaveCalls = knowSaveCalls + 1
    return origKnowSave(flushGlobal)
end
local flushCalls = 0
local origFlush = PNC.Registry.FlushDirty
PNC.Registry.FlushDirty = function(opts)
    flushCalls = flushCalls + 1
    return origFlush(opts)
end
local runtimeStore = PsychopatzCore.Actors.RuntimeStore
local coreStoreSaves = 0
local origStoreSave = runtimeStore.Save
runtimeStore.Save = function(...)
    coreStoreSaves = coreStoreSaves + 1
    return origStoreSave(...)
end

env.resetGlobalSaveCalls()
local commitsBefore = PNC.PersistenceCoordinator.Metrics.logicalCommits
for i = 1, 15 do
    PNC.NPCKnowledge.RecordGiftPreferences(
        "char_l2_tester",
        "core:l2:1",
        { ["Base.TinCan"] = (i % 2 == 0) and "like" or "dislike" },
        "gift_reaction",
        "gift_l2_" .. tostring(i),
        500 + i
    )
    local ok, status = PNC.PersistenceCoordinator.Commit("knowledge_disclosure")
    T.truthy(ok, status)
    T.equal(status, "queued", "ordinary gameplay Commit must enqueue instead of synchronous flush")
end

T.equal(PNC.PersistenceCoordinator.Metrics.logicalCommits, commitsBefore + 15, "counted all 15 logical commits")
T.equal(knowSaveCalls, 0, "15 rapid commits executed 0 synchronous NPCKnowledge.Save writes")
T.equal(flushCalls, 0, "15 rapid commits executed 0 synchronous Registry.FlushDirty calls")
T.equal(coreStoreSaves, 0, "15 rapid commits executed 0 RuntimeStore.Save calls")
T.equal(env.getGlobalSaveCalls(), 0, "15 rapid commits executed 0 GlobalModData.save calls")

-- Bounded Pump coalesces all 15 commits into 1 domain Save with 0 GlobalModData.save / RuntimeStore.Save.
env.advanceMs(3000)
local pumped, pumpReason = PNC.PersistenceCoordinator.Pump(env.now())
T.truthy(pumped, pumpReason)
T.equal(knowSaveCalls, 1, "15 rapid knowledge commits coalesced into 1 NPCKnowledge.Save write")
T.equal(coreStoreSaves, 0, "background Pump did not rewrite full Core RuntimeStore")
T.equal(env.getGlobalSaveCalls(), 0, "background Pump did not call GlobalModData.save")

-- 6. Bounded physical checkpoint sampler (12 moved promoted actors; max 8 per pass; unrelated commit = 0 scans).
for i = 5, 16 do
    assert(actorReg:Create({
        actorId = "core:ckpt:" .. tostring(i),
        identitySeed = "ckpt_" .. tostring(i),
        archetypeID = "core.survivor",
        appearance = CORE_APPEARANCE,
        providerLease = {
            provider = "ProjectHoomans",
            owner = "ProjectHoomans:l2",
            state = "abstract",
        },
        world = { position = { x = 500 + i * 2, y = 500, z = 0 } },
        extensions = {
            ["PsychopatzCore.SurvivorWorld"] = { factionID = "fac_l2", role = "member" },
        },
    }))
    assert(PNC.Persistence.CoreProvider.PromoteCoreActor("core:ckpt:" .. tostring(i), PsychopatzCore))
end
PNC.Registry.FlushDirty({ mode = "drain", now = env.now(), ignoreBackoff = true })
T.equal(countMap(PNC.Registry.DirtyByID), 0, "all promoted checkpoint test actors flushed cleanly")

for i = 5, 16 do
    local rec = assert(PNC.Registry.Get("core:ckpt:" .. tostring(i)))
    rec.x = (tonumber(rec.x) or 0) + 17
    rec.stamina = { current = 42, max = 100 }
end

local scansBeforeUnrelated = PNC.Registry.PersistenceMetrics.checkpointScans
PNC.NPCKnowledge.RecordGiftPreferences(
    "char_l2_tester", "core:l2:1", { ["Base.WaterBottle"] = "like" }, "gift_reaction", "unrelated_1", 600
)
PNC.PersistenceCoordinator.Commit("unrelated_knowledge")
T.equal(countMap(PNC.Registry.DirtyByID), 0, "unrelated logical commit must NOT scan all promoted actors")
T.equal(PNC.Registry.PersistenceMetrics.checkpointScans, scansBeforeUnrelated, "no checkpoint scan on unrelated Commit")

env.advanceMs(6000)
local marked1, scanned1 = PNC.Registry.PumpPhysicalCheckpoints(env.now())
T.equal(scanned1, 8, "first checkpoint pass bounded to PERSISTENCE_CHECKPOINT_MAX_RECORDS=8")
T.truthy(marked1 >= 1 and marked1 <= 8, "first checkpoint pass only dirtied sampled changed actors")

env.advanceMs(6000)
local marked2, scanned2 = PNC.Registry.PumpPhysicalCheckpoints(env.now())
T.equal(scanned2, 8, "second checkpoint pass bounded to 8")
T.truthy(marked1 + marked2 >= 12, "round-robin checkpoint passes catch all 12 moved promoted actors")

-- 7. Full save/reload round-trip with durability proof (HP, stamina, pos, inventory, Core appearance, knowledge).
local mutRec = assert(PNC.Registry.Get("core:l2:1"))
mutRec.x = 3456
mutRec.y = 2345
mutRec.health.current = 61
mutRec.stamina = { current = 42, max = 100 }
PNC.Inventory.AddItems(mutRec, { { type = "Base.Hammer", count = 1 } }, "root", "l2_save_test")
PNC.Registry.MarkDirty(mutRec, "l2_roundtrip_edit")

env.resetGlobalSaveCalls()
for _, fn in ipairs(env.getEvents().OnSave or {}) do fn() end
T.equal(env.getGlobalSaveCalls(), 1, "world save triggers exactly one GlobalModData.save")
T.equal(countMap(PNC.Registry.DirtyByID), 0, "world save drains all DirtyByID records")

-- Boot completely fresh state from saved stores.
local savedStores = env.getStores()
env.resetModuleCache()
env.installGlobals(savedStores)
env.advanceMs(5000)

local Bootstrap2 = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap2.Initialize()
require "PsychopatzCore/Runtime/PC_RuntimeRole"
require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Actors2 = require "PsychopatzCore/Actors/PsychopatzActors"
local reg2 = Actors2.DefaultRegistry

require "PNC/00_PNC_Init"
require "PNC/Composition/PNC_ServerComposition"
for _, fn in ipairs(env.getEvents().OnInitGlobalModData or {}) do fn() end
for _, fn in ipairs(env.getEvents().OnServerStarted or {}) do fn() end

local reloaded = assert(PNC.Registry.Get("core:l2:1")
    or PNC.Persistence.CoreProvider.PromoteCoreActor("core:l2:1", PsychopatzCore))
T.equal(reloaded.x, 3456, "reloaded X preserved")
T.equal(reloaded.y, 2345, "reloaded Y preserved")
T.equal(reloaded.health.current, 61, "reloaded HP preserved")
T.equal(reloaded.stamina and reloaded.stamina.current, 42, "reloaded stamina preserved")
local canonical2 = assert(reg2:Get("core:l2:1"))
T.equal(canonical2.appearance and canonical2.appearance.policySchemaVersion, initialAppearanceSchema,
    "Core appearance envelope preserved untouched across save/reload")
T.equal(canonical2.appearance and canonical2.appearance.contract
    and canonical2.appearance.contract.policyHash, initialPolicyHash,
    "Core appearance policyHash preserved untouched across save/reload")
local foundHammer = false
for _, item in pairs(reloaded.inventory and reloaded.inventory.items or {}) do
    if item.type == "Base.Hammer" then foundHammer = true end
end
T.truthy(foundHammer, "reloaded Core-compacted inventory preserved Base.Hammer")

local knowNote = assert(PNC.NPCKnowledge.GetGiftPreference("char_l2_tester", "core:l2:1", "Base.WaterBottle"))
T.equal(knowNote.disposition, "like", "reloaded queued+pumped NPCKnowledge preserved")
T.equal(countMap(PNC.Registry.DirtyByID), 0, "reloaded save leaves 0 dirty records")

-- A recruited API spawn must use the same canonical actor before and after save.
local recruited = assert(PNC.API.Spawn({
    id = "authority_recruit", name = "Authority Recruit",
    x = 100, y = 101, z = 0, tacticalClass = "neutral",
}))
local recruitedID = assert(recruited.coreActorID)
local function rosterContains(id)
    local snapshot = PNC.ColonyManagement.BuildSnapshot(env.getPlayer(), { sections = { "roster" } })
    for _, person in ipairs(snapshot.people or {}) do
        if person.id == id then return true end
    end
    return false
end
assert(PNC.API.SetOrder(recruited.id, {
    kind = "follow", ownerUsername = env.getPlayer():getUsername(),
}))
T.equal(rosterContains(recruited.id), false, "follow alone grants no membership")

local recruitedOK, recruitedReason, membership =
    PNC.Recruitment.Try(env.getPlayer(), { npcID = recruited.id })
assert(recruitedOK, recruitedReason)
T.equal(recruited.orderSpec.kind, "follow", "recruitment installs the normal follow order")
T.truthy(recruited.ownerUsername, "follow has an owner")

local function checkRecruitment(record, actor, actorID)
    T.equal(record.coreBacked, true, "API spawn uses Core persistence authority")
    T.equal(record.persistenceAuthority, "core_extension")
    T.equal(record.coreActorID, actorID or recruitedID)
    T.equal(record.affiliation.membershipStatus, "member")
    T.equal(record.affiliation.factionID, membership.factionID)
    T.equal(record.affiliation.communityID, membership.communityID)
    local affiliation = actor.extensions["PsychopatzCore.SurvivorWorld"]
    T.equal(affiliation and affiliation.factionID, membership.factionID)
    T.equal(affiliation and affiliation.communityID, membership.communityID)
    T.truthy(actor.extensions["ProjectHoomans.ActorExtension"], "Core owns the recruited extension")
end

local owner = recruited.ownerUsername
local ownerCharacter = recruited.ownerCharacterUUID
checkRecruitment(recruited, assert(reg2:Get(recruitedID)))
local rp, rr = PNC.Factions.GetPlayerFaction(env.getPlayer())
assert(rp, rr)
local communities = PNC.Communities.GetForFaction(rp.id)
assert(communities[1], "player faction has no community")
T.equal(communities[1].memberIDs[recruited.id], true, "community member index")
T.equal(rosterContains(recruited.id), true, "canonical community members appear in Colonists")
local storageKey = PNC.Registry.Internal.StorageKeyForID(recruited.id)
T.equal(env.getStores()[storageKey], nil, "Core-backed spawn wrote no legacy NPC payload")

local failedRecord = assert(PNC.API.Spawn({
    id = "authority_recruit_failure", x = 100, y = 103, z = 0,
}))
local commitActor = reg2.Commit
reg2.Commit = function(self, id, patch, rev)
    if id == failedRecord.coreActorID and patch.extensions
        and patch.extensions["ProjectHoomans.ActorExtension"]
        and patch.extensions["ProjectHoomans.ActorExtension"].recruited
    then
        return nil, "injected_commit_failure"
    end
    return commitActor(self, id, patch, rev)
end
local failed, failure = PNC.Recruitment.Assign(env.getPlayer(), failedRecord)
reg2.Commit = commitActor
T.equal(failed, false, "Core failure rejects recruitment")
T.equal(failure, "injected_commit_failure")
T.equal(failedRecord.recruited, false)
T.falsy(failedRecord.orderSpec.kind == "follow", "failed recruit never follows")
T.equal(failedRecord.affiliation.factionID, nil)
T.equal(failedRecord.affiliation.communityID, nil)
T.equal(rosterContains(failedRecord.id), false, "rollback removes both membership indexes")

local rollbackCommunity = PNC.Communities.RemoveNPC
PNC.Communities.RemoveNPC = function() return false, "injected_rollback_failure" end
reg2.Commit = function(self, id, patch, rev)
    if id == failedRecord.coreActorID then return nil, "injected_commit_failure" end
    return commitActor(self, id, patch, rev)
end
local pendingOK, pendingReason = PNC.Recruitment.Assign(env.getPlayer(), failedRecord)
PNC.Communities.RemoveNPC = rollbackCommunity
reg2.Commit = commitActor
T.equal(pendingOK, false)
T.equal(pendingReason, "recruitment_rollback_pending")
T.equal(rosterContains(failedRecord.id), false, "pending rollback is outside the roster")
T.falsy(failedRecord.orderSpec.kind == "follow")
local retried, retryReason = PNC.Recruitment.Assign(env.getPlayer(), failedRecord)
assert(retried, retryReason)
T.equal(rosterContains(failedRecord.id), true, "retry repairs rollback and recruits")

local player = env.getPlayer()
local starterTraits = PNC.StartingCompanionTraits.IDS
player.getCharacterTraits = function()
    return { getKnownTraits = function() return { starterTraits.FRIEND, starterTraits.BROTHER } end }
end
local sanitizer = require "PNC/Core/Identity/PNC_StartingCompanionSanitizer"
local authored = assert(sanitizer.SanitizeDefinition({
    displayName = "Riley Reyes",
    identity = { nickname = "Rye", survivor = { forename = "Riley", surname = "Reyes" } },
}, starterTraits.FRIEND))
local granted, grantReason = PNC.StartingCompanions.Ensure(
    player, assert(ownerCharacter), 50, { blueprints = { [starterTraits.FRIEND] = authored } }
)
assert(granted, grantReason)
local startingGrants = PNC.PlayerCharacters.GetRegistryRecord(ownerCharacter).startingCompanions.grants
local starterIDs = {}
for _, trait in ipairs({ starterTraits.FRIEND, starterTraits.BROTHER }) do
    local id = assert(startingGrants[trait].npcID)
    starterIDs[#starterIDs + 1] = id
    local record = assert(PNC.Registry.Get(id))
    T.equal(record.orderSpec.kind, "follow", "starter joins before publication")
    local actor = assert(reg2:Get(record.coreActorID))
    checkRecruitment(record, actor, id)
    if trait == starterTraits.FRIEND then
        T.equal(actor.identity.survivor.forename, "Riley", "authored starter identity is canonical")
    end
    T.equal(rosterContains(id), true, "each starter is canonically rostered")
end

local legacy = PNC.Types.NewRecord({
    id = "legacy_migration_npc", displayName = "Legacy Migration",
    x = 100, y = 102, z = 0,
})
assert(PNC.Registry.AddRecord(legacy))
local legacyKey = PNC.Registry.Internal.StorageKeyForID(legacy.id)

for _, onSave in ipairs(env.getEvents().OnSave or {}) do onSave() end
local recruitedStores = env.getStores()
T.truthy(recruitedStores[legacyKey], "old-format source is present awaiting migration")
env.resetModuleCache()
env.installGlobals(recruitedStores)
require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
require "PsychopatzCore/Runtime/PC_RuntimeRole"
require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local reloadedActors = require "PsychopatzCore/Actors/PsychopatzActors"
require "PNC/00_PNC_Init"
require "PNC/Composition/PNC_ServerComposition"
for _, fn in ipairs(env.getEvents().OnInitGlobalModData or {}) do fn() end
for _, fn in ipairs(env.getEvents().OnServerStarted or {}) do fn() end
local recovered = assert(PNC.Registry.Get(recruited.id)
    or PNC.Persistence.CoreProvider.PromoteCoreActor(recruitedID, PsychopatzCore))
checkRecruitment(recovered, assert(reloadedActors.Get(recruitedID)))
T.equal(recovered.ownerUsername, owner)
T.equal(recovered.ownerCharacterUUID, ownerCharacter)
T.equal(recovered.orderSpec.kind, "follow")
T.equal(rosterContains(recovered.id), true, "reloaded canonical member appears in Colonists")
for _, id in ipairs(starterIDs) do
    local record = assert(PNC.Registry.Get(id))
    checkRecruitment(record, assert(reloadedActors.Get(id)), id)
    T.equal(record.orderSpec.kind, "follow")
    T.equal(rosterContains(id), true, "starter remains a colonist after reconnect")
end
local loadedLegacy = assert(PNC.Registry.Get(legacy.id))
PNC.Registry.FlushDirty({ mode = "pump", maxRecords = 64, now = env.now() })
T.equal(loadedLegacy.coreBacked, true, "bounded pump adopts legacy NPC")
T.truthy(recruitedStores[legacyKey], "legacy data remains before durable save")
for _, onSave in ipairs(env.getEvents().OnSave or {}) do onSave() end
T.equal(recruitedStores[legacyKey], nil, "legacy data retired after Core save")
T.truthy(reloadedActors.Get(legacy.id), "legacy actor is now canonical")
local dismissed, dismissReason = PNC.ColonistDeparture.Depart(recovered, "manual", {
    player = env.getPlayer(),
})
assert(dismissed, dismissReason)
T.equal(rosterContains(recovered.id), false, "dismissed NPC leaves the roster")
T.equal(recovered.recruited, false)
T.equal(recovered.ownerUsername, nil)
T.falsy(recovered.orderSpec.kind == "follow", "dismissal stops following")
for _, onSave in ipairs(env.getEvents().OnSave or {}) do onSave() end
local dismissedActor = assert(reloadedActors.Get(recruitedID))
local roundtrip = assert(PsychopatzCore.ActorPersistence.DecodeActor(
    assert(PsychopatzCore.ActorPersistence.SerializeActor(dismissedActor))
))
local dismissedAffiliation = roundtrip.extensions["PsychopatzCore.SurvivorWorld"] or {}
T.falsy(dismissedAffiliation.factionID == membership.factionID,
    "departure releases the player's faction")
T.equal(dismissedAffiliation.communityID, nil)
local dismissedExtension = roundtrip.extensions["ProjectHoomans.ActorExtension"] or {}
T.equal(dismissedExtension.recruited, nil)
T.equal(dismissedExtension.ownerUsername, nil)
T.equal(env.getStores()[storageKey], nil, "recruit and dismissal never write a legacy payload")

local dismissedStores = env.getStores()
env.resetModuleCache()
env.installGlobals(dismissedStores)
require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
require "PsychopatzCore/Runtime/PC_RuntimeRole"
require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local finalActors = require "PsychopatzCore/Actors/PsychopatzActors"
require "PNC/00_PNC_Init"
require "PNC/Composition/PNC_ServerComposition"
for _, fn in ipairs(env.getEvents().OnInitGlobalModData or {}) do fn() end
for _, fn in ipairs(env.getEvents().OnServerStarted or {}) do fn() end
local dismissedRecord = assert(PNC.Registry.Get(recruitedID)
    or PNC.Persistence.CoreProvider.PromoteCoreActor(recruitedID, PsychopatzCore))
T.equal(dismissedRecord.recruited, false, "dismissal survives a fresh reload")
T.equal(dismissedRecord.ownerUsername, nil)
T.equal(dismissedRecord.ownerCharacterUUID, nil)
T.falsy(dismissedRecord.orderSpec.kind == "follow")
T.equal(rosterContains(recruitedID), false, "dismissal survives roster reconstruction")
T.truthy(finalActors.Get(legacy.id), "migrated actor survives a fresh reload")
T.equal(dismissedStores[legacyKey], nil, "legacy retirement is idempotent")


T.finish("pnc_lightweight_persistence_authority_smoke")
