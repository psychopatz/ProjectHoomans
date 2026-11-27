local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
local Core = require "PsychopatzCore/Actors/PsychopatzActors"

-- 1. Verify FindRecordByZombie safely rejects non-zombie values (no nil call).
T.load("ProjectHoomans", "shared", "PNC/Core/Registry/PNC_Registry/PNC_Registry_Records.lua")
PNC.Registry.EnsureLoaded = PNC.Registry.EnsureLoaded or function() end
PNC.Registry.Data = PNC.Registry.Data or {}
PNC.Registry.RuntimeViews = PNC.Registry.RuntimeViews or {}
PNC.Registry.LiveByID = PNC.Registry.LiveByID or {}
PNC.Registry.SavedSnapshots = PNC.Registry.SavedSnapshots or {}
PNC.Registry.MarkDirty = PNC.Registry.MarkDirty or function() return true end
T.equal(PNC.Registry.FindRecordByZombie(nil), nil)
T.equal(PNC.Registry.FindRecordByZombie(10612), nil)
T.equal(PNC.Registry.FindRecordByZombie({}), nil)

-- 2. Verify BehaviorLoot passes live zombie as 2nd argument to MoveRecord.
T.load("ProjectHoomans", "server", "PNC/Scavenge/PNC_Behavior_Loot.lua")
local BehaviorLoot = PNC.BehaviorLoot
local fakeZombie = {
    tag = "live_zombie",
    getModData = function() return { PNC_UUID = "npc_loot_1" } end,
}
local lootRecord = {
    id = "npc_loot_1",
    x = 100,
    y = 100,
    z = 0,
    runtime = {
        lootTarget = {
            x = 105,
            y = 108,
            z = 0,
            startedAt = 1000,
        },
    },
}
local origGetLiveZombie = PNC.Registry.GetLiveZombie
local origMoveRecord = PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord
PNC.Registry.GetLiveZombie = function(id)
    return id == "npc_loot_1" and fakeZombie or nil
end
PNC.BehaviorCommon = PNC.BehaviorCommon or {}
local capturedMove = nil
PNC.BehaviorCommon.MoveRecord = function(rec, zom, tx, ty, tz, mode, stopDist, reason)
    capturedMove = {
        record = rec,
        zombie = zom,
        tx = tx,
        ty = ty,
        tz = tz,
        mode = mode,
        stopDist = stopDist,
        reason = reason,
    }
end
local okLoot, lootStatus = BehaviorLoot.Tick(lootRecord, 1500, {})
T.truthy(okLoot)
T.equal(lootStatus, "moving")
T.truthy(capturedMove, "MoveRecord was invoked")
T.equal(capturedMove.zombie, fakeZombie, "live zombie passed as 2nd arg")
T.equal(capturedMove.tx, 105)
T.equal(capturedMove.ty, 108)
T.equal(capturedMove.reason, "opportunistic_loot")
PNC.Registry.GetLiveZombie = origGetLiveZombie
PNC.BehaviorCommon.MoveRecord = origMoveRecord

-- 3. Verify CommunitySiteResolver MetaGrid discovery works while unloaded/abstract.
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_EntityRef.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Communities/PNC_CommunityConstants.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Communities/PNC_CommunityProfiles.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Communities/PNC_CommunityMath.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Communities/PNC_CommunityTypes.lua")
PNC.Communities = PNC.Communities or {
    BuildSiteID = function(site)
        return (PNC.CommunityConstants.SITE_ID_PREFIX or "site_")
            .. tostring(math.floor(site.home.x)) .. "_"
            .. tostring(math.floor(site.home.y))
    end,
    GetSite = function() return nil end,
    FindSiteOverlap = function() return nil end,
}
T.load("ProjectHoomans", "server", "PNC/Communities/CommunitySiteResolver/PNC_CommunitySiteResolver_Core.lua")
T.load("ProjectHoomans", "server", "PNC/Communities/CommunitySiteResolver/PNC_CommunitySiteResolver_Description.lua")
T.load("ProjectHoomans", "server", "PNC/Communities/CommunitySiteResolver/PNC_CommunitySiteResolver_Candidates.lua")
T.load("ProjectHoomans", "server", "PNC/Communities/CommunitySiteResolver/PNC_CommunitySiteResolver_Finders.lua")

local function makeDef(x, y, x2, y2)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getX2 = function() return x2 end,
        getY2 = function() return y2 end,
    }
end

local nearDef = makeDef(10585, 10300, 10595, 10310)
local farDef = makeDef(10620, 10340, 10630, 10350)

_G.ArrayList = {
    new = function()
        local items = {}
        return {
            add = function(_, v) items[#items + 1] = v end,
            size = function() return #items end,
            get = function(_, idx) return items[idx + 1] end,
        }
    end,
}
_G.getCell = function()
    return {
        getGridSquare = function() return nil end,
    }
end
_G.getWorld = function()
    return {
        getMetaGrid = function()
            return {
                getBuildingAt = function(_, gx, gy)
                    if gx >= 10585 and gx <= 10595 and gy >= 10300 and gy <= 10310 then
                        return nearDef
                    end
                    return nil
                end,
                getBuildingsIntersecting = function(_, _, _, _, _, out)
                    out:add(farDef)
                    out:add(nearDef)
                end,
            }
        end,
    }
end

local metaAt, metaAtReason = PNC.CommunitySiteResolver.DescribeAt(10590, 10305, 0)
T.truthy(metaAt, metaAtReason)
T.equal(metaAt.kind, "building", "DescribeAt falls back to MetaGrid when unloaded")

local nearestSite, nearestReason = PNC.CommunitySiteResolver.FindAvailableNear(10580, 10305, 0, {
    searchRadius = 64,
})
T.truthy(nearestSite, nearestReason)
T.equal(nearestReason, "nearby_meta_building_found")
T.near(nearestSite.home.x, 10590, 0.5, "picks closest MetaGrid building")
T.near(nearestSite.home.y, 10305, 0.5)

-- 4. Verify CoreProvider assigns cached shelter order to promoted AI community actors.
T.load("ProjectHoomans", "shared", "PNC/Core/Persistence/PNC_Persistence_CoreProvider.lua")
local Adapter = PNC.Persistence.CoreProvider
Adapter._aiBuildingOrderCache = {}
local findCalls = 0
local origFindNear = PNC.CommunitySiteResolver.FindAvailableNear
PNC.CommunitySiteResolver.FindAvailableNear = function(...)
    findCalls = findCalls + 1
    return origFindNear(...)
end

local coreReg = Core.NewRegistry()
local a1 = coreReg:Create({
    actorId = "npc_ai_res_1",
    identitySeed = "ai-res-1",
    world = { location = { position = { x = 10580, y = 10305, z = 0 } } },
    extensions = {
        ["PsychopatzCore.SurvivorWorld"] = {
            communityID = "community_test_ai",
            factionID = "faction_test_ai",
            role = "resident",
        },
    },
})
local a2 = coreReg:Create({
    actorId = "npc_ai_res_2",
    identitySeed = "ai-res-2",
    world = { location = { position = { x = 10580, y = 10305, z = 0 } } },
    extensions = {
        ["PsychopatzCore.SurvivorWorld"] = {
            communityID = "community_test_ai",
            factionID = "faction_test_ai",
            role = "resident",
        },
    },
})
local coreEnv = {
    Actors = {
        DefaultRegistry = coreReg,
        Provider = Core.Provider,
    },
}

local r1 = Adapter.PromoteCoreActor(a1, coreEnv, { reason = "presence_interest" })
local r2 = Adapter.PromoteCoreActor(a2, coreEnv, { reason = "presence_interest" })
T.truthy(r1 and r1.orderSpec, "first promoted AI actor gets default orderSpec")
T.equal(r1.orderSpec.kind, PNC.Const.ORDER_ROAM)
T.equal(r1.orderSpec.roamMode, PNC.Const.ROAM_MODE_SHELTER)
T.equal(r1.orderSpec.ambientObjective, "shelter")
T.near(r1.orderSpec.x, 10590, 0.5)
T.truthy(r2 and r2.orderSpec, "second promoted AI actor gets default orderSpec")
T.equal(r2.orderSpec.roamMode, PNC.Const.ROAM_MODE_SHELTER)
T.equal(findCalls, 1, "community building lookup is cached across residents")
PNC.CommunitySiteResolver.FindAvailableNear = origFindNear

-- 5. Verify RoamingSeat allows sheltered and ambientVisit camp AI NPCs to sit.
PNC.AutonomyExecutors = PNC.AutonomyExecutors or {}
PNC.AutonomyExecutors.RoamingSeat = PNC.AutonomyExecutors.RoamingSeat or {
    MIN_IDLE_MS = 1200,
    Internal = {},
}
PNC.AmbientVisitService = {
    CanUseAmbient = function() return true end,
}
T.load("ProjectHoomans", "server", "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamingSeat_Policy.lua")
local seatPolicy = PNC.AutonomyExecutors.RoamingSeat
local campVisitRec = {
    id = "npc_ai_res_1",
    alive = true,
    orderSpec = { kind = PNC.Const.ORDER_CAMP or "camp", ambientVisit = true },
    runtime = {},
}
T.truthy(
    seatPolicy.CanAttempt(campVisitRec, fakeZombie, nil, 5000),
    "ambientVisit camp AI NPC can sit on indoor objects"
)
local shelteredRec = {
    id = "npc_ai_res_2",
    alive = true,
    orderSpec = { kind = PNC.Const.ORDER_ROAM or "roam", roamMode = "shelter" },
    runtime = {},
}
T.truthy(
    seatPolicy.CanAttempt(shelteredRec, fakeZombie, { phase = "sheltered", idleSince = 0 }, 5000),
    "sheltered AI NPC can sit on indoor objects"
)

T.finish("pnc_ai_building_autonomy_and_loot_move_smoke")
