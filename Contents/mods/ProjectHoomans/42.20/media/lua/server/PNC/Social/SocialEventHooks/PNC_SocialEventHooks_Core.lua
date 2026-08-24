if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local EntityRef = PNC.EntityRef
local Core = PNC.Core

Hooks.RescueContributions = Hooks.RescueContributions or {}
Hooks.ThreatAttributions = Hooks.ThreatAttributions or {}

function H.WorldAgeHours()
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            tonumber(getGameTime():getWorldAgeHours()) or 0
        )
    end
    return 0
end

function H.Enabled()
    return PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.EnableSocialEvents ~= false
end

function H.DebugWarning(message)
    if not (PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.DebugSocialEvents == true)
    then
        return
    end
    if Core and Core.LogDebug then
        Core.LogDebug("[PNC SocialEvent] " .. tostring(message))
    elseif print then
        print("[PNC SocialEvent] " .. tostring(message))
    end
end

function Hooks.WorldAgeHours()
    return H.WorldAgeHours()
end

function Hooks.ResolveNPCKey(recordOrID)
    local id = type(recordOrID) == "table"
        and recordOrID.id or recordOrID
    return EntityRef.ForNPC(id)
end

function Hooks.ResolvePlayerKey(player)
    local key
    local reason
    if not PNC.PlayerCharacters
        or not PNC.PlayerCharacters.GetEntityKey
    then
        return nil, "player_character_service_unavailable"
    end
    key, reason = PNC.PlayerCharacters.GetEntityKey(player, {
        callback = "social_event_player_resolution",
        worldAgeHours = H.WorldAgeHours(),
    })
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogCombat
    then
        PNC.PlayerCharacterDebug.LogCombat({
            callback = "player_identity_resolution",
            event = "social_event",
            worldAgeHours = H.WorldAgeHours(),
            onlineID = player and player.getOnlineID
                and player:getOnlineID() or nil,
            result = key and "resolved" or "rejected",
            reason = reason,
        })
    end
    if not key then
        H.DebugWarning(
            "player social attribution skipped: stable "
            .. "player-character identity is unavailable ("
            .. tostring(reason) .. ")"
        )
        return nil, reason or "player_character_identity_unavailable"
    end
    return key
end

return Hooks

