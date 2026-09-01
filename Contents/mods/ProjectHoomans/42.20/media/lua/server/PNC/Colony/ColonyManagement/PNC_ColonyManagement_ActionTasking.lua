if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Internal = PNC.ColonyManagement.Internal

local function playerKey(player)
    if player and type(player.getUsername) == "function" then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then return username end
    end
    if player and type(player.getOnlineID) == "function" then
        return tostring(player:getOnlineID() or "")
    end
    return "local"
end

local function ownedZone(service, player, zoneID)
    local data = service and service.Data or nil
    local zones = data and data.zones or nil
    local ownerID = playerKey(player)
    if type(zones) ~= "table" then return nil end
    if zoneID and service.GetZone then
        local zone = service.GetZone(zoneID)
        if zone and tostring(zone.ownerId or "") == ownerID
            and tostring(zone.ownerType or "player") == "player"
        then return zone end
        return nil
    end
    local selected
    for _, zone in pairs(zones) do
        if tostring(zone.ownerId or "") == ownerID
            and tostring(zone.ownerType or "player") == "player"
            and (not selected or tostring(zone.id) < tostring(selected.id))
        then selected = zone end
    end
    return selected
end

local function authorizedNPCs(player, job)
    local output = {}
    local commands = PNC.CompanionCommands
    if not PNC.Registry or type(PNC.Registry.Data) ~= "table"
        or not commands or type(commands.IsOwnedByPlayer) ~= "function"
    then return output end
    for _, record in pairs(PNC.Registry.Data) do
        local allowed = not record.allowedJobs
            or record.allowedJobs[job] ~= false
        if record.alive ~= false and allowed
            and commands.IsOwnedByPlayer(record, player) == true
        then
            output[#output + 1] = tostring(record.id)
        end
    end
    table.sort(output)
    return output
end

local function setWorkZone(player, args, service, job, missingReason)
    args = type(args) == "table" and args or {}
    if not service or type(service.CreateZone) ~= "function" then
        return { ok = false, reason = "ZONE_SERVICE_UNAVAILABLE" }
    end
    if ownedZone(service, player) then
        return { ok = false, reason = "ZONE_EXISTS" }
    end
    if type(args.region) ~= "table" then
        return { ok = false, reason = missingReason or "REGION_REQUIRED" }
    end
    local zone, reason = service.CreateZone({
        region = args.region,
        ownerType = "player",
        ownerId = playerKey(player),
        npcIds = authorizedNPCs(player, job),
    })
    if not zone then return { ok = false, reason = reason or "ZONE_CREATE_FAILED" } end
    return {
        ok = true,
        reason = "ZONE_CREATED",
        details = service.GetSnapshot and service.GetSnapshot(zone.id) or nil,
    }
end

local function clearWorkZone(player, service)
    if not service or type(service.DeleteZone) ~= "function" then
        return { ok = false, reason = "ZONE_SERVICE_UNAVAILABLE" }
    end
    local zone = ownedZone(service, player)
    if not zone then return { ok = false, reason = "ZONE_NOT_FOUND" } end
    local ok, reason = service.DeleteZone(zone.id, "zone_deleted_by_player")
    return { ok = ok == true, reason = reason }
end

function Internal.handleTaskingAction(player, args, action)
    if action == "lumber_zone_set" then
        return setWorkZone(player, args, PNC.LumberService, "Lumber",
            "LUMBER_REGION_REQUIRED")
    end
    if action == "lumber_zone_clear" then
        return clearWorkZone(player, PNC.LumberService)
    end
    if action == "fishing_zone_set" then
        return setWorkZone(player, args, PNC.FishingService, "Fishing",
            "FISHING_REGION_REQUIRED")
    end
    if action == "fishing_zone_clear" then
        return clearWorkZone(player, PNC.FishingService)
    end
    if action == "corpse_haul_zones_clear" then
        local service = PNC.CorpseHaulService
        if not service or not service.ClearConfiguration then
            return { ok = false, reason = "CORPSE_HAUL_SERVICE_UNAVAILABLE" }
        end
        local ok, reason, details = service.ClearConfiguration(player, args)
        return { ok = ok, reason = reason, details = details }
    end
    if action ~= "corpse_haul_zones_set" then return nil end
    local service = PNC.CorpseHaulService
    if not service or not service.SetConfiguration then
        return { ok = false, reason = "CORPSE_HAUL_SERVICE_UNAVAILABLE" }
    end
    local ok, reason, details = service.SetConfiguration(player, args)
    return { ok = ok, reason = reason, details = details }
end

return PNC.ColonyManagement
