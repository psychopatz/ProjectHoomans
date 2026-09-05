-- Reusable server-authoritative player-to-NPC meeting detection.
--
-- This service deliberately contains only cheap geometry filters followed by
-- the engine gameplay-LOS check. It does not own greetings or flavor policy,
-- so future player-approach commentary can use the same meeting contract.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.SocialMeeting = PNC.SocialMeeting or {}

local Service = PNC.SocialMeeting
local Registry = PNC.Registry

Service.DEFAULT_RADIUS = 10

local function liveBody(id)
    local body = Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(id) or nil
    if not body then return nil end
    if body.isDead and body:isDead() then return nil end
    return body
end

local function bodyPosition(body, record)
    local x = body and body.getX and tonumber(body:getX())
        or tonumber(record and record.x)
    local y = body and body.getY and tonumber(body:getY())
        or tonumber(record and record.y)
    local z = body and body.getZ and tonumber(body:getZ())
        or tonumber(record and record.z)
    if x == nil or y == nil or z == nil then return nil end
    return x, y, z
end

-- Returns (eligible, reason, distanceSquared). Gameplay LOS is used instead
-- of a render-camera frustum because only the former is authoritative on the
-- server.
function Service.CanPlayerMeetNPC(player, record, body, radius)
    local px
    local py
    local pz
    local x
    local y
    local z
    local maxRadius
    local distSq
    local ok
    local visible
    if not player or not record then return false, "invalid_meeting_subject" end
    if player.isDead and player:isDead() then
        return false, "player_unavailable"
    end
    body = body or liveBody(record.id)
    if not body then return false, "npc_unavailable" end
    if body.isDead and body:isDead() then
        return false, "npc_unavailable"
    end
    px = player.getX and tonumber(player:getX()) or nil
    py = player.getY and tonumber(player:getY()) or nil
    pz = player.getZ and tonumber(player:getZ()) or nil
    x, y, z = bodyPosition(body, record)
    if px == nil or py == nil or pz == nil
        or x == nil or y == nil or z == nil
    then
        return false, "position_unavailable"
    end
    if math.floor(z) ~= math.floor(pz) then
        return false, "floor_mismatch"
    end
    maxRadius = math.max(0, tonumber(radius) or Service.DEFAULT_RADIUS)
    distSq = ((x - px) * (x - px)) + ((y - py) * (y - py))
    if distSq > maxRadius * maxRadius then
        return false, "out_of_range", distSq
    end
    if type(player.CanSee) ~= "function" then
        return false, "visibility_api_unavailable", distSq
    end
    ok, visible = pcall(player.CanSee, player, body)
    if not ok then return false, "visibility_check_failed", distSq end
    if visible ~= true then return false, "not_visible", distSq end
    return true, "visible", distSq
end

Service.GetBodyPosition = bodyPosition

return Service
