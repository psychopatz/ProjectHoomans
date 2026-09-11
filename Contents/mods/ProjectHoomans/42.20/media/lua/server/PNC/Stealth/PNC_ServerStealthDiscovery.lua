-- Server-authoritative discovery state for the local player's stealth
-- diagnostic.  This is intentionally separate from zombie targeting: it
-- observes the existing stealth predicate and sends only the result to the
-- player who owns that state.

PNC = PNC or {}
PNC.ServerStealthDiscovery = PNC.ServerStealthDiscovery or {}

local Service = PNC.ServerStealthDiscovery
local Core = PNC.Core
local Const = PNC.Const
local Network = PNC.Network
local Stealth = PNC.Stealth
local Registry = PNC.Registry

Service.State = Service.State or {}
Service.nextPumpAt = tonumber(Service.nextPumpAt) or 0

local function playerKey(player)
    if Network
        and Network.Internal
        and Network.Internal.PlayerKey
    then
        return Network.Internal.PlayerKey(player)
    end
    if player and player.getUsername then
        return tostring(player:getUsername())
    end
    return tostring(player)
end

local function playerIsDead(player)
    return player
        and player.isDead
        and player:isDead() == true
end

local function playerIsSneaking(player)
    if Stealth and Stealth.IsOwnerActuallySneaking then
        return Stealth.IsOwnerActuallySneaking(player) == true
    end
    return player
        and player.isSneaking
        and player:isSneaking() == true
end

local function samePlayer(ownerID, ownerUsername, player)
    local playerID = player and player.getOnlineID
        and player:getOnlineID() or nil
    local playerUsername = player and player.getUsername
        and tostring(player:getUsername() or "") or ""
    if ownerID ~= nil and playerID ~= nil then
        return tonumber(ownerID) == tonumber(playerID)
    end
    return ownerUsername ~= nil
        and tostring(ownerUsername) ~= ""
        and tostring(ownerUsername) == playerUsername
end

local function isColonistFollower(record, player)
    local order
    local ownerID
    local ownerUsername
    if type(record) ~= "table" or record.alive == false then
        return false
    end
    -- Player-owned colonists are the only records eligible for this visual.
    -- Mobile/roaming populations are not recruited and use roam orders, so
    -- both checks are intentional rather than relying on faction labels.
    if tostring(record.tacticalClass or "")
        ~= tostring(Const.TACTICAL_CLASS_COLONIST or "colonist")
        or record.recruited ~= true
    then
        return false
    end
    order = record.orderSpec
    if type(order) ~= "table"
        or tostring(order.kind or "")
            ~= tostring(Const.ORDER_FOLLOW or "follow")
    then
        return false
    end
    ownerID = order.ownerOnlineID or record.ownerOnlineID
    ownerUsername = order.ownerUsername or record.ownerUsername
    return samePlayer(ownerID, ownerUsername, player)
end

local function hasFollowingColonist(player)
    local found = false
    if not Registry or type(Registry.Data) ~= "table" then
        return false
    end
    for _, record in pairs(Registry.Data) do
        if isColonistFollower(record, player) then
            found = true
            break
        end
    end
    return found
end

local function publish(
    player,
    state,
    now,
    hasFollower,
    sneaking,
    discovered,
    reason
)
    local revision = (tonumber(state.revision) or 0) + 1
    local payload = {
        hasFollowingColonist = hasFollower == true,
        sneaking = sneaking == true,
        discovered = discovered == true,
        reason = tostring(reason or "unknown"),
        revision = revision,
        ttlMs = (
            tonumber(Const.STEALTH_INDICATOR_TIMEOUT_MS) or 1500
        ),
    }
    if not Network
        or not Network.Internal
        or not Network.Internal.SendToPlayer
        or not Network.Internal.SendToPlayer(
            player,
            Const.CMD_STEALTH_DISCOVERY,
            payload
        )
    then
        return false
    end
    state.revision = revision
    state.lastSentAt = now
    state.lastSignature = table.concat({
        tostring(hasFollower == true),
        tostring(sneaking == true),
        tostring(discovered == true),
        tostring(reason or "unknown"),
    }, ":")
    return true
end

function Service.Pump(now)
    local seen = {}
    local sent = 0
    local updateMs
    local heartbeatMs
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    if not isServer or isServer() ~= true then
        return 0
    end
    updateMs = tonumber(Const.STEALTH_INDICATOR_UPDATE_MS) or 200
    if now < (tonumber(Service.nextPumpAt) or 0) then
        return 0
    end
    Service.nextPumpAt = now + updateMs
    heartbeatMs = tonumber(Const.STEALTH_INDICATOR_HEARTBEAT_MS) or 1000

    if not Core or not Core.ForEachPlayer then
        return 0
    end
    Core.ForEachPlayer(function(player)
        local key
        local state
        local sneaking
        local hasFollower
        local discovered = false
        local reason = "no_colonist_following"
        local signature
        local lastSentAt
        if not player or playerIsDead(player) then
            return
        end
        key = playerKey(player)
        seen[key] = true
        state = Service.State[key] or { revision = 0 }
        Service.State[key] = state
        hasFollower = hasFollowingColonist(player)
        sneaking = hasFollower and playerIsSneaking(player) or false
        if hasFollower
            and sneaking
            and Stealth
            and Stealth.IsOwnerDiscovered
        then
            discovered, reason = Stealth.IsOwnerDiscovered(player)
        elseif hasFollower then
            reason = "not_sneaking"
        end
        signature = table.concat({
            tostring(hasFollower == true),
            tostring(sneaking == true),
            tostring(discovered == true),
            tostring(reason or "unknown"),
        }, ":")
        lastSentAt = tonumber(state.lastSentAt) or 0
        if state.lastSignature ~= signature
            or now - lastSentAt >= heartbeatMs
        then
            if publish(
                player,
                state,
                now,
                hasFollower,
                sneaking,
                discovered,
                reason
            ) then
                sent = sent + 1
            end
        end
    end)

    for key, _ in pairs(Service.State) do
        if not seen[key] then
            Service.State[key] = nil
        end
    end
    return sent
end

return Service
