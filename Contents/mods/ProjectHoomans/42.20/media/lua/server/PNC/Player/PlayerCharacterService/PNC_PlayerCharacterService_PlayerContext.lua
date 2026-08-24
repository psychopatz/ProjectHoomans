if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerCharacters = PNC.PlayerCharacters or {}
PNC.PlayerContext = PNC.PlayerContext or {}
PNC.PlayerCharacters.Internal = PNC.PlayerCharacters.Internal or {}

local PlayerCharacters = PNC.PlayerCharacters
local Internal = PlayerCharacters.Internal
local Constants = PNC.PlayerCharacterConstants
local Types = PNC.PlayerCharacterTypes
local EntityRef = PNC.EntityRef
local Core = PNC.Core
local copy = Internal.copy

function PNC.PlayerContext.Resolve(player, reason)
    local uuid, why = PlayerCharacters.EnsureIdentity(player, {
        callback = reason or "player_context",
    })
    if not uuid then return nil, why end
    local value = PlayerCharacters.RuntimeContexts[player]
    if not value then return nil, "binding_context_unavailable" end
    return copy(value), why or "resolved"
end

function PNC.PlayerContext.Peek(player)
    local value = PlayerCharacters.RuntimeContexts[player]
    return value and copy(value) or nil
end


return PlayerCharacters
