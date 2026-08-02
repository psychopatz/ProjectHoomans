-- Client read model for map/UI journey presentation.

PNC = PNC or {}
PNC.TravelDirectory = PNC.TravelDirectory or {}

local Directory = PNC.TravelDirectory
local ClientState = PNC.Network.ClientState
local Core = PNC.Core
local Projection = PNC.Travel and PNC.Travel.Projection
local Route = PNC.Travel and PNC.Travel.Route

Directory.VisibilityFilters = Directory.VisibilityFilters or {}

local function currentPlayerKey()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if player and player.getUsername then
        return tostring(player:getUsername())
    end
    if player and player.getOnlineID then
        return tostring(player:getOnlineID())
    end
    return nil
end

local function isSelected(snapshot)
    return snapshot
        and PNC.MapCommands
        and PNC.MapCommands.IsSelected
        and PNC.MapCommands.IsSelected(snapshot.id)
        or false
end

local function resolveSnapshot(npcId)
    npcId = tostring(npcId or "")
    if not (Core and Core.IsClientOnly and Core.IsClientOnly())
        and PNC.Registry
        and PNC.Registry.Get
    then
        local authoritative = PNC.Registry.Get(npcId)
        if authoritative then return authoritative end
        local marker = PNC.Registry.GetDeathMarker
            and PNC.Registry.GetDeathMarker(npcId) or nil
        if marker and PNC.Network.BuildDeathMarkerSnapshot then
            return PNC.Network.BuildDeathMarkerSnapshot(marker)
        end
    end
    local snapshot = ClientState.snapshots
        and ClientState.snapshots[npcId] or nil
    local i
    local candidate
    if snapshot then return snapshot end
    for i = 1, #(ClientState.debugRoster or {}) do
        candidate = ClientState.debugRoster[i]
        if tostring(candidate and candidate.id or "") == npcId then
            return candidate
        end
    end
    return nil
end

local function resolvePortrait(snapshot)
    if snapshot and snapshot.portrait then
        return snapshot.portrait
    end
    if snapshot and snapshot.runtime
        and PNC.Identity
        and PNC.Identity.BuildPortraitSummary
    then
        return PNC.Identity.BuildPortraitSummary(snapshot)
    end
    return nil
end

local function resolveOrganizationalFaction(snapshot)
    if type(snapshot and snapshot.organizationalFaction)
        == "table"
    then
        return snapshot.organizationalFaction
    end
    local affiliation = type(snapshot and snapshot.affiliation)
        == "table" and snapshot.affiliation or nil
    local factionID = affiliation and affiliation.factionID
    if not factionID then return nil end
    local faction = PNC.Factions
        and PNC.Factions.GetPresentation
        and PNC.Factions.GetPresentation(factionID) or nil
    return {
        id = factionID,
        name = faction and faction.name or factionID,
        archetypeID = faction and faction.archetypeID or nil,
        emblem = faction and faction.emblem or nil,
        membershipStatus = affiliation.membershipStatus,
        role = affiliation.role,
        rank = affiliation.rank,
    }
end

local function currentWorldHour()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and tonumber(gameTime:getWorldAgeHours())
        or 0
end

function Directory.RegisterVisibilityFilter(id, filter)
    id = tostring(id or "")
    if id == "" or type(filter) ~= "function" then return false end
    Directory.VisibilityFilters[id] = filter
    return true
end

function Directory.UnregisterVisibilityFilter(id)
    id = tostring(id or "")
    if id == "" then return false end
    Directory.VisibilityFilters[id] = nil
    return true
end

function Directory.IsVisible(snapshot)
    local travel = snapshot and snapshot.travel or nil
    local selected = isSelected(snapshot)
    local id
    local filter
    if snapshot and snapshot.deathMarker == true then
        return tonumber(snapshot.x) ~= nil and tonumber(snapshot.y) ~= nil
    end
    if not snapshot or snapshot.alive == false
        or snapshot.presenceState == PNC.Const.PRESENCE_CORPSE
        or travel and tostring(travel.visibility or "all") == "hidden"
    then
        return false
    end
    if PNC.MapPresentation
        and PNC.MapPresentation.IsVisibleFor
        and not PNC.MapPresentation.IsVisibleFor(
            snapshot.mapPresentation,
            currentPlayerKey(),
            selected
        )
    then
        return false
    end
    for id, filter in pairs(Directory.VisibilityFilters) do
        local ok
        local visible
        ok, visible = pcall(filter, snapshot, travel, id)
        if ok and visible == false then return false end
    end
    return true
end

function Directory.GetProjected(npcId, atWorldHour)
    local snapshot = resolveSnapshot(npcId)
    local travel = snapshot and snapshot.travel or nil
    local projected
    local total
    local travelled
    local hour = tonumber(atWorldHour) or currentWorldHour()
    if not Directory.IsVisible(snapshot) then return nil end

    if not travel then
        return {
            id = tostring(snapshot.id),
            npcId = tostring(snapshot.id),
            name = tostring(
                snapshot.displayName or snapshot.name or snapshot.id
            ),
            faction = tostring(snapshot.faction or "neutral"),
            organizationalFaction =
                resolveOrganizationalFaction(snapshot),
            recruited = snapshot.recruited == true,
            colonist = snapshot.colonist == true
                or snapshot.recruited == true
                or tostring(snapshot.faction or "") == "colonist",
            deathMarker = snapshot.deathMarker == true,
            alive = snapshot.alive ~= false,
            infected = snapshot.infected == true,
            orderKind = snapshot.orderKind,
            portrait = resolvePortrait(snapshot),
            roleTag = snapshot.mapPresentation
                and snapshot.mapPresentation.roleTag
                or snapshot.organizationalFaction
                    and snapshot.organizationalFaction.role
                or snapshot.affiliation
                    and snapshot.affiliation.role
                or nil,
            iconID = snapshot.mapPresentation
                and snapshot.mapPresentation.iconID or nil,
            mapVisibility = snapshot.mapPresentation
                and snapshot.mapPresentation.visibility or "all",
            presenceState = snapshot.presenceState,
            state = snapshot.presenceState == PNC.Const.PRESENCE_LIVE
                and "live" or "idle",
            x = tonumber(snapshot.x),
            y = tonumber(snapshot.y),
            z = tonumber(snapshot.z),
            percent = nil,
            distanceTotal = nil,
            distanceTravelled = nil,
            distanceRemaining = nil,
            etaWorldHour = nil,
            remainingWorldHours = nil,
            metadata = {},
            route = nil,
        }
    end

    -- Network payloads carry points but deliberately omit derived segments.
    -- Compile them once into the client cache, then reuse the geometry for
    -- inexpensive extrapolation on each map frame.
    if Route and travel.route and type(travel.route.segments) ~= "table" then
        travel.route = Route.Build(
            travel.route.points or travel.route,
            travel.origin,
            travel.destination
        )
    end
    if snapshot.presenceState == PNC.Const.PRESENCE_LIVE
        or not Projection
        or not Projection.Project
    then
        projected = travel
    else
        projected = Projection.Project(travel, hour) or travel
    end
    total = math.max(0, tonumber(projected.distanceTotal) or 0)
    travelled = math.max(
        0,
        math.min(total, tonumber(projected.distanceTravelled) or 0)
    )
    return {
        id = tostring(snapshot.id),
        npcId = tostring(snapshot.id),
        name = tostring(
            snapshot.displayName or snapshot.name or snapshot.id
        ),
        faction = tostring(snapshot.faction or "neutral"),
        organizationalFaction =
            resolveOrganizationalFaction(snapshot),
        recruited = snapshot.recruited == true,
        colonist = snapshot.colonist == true
            or snapshot.recruited == true
            or tostring(snapshot.faction or "") == "colonist",
        deathMarker = snapshot.deathMarker == true,
        alive = snapshot.alive ~= false,
        infected = snapshot.infected == true,
        orderKind = snapshot.orderKind,
        portrait = resolvePortrait(snapshot),
        roleTag = snapshot.mapPresentation
            and snapshot.mapPresentation.roleTag
            or snapshot.organizationalFaction
                and snapshot.organizationalFaction.role
            or snapshot.affiliation
                and snapshot.affiliation.role
            or nil,
        iconID = snapshot.mapPresentation
            and snapshot.mapPresentation.iconID or nil,
        mapVisibility = snapshot.mapPresentation
            and snapshot.mapPresentation.visibility or "all",
        presenceState = snapshot.presenceState,
        journeyId = projected.journeyId,
        state = projected.state,
        x = snapshot.presenceState == PNC.Const.PRESENCE_LIVE
            and tonumber(snapshot.x) or tonumber(projected.x) or tonumber(snapshot.x),
        y = snapshot.presenceState == PNC.Const.PRESENCE_LIVE
            and tonumber(snapshot.y) or tonumber(projected.y) or tonumber(snapshot.y),
        z = snapshot.presenceState == PNC.Const.PRESENCE_LIVE
            and tonumber(snapshot.z) or tonumber(projected.z) or tonumber(snapshot.z),
        percent = total <= 0 and 1 or travelled / total,
        distanceTotal = total,
        distanceTravelled = travelled,
        distanceRemaining = math.max(0, total - travelled),
        etaWorldHour = projected.etaWorldHour,
        remainingWorldHours = projected.etaWorldHour
            and math.max(0, projected.etaWorldHour - hour) or nil,
        ownerMod = projected.ownerMod,
        ownerRef = projected.ownerRef,
        metadata = PNC.Travel.Model.CopyMetadata(projected.metadata),
        route = projected.route,
    }
end

function Directory.ListProjected(atWorldHour)
    local output = {}
    local seen = {}
    local id
    local projected
    for id, _ in pairs(ClientState.snapshots or {}) do
        projected = Directory.GetProjected(id, atWorldHour)
        if projected then
            output[#output + 1] = projected
            seen[tostring(id)] = true
        end
    end
    for _, item in ipairs(ClientState.debugRoster or {}) do
        id = item and tostring(item.id or "") or ""
        if id ~= "" and not seen[id] then
            projected = Directory.GetProjected(id, atWorldHour)
            if projected then
                output[#output + 1] = projected
                seen[id] = true
            end
        end
    end
    if not (Core and Core.IsClientOnly and Core.IsClientOnly())
        and PNC.Registry
        and PNC.Registry.ForEach
    then
        PNC.Registry.ForEach(function(record)
            id = record and tostring(record.id or "") or ""
            if id ~= "" and not seen[id] then
                projected = Directory.GetProjected(id, atWorldHour)
                if projected then
                    output[#output + 1] = projected
                    seen[id] = true
                end
            end
        end)
        if PNC.Registry.ForEachDeathMarker then
            PNC.Registry.ForEachDeathMarker(function(marker)
                id = marker and tostring(marker.id or "") or ""
                if id ~= "" and not seen[id] then
                    projected = Directory.GetProjected(id, atWorldHour)
                    if projected then
                        output[#output + 1] = projected
                        seen[id] = true
                    end
                end
            end)
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.name) < tostring(right.name)
    end)
    return output
end

function Directory.GetWorldHour()
    return currentWorldHour()
end

return Directory
