local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")

local owned = 0
local fallbackRecord
local primaryCalls = 0
local primaryArgs
local fallbackCalls = 0
local primaryResult
local fallbackBody
local spawnsDisabled = true
local nowMs = 100
local preclaimCount = 0
local preclaimInsideSpawnWindow = false

-- Kahlua throws when Lua indexes a member the exposer does not publish, and
-- the engine dumps a stack trace for every caught Java exception. Model that
-- strictly so the factory can never regress into touching an unexposed member.
-- Applied values are recorded outside the body so the test never indexes a
-- member the strict metatable would reject.
local function makeBody()
    local record = {}
    local body = {
        modData = {},
        getModData = function(self) return self.modData end,
        isGodMod = function() return record.godMod == true end,
        setGodMod = function(_, value) record.godMod = value end,
        setHealth = function(_, value) record.health = value end,
        setFemaleEtc = function(_, value) record.female = value end,
        dressInPersistentOutfit = function(_, outfit)
            record.carrierOutfit = outfit
            record.outfitID = 424242
        end,
        getPersistentOutfitID = function() return record.outfitID or 0 end,
    }
    setmetatable(body, {
        __index = function(_, key)
            error("attempted index of non-table: " .. tostring(key))
        end,
        __newindex = function(_, key)
            error("attempted index of non-table (write): " .. tostring(key))
        end,
    })
    return body, record
end

PNC = {
    Core = {
        Now = function() return nowMs end,
        LogInfo = function() end,
        LogWarn = function() end,
        LogDebug = function() end,
        IsManagedNPCBody = function() return false end,
    },
    Const = { BODY_FACTORY_ALLOW_FALLBACK = true },
    Compatibility = {
        ActorOwnership = {
            MarkHoomansOwned = function()
                owned = owned + 1
                return true
            end,
        },
    },
}

addZombiesInOutfit = function(...)
    primaryCalls = primaryCalls + 1
    primaryArgs = { ... }
    return primaryResult
end

createZombie = function()
    fallbackCalls = fallbackCalls + 1
    return fallbackBody
end

IsoWorld = { getZombiesDisabled = function() return spawnsDisabled end }
IsoDirections = { getRandom = function() return "S" end }

T.load(SHARED
    .. "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_BodyFactory.lua")

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
Lifecycle.PreclaimLiveBody = function(record, body)
    preclaimCount = preclaimCount + 1
    preclaimInsideSpawnWindow = Internal.SpawnInProgress == true
    local modData = body:getModData()
    modData.PNC_UUID = record.id
    modData.PNC_NPC = true
    modData.PNC_BodyKind = "live"
    modData.PNC_BodyLease = "body_preclaim"
    return "body_preclaim"
end
local position = { x = 10, y = 20, z = 0 }

T.truthy(Lifecycle.AreZombieSpawnsDisabled(),
    "zombie spawn gate was not detected")

-- Primary factory yields no body because zombie creation is disabled. The
-- verified carrier fallback still creates a usable NPC shell.
primaryResult = { size = function() return 0 end }
fallbackBody, fallbackRecord = makeBody()
local zombie, factory = Lifecycle.SpawnLiveBody(
    { id = "npc_1", isFemale = true }, position, "test_disabled")
T.truthy(zombie, "verified fallback produced no body")
T.equal(factory, "createZombie", "fallback factory was not reported")
T.equal(primaryCalls, 1, "primary factory was not attempted first")
T.equal(primaryArgs[11], false,
    "primary factory requested an invulnerable body")
T.equal(fallbackCalls, 1, "fallback factory call count")
T.equal(fallbackRecord.carrierOutfit, "PNCShellCarrier",
    "fallback body did not receive the durable carrier outfit")
T.equal(fallbackRecord.godMod, false,
    "fallback body retained engine invulnerability")
T.equal(fallbackRecord.health, 1,
    "fallback body health does not match the shell")
T.equal(fallbackRecord.female, true,
    "fallback body gender hint was not applied")
T.equal(owned, 1, "fallback body was not marked as owned")
T.equal(preclaimCount, 1, "fallback body was not preclaimed")
T.truthy(preclaimInsideSpawnWindow,
    "fallback body was preclaimed after the MP spawn window closed")
T.equal(fallbackBody:getModData().PNC_UUID, "npc_1",
    "preclaim did not stamp NPC identity before exposure")
T.falsy(Internal.SpawnInProgress, "spawn window was left open")

-- An explicit disable remains available for deployments that want to fail
-- closed while diagnosing an unavailable engine surface.
PNC.Const.BODY_FACTORY_ALLOW_FALLBACK = false
fallbackBody, fallbackRecord = makeBody()
zombie, factory = Lifecycle.SpawnLiveBody(
    { id = "npc_1_opt_in", isFemale = true }, position, "test_opt_in")
T.falsy(zombie, "disabled fallback produced a body")
T.equal(factory, "spawn_disabled_no_factory",
    "disabled fallback did not report the disabled-world reason")
T.equal(fallbackCalls, 1, "disabled fallback was not blocked")
T.equal(owned, 1, "disabled fallback body was marked as owned")
T.falsy(Internal.SpawnInProgress, "spawn window was left open")
T.equal(Lifecycle.BodyFactory.lastFactory, "createZombie",
    "last factory was not recorded")

-- Primary factory succeeds: no fallback, no extra cost.
primaryResult = {
    size = function() return 1 end,
    get = function() return fallbackBody end,
}
fallbackBody, fallbackRecord = makeBody()
zombie, factory = Lifecycle.SpawnLiveBody(
    { id = "npc_2" }, position, "test_primary")
T.equal(factory, "addZombiesInOutfit", "primary factory was not preferred")
T.equal(fallbackCalls, 1, "fallback ran even though the primary succeeded")
T.equal(preclaimCount, 2,
    "primary body was returned before authoritative preclaim")
T.equal(fallbackBody:getModData().PNC_UUID, "npc_2",
    "primary body was exposed without its PNC UUID")
T.equal(fallbackRecord.female, nil,
    "primary bodies must not be re-configured by the factory")

-- Both factories fail: a typed reason must be returned, and the spawn window
-- must still close so the next spawn is not rejected as re-entrant.
primaryResult = { size = function() return 0 end }
fallbackBody = nil
zombie, factory = Lifecycle.SpawnLiveBody({ id = "npc_3" }, position, "test_fail")
T.falsy(zombie, "exhausted factories produced a body")
T.equal(factory, "spawn_disabled_no_factory",
    "disabled-world failure reason was not reported")
T.falsy(Internal.SpawnInProgress, "spawn window was left open after failure")

-- The spawn gate is cached for a short window; advance past it before changing
-- the configuration so the factory sees the new value.
spawnsDisabled = false
nowMs = nowMs + 2000
primaryResult = nil
zombie, factory = Lifecycle.SpawnLiveBody({ id = "npc_4" }, position, "test_no_factory")
T.falsy(zombie, "missing factories produced a body")
T.equal(factory, "spawn_returned_no_body",
    "enabled-world failure reason was not reported")

-- Re-entrancy guard: an OnZombieCreate that reached back into the factory must
-- never recurse.
Internal.SpawnInProgress = true
zombie, factory = Lifecycle.SpawnLiveBody({ id = "npc_5" }, position, "test_reentrant")
T.falsy(zombie, "re-entrant spawn produced a body")
T.equal(factory, "spawn_reentrant", "re-entrant spawn reason")
Internal.SpawnInProgress = false

return T.finish("pnc_body_factory_zombie_none_smoke")
