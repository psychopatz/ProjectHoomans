--[[
    NPC live-body creation.

    The vanilla helper used for NPC shells is `addZombiesInOutfit`, which is a
    debug/tutorial spawner and returns an EMPTY list whenever zombie creation is
    disabled:

        LuaManager.addZombiesInOutfit
          -> IsoWorld.getZombiesDisabled()
          == noZombies, or SystemDisabler.doZombieCreation is false,
             or SandboxOptions.zombies == 6    ("Zombie Count: None")

    NPC bodies must not inherit the sandbox zombie population setting. The old
    implementation therefore used `createZombie` as a second factory. That
    path bypasses normal population admission, so it is accepted only after
    the new body is dressed in the PNC-only carrier and its persistent outfit
    id is verified. A body that cannot carry that identity is detached and
    discarded before it can enter the NPC or ordinary-zombie lanes. The
    direct VirtualZombieManager path is preferred because the global
    createZombie helper cannot resolve an engine square on some dedicated
    server frames even when a real square object is available.

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
local Const = PNC.Const

local PRIMARY_OUTFIT = Const and Const.BODY_SHELL_OUTFIT
    or "PNCShellCarrier"
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
        false, false, false, false, false, false, PRIMARY_HEALTH
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
    The fallback dresses the body in `PNCShellCarrier` after setting the
    requested gender. The carrier is not the NPC's visible outfit; PNC applies
    the real visuals and equipment afterwards.
    ]]
    if zombie.setFemaleEtc then
        pcall(zombie.setFemaleEtc, zombie,
            record ~= nil and record.isFemale == true)
    end
    if zombie.setHealth then
        pcall(zombie.setHealth, zombie, PRIMARY_HEALTH)
    end
    return zombie
end

local function clearEngineInvulnerability(zombie)
    local checker
    local setter
    local ok
    local value
    if not zombie then
        return false
    end
    ok, checker = pcall(function() return zombie.isGodMod end)
    if not ok or not checker then
        ok, checker = pcall(function() return zombie.isInvulnerable end)
        if not ok then checker = nil end
    end
    ok, setter = pcall(function() return zombie.setGodMod end)
    if ok and setter then
        pcall(setter, zombie, false)
    end
    if not checker then
        return true
    end
    ok, value = pcall(checker, zombie)
    return not (ok and value == true)
end

local function abortSpawnedBody(zombie)
    local method
    local ok
    local attached
    if not zombie then
        return true
    end
    if Internal.removeZombie then
        local ok, removed = pcall(Internal.removeZombie, zombie)
        attached = Internal.isBodyAttached
            and Internal.isBodyAttached(zombie) or false
        if ok and (removed == true or not attached) then
            return true
        end
    end
    ok, method = pcall(function() return zombie.removeFromWorld end)
    if ok and type(method) == "function" then
        pcall(method, zombie)
    end
    ok, method = pcall(function() return zombie.removeFromSquare end)
    if ok and type(method) == "function" then
        pcall(method, zombie)
    end
    attached = Internal.isBodyAttached
        and Internal.isBodyAttached(zombie) or false
    return not attached
end

Lifecycle.ClearEngineInvulnerability = clearEngineInvulnerability
Lifecycle.AbortSpawnedBody = abortSpawnedBody

local function resolveSpawnSquare(position)
    local cell
    local square
    local ok
    if type(getCell) ~= "function" then
        return nil
    end
    ok, cell = pcall(getCell)
    if not ok or not cell then
        return nil
    end
    if cell.getGridSquare then
        ok, square = pcall(function()
            return cell:getGridSquare(position.x, position.y, position.z)
        end)
        if ok and square then
            return square
        end
    end
    -- Materialization normally runs in a loaded player-interest square. This
    -- second lookup is also useful during a server-side restore frame where
    -- ServerMap has the square but IsoCell has not exposed it through its
    -- double-coordinate lookup yet.
    if cell.getOrCreateGridSquare then
        ok, square = pcall(function()
            return cell:getOrCreateGridSquare(
                position.x, position.y, position.z
            )
        end)
        if ok and square then
            local waterOK, water = pcall(square.isWaterSquare, square)
            if not waterOK or water ~= true then
                return square
            end
        end
    end
    return nil
end

local function spawnViaVirtualZombieManager(position, direction)
    local manager
    local choices
    local square
    local ok
    local zombie
    local managerOK
    managerOK, manager = pcall(function()
        return VirtualZombieManager and VirtualZombieManager.instance or nil
    end)
    if not managerOK or not manager then
        return nil
    end
    square = resolveSpawnSquare(position)
    if not square then
        return nil
    end
    ok, choices = pcall(function() return manager.choices end)
    if not ok or not choices then
        return nil
    end
    ok = pcall(function() choices:clear() end)
    if not ok then
        return nil
    end
    ok = pcall(function() choices:add(square) end)
    if not ok then
        pcall(function() choices:clear() end)
        return nil
    end
    ok, zombie = pcall(function()
        return manager:createRealZombieAlways(direction, false, 0, 0)
    end)
    pcall(function() choices:clear() end)
    if ok and zombie then
        return zombie, "createRealZombieAlways"
    end
    return nil
end

local function spawnFallback(record, position)
    local dresser
    local getter
    local outfitID
    local ok
    local direction = randomDirection()
    if direction == nil then
        return nil
    end
    local zombie, factoryName = spawnViaVirtualZombieManager(
        position, direction
    )
    if not zombie and type(createZombie) == "function" then
        zombie = createZombie(
            position.x, position.y, position.z, nil, 0, direction
        )
        factoryName = zombie and "createZombie" or nil
    end
    if not zombie then
        return nil
    end
    applyPrimaryParity(zombie, record)
    -- createZombie fires OnZombieCreate before this function returns. The
    -- spawn window suppresses reaping during that hand-off, but the body must
    -- still receive the durable carrier before the window closes.
    ok, dresser = pcall(function()
        return zombie.dressInPersistentOutfit
    end)
    if not ok or type(dresser) ~= "function"
        or not pcall(dresser, zombie, PRIMARY_OUTFIT)
    then
        abortSpawnedBody(zombie)
        return nil
    end
    ok, getter = pcall(function()
        return zombie.getPersistentOutfitID
    end)
    if not ok or type(getter) ~= "function" then
        abortSpawnedBody(zombie)
        return nil
    end
    ok, outfitID = pcall(getter, zombie)
    if not ok or outfitID == nil or tostring(outfitID) == ""
        or tostring(outfitID) == "0" or tonumber(outfitID) == 0
    then
        abortSpawnedBody(zombie)
        return nil
    end
    Lifecycle.BodyFactory.lastFallbackOutfitID = tostring(outfitID)
    if Internal.isBodyAttached and not Internal.isBodyAttached(zombie) then
        abortSpawnedBody(zombie)
        return nil
    end
    return zombie, factoryName
end

local function guardedSpawn(factory, record, position)
    if type(factory) ~= "function" then
        return nil, false
    end
    local ok, zombie, detail = pcall(factory, record, position)
    if ok and zombie then
        return zombie, true, detail
    end
    return nil, ok, detail
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
    local fallbackOk = false
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
    elseif PNC.Const and PNC.Const.BODY_FACTORY_ALLOW_FALLBACK == true then
        local fallbackZombie
        local fallbackFactory
        fallbackZombie, fallbackOk, fallbackFactory = guardedSpawn(
            spawnFallback, record, position
        )
        if fallbackZombie then
            zombie = fallbackZombie
            factoryName = fallbackFactory or "createZombie"
            factory.fallbackSpawns = (tonumber(factory.fallbackSpawns) or 0) + 1
            noteIncrement("BodyFactory.FallbackSpawns")
            logOnce("fallbackLogged", "info",
                "PNC body factory fallback active factory=createZombie"
                    .. " zombieSpawnsDisabled="
                    .. tostring(Lifecycle.AreZombieSpawnsDisabled())
                    .. " reason=" .. tostring(reason or "unknown"))
        end
    else
        factory.fallbackBlocked = (tonumber(factory.fallbackBlocked) or 0) + 1
        noteIncrement("BodyFactory.FallbackBlocked")
        logOnce("fallbackBlockedLogged", "warn",
            "PNC body factory fallback blocked; keeping NPC abstract"
                .. " reason=" .. tostring(reason or "unknown"))
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
    if not clearEngineInvulnerability(zombie) then
        factory.failedSpawns = (tonumber(factory.failedSpawns) or 0) + 1
        noteIncrement("BodyFactory.InvulnerableRejected")
        abortSpawnedBody(zombie)
        logOnce("invulnerableLogged", "warn",
            "PNC body factory rejected invulnerable engine body")
        return nil, "spawn_invulnerable_body_rejected"
    end
    factory.lastFactory = factoryName
    if PNC.Compatibility and PNC.Compatibility.ActorOwnership
        and PNC.Compatibility.ActorOwnership.MarkHoomansOwned
    then
        pcall(PNC.Compatibility.ActorOwnership.MarkHoomansOwned, zombie)
    end
    return zombie, factoryName
end
