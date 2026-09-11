-- Small local-player-only diagnostic for the existing stealth discovery gate.
-- The textures are base-game assets; no duplicate mod asset is required.

PNC = PNC or {}
PNC.NameplateStealthIndicator = PNC.NameplateStealthIndicator or {}

local Indicator = PNC.NameplateStealthIndicator
local Core = PNC.Core
local Const = PNC.Const
local Stealth = PNC.Stealth
local ClientState = PNC.Network and PNC.Network.ClientState or {}

local EYE_OFF = getTexture
    and getTexture("media/ui/foraging/eyeconOff.png") or nil
local EYE_ON = getTexture
    and getTexture("media/ui/foraging/eyeconOn.png") or nil

Indicator.FollowerCache = Indicator.FollowerCache or {}
Indicator.SingleplayerState = Indicator.SingleplayerState or {}

local function playerKey(player)
    local onlineID = player and player.getOnlineID
        and player:getOnlineID() or nil
    local username = player and player.getUsername
        and player:getUsername() or nil
    if onlineID ~= nil then return "id:" .. tostring(onlineID) end
    return "user:" .. tostring(username or player)
end

local function samePlayer(ownerID, ownerUsername, player)
    local playerID = player and player.getOnlineID
        and player:getOnlineID() or nil
    local username = player and player.getUsername
        and tostring(player:getUsername() or "") or ""
    if ownerID ~= nil and playerID ~= nil then
        return tonumber(ownerID) == tonumber(playerID)
    end
    return ownerUsername ~= nil
        and tostring(ownerUsername) ~= ""
        and tostring(ownerUsername) == username
end

local function hasFollowingColonist(player, now)
    local key = playerKey(player)
    local cached = Indicator.FollowerCache[key]
    local snapshot
    local orderKind
    local ownerID
    local ownerUsername
    if cached and cached.player == player and now < cached.expiresAt then
        return cached.value == true
    end
    for _, candidate in pairs(ClientState.snapshots or {}) do
        snapshot = candidate
        if type(snapshot) == "table"
            and snapshot.alive ~= false
            and snapshot.recruited == true
            and tostring(snapshot.tacticalClass or "")
                == tostring(Const.TACTICAL_CLASS_COLONIST or "colonist")
        then
            orderKind = tostring(snapshot.orderKind or "")
            if orderKind == tostring(Const.ORDER_FOLLOW or "follow")
                and snapshot.mobileGroup ~= true
                and snapshot.mobileAmbient ~= true
            then
                ownerID = snapshot.ownerOnlineID
                ownerUsername = snapshot.ownerUsername
                if samePlayer(ownerID, ownerUsername, player) then
                    Indicator.FollowerCache[key] = {
                        player = player,
                        value = true,
                        expiresAt = now + (
                            tonumber(Const.STEALTH_INDICATOR_UPDATE_MS) or 200
                        ),
                    }
                    return true
                end
            end
        end
    end
    Indicator.FollowerCache[key] = {
        player = player,
        value = false,
        expiresAt = now + (
            tonumber(Const.STEALTH_INDICATOR_UPDATE_MS) or 200
        ),
    }
    return false
end

local function isMultiplayerClient()
    return isClient and isClient() == true
end

local function isSneaking(player)
    if Stealth and Stealth.IsOwnerActuallySneaking then
        return Stealth.IsOwnerActuallySneaking(player) == true
    end
    return player
        and player.isSneaking
        and player:isSneaking() == true
end

local function resolveState(player, now)
    local state
    local discovered
    local reason
    local cached
    local visible
    if not player or (player.isDead and player:isDead()) then
        return nil
    end
    if isMultiplayerClient() then
        state = ClientState.stealthDiscovery
        if not state or now >= (tonumber(state.expiresAt) or 0) then
            return nil
        end
        if state.hasFollowingColonist ~= true then
            return nil
        end
        if state.sneaking ~= true then
            return nil
        end
        return state.discovered == true, state.reason
    end
    if not isSneaking(player) then
        Indicator.SingleplayerState = {
            player = player,
            visible = false,
            expiresAt = now + (
                tonumber(Const.STEALTH_INDICATOR_UPDATE_MS) or 200
            ),
        }
        return nil
    end
    cached = Indicator.SingleplayerState
    if cached.player == player and now < (tonumber(cached.expiresAt) or 0) then
        if cached.visible == true then
            return cached.discovered == true
        end
        return nil
    end
    visible = hasFollowingColonist(player, now)
    if not visible then
        Indicator.SingleplayerState = {
            player = player,
            visible = false,
            expiresAt = now + (
                tonumber(Const.STEALTH_INDICATOR_UPDATE_MS) or 200
            ),
        }
        return nil
    end
    if Stealth and Stealth.IsOwnerDiscovered then
        discovered, reason = Stealth.IsOwnerDiscovered(player)
        Indicator.SingleplayerState = {
            player = player,
            visible = true,
            discovered = discovered == true,
            reason = reason,
            expiresAt = now + (
                tonumber(Const.STEALTH_INDICATOR_UPDATE_MS) or 200
            ),
        }
        return discovered == true, reason
    end
    Indicator.SingleplayerState = {
        player = player,
        visible = false,
        expiresAt = now + (
            tonumber(Const.STEALTH_INDICATOR_UPDATE_MS) or 200
        ),
    }
    return nil
end

function Indicator.ResolveState(player, now)
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    return resolveState(player, now)
end

function Indicator.Render(manager, settings)
    local discovered
    local texture
    local width
    local height
    local screenX
    local screenY
    local alpha
    local now
    local zoom = 1
    local core
    if not manager
        or not settings
        or settings.showStealthIndicator ~= true
        or not manager.player
        or not isoToScreenX
        or not isoToScreenY
    then
        return false
    end
    now = Core and Core.Now and Core.Now() or 0
    discovered = Indicator.ResolveState(manager.player, now)
    if discovered == nil then
        return false
    end
    texture = discovered and EYE_ON or EYE_OFF
    if not texture or not texture.getWidth or not texture.getHeight then
        return false
    end
    width = texture:getWidth()
    height = texture:getHeight()
    screenX = isoToScreenX(
        manager.playerIndex,
        manager.player:getX(),
        manager.player:getY(),
        manager.player:getZ()
    ) - (manager.x or 0)
    screenY = isoToScreenY(
        manager.playerIndex,
        manager.player:getX(),
        manager.player:getY(),
        manager.player:getZ()
    ) - (manager.y or 0)
    core = getCore and getCore() or nil
    if core and core.getZoom then
        zoom = tonumber(core:getZoom(manager.playerIndex)) or 1
        if zoom <= 0 then zoom = 1 end
    end
    alpha = manager.player.getAlpha
        and manager.player:getAlpha(manager.playerIndex) or 1
    manager:drawTextureScaled(
        texture,
        screenX - (width / 2),
        screenY - (140 / zoom) - height,
        width,
        height,
        alpha,
        1,
        1,
        1
    )
    return true
end

return Indicator
