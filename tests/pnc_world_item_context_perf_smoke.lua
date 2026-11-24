local T = require "tests/support/test"

T.addPackagePaths({
    { "PsychopatzCore", "shared" },
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local nowMs = 10000
local worldHours = 24.0
local moveCalls = {}
local animRequests = {}
local broadcasts = {}
local leaseState = {}
local taskReevalCount = 0

isServer = function() return true end
isClient = function() return false end

SafeHouse = {
    _list = {},
    getSafehouseList = function() return SafeHouse._list end,
}

local grid = {}
local function squareKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z or 0)
end

local function makeMockItem(spec)
    local item = {
        id = spec.id or ("item_" .. tostring(math.random(100000, 999999))),
        fullType = spec.fullType,
        displayName = spec.displayName or spec.fullType,
        category = spec.category or "Item",
        fabricType = spec.fabricType,
        isClothing = spec.isClothing == true,
        isFood = spec.isFood == true,
        hungChange = spec.hungChange,
        rotten = spec.rotten == true,
        poison = spec.poison == true,
        burnt = spec.burnt == true,
        favorite = spec.favorite == true,
        dirtyness = spec.dirtyness or 0,
        bloodLevel = spec.bloodLevel or 0,
        _container = nil,
    }
    function item:getID() return self.id end
    function item:getFullType() return self.fullType end
    function item:getDisplayName() return self.displayName end
    function item:getName() return self.displayName end
    function item:getCategory() return self.category end
    function item:getFabricType() return self.fabricType end
    function item:IsClothing() return self.isClothing end
    function item:IsFood() return self.isFood end
    function item:getHungChange() return self.hungChange end
    function item:isRotten() return self.rotten end
    function item:isPoison() return self.poison end
    function item:isBurnt() return self.burnt end
    function item:isFavorite() return self.favorite end
    function item:isEquipped() return false end
    function item:getDirtyness() return self.dirtyness end
    function item:getBloodlevel() return self.bloodLevel end
    function item:getContainer() return self._container end
    return item
end

local function makeMockContainer(items)
    local container = { _items = {} }
    function container:getItems() return self._items end
    function container:DoRemoveItem(target)
        for index = #self._items, 1, -1 do
            if self._items[index] == target then
                table.remove(self._items, index)
                return true
            end
        end
        return false
    end
    for index = 1, #(items or {}) do
        items[index]._container = container
        container._items[#container._items + 1] = items[index]
    end
    return container
end

local function makeSquare(x, y, z)
    z = z or 0
    local sq = { x = x, y = y, z = z, _objects = {}, _corpses = {}, _worldObjects = {} }
    function sq:getX() return self.x end
    function sq:getY() return self.y end
    function sq:getZ() return self.z end
    function sq:getObjects() return self._objects end
    function sq:getStaticMovingObjects() return self._corpses end
    function sq:getWorldObjects() return self._worldObjects end
    function sq:transmitRemoveItemFromSquare(wo)
        for i = #self._worldObjects, 1, -1 do
            if self._worldObjects[i] == wo then
                table.remove(self._worldObjects, i)
                return true
            end
        end
        return false
    end
    grid[squareKey(x, y, z)] = sq
    return sq
end

local function addContainerToSquare(sq, items)
    local cont = makeMockContainer(items)
    sq._objects[#sq._objects + 1] = {
        getObjectName = function() return "Container" end,
        getContainer = function() return cont end,
        getContainerCount = function() return 1 end,
        getContainerByIndex = function() return cont end,
    }
    return cont
end

local function addCorpseToSquare(sq, items)
    local cont = makeMockContainer(items)
    sq._corpses[#sq._corpses + 1] = {
        isDeadBody = true,
        getObjectName = function() return "Corpse" end,
        getContainer = function() return cont end,
    }
    return cont
end

local function addFloorItemToSquare(sq, item)
    local wo = {
        getItem = function() return item end,
    }
    sq._worldObjects[#sq._worldObjects + 1] = wo
    return wo
end

local mockCell = {
    getGridSquare = function(_, x, y, z)
        return grid[squareKey(math.floor(x), math.floor(y), math.floor(z or 0))]
    end,
}
function getCell() return mockCell end

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

PNC = {
    Core = {
        Now = function() return nowMs end,
        DeepCopy = function(v)
            if type(v) ~= "table" then return v end
            local out = {}
            for k, entry in pairs(v) do out[k] = PNC.Core.DeepCopy(entry) end
            return out
        end,
        IsAuthority = function() return true end,
    },
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        TACTICAL_CLASS_COLONIST = "colonist",
        TACTICAL_CLASS_NEUTRAL = "neutral",
        TACTICAL_CLASS_HOSTILE = "hostile",
        ORDER_FOLLOW = "follow",
        BANDAGE_TYPES = {
            "Base.AlcoholBandage", "Base.Bandage", "Base.Bandaid",
            "Base.AlcoholRippedSheets", "Base.RippedSheets",
            "Base.DenimStrips", "Base.LeatherStrips",
            "Base.BandageDirty", "Base.RippedSheetsDirty",
        },
    },
    Registry = {
        Data = {},
        Get = function(id) return PNC.Registry.Data[tostring(id)] end,
        GetLiveZombie = function(id)
            local r = PNC.Registry.Data[tostring(id)]
            return r and r._body or nil
        end,
        MarkDirty = function() end,
    },
    Network = {
        BroadcastRecord = function(record, eventName)
            broadcasts[#broadcasts + 1] = { id = record.id, event = eventName }
        end,
    },
    Inventory = {
        EnsureRecordInventory = function(record)
            record.inventory = record.inventory or { items = {}, maxWeight = 20 }
            record.inventory.items = record.inventory.items or {}
            return record.inventory
        end,
        CanAccept = function(record, specs)
            local used = 0
            for _, item in pairs((record.inventory and record.inventory.items) or {}) do
                used = used + (tonumber(item.stack) or 1) * 0.2
            end
            return (used + #specs * 0.2) <= (record.inventory and record.inventory.maxWeight or 20)
        end,
        GetEncumbranceState = function(record)
            local maxW = (record.inventory and record.inventory.maxWeight) or 20
            return { usedWeight = 0, maxWeight = maxW, ratio = 0 }
        end,
        AddItems = function(record, specs)
            record.inventory = record.inventory or { items = {}, maxWeight = 20 }
            record.inventory.items = record.inventory.items or {}
            local ids = {}
            for index = 1, #specs do
                local id = tostring(specs[index].type) .. ":" .. tostring(math.random(10000, 99999))
                record.inventory.items[id] = {
                    id = id,
                    type = specs[index].type,
                    stack = tonumber(specs[index].stack) or 1,
                }
                ids[#ids + 1] = id
            end
            return true, "added", ids
        end,
        MaterializeItem = function() end,
    },
    BehaviorCommon = {
        GetOwner = function(record) return record and record._owner or nil end,
        HaltMovement = function() return true end,
        MoveRecord = function(record, body, tx, ty, tz)
            moveCalls[#moveCalls + 1] = { id = record.id, tx = tx, ty = ty, tz = tz }
            local dx = tx - record.x
            local dy = ty - record.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist <= 1.2 then
                record.x, record.y, record.z = tx, ty, tz
                body.x, body.y, body.z = tx, ty, tz
                return true, "arrived"
            end
            local step = 1.5
            record.x = record.x + (dx / dist) * step
            record.y = record.y + (dy / dist) * step
            body.x, body.y = record.x, record.y
            return true, "moving"
        end,
    },
    AnimationScenes = {
        Request = function(record, _, sceneId)
            animRequests[#animRequests + 1] = { id = record.id, scene = sceneId }
            return true
        end,
        Interrupt = function() end,
    },
    PathService = {
        IsSquareWalkable = function(x, y)
            return not (grid[squareKey(x, y, 0)] and grid[squareKey(x, y, 0)]._blocked == true)
        end,
    },
    TaskLeaseService = {
        ForNPC = function(npcId) return leaseState[tostring(npcId)] end,
    },
    Tasking = {
        Providers = {},
        Commands = {
            RegisterProvider = function(domain, provider)
                PNC.Tasking.Providers[domain] = provider
                return true
            end,
            SetPhase = function() end,
            Complete = function(leaseId)
                for npcId, l in pairs(leaseState) do
                    if l.leaseId == leaseId then leaseState[npcId] = nil end
                end
                return true
            end,
            CancelForNPC = function(npcId)
                leaseState[tostring(npcId)] = nil
                return true
            end,
            ReevaluateNow = function()
                taskReevalCount = taskReevalCount + 1
                return true
            end,
        },
    },
    ModDataStore = {
        Read = function() return nil end,
        Write = function() return true end,
        Check = function(raw) return raw == nil and "empty_state" or nil end,
        Mark = function() end,
    },
    PlayerCharacters = {
        GetEntityKey = function(player) return player and player._key or nil end,
    },
    IndividualNeeds = {
        Get = function(record, needType)
            return record.needs and record.needs[needType] or 0
        end,
    },
    NeedsUtils = { WorldAgeHours = function() return worldHours end },
    NeedsDefinitions = { SUPPLY = { hunger = { trigger = 0.40 } } },
    SupplyMetrics = { Increment = function() end, Set = function() end },
    SupplyInventory = {
        Commands = { EnsurePersonalInventory = function() end },
        Queries = {
            FindPersonal = function(record, request)
                local out = {}
                for _, item in pairs((record.inventory and record.inventory.items) or {}) do
                    if request.resourceKind == "MEDICAL"
                        and PNC.Treatment.IsBandageType(item.type)
                        and not string.find(item.type, "Dirty", 1, true)
                    then
                        out[#out + 1] = { descriptor = { quantity = item.stack or 1, bandage = true } }
                    end
                end
                return out
            end,
        },
    },
    NPCSupplyService = {
        Process = function() return false, "no_supply" end,
        ClearRetry = function() end,
    },
    Factions = {
        GetNPCFaction = function() return nil, "npc_faction_missing" end,
    },
}

local CoreZones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

PNC.Types = PNC.Types or {}
T.load("ProjectHoomans", "shared", "PNC/Core/WorldItems/PNC_WorldItemCategories.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Types/PNC_Types_TacticalClasses.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_Treatment/PNC_Treatment_Policy.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_Treatment/PNC_Treatment_Inventory.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Provision/PNC_ProvisionRuleRegistry.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Provision/Rules/PNC_BandageProvisionRule.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Provision/PNC_ProvisionPolicy.lua")

T.load("ProjectHoomans", "server", "PNC/WorldItems/PNC_WorldItemContext.lua")
T.load("ProjectHoomans", "server", "PNC/Scavenge/PNC_ScavengePolicy.lua")
T.load("ProjectHoomans", "server", "PNC/Scavenge/PNC_ScavengeRuntime.lua")
T.load("ProjectHoomans", "server", "PNC/WorldItems/PNC_WorldItemService.lua")
T.load("ProjectHoomans", "server", "PNC/WorldItems/PNC_WorldItemExecutor.lua")
T.load("ProjectHoomans", "server", "PNC/Provision/PNC_ProvisionResolver.lua")
T.load("ProjectHoomans", "server", "PNC/Provision/PNC_ProvisionEvaluator.lua")
T.load("ProjectHoomans", "server", "PNC/Provision/PNC_ProvisionScheduler.lua")

local Context = PNC.WorldItemContext
local Service = PNC.WorldItemService
local Executor = PNC.WorldItemExecutor

local function makeBody(x, y, z)
    return {
        x = x, y = y, z = z or 0,
        getX = function(s) return s.x end,
        getY = function(s) return s.y end,
        getZ = function(s) return s.z end,
        faceLocation = function() end,
    }
end

local function makeNPC(id, x, y, tacticalClass)
    local npc = {
        id = tostring(id),
        alive = true,
        presenceState = "live",
        tacticalClass = tacticalClass or "neutral",
        x = x, y = y, z = 0,
        needs = { hunger = 0 },
        inventory = { items = {}, maxWeight = 20 },
        runtime = {},
        _body = makeBody(x, y, 0),
    }
    PNC.Registry.Data[npc.id] = npc
    return npc
end

-- 1. Zone & Safehouse theft protection + allowRestrictedZones flag.
do
    SafeHouse._list = {
        { getX = function() return 20 end, getY = function() return 20 end,
          getW = function() return 5 end, getH = function() return 5 end },
    }
    CoreZones.register({
        id = "base:p1", ownerType = "projecthoomans.base", ownerId = "b1", type = "base",
        geometry = GridRegion.normalize({ levels = { [0] = { rows = { [32] = { 30, 35 } } } } }),
    })
    Context.InvalidateCache()

    local sqSafe = makeSquare(22, 22, 0)
    addContainerToSquare(sqSafe, {
        makeMockItem({ fullType = "Base.Bandage", category = "FirstAid" }),
    })
    local sqBase = makeSquare(32, 32, 0)
    addFloorItemToSquare(sqBase, makeMockItem({
        fullType = "Base.Tshirt_DefaultTEXTURE", isClothing = true, fabricType = "Cotton",
    }))

    local probe = makeNPC("zone-probe", 22, 22, "neutral")
    local blockedSafe = Context.FindBestCandidate(probe, {
        x = 22, y = 22, radius = 4, filter = { categories = { medical = true } },
    })
    T.falsy(blockedSafe, "safehouse container items are blocked by default")

    local thiefAllowed = Context.FindBestCandidate(probe, {
        x = 22, y = 22, radius = 4, allowRestrictedZones = true,
        filter = { categories = { medical = true } },
    })
    T.truthy(thiefAllowed and thiefAllowed.itemCtx.fullType == "Base.Bandage",
        "allowRestrictedZones opt-in unlocks restricted zone lookup for future thief NPCs")

    local probeBase = makeNPC("base-probe", 32, 32, "neutral")
    local blockedBase = Context.FindBestCandidate(probeBase, {
        x = 32, y = 32, radius = 4, filter = { mode = "rip_bandage" },
    })
    T.falsy(blockedBase, "player base zone floor clothing is blocked by default")
end

-- 2. Neutral NPC non-unlimited bandages + bandage provision triggering corpse cloth rip.
do
    SafeHouse._list = {}
    grid = {}
    Context.InvalidateCache()

    local neutral = makeNPC("neutral-rip", 10, 10, "neutral")
    T.truthy(PNC.Treatment.RequiresNPCMedicalItem(neutral),
        "neutral NPC requires real medical items (no abstract unlimited bandages)")

    local corpseSq = makeSquare(13, 10, 0)
    local shirt = makeMockItem({
        fullType = "Base.Shirt_White", displayName = "Cotton Shirt",
        isClothing = true, fabricType = "Cotton",
    })
    local corpseCont = addCorpseToSquare(corpseSq, { shirt })

    -- Bandage provision rule (refillBelow=1, target=3) evaluates neutral NPC with 0 bandages.
    PNC.ProvisionScheduler.MarkDirty(neutral, "bandage", 0)
    local processed = PNC.ProvisionScheduler.Pump(nowMs + 5000)
    T.truthy(processed >= 1, "provision scheduler processes neutral bandage rule")

    local cands = Executor.GetCandidates(neutral.id)
    T.equal(#cands, 1, "bandage provision schedules world_item rip task for neutral NPC")
    T.equal(cands[1].kind, "RIP_CLOTHING", "task intent is RIP_CLOTHING")
    local lease = { leaseId = "lease-rip-1", npcId = neutral.id, sourceRef = cands[1].sourceRef }
    leaseState[neutral.id] = lease
    T.truthy(Executor.Start(lease), "rip lease starts")

    -- Step: NPC must walk towards corpse before ripping
    Executor.Tick(lease)
    T.truthy(#moveCalls >= 1, "NPC moves toward corpse before ripping")
    T.equal(#corpseCont._items, 1, "clothing stays in corpse while NPC is still walking")

    -- Advance movement to corpse and enter interaction animation
    for _ = 1, 5 do
        nowMs = nowMs + 100
        Executor.Tick(lease)
    end
    T.equal(animRequests[#animRequests].scene, "scavenge.rip",
        "NPC plays scavenge.rip animation at corpse")

    -- Wait out rip duration and commit
    nowMs = nowMs + 1500
    Executor.Tick(lease)
    T.equal(#corpseCont._items, 0, "ripped clothing removed from corpse container")
    T.truthy(PNC.Treatment.HasNPCBandage(neutral),
        "neutral NPC gained usable ripped sheets from corpse clothing")
end

-- 3. Autonomous food scavenging (skips rotten food, walks to container, grabs beans).
do
    grid = {}
    Context.InvalidateCache()
    local hungry = makeNPC("hungry-1", 50, 50, "neutral")
    hungry.needs.hunger = 0.65

    local shelfSq = makeSquare(54, 50, 0)
    shelfSq._blocked = true
    local rottenApple = makeMockItem({
        fullType = "Base.Apple", isFood = true, hungChange = -15, rotten = true,
    })
    local cannedBeans = makeMockItem({
        fullType = "Base.CannedBeans", isFood = true, hungChange = -30, rotten = false,
    })
    local cont = addContainerToSquare(shelfSq, { rottenApple, cannedBeans })
    makeSquare(53, 50, 0) -- adjacent walkable approach tile

    local triggered = Service.TickAutonomous(hungry, nowMs + 10000)
    T.truthy(triggered, "hungry NPC triggers autonomous food scavenge")

    local intent = Service.GetActiveIntent(hungry.id)
    T.equal(intent.candidate.itemCtx.fullType, "Base.CannedBeans",
        "autonomous food scavenge skips rotten apple and selects safe canned beans")

    local cands = Executor.GetCandidates(hungry.id)
    local lease = { leaseId = "lease-food-1", npcId = hungry.id, sourceRef = cands[1].sourceRef }
    leaseState[hungry.id] = lease
    Executor.Start(lease)
    for _ = 1, 6 do
        nowMs = nowMs + 250
        Executor.Tick(lease)
    end
    nowMs = nowMs + 1000
    Executor.Tick(lease)

    local foundBeans = false
    for _, item in pairs(hungry.inventory.items) do
        if item.type == "Base.CannedBeans" then foundBeans = true end
    end
    T.truthy(foundBeans, "hungry NPC walked to adjacent shelf tile and grabbed beans")
    T.equal(#cont._items, 1, "rotten apple remained untouched in container")
end

-- 4. Following companion category scavenging (player toggles categories via ScavengeRuntime).
do
    grid = {}
    Context.InvalidateCache()
    SafeHouse._list = {
        { getX = function() return 60 end, getY = function() return 60 end,
          getW = function() return 3 end, getH = function() return 3 end },
    }
    Context.InvalidateCache()

    local owner = {
        _key = "owner:p1",
        getX = function() return 65 end, getY = function() return 65 end, getZ = function() return 0 end,
    }
    PNC.ScavengeRuntime.HandleRequest(owner, {
        action = "set_category", categoryId = "medical", enabled = true,
    })

    local companion = makeNPC("follower-1", 65, 65, "colonist")
    companion._owner = owner
    companion.orderSpec = { kind = "follow" }

    -- SafeHouse container has Bandage (must be blocked by zone guard)
    local safeSq = makeSquare(61, 61, 0)
    addContainerToSquare(safeSq, {
        makeMockItem({ fullType = "Base.Bandage", category = "FirstAid" }),
    })
    -- Public square has Food (must be ignored because food=false) + AlcoholBandage (must grab)
    local streetSq = makeSquare(68, 65, 0)
    addFloorItemToSquare(streetSq, makeMockItem({
        fullType = "Base.Chips", isFood = true, hungChange = -15,
    }))
    addFloorItemToSquare(streetSq, makeMockItem({
        fullType = "Base.AlcoholBandage", category = "FirstAid",
    }))

    local grabbedQueued = Service.TickFollowCompanion(companion, companion._body, owner, nowMs + 20000)
    T.truthy(grabbedQueued, "following companion detected enabled medical category item")
    local fIntent = Service.GetActiveIntent(companion.id)
    T.equal(fIntent.candidate.itemCtx.fullType, "Base.AlcoholBandage",
        "companion picked AlcoholBandage outside safehouse and skipped unselected food")

    local fLease = { leaseId = "lease-fol-1", npcId = companion.id, sourceRef = fIntent.id }
    leaseState[companion.id] = fLease
    Executor.Start(fLease)
    for _ = 1, 5 do
        nowMs = nowMs + 250
        Executor.Tick(fLease)
    end
    nowMs = nowMs + 1000
    Executor.Tick(fLease)
    T.truthy(PNC.Treatment.HasNPCBandage(companion),
        "following companion walked over and picked up AlcoholBandage into inventory")
end

-- 5. Dense scale & performance benchmark: 25x25 grid, 200+ sources, 600+ items, 20 concurrent NPCs.
do
    grid = {}
    Context.InvalidateCache()
    Context.ResetMetrics()
    SafeHouse._list = {
        { getX = function() return 109 end, getY = function() return 109 end,
          getW = function() return 3 end, getH = function() return 3 end },
    }
    Context.InvalidateCache()

    local sourceCount = 0
    local itemCount = 0
    for y = 100, 124 do
        for x = 100, 124 do
            local sq = makeSquare(x, y, 0)
            if ((x + y) % 3) == 0 then
                local items = {}
                for k = 1, 3 do
                    local isHit = (x == 114 and y == 111 and k == 2)
                    items[#items + 1] = makeMockItem({
                        fullType = isHit and "Base.CannedSoup" or "Base.Nails",
                        category = isHit and "Food" or "Material",
                        isFood = isHit,
                        hungChange = isHit and -25 or nil,
                        isMaterial = not isHit,
                    })
                    itemCount = itemCount + 1
                end
                addContainerToSquare(sq, items)
                sourceCount = sourceCount + 1
            end
        end
    end
    T.truthy(sourceCount >= 200, "benchmark created 200+ world containers (" .. tostring(sourceCount) .. ")")
    T.truthy(itemCount >= 600, "benchmark created 600+ world items (" .. tostring(itemCount) .. ")")

    local t0 = os.clock()
    local hits = 0
    for n = 1, 20 do
        local npc = makeNPC("bench-" .. tostring(n), 112, 112, "neutral")
        local cand = Context.FindBestCandidate(npc, {
            x = 112, y = 112, z = 0, radius = 10,
            filter = { categories = { food = true } },
        })
        if cand then hits = hits + 1 end
    end
    local elapsedMs = (os.clock() - t0) * 1000
    local metrics = Context.GetMetrics()
    T.equal(hits, 20, "all 20 concurrent NPC scans located the target food item")
    T.truthy(elapsedMs < 100, "20 concurrent dense scans finished under 100ms (got " .. string.format("%.2fms", elapsedMs) .. ")")
    T.truthy(metrics.cacheHits > 0, "bucket source cache produced hits (" .. tostring(metrics.cacheHits) .. ")")
    T.truthy(metrics.earlyExits > 0, "spiral early-exit bounded scan radius (" .. tostring(metrics.earlyExits) .. ")")
    T.truthy(metrics.zoneBlocked > 0, "safehouse squares filtered prior to item inspection")
    print(string.format("[PERF] 20 scans / %d sources / %d items: %.2fms, squares=%d, cacheHits=%d, earlyExits=%d",
        sourceCount, itemCount, elapsedMs, metrics.squaresVisited, metrics.cacheHits, metrics.earlyExits))
end

T.finish("pnc_world_item_context_perf_smoke")
