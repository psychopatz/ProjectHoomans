--[[
    Live-body admission policy.

    Persistent NPC records are inexpensive; loaded IsoZombie bodies are not.
    Presence asks this policy before a range-driven materialization so a dense
    population cannot accidentally turn every abstract traveller into a live
    engine body at once. Explicit force-live/admin spawns remain outside this
    policy.
]]

PNC = PNC or {}
PNC.PresenceAdmission = PNC.PresenceAdmission or {}

local Admission = PNC.PresenceAdmission
local Const = PNC.Const
local Core = PNC.Core

Admission.Rules = Admission.Rules or {}

local function countLiveBodies(player)
    local total = 0
    local nearPlayer = 0
    local radius = tonumber(Const.MATERIALIZE_DISTANCE) or 28
    local radiusSq = radius * radius
    if not PNC.Registry or not PNC.Registry.ForEachLive then
        return total, nearPlayer
    end
    PNC.Registry.ForEachLive(function(record)
        total = total + 1
        if player then
            local distSq = Core.DistanceSq(
                record.x,
                record.y,
                player:getX(),
                player:getY()
            )
            if distSq <= radiusSq then
                nearPlayer = nearPlayer + 1
            end
        end
    end)
    return total, nearPlayer
end

function Admission.RegisterRule(id, rule)
    id = tostring(id or "")
    if id == "" or type(rule) ~= "function" then return false end
    Admission.Rules[id] = rule
    return true
end

function Admission.UnregisterRule(id)
    id = tostring(id or "")
    if id == "" or Admission.Rules[id] == nil then return false end
    Admission.Rules[id] = nil
    return true
end

function Admission.Evaluate(record, nearest)
    local total, nearPlayer = countLiveBodies(nearest and nearest.player)
    local globalMaximum = math.max(
        1,
        math.floor(tonumber(Const.LIVE_BODY_MAX_GLOBAL) or 32)
    )
    local playerMaximum = math.max(
        1,
        math.floor(tonumber(Const.LIVE_BODY_MAX_PER_PLAYER) or 20)
    )
    local id
    local rule
    local ok
    local allowed
    local reason

    if total >= globalMaximum then
        return false, "global_live_body_cap"
    end
    if nearest and nearest.player and nearPlayer >= playerMaximum then
        return false, "player_live_body_cap"
    end
    for id, rule in pairs(Admission.Rules) do
        ok, allowed, reason = pcall(rule, record, nearest, {
            liveCount = total,
            nearbyLiveCount = nearPlayer,
            globalMaximum = globalMaximum,
            playerMaximum = playerMaximum,
        })
        if not ok then
            if Core and Core.LogWarn then
                Core.LogWarn(
                    "PNC presence admission rule failed id=" .. tostring(id)
                )
            end
        elseif allowed == false then
            return false, tostring(reason or id)
        end
    end
    return true
end

return Admission
