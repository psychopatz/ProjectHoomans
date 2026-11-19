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
    local zombies = {}
    local nextOid = 500
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
            getFullType = function() return tostring(fullType or "Base.Axe") end,
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

    local function makeZombie(x, y, z)
        nextOid = nextOid + 1
        local oid = nextOid
        local zx, zy, zz = x or 0, y or 0, z or 0
        local md, vars, inv = {}, {}, makeInv()
        local vis = {
            setSkinTextureIndex = function() end, setSkinTextureName = function() end,
            setHairModel = function() end, setBeardModel = function() end,
            setHairColor = function() end, setBeardColor = function() end,
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
        local obj
        obj = {
            __class = "IsoZombie",
            getX = function() return zx end, setX = function(_, v) zx = v end,
            getY = function() return zy end, setY = function(_, v) zy = v end,
            getZ = function() return zz end, setZ = function(_, v) zz = v end,
            getOnlineID = function() return oid end,
            getPersistentOutfitID = function() return oid + 10000 end,
            isDead = function() return false end,
            isFakeDead = function() return false end,
            getModData = function() return md end,
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
            getItemVisuals = function() return makeList({}) end,
            DoZombieStats = function() end, resetModelNextFrame = function() end, resetModel = function() end,
            setUseless = function() end, setFakeDead = function() end, setNoTeeth = function() end,
            setCrawler = function() end, setCanCrawlUnderVehicle = function() end,
            setSkeleton = function() end, setOnFire = function() end,
            setTarget = function() end, getTarget = function() return nil end,
            setPath2 = function() end, clearAggroList = function() end, setRunning = function() end,
            getPathFindBehavior2 = function() return pfb end,
            getHealth = function() return 1.0 end, setHealth = function() end,
            setAvoidDamage = function() end, setImmortal = function() end, setInvulnerable = function() end,
            setDir = function() end, facePosition = function() end,
            faceLocation = function() end, faceLocationF = function() end,
            setForwardDirection = function() end, setForceEatingAnimation = function() end,
            setAttackOutcome = function() end,
            removeFromWorld = function()
                removed = true
                for i = #zombies, 1, -1 do
                    if zombies[i] == obj then table.remove(zombies, i) end
                end
            end,
            removeFromSquare = function()
                removed = true
            end,
            getWornItems = function() return makeList({}) end, clearWornItems = function() end,
            setPrimaryHandItem = function() end, setSecondaryHandItem = function() end,
            getPrimaryHandItem = function() return nil end, getSecondaryHandItem = function() return nil end,
            getAttachedItems = function() return makeList({}) end, clearAttachedItems = function() end,
            getLastKnownLocation = function() return nil end, isMoving = function() return false end,
        }
        zombies[#zombies + 1] = obj
        return obj
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
        zombies = {}
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
        GlobalModData = { save = function() end }
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
                getYear = function() return 1993 end, getMonth = function() return 7 end,
                getDay = function() return 9 end, getHour = function() return 12 end,
                getMinutes = function() return 0 end, getTimeOfDay = function() return 12.0 end,
                getDawn = function() return 6 end, getDusk = function() return 20 end,
            }
        end
        getCore = function() return { getOptionFontSize = function() return 1 end } end
        instanceItem = function(ft) return makeItem(ft) end
        InventoryItemFactory = { CreateItem = function(ft) return makeItem(ft) end }
        instanceof = function(o, c) return type(o) == "table" and o.__class == c end
        getCell = function()
            return {
                getZombieList = function() return makeList(zombies) end,
                getGridSquare = function(_, x, y, z) return getSquare(x, y, z) end,
            }
        end
        getWorld = function() return { getCell = getCell } end
        addZombiesInOutfit = function(x, y, z) return makeList({ makeZombie(x, y, z) }) end
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
        advanceMs = function(dt) nowMs = nowMs + dt end,
        getEvents = function() return events end,
        getStores = function() return stores end,
        getPlayer = function() return player end,
        getZombies = function() return zombies end,
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
local SW = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local actorReg = Actors.DefaultRegistry

local ABSTRACT_LEASE = {
    provider = "ProjectHoomans",
    owner = "ProjectHoomans:test",
    state = "abstract",
}

-- Create 120 distant Core actors (> 1000 tiles away), 1 recruited companion, 1 unique NPC,
-- 1 starter companion actor, and 1 unmodified bystander + 1 debug handoff actor.
for i = 1, 116 do
    assert(actorReg:Create({
        actorId = "core:distant:" .. tostring(i),
        identitySeed = "distant:" .. tostring(i),
        archetypeID = "core.survivor",
        providerLease = ABSTRACT_LEASE,
        world = { position = { x = 5000 + i * 20, y = 5000, z = 0 } },
        extensions = {
            ["PsychopatzCore.SurvivorWorld"] = {
                factionID = "fac_sw_1",
                communityID = "com_sw_1",
                groupID = "grp_sw_1",
                role = "member",
            },
        },
    }))
end

-- Unmodified far bystander (id = core:bystander:clean)
assert(actorReg:Create({
    actorId = "core:bystander:clean",
    identitySeed = "bystander-clean",
    archetypeID = "core.survivor",
    providerLease = ABSTRACT_LEASE,
    world = { position = { x = 3000, y = 3000, z = 0 } },
    extensions = {
        ["PsychopatzCore.SurvivorWorld"] = { factionID = "fac_sw_1", role = "member" },
    },
}))

-- Far bystander that will be mutated and demoted
assert(actorReg:Create({
    actorId = "core:bystander:mutated",
    identitySeed = "bystander-mutated",
    archetypeID = "core.survivor",
    providerLease = ABSTRACT_LEASE,
    world = { position = { x = 3100, y = 3000, z = 0 } },
    extensions = {
        ["PsychopatzCore.SurvivorWorld"] = { factionID = "fac_sw_1", role = "member" },
    },
}))

-- Unique NPC actor (with persisted Hoomans extension identifying uniqueDefinitionId)
assert(actorReg:Create({
    actorId = "core:unique:1",
    identitySeed = "unique-1",
    archetypeID = "core.survivor",
    providerLease = ABSTRACT_LEASE,
    world = { position = { x = 3200, y = 3000, z = 0 } },
    extensions = {
        ["PsychopatzCore.SurvivorWorld"] = { factionID = "fac_sw_1", role = "member" },
    },
}))

-- Starting companion Core actor
assert(actorReg:Create({
    actorId = "core:starter:1",
    identitySeed = "starter-1",
    archetypeID = "core.survivor",
    providerLease = ABSTRACT_LEASE,
    world = { position = { x = 3300, y = 3000, z = 0 } },
    extensions = {
        ["PsychopatzCore.SurvivorWorld"] = { factionID = "fac_sw_1", role = "member" },
    },
}))

require "PNC/00_PNC_Init"
require "PNC/Composition/PNC_ServerComposition"

for _, fn in ipairs(env.getEvents().OnInitGlobalModData or {}) do fn() end
for _, fn in ipairs(env.getEvents().OnServerStarted or {}) do fn() end

-- 1. Startup with 120 Core actors has ZERO promoted Hoomans records, while map/portrait projection sees all 120.
T.equal(countMap(PNC.Registry.Data), 0, "startup must promote 0 idle Core actors")
local worldReg = assert(PNC.CoreSurvivorWorldAuthority.Registry)
local projected = SW.Presentation.BuildActorEntries(worldReg, actorReg, 10000)
T.equal(#projected, 120, "Core map/portrait projection must cover all 120 actors without promoting them")
T.equal(countMap(PNC.Registry.Data), 0, "BuildActorEntries must promote 0 actors")

local CoreProvider = assert(PNC.Persistence.CoreProvider)
local CoreExtension = assert(PNC.Persistence.CoreActorExtension)

-- 2. Unmodified bystander promote -> demote writes ZERO extension bytes.
local cleanRec, cleanStatus = assert(CoreProvider.PromoteCoreActor(
    "core:bystander:clean", PsychopatzCore, { reason = "test_clean" }
))
T.equal(cleanStatus, "created")
T.equal(cleanRec.coreBacked, true)
local cleanDemoteOk, cleanDemoteInfo = assert(CoreProvider.DemoteCoreActor(
    "core:bystander:clean", PsychopatzCore, { force = true }
))
T.truthy(cleanDemoteOk)
T.equal(cleanDemoteInfo.extensionPersisted, false,
    "unmodified bystander demotion must not persist empty ProjectHoomans.ActorExtension")
T.equal(actorReg:GetExtension("core:bystander:clean", CoreExtension.EXTENSION_ID), nil,
    "unmodified Core actor extension must remain nil")

-- 3. Mutated bystander promote -> modify health/wounds/skills/inventory/position -> demote.
local mutRec = assert(CoreProvider.PromoteCoreActor(
    "core:bystander:mutated", PsychopatzCore, { reason = "test_mutated" }
))
mutRec.x = 3150
mutRec.y = 3075
mutRec.health.current = 55
mutRec.progression = {
    skillLevelDeltas = { Axe = 1 },
    skillXP = { Axe = 40 },
}
mutRec.skillBaseLevels = { Axe = 3 }
assert(PNC.Inventory.AddItems(mutRec, {
    { type = "Base.Hammer", count = 1 },
}, "root", "test"))
assert(CoreProvider.DemoteCoreActor(mutRec, PsychopatzCore, { force = true }))

T.equal(countMap(PNC.Registry.Data), 0, "demoted actor must leave Registry.Data")
T.equal(countMap(PNC.Scheduler.SlotByID), 0, "demoted actor must leave Scheduler.SlotByID")
T.equal(countMap(PNC.SpatialIndex.NPCMembership), 0, "demoted actor must leave SpatialIndex")
T.equal(env.getStores()["PNC_npc_core:bystander:mutated"], nil,
    "Core-backed actor must never create duplicate PNC_npc_<id> ModData")

local coreMut = assert(actorReg:Get("core:bystander:mutated"))
T.equal(coreMut.actorId, "core:bystander:mutated", "canonical Core ID preserved across demotion")
T.equal(coreMut.world.location.position.x, 3150, "position flushed to Core on demotion")
T.equal(coreMut.world.location.position.y, 3075, "y position flushed to Core on demotion")

local mutExt = assert(actorReg:GetExtension("core:bystander:mutated", CoreExtension.EXTENSION_ID))
T.equal(mutExt.health.current, 55, "HP delta persisted in Hoomans extension")
T.equal(mutExt.progression.skillXP.Axe, 40, "skill XP delta persisted in Hoomans extension")
-- Ensure forbidden Core-owned domains are never duplicated inside extension:
for _, forbiddenKey in ipairs({
    "identity", "displayName", "appearance", "personalInventory", "inventory",
    "social", "persona", "knowledge", "affiliation", "factionID", "providerLease", "runtime",
}) do
    T.equal(mutExt[forbiddenKey], nil,
        "Core-owned field must not exist inside ProjectHoomans.ActorExtension: " .. forbiddenKey)
end

-- 4. Unique NPC survives demotion + Reconcile + BuildDebugSnapshot without losing status.
local uqRec = assert(CoreProvider.PromoteCoreActor("core:unique:1", PsychopatzCore, { reason = "test_unique" }))
uqRec.uniqueDefinitionId = "uq_test_sentinel"
uqRec.uniqueDefinitionVersion = 1
local states = PNC.UniqueNPCRegistry.Internal.Ensure()
states["uq_test_sentinel"] = {
    definitionId = "uq_test_sentinel",
    status = "alive",
    runtimeNpcId = "core:unique:1",
    identitySeed = uqRec.identitySeed,
    definitionVersion = 1,
}
assert(CoreProvider.DemoteCoreActor(uqRec, PsychopatzCore, { force = true }))
local recOk = PNC.UniqueNPCRegistry.Reconcile()
T.truthy(recOk)
T.equal(states["uq_test_sentinel"].status, "alive",
    "UniqueNPCRegistry.Reconcile must preserve demoted Core-backed unique NPC")
local diag = assert(PNC.UniqueNPCRegistry.BuildDebugSnapshot())
local foundUq = false
for _, row in ipairs(diag.entries or {}) do
    if row.definitionId == "uq_test_sentinel" then
        foundUq = true
        T.equal(row.status, "alive")
        T.truthy(row.integrity ~= "alive_record_missing",
            "demoted unique NPC must not be reported as alive_record_missing")
    end
end
T.truthy(foundUq, "unique diagnostic entry present")

-- 5. Recruited companion + active responsibility resists demotion; dismissal allows demotion.
local compRec = assert(CoreProvider.PromoteCoreActor("core:distant:1", PsychopatzCore, { reason = "test_recruit" }))
compRec.recruited = true
compRec.ownerUsername = "TestOwner"
compRec.ownerCharacterUUID = "char_test_1"
compRec.orderSpec = { kind = "follow", ownerUsername = "TestOwner", ownerCharacterUUID = "char_test_1" }
local activeOk, activeReason = CoreProvider.HasActiveHoomansResponsibility(compRec, 15000, { ignoreGrace = true })
T.equal(activeOk, true, "recruited companion must keep active Hoomans responsibility")
local demoteCompOk, demoteCompErr = CoreProvider.DemoteCoreActor(compRec, PsychopatzCore, { now = 15000 })
T.equal(demoteCompOk, false, "recruited companion must not demote via normal path")
T.equal(demoteCompErr, activeReason)
-- Flush companion state + starter state + mutated state to Core & ModData before restart test.
PNC.Registry.MarkDirty(compRec, "recruited")
PNC.Registry.Save()
env.advanceMs(5000)

-- 6. Save & Reload:
--    * core:distant:1 (recruited companion) restores promoted at startup!
--    * core:bystander:mutated (demoted wounded bystander) stays unpromoted at startup, then re-promotes with exact HP/XP/Hammer/pos!
--    * starting companion grant promotes existing core:starter:1 without duplicating!
local persistedStores = env.getStores()
env.resetModuleCache()
env.installGlobals(persistedStores)

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

T.equal(countMap(PNC.Registry.Data), 1,
    "reload must restore only the 1 recruited companion, keeping 119 bystanders unpromoted")
local reloadedComp = assert(PNC.Registry.Get("core:distant:1"), "recruited companion restored")
T.equal(reloadedComp.ownerCharacterUUID, "char_test_1", "companion ownerCharacterUUID preserved")
T.equal(reloadedComp.orderSpec.kind, "follow", "companion follow order preserved")
T.equal(PNC.Registry.Get("core:bystander:mutated"), nil,
    "demoted wounded bystander stays Core-only until needed again")

-- Now re-promote wounded bystander on demand -> verify exact state restored!
local repromotedMut = assert(PNC.Persistence.CoreProvider.PromoteCoreActor(
    "core:bystander:mutated", PsychopatzCore, { reason = "test_repromote" }
))
T.equal(repromotedMut.health.current, 55, "re-promoted HP restored from Core extension")
T.equal(repromotedMut.progression.skillXP.Axe, 40, "re-promoted XP restored from Core extension")
T.equal(repromotedMut.skillBaseLevels.Axe, 3, "re-promoted skillBaseLevels restored from Core extension")
T.equal(repromotedMut.x, 3150, "re-promoted X restored from Core")
local foundHammer = false
for _, item in pairs(repromotedMut.inventory and repromotedMut.inventory.items or {}) do
    if item.type == "Base.Hammer" then foundHammer = true end
end
T.truthy(foundHammer, "re-promoted compacted Core inventory preserved Base.Hammer")

-- StartingCompanion Ensure finds & promotes core:starter:1 instead of spawning a duplicate.
local player = env.getPlayer()
local charUUID, charErr = PNC.PlayerCharacters.EnsureIdentity(
    player, { callback = "test_starter", worldAgeHours = 50 }
)
T.truthy(charUUID, charErr)
local appliedOk, appliedReason = PNC.PlayerCharacters.ApplyStartingCompanionState(charUUID, {
    resolved = true,
    grants = {
        PNC_HasFriend = {
            status = "granted",
            traitID = "PNC_HasFriend",
            relationshipKind = "friend",
            npcID = "core:starter:1",
            selectedAt = 50,
            grantedAt = 50,
            enrichmentVersion = PNC.StartingCompanions.ENRICHMENT_VERSION or 1,
            relationshipKeyVersion = PNC.StartingCompanions.RELATIONSHIP_KEY_VERSION or 1,
        },
    },
})
T.truthy(appliedOk, appliedReason)
local beforeActorCount = reg2:Count()
local existingStarter = PNC.Registry.Get("core:starter:1")
T.equal(existingStarter, nil)
-- StartingCompanions.Ensure checks Registry.Get -> CoreProvider.PromoteCoreActor
PNC.StartingCompanions.Ensure(player, charUUID, 50)
T.truthy(PNC.Registry.Get("core:starter:1"),
    "StartingCompanionService promoted canonical Core actor")
T.equal(reg2:Count(), beforeActorCount,
    "StartingCompanionService must not create a duplicate Core actor")

-- Dismiss companion -> verify reversible demotion cleanly removes from Registry while preserving Core actor.
reloadedComp.recruited = false
reloadedComp.ownerUsername = nil
reloadedComp.ownerCharacterUUID = nil
reloadedComp.orderSpec = nil
env.advanceMs(5000)
local dismissedOk = assert(PNC.Persistence.CoreProvider.DemoteCoreActor(
    reloadedComp, PsychopatzCore, { now = 20000 }
))
T.truthy(dismissedOk)
T.equal(PNC.Registry.Get("core:distant:1"), nil, "dismissed companion demoted cleanly")
T.truthy(reg2:HasActiveActor("core:distant:1"), "dismissed companion retained in Core")

-- 7. Provider handoff via PsychopatzSurvivorWorldPresence.DebugForceLive & DebugRelease on UNPROMOTED Core actor.
local PresenceSW = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresence"
local DebugSettings = require "PsychopatzCore/Debug/PsychopatzDebugSettings"
local DebugCore = require "PsychopatzCore/Debug/PsychopatzDebug"
local prevCanUse = DebugCore.CanUse
DebugCore.CanUse = function() return true end
DebugSettings.Set(PresenceSW.SETTING_ID, true, false)
DebugSettings.ApplyConfigured()

local handoffActor = assert(reg2:Get("core:distant:2"))
T.equal(PNC.Registry.Get("core:distant:2"), nil, "target actor starts unpromoted")
local liveActor, liveErr = PresenceSW.DebugForceLive(player, "core:distant:2", { reason = "test_handoff" })
T.truthy(liveActor, liveErr)
T.equal(liveActor.actorId, "core:distant:2", "DebugForceLive preserved canonical ID")
T.equal(liveActor.providerLease and liveActor.providerLease.state, "materialized", "DebugForceLive materialized Core lease")
local promotedHandoff = assert(PNC.Registry.Get("core:distant:2"))
T.equal(promotedHandoff.id, "core:distant:2", "DebugForceLive promoted canonical ID")
T.equal(promotedHandoff.presenceState, PNC.Const.PRESENCE_LIVE, "DebugForceLive materialized body")
local relRes, relErr = PresenceSW.DebugRelease(player, "core:distant:2", { reason = "test_release" })
T.truthy(relRes, relErr)
T.equal(PNC.Registry.Get("core:distant:2"), nil,
    "DebugRelease demoted temporary handoff Core actor outside range")
T.truthy(reg2:HasActiveActor("core:distant:2"), "DebugRelease retained canonical Core actor")
DebugCore.CanUse = prevCanUse

-- 8. Mass interest entry (40 unpromoted Core actors placed at (100,100)):
--    Single refresh promotes <= CORE_PROMOTE_MAX_PER_REFRESH (4).
for i = 1, 40 do
    assert(reg2:Create({
        actorId = "core:crowd:" .. tostring(i),
        identitySeed = "crowd:" .. tostring(i),
        archetypeID = "core.survivor",
        world = { position = { x = 100 + (i % 6), y = 100 + math.floor(i / 6), z = 0 } },
        extensions = {
            ["PsychopatzCore.SurvivorWorld"] = { factionID = "fac_sw_1", role = "member" },
        },
    }))
end
PNC.Presence.RefreshMaterializationCandidates(25000, true)
T.truthy((tonumber(PNC.Presence.Internal.lastRefreshPromotions) or 0) <= 4,
    "single interest refresh must promote <= CORE_PROMOTE_MAX_PER_REFRESH=4")

T.finish("pnc_lightweight_lazy_promotion_demotion_smoke")
