-- Unified server-only Night Camp & Shelter Service for non-colonist NPCs.
-- Zero global ModData bloat: all camp/room caches live in bounded ephemeral
-- server memory; temporary campfires use vanilla SCampfireSystem and are
-- cleanly removed at dawn, on group departure/demotion, or on expiry.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NightCampService = PNC.NightCampService or {}

local Service = PNC.NightCampService
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"

Service.MAX_TEMP_CAMPFIRES = 24
Service.MAX_BUILDING_CACHE = 32
Service.BUILDING_CACHE_TTL_MS = 30000
Service.CAMPFIRE_FUEL_MINUTES = 240
Service.PRUNE_INTERVAL_MS = 30000
Service.CAMP_START_HOUR = 19
Service.SLEEP_CURFEW_HOUR = 23
Service.NIGHT_END_HOUR = 6
Service.CAMPFIRE_BUILD_DURATION_MS = 4500
Service.STORY_INTERVAL_MS = 38000
Service.PLAYER_INTERACT_INTERVAL_MS = 50000
Service.PLAYER_INTERACT_RADIUS = 10

-- Strictly in-memory ephemeral tables (never serialized to ModData).
Service.TempCampfires = Service.TempCampfires or {}
Service.TempCampfireCount = tonumber(Service.TempCampfireCount) or 0
Service.GroupCamps = Service.GroupCamps or {}
Service.BuildingCache = Service.BuildingCache or {}
Service.BuildingCacheOrder = Service.BuildingCacheOrder or {}
Service.NextPruneAt = tonumber(Service.NextPruneAt) or 0

local ROOM_PRIORITY = {
    bedroom = 100,
    livingroom = 60,
    lounge = 60,
    diningroom = 50,
    office = 45,
    hall = 40,
    kitchen = 30,
    bathroom = 10,
    closet = 10,
}

local CAMP_RING_OFFSETS = {
    { 2, 0, "W" }, { -2, 0, "E" }, { 0, 2, "N" }, { 0, -2, "S" },
    { 2, 1, "W" }, { -2, -1, "E" }, { 1, 2, "N" }, { -1, -2, "S" },
    { 2, -1, "W" }, { -2, 1, "E" }, { -1, 2, "N" }, { 1, -2, "S" },
}

local BUILD_STAND_OFFSETS = {
    { 1, 0, "W" }, { -1, 0, "E" }, { 0, 1, "N" }, { 0, -1, "S" },
}

local function currentTimeOfDay(override)
    if override ~= nil then return (tonumber(override) or 0) % 24 end
    local clock = PNC.WorldClock
    if clock and type(clock.GetTimeOfDay) == "function" then
        return clock.GetTimeOfDay()
    end
    local gt = type(getGameTime) == "function" and getGameTime() or nil
    if gt and gt.getTimeOfDay then
        local tod = tonumber(gt:getTimeOfDay())
        if tod ~= nil then return tod % 24 end
    end
    local roam = PNC.AutonomyExecutors and PNC.AutonomyExecutors.RoamAmbient or nil
    if roam and type(roam.GetTimeOfDay) == "function" then
        return roam.GetTimeOfDay()
    end
    return 0
end

function Service.IsNightTime(timeOfDayOverride)
    local clock = PNC.WorldClock
    if clock and type(clock.IsNightCampHour) == "function" then
        return clock.IsNightCampHour(timeOfDayOverride)
    end
    local tod = currentTimeOfDay(timeOfDayOverride)
    return tod >= Service.CAMP_START_HOUR or tod < Service.NIGHT_END_HOUR
end

function Service.IsSleepCurfew(timeOfDayOverride)
    local clock = PNC.WorldClock
    if clock and type(clock.IsSleepCurfewHour) == "function" then
        return clock.IsSleepCurfewHour(timeOfDayOverride)
    end
    local tod = currentTimeOfDay(timeOfDayOverride)
    return tod >= Service.SLEEP_CURFEW_HOUR or tod < Service.NIGHT_END_HOUR
end

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function worldAgeHours()
    local clock = PNC.WorldClock
    if clock and type(clock.GetWorldAgeHours) == "function" then
        return clock.GetWorldAgeHours()
    end
    local gt = type(getGameTime) == "function" and getGameTime() or nil
    if gt and gt.getWorldAgeHours then
        return tonumber(gt:getWorldAgeHours()) or 0
    end
    return 0
end

local function squareKey(x, y, z)
    return tostring(math.floor(tonumber(x) or 0)) .. ":"
        .. tostring(math.floor(tonumber(y) or 0)) .. ":"
        .. tostring(math.floor(tonumber(z) or 0))
end

local function groupKeyFor(record)
    if type(record) ~= "table" then return "solo" end
    local key = record.factionID or record.groupId or record.mobileGroupId
    if key ~= nil and tostring(key) ~= "" then
        return "grp:" .. tostring(key)
    end
    return "npc:" .. tostring(record.id or "solo")
end

local function isWalkableSpot(square)
    if not square then return false end
    if square.isSolid and square:isSolid() == true then return false end
    if square.isSolidTrans and square:isSolidTrans() == true then return false end
    if square.haveFire and square:haveFire() == true then return false end
    if square.isFree and square:isFree(false) ~= true then return false end
    return true
end

local function isOutdoorCampfireSquare(square)
    if not square then return false end
    if square.isOutside and square:isOutside() ~= true then return false end
    if square.getBuilding and square:getBuilding() ~= nil then return false end
    return isWalkableSpot(square)
end

local function getSquare(cell, x, y, z)
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(math.floor(x), math.floor(y), math.floor(z))
end

local function findExistingCampfireNear(cell, ox, oy, oz, radius)
    local r = math.min(6, math.max(1, tonumber(radius) or 4))
    for dx = -r, r do
        for dy = -r, r do
            local sq = getSquare(cell, ox + dx, oy + dy, oz)
            if sq and sq.getCampfire and sq:getCampfire() ~= nil then
                return sq
            end
        end
    end
    return nil
end

local function spawnTemporaryCampfire(square, groupKey, wakeAt, at)
    if not square or not SCampfireSystem or not SCampfireSystem.instance then
        return nil
    end
    if Service.TempCampfireCount >= Service.MAX_TEMP_CAMPFIRES then
        return nil
    end
    local sys = SCampfireSystem.instance
    local existing = sys.getLuaObjectOnSquare and sys:getLuaObjectOnSquare(square)
    local luaObj = existing
    if not luaObj and type(sys.addCampfire) == "function" then
        local ok, created = pcall(sys.addCampfire, sys, square)
        if ok then luaObj = created end
    end
    if not luaObj then return nil end
    local isoObj = luaObj.getIsoObject and luaObj:getIsoObject() or nil
    if not existing then
        if luaObj.addFuel then
            pcall(luaObj.addFuel, luaObj, Service.CAMPFIRE_FUEL_MINUTES)
        end
        if luaObj.lightFire then
            pcall(luaObj.lightFire, luaObj)
        end
        if luaObj.saveData then
            pcall(luaObj.saveData, luaObj)
        end
        if isoObj and isoObj.getModData then
            local md = isoObj:getModData()
            if md then
                md.PNC_TempCampfire = true
                md.PNC_TempCampfireOwner = groupKey
                md.PNC_TempCampfireExpiresAt = tonumber(wakeAt) or (worldAgeHours() + 8)
            end
        end
    end
    local cx, cy, cz = square:getX(), square:getY(), square:getZ()
    local key = squareKey(cx, cy, cz)
    if not Service.TempCampfires[key] then
        Service.TempCampfireCount = Service.TempCampfireCount + 1
    end
    Service.TempCampfires[key] = {
        key = key,
        x = cx, y = cy, z = cz,
        groupKey = groupKey,
        expiresAt = tonumber(wakeAt) or (worldAgeHours() + 8),
        createdAt = nowMs(at),
        members = {},
    }
    return Service.TempCampfires[key]
end

function Service.RemoveTemporaryCampfire(key)
    local entry = Service.TempCampfires[key]
    if not entry then return false end
    Service.TempCampfires[key] = nil
    Service.TempCampfireCount = math.max(0, Service.TempCampfireCount - 1)
    if entry.groupKey and Service.GroupCamps[entry.groupKey]
        and Service.GroupCamps[entry.groupKey].fireKey == key
    then
        Service.GroupCamps[entry.groupKey] = nil
    end
    local sys = SCampfireSystem and SCampfireSystem.instance or nil
    local cell = type(getCell) == "function" and getCell() or nil
    local sq = cell and getSquare(cell, entry.x, entry.y, entry.z) or nil
    if sys and sq and sys.getLuaObjectOnSquare then
        local luaObj = sys:getLuaObjectOnSquare(sq)
        local isoObj = luaObj and luaObj.getIsoObject and luaObj:getIsoObject() or nil
        local md = isoObj and isoObj.getModData and isoObj:getModData() or nil
        if luaObj and md and md.PNC_TempCampfire == true then
            if type(sys.removeCampfire) == "function" then
                pcall(sys.removeCampfire, sys, luaObj)
            elseif type(sys.putOut) == "function" then
                pcall(sys.putOut, sys, luaObj)
            end
        end
    end
    return true
end

local function cachedBuildingRooms(building, at)
    local def = building and building.getDef and building:getDef() or nil
    local bId = def and def.getID and tostring(def:getID()) or tostring(building)
    local now = nowMs(at)
    local cached = Service.BuildingCache[bId]
    if cached and now < cached.expiresAt then
        return cached.rooms
    end
    local rooms = {}
    local list = def and def.getRooms and def:getRooms() or nil
    local count = list and list.size and list:size() or 0
    for i = 0, count - 1 do
        local roomDef = list:get(i)
        if roomDef then
            local name = string.lower(tostring(
                roomDef.getName and roomDef:getName() or ""))
            local prio = ROOM_PRIORITY[name] or 25
            rooms[#rooms + 1] = {
                roomDef = roomDef,
                name = name,
                priority = prio,
                x = roomDef.getX and roomDef:getX() or nil,
                y = roomDef.getY and roomDef:getY() or nil,
                w = roomDef.getW and roomDef:getW() or 1,
                h = roomDef.getH and roomDef:getH() or 1,
                z = roomDef.getZ and roomDef:getZ() or 0,
            }
        end
    end
    table.sort(rooms, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        return tostring(a.name) < tostring(b.name)
    end)
    if not Service.BuildingCache[bId] then
        Service.BuildingCacheOrder[#Service.BuildingCacheOrder + 1] = bId
        while #Service.BuildingCacheOrder > Service.MAX_BUILDING_CACHE do
            local oldest = table.remove(Service.BuildingCacheOrder, 1)
            Service.BuildingCache[oldest] = nil
        end
    end
    Service.BuildingCache[bId] = {
        rooms = rooms,
        expiresAt = now + Service.BUILDING_CACHE_TTL_MS,
    }
    return rooms
end

local function sceneIdForCampRole(role)
    if role == "builder" then return "ambient.roam.camp.build" end
    if role == "fireside" then return "ambient.roam.camp.fireside" end
    if role == "sentry" then return "ambient.roam.camp.sentry" end
    return "ambient.roam.sleep.floor"
end

local function makeFloorSleepCandidate(record, x, y, z, facing, role, fireKey)
    local sceneId = sceneIdForCampRole(role)
    local resourceKind = role == "builder" and "camp_builder"
        or (role == "fireside" and "camp_fireside"
            or (role == "sentry" and "camp_sentry" or "floor_sleep"))
    local resourceKey = (fireKey and ("nightcamp:" .. fireKey) or "nightroom")
        .. ":" .. tostring(record and record.id or "npc")
    local resource = {
        kind = "virtual",
        detectorId = "virtual",
        resourceKind = resourceKind,
        sleepSurface = "floor",
        resourceKey = resourceKey,
        x = x + 0.5, y = y + 0.5, z = z,
        originX = x, originY = y, originZ = z,
        exclusive = false,
        available = true,
        virtual = true,
        campRole = role or "sleeper",
        tempCampfireKey = fireKey,
    }
    local target = {
        x = x + 0.5, y = y + 0.5, z = z,
        sleepSurface = "floor",
        sleepFacing = facing or "S",
        sceneId = sceneId,
        resourceKey = resourceKey,
        resourceKind = resource.resourceKind,
        validSpot = true,
        campRole = role or "sleeper",
        tempCampfireKey = fireKey,
    }
    return {
        object = nil,
        resource = resource,
        target = target,
        targets = { target },
        role = role or "sleeper",
        tempCampfireKey = fireKey,
    }
end

local function pickIndoorRoomFloorSpot(record, cell, building, originZ, at)
    local rooms = cachedBuildingRooms(building, at)
    if #rooms == 0 then return nil end
    local seed = math.abs(tonumber(record and record.identitySeed) or 1)
    for i = 1, #rooms do
        local room = rooms[i]
        if room.x and room.y and math.floor(room.z) == math.floor(originZ) then
            local cx = math.floor(room.x + (seed % math.max(1, room.w)))
            local cy = math.floor(room.y + ((seed + i) % math.max(1, room.h)))
            local sq = getSquare(cell, cx, cy, originZ)
            if isWalkableSpot(sq) then
                return makeFloorSleepCandidate(record, cx, cy, originZ, "S", "sleeper", nil)
            end
        end
    end
    return nil
end

local function pickCampRole(groupCamp, record)
    local npcId = tostring(record and record.id or "")
    if not groupCamp or npcId == "" then return "sleeper" end
    if groupCamp.sentryNpcId == npcId then return "sentry" end
    -- Multi-member outdoor camps designate 1 awake sentry; solo campers sleep.
    local memberCount = 0
    for _ in pairs(groupCamp.members) do
        memberCount = memberCount + 1
    end
    if memberCount >= 1 and groupCamp.sentryNpcId == nil then
        groupCamp.sentryNpcId = npcId
        return "sentry"
    end
    return "sleeper"
end

local function assignCircleSlot(groupCamp, npcId, cell)
    groupCamp.slots = groupCamp.slots or {}
    local existingIdx = groupCamp.slots[npcId]
    if existingIdx then
        local e = CAMP_RING_OFFSETS[existingIdx]
        if e then
            local sq = getSquare(cell, groupCamp.fireX + e[1], groupCamp.fireY + e[2], groupCamp.fireZ)
            if isWalkableSpot(sq) then
                return groupCamp.fireX + e[1], groupCamp.fireY + e[2], groupCamp.fireZ, e[3]
            end
        end
    end
    local used = {}
    for id, idx in pairs(groupCamp.slots) do
        if id ~= npcId and groupCamp.members[id] then
            used[idx] = true
        end
    end
    for i = 1, #CAMP_RING_OFFSETS do
        if not used[i] then
            local e = CAMP_RING_OFFSETS[i]
            local sx = groupCamp.fireX + e[1]
            local sy = groupCamp.fireY + e[2]
            local sq = getSquare(cell, sx, sy, groupCamp.fireZ)
            if isWalkableSpot(sq) then
                groupCamp.slots[npcId] = i
                return sx, sy, groupCamp.fireZ, e[3]
            end
        end
    end
    for i = 1, #CAMP_RING_OFFSETS do
        local e = CAMP_RING_OFFSETS[i]
        local sx = groupCamp.fireX + e[1]
        local sy = groupCamp.fireY + e[2]
        local sq = getSquare(cell, sx, sy, groupCamp.fireZ)
        if isWalkableSpot(sq) then
            groupCamp.slots[npcId] = i
            return sx, sy, groupCamp.fireZ, e[3]
        end
    end
    return nil
end

local function findBuildStandSpot(groupCamp, cell)
    for i = 1, #BUILD_STAND_OFFSETS do
        local e = BUILD_STAND_OFFSETS[i]
        local sx = groupCamp.fireX + e[1]
        local sy = groupCamp.fireY + e[2]
        local sq = getSquare(cell, sx, sy, groupCamp.fireZ)
        if isWalkableSpot(sq) then
            return sx, sy, groupCamp.fireZ, e[3]
        end
    end
    return assignCircleSlot(groupCamp, groupCamp.builderNpcId or "builder", cell)
end

local function collectLiveGroupRecords(groupCamp, excludeNpcId)
    local out = {}
    local reg = PNC.Registry
    if not groupCamp or not reg or type(reg.Get) ~= "function" then
        return out
    end
    for id in pairs(groupCamp.members or {}) do
        if id ~= excludeNpcId then
            local rec = reg.Get(id)
            if rec and rec.alive ~= false
                and (rec.presenceState == nil or rec.presenceState == (PNC.Const and PNC.Const.PRESENCE_LIVE or "live"))
            then
                out[#out + 1] = rec
            end
        end
    end
    return out
end

local function findNearbyPlayer(x, y, z, radius)
    local core = PNC.Core
    if not core or type(core.ForEachPlayer) ~= "function" then return nil, nil end
    local maxDistSq = (tonumber(radius) or Service.PLAYER_INTERACT_RADIUS) ^ 2
    local bestPlayer, bestName, bestDistSq = nil, nil, maxDistSq
    core.ForEachPlayer(function(p)
        if not p then return end
        local px = p.getX and tonumber(p:getX())
        local py = p.getY and tonumber(p:getY())
        local pz = p.getZ and tonumber(p:getZ()) or 0
        if not px or not py or math.abs(pz - (tonumber(z) or 0)) >= 1 then return end
        local dx, dy = px - x, py - y
        local dSq = dx * dx + dy * dy
        if dSq <= bestDistSq then
            bestDistSq = dSq
            bestPlayer = p
            local desc = p.getDescriptor and p:getDescriptor() or nil
            bestName = (desc and desc.getForename and desc:getForename())
                or (p.getDisplayName and p:getDisplayName())
                or (p.getUsername and p:getUsername())
                or "friend"
        end
    end)
    return bestPlayer, bestName
end

function Service.CommitTemporaryCampfire(groupCamp, at)
    if type(groupCamp) ~= "table" then return nil end
    if groupCamp.fireBuilt == true then
        return Service.TempCampfires[groupCamp.fireKey]
    end
    local cell = type(getCell) == "function" and getCell() or nil
    local sq = cell and getSquare(cell, groupCamp.fireX, groupCamp.fireY, groupCamp.fireZ) or nil
    if not sq then return nil end
    local fireEntry = spawnTemporaryCampfire(sq, groupCamp.groupKey, groupCamp.expiresAt, at)
    if not fireEntry then return nil end
    for id in pairs(groupCamp.members or {}) do
        fireEntry.members[id] = true
    end
    groupCamp.fireBuilt = true
    groupCamp.buildPhase = "built"
    groupCamp.fireKey = fireEntry.key
    return fireEntry
end

local function resolveOutdoorCampCandidate(record, zombie, cell, plan, at)
    local tod = plan and plan.timeOfDay or currentTimeOfDay()
    if not Service.IsNightTime(tod) then
        return nil
    end
    local ox = math.floor(zombie:getX())
    local oy = math.floor(zombie:getY())
    local oz = math.floor(zombie:getZ())
    local gKey = groupKeyFor(record)
    local groupCamp = Service.GroupCamps[gKey]
    local npcId = tostring(record.id or "")
    local isCurfew = Service.IsSleepCurfew(tod)

    if not groupCamp then
        local existingFireSq = findExistingCampfireNear(cell, ox, oy, oz, 5)
        local fireSq = existingFireSq
        if not fireSq then
            local candidates = {
                { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
                { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 },
                { 0, 0 },
            }
            for i = 1, #candidates do
                local sq = getSquare(cell, ox + candidates[i][1], oy + candidates[i][2], oz)
                if isOutdoorCampfireSquare(sq) then
                    fireSq = sq
                    break
                end
            end
        end
        if not fireSq then return nil end
        local fx, fy, fz = fireSq:getX(), fireSq:getY(), fireSq:getZ()
        local fKey = squareKey(fx, fy, fz)
        groupCamp = {
            groupKey = gKey,
            fireKey = fKey,
            fireX = fx,
            fireY = fy,
            fireZ = fz,
            fireBuilt = existingFireSq ~= nil,
            buildPhase = existingFireSq ~= nil and "built" or "pending",
            builderNpcId = existingFireSq == nil and npcId or nil,
            buildStartedAt = nil,
            buildFinishAt = nil,
            buildBeatFired = false,
            phase = isCurfew and "night_watch" or "evening_fireside",
            watchBeatFired = false,
            nextStoryAt = nowMs(at) + 12000,
            nextPlayerBeatAt = nowMs(at) + 15000,
            storyIndex = 0,
            sentryNpcId = nil,
            members = {},
            slots = {},
            expiresAt = tonumber(plan and plan.wakeAt) or (worldAgeHours() + 8),
        }
        Service.GroupCamps[gKey] = groupCamp
        if existingFireSq ~= nil then
            spawnTemporaryCampfire(existingFireSq, gKey, groupCamp.expiresAt, at)
        end
    end

    groupCamp.members[npcId] = true
    local fireEntry = Service.TempCampfires[groupCamp.fireKey]
    if fireEntry then
        fireEntry.members[npcId] = true
    end

    -- While the campfire is not yet built, the designated builder goes to the
    -- adjacent build spot to perform the LootLow build ritual + dialogue beats,
    -- while other group members gather in the radius-2 circle facing the spot.
    if groupCamp.fireBuilt ~= true and groupCamp.builderNpcId == npcId then
        local bx, by, bz, bFacing = findBuildStandSpot(groupCamp, cell)
        if not bx then return nil end
        return makeFloorSleepCandidate(
            record, bx, by, bz, bFacing, "builder", groupCamp.fireKey)
    end

    local role
    if isCurfew then
        role = pickCampRole(groupCamp, record)
    else
        role = "fireside"
    end
    local sx, sy, sz, facing = assignCircleSlot(groupCamp, npcId, cell)
    if not sx then return nil end
    return makeFloorSleepCandidate(
        record, sx, sy, sz, facing, role, groupCamp.fireKey)
end

local function switchMemberScene(record, zombie, state, newRole, cell)
    local npcId = tostring(record.id or "")
    local gKey = groupKeyFor(record)
    local groupCamp = Service.GroupCamps[gKey]
    local newSceneId = sceneIdForCampRole(newRole)
    state.campRole = newRole
    state.sceneId = newSceneId
    if state.resource then
        state.resource.campRole = newRole
    end
    if groupCamp and cell then
        local sx, sy, sz, facing = assignCircleSlot(groupCamp, npcId, cell)
        if sx then
            state.target = { x = sx + 0.5, y = sy + 0.5, z = sz }
            state.x, state.y, state.z = state.target.x, state.target.y, state.target.z
            state.sleepFacing = facing or state.sleepFacing or "S"
            state.arrivalSettled = false
            state.positioned = false
        end
    end
    local scenes = PNC.AnimationScenes
    if scenes and scenes.Stop and record.runtime and record.runtime.animationScene then
        pcall(scenes.Stop, record, zombie, "night_camp_phase_transition")
    end
    return true
end

function Service.TickCampMember(record, zombie, state, at, timeOfDayOverride)
    if not record or not zombie or type(state) ~= "table" then return false end
    if not state.tempCampfireKey then return false end
    local gKey = groupKeyFor(record)
    local groupCamp = Service.GroupCamps[gKey]
    if not groupCamp then return false end
    local now = nowMs(at)
    local npcId = tostring(record.id or "")
    local beats = PNC.Semantics and PNC.Semantics.DialogueBeats or nil
    local cell = type(getCell) == "function" and getCell() or nil
    local tod = currentTimeOfDay(timeOfDayOverride)
    local isCurfew = Service.IsSleepCurfew(tod)

    -- 1. Live campfire build ritual: builder plays LootLow while build dialogue beats play,
    -- then spawns & lights the campfire and moves to their radius-2 circle seat.
    if groupCamp.fireBuilt ~= true and state.campRole == "builder" then
        if groupCamp.buildPhase == "pending" then
            groupCamp.buildPhase = "building"
            groupCamp.buildStartedAt = now
            groupCamp.buildFinishAt = now + Service.CAMPFIRE_BUILD_DURATION_MS
            if not groupCamp.buildBeatFired and beats and type(beats.Emit) == "function" then
                groupCamp.buildBeatFired = true
                local helpers = collectLiveGroupRecords(groupCamp, npcId)
                beats.Emit("night_camp.build_start", {
                    builder = record,
                    helpers = helpers,
                    campKey = groupCamp.fireKey,
                    now = now,
                }, now)
            end
        end
        if groupCamp.buildPhase == "building"
            and now >= (tonumber(groupCamp.buildFinishAt) or 0)
        then
            Service.CommitTemporaryCampfire(groupCamp, now)
            local nextRole = isCurfew and pickCampRole(groupCamp, record) or "fireside"
            switchMemberScene(record, zombie, state, nextRole, cell)
            return true
        end
        return false
    end

    if groupCamp.fireBuilt ~= true then
        return false
    end

    -- 2. At 11:00 PM (curfew), transition evening fireside circle into 1 lookout + sleepers.
    if isCurfew then
        if groupCamp.phase ~= "night_watch" then
            groupCamp.phase = "night_watch"
            local desiredRole = pickCampRole(groupCamp, record)
            if not groupCamp.watchBeatFired and beats and type(beats.Emit) == "function" then
                groupCamp.watchBeatFired = true
                local sentryRec = (groupCamp.sentryNpcId == npcId) and record
                    or (PNC.Registry and PNC.Registry.Get and groupCamp.sentryNpcId and PNC.Registry.Get(groupCamp.sentryNpcId))
                    or record
                local others = collectLiveGroupRecords(groupCamp, sentryRec.id)
                beats.Emit("night_camp.watch_handoff", {
                    sentry = sentryRec,
                    sleeper = others[1],
                    campKey = groupCamp.fireKey,
                    now = now,
                }, now)
            end
            if state.campRole == "fireside" then
                switchMemberScene(record, zombie, state, desiredRole, cell)
                return true
            end
        elseif state.campRole == "fireside" then
            local desiredRole = pickCampRole(groupCamp, record)
            switchMemberScene(record, zombie, state, desiredRole, cell)
            return true
        end

        -- Night-watch lookout interacting with a nearby player.
        if state.campRole == "sentry"
            and now >= (tonumber(groupCamp.nextPlayerBeatAt) or 0)
            and beats and type(beats.Emit) == "function"
        then
            local player, playerName = findNearbyPlayer(
                groupCamp.fireX + 0.5, groupCamp.fireY + 0.5, groupCamp.fireZ,
                Service.PLAYER_INTERACT_RADIUS)
            if player then
                groupCamp.nextPlayerBeatAt = now + Service.PLAYER_INTERACT_INTERVAL_MS
                beats.Emit("night_camp.lookout_player", {
                    sentry = record,
                    playerName = playerName,
                    campKey = groupCamp.fireKey,
                    now = now,
                }, now)
            end
        end
        return false
    end

    -- 3. Evening fireside circle (19:00..22:59): stories & player invite beats.
    if beats and type(beats.Emit) == "function" then
        if now >= (tonumber(groupCamp.nextPlayerBeatAt) or 0) then
            local player, playerName = findNearbyPlayer(
                groupCamp.fireX + 0.5, groupCamp.fireY + 0.5, groupCamp.fireZ,
                Service.PLAYER_INTERACT_RADIUS)
            if player then
                groupCamp.nextPlayerBeatAt = now + Service.PLAYER_INTERACT_INTERVAL_MS
                beats.Emit("night_camp.player_invite", {
                    speaker = record,
                    playerName = playerName,
                    campKey = groupCamp.fireKey,
                    now = now,
                }, now)
                return false
            end
        end
        if now >= (tonumber(groupCamp.nextStoryAt) or 0) then
            local others = collectLiveGroupRecords(groupCamp, npcId)
            if #others >= 1 then
                groupCamp.nextStoryAt = now + Service.STORY_INTERVAL_MS
                groupCamp.storyIndex = (tonumber(groupCamp.storyIndex) or 0) + 1
                beats.Emit("night_camp.story", {
                    speaker = record,
                    partner = others[1],
                    third = others[2],
                    campKey = groupCamp.fireKey,
                    now = now,
                }, now)
            end
        end
    end
    return false
end

---Unified entry point for non-colonist night sleep/camping (bed -> bedroom -> outdoor campfire).
function Service.ResolveNightCandidate(record, zombie, plan, at)
    if not record or not zombie then return nil end
    local cell = type(getCell) == "function" and getCell() or nil
    if not cell or not cell.getGridSquare then return nil end
    local ox = math.floor(zombie:getX())
    local oy = math.floor(zombie:getY())
    local oz = math.floor(zombie:getZ())
    local currentSq = getSquare(cell, ox, oy, oz)
    local building = currentSq and currentSq.getBuilding and currentSq:getBuilding() or nil
    local roamAmbient = PNC.AutonomyExecutors and PNC.AutonomyExecutors.RoamAmbient or nil

    -- 1. If indoors (or near a real bed/sofa), prefer real beds/sofas first.
    if roamAmbient and type(roamAmbient.FindSleepSurface) == "function" then
        local surface = roamAmbient.FindSleepSurface(zombie)
        if surface then return surface end
    end

    -- 2. If inside a building without a bed in immediate reach, prefer bedrooms.
    if building then
        return pickIndoorRoomFloorSpot(record, cell, building, oz, at)
    end

    -- 3. Outdoors at night: establish/join a temporary campfire with 1 awake sentry.
    if currentSq and (not currentSq.isOutside or currentSq:isOutside() == true) then
        return resolveOutdoorCampCandidate(record, zombie, cell, plan, at)
    end
    return nil
end

function Service.ReleaseMember(record)
    if not record then return end
    local npcId = tostring(record.id or "")
    local gKey = groupKeyFor(record)
    local groupCamp = Service.GroupCamps[gKey]
    if not groupCamp then return end
    groupCamp.members[npcId] = nil
    if groupCamp.slots then
        groupCamp.slots[npcId] = nil
    end
    if groupCamp.builderNpcId == npcId then
        groupCamp.builderNpcId = nil
    end
    if groupCamp.sentryNpcId == npcId then
        groupCamp.sentryNpcId = nil
    end
    local fireEntry = Service.TempCampfires[groupCamp.fireKey]
    if fireEntry then
        fireEntry.members[npcId] = nil
    end
    local remaining = 0
    for _ in pairs(groupCamp.members) do
        remaining = remaining + 1
        break
    end
    if remaining == 0 then
        Service.RemoveTemporaryCampfire(groupCamp.fireKey)
        Service.GroupCamps[gKey] = nil
    end
end

function Service.Prune(now, currentHours)
    now = nowMs(now)
    if now < Service.NextPruneAt then return 0 end
    Service.NextPruneAt = now + Service.PRUNE_INTERVAL_MS
    local hours = tonumber(currentHours) or worldAgeHours()
    local toRemove = {}
    for key, entry in pairs(Service.TempCampfires) do
        local hasMembers = false
        for _ in pairs(entry.members) do
            hasMembers = true
            break
        end
        if not hasMembers or hours >= (tonumber(entry.expiresAt) or 0) then
            toRemove[#toRemove + 1] = key
        end
    end
    for i = 1, #toRemove do
        Service.RemoveTemporaryCampfire(toRemove[i])
    end
    return #toRemove
end

function Service.Reset()
    Service.TempCampfires = {}
    Service.TempCampfireCount = 0
    Service.GroupCamps = {}
    Service.BuildingCache = {}
    Service.BuildingCacheOrder = {}
    Service.NextPruneAt = 0
end

return Service
