--[[
    PNC Network Snapshots - Roster Payloads
    Builds compact roster and death-marker snapshots.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Core = PNC.Core
local Const = PNC.Const
local Stamina = PNC.Stamina
local Identity = PNC.Identity
local Settings = PNC.Sandbox

function Network.BuildRosterSnapshot(record, includeTravelRoute)
    local aiState
    local inCombat
    local staminaInfo
    local identity
    if type(record) ~= "table" then
        return nil
    end
    aiState, inCombat = Parts.ResolveAIState(record)
    staminaInfo = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {}
    identity = Parts.BuildIdentitySummary(record)
    return {
        interestDetailed = false,
        id = record.id,
        displayName = identity.displayName,
        name = identity.displayName,
        archetypeID = identity.archetypeID,
        archetypeLabel = identity.archetypeLabel,
        identitySeed = identity.identitySeed,
        portrait = Identity
            and Identity.BuildPortraitSummary
            and Identity.BuildPortraitSummary(record)
            or nil,
        faction = record.faction,
        organizationalFaction =
            Parts.BuildOrganizationalFactionSummary(record),
        worldDiscovery = Parts.BuildWorldDiscoverySummary(record),
        presenceState = record.presenceState,
        zombieTargetable = Settings
            and Settings.CanZombieTargetRecord
            and Settings.CanZombieTargetRecord(record)
            or false,
        x = record.x,
        y = record.y,
        z = record.z,
        orderKind = record.orderSpec and record.orderSpec.kind or nil,
        attackType = record.attackType or "auto",
        ownerUsername = record.ownerUsername
            or record.characterWindow
                and record.characterWindow.ownerUsername,
        ownerOnlineID = record.ownerOnlineID
            or record.characterWindow
                and record.characterWindow.ownerOnlineID,
        hpCurrent = record.health and record.health.current or nil,
        hpMax = record.health and record.health.max or nil,
        healthState = record.health and record.health.state or nil,
        staminaCurrent = staminaInfo.current,
        staminaMax = staminaInfo.max,
        staminaBaseMax = staminaInfo.baseMax,
        staminaState = staminaInfo.state,
        encumbranceLevel = staminaInfo.encumbranceLevel,
        encumbranceRatio = staminaInfo.encumbranceRatio,
        aiState = aiState,
        inCombat = inCombat,
        recruited = record.recruited == true,
        relationshipCategory = record.generation
                and record.generation.relationshipKind == "lover"
            and "Lover" or nil,
        startingRelationship = record.generation
            and record.generation.source == "starting_companion_trait"
            and {
                kind = record.generation.relationshipKind,
                since = record.generation.relationshipSince,
            } or nil,
        persist = record.persist ~= false,
        travel = Parts.BuildTravelSummary(record, includeTravelRoute ~= false),
        mapPresentation = Parts.BuildMapPresentationSummary(record),
    }
end

function Network.BuildDeathMarkerSnapshot(marker)
    if type(marker) ~= "table" or marker.id == nil then
        return nil
    end
    return {
        interestDetailed = false,
        id = tostring(marker.id),
        displayName = tostring(marker.name or marker.id),
        name = tostring(marker.name or marker.id),
        faction = "dead",
        presenceState = Const.PRESENCE_CORPSE,
        alive = false,
        deathMarker = true,
        colonist = marker.colonist == true,
        infected = marker.infected == true,
        portrait = marker.portrait and Core.DeepCopy(marker.portrait) or nil,
        corpseToken = marker.corpseToken,
        createdWorldHour = marker.createdWorldHour,
        x = tonumber(marker.x) or 0,
        y = tonumber(marker.y) or 0,
        z = tonumber(marker.z) or 0,
        hpCurrent = 0,
        hpMax = 0,
        healthState = "dead",
        aiState = "Dead",
        inCombat = false,
        recruited = false,
        persist = true,
    }
end

return Network
