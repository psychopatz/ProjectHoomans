local T = require "tests/support/test"

T.addPackagePaths()

local Simulator = {}
local originalPrint = print

local COARSE_METRICS = {
    ["ProjectHoomans.Server.Update"] = true,
    ["ProjectHoomans.Server.Update.Spatial.Rebuild"] = true,
    ["ProjectHoomans.WorldCensus.Refresh"] = true,
    ["ProjectHoomans.Network.BroadcastRecord"] = true,
    ["ProjectHoomans.Network.Snapshot.Full"] = true,
    ["ProjectHoomans.Network.Snapshot.CombatDamageDelta"] = true,
    ["ProjectHoomans.Network.Snapshot.CombatStateDelta"] = true,
    ["ProjectHoomans.Network.Snapshot.HealthWoundsDelta"] = true,
    ["ProjectHoomans.Network.Snapshot.EquipmentDelta"] = true,
    ["ProjectHoomans.Network.Snapshot.PresenceDelta"] = true,
    ["ProjectHoomans.Server.Update.Network.FlushRosterDeltas"] = true,
    ["ProjectHoomans.Persistence.Commit"] = true,
    ["ProjectHoomans.Persistence.Pump"] = true,
    ["ProjectHoomans.Persistence.NPCRecords"] = true,
    ["ProjectHoomans.Server.Update.NPC.Materialize"] = true,
}

local function countMap(tbl)
    local count = 0
    for _, _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function tableSignature(value, seen)
    local kind = type(value)
    if kind ~= "table" then
        return kind .. ":" .. tostring(value)
    end
    seen = seen or {}
    if seen[value] then return "<cycle>" end
    seen[value] = true
    local keys = {}
    for k, _ in pairs(value) do
        keys[#keys + 1] = tostring(k)
    end
    table.sort(keys)
    local parts = {}
    for i = 1, #keys do
        local k = keys[i]
        local rawVal = value[k]
        if rawVal == nil then rawVal = value[tonumber(k)] end
        parts[i] = k .. "=" .. tableSignature(rawVal, seen)
    end
    seen[value] = nil
    return "{" .. table.concat(parts, ",") .. "}"
end

function Simulator.ResetEnvironment()
    print = originalPrint
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
    PSYCHOPATZ_PROFILER_PERFORMANCE_DEPTH = nil
    PSYCHOPATZ_PROFILER_DEEP_DURATION_MS = nil
    getFileReader = nil
    getFileWriter = nil
end

local function makeJavaList(items)
    return {
        size = function() return #items end,
        get = function(_, index) return items[index + 1] end,
        add = function(_, value) items[#items + 1] = value end,
    }
end

local function makeItem(fullType)
    local md = {}
    local cond = 10
    return {
        getFullType = function() return tostring(fullType or "Base.Dummy") end,
        getType = function()
            local dot = string.find(tostring(fullType or ""), ".", 1, true)
            return dot and string.sub(fullType, dot + 1) or tostring(fullType)
        end,
        getModData = function() return md end,
        getCondition = function() return cond end,
        getConditionMax = function() return 10 end,
        setCondition = function(_, v) cond = tonumber(v) or cond end,
        getWeight = function() return 0.5 end,
        getActualWeight = function() return 0.5 end,
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
        getItems = function() return makeJavaList(items) end,
        clear = function() items = {} end,
        AddItem = function(_, fullType)
            local item = makeItem(fullType)
            items[#items + 1] = item
            return item
        end,
        Remove = function(_, target)
            for i = #items, 1, -1 do
                if items[i] == target then table.remove(items, i) end
            end
        end,
        FindAndReturn = function(_, fullType)
            for i = 1, #items do
                if items[i]:getFullType() == fullType then return items[i] end
            end
            return nil
        end,
    }
end

function Simulator.New(options)
    options = options or {}
    local config = {
        worldSeed = math.floor(tonumber(options.worldSeed) or 123456),
        actorCount = math.max(1, math.floor(tonumber(options.actorCount) or 100)),
        nearbyActors = math.max(0, math.floor(tonumber(options.nearbyActors) or 14)),
        expectedPromotedActors = math.max(0, math.floor(tonumber(options.expectedPromotedActors) or 6)),
        zombieCount = math.max(0, math.floor(tonumber(options.zombieCount) or 40)),
        playerCount = math.max(1, math.floor(tonumber(options.playerCount) or 1)),
        clientCount = math.max(1, math.floor(tonumber(options.clientCount) or 1)),
        simulatedMs = math.max(100, math.floor(tonumber(options.simulatedMs) or 15000)),
        stepMs = math.max(10, math.floor(tonumber(options.stepMs) or 50)),
        mutationIntervalMs = math.max(100, math.floor(tonumber(options.mutationIntervalMs) or 1000)),
        knowledgeMutationIntervalMs = math.max(50, math.floor(tonumber(options.knowledgeMutationIntervalMs) or 4000)),
        mixedCapabilities = options.mixedCapabilities == true,
        injectRevisionGap = options.injectRevisionGap == true,
        departAtMs = tonumber(options.departAtMs),
        massInterestActors = tonumber(options.massInterestActors),
        profilerMode = string.upper(tostring(options.profilerMode or "OFF")),
        deepDurationMs = math.floor(tonumber(options.deepDurationMs) or 10000),
        quiet = options.quiet ~= false,
    }
    return setmetatable({ config = config }, { __index = Simulator })
end

function Simulator:Run()
    local cfg = self.config
    Simulator.ResetEnvironment()

    if cfg.quiet then
        print = function(message, ...)
            local text = tostring(message or "")
            if string.sub(text, 1, 5) == "[PNC]"
                or string.sub(text, 1, 16) == "[PsychopatzCore]"
                or string.sub(text, 1, 20) == "[PsychopatzProfiler]"
            then
                return
            end
            originalPrint(message, ...)
        end
    end

    local seed = math.abs(cfg.worldSeed) % 2147483647
    if seed == 0 then seed = 123456 end
    local function nextRand()
        seed = (seed * 48271) % 2147483647
        return seed
    end

    local nowMs = 10000
    local events = {}
    local stores = {}
    local storeSignatures = {}
    local squares = {}
    local zombies = {}
    local players = {}
    local nextOnlineID = 100

    local metrics = {
        globalSaveCalls = 0,
        physicalWrites = 0,
        coreRuntimeStoreSaves = 0,
        materializationAttempts = 0,
        materializationSuccesses = 0,
        spatialRebuilds = 0,
        presenceDeltas = 0,
        combatDamageDeltas = 0,
        combatStateDeltas = 0,
        combatDeltas = 0,
        healthOrWoundDeltas = 0,
        equipmentDeltas = 0,
        fullSnapshots = 0,
        repairSnapshots = 0,
        fallbackSnapshots = 0,
        rosterDeltas = 0,
        packetsSent = 0,
        zombieListQueriesTick = 0,
        inTickPhase = false,
    }

    local function snapshotStoreWrites()
        for key, tbl in pairs(stores) do
            local sig = tableSignature(tbl)
            if storeSignatures[key] ~= sig then
                if storeSignatures[key] ~= nil or next(tbl) ~= nil then
                    metrics.physicalWrites = metrics.physicalWrites + 1
                end
                storeSignatures[key] = sig
            end
        end
    end

    Events = setmetatable({}, {
        __index = function(tbl, key)
            local list = {}
            events[key] = list
            tbl[key] = {
                Add = function(fn)
                    for i = 1, #list do if list[i] == fn then return end end
                    list[#list + 1] = fn
                end,
                Remove = function(fn)
                    for i = #list, 1, -1 do
                        if list[i] == fn then table.remove(list, i) end
                    end
                end,
            }
            return tbl[key]
        end,
    })

    ModData = {
        get = function(key) return stores[key] end,
        getOrCreate = function(key)
            stores[key] = stores[key] or {}
            return stores[key]
        end,
        remove = function(key)
            stores[key] = nil
            storeSignatures[key] = nil
        end,
        getTableNames = function()
            local out = {}
            for key, _ in pairs(stores) do out[#out + 1] = key end
            table.sort(out)
            return out
        end,
        transmit = function() end,
    }
    GlobalModData = {
        save = function()
            metrics.globalSaveCalls = metrics.globalSaveCalls + 1
        end,
    }
    SandboxVars = { ProjectHoomans = {} }
    isServer = function() return true end
    isClient = function() return false end
    getTimeInMillis = function() return nowMs end
    getTimestampMs = function() return nowMs end
    getText = function(key) return key end
    ZombRand = function(minOrMax, maxVal)
        if maxVal ~= nil then
            local lo = math.floor(tonumber(minOrMax) or 0)
            local hi = math.floor(tonumber(maxVal) or lo)
            if hi <= lo then return lo end
            return lo + (nextRand() % (hi - lo))
        end
        local limit = math.floor(tonumber(minOrMax) or 1)
        if limit <= 1 then return 0 end
        return nextRand() % limit
    end
    getGameTime = function()
        return {
            getWorldAgeHours = function() return 100 + (nowMs / 3600000) end,
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
    instanceItem = function(fullType) return makeItem(fullType) end
    InventoryItemFactory = { CreateItem = function(fullType) return makeItem(fullType) end }
    instanceof = function(obj, cls) return type(obj) == "table" and obj.__class == cls end

    local function getSquare(x, y, z)
        local sx = math.floor(tonumber(x) or 0)
        local sy = math.floor(tonumber(y) or 0)
        local sz = math.floor(tonumber(z) or 0)
        local key = tostring(sx) .. ":" .. tostring(sy) .. ":" .. tostring(sz)
        if not squares[key] then
            squares[key] = {
                getX = function() return sx end,
                getY = function() return sy end,
                getZ = function() return sz end,
                isFree = function() return true end,
                isSolidTrans = function() return false end,
                isSolid = function() return false end,
                HasStairs = function() return false end,
                getObjects = function() return makeJavaList({}) end,
                getMovingObjects = function() return makeJavaList({}) end,
                getDeadBodys = function() return makeJavaList({}) end,
                TreatAsSolidFloor = function() return true end,
            }
        end
        return squares[key]
    end

    for p = 1, cfg.playerCount do
        local px, py, pz = 10000 + (p - 1) * 2, 10000, 0
        local pInv = makeInv()
        local pMod = {}
        players[p] = {
            __class = "IsoPlayer",
            getUsername = function() return "sim_player_" .. tostring(p) end,
            getDisplayName = function() return "Sim Player " .. tostring(p) end,
            getOnlineID = function() return p end,
            getX = function() return px end,
            _setX = function(v) px = v end,
            getY = function() return py end,
            _setY = function(v) py = v end,
            getZ = function() return pz end,
            getAccessLevel = function() return "admin" end,
            isDead = function() return false end,
            isSneaking = function() return false end,
            isRunning = function() return false end,
            isSprinting = function() return false end,
            isAiming = function() return false end,
            getModData = function() return pMod end,
            getCurrentSquare = function() return getSquare(px, py, pz) end,
            getInventory = function() return pInv end,
        }
    end
    getOnlinePlayers = function() return makeJavaList(players) end
    getNumActivePlayers = function() return 0 end
    getSpecificPlayer = function() return nil end
    getPlayer = function() return players[1] end

    local function makeZombieShell(x, y, z)
        nextOnlineID = nextOnlineID + 1
        local oid = nextOnlineID
        local zx, zy, zz = tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
        local zmd, vars, inv = {}, {}, makeInv()
        local vis = {
            setSkinTextureIndex = function() end,
            setSkinTextureName = function() end,
            setHairModel = function() end,
            setBeardModel = function() end,
            setHairColor = function() end,
            setBeardColor = function() end,
            getSkinTexture = function() return "MaleBody01" end,
            getHairModel = function() return "Short" end,
            getBeardModel = function() return "" end,
        }
        local pfb = {
            cancel = function() end,
            setTarget = function() end,
            reset = function() end,
            clearTarget = function() end,
        }
        local removed = false
        local zObj
        zObj = {
            __class = "IsoZombie",
            getX = function() return zx end,
            setX = function(_, v) zx = v end,
            getY = function() return zy end,
            setY = function(_, v) zy = v end,
            getZ = function() return zz end,
            setZ = function(_, v) zz = v end,
            getOnlineID = function() return oid end,
            getPersistentOutfitID = function() return oid + 10000 end,
            isDead = function() return false end,
            isFakeDead = function() return false end,
            getModData = function() return zmd end,
            getVariableBoolean = function(_, k) return vars[k] == true end,
            getVariableString = function(_, k) return vars[k] or "" end,
            setVariable = function(_, k, v) vars[k] = v end,
            clearVariable = function(_, k) vars[k] = nil end,
            getCurrentSquare = function()
                if removed then return nil end
                return getSquare(zx, zy, zz)
            end,
            getSquare = function()
                if removed then return nil end
                return getSquare(zx, zy, zz)
            end,
            isExistInTheWorld = function() return not removed end,
            getInventory = function() return inv end,
            getHumanVisual = function() return vis end,
            getItemVisuals = function() return makeJavaList({}) end,
            DoZombieStats = function() end,
            resetModelNextFrame = function() end,
            resetModel = function() end,
            setUseless = function() end,
            setFakeDead = function() end,
            setNoTeeth = function() end,
            setCrawler = function() end,
            setCanCrawlUnderVehicle = function() end,
            setSkeleton = function() end,
            setOnFire = function() end,
            setTarget = function() end,
            getTarget = function() return nil end,
            setPath2 = function() end,
            clearAggroList = function() end,
            setRunning = function() end,
            getPathFindBehavior2 = function() return pfb end,
            getHealth = function() return 1.0 end,
            setHealth = function() end,
            setAvoidDamage = function() end,
            setImmortal = function() end,
            setInvulnerable = function() end,
            setDir = function() end,
            facePosition = function() end,
            faceLocation = function() end,
            faceLocationF = function() end,
            setForwardDirection = function() end,
            setForceEatingAnimation = function() end,
            setAttackOutcome = function() end,
            removeFromWorld = function()
                removed = true
                for i = #zombies, 1, -1 do
                    if zombies[i] == zObj then table.remove(zombies, i) end
                end
            end,
            removeFromSquare = function()
                removed = true
            end,
            getWornItems = function() return makeJavaList({}) end,
            clearWornItems = function() end,
            setPrimaryHandItem = function() end,
            setSecondaryHandItem = function() end,
            getPrimaryHandItem = function() return nil end,
            getSecondaryHandItem = function() return nil end,
            getAttachedItems = function() return makeJavaList({}) end,
            clearAttachedItems = function() end,
            getLastKnownLocation = function() return nil end,
            isMoving = function() return false end,
        }
        zombies[#zombies + 1] = zObj
        return zObj
    end

    getCell = function()
        return {
            getZombieList = function()
                if metrics.inTickPhase then
                    metrics.zombieListQueriesTick = metrics.zombieListQueriesTick + 1
                end
                return makeJavaList(zombies)
            end,
            getGridSquare = function(_, x, y, z) return getSquare(x, y, z) end,
        }
    end
    getWorld = function() return { getCell = getCell } end

    addZombiesInOutfit = function(x, y, z)
        metrics.materializationSuccesses = metrics.materializationSuccesses + 1
        return makeJavaList({ makeZombieShell(x, y, z) })
    end
    for i = 1, cfg.zombieCount do
        makeZombieShell(10005 + (i % 12), 10005 + math.floor(i / 12), 0)
    end

    sendServerCommand = function(targetPlayer, _, command, payload)
        metrics.packetsSent = metrics.packetsSent + 1
        if command == "SyncRecord" then
            local snap = type(payload) == "table" and payload.snapshot or nil
            local deltaKind = type(snap) == "table" and snap.deltaKind or nil
            if deltaKind == "presence" then
                metrics.presenceDeltas = metrics.presenceDeltas + 1
            elseif deltaKind == "combat_damage" then
                metrics.combatDamageDeltas = metrics.combatDamageDeltas + 1
                metrics.combatDeltas = metrics.combatDeltas + 1
            elseif deltaKind == "combat_state" then
                metrics.combatStateDeltas = metrics.combatStateDeltas + 1
                metrics.combatDeltas = metrics.combatDeltas + 1
            elseif deltaKind == "health_wounds"
                or deltaKind == "health"
                or deltaKind == "wounds"
                or deltaKind == "medical"
            then
                metrics.healthOrWoundDeltas = metrics.healthOrWoundDeltas + 1
            elseif deltaKind == "equipment" or deltaKind == "appearance" then
                metrics.equipmentDeltas = metrics.equipmentDeltas + 1
            else
                metrics.fullSnapshots = metrics.fullSnapshots + 1
                if cfg.mixedCapabilities and targetPlayer == players[2] then
                    metrics.fallbackSnapshots = metrics.fallbackSnapshots + 1
                end
                local ev = type(payload) == "table" and tostring(payload.event or "") or ""
                if ev == "repair" or ev == "reconnect" or ev == "gap_repair"
                    or ev == "unsupported_delta" or ev == "missing_baseline"
                    or ev == "incarnation_mismatch"
                then
                    metrics.repairSnapshots = metrics.repairSnapshots + 1
                end
            end
        elseif command == "RosterDelta" then
            metrics.rosterDeltas = metrics.rosterDeltas + 1
        end
    end
    triggerEvent = function() end

    -- Configure profiler mode BEFORE loading Core/Hoomans.
    if cfg.profilerMode == "COARSE" then
        PSYCHOPATZ_PROFILER_MODE = "BASIC"
    elseif cfg.profilerMode == "DEEP" then
        PSYCHOPATZ_PROFILER_MODE = "DETAILED"
        PSYCHOPATZ_PROFILER_PERFORMANCE_DEPTH = "deep"
        PSYCHOPATZ_PROFILER_DEEP_DURATION_MS = cfg.deepDurationMs
    else
        PSYCHOPATZ_PROFILER_MODE = nil
    end

    local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
    Bootstrap.Initialize()

    require "PsychopatzCore/Runtime/PC_RuntimeRole"
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
    local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
    PsychopatzCore.Actors = Actors
    local actorRegistry = Actors.DefaultRegistry or Actors.NewRegistry()
    Actors.DefaultRegistry = actorRegistry

    local massInterestCount = cfg.massInterestActors and math.floor(cfg.massInterestActors) or nil
    for i = 1, cfg.actorCount do
        local x, y
        if massInterestCount and i <= massInterestCount then
            x = 10002 + ((i - 1) % 8)
            y = 10000 + math.floor((i - 1) / 8)
        elseif i <= cfg.expectedPromotedActors then
            x = 10002 + i
            y = 10000
        elseif i <= cfg.expectedPromotedActors + cfg.nearbyActors then
            x = 10030 + ((i - cfg.expectedPromotedActors) % 10)
            y = 10000
        else
            x = 15000 + i * 10
            y = 15000
        end
        actorRegistry:Create({
            actorId = "sim_actor_" .. tostring(i),
            identitySeed = "sim_seed_" .. tostring(i),
            archetypeID = "core.survivor",
            world = { position = { x = x, y = y, z = 0 } },
            extensions = {
                ["PsychopatzCore.SurvivorWorld"] = {
                    factionID = "fac_sim_1",
                    communityID = "com_sim_1",
                    groupID = "grp_sim_" .. tostring(math.ceil(i / 5)),
                    role = "member",
                },
            },
        })
    end

    require "PNC/00_PNC_Init"
    require "PNC/Composition/PNC_ServerComposition"

    local runtimeStore = PsychopatzCore
        and PsychopatzCore.Actors
        and PsychopatzCore.Actors.RuntimeStore
    if runtimeStore and type(runtimeStore.Save) == "function" then
        local origRuntimeStoreSave = runtimeStore.Save
        runtimeStore.Save = function(...)
            metrics.coreRuntimeStoreSaves = metrics.coreRuntimeStoreSaves + 1
            return origRuntimeStoreSave(...)
        end
    end

    local rawServerOnTick = PNC.Server.OnTick
    if PNC.ProfilerIntegration and PNC.ProfilerIntegration._serverTickHook then
        rawServerOnTick = PNC.ProfilerIntegration._serverTickHook.original
    end

    local startupCpuStart = os.clock()
    for _, fn in ipairs(events.OnInitGlobalModData or {}) do fn() end
    for _, fn in ipairs(events.OnServerStarted or {}) do fn() end
    if cfg.mixedCapabilities and PNC.ServerCommandRouter and PNC.ServerCommandRouter.Handle then
        if players[1] then
            PNC.ServerCommandRouter.Handle(PNC.Const.CMD_FULL_SYNC_REQUEST, players[1], {
                domainDeltaProtocol = PNC.Const.DOMAIN_DELTA_PROTOCOL or 1,
                portraitProtocol = PNC.Const.ROSTER_PORTRAIT_PROTOCOL,
            })
        end
        if players[2] then
            PNC.ServerCommandRouter.Handle(PNC.Const.CMD_FULL_SYNC_REQUEST, players[2], {
                domainDeltaProtocol = 0,
            })
        end
    end
    local startupCpuMs = (os.clock() - startupCpuStart) * 1000
    snapshotStoreWrites()
    local promotedAtStartup = countMap(PNC.Registry and PNC.Registry.Data)
    local peakPromotedHoomansRecords = promotedAtStartup
    local maxPromotionsInSingleRefresh = 0
    local maxMaterializationsInSingleTick = 0
    local departed = false

    local Integration = PNC.ProfilerIntegration
    local initialWrapperCounts = Integration
        and Integration.GetInstalledWrapperCounts
        and Integration.GetInstalledWrapperCounts()
        or { total = 0, coarse = 0, deep = 0 }
    local Profiler = rawget(PsychopatzCore, "Profiler")
    local initialSnapshot = Profiler and Profiler.BuildSnapshot and Profiler.BuildSnapshot() or nil

    local censusGenerationStart = PNC.WorldCensus and tonumber(PNC.WorldCensus.Generation) or 0

    local coordMetrics = PNC.PersistenceCoordinator
        and PNC.PersistenceCoordinator.Metrics or {}
    local observedPumpRuns = tonumber(coordMetrics.pumpRuns) or 0

    local function driveCommit(reason)
        PNC.PersistenceCoordinator.Commit(reason)
    end

    local mutationEvents = {
        "attack_start",
        "combat_damage",
        "equipment_changed",
        "wound_treated",
        "attack_finish",
        "reload_finished",
        "medical_care_treating",
        "weapon_restore_ranged",
        "self_bandaged",
        "position_recovery",
    }
    local mutationIndex = 0
    local gapRepairInjected = false

    metrics.inTickPhase = true
    local tickCpuStart = os.clock()
    local totalTicks = math.floor(cfg.simulatedMs / cfg.stepMs)
    local startMs = nowMs
    for tick = 1, totalTicks do
        nowMs = nowMs + cfg.stepMs
        local elapsedMs = nowMs - startMs
        if cfg.departAtMs and not departed and elapsedMs >= cfg.departAtMs then
            departed = true
            local p1 = players[1]
            if p1 and p1._setX then
                p1._setX(12000)
                if p1._setY then p1._setY(12000) end
            end
        end
        local matBeforeTick = metrics.materializationSuccesses
        for _, fn in ipairs(events.OnTick or {}) do
            fn()
        end
        local matDelta = metrics.materializationSuccesses - matBeforeTick
        if matDelta > maxMaterializationsInSingleTick then
            maxMaterializationsInSingleTick = matDelta
        end
        local refreshPromos = tonumber(
            PNC.Presence and PNC.Presence.Internal
                and PNC.Presence.Internal.lastRefreshPromotions
        ) or 0
        if refreshPromos > maxPromotionsInSingleRefresh then
            maxPromotionsInSingleRefresh = refreshPromos
        end
        local promotedNow = countMap(PNC.Registry and PNC.Registry.Data)
        if promotedNow > peakPromotedHoomansRecords then
            peakPromotedHoomansRecords = promotedNow
        end
        if nowMs % 1000 == 0 then
            local p1 = players[1]
            if p1 and p1._setX and not departed then
                p1._setX(10000 + ((math.floor(tick / 20)) % 4))
            end
            for _, fn in ipairs(events.EveryOneSecond or {}) do
                fn()
            end
        end
        if nowMs % cfg.mutationIntervalMs == 0 then
            mutationIndex = mutationIndex + 1
            local targetRecord
            for _, rec in pairs(PNC.Registry.Data or {}) do
                if rec.presenceState == PNC.Const.PRESENCE_LIVE then
                    targetRecord = rec
                    break
                end
            end
            if not targetRecord then
                targetRecord = PNC.Registry.Get("sim_actor_1")
            end
            if targetRecord then
                local evName = mutationEvents[((mutationIndex - 1) % #mutationEvents) + 1]
                PNC.Network.BroadcastRecord(targetRecord, evName)
            end
        end
        if cfg.injectRevisionGap
            and not gapRepairInjected
            and elapsedMs >= math.floor(cfg.simulatedMs * 0.65)
            and PNC.ServerCommandRouter
            and PNC.ServerCommandRouter.Handle
            and PNC.Const.CMD_REQUEST_RECORD_REPAIR
        then
            local repairTarget = PNC.Registry.Get("sim_actor_1")
            if not repairTarget then
                for _, rec in pairs(PNC.Registry.Data or {}) do
                    repairTarget = rec
                    break
                end
            end
            if repairTarget and players[1] then
                gapRepairInjected = true
                PNC.ServerCommandRouter.Handle(
                    PNC.Const.CMD_REQUEST_RECORD_REPAIR,
                    players[1],
                    { id = repairTarget.id, reason = "gap_repair" }
                )
            end
        end
        if nowMs % cfg.knowledgeMutationIntervalMs == 0 then
            if PNC.NPCKnowledge and PNC.NPCKnowledge.RecordGiftPreferences then
                local stepBucket = math.floor(nowMs / cfg.knowledgeMutationIntervalMs)
                local ok = PNC.NPCKnowledge.RecordGiftPreferences(
                    "player_uuid_sim",
                    "sim_actor_1",
                    { ["Base.TinCan"] = (stepBucket % 2 == 0) and "like" or "dislike" },
                    "gift_reaction",
                    "sim_gift_" .. tostring(nowMs),
                    math.floor(nowMs / 1000)
                )
                if not ok then PNC.NPCKnowledge.Dirty = true end
            elseif PNC.NPCKnowledge then
                PNC.NPCKnowledge.Dirty = true
            end
            driveCommit("sim_knowledge_mutation")
        end
        if (tonumber(coordMetrics.pumpRuns) or 0) > observedPumpRuns then
            observedPumpRuns = tonumber(coordMetrics.pumpRuns) or 0
            snapshotStoreWrites()
        end
    end
    local tickLoopCpuMs = (os.clock() - tickCpuStart) * 1000
    metrics.inTickPhase = false

    -- Fire OnSave (real pre-save body retirement + Coordinator.Commit("world_save")).
    for _, fn in ipairs(events.OnSave or {}) do
        fn()
    end
    snapshotStoreWrites()

    local endWrapperCounts = Integration
        and Integration.GetInstalledWrapperCounts
        and Integration.GetInstalledWrapperCounts()
        or { total = 0, coarse = 0, deep = 0 }
    local endSnapshot = Profiler and Profiler.BuildSnapshot and Profiler.BuildSnapshot() or nil

    local coarseCalls, deepCalls = 0, 0
    if Profiler and Profiler.GetMetrics then
        for _, metric in ipairs(Profiler.GetMetrics("timer", "ProjectHoomans")) do
            if COARSE_METRICS[metric.name] then
                coarseCalls = coarseCalls + (tonumber(metric.calls) or 0)
            else
                deepCalls = deepCalls + (tonumber(metric.calls) or 0)
            end
        end
    end

    local savedOriginals = {}
    for metricName, entry in pairs(Integration and Integration.originals or {}) do
        savedOriginals[metricName] = entry
    end

    local restoredCleanly = true
    if Profiler ~= nil then
        Bootstrap.Disable()
        local postDisableCounts = Integration
            and Integration.GetInstalledWrapperCounts
            and Integration.GetInstalledWrapperCounts()
            or { total = 0, coarse = 0, deep = 0 }
        if postDisableCounts.total ~= 0 or Profiler.IsRunning() then
            restoredCleanly = false
        end
        for _, entry in pairs(savedOriginals) do
            if entry.owner[entry.key] ~= entry.callback then
                restoredCleanly = false
            end
        end
        if PNC.Server.OnTick ~= rawServerOnTick then
            restoredCleanly = false
        end
        local onTickFound = false
        for _, fn in ipairs(events.OnTick or {}) do
            if fn == rawServerOnTick then onTickFound = true end
        end
        if not onTickFound then restoredCleanly = false end
    else
        restoredCleanly = Integration == nil
            or (Integration.originals == nil and Integration._serverTickHook == nil)
    end

    local diagCounters = PNC.PerformanceScalingDiagnostics
        and PNC.PerformanceScalingDiagnostics.Counters or {}
    local censusScans = (PNC.WorldCensus and tonumber(PNC.WorldCensus.Generation) or 0)
        - censusGenerationStart
    local extraZombieListQueries = math.max(0, metrics.zombieListQueriesTick - censusScans)

    local coreProvider = PNC.Persistence and PNC.Persistence.CoreProvider or nil
    local coreMetrics = coreProvider and coreProvider.Metrics or {}
    local finalCoordMetrics = PNC.PersistenceCoordinator
        and PNC.PersistenceCoordinator.Metrics or {}
    local finalRegMetrics = PNC.Registry
        and PNC.Registry.PersistenceMetrics or {}
    local serAttempts = (tonumber(finalRegMetrics.written) or 0)
        + (tonumber(finalRegMetrics.terminal) or 0)
        + (tonumber(finalRegMetrics.retryable) or 0)
    local endPromotedHoomansRecords = countMap(PNC.Registry and PNC.Registry.Data)
    local schedulerMembersAtEnd = countMap(PNC.Scheduler and PNC.Scheduler.SlotByID)
    local spatialMembersAtEnd = countMap(PNC.SpatialIndex and PNC.SpatialIndex.NPCMembership)
    local promotionsCount = tonumber(coreMetrics.promotions) or 0
    local demotionsCount = tonumber(coreMetrics.demotions) or 0
    local coreExtensionsAttached = 0
    if type(actorRegistry.ListWithExtension) == "function" then
        coreExtensionsAttached = #actorRegistry:ListWithExtension("ProjectHoomans.ActorExtension")
    end

    local report = {
        CoreActors = actorRegistry:Count(),
        PromotedAtStartup = promotedAtStartup,
        PromotedHoomansRecords = endPromotedHoomansRecords,
        PeakPromotedHoomansRecords = peakPromotedHoomansRecords,
        EndPromotedHoomansRecords = endPromotedHoomansRecords,
        SchedulerMembersAtEnd = schedulerMembersAtEnd,
        SpatialMembersAtEnd = spatialMembersAtEnd,
        LiveBodies = countMap(PNC.Registry and PNC.Registry.LiveByID),
        SchedulerProcessed = tonumber(diagCounters["Scheduler.DueProcessed"]) or 0,
        SchedulerDeferred = tonumber(diagCounters["Scheduler.Deferred"]) or 0,
        PromotionAttempts = promotionsCount,
        Promotions = promotionsCount,
        PromotionsCount = promotionsCount,
        Demotions = demotionsCount,
        DemotionsCount = demotionsCount,
        MaxPromotionsInSingleRefresh = maxPromotionsInSingleRefresh,
        MaxMaterializationsInSingleTick = maxMaterializationsInSingleTick,
        CoreExtensionsAttached = coreExtensionsAttached,
        MaterializationAttempts = tonumber(
            PNC.Presence and PNC.Presence.Metrics
                and PNC.Presence.Metrics.materializeAttempts
        ) or 0,
        Materializations = metrics.materializationSuccesses,
        SpatialRebuilds = tonumber(
            PNC.SpatialIndex and PNC.SpatialIndex.RebuildCount
        ) or 0,
        ZombieAggroProcessed = tonumber(diagCounters["ZombieAggro.ProcessedCount"]) or 0,
        LogicalCommits = tonumber(finalCoordMetrics.logicalCommits) or 0,
        DirtyDomainMarks = tonumber(finalCoordMetrics.dirtyDomainMarks) or 0,
        PersistencePumps = tonumber(finalCoordMetrics.pumpRuns) or 0,
        ImmediateFlushes = tonumber(finalCoordMetrics.immediateFlushes) or 0,
        CoalescedCommits = tonumber(finalCoordMetrics.coalescedCommits) or 0,
        SerializationAttempts = serAttempts,
        PhysicalWrites = metrics.physicalWrites,
        GlobalSaveCalls = metrics.globalSaveCalls,
        CoreRuntimeStoreSaves = metrics.coreRuntimeStoreSaves,
        CheckpointScans = tonumber(finalRegMetrics.checkpointScans) or 0,
        RetryablePersistenceFailures = tonumber(finalRegMetrics.retryable) or 0,
        RetryAttemptsScheduled = tonumber(finalRegMetrics.retriesScheduled) or 0,
        TerminalPersistenceOutcomes = tonumber(finalRegMetrics.terminal) or 0,
        DirtyRecordsEnd = countMap(PNC.Registry and PNC.Registry.DirtyByID),
        PresenceDeltas = metrics.presenceDeltas,
        CombatDamageDeltas = metrics.combatDamageDeltas,
        CombatStateDeltas = metrics.combatStateDeltas,
        CombatDeltas = metrics.combatDeltas,
        HealthOrWoundDeltas = metrics.healthOrWoundDeltas,
        EquipmentDeltas = metrics.equipmentDeltas,
        FullSnapshots = metrics.fullSnapshots,
        RepairSnapshots = metrics.repairSnapshots,
        FallbackSnapshots = metrics.fallbackSnapshots,
        RosterDeltas = metrics.rosterDeltas,
        PacketsSent = metrics.packetsSent,
        CensusScans = censusScans,
        PerNpcGlobalZombieScans = extraZombieListQueries,
        SafePhaseFailures = PNC.Server.Internal.SafePhaseDiagnostics.totalFailures,
        ProfilerMode = cfg.profilerMode,
        ProfilerLoaded = Profiler ~= nil,
        InitialCoarseWrappersInstalled = initialWrapperCounts.coarse,
        InitialDeepWrappersInstalled = initialWrapperCounts.deep,
        EndCoarseWrappersInstalled = endWrapperCounts.coarse,
        EndDeepWrappersInstalled = endWrapperCounts.deep,
        ProfilerCoarseWrapperCalls = coarseCalls,
        ProfilerDeepWrapperCalls = deepCalls,
        DeepExpired = endSnapshot ~= nil
            and endSnapshot.runtime ~= nil
            and endSnapshot.runtime.instrumentation ~= nil
            and endSnapshot.runtime.instrumentation.deepExpired == true
            or false,
        InitialTimingLabel = initialSnapshot and initialSnapshot.runtime
            and initialSnapshot.runtime.instrumentation
            and initialSnapshot.runtime.instrumentation.timingLabel or "off",
        EndTimingLabel = endSnapshot and endSnapshot.runtime
            and endSnapshot.runtime.instrumentation
            and endSnapshot.runtime.instrumentation.timingLabel or "off",
        RestoredCleanly = restoredCleanly,
        StartupCpuMs = startupCpuMs,
        TickLoopCpuMs = tickLoopCpuMs,
        TotalCpuMs = startupCpuMs + tickLoopCpuMs,
    }

    print = originalPrint
    Simulator.ResetEnvironment()
    return report
end

function Simulator.FormatSummary(report)
    return string.format(
        "mode=%s core=%d startProm=%d peakProm=%d endProm=%d demoted=%d schedEnd=%d spatialEnd=%d live=%d matAtt=%d matOk=%d schedProc=%d schedDef=%d commits=%d pumps=%d serAttempts=%d physWrites=%d globalSaves=%d coreSaves=%d term=%d retry=%d dirtyEnd=%d presD=%d combatD=%d hwD=%d eqD=%d fullSnap=%d repSnap=%d fbSnap=%d census=%d extraZScans=%d zAggro=%d coarseCalls=%d deepCalls=%d tickCpuMs=%.2f",
        tostring(report.ProfilerMode),
        report.CoreActors,
        report.PromotedAtStartup or 0,
        report.PeakPromotedHoomansRecords or report.PromotedHoomansRecords or 0,
        report.EndPromotedHoomansRecords or report.PromotedHoomansRecords or 0,
        report.DemotionsCount or 0,
        report.SchedulerMembersAtEnd or 0,
        report.SpatialMembersAtEnd or 0,
        report.LiveBodies,
        report.MaterializationAttempts or 0,
        report.Materializations or 0,
        report.SchedulerProcessed,
        report.SchedulerDeferred,
        report.LogicalCommits,
        report.PersistencePumps or 0,
        report.SerializationAttempts,
        report.PhysicalWrites,
        report.GlobalSaveCalls,
        report.CoreRuntimeStoreSaves or 0,
        report.TerminalPersistenceOutcomes or 0,
        report.RetryablePersistenceFailures or 0,
        report.DirtyRecordsEnd,
        report.PresenceDeltas,
        report.CombatDeltas,
        report.HealthOrWoundDeltas or 0,
        report.EquipmentDeltas or 0,
        report.FullSnapshots,
        report.RepairSnapshots or 0,
        report.FallbackSnapshots or 0,
        report.CensusScans,
        report.PerNpcGlobalZombieScans,
        report.ZombieAggroProcessed or 0,
        report.ProfilerCoarseWrapperCalls,
        report.ProfilerDeepWrapperCalls,
        report.TickLoopCpuMs
    )
end

return Simulator
