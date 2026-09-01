-- Map command adapter for creating a bounded lumber work zone.
-- The server validates NPC ownership and creates the authoritative zone.
PNC = PNC or {}

local Service = PNC.MapCommandService
local Const = PNC.Const or {}

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

local function authorize(player, npcIds)
    local commands = PNC.CompanionCommands
    if not commands or type(commands.CanPlayerCommand) ~= "function" then
        return false, "companion_authorization_unavailable"
    end
    for index = 1, #npcIds do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcIds[index]) or nil
        if not record then return false, "npc_not_found" end
        local allowed, reason = commands.CanPlayerCommand(
            record, player, tonumber(Const.COMPANION_COMMAND_RADIUS) or 20)
        if allowed ~= true then return false, reason or "npc_unauthorized" end
    end
    return true
end

if Service and Service.RegisterHandler then
    Service.RegisterHandler("lumber_zone", {
        authorize = authorize,
        execute = function(player, npcIds, target, options)
            options = type(options) == "table" and options or {}
            local centerX = math.floor(tonumber(target.x) or 0)
            local centerY = math.floor(tonumber(target.y) or 0)
            local args = {
                z = math.floor(tonumber(target.z) or 0),
                npcIds = npcIds,
                ownerType = "player",
                ownerId = playerKey(player),
            }
            if type(options.region) == "table" then
                args.region = options.region
            else
                local radius = math.max(1, math.min(
                    tonumber(Const.LUMBER_MAX_RADIUS) or 32,
                    math.floor(tonumber(options.radius)
                        or tonumber(Const.LUMBER_DEFAULT_RADIUS) or 12)
                ))
                args.minX = centerX - radius
                args.minY = centerY - radius
                args.maxX = centerX + radius
                args.maxY = centerY + radius
            end
            local zone, reason = PNC.LumberService.CreateZone(args)
            if not zone then
                return { ok = false, accepted = 0, rejected = #npcIds,
                    reason = reason or "lumber_zone_failed" }
            end
            return {
                ok = true, accepted = #npcIds, rejected = 0,
                reason = "lumber_zone_created",
                details = PNC.LumberService.GetSnapshot(zone.id),
            }
        end,
    })
end

return Service
