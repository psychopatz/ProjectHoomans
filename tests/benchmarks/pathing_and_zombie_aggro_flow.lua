-- Repeatable CPU micro-benchmark and pathing / zombie-aggro / multi-NPC contention verifier.
-- Usage:
--   lua tests/benchmarks/pathing_and_zombie_aggro_flow.lua [--baseline]
local T = require "tests/support/test"

local BASELINE_MODE = false
for i = 1, #(arg or {}) do
    if arg[i] == "--baseline" then BASELINE_MODE = true end
end

T.addPackagePaths()

local failures = {}
local function check(cond, msg)
    if not cond then
        failures[#failures + 1] = tostring(msg)
        print("[FAIL] " .. tostring(msg))
    end
end

local function msSince(t0)
    return (os.clock() - t0) * 1000.0
end

local nowMs = 10000
local mpClient = false
local mpServer = false
local currentCell = nil
local activePlayer = nil

isClient = function() return mpClient end
isServer = function() return mpServer end
getTimeInMillis = function() return nowMs end
getTimestampMs = function() return nowMs end
getCell = function() return currentCell end
getPlayer = function() return activePlayer end
getOnlinePlayers = function() return nil end
getText = function(k) return k end
getCurrentSaveName = function() return "bench-pathing" end

local classLookup = setmetatable({}, { __mode = "k" })
instanceof = function(obj, className)
    return obj ~= nil and (obj.__class == className or classLookup[obj] == className)
end

Events = Events or {}
for _, evName in ipairs({
    "OnTick", "OnResetLua", "OnZombieUpdate",
    "OnServerStarted", "OnClientCommand", "OnServerCommand",
}) do
    Events[evName] = Events[evName] or {
        Add = function() end,
        Remove = function() end,
    }
end

local function distSq2(x1, y1, x2, y2)
    local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
    local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return dx * dx + dy * dy
end

local env = {
    zombies = {},
    npcs = {},
    managed = {},
    blocksLos = false,
}

local function makeSquare(x, y, z, opts)
    opts = opts or {}
    local sq = {
        _x = x, _y = y, _z = z or 0,
        _doorTo = opts.doorTo or {},
        _windowTo = opts.windowTo or {},
        _fenceTo = opts.fenceTo or {},
        _specialTo = opts.specialTo or {},
        _wall = opts.wall == true,
        _dirty = 0,
        _recalc = 0,
        getX = function(self) return self._x end,
        getY = function(self) return self._y end,
        getZ = function(self) return self._z end,
        isSomethingTo = function(_, _) return env.blocksLos == true end,
        getDoorTo = function(self, other)
            if opts.onDoorQuery then opts.onDoorQuery(self, other) end
            return self._doorTo[other]
        end,
        getWindowTo = function(self, other)
            if opts.onWindowQuery then opts.onWindowQuery(self, other) end
            return self._windowTo[other]
        end,
        getWindowThumpableTo = function() return nil end,
        getHoppableTo = function(self, other)
            if opts.onFenceQuery then opts.onFenceQuery(self, other) end
            return self._fenceTo[other]
        end,
        getWallHoppableTo = function() return nil end,
        getHoppableThumpableTo = function() return nil end,
        testCollideSpecialObjects = function(self, other)
            if opts.onSpecialCollide then opts.onSpecialCollide(self, other) end
            return self._specialTo[other]
        end,
        InvalidateSpecialObjectPaths = function(self) self._dirty = self._dirty + 1 end,
        RecalcProperties = function(self) self._recalc = self._recalc + 1 end,
        getObjects = function() return { size = function() return 0 end } end,
    }
    return sq
end

local function makeCell()
    local squares = {}
    local cellObj = {
        squares = squares,
        getGridSquare = function(self, x, y, z)
            local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z or 0)
            local sq = self.squares[key]
            if not sq then
                sq = makeSquare(x, y, z or 0)
                self.squares[key] = sq
            end
            return sq
        end,
        getZombieList = function()
            local list = env.zombies
            return {
                size = function() return #list end,
                get = function(_, idx) return list[idx + 1] end,
            }
        end,
    }
    return cellObj
end

currentCell = makeCell()

local function makeZombieBody(id, x, y, opts)
    opts = opts or {}
    local sq = opts.square or currentCell:getGridSquare(math.floor(x), math.floor(y), 0)
    local md = { PNC_ZombieID = tostring(id) }
    local body = {
        _id = tostring(id),
        _x = x, _y = y, _z = 0,
        _square = sq,
        _feeler = opts.feeler,
        _target = nil,
        _attackedBy = nil,
        _actionState = opts.actionState or "idle",
        _pathRequests = 0,
        _pathCharRequests = 0,
        _hasPath2 = opts.hasPath2 == true,
        _fwdX = opts.fwdX or 1,
        _fwdY = opts.fwdY or 0,
        getX = function(self) return self._x end,
        getY = function(self) return self._y end,
        getZ = function(self) return self._z end,
        setX = function(self, v) self._x = v end,
        setY = function(self, v) self._y = v end,
        setZ = function(self, v) self._z = v end,
        isDead = function() return false end,
        isAlive = function() return true end,
        isProne = function() return false end,
        isUseless = function() return false end,
        setUseless = function() end,
        isReanimatedForGrappleOnly = function() return false end,
        isOutside = function() return true end,
        getModData = function(self) return md end,
        getCurrentSquare = function(self) return self._square end,
        getSquare = function(self) return self._square end,
        getFeelerTile = function(self) return self._feeler end,
        getFeelersize = function() return 0.5 end,
        getOnlineID = function() return 0 end,
        getActionStateName = function(self) return self._actionState end,
        getCurrentActionContextStateName = function(self) return self._actionState end,
        getTarget = function(self) return self._target end,
        setTarget = function(self, v) self._target = v end,
        setTargetSeenTime = function() end,
        getAttackedBy = function(self) return self._attackedBy end,
        setAttackedBy = function(self, v) self._attackedBy = v end,
        getPath2 = function(self) return self._hasPath2 and {} or nil end,
        setPath2 = function(self, v) self._hasPath2 = v ~= nil end,
        pathToLocationF = function(self)
            self._pathRequests = self._pathRequests + 1
            self._hasPath2 = true
        end,
        getPathFindBehavior2 = function(self)
            if not self._behavior2 then
                self._behavior2 = {
                    cancel = function() end,
                    reset = function() end,
                    pathToLocationF = function()
                        self._pathRequests = self._pathRequests + 1
                        self._hasPath2 = true
                    end,
                }
            end
            return self._behavior2
        end,
        pathToCharacter = function(self, target)
            self._target = target
            self._pathCharRequests = self._pathCharRequests + 1
            self._hasPath2 = true
        end,
        faceLocationF = function() end,
        faceThisObject = function() end,
        setTurnDelta = function() end,
        getVariableBoolean = function() return false end,
        setVariable = function() end,
        CanSee = function() return true end,
        isFacingObject = function() return true end,
        getForwardDirection = function(self)
            return {
                getX = function() return self._fwdX end,
                getY = function() return self._fwdY end,
            }
        end,
        clearAggroList = function() end,
        setNoTeeth = function() end,
        isOnFloor = function() return false end,
        isCrawling = function() return false end,
        playSound = function() end,
        isRemoteZombie = function() return false end,
        isVariable = function() return false end,
    }
    if opts.isManaged then
        env.managed[body] = true
    end
    return body
end

-- Seed PNC core harness before loading production modules
PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ZOMBIE_AGGRO_RADIUS = 16,
        ZOMBIE_AGGRO_ACTIVE_REFRESH_MS = 250,
        ZOMBIE_AGGRO_ACTIVE_TTL_MS = 1500,
        ZOMBIE_AGGRO_MAX_PER_TICK = 40,
        ZOMBIE_AGGRO_PATH_REQUESTS_PER_TICK = 24,
        ZOMBIE_NPC_AGGRO_LEASE_MS = 8000,
        ZOMBIE_NPC_COMMIT_RADIUS = 14,
        ZOMBIE_NPC_PLAYER_RECLAIM_RADIUS = 2.4,
        ZOMBIE_AGGRO_KEEP_RADIUS = 2.4,
        ZOMBIE_TARGET_PLAYER_KEEP_RADIUS = 2.0,
        ZOMBIE_NPC_PATH_REFRESH_MS = 350,
        ZOMBIE_NPC_PATH_REFRESH_DISTANCE = 0.6,
        ZOMBIE_NPC_PATH_STABLE_RETRY_MS = 1500,
        ZOMBIE_NPC_DIRECTIVE_SEND_MS = 400,
        ZOMBIE_NPC_DIRECTIVE_TTL_MS = 1100,
        ZOMBIE_NPC_STIMULUS_INTERVAL_MS = 500,
        ZOMBIE_NPC_STIMULUS_RADIUS = 14,
        ZOMBIE_NPC_STIMULUS_VOLUME = 1,
        ZOMBIE_ATTACK_RANGE = 0.95,
        ZOMBIE_ATTACK_COOLDOWN_MS = 1500,
        ZOMBIE_BITE_APPLY_DELAY_MS = 450,
        ZOMBIE_BITE_CLEAR_DELAY_MS = 700,
        ZOMBIE_BITE_DISTANCE = 0.8,
        ZOMBIE_ATTACKER_OBSERVATION_MS = 1500,
        COMBAT_FORMATION_QUERY_RADIUS = 2.4,
        COMBAT_FORMATION_SLOT_RADIUS = 1.05,
        MELEE_APPROACH_STOP_DISTANCE = 0.92,
        MELEE_FORMATION_STOP_DISTANCE = 0.45,
        ZOMBIE_AGGRO_SCAN_CELL_ZOMBIES = true,
    },
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return not mpClient end,
        IsClientOnly = function() return mpClient and not mpServer end,
        Distance = function(x1, y1, x2, y2) return math.sqrt(distSq2(x1, y1, x2, y2)) end,
        DistanceSq = distSq2,
        IsManagedNPCBody = function(body) return env.managed[body] == true end,
        GenerateID = function() return "id-" .. tostring(nowMs) end,
        LogWarn = function() end,
        LogDebug = function() end,
    },
    Sandbox = {
        CanZombieTargetRecord = function() return true end,
    },
    Stealth = {},
    Compatibility = {
        ActorOwnership = {
            IsForeignOwned = function() return false end,
            GetForeignOwner = function() return nil end,
        },
    },
    PerformanceScalingDiagnostics = { Increment = function() end },
    CombatZombieReaction = { IsActive = function() return false end },
    Registry = {
        Data = {},
        LiveByID = {},
        DirtyDomains = {},
        ForEachLive = function(cb)
            for _, rec in ipairs(env.npcs) do
                cb(rec, env.managed[rec._body] and rec._body or rec._body)
            end
        end,
        Get = function(id)
            return PNC.Registry.Data[tostring(id)]
        end,
        GetLiveZombie = function(id)
            local rec = PNC.Registry.Data[tostring(id)]
            return rec and rec._body or nil
        end,
        FindRecordByZombie = function(body)
            for _, rec in ipairs(env.npcs) do
                if rec._body == body then return rec end
            end
            return nil
        end,
    },
    SpatialIndex = {
        QueryZombies = function(x, y, radius)
            local out = {}
            local rSq = (tonumber(radius) or 16) ^ 2
            for _, z in ipairs(env.zombies) do
                if distSq2(x, y, z:getX(), z:getY()) <= rSq then
                    out[#out + 1] = z
                end
            end
            return out
        end,
        QueryNPCs = function(x, y, radius)
            local out = {}
            local rSq = (tonumber(radius) or 16) ^ 2
            for _, rec in ipairs(env.npcs) do
                if distSq2(x, y, rec.x, rec.y) <= rSq then
                    out[#out + 1] = rec
                end
            end
            return out
        end,
    },
    Perception = {
        IsActualZombieBody = function(z)
            return z ~= nil and env.managed[z] ~= true
        end,
        PublishZombieGroupAlert = function() end,
    },
    WorldCensus = {
        GetNearestNPC = function() return nil end,
    },
}

-- Load production ZombieAggro stack
T.load("ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro.lua")

-- Configure ClientPresenceSync hooks before loading ClientZombieAggroController_Update
local clientCalls = { safety = 0, targetLookups = 0, directives = 0, safetyOnManaged = 0 }
PNC.ClientPresenceSync = {
    Internal = {
        Effects = {
            EnforceManagedSafetyGuard = function(z)
                clientCalls.safety = clientCalls.safety + 1
                if env.managed[z] then clientCalls.safetyOnManaged = clientCalls.safetyOnManaged + 1 end
                return env.managed[z] == true
            end,
            ApplyCoordinateDirective = function()
                clientCalls.directives = clientCalls.directives + 1
                return true
            end,
            ApplySingleplayerAggro = function() return true end,
            ApplyPlayerTarget = function() end,
            ReleaseManagedTarget = function() end,
            HandoffToNativePlayer = function() end,
        },
        TargetIndex = {
            Rebuild = function() end,
        },
        AggroTierMS = 100,
        AggroTierCount = 4,
        IsForeignOwnedBody = function() return false end,
        IsMultiplayerMode = function() return mpClient or mpServer end,
        IsStandaloneSingleplayer = function() return not mpClient and not mpServer end,
        FindNearestTarget = function()
            clientCalls.targetLookups = clientCalls.targetLookups + 1
            return nil, math.huge, false
        end,
        GetPursuitDirective = function()
            clientCalls.directives = clientCalls.directives + 1
            return nil
        end,
        LogPursuitDiagnostic = function() end,
    },
}
local ClientUpdate = T.load("ProjectHoomans", "client",
    "PNC/PresenceSync/PNC_ClientZombieAggroController_Update.lua")

-- Load TraversalQuery + PathService + EnginePathPlanner Passage + LiveBodyControl Probe
local edgeCanOccupy = function() return true end
local edgeCanStep = function() return true, nil end
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Internal.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Objects.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Passages.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Fences.lua")
PNC.TraversalQuery.CanOccupy = function(x, y, z) return edgeCanOccupy(x, y, z) end
PNC.TraversalQuery.CanStep = function(fx, fy, fz, tx, ty, tz) return edgeCanStep(fx, fy, fz, tx, ty, tz) end

PNC.PathService = {
    Internal = {
        Core = PNC.Core,
        SPECIAL_ACTION_COOLDOWN_MS = 500,
        describeSquare = function(sq)
            return sq and (tostring(sq:getX()) .. "," .. tostring(sq:getY()) .. "," .. tostring(sq:getZ())) or "nil"
        end,
        describePoint = function(x, y, z) return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z) end,
        passageObstacleSquareKey = function(sq)
            return sq and (tostring(sq:getX()) .. ":" .. tostring(sq:getY()) .. ":" .. tostring(sq:getZ())) or nil
        end,
        logMoveDebug = function() end,
        rememberTraversalIssue = function() end,
        noteTraversalAttempt = function() end,
        isInteriorBoundaryBlocked = function() return false end,
        tryWindowBreach = function() return nil, nil, false end,
        hasRepeatedTraversalFailure = function() return false end,
        beginTraversalAction = function(_, _, lane, spec)
            lane.ownerMode = spec.kind
            lane.specialMoveUntil = nowMs + (tonumber(spec.travelDurationMs) or 700)
            lane.traversalAction = {
                kind = spec.kind,
                finishAt = nowMs + (tonumber(spec.travelDurationMs) or 700),
            }
            return true
        end,
        updateTraversalAction = function(_, _, lane, now)
            local act = lane.traversalAction
            if not act then return false, nil end
            if now >= (tonumber(act.finishAt) or now) then
                lane.traversalAction = nil
                lane.ownerMode = "fake_locomotion"
                lane.specialMoveUntil = 0
                lane.lastTraversalFinishReason = "arrived"
                return false, "completed"
            end
            return true, act.kind
        end,
    },
}
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/PNC_PathService/Interactions/PNC_PathService_PassagePolicy.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/PNC_PathService/Interactions/PNC_PathService_PassageObjects.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/PNC_PathService/Interactions/PNC_PathService_PassageWindows.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/PNC_PathService/Interactions/PNC_PathService_PassageFences.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionPassage.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_Passage.lua")

PNC.LiveBodyControl = {
    Internal = {
        NATIVE_PASSAGE_STATES = { climbwindow = true, climbfence = true },
    },
}
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State_Passage_Probe.lua")

-- Load CombatTactics
PNC.Skills = { GetLevel = function() return 2 end, ResolveWeaponSkill = function() return "Blunt" end }
PNC.Stamina = { GetRatio = function() return 1 end, CanSpendAttack = function() return true end }
PNC.Relationships = { AreNPCsEnemies = function() return false end }
T.load("ProjectHoomans", "shared", "PNC/Core/Combat/CombatTactics/PNC_Combat_Tactics.lua")

-- Load Inventory Weights & Persistence CoreSocial
PNC.Inventory = {
    Internal = {
        normalizeItemWeightReduction = function(v) return tonumber(v) or 0 end,
        getItemWeight = function() return 1.0 end,
        buildBaseCarryWeight = function() return 18 end,
        ensureContainer = function() end,
        countMapEntries = function(t)
            local c = 0
            for _ in pairs(t or {}) do c = c + 1 end
            return c
        end,
    },
    EnsureRecordInventory = function()
        error("EnsureRecordInventory should not run on pre-hydrated fast path")
    end,
}
T.load("ProjectHoomans", "shared", "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items/PNC_Inventory_Items_Weights.lua")
PNC.EntityRef = PNC.EntityRef or {
    ForNPC = function(id) return "npc:" .. tostring(id) end,
    ForPlayer = function(id) return "player:" .. tostring(id) end,
    IsValid = function(k) return type(k) == "string" and k ~= "" end,
    IsCoreTargetValid = function(k) return type(k) == "string" and k ~= "" end,
    Parse = function(k)
        local kind, id = string.match(tostring(k or ""), "^([^:]+):(.+)$")
        if not kind or not id then return nil end
        return { key = tostring(k), kind = kind, targetID = id }
    end,
}
T.load("ProjectHoomans", "shared", "PNC/Core/Travel/PNC_Travel.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipConstants.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipTypes.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Persistence/PNC_Persistence_CoreSocial.lua")
local CoreActors = require "PsychopatzCore/Actors/PsychopatzActors"

local function populateCrowd(npcCount, zombieCount)
    env.npcs = {}
    env.zombies = {}
    env.managed = {}
    PNC.Registry.Data = {}
    PNC.Registry.LiveByID = {}
    if PNC.ZombieAggro.Reset then PNC.ZombieAggro.Reset() end
    for i = 1, npcCount do
        local x = ((i - 1) % 5) * 4 + 10
        local y = math.floor((i - 1) / 5) * 4 + 10
        local body = makeZombieBody("npc-" .. i, x, y, { isManaged = true })
        local rec = {
            id = "npc-" .. i,
            x = x, y = y, z = 0,
            alive = true,
            tacticalClass = "colonist",
            presenceState = "live",
            runtime = {},
            _body = body,
        }
        body:getModData().PNC_UUID = rec.id
        env.npcs[i] = rec
        PNC.Registry.Data[rec.id] = rec
        PNC.Registry.LiveByID[rec.id] = body
    end
    for i = 1, zombieCount do
        local npc = env.npcs[((i - 1) % npcCount) + 1]
        local zBody = makeZombieBody("z-" .. i, npc.x + 1.5, npc.y + 0.5)
        env.zombies[i] = zBody
        PNC.ZombieAggro.Activate(zBody, nowMs, "bench")
    end
end

print("=== 1. ZOMBIE AGGRO PUMP SCALING (20N/80Z vs 40N/120Z, 100 TICKS EACH) ===")
local function benchAggro(npcCount, zombieCount)
    populateCrowd(npcCount, zombieCount)
    local t0 = os.clock()
    local totalProcessed = 0
    for tick = 1, 100 do
        nowMs = 10000 + tick * 50
        local processed = PNC.ZombieAggro.Pump(nowMs)
        totalProcessed = totalProcessed + (tonumber(processed) or 0)
    end
    local elapsed = msSince(t0)
    local leased = 0
    for _, zb in ipairs(env.zombies) do
        local owner = PNC.ZombieAggro.Internal.GetPursuitLeaseFields(zb, nowMs)
        if owner == "ProjectHoomans" then leased = leased + 1 end
    end
    print(string.format("  %dN/%dZ: total=%.2fms (%.3fms/tick), processed=%d, leased=%d/%d",
        npcCount, zombieCount, elapsed, elapsed / 100.0, totalProcessed, leased, zombieCount))
    check(leased > 0, string.format("%dN/%dZ zombies acquired pursuit leases", npcCount, zombieCount))
    check(totalProcessed > 0, string.format("%dN/%dZ Pump processed active zombies", npcCount, zombieCount))
end
benchAggro(20, 80)
benchAggro(40, 120)

print("\n=== 2. CLOSE-RANGE WALL-BLOCKED ZOMBIE COOLDOWN ===")
env.npcs = {}
env.zombies = {}
env.managed = {}
PNC.Registry.Data = {}
PNC.Registry.LiveByID = {}
if PNC.ZombieAggro.Reset then PNC.ZombieAggro.Reset() end
env.blocksLos = true
local wallNpcSq = currentCell:getGridSquare(20, 20, 0)
local wallNpcBody = makeZombieBody("wall-npc", 20.5, 20.5, { isManaged = true, square = wallNpcSq })
local wallNpcRec = {
    id = "wall-npc", x = 20.5, y = 20.5, z = 0, alive = true,
    tacticalClass = "colonist", presenceState = "live", runtime = {}, _body = wallNpcBody,
}
wallNpcBody:getModData().PNC_UUID = wallNpcRec.id
env.npcs[1] = wallNpcRec
PNC.Registry.Data[wallNpcRec.id] = wallNpcRec
PNC.Registry.LiveByID[wallNpcRec.id] = wallNpcBody

local blockedZSq = currentCell:getGridSquare(19, 20, 0)
local blockedZ = makeZombieBody("blocked-z", 19.5, 20.5, { square = blockedZSq, hasPath2 = false })
env.zombies[1] = blockedZ
nowMs = 30000
PNC.ZombieAggro.Activate(blockedZ, nowMs, "wall_test")
local entryProcessedCount = 0
for step = 0, 39 do
    nowMs = 30000 + step * 50 -- 2000ms total across 40 x 50ms ticks
    local n = PNC.ZombieAggro.Pump(nowMs)
    entryProcessedCount = entryProcessedCount + (tonumber(n) or 0)
end
env.blocksLos = false
local pathCallsAfter = blockedZ._pathRequests
print(string.format("  close-blocked 2000ms @ 50ms steps: entryProcessed=%d, pathRequests=%d",
    entryProcessedCount, pathCallsAfter))
check(entryProcessedCount <= 15,
    "close-blocked zombie did not re-wake at 60Hz/every-50ms tick (processed=" .. tostring(entryProcessedCount) .. ")")
check(pathCallsAfter >= 1 and pathCallsAfter <= 2,
    "close-blocked zombie respected >=1500ms path retry backoff when hasPath2 (requests=" .. tostring(pathCallsAfter) .. ")")

print("\n=== 3. STANDALONE-SP CLIENT ZOMBIE AGGRO SHORT-CIRCUIT ===")
mpClient = false
mpServer = false
clientCalls = { safety = 0, targetLookups = 0, directives = 0, safetyOnManaged = 0 }
local spOrdZ = makeZombieBody("sp-ord", 30, 30)
local spNpcZ = makeZombieBody("sp-npc", 31, 30, { isManaged = true })
local tSp0 = os.clock()
for i = 1, 1000 do
    ClientUpdate.UpdateClientZombieAggro(spOrdZ, 40000 + i)
    if i <= 10 then
        ClientUpdate.UpdateClientZombieAggro(spNpcZ, 40000 + i)
    end
end
local tSpMs = msSince(tSp0)
print(string.format("  1010 SP client calls: %.2fms, safety=%d (managed=%d), targetLookups=%d, directives=%d",
    tSpMs, clientCalls.safety, clientCalls.safetyOnManaged, clientCalls.targetLookups, clientCalls.directives))
check(clientCalls.targetLookups == 0 and clientCalls.directives == 0,
    "standalone-SP client controller skipped pursuit/directive scanning")
check(clientCalls.safetyOnManaged == 10,
    "standalone-SP client controller still enforced managed safety guard")

print("\n=== 4. TRAVERSALQUERY EDGE CACHE & DOOR/WINDOW INVALIDATION ===")
local nativeQueries = { door = 0, window = 0, fence = 0 }
local doorSqA = makeSquare(5, 5, 0, {
    onDoorQuery = function() nativeQueries.door = nativeQueries.door + 1 end,
    onWindowQuery = function() nativeQueries.window = nativeQueries.window + 1 end,
    onFenceQuery = function() nativeQueries.fence = nativeQueries.fence + 1 end,
})
local doorSqB = makeSquare(6, 5, 0, {
    onDoorQuery = function() nativeQueries.door = nativeQueries.door + 1 end,
    onWindowQuery = function() nativeQueries.window = nativeQueries.window + 1 end,
    onFenceQuery = function() nativeQueries.fence = nativeQueries.fence + 1 end,
})
local emptySqC = makeSquare(7, 5, 0, {
    onDoorQuery = function() nativeQueries.door = nativeQueries.door + 1 end,
    onWindowQuery = function() nativeQueries.window = nativeQueries.window + 1 end,
})
local doorOpen = false
local sampleDoor = {
    __class = "IsoDoor",
    IsOpen = function() return doorOpen end,
    isOpen = function() return doorOpen end,
    couldBeOpen = function() return true end,
    isLocked = function() return false end,
    isLockedByKey = function() return false end,
    ToggleDoorSilent = function() doorOpen = true end,
    getSquare = function() return doorSqA end,
    getProperties = function() return { has = function() return false end, get = function() return nil end } end,
}
doorSqA._doorTo[doorSqB] = sampleDoor
PNC.TraversalQuery.InvalidateEdgeCache(nil)
nowMs = 50000
local tTq0 = os.clock()
for i = 1, 2000 do
    local p = PNC.TraversalQuery.GetPassageBetween(doorSqA, doorSqB)
    if i == 1 then check(p == sampleDoor, "GetPassageBetween returned door on miss") end
    local emptyP = PNC.TraversalQuery.GetPassageBetween(doorSqB, emptySqC)
    if i == 1 then check(emptyP == nil, "GetPassageBetween returned nil for clear edge") end
end
local tTqMs = msSince(tTq0)
print(string.format("  4000 cached edge lookups (hits + nil edges): %.2fms, native doorQueries=%d",
    tTqMs, nativeQueries.door))
check(nativeQueries.door <= 3,
    "TraversalQuery edge cache avoided repeated native door lookups (doorQueries=" .. tostring(nativeQueries.door) .. ")")

-- Mutate door via OpenDoorForNPC and verify immediate cache invalidation
local doorNpc = makeZombieBody("door-npc", 5.5, 5.5, { isManaged = true })
check(PNC.PathService.OpenDoorForNPC(doorNpc, sampleDoor) == true, "OpenDoorForNPC opened door")
doorSqA._doorTo[doorSqB] = nil -- simulate replaced/removed passage edge after mutation
local postMutPassage = PNC.TraversalQuery.GetPassageBetween(doorSqA, doorSqB)
check(postMutPassage == nil, "OpenDoorForNPC invalidated TraversalQuery edge cache immediately")
check(nativeQueries.door > 3, "post-invalidation query re-probed engine edge")

-- Window open & smash invalidation check
local winOpen = false
local winSmashed = false
local winObj = {
    __class = "IsoWindow",
    IsOpen = function() return winOpen end,
    isOpen = function() return winOpen end,
    isSmashed = function() return winSmashed end,
    isPermaLocked = function() return false end,
    ToggleWindow = function() winOpen = true end,
    smashWindow = function() winSmashed = true end,
    getSquare = function() return doorSqA end,
}
doorSqA._windowTo[doorSqB] = winObj
PNC.TraversalQuery.InvalidateEdgeCache(nil)
check(PNC.TraversalQuery.GetPassageBetween(doorSqA, doorSqB) == winObj, "window cached on square A")
check(PNC.PathService.OpenWindowForNPC(doorNpc, winObj) == true, "OpenWindowForNPC opened window")
doorSqA._windowTo[doorSqB] = nil
check(PNC.TraversalQuery.GetPassageBetween(doorSqA, doorSqB) == nil,
    "OpenWindowForNPC invalidated TraversalQuery edge cache")
doorSqA._windowTo[doorSqB] = winObj
nowMs = 50300 -- advance past 250ms TTL to re-populate cache
check(PNC.TraversalQuery.GetPassageBetween(doorSqA, doorSqB) == winObj, "window re-cached")
check(PNC.PathService.SmashWindowForNPC(doorNpc, winObj) == true, "SmashWindowForNPC smashed window")
doorSqA._windowTo[doorSqB] = nil
check(PNC.TraversalQuery.GetPassageBetween(doorSqA, doorSqB) == nil,
    "SmashWindowForNPC invalidated TraversalQuery edge cache")

print("\n=== 5. LIVEBODYCONTROL SAME-FRAME PASSAGE MEMO ===")
local specialCollideCount = 0
local probeFrom = makeSquare(12, 12, 0, {
    onSpecialCollide = function() specialCollideCount = specialCollideCount + 1 end,
})
local probeFeeler = makeSquare(13, 12, 0)
local probeWin = { __class = "IsoWindow" }
probeFrom._specialTo[probeFeeler] = probeWin
local probeZ = makeZombieBody("probe-z", 12.5, 12.5, { square = probeFrom, feeler = probeFeeler, isManaged = true })
nowMs = 60000
local tMemo0 = os.clock()
for i = 1, 1000 do
    local obj, kind = PNC.LiveBodyControl.GetVanillaPassageAhead(probeZ)
    if i == 1 then check(obj == probeWin and kind == "window", "GetVanillaPassageAhead identified window") end
end
local tMemoMs = msSince(tMemo0)
check(specialCollideCount == 1,
    "GetVanillaPassageAhead probed feeler once in same frame (calls=" .. tostring(specialCollideCount) .. ")")
PNC.LiveBodyControl.InvalidatePassageAheadCache(probeZ)
local objAfterInv = PNC.LiveBodyControl.GetVanillaPassageAhead(probeZ)
check(objAfterInv == probeWin and specialCollideCount == 2,
    "InvalidatePassageAheadCache forced immediate re-probe on next call")
print(string.format("  1000 same-frame calls: %.2fms, native calls=%d->%d", tMemoMs, 1, specialCollideCount))

print("\n=== 6. CORESOCIAL 100KB SYNC (CLEAN SKIP VS DIRTY RETURNCLONE=FALSE) ===")
local coreRegistry = CoreActors.NewRegistry()
local fakeCore = { Actors = CoreActors }
fakeCore.Actors.DefaultRegistry = coreRegistry
local heavySocialActor = coreRegistry:Create({
    actorId = "actor:heavy:social",
    identitySeed = "seed-heavy",
    archetypeID = "trader.resident",
})
local bigRels = {}
local bigMems = {}
for i = 1, 140 do
    local tKey = "player:target:" .. tostring(i)
    local extPayload = string.rep("social_history_payload_", 25) .. tostring(i)
    bigRels[tKey] = {
        approval = 15, respect = 10, familiarity = 25, revision = 2,
        extensions = {
            ProjectHoomans = {
                baselineApproval = 5, baselineRespect = 5, state = "friend",
                interactionJournal = { { id = "j-" .. i, note = extPayload } },
            },
        },
    }
    bigMems[i] = {
        id = "mem-" .. i,
        type = "shared_combat",
        aboutKey = tKey,
        summary = extPayload,
        revision = 1,
    }
end
local committedHeavy, commitHeavyErr = coreRegistry:Commit(heavySocialActor.actorId, {
    social = { revision = 5, relationships = bigRels, memoryBank = bigMems },
})
check(committedHeavy ~= nil, "seeded ~100KB heavy Core social actor: " .. tostring(commitHeavyErr))

local heavyRec = {
    id = "heavy-npc-1",
    coreActorID = heavySocialActor.actorId,
    coreBacked = true,
    runtime = {},
}
check(PNC.Persistence.CoreSocial.SyncFromCore(heavyRec, fakeCore) == true, "initial SyncFromCore succeeded")
check(heavyRec.runtime._coreSyncedSocialRev == 5, "_coreSyncedSocialRev cached after SyncFromCore")

-- Benchmark clean skip check (matching SyncPromotedCoreActorToCore guard) vs explicit dirty commit
local function simulatePromotedSocialGuard(rec, core, dirty)
    local reg = core.Actors.DefaultRegistry
    local actor = reg:Peek(rec.coreActorID)
    local localRev = tonumber(rec.social and rec.social.revision) or 0
    local coreRev = tonumber(actor and actor.social and actor.social.revision) or 0
    local syncedRev = rec.runtime and tonumber(rec.runtime._coreSyncedSocialRev) or nil
    if (syncedRev ~= nil and localRev <= coreRev and not dirty) then
        return "skipped"
    end
    local ok = PNC.Persistence.CoreSocial.SyncToCore(rec, core)
    return ok and "synced" or "failed"
end

local tClean0 = os.clock()
local skippedCount = 0
for _ = 1, 200 do
    if simulatePromotedSocialGuard(heavyRec, fakeCore, false) == "skipped" then
        skippedCount = skippedCount + 1
    end
end
local tCleanMs = msSince(tClean0)

local tDirty0 = os.clock()
local dirtySynced = 0
for i = 1, 10 do
    heavyRec.social.revision = (tonumber(heavyRec.social.revision) or 0) + 1
    if simulatePromotedSocialGuard(heavyRec, fakeCore, true) == "synced" then
        dirtySynced = dirtySynced + 1
    end
end
local tDirtyMs = msSince(tDirty0)
print(string.format("  100KB social: 200 clean skips=%.2fms (skipped=%d), 10 dirty returnClone=false=%.2fms (synced=%d)",
    tCleanMs, skippedCount, tDirtyMs, dirtySynced))
check(skippedCount == 200 and dirtySynced == 10, "clean syncs skipped 100%, dirty syncs committed via returnClone=false")

print("\n=== 7. INVENTORY GETENCUMBRANCESTATE FAST-PATH ===")
local hydratedRec = {
    id = "enc-npc",
    inventory = {
        items = { it1 = { id = "it1", type = "Axe" } },
        containers = { root = { id = "root", maxWeight = 18 } },
        cachedWeight = 9.0,
        maxWeight = 18.0,
    },
}
local tEnc0 = os.clock()
local lastEnc
for _ = 1, 5000 do
    lastEnc = PNC.Inventory.GetEncumbranceState(hydratedRec)
end
local tEncMs = msSince(tEnc0)
print(string.format("  5000 GetEncumbranceState fast-path calls: %.2fms, level=%s ratio=%.2f",
    tEncMs, tostring(lastEnc and lastEnc.level), tonumber(lastEnc and lastEnc.ratio) or -1))
check(lastEnc and lastEnc.level == "normal" and lastEnc.ratio == 0.5,
    "GetEncumbranceState fast-path preserved exact encumbrance calculations")

print("\n=== 8. MULTI-NPC OBSTACLE CONTENTION FLOWS ===")
-- 8A. Locked exterior door refused -> EnginePathPlanner_Context_Passage skips it
nowMs = 70000
local lockedSqFrom = currentCell:getGridSquare(40, 40, 0)
local lockedSqTo = currentCell:getGridSquare(41, 40, 0)
local exteriorLockedDoor = {
    __class = "IsoDoor",
    IsOpen = function() return false end,
    isOpen = function() return false end,
    couldBeOpen = function() return false end,
    isLocked = function() return true end,
    isLockedByKey = function() return true end,
    getSquare = function() return lockedSqTo end,
    getProperties = function() return { has = function() return false end, get = function() return nil end } end,
}
lockedSqFrom._doorTo[lockedSqTo] = exteriorLockedDoor
local doorPlannerBody = makeZombieBody("planner-npc", 40.5, 40.5, {
    square = lockedSqFrom, fwdX = 1, fwdY = 0, isManaged = true,
})
local nav = { requestX = 45.5, requestY = 40.5, requestRevision = 1, lastBehaviorResult = 1 }
local upcomingBefore = PNC.EnginePathPlanner.Internal.GetUpcomingPathPassage(doorPlannerBody, nav)
check(upcomingBefore and upcomingBefore.object == exteriorLockedDoor and upcomingBefore.kind == "door",
    "EnginePathPlanner detected closed door before refusal")
check(PNC.PathService.OpenDoorForNPC(doorPlannerBody, exteriorLockedDoor) == false,
    "OpenDoorForNPC refused locked exterior door")
check(PNC.PathService.IsDoorRefused(exteriorLockedDoor, nowMs) == true,
    "IsDoorRefused reports true during 5000ms backoff")
-- Same-position cached upcomingPassage must also be cleared/skipped immediately
local upcomingAfterCached = PNC.EnginePathPlanner.Internal.GetUpcomingPathPassage(doorPlannerBody, nav)
check(upcomingAfterCached == nil,
    "EnginePathPlanner cleared cached refused door on same-square lookup")
-- Fresh requestRevision uncached lookup must also skip refused door
nav.requestRevision = 2
local upcomingAfterUncached = PNC.EnginePathPlanner.Internal.GetUpcomingPathPassage(doorPlannerBody, nav)
check(upcomingAfterUncached == nil,
    "EnginePathPlanner skipped refused door on fresh uncached lookup")

-- 8B. Simultaneous 4-NPC window climb & 4-NPC fence climb queuing
PNC.PathService.Internal.ResetPassageReservations()
nowMs = 80000
local winSq = currentCell:getGridSquare(50, 50, 0)
local winDestSq = currentCell:getGridSquare(51, 50, 0)
local sharedWindow = {
    __class = "IsoWindow",
    canClimbThrough = function() return true end,
    isSmashed = function() return false end,
    IsOpen = function() return true end,
    isOpen = function() return true end,
    getSquare = function() return winSq end,
    getOppositeSquare = function() return winDestSq end,
    getAddSheetSquare = function() return winSq end,
    isNorth = function() return false end,
}
local winNpcs = {}
for i = 1, 4 do
    local z = makeZombieBody("win-npc-" .. i, 50.5, 50.5, { square = winSq, isManaged = true })
    local lane = { goalRevision = 1, specialMoveUntil = 0 }
    local rec = { id = "win-npc-" .. i, x = 50.5, y = 50.5, z = 0, runtime = { pathing = lane } }
    winNpcs[i] = {
        zombie = z, record = rec, lane = lane, now = nowMs,
        actorSquare = winSq,
        fromX = 50.5, fromY = 50.5, fromZ = 0, fromPoint = "50,50,0",
        goalX = 55.5, goalY = 50.5, goalZ = 0, blockedPassage = sharedWindow,
    }
end
local wH1, wR1 = PNC.PathService.Internal.tryWindowPassageCandidate(winNpcs[1], sharedWindow, { x = 51, y = 50 })
check(wH1 == true and wR1 == "window_climb",
    "NPC 1 acquired window climb immediately (reason=" .. tostring(wR1) .. ")")
for i = 2, 4 do
    local h, r, d = PNC.PathService.Internal.tryWindowPassageCandidate(winNpcs[i], sharedWindow, { x = 51, y = 50 })
    check(h == true and r == "passage_queued" and d == true,
        string.format("window NPC %d queued cleanly (reason=%s)", i, tostring(r)))
    check(winNpcs[i].lane.ownerMode == "window_climb" and winNpcs[i].lane.specialMoveUntil == nowMs + 220,
        string.format("window NPC %d hold window set", i))
end
-- Advance past NPC 1 completion via MotionPassage -> releases reservation for NPC 2
local motionActive, motionReason = PNC.PathService.Internal.updateScriptedSpecialMove(
    winNpcs[1].zombie, winNpcs[1].record, winNpcs[1].lane, nowMs + 800
)
check(motionActive == true and motionReason == "traversal_completed",
    "MotionPassage completed NPC 1 traversal and released window reservation")
check(winNpcs[1].lane.reservedPassageKey == nil, "NPC 1 reservedPassageKey cleared on completion")
winNpcs[2].now = nowMs + 800
local wH2, wR2 = PNC.PathService.Internal.tryWindowPassageCandidate(winNpcs[2], sharedWindow, { x = 51, y = 50 })
check(wH2 == true and wR2 == "window_climb",
    "NPC 2 claimed window climb cleanly after NPC 1 completed")

-- Simultaneous 4-NPC fence climb queuing
PNC.PathService.Internal.ResetPassageReservations()
nowMs = 85000
local fenceFromSq = currentCell:getGridSquare(60, 60, 0)
local fenceLandSq = currentCell:getGridSquare(61, 60, 0)
local fenceObj = {
    __class = "IsoThumpable",
    getSquare = function() return fenceFromSq end,
    isHoppable = function() return true end,
    isTallHoppable = function() return false end,
}
fenceFromSq._fenceTo[fenceLandSq] = fenceObj
local fenceNpcs = {}
for i = 1, 4 do
    local z = makeZombieBody("fence-npc-" .. i, 60.8, 60.5, { square = fenceFromSq, isManaged = true })
    local lane = { goalRevision = 1, specialMoveUntil = 0, blockedStepToX = 61 }
    local rec = { id = "fence-npc-" .. i, x = 60.8, y = 60.5, z = 0, runtime = { pathing = lane } }
    fenceNpcs[i] = {
        zombie = z, record = rec, lane = lane, now = nowMs,
        actorSquare = fenceFromSq,
        blockedFromSquare = fenceFromSq,
        blockedSquare = fenceLandSq,
        fromX = 60.8, fromY = 60.5, fromZ = 0, fromPoint = "60,60,0",
        goalX = 65.5, goalY = 60.5, goalZ = 0,
    }
end
local fH1, fR1 = PNC.PathService.Internal.tryFencePassage(fenceNpcs[1])
check(fH1 == true and fR1 == "fence_climb", "NPC 1 acquired fence climb immediately")
for i = 2, 4 do
    local h, r, d = PNC.PathService.Internal.tryFencePassage(fenceNpcs[i])
    check(h == true and r == "passage_queued" and d == true,
        string.format("fence NPC %d queued cleanly (reason=%s)", i, tostring(r)))
end
local fMotionActive, fMotionReason = PNC.PathService.Internal.updateScriptedSpecialMove(
    fenceNpcs[1].zombie, fenceNpcs[1].record, fenceNpcs[1].lane, nowMs + 1000
)
check(fMotionActive == true and fMotionReason == "traversal_completed",
    "MotionPassage completed NPC 1 fence traversal and released reservation")
fenceNpcs[2].now = nowMs + 800
local fH2, fR2 = PNC.PathService.Internal.tryFencePassage(fenceNpcs[2])
check(fH2 == true and fR2 == "fence_climb", "NPC 2 acquired fence climb after NPC 1 completed")

-- 8C. Multi-NPC obstacle-aware melee approach slots (walls on East/NE, occupied tolerated vs walls rejected)
local meleeTarget = { kind = "zombie", zombieId = "mz1", x = 70.5, y = 70.5, z = 0, distSq = 4 }
env.npcs = {}
for i = 1, 4 do
    env.npcs[i] = {
        id = "melee-" .. i,
        tacticalClass = "colonist",
        alive = true,
        x = 70.5, y = 70.5, z = 0,
        runtime = {},
    }
end
-- Reject any slot East of target (cx > target.x + 0.5) as "wall", while marking one valid slot "occupied"
edgeCanOccupy = function(cx, cy)
    if cx > meleeTarget.x + 0.55 then return false end
    return true
end
edgeCanStep = function(fx, fy)
    if fx > meleeTarget.x + 0.55 then return false, "wall" end
    if math.abs(fx - meleeTarget.x) < 0.3 and fy > meleeTarget.y + 0.5 then
        return false, "occupied"
    end
    return true, nil
end
local chosenSlots = {}
for i = 1, 4 do
    local sx, sy, usingForm = PNC.CombatTactics.GetMeleeApproachPoint(env.npcs[i], meleeTarget)
    check(usingForm == true, string.format("melee NPC %d received formation slot", i))
    check(sx <= meleeTarget.x + 0.55,
        string.format("melee NPC %d avoided East wall slot (sx=%.2f)", i, sx))
    chosenSlots[i] = { x = sx, y = sy }
    env.npcs[i].x = sx
    env.npcs[i].y = sy
end
for i = 1, 3 do
    for j = i + 1, 4 do
        local dSq = distSq2(chosenSlots[i].x, chosenSlots[i].y, chosenSlots[j].x, chosenSlots[j].y)
        check(dSq > 0.05,
            string.format("melee NPCs %d & %d took separated slots (distSq=%.3f)", i, j, dSq))
    end
end
print("  4-NPC obstacle-aware melee slots avoided walled quadrant and spread cleanly without stacking.")

if #failures > 0 then
    print(string.format("\nSUMMARY: %d failures (BASELINE_MODE=%s)", #failures, tostring(BASELINE_MODE)))
    if not BASELINE_MODE then os.exit(1) end
else
    print("\nSUMMARY: ALL PATHING & ZOMBIE AGGRO BENCHMARK + FLOW CHECKS PASSED")
end
