-- Client receipt of the server-authoritative local-player stealth state.

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}
PNC.Network = PNC.Network or {}
PNC.Network.ClientState = PNC.Network.ClientState or {}

local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

local function accept(args)
    local revision
    local previous
    local now
    if type(args) ~= "table" then
        return false
    end
    revision = tonumber(args.revision) or 0
    previous = ClientState.stealthDiscovery
    if previous and revision < (tonumber(previous.revision) or 0) then
        return false
    end
    now = Core and Core.Now and Core.Now() or 0
    ClientState.stealthDiscovery = {
        hasFollowingColonist = args.hasFollowingColonist == true,
        sneaking = args.sneaking == true,
        discovered = args.discovered == true,
        reason = tostring(args.reason or "unknown"),
        revision = revision,
        receivedAt = now,
        expiresAt = now + (tonumber(args.ttlMs) or
            (tonumber(Const.STEALTH_INDICATOR_TIMEOUT_MS) or 1500)),
    }
    return true
end

function Internal.ResetStealthDiscovery()
    ClientState.stealthDiscovery = nil
end

Internal.RegisterServerCommand(Const.CMD_STEALTH_DISCOVERY, accept)

return accept
