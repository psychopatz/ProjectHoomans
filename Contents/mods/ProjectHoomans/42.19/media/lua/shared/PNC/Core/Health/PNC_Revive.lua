-- Compatibility facade for the retired bulk-revive interaction.
-- It now applies ordinary bandages to every treatable wound and never grants
-- HP or changes the incapacitation state directly.

PNC = PNC or {}
PNC.Revive = PNC.Revive or {}

local Revive = PNC.Revive
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local Health = PNC.Health
local Treatment = PNC.Treatment

local function targetPosition(record)
    local body = record and Registry.GetLiveZombie(record.id) or nil
    return body and body:getX() or tonumber(record and record.x) or 0,
        body and body:getY() or tonumber(record and record.y) or 0,
        body and body:getZ() or tonumber(record and record.z) or 0
end

local function isPlayerInRange(player, record)
    local x
    local y
    local z
    if not player or not record then
        return false
    end
    x, y, z = targetPosition(record)
    if math.abs((tonumber(player:getZ()) or 0) - z) >= 1 then
        return false
    end
    return Core.DistanceSq(player:getX(), player:getY(), x, y)
        <= (Const.REVIVE_RANGE * Const.REVIVE_RANGE)
end

function Revive.CountBandages(player)
    return Treatment and Treatment.CountBandages
        and Treatment.CountBandages(player) or 0
end

function Revive.Try(player, npcId)
    local record = npcId and Registry.Get(npcId) or nil
    local wounds
    local i
    local applied
    local reason
    if not Core.IsAuthority() then
        return false, "not_authority"
    end
    if not player or (player.isDead and player:isDead()) then
        return false, "invalid_player"
    end
    if not record then
        return false, "npc_missing"
    end
    if not Health.CanRevive(record) then
        return false, "not_incapacitated"
    end
    if not isPlayerInRange(player, record) then
        return false, "too_far"
    end
    wounds = PNC.NPCWounds and PNC.NPCWounds.GetTreatableWounds
        and PNC.NPCWounds.GetTreatableWounds(record) or {}
    if #wounds <= 0 then
        return false, "no_treatable_wounds"
    end
    if Revive.CountBandages(player) < #wounds then
        return false, "missing_bandages"
    end
    for i = 1, #wounds do
        applied, reason = Treatment.TryBandage(
            player,
            record.id,
            wounds[i].partId
        )
        if not applied then return false, reason end
    end
    return true, "wounds_bandaged"
end
