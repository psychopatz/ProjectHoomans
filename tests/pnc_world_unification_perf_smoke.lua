local T = require "tests/support/test"

T.addPackagePaths({
    { "PsychopatzCore", "shared" },
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local nowMs = 10000
local counters = {
    getSquare = 0,
    getObjects = 0,
    getWorldObjects = 0,
}

-- 1. Pure MP client guard check: server unification modules must no-op cleanly.
isServer = function() return false end
isClient = function() return true end
PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return false end,
    },
}
PNC = {}
local originalRequire = require
require = function(name)
    error("pure MP client required server module: " .. tostring(name))
end
T.load("ProjectHoomans", "server", "PNC/WorldItems/PNC_WorldItemContext.lua")
T.load("ProjectHoomans", "server", "PNC/WorldItems/PNC_WorldItemContext_Approach.lua")
T.load("ProjectHoomans", "server", "PNC/WorldItems/PNC_WorldItemContext_Objects.lua")
require = originalRequire
T.falsy(PNC.WorldItemContext,
    "pure MP client must not initialize PNC.WorldItemContext")

-- 2. Server-authoritative multi-subsystem cache sharing + surgical invalidation.
isServer = function() return true end
isClient = function() return false end
getTimestampMs = function() return nowMs end
SafeHouse = {
    _list = {},
    getSafehouseList = function() return SafeHouse._list end,
}

local grid = {}
local function sqKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z or 0)
end

local function makeMockItem(id, fullType, isFood)
    return {
        getID = function() return id end,
        getFullType = function() return fullType end,
        getDisplayName = function() return fullType end,
        getName = function() return fullType end,
        getCategory = function() return isFood and "Food" or "Item" end,
        IsFood = function() return isFood == true end,
        getHungChange = function() return isFood and -20 or 0 end,
        isRotten = function() return false end,
        isPoison = function() return false end,
        isBurnt = function() return false end,
        isFavorite = function() return false end,
        isEquipped = function() return false end,
    }
end

local function makeJavaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function makeContainer(items)
    local jlist = makeJavaList(items)
    return {
        getItems = function() return jlist end,
    }
end

local function makeSquare(x, y, z)
    z = z or 0
    local sq = {
        x = x, y = y, z = z,
        _objects = {}, _corpses = {}, _worldObjects = {},
    }
    function sq:getX() return self.x end
    function sq:getY() return self.y end
    function sq:getZ() return self.z end
    function sq:isSolid() return false end
    function sq:isSolidTrans() return false end
    function sq:isFree() return true end
    function sq:getObjects()
        counters.getObjects = counters.getObjects + 1
        return self._objects
    end
    function sq:getStaticMovingObjects() return self._corpses end
    function sq:getWorldObjects()
        counters.getWorldObjects = counters.getWorldObjects + 1
        return self._worldObjects
    end
    grid[sqKey(x, y, z)] = sq
    return sq
end

local mockCell = {
    getGridSquare = function(_, x, y, z)
        counters.getSquare = counters.getSquare + 1
        return grid[sqKey(math.floor(x), math.floor(y), math.floor(z or 0))]
    end,
}
function getCell() return mockCell end

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}
PNC = {
    Core = {
        Now = function() return nowMs end,
        Distance = function(ax, ay, bx, by)
            local dx, dy = (bx - ax), (by - ay)
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    Const = {},
    Semantics = {},
}

local Context = T.load("ProjectHoomans", "server", "PNC/WorldItems/PNC_WorldItemContext.lua")
local Locator = T.load("ProjectHoomans", "server", "PNC/World/PNC_NearbyResourceLocator.lua")
local Water = T.load("ProjectHoomans", "server", "PNC/World/PNC_NearbyWaterService.lua")
T.load("ProjectHoomans", "server", "PNC/Semantics/Beats/PNC_SemanticBeats_WorldObjects.lua")
local WorkOutput = T.load("ProjectHoomans", "server", "PNC/Production/PNC_WorkOutputService.lua")

-- Build a 25x25 town grid (625 squares) with food containers, water sink, beat object, floor items.
for y = 100, 124 do
    for x = 100, 124 do
        makeSquare(x, y, 0)
    end
end

local pantrySq = grid[sqKey(114, 112, 0)]
local soup = makeMockItem("soup-1", "Base.CannedSoup", true)
pantrySq._objects[#pantrySq._objects + 1] = {
    getObjectName = function() return "Container" end,
    getSprite = function() return { getName = function() return "furniture_shelving_01_1" end } end,
    getID = function() return 101 end,
    getContainer = function() return makeContainer({ soup }) end,
    getContainerCount = function() return 1 end,
    getContainerByIndex = function() return makeContainer({ soup }) end,
}

local sinkSq = grid[sqKey(113, 112, 0)]
local cleanSink = {
    _tag = "clean_sink",
    getObjectName = function() return "Sink" end,
    getSprite = function() return { getName = function() return "appliances_plumbing_01_1" end } end,
    getID = function() return 202 end,
    hasFluid = function() return true end,
    getFluidAmount = function() return 10000 end,
    getFluidCapacity = function() return 10000 end,
    getFluidContainer = function()
        return { isEmpty = function() return true end, isWaterOnlySource = function() return true end }
    end,
    isTaintedWater = function() return false end,
    transferFluidTo = function(_, _, amount) return amount end,
}
sinkSq._objects[#sinkSq._objects + 1] = cleanSink

local outputSq = grid[sqKey(112, 113, 0)]
local plankItem = makeMockItem("plank-1", "Base.Plank", false)
local floorPlankWO = { getItem = function() return plankItem end }
outputSq._worldObjects[#outputSq._worldObjects + 1] = floorPlankWO

local npcBodies = {}
for i = 1, 10 do
    local bx, by = 112.5, 112.5
    npcBodies[i] = {
        getX = function() return bx end,
        getY = function() return by end,
        getZ = function() return 0 end,
    }
end
PNC.Registry = {
    GetLiveZombie = function(id)
        local idx = tonumber(string.match(tostring(id), "%d+")) or 1
        return npcBodies[idx] or npcBodies[1]
    end,
}

-- Setup SemanticBeats world-object hook
local Beats = PNC.Semantics.DialogueBeats
local startedThreads = 0
Beats.FindCalmSpeakerNearPlayer = function()
    return { id = "npc-1", x = 112.5, y = 112.5, z = 0 }, nil
end
Beats.StartThread = function()
    startedThreads = startedThreads + 1
end
Beats.RegisterObjectBeatHook("test-sink-remark", {
    priority = 50,
    cooldownMs = 1000,
    maxDistance = 3,
    matches = function(obj) return obj == cleanSink end,
    evaluate = function() return { opening = { semantic = "beat.sink" } } end,
})

Context.InvalidateCache()
Context.Cache.ResetStats()
Context.ResetMetrics()

-- Pass 1 (warms r=4 neighborhood via multi-subsystem queries)
local itemCand = Context.FindBestCandidate({ id = "npc-1", x = 112.5, y = 112.5, z = 0 }, {
    radius = 6,
    filter = { categories = { food = true } },
})
T.equal(itemCand.item, soup, "WorldItemContext locates food container")

local objCand = Context.FindBestObject(npcBodies[1], {
    radius = 6,
    accept = function(c) return c.object == cleanSink end,
})
T.equal(objCand.object, cleanSink, "WorldItemContext.FindBestObject locates water sink")

local beatOk, beatHookId = Beats.CheckNearbyWorldObjects(nowMs)
T.truthy(beatOk, "SemanticBeats discovered sink via shared WorldItemContext cache")
T.equal(beatHookId, "test-sink-remark", "SemanticBeats matched registered object hook")
T.equal(startedThreads, 1, "SemanticBeats started dialogue thread once")

local firstLocItem = Locator.Find(npcBodies[1], {
    radius = 4,
    cacheKey = "warm:1",
    accept = function(e) return e.item == soup end,
})
T.truthy(firstLocItem and firstLocItem.item == soup, "first Locator.Find locates food")

-- Pass 2: 10 concurrent NPCs querying NearbyResourceLocator + NearbyWaterService + FindBestCandidate
-- + WorkOutput at the same timestamp -> must hit warm buckets with ZERO raw getGridSquare/getObjects!
local callsBeforeWarm = {
    getSquare = counters.getSquare,
    getObjects = counters.getObjects,
    getWorldObjects = counters.getWorldObjects,
}
local statsBeforeWarm = Context.Cache.GetStats()

local t0 = os.clock()
for i = 1, 10 do
    local rec = { id = "npc-" .. tostring(i), x = 112.5, y = 112.5, z = 0 }
    local locItem = Locator.Find(npcBodies[i], {
        radius = 4,
        accept = function(e) return e.item == soup end,
    })
    T.truthy(locItem and locItem.item == soup, "NearbyResourceLocator.Find shares cache for food")

    local locSink = Locator.FindObject(npcBodies[i], {
        radius = 4,
        accept = function(e) return e.object == cleanSink end,
    })
    T.truthy(locSink and locSink.object == cleanSink, "NearbyResourceLocator.FindObject shares cache for sink")

    local waterSrc = Water.FindAt(rec, 113, 112, 0)
    T.truthy(waterSrc and waterSrc.object == cleanSink, "NearbyWaterService.FindAt hits cached sink")

    local approach = Water.BuildApproach(rec, waterSrc)
    T.truthy(approach ~= nil, "NearbyWaterService.BuildApproach builds walkable tile via shared helper")

    local preDrop = WorkOutput.CaptureGroundOutput(outputSq, nil, nil, { snapshotOnly = true })
    T.truthy(preDrop[floorPlankWO], "WorkOutputService inspects cached worldObjects on output tile")
end
local warmElapsedMs = (os.clock() - t0) * 1000
local statsAfterWarm = Context.Cache.GetStats()

T.equal(counters.getSquare - callsBeforeWarm.getSquare, 0,
    "warm cross-subsystem pass issued zero extra cell:getGridSquare calls")
T.equal(counters.getObjects - callsBeforeWarm.getObjects, 0,
    "warm cross-subsystem pass issued zero extra square:getObjects calls")
T.equal(counters.getWorldObjects - callsBeforeWarm.getWorldObjects, 0,
    "warm cross-subsystem pass issued zero extra square:getWorldObjects calls")
T.truthy(statsAfterWarm.hits > statsBeforeWarm.hits,
    "shared bucket cache recorded cross-subsystem hits (" .. tostring(statsAfterWarm.hits - statsBeforeWarm.hits) .. ")")
T.truthy(warmElapsedMs < 150,
    "50 warm multi-subsystem queries completed in <150ms (got " .. string.format("%.2fms", warmElapsedMs) .. ")")

-- 3. Surgical invalidation: ClearSquare clears ONLY the target square.
local sqBeforeClear = counters.getSquare
Context.ClearSquare(mockCell, 113, 112, 0)

-- Reading neighbor (112, 112) stays cached (0 getGridSquare calls)
Context.GetSquareSnapshot(mockCell, 112, 112, 0, nowMs)
T.equal(counters.getSquare, sqBeforeClear,
    "ClearSquare leaves untouched neighboring squares cached")

-- Reading dirty (113, 112) fetches fresh square (exactly 1 getGridSquare call)
Context.GetSquareSnapshot(mockCell, 113, 112, 0, nowMs)
T.equal(counters.getSquare, sqBeforeClear + 1,
    "ClearSquare forces fresh read on the single cleared square only")

-- 4. Special object (GlobalObject) parity when routed through WorldItemContext
local specialMarker = { getID = function() return 999 end }
local specialFound = Locator.FindObject(npcBodies[1], {
    radius = 0,
    specialObject = function(sq)
        if sq == grid[sqKey(112, 112, 0)] then
            return { object = specialMarker, source = "global_test", key = "global@112:112:0" }
        end
        return nil
    end,
    accept = function(c) return c.source == "global_test" end,
})
T.truthy(specialFound and specialFound.object == specialMarker,
    "NearbyResourceLocator.FindObject -> WorldItemContext preserves GlobalObject specialObject hook")

print(string.format("[UNIFIED PERF] 50 warm cross-subsystem queries: %.2fms, cacheHitsDelta=%d, warmGridCalls=0",
    warmElapsedMs, statsAfterWarm.hits - statsBeforeWarm.hits))

T.finish("pnc_world_unification_perf_smoke")
