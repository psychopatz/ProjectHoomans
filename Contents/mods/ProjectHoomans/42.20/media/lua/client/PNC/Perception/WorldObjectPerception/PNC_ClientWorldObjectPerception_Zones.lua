-- Client-visible camp zones and the same room-first camp policy used by the
-- dialogue hint path. This is diagnostic projection only; the server still
-- validates the selected site before creating a task.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

local Perception = PNC.Perception.WorldObjects
local Internal = Perception.Internal
local CampSite = Internal.CampSite
local Geometry = Internal.Geometry

local function number(value)
    return Internal.Number(value)
end

local function text(value, maximum)
    return Internal.Text(value, maximum)
end

local function copyPrimitive(value)
    return Internal.CopyPrimitive(value)
end

local function zoneDistance(site, originX, originY, originZ)
    local x = number(site and site.x)
    local y = number(site and site.y)
    local z = number(site and site.z) or 0
    if x == nil or y == nil then return nil end
    if math.abs(z - originZ) > 1 then return nil end
    local dx = x - originX
    local dy = y - originY
    return math.sqrt(dx * dx + dy * dy)
end

local function roomZone(site, distance)
    if type(site) ~= "table" or type(site.roomBounds) ~= "table" then
        return nil
    end
    local label = text(site.label, 64)
        or CampSite.RoomLabel(site.roomType, site.roomName)
        or "room"
    return {
        kind = "room",
        valid = true,
        validation = "geometry_room",
        siteID = text(site.siteID, 128),
        roomID = text(site.roomID, 128),
        buildingID = text(site.buildingID, 128),
        roomType = text(site.roomType, 48),
        roomName = text(site.roomName, 64),
        label = label,
        roomBounds = copyPrimitive(site.roomBounds),
        x = number(site.x), y = number(site.y), z = number(site.z) or 0,
        distance = distance,
        source = "client_loaded_rooms",
    }
end

local function collectZones(cell, origin, originX, originY, originZ, radius,
    objects)
    local zones = {}
    local roomByKey = {}
    local diagnostics = {}
    local function addRoom(site, distance, validation)
        local zone = roomZone(site, distance)
        if not zone then return end
        if validation then zone.validation = validation end
        local key = tostring(zone.siteID or ((zone.roomID or "room")
            .. ":" .. tostring(zone.roomBounds.minX)))
        if not roomByKey[key] then
            roomByKey[key] = true
            zones[#zones + 1] = zone
        end
    end

    if Geometry and type(Geometry.EnumerateRooms) == "function" then
        local ok = pcall(Geometry.EnumerateRooms, cell,
            function(room, building)
                local site, reason = Geometry.DescribeRoom(room, building,
                    cell, origin, {})
                local distance = zoneDistance(site, originX, originY, originZ)
                if site and distance and distance <= radius then
                    addRoom(site, distance)
                elseif reason and #diagnostics < 32 then
                    diagnostics[#diagnostics + 1] = {
                        kind = "room",
                        reason = tostring(reason),
                    }
                end
            end, { maxBuildings = 128 })
        if not ok and #diagnostics < 32 then
            diagnostics[#diagnostics + 1] = {
                kind = "room", reason = "room_enumeration_failed",
            }
        end
    end

    -- Candidate filtering intentionally removes ordinary room floors from
    -- the object list. Preserve room-zone recovery when the building index is
    -- incomplete by asking the player's current loaded square directly.
    local currentSquare = origin and Internal.Call(origin, "getCurrentSquare")
    if currentSquare and Geometry
        and type(Geometry.RoomIdentity) == "function"
    then
        local identityOk, identity = pcall(Geometry.RoomIdentity,
            currentSquare)
        local distance = zoneDistance(identity, originX, originY, originZ)
        if identityOk and type(identity) == "table" and distance
            and distance <= radius
            and type(identity.roomBounds) == "table"
        then
            addRoom({
                siteID = "room:" .. tostring(identity.buildingID or "unknown")
                    .. ":" .. tostring(identity.roomID or "current"),
                roomID = identity.roomID,
                buildingID = identity.buildingID,
                roomType = identity.roomType,
                roomName = identity.roomName,
                label = CampSite.RoomLabel(identity.roomType,
                    identity.roomName),
                roomBounds = identity.roomBounds,
                x = identity.x, y = identity.y, z = identity.z,
            }, distance, "observed_current_room")
        end
    end

    -- A few runtime versions expose room identity on loaded squares while
    -- their building list is incomplete. Keep that observation visible, but
    -- label it as weaker evidence than full room enumeration.
    for index = 1, #(objects or {}) do
        local facts = objects[index].facts or {}
        local identity = facts.room
        local distance = zoneDistance(identity, originX, originY, originZ)
        if type(identity) == "table" and distance and distance <= radius
            and type(identity.roomBounds) == "table"
        then
            local site = {
                siteID = "room:" .. tostring(identity.buildingID or "unknown")
                    .. ":" .. tostring(identity.roomID or "observed"),
                roomID = identity.roomID,
                buildingID = identity.buildingID,
                roomType = identity.roomType,
                roomName = identity.roomName,
                label = CampSite.RoomLabel(identity.roomType,
                    identity.roomName),
                roomBounds = identity.roomBounds,
                x = identity.x, y = identity.y, z = identity.z,
            }
            addRoom(site, distance, "observed_room_identity")
        end
    end

    for index = 1, #(objects or {}) do
        local object = objects[index]
        local facts = object.facts or {}
        if facts.isCampfire == true then
            zones[#zones + 1] = {
                kind = "campfire",
                valid = true,
                validation = "client_loaded_campfire",
                siteID = text(object.targetID or object.objectKey, 128),
                campfireID = text(object.targetID or object.objectKey, 128),
                label = "campfire",
                x = number(object.x), y = number(object.y),
                z = number(object.z) or 0,
                radius = number(facts.campfireRadius)
                    or Perception.CAMPFIRE_RADIUS,
                distance = zoneDistance(object, originX, originY, originZ),
                source = "client_loaded_campfire",
            }
        end
    end
    table.sort(zones, function(left, right)
        local ld = tonumber(left.distance) or math.huge
        local rd = tonumber(right.distance) or math.huge
        if ld ~= rd then return ld < rd end
        return tostring(left.siteID or "") < tostring(right.siteID or "")
    end)
    return zones, diagnostics
end

local function previewCamp(origin, cell)
    local hints = PNC.Semantics and PNC.Semantics.ClientCampSiteHints
    if not hints then
        local loaded, value = pcall(require,
            "PNC/Semantics/PNC_SemanticCampSiteHints")
        if loaded then hints = value end
    end
    if not hints or type(hints.Resolve) ~= "function" then
        return { status = "UNAVAILABLE", reason = "camp_hint_unavailable" }
    end
    local ok, hint, reason = pcall(hints.Resolve, {
        kind = CampSite.KIND,
        scope = CampSite.SCOPES.HERE,
    }, {
        origin = origin,
        player = origin,
        selectionOrigin = origin,
        cell = cell,
    })
    if not ok then
        return {
            status = "UNAVAILABLE",
            policy = "room_then_campfire",
            reason = "camp_hint_error",
        }
    end
    if not hint then
        return {
            status = "UNSAFE",
            policy = "room_then_campfire",
            reason = tostring(reason or "no_visible_site"),
        }
    end
    return {
        status = "SAFE",
        policy = "room_then_campfire",
        scope = hint.scope or hint.siteScope,
        source = hint.source,
        label = hint.label,
        siteID = hint.siteID,
        roomID = hint.roomID,
        roomType = hint.roomType,
        roomName = hint.roomName,
        campfireID = hint.campfireID,
        x = hint.x, y = hint.y, z = hint.z,
        radius = hint.radius,
        score = hint.score,
        clientHint = copyPrimitive(hint),
    }
end

Internal.CollectZones = collectZones
Internal.PreviewCamp = previewCamp

return Perception
