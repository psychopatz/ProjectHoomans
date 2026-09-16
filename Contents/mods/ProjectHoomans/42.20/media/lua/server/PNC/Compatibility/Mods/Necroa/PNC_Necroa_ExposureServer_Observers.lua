-- Proximity fan-out for the Necroa exposure adapter.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Necroa = PNC.Compatibility.Necroa or {}

local Registry = PNC.Registry
local Spatial = PNC.SpatialIndex
local EntityRef = PNC.EntityRef
local Mask = PNC.Compatibility.Necroa.Mask
local Social = require "PNC/Compatibility/Mods/Necroa/PNC_Necroa_ExposureServer_Social"
local Observers = {}
local PLAYER_WARNING_INTERVAL_HOURS = 1

local function nowMillis()
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function distanceSq(left, right)
    local dx = (tonumber(left and left:getX()) or 0)
        - (tonumber(right and right:getX()) or 0)
    local dy = (tonumber(left and left:getY()) or 0)
        - (tonumber(right and right:getY()) or 0)
    local dz = (tonumber(left and left:getZ()) or 0)
        - (tonumber(right and right:getZ()) or 0)
    return dx * dx + dy * dy + dz * dz * 4
end

local function positionOf(object)
    return {
        x = object and object.getX and object:getX() or nil,
        y = object and object.getY and object:getY() or nil,
        z = object and object.getZ and object:getZ() or nil,
    }
end

-- The exposure pump runs on the server's centralized scheduler, after the
-- spatial index rebuild. Keep the registry walk only as a compatibility
-- fallback for tests and older load orders where SpatialIndex is unavailable.
local function nearbyNPCs(object, radius)
    local output = {}
    local x = object and object.getX and object:getX() or nil
    local y = object and object.getY and object:getY() or nil
    local records
    if Spatial and Spatial.QueryNPCs and x ~= nil and y ~= nil then
        records = Spatial.QueryNPCs(x, y, radius) or {}
        for index = 1, #records do
            local record = records[index]
            local body = record and Registry.GetLiveZombie
                and Registry.GetLiveZombie(record.id) or nil
            if record and body then
                output[#output + 1] = {
                    record = record,
                    body = body,
                }
            end
        end
        return output
    end
    Registry.ForEachLive(function(record, body)
        if record and body and distanceSq(object, body) <= radius * radius then
            output[#output + 1] = {
                record = record,
                body = body,
            }
        end
    end)
    return output
end

local function nearbyPlayers(object, radius, fallback)
    local x = object and object.getX and object:getX() or nil
    local y = object and object.getY and object:getY() or nil
    if Spatial and Spatial.QueryPlayers and x ~= nil and y ~= nil then
        local players = Spatial.QueryPlayers(x, y, radius)
        if players and #players > 0 then return players end
    end
    return fallback or {}
end

local function eventID(prefix, actorID, observerID, bucket)
    return "social:" .. prefix .. ":" .. tostring(actorID)
        .. ":" .. tostring(observerID) .. ":"
        .. tostring(bucket or math.floor(nowMillis() / 1000))
end

local function maskWarning(observerRecord, victimID)
    local role = Social.Role(observerRecord)
    return {
        flavorID = "compat.necroa.mask_warning",
        eventType = "necroa_mask_removed",
        family = "necroa_mask_safety",
        priority = 65,
        llmPriority = 95,
        weight = 3,
        npcID = tostring(observerRecord.id),
        npcType = role,
        socialRole = role,
        mergeKey = tostring(observerRecord.id) .. ":necroa_mask",
        cooldowns = {
            familyMs = 12000, speakerMs = 12000,
            ambientMs = 2500, mergeWindowMs = 1800,
        },
        victimNPCID = tostring(victimID),
        context = {
            eventType = "necroa_mask_removed",
            victimNPCID = tostring(victimID),
            source = "necroa_airborne_exposure",
        },
    }
end

local function playerWarning(observerRecord)
    local role = Social.Role(observerRecord)
    return {
        flavorID = "compat.necroa.player_mask_removed",
        eventType = "necroa_player_mask_removed",
        family = "necroa_mask_safety",
        priority = 75,
        llmPriority = 100,
        weight = 4,
        npcID = tostring(observerRecord.id),
        npcType = role,
        socialRole = role,
        mergeKey = tostring(observerRecord.id) .. ":necroa_player_mask",
        cooldowns = {
            familyMs = 15000, speakerMs = 15000,
            ambientMs = 2500, mergeWindowMs = 1800,
        },
        context = {
            eventType = "necroa_player_mask_removed",
            source = "necroa_airborne_exposure",
        },
    }
end

function Observers.NPC(Exposure, record, body, players)
    local actorKey = EntityRef and EntityRef.ForNPC
        and EntityRef.ForNPC(record.id) or nil
    local position = positionOf(body)
    local candidates = nearbyNPCs(body, Exposure.RADIUS)
    for index = 1, #candidates do
        local candidate = candidates[index]
        local observerRecord = candidate.record
        local observerBody = candidate.body
        if observerRecord.id ~= record.id and observerRecord.alive ~= false then
            local localPlayers = nearbyPlayers(observerBody, Exposure.RADIUS, players)
            for _, player in ipairs(localPlayers) do
                if player and distanceSq(observerBody, player)
                    <= Exposure.RADIUS * Exposure.RADIUS
                then
                    Social.Emit(
                        observerRecord,
                        actorKey,
                        "necroa_mask_removed",
                        eventID(
                            "necroa_mask_removed",
                            record.id,
                            observerRecord.id
                        ),
                        position,
                        maskWarning(observerRecord, record.id),
                        player
                    )
                    break
                end
            end
        end
    end
end

function Observers.Player(Exposure, player)
    local key = player and player.getOnlineID
        and tostring(player:getOnlineID()) or tostring(player)
    local hasMask = Mask.HasMask(player)
    local worldHour = Social.WorldAgeHours()
    local lastWarningAt = tonumber(Exposure.State.playerWarningAt[key])
    Exposure.State.playerMask[key] = hasMask
    if hasMask then return end
    if lastWarningAt ~= nil
        and worldHour - lastWarningAt < PLAYER_WARNING_INTERVAL_HOURS
    then
        return
    end
    local actorKey = Social.PlayerKey(player)
    if not actorKey then return end
    local candidates = nearbyNPCs(player, Exposure.RADIUS)
    local nearest
    local nearestDistance
    for index = 1, #candidates do
        local candidate = candidates[index]
        local observerRecord = candidate.record
        local observerBody = candidate.body
        if observerRecord.alive ~= false then
            local candidateDistance = distanceSq(observerBody, player)
            if candidateDistance <= Exposure.RADIUS * Exposure.RADIUS
                and (nearestDistance == nil or candidateDistance < nearestDistance)
            then
                nearest = candidate
                nearestDistance = candidateDistance
            end
        end
    end
    if not nearest then return end
    local observerRecord = nearest.record
    local emitted = Social.Emit(
        observerRecord,
        actorKey,
        "necroa_player_mask_removed",
        eventID(
            "necroa_player_mask_removed",
            key,
            observerRecord.id,
            math.floor(worldHour)
        ),
        positionOf(player),
        playerWarning(observerRecord),
        player
    )
    if emitted ~= false then
        Exposure.State.playerWarningAt[key] = worldHour
    end
end

return Observers
