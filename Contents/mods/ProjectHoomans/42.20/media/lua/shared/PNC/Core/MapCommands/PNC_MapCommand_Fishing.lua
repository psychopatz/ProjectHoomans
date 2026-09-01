-- Server command adapter for a selected in-world fishing region. The generic
-- command transport is retained, but fishing selection is owned by the
-- Psychopatz grid-region selector rather than the world map.

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
            options = type(options) == "table" and options or {}
            local region = options.region
            local centerX = math.floor(tonumber(target and target.x) or 0)
            local centerY = math.floor(tonumber(target and target.y) or 0)
            local zone, reason = PNC.FishingService.CreateZone({
                region = region,
                minX = centerX, minY = centerY, maxX = centerX, maxY = centerY,
                z = math.floor(tonumber(target and target.z) or 0), npcIds = npcIds,
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
