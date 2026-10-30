-- Bounded candidate discovery for dedicated late-stream restart recovery.

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Const = PNC.Const

local function hintOf(record)
    local runtime = record and record.runtime or nil
    return runtime and runtime.startupBodyHint or nil
end

local function validSavedIdentity(value)
    return value ~= nil
        and tostring(value) ~= ""
        and tostring(value) ~= "0"
end

local function hasLateStreamBaseProof(hint)
    return hint ~= nil
        and tostring(hint.lease or "") ~= ""
        and tonumber(hint.x) ~= nil
        and tonumber(hint.y) ~= nil
        and tonumber(hint.z) ~= nil
end

local function hasSavedEngineIdentity(hint)
    return hint ~= nil
        and (
            validSavedIdentity(hint.instanceID)
            or validSavedIdentity(hint.populationId)
        )
end

function Internal.ValidLateStreamHint(record)
    local hint = hintOf(record)
    return hasLateStreamBaseProof(hint)
        and (
            hint.wasLive == true
            or hasSavedEngineIdentity(hint)
        )
end

function Internal.IsLegacyStrongLateStreamHint(record)
    local hint = hintOf(record)
    return hasLateStreamBaseProof(hint)
        and hint.wasLive ~= true
        and hasSavedEngineIdentity(hint)
end

function Internal.LateStreamSavedPosition(record)
    local hint = hintOf(record)
    if not hint then return nil end
    local x = tonumber(hint.x) or tonumber(record and record.x)
    local y = tonumber(hint.y) or tonumber(record and record.y)
    local z = tonumber(hint.z) or tonumber(record and record.z) or 0
    if x == nil or y == nil then return nil end
    return x, y, z
end

function Internal.LateStreamCenterSquare(record)
    local cell = getCell and getCell() or nil
    local x, y, z = Internal.LateStreamSavedPosition(record)
    if not cell or not cell.getGridSquare or x == nil then
        return nil
    end
    return cell:getGridSquare(
        math.floor(x),
        math.floor(y),
        math.floor(z)
    )
end

local function isZombieObject(object)
    if not object then return false end
    if instanceof then
        return instanceof(object, "IsoZombie") == true
    end
    return object.getPersistentOutfitID ~= nil
        or object.getOnlineID ~= nil
end

local function addCandidate(values, seen, object)
    if isZombieObject(object) and not seen[object] then
        seen[object] = true
        values[#values + 1] = object
    end
end

local function collectLoadedCandidates(record)
    local cell = getCell and getCell() or nil
    local x, y, z = Internal.LateStreamSavedPosition(record)
    local values = {}
    local seen = {}
    local radius = math.max(
        1,
        math.ceil(
            tonumber(Const.BODY_SHELL_REHYDRATE_ANON_RADIUS) or 1
        )
    )
    local dx
    local dy
    local square
    local objects
    local count
    local index

    if not cell or not cell.getGridSquare or x == nil then
        return values
    end

    for dx = -radius, radius do
        for dy = -radius, radius do
            square = cell:getGridSquare(
                math.floor(x) + dx,
                math.floor(y) + dy,
                math.floor(z)
            )
            objects = square and square.getMovingObjects
                and square:getMovingObjects() or nil
            if objects then
                count = objects.size and objects:size() or #objects
                for index = 0, count - 1 do
                    addCandidate(
                        values,
                        seen,
                        objects.get and objects:get(index)
                            or objects[index + 1]
                    )
                end
            end
        end
    end

    if PNC.SpatialIndex and PNC.SpatialIndex.QueryZombies then
        local nearby = PNC.SpatialIndex.QueryZombies(
            x,
            y,
            radius + 1.5
        )
        for index = 1, #nearby do
            addCandidate(values, seen, nearby[index])
        end
    end
    return values
end

local function savedEngineIdentityMatches(record, body)
    local hint = hintOf(record)
    local actualInstance
    if not hint or not body then return false end
    if Internal.StartupPopulationHintMatches
        and Internal.StartupPopulationHintMatches(record, body)
    then
        return true
    end
    if Internal.GetStartupBodyInstanceID
        and validSavedIdentity(hint.instanceID)
    then
        actualInstance = Internal.GetStartupBodyInstanceID(body)
        if actualInstance ~= nil
            and tostring(actualInstance) == tostring(hint.instanceID)
        then
            return true
        end
    end
    return false
end

function Internal.QuarantineLateStreamCandidate(body, source)
    if Internal.QuarantineRehydrateCandidate then
        Internal.QuarantineRehydrateCandidate(body, source)
        return
    end
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.ApplyHumanizedBodyFlags
    then
        PNC.LiveBodyControl.ApplyHumanizedBodyFlags(body)
        if PNC.LiveBodyControl.SuppressZombieSounds then
            PNC.LiveBodyControl.SuppressZombieSounds(body)
        end
    elseif Internal.clearBodyCombat then
        Internal.clearBodyCombat(body)
    end
end

function Internal.ClassifyLateStreamCandidates(record, now)
    local values = collectLoadedCandidates(record)
    local exact = {}
    local anonymous = {}
    local i
    local body
    local npcId
    local strong
    local eligible
    local settled

    for i = 1, #values do
        body = values[i]
        if not (Internal.IsProtectedBody
            and Internal.IsProtectedBody(body))
            and not (
                Internal.IsCanonicalStartupBody
                and Internal.IsCanonicalStartupBody(record, body)
            )
        then
            npcId, strong = Internal.GetLiveShellIdentity(body)
            if strong == true
                and npcId ~= nil
                and tostring(npcId) == tostring(record.id)
            then
                exact[#exact + 1] = body
            elseif savedEngineIdentityMatches(record, body) then
                exact[#exact + 1] = body
            elseif npcId == nil and strong ~= true
                and Internal.MatchAnonymousStartupRehydrate
            then
                eligible, settled =
                    Internal.MatchAnonymousStartupRehydrate(
                        record,
                        body,
                        now
                    )
                if eligible then
                    anonymous[#anonymous + 1] = {
                        body = body,
                        settled = settled == true,
                    }
                end
            end
        end
    end
    return exact, anonymous
end

return Internal
