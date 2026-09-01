-- Server map-command adapter for a bounded fishing zone. The current map
-- command surface supplies a point, so the first slice expands that point to
-- a validated square; the zone service still owns shoreline derivation.

PNC = PNC or {}

local Service = PNC.MapCommandService
local Const = PNC.Const or {}

local function playerKey(player)
    if player and player.getUsername then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then return username end
    end
    if player and player.getOnlineID then
        return tostring(player:getOnlineID() or "")
    end
    return "local"
end

local function authorize(player, npcIds)
    local commands = PNC.CompanionCommands
    if not commands or not commands.CanPlayerCommand then
        return false, "companion_authorization_unavailable"
    end
    for index = 1, #npcIds do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcIds[index]) or nil
        if not record then return false, "npc_not_found" end
        local allowed, reason = commands.CanPlayerCommand(record, player,
            tonumber(Const.COMPANION_COMMAND_RADIUS) or 20)
        if allowed ~= true then return false, reason or "npc_unauthorized" end
    end
    return true
end

if Service and Service.RegisterHandler then
    Service.RegisterHandler("fishing_zone", {
        authorize = authorize,
        execute = function(player, npcIds, target, options)
            local radius = math.max(1, math.min(tonumber(options and options.radius)
                or tonumber(Const.FISHING_ZONE_RADIUS) or 12, 32))
            local centerX = math.floor(tonumber(target.x) or 0)
            local centerY = math.floor(tonumber(target.y) or 0)
            local zone, reason = PNC.FishingService.CreateZone({
                minX = centerX - radius, minY = centerY - radius,
                maxX = centerX + radius, maxY = centerY + radius,
                z = math.floor(tonumber(target.z) or 0), npcIds = npcIds,
                ownerType = "player", ownerId = playerKey(player),
            })
            if not zone then
                return { ok = false, accepted = 0, rejected = #npcIds,
                    reason = reason or "fishing_zone_failed" }
            end
            return { ok = true, accepted = #npcIds, rejected = 0,
                reason = "fishing_zone_created",
                details = PNC.FishingService.GetSnapshot(zone.id) }
        end,
    })
end

return Service
