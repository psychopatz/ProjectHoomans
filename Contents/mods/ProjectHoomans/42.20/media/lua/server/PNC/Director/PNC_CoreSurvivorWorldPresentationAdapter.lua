if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.CoreSurvivorWorldPresentationAdapter =
    PNC.CoreSurvivorWorldPresentationAdapter or {}

local Adapter = PNC.CoreSurvivorWorldPresentationAdapter
local World = require
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"
local Policy = PNC.OptionalProviderPolicy

Adapter.PROVIDER_ID = "ProjectHoomans.LiveBody"
Adapter.PRIORITY = 500
Adapter.PROXIMITY_VISIBILITY_RADIUS = 120

local function playerPosition(player)
    if not player then return nil, nil end
    local okX, x = pcall(function() return player.getX and player:getX() end)
    local okY, y = pcall(function() return player.getY and player:getY() end)
    x = okX and tonumber(x) or nil
    y = okY and tonumber(y) or nil
    return x, y
end

local function playerDiscoveryKey(player)
    if not player then return nil end
    if PNC.CoreWorldDiscoveryAdapter
        and type(PNC.CoreWorldDiscoveryAdapter.ResolvePlayerKey) == "function"
    then
        local ok, key = pcall(
            PNC.CoreWorldDiscoveryAdapter.ResolvePlayerKey,
            player
        )
        if ok and type(key) == "string" and key ~= "" then return key end
    end
    if type(player.getUsername) == "function" then
        local ok, name = pcall(player.getUsername, player)
        if ok and type(name) == "string" and name ~= "" then
            return "player:" .. name
        end
    end
    return nil
end

local function isPlayerOwnedOrAllied(entry, actor, player)
    local actorID = entry and entry.actorID or actor and actor.actorId
    local record = actorID and PNC.Registry
        and type(PNC.Registry.Get) == "function"
        and PNC.Registry.Get(actorID) or nil
    if record then
        if record.recruited == true or record.colonyOwned == true then
            local username = player and type(player.getUsername) == "function"
                and player:getUsername() or nil
            if not username or not record.ownerUsername
                or record.ownerUsername == username
            then
                return true
            end
        end
    end
    if entry and entry.factionID and PNC.Factions
        and type(PNC.Factions.GetPlayerFaction) == "function"
    then
        local ok, pf = pcall(PNC.Factions.GetPlayerFaction, player)
        if ok and type(pf) == "table" and pf.id == entry.factionID then
            return true
        end
    end
    return false
end

local function isDiscoveredByPlayer(entry, player, worldRegistry)
    if type(worldRegistry) ~= "table"
        or type(worldRegistry.GetDiscovery) ~= "function"
    then
        return false
    end
    local key = playerDiscoveryKey(player)
    if not key then return false end
    local discovery = worldRegistry:GetDiscovery()
    local bucket = type(discovery) == "table"
        and type(discovery.players) == "table"
        and discovery.players[key] or nil
    local entities = type(bucket) == "table"
        and type(bucket.entities) == "table"
        and bucket.entities or nil
    if not entities then return false end
    if entry.groupID
        and type(entities.group) == "table"
        and type(entities.group[entry.groupID]) == "table"
        and (tonumber(entities.group[entry.groupID].phase) or 0) >= 1
    then
        return true
    end
    if entry.communityID
        and type(entities.community) == "table"
        and type(entities.community[entry.communityID]) == "table"
        and (tonumber(entities.community[entry.communityID].phase) or 0) >= 1
    then
        return true
    end
    return false
end

function Adapter.IsVisibleToPlayer(entry, actor, group, player, worldRegistry)
    if not player then return true end
    if isPlayerOwnedOrAllied(entry, actor, player) then
        return true
    end
    local px, py = playerPosition(player)
    local pos = entry and entry.position or nil
    if px ~= nil and py ~= nil and type(pos) == "table"
        and tonumber(pos.x) ~= nil and tonumber(pos.y) ~= nil
    then
        local dx = tonumber(pos.x) - px
        local dy = tonumber(pos.y) - py
        local radius = Adapter.PROXIMITY_VISIBILITY_RADIUS
        if dx * dx + dy * dy <= radius * radius then
            return true
        end
    end
    if entry and (entry.groupID ~= nil or entry.communityID ~= nil) then
        return isDiscoveredByPlayer(entry, player, worldRegistry)
    end
    return true
end

local function liveBody(actorID)
    if not PNC.Registry
        or type(PNC.Registry.GetLiveZombie) ~= "function"
    then
        return nil
    end
    return PNC.Registry.GetLiveZombie(actorID)
end

local function bodyPosition(body)
    if not body then return nil end
    local x = body.getX and tonumber(body:getX()) or nil
    local y = body.getY and tonumber(body:getY()) or nil
    if x == nil or y == nil then return nil end
    local z = body.getZ and tonumber(body:getZ()) or 0
    return { x = x, y = y, z = z or 0 }
end

function Adapter.ResolvePosition(actor)
    local actorID = actor and (actor.actorId or actor.actorID)
    if not actorID then return nil end
    return bodyPosition(liveBody(actorID))
end

local ok, reason = World.Presentation.RegisterPositionProvider(
    Adapter.PROVIDER_ID,
    {
        priority = Adapter.PRIORITY,
        resolve = Adapter.ResolvePosition,
    }
)

Adapter.Registered = ok == true
Adapter.LastRegistrationReason = reason

if World.Presentation
    and type(World.Presentation.RegisterEntryFilter) == "function"
    and Policy
then
    local filterOK, filterReason = World.Presentation.RegisterEntryFilter(
        "ProjectHoomans:OptionalProviders",
        {
            filter = function(entry, actor)
                return Policy.ShouldProject(actor, entry)
            end,
        }
    )
    Adapter.FilterRegistered = filterOK == true
    Adapter.FilterRegistrationReason = filterReason
end

if World.Presentation
    and type(World.Presentation.RegisterEntryFilter) == "function"
then
    local visOK, visReason = World.Presentation.RegisterEntryFilter(
        "ProjectHoomans:PlayerVisibility",
        {
            filter = function(entry, actor, group, player, worldRegistry)
                return Adapter.IsVisibleToPlayer(
                    entry,
                    actor,
                    group,
                    player,
                    worldRegistry
                )
            end,
        }
    )
    Adapter.VisibilityFilterRegistered = visOK == true
    Adapter.VisibilityFilterReason = visReason
end

return Adapter
