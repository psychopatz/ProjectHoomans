-- Puppet Opera response transport and snapshots.
--
-- This provider owns server/client response delivery while the lifecycle
-- module owns session state, phase transitions, and actor release.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal
local Const = PNC.Const or {}

local function sendToClient(player, command, payload)
    if not player then return false end
    local serverRuntime = not isServer or isServer()
    if serverRuntime and sendServerCommand then
        sendServerCommand(player, Const.MODULE, command, payload)
        return true
    end
    if not serverRuntime and triggerEvent then
        triggerEvent("OnServerCommand", Const.MODULE, command, payload)
        return true
    end
    return false
end

local function sendState(session, includeTrace)
    if not session or not session.ownerPlayer then return false end
    return sendToClient(
        session.ownerPlayer,
        Const.CMD_PUPPET_OPERA_STATE,
        Opera.BuildSnapshot(session, includeTrace == true)
    )
end

local function sendError(player, reason, existingSession)
    if not player then return false end
    if existingSession and not existingSession.closed then
        local snapshot = Opera.BuildSnapshot(existingSession, false)
        snapshot.lastError = tostring(reason or "puppet_opera_request_rejected")
        return sendToClient(
            player,
            Const.CMD_PUPPET_OPERA_STATE,
            snapshot
        )
    end
    return sendToClient(player, Const.CMD_PUPPET_OPERA_STATE, {
        phase = Opera.Phases.ABORTED,
        lastError = tostring(reason or "puppet_opera_request_rejected"),
        restored = true,
    })
end

Internal.sendToClient = sendToClient
Internal.sendState = sendState
Internal.sendError = sendError

return true

