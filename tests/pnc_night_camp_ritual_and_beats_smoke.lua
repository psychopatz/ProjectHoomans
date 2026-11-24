local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 100000
local currentWorldHours = 29.0
local currentTimeOfDay = 14.0

getGameTime = function()
    return {
        getWorldAgeHours = function() return currentWorldHours end,
        getTimeOfDay = function() return currentTimeOfDay end,
    }
end

local squares = {}
local function makeSquare(x, y, z)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        isSolid = function() return false end,
        isSolidTrans = function() return false end,
        haveFire = function() return false end,
        isFree = function() return true end,
        isOutside = function() return true end,
        getBuilding = function() return nil end,
        getCampfire = function() return nil end,
    }
end
for x = 90, 110 do
    for y = 90, 110 do
        squares[x .. ":" .. y .. ":0"] = makeSquare(x, y, 0)
    end
end
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[math.floor(x) .. ":" .. math.floor(y) .. ":" .. math.floor(z)]
        end,
    }
end

local campfiresAdded = 0
local campfiresLit = 0
SCampfireSystem = {
    instance = {
        getLuaObjectOnSquare = function() return nil end,
        addCampfire = function(_, sq)
            campfiresAdded = campfiresAdded + 1
            local modData = {}
            return {
                getIsoObject = function()
                    return { getModData = function() return modData end }
                end,
                addFuel = function() end,
                lightFire = function() campfiresLit = campfiresLit + 1 end,
                saveData = function() end,
            }
        end,
        removeCampfire = function() end,
    },
}

local recordsById = {}
local nearbyPlayer = nil
local emittedBeats = {}
local stoppedScenes = {}

PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Core = {
        Now = function() return nowMs end,
        ForEachPlayer = function(fn)
            if nearbyPlayer then fn(nearbyPlayer) end
        end,
    },
    Registry = {
        Get = function(id) return recordsById[tostring(id)] end,
    },
    AnimationScenes = {
        Stop = function(rec, z, reason)
            stoppedScenes[#stoppedScenes + 1] = { id = rec.id, reason = reason }
            if rec.runtime then rec.runtime.animationScene = nil end
        end,
    },
    Semantics = {
        DialogueBeats = {
            RegisterHook = function() end,
            Emit = function(eventName, payload, at)
                emittedBeats[#emittedBeats + 1] = { event = eventName, payload = payload, at = at }
                return true, eventName
            end,
        },
    },
}

T.load("ProjectHoomans", "server", "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamAmbient_Policy.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamAmbient_Schedule.lua")
T.load("ProjectHoomans", "server", "PNC/World/PNC_NightCampService.lua")

local RoamAmbient = PNC.AutonomyExecutors.RoamAmbient
local NightCamp = PNC.NightCampService

local function makeNPC(id, x, y)
    local rec = {
        id = id,
        name = id,
        alive = true,
        presenceState = "live",
        factionID = "campers",
        identitySeed = 42,
        x = x, y = y, z = 0,
        runtime = {},
    }
    recordsById[id] = rec
    local z = {
        getX = function() return rec.x end,
        getY = function() return rec.y end,
        getZ = function() return rec.z end,
    }
    return rec, z
end

-- 1. Daytime gate: 2:00 PM with worldAgeHours=29 must NOT trigger night sleep or campfire.
do
    currentWorldHours = 29.0
    currentTimeOfDay = 14.0
    local rec, z = makeNPC("npc_day", 100.5, 100.5)
    local plan = RoamAmbient.GetActionPlan(rec, currentWorldHours)
    T.truthy(plan == nil or plan.action ~= "sleep",
        "daytime 14:00 should not schedule night camp sleep even when worldAgeHours=29")
    local cand = NightCamp.ResolveNightCandidate(rec, z, { wakeAt = 37 }, nowMs)
    T.equal(cand, nil, "NightCampService should refuse to build outdoor campfire during daytime")
    T.equal(campfiresAdded, 0, "no campfire should be spawned during daytime")
end

-- 2. Evening night camp (8:00 PM): live build ritual (LootLow) -> dialogue beats -> fire built -> circle seating.
do
    NightCamp.Reset()
    recordsById = {}
    emittedBeats = {}
    campfiresAdded = 0
    campfiresLit = 0
    currentWorldHours = 35.0
    currentTimeOfDay = 20.0

    local r1, z1 = makeNPC("npc_a", 100.5, 100.5)
    local r2, z2 = makeNPC("npc_b", 101.5, 100.5)
    local r3, z3 = makeNPC("npc_c", 99.5, 100.5)

    local plan1 = RoamAmbient.GetActionPlan(r1, currentWorldHours)
    T.truthy(plan1 ~= nil and plan1.action == "sleep", "20:00 should trigger night camp plan")

    local c1 = NightCamp.ResolveNightCandidate(r1, z1, plan1, nowMs)
    local c2 = NightCamp.ResolveNightCandidate(r2, z2, plan1, nowMs)
    local c3 = NightCamp.ResolveNightCandidate(r3, z3, plan1, nowMs)

    T.truthy(c1 ~= nil, "builder candidate missing")
    T.equal(c1.role, "builder", "first camper should be designated campfire builder")
    T.equal(c1.target.sceneId, "ambient.roam.camp.build", "builder should use LootLow build scene")
    T.equal(campfiresAdded, 0, "campfire should NOT be spawned before build ritual completes")

    -- Other members gather in radius-2 circle around the planned campfire (never on it).
    local gCamp = NightCamp.GroupCamps["grp:campers"]
    T.equal(c2.role, "fireside", "second camper should sit in evening fireside circle")
    T.equal(c2.target.sceneId, "ambient.roam.camp.fireside", "evening camper should use fireside scene")
    T.equal(c3.role, "fireside", "third camper should sit in evening fireside circle")
    local dist2 = math.sqrt((c2.target.x - (gCamp.fireX + 0.5)) ^ 2 + (c2.target.y - (gCamp.fireY + 0.5)) ^ 2)
    local dist3 = math.sqrt((c3.target.x - (gCamp.fireX + 0.5)) ^ 2 + (c3.target.y - (gCamp.fireY + 0.5)) ^ 2)
    T.truthy(dist2 >= 1.9 and dist3 >= 1.9, "campers must sit in circle away from campfire center")
    T.truthy(c2.target.x ~= c3.target.x or c2.target.y ~= c3.target.y, "campers should take distinct circle slots")

    -- Builder starts building: emits build_start dialogue beat (propose -> wood -> lighter).
    local state1 = { action = "sleep", campRole = "builder", sceneId = "ambient.roam.camp.build", tempCampfireKey = gCamp.fireKey }
    local state2 = { action = "sleep", campRole = "fireside", sceneId = "ambient.roam.camp.fireside", tempCampfireKey = gCamp.fireKey }
    local state3 = { action = "sleep", campRole = "fireside", sceneId = "ambient.roam.camp.fireside", tempCampfireKey = gCamp.fireKey }

    NightCamp.TickCampMember(r1, z1, state1, nowMs, currentTimeOfDay)
    T.equal(#emittedBeats, 1, "build_start beat did not fire")
    T.equal(emittedBeats[1].event, "night_camp.build_start", "expected night_camp.build_start beat")
    T.equal(#emittedBeats[1].payload.helpers, 2, "build_start should include both group helpers")
    T.equal(campfiresAdded, 0, "campfire should wait for build duration to finish")

    -- Complete build duration -> campfire spawns & lights, builder transitions to fireside circle.
    nowMs = nowMs + NightCamp.CAMPFIRE_BUILD_DURATION_MS + 100
    local transitioned = NightCamp.TickCampMember(r1, z1, state1, nowMs, currentTimeOfDay)
    T.truthy(transitioned, "builder did not transition after finishing campfire build")
    T.equal(campfiresAdded, 1, "campfire was not created after build ritual")
    T.equal(campfiresLit, 1, "campfire was not lit after build ritual")
    T.equal(state1.campRole, "fireside", "builder did not join fireside circle")
    T.equal(state1.sceneId, "ambient.roam.camp.fireside", "builder scene did not switch to fireside")

    -- 3. Evening stories & player interaction beats.
    nowMs = nowMs + NightCamp.STORY_INTERVAL_MS + 1000
    NightCamp.TickCampMember(r1, z1, state1, nowMs, currentTimeOfDay)
    T.equal(emittedBeats[#emittedBeats].event, "night_camp.story", "evening fireside story beat did not fire")

    nearbyPlayer = {
        getX = function() return gCamp.fireX + 3 end,
        getY = function() return gCamp.fireY + 1 end,
        getZ = function() return 0 end,
        getUsername = function() return "Patz" end,
    }
    nowMs = nowMs + NightCamp.PLAYER_INTERACT_INTERVAL_MS + 1000
    NightCamp.TickCampMember(r2, z2, state2, nowMs, currentTimeOfDay)
    T.equal(emittedBeats[#emittedBeats].event, "night_camp.player_invite", "fireside player invite beat did not fire")

    -- 4. 11:00 PM curfew: 1 lookout (sentry), others sleep, watch_handoff & lookout_player beats fire.
    currentTimeOfDay = 23.2
    nowMs = nowMs + 2000
    T.truthy(NightCamp.TickCampMember(r1, z1, state1, nowMs, currentTimeOfDay), "r1 did not transition at 11 PM")
    T.truthy(NightCamp.TickCampMember(r2, z2, state2, nowMs, currentTimeOfDay), "r2 did not transition at 11 PM")
    T.truthy(NightCamp.TickCampMember(r3, z3, state3, nowMs, currentTimeOfDay), "r3 did not transition at 11 PM")

    local sentryCount, sleepCount = 0, 0
    for _, st in ipairs({ state1, state2, state3 }) do
        if st.campRole == "sentry" and st.sceneId == "ambient.roam.camp.sentry" then
            sentryCount = sentryCount + 1
        elseif st.campRole == "sleeper" and st.sceneId == "ambient.roam.sleep.floor" then
            sleepCount = sleepCount + 1
        end
    end
    T.equal(sentryCount, 1, "exactly 1 group member should stay awake on lookout at 11 PM")
    T.equal(sleepCount, 2, "remaining group members should sleep at 11 PM")

    local sawHandoff = false
    for i = 1, #emittedBeats do
        if emittedBeats[i].event == "night_camp.watch_handoff" then sawHandoff = true end
    end
    T.truthy(sawHandoff, "11 PM watch_handoff beat did not fire")

    -- Lookout interacts with nearby player during night watch.
    nowMs = nowMs + NightCamp.PLAYER_INTERACT_INTERVAL_MS + 1000
    local sentryRec = (state1.campRole == "sentry" and r1) or (state2.campRole == "sentry" and r2) or r3
    local sentryZ = (state1.campRole == "sentry" and z1) or (state2.campRole == "sentry" and z2) or z3
    local sentryState = (state1.campRole == "sentry" and state1) or (state2.campRole == "sentry" and state2) or state3
    NightCamp.TickCampMember(sentryRec, sentryZ, sentryState, nowMs, currentTimeOfDay)
    T.equal(emittedBeats[#emittedBeats].event, "night_camp.lookout_player", "lookout player beat did not fire")
end

T.finish("pnc_night_camp_ritual_and_beats_smoke")
