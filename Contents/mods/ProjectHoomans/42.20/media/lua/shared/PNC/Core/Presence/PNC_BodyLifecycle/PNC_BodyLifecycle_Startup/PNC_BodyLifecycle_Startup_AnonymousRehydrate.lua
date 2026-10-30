-- Safe recovery for current-save live shells restored without PNC identity.
--
-- PZ can persist a registered real zombie into PopMan and later restore it
-- without Lua ModData or a usable persistent-outfit id. The durable PNC record
-- remains authoritative. This lane may ADOPT one unique zero-identity body
-- from the same current-save live lease; it never authorizes deletion of an
-- anonymous body.

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Const = PNC.Const

local function expectsRehydration(record)
    local runtime = record and record.runtime or nil
    return runtime
        and (
            runtime.startupRehydrateExpected == true
            or runtime.lateStreamRehydrateExpected == true
        )
        or false
end

local function validSavedIdentity(value)
    return value ~= nil
        and tostring(value) ~= ""
        and tostring(value) ~= "0"
end

local function ownsLane(record)
    local hint = record and record.runtime
        and record.runtime.startupBodyHint or nil
    local lease = hint and tostring(hint.lease or "") or ""
    local hadEngineIdentity = hint
        and (
            validSavedIdentity(hint.instanceID)
            or validSavedIdentity(hint.populationId)
        )
        or false
    return expectsRehydration(record)
        and hint ~= nil
        and hint.wasLive == true
        and lease ~= ""
        and hadEngineIdentity == true
end

function Internal.MatchAnonymousStartupRehydrate(record, zombie, now)
    local hint = record and record.runtime
        and record.runtime.startupBodyHint or nil
    local radius = tonumber(Const.BODY_SHELL_REHYDRATE_ANON_RADIUS) or 1.0
    local runtime = record and record.runtime or nil
    local lateStream = runtime
        and runtime.lateStreamRehydrateExpected == true
    local startedAt
    if lateStream then
        startedAt = tonumber(runtime.lateStreamRehydrateLoadedAt)
            or tonumber(now)
            or 0
    else
        startedAt = Lifecycle.StartupCleanup
            and tonumber(Lifecycle.StartupCleanup.startedAt)
            or tonumber(now)
            or 0
    end
    local settle = lateStream
        and (
            tonumber(Const.BODY_SHELL_LATE_STREAM_SETTLE_MS)
            or tonumber(Const.BODY_SHELL_STARTUP_SETTLE_MS)
            or 1500
        )
        or tonumber(Const.BODY_SHELL_REHYDRATE_ANON_SETTLE_MS)
        or 750
    local instanceID
    local populationID
    local distance

    if not ownsLane(record) or not hint or not zombie then
        return false, false
    end

    -- This fallback is only for the true identity-stripped PopMan shape.
    -- Any surviving engine identity belongs in the normal exact-proof lanes.
    instanceID = Internal.GetStartupBodyInstanceID
        and Internal.GetStartupBodyInstanceID(zombie) or nil
    populationID = Internal.GetStartupBodyPopulationID
        and Internal.GetStartupBodyPopulationID(zombie) or nil
    if instanceID ~= nil or populationID ~= nil then
        return false, false
    end

    distance = Internal.StartupDistanceSqToRecord(zombie, {
        x = tonumber(hint.x) or tonumber(record.x),
        y = tonumber(hint.y) or tonumber(record.y),
        z = tonumber(hint.z) or tonumber(record.z),
    })
    if distance == nil or distance > radius * radius then
        return false, false
    end

    if zombie.isFemale and record.isFemale ~= nil then
        local bodyFemale = zombie:isFemale() == true
        if bodyFemale ~= (record.isFemale == true) then
            return false, false
        end
    end

    return true, (tonumber(now) or 0) - startedAt >= settle
end

local function rehydrateDistance(match)
    local record = match and match.record or nil
    local body = match and match.body or nil
    local hint = record and record.runtime
        and record.runtime.startupBodyHint or nil
    local x = hint and tonumber(hint.x) or record and tonumber(record.x)
    local y = hint and tonumber(hint.y) or record and tonumber(record.y)
    local z = hint and tonumber(hint.z) or record and tonumber(record.z)
    if not body or not x or not y or not z
        or not body.getX or not body.getY or not body.getZ
    then
        return math.huge
    end
    local dz = (tonumber(body:getZ()) or 0) - z
    local dx = (tonumber(body:getX()) or 0) - x
    local dy = (tonumber(body:getY()) or 0) - y
    return dx * dx + dy * dy + dz * dz * 16
end

local function rehydrateStrength(match)
    local reason = match and tostring(match.reason or "") or ""
    if reason == "uuid" then return 4 end
    if reason == "population_id" then return 3 end
    if reason == "body_hint" then return 2 end
    if reason == "legacy_rehydrate" then return 1 end
    return 0
end

-- Mutates only candidate metadata. Anonymous candidates are adoption-only:
-- if more than one competes, or an exact/proven candidate exists, all
-- anonymous candidates are disabled and none becomes duplicate-cleanup proof.
function Internal.ResolveStartupRehydrateGroup(group)
    local anonymousCount = 0
    local provenCount = 0
    local winner
    local winnerDistance
    local winnerStrength
    local anonymousAmbiguous = false
    local i
    local match

    if not group or (tonumber(group.rehydrate) or 0) <= 0 then
        return nil, false
    end

    for i = 1, #group.items do
        match = group.items[i]
        if match.rehydrateEligible == true and match.disabled ~= true then
            if match.anonymous == true then
                anonymousCount = anonymousCount + 1
            else
                provenCount = provenCount + 1
            end
        end
    end

    if anonymousCount > 0
        and (anonymousCount > 1 or provenCount > 0)
    then
        anonymousAmbiguous = true
        for i = 1, #group.items do
            match = group.items[i]
            if match.rehydrateEligible == true
                and match.anonymous == true
            then
                match.disabled = true
                match.rehydrateEligible = false
                match.ambiguousReason = "ambiguous_anonymous_rehydrate"
                group.rehydrate = math.max(0, group.rehydrate - 1)
            end
        end
    end

    for i = 1, #group.items do
        match = group.items[i]
        if match.rehydrateEligible == true and match.disabled ~= true then
            local distance = rehydrateDistance(match)
            local strength = rehydrateStrength(match)
            if not winner
                or distance < winnerDistance
                or (
                    distance == winnerDistance
                    and strength > winnerStrength
                )
            then
                winner = match
                winnerDistance = distance
                winnerStrength = strength
            end
        end
    end

    if winner then
        for i = 1, #group.items do
            match = group.items[i]
            if match.rehydrateEligible == true
                and match.disabled ~= true
                and match ~= winner
            then
                if match.anonymous == true then
                    match.disabled = true
                    match.ambiguousReason =
                        "ambiguous_anonymous_rehydrate"
                else
                    match.rehydrateDuplicate = true
                end
            end
        end
    end

    return winner, anonymousAmbiguous
end

return Internal
