--[[
    NPC live-body creation.

    The vanilla helper used for NPC shells is `addZombiesInOutfit`, which is a
    debug/tutorial spawner and returns an EMPTY list whenever zombie creation is
    disabled:

        LuaManager.addZombiesInOutfit
          -> IsoWorld.getZombiesDisabled()
          == noZombies, or SystemDisabler.doZombieCreation is false,
             or SandboxOptions.zombies == 6    ("Zombie Count: None")

    NPC bodies must not inherit the sandbox zombie population setting, so when
    the primary helper yields no body a second factory is attempted.
    `createZombie` uses the same engine construction path
    (VirtualZombieManager.createRealZombieAlways) but is gated only by the
    debug-only SystemDisabler.doZombieCreation flag, so it still produces NPC
    bodies in a "Zombie Count: None" world.

    Both factories run inside Internal.SpawnInProgress. The husk reaper ignores
    bodies created inside that window because they are ours and are about to be
    stamped with PNC identity.
]]

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core

local PRIMARY_OUTFIT = "Naked"
local PRIMARY_HEALTH = 1

Lifecycle.BodyFactory = Lifecycle.BodyFactory or {
    lastFactory = nil,
    fallbackSpawns = 0,
    failedSpawns = 0,
    fallbackLogged = false,
    unavailableLogged = false,
}

Internal.SpawnInProgress = Internal.SpawnInProgress or false

--[[
    Run a PNC-initiated engine spawn inside the reaper's suppression window.

    Every body PNC asks the engine to build (live shells, corpse reanimation
    fallbacks) must be invisible to the husk reaper until PNC has stamped it:
    an unstamped body at a recorded husk position is otherwise
    indistinguishable from a resurrected husk. Returns the callback results, or
    `nil, error` when the engine call raised.
]]
function Internal.WithSpawnWindow(callback)
    local previous = Internal.SpawnInProgress
    local results
    Internal.SpawnInProgress = true
    results = { pcall(callback) }
    Internal.SpawnInProgress = previous
    if results[1] ~= true then
        return nil, tostring(results[2])
    end
    return results[2], results[3], results[4]
end

local function noteIncrement(name)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if diagnostics and diagnostics.Increment then
        pcall(diagnostics.Increment, name)
    end
end

local function logOnce(flag, level, message)
    local factory = Lifecycle.BodyFactory
    if factory[flag] == true then
        return
    end
    factory[flag] = true
    local logger = Core and (level == "warn" and Core.LogWarn or Core.LogInfo)
        or nil
    if logger then
        pcall(logger, message)
    end
end

local function isFemaleChance(record)
    if record and record.isFemale then
        return 100
    end
    return 0
end

--[[
    True when the engine refuses to create zombies at all.

    Called for every unmarked body the husk sweep inspects and for every zombie
    the reaper sees created, so the Java call is cached for a short window and
    the lookup allocates nothing. Only used for diagnostics, factory selection
    and the husk fingerprint gate: the fallback is attempted whenever the
    primary helper yields nothing.
]]
local zombiesDisabledCache = nil
local zombiesDisabledCacheAt = -1

function Lifecycle.AreZombieSpawnsDisabled()
    local now = Core and Core.Now and Core.Now() or 0
    local ttl = PNC.Const and tonumber(PNC.Const.ZOMBIE_SPAWN_DISABLED_CACHE_MS)
        or 1000
    local fn
    local disabled
    local ok
    local value
    if zombiesDisabledCache ~= nil and (now - zombiesDisabledCacheAt) < ttl then
        return zombiesDisabledCache
    end
    fn = IsoWorld and IsoWorld.getZombiesDisabled or nil
    disabled = false
    if fn ~= nil then
        ok, value = pcall(fn)
        disabled = ok and value == true
    end
    if now >= zombiesDisabledCacheAt then
        zombiesDisabledCache = disabled
        zombiesDisabledCacheAt = now
    end
    return disabled
end

local function spawnPrimary(record, position)
    if type(addZombiesInOutfit) ~= "function" then
        return nil
    end
    local list = addZombiesInOutfit(
        position.x, position.y, position.z, 1, PRIMARY_OUTFIT,
        isFemaleChance(record),
        false, false, false, false, true, false, PRIMARY_HEALTH
    )
    if not list or not list.size or list:size() <= 0 then
        return nil
    end
    return list:get(0)
end

local function randomDirection()
    local ok, value = pcall(function()
        return IsoDirections ~= nil
            and IsoDirections.getRandom ~= nil
            and IsoDirections.getRandom()
    end)
    if ok and value ~= nil then
        return value
    end
    local fallbackOk, fallback = pcall(function()
        return IsoDirections ~= nil and (IsoDirections.S or IsoDirections.N)
    end)
    if fallbackOk then
        return fallback
    end
    return nil
end

local function applyPrimaryParity(zombie, record)
    --[[
        Only members that are exposed to Lua may be touched here.

        Kahlua throws a Java exception when Lua indexes a member the exposer
        does not publish, and the engine dumps a stack trace for every caught
        exception, so a single wrong member name spams the log on every spawn.
        `dressInPersistentOutfit` (interface-declared), `dressInRandomOutfit`
        and `lunger` (public fields) are all unavailable; the engine's own
        `createZombie` path therefore keeps its random outfit. That is fine:
        PNC applies the real visuals and equipment afterwards, and the husk
        reclaim no longer depends on the persistent outfit id.
    ]]
    if zombie.setFemaleEtc then
        pcall(zombie.setFemaleEtc, zombie,
            record ~= nil and record.isFemale == true)
    end
    if zombie.setHealth then
        pcall(zombie.setHealth, zombie, PRIMARY_HEALTH)
    end
    if zombie.setGodMod then
        pcall(zombie.setGodMod, zombie, true)
    end
    return zombie
end

local function spawnFallback(record, position)
    if type(createZombie) ~= "function" then
        return nil
    end
    local direction = randomDirection()
    if direction == nil then
        return nil
    end
    local zombie = createZombie(
        position.x, position.y, position.z, nil, 0, direction
    )
    if not zombie then
        return nil
    end
    return applyPrimaryParity(zombie, record)
end

local function guardedSpawn(factory, record, position)
    if type(factory) ~= "function" then
        return nil, false
    end
    local ok, zombie = pcall(factory, record, position)
    if ok and zombie then
        return zombie, true
    end
    return nil, ok
end

--[[
    Create one live shell for `record` at `position`.

    Returns `zombie, factoryName` on success and `nil, reason` on failure. The
    caller owns lifecycle marking; ownership marking happens here so a body is
    never exposed to the engine unmarked.
]]
function Lifecycle.SpawnLiveBody(record, position, reason)
    local factory = Lifecycle.BodyFactory
    local zombie
    local factoryName
    local primaryOk
    local fallbackOk
    local disabled
    if not record or not position then
        return nil, "invalid_spawn_request"
    end
    if Internal.SpawnInProgress == true then
        return nil, "spawn_reentrant"
    end
    Internal.SpawnInProgress = true
    zombie, primaryOk = guardedSpawn(spawnPrimary, record, position)
    if zombie then
        factoryName = "addZombiesInOutfit"
    else
        local fallbackZombie
        fallbackZombie, fallbackOk = guardedSpawn(spawnFallback, record, position)
        if fallbackZombie then
            zombie = fallbackZombie
            factoryName = "createZombie"
            factory.fallbackSpawns = (tonumber(factory.fallbackSpawns) or 0) + 1
            noteIncrement("BodyFactory.FallbackSpawns")
            logOnce("fallbackLogged", "info",
                "PNC body factory fallback active factory=createZombie"
                    .. " zombieSpawnsDisabled="
                    .. tostring(Lifecycle.AreZombieSpawnsDisabled())
                    .. " reason=" .. tostring(reason or "unknown"))
        end
    end
    Internal.SpawnInProgress = false
    if not zombie then
        factory.failedSpawns = (tonumber(factory.failedSpawns) or 0) + 1
        noteIncrement("BodyFactory.FailedSpawns")
        disabled = Lifecycle.AreZombieSpawnsDisabled()
        if disabled then
            logOnce("unavailableLogged", "warn",
                "PNC body factory exhausted zombieSpawnsDisabled=true"
                    .. " primaryOk=" .. tostring(primaryOk == true)
                    .. " fallbackOk=" .. tostring(fallbackOk == true))
            return nil, "spawn_disabled_no_factory"
        end
        return nil, "spawn_returned_no_body"
    end
    factory.lastFactory = factoryName
    if PNC.Compatibility and PNC.Compatibility.ActorOwnership
        and PNC.Compatibility.ActorOwnership.MarkHoomansOwned
    then
        pcall(PNC.Compatibility.ActorOwnership.MarkHoomansOwned, zombie)
    end
    return zombie, factoryName
end
